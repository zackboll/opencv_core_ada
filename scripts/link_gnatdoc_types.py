#!/usr/bin/env python3
"""Conservative, source-backed cross-references for pinned GNATdoc HTML.

Only type-mark positions are candidates. Native targets are discovered, never
computed. Source declarations establish scope, order, shadowing and imports;
the HTML alone cannot establish Ada visibility. No third-party dependencies.
"""

import argparse
import hashlib
import html
import json
import re
from collections import Counter
from pathlib import Path

from compare_gnatdoc_warnings import declaration_index, code_tokens, WarningComparisonError


class CrossReferenceError(ValueError):
    """The pinned input or an integrity invariant was violated."""


IDENT = r"[A-Za-z][A-Za-z0-9_]*"
NAME = IDENT + r"(?:\." + IDENT + r")*"
SECTION = re.compile(
    r"<h4 id=([^ >]+)>([^<]+)</h4>"
    r"<pre class=ada-code-snippet><code>(.*?)</code></pre>", re.S)
LINK = re.compile(
    r'<a class="type-reference" href="([^"<>]+)" '
    r'data-type="([A-Za-z0-9_.]+)">([^<>]+)</a>')
TOKEN = re.compile(
    r'--[^\n]*|"(?:[^"\n]|"")*"|' + NAME +
    r"|:=|=>|\.\.|<>|\d[\w.]*|[^\s]", re.I)
MODIFIERS = {"aliased", "in", "out", "not", "null", "access", "constant"}
STANDARD = {
    "integer", "natural", "positive", "boolean", "float", "long_float",
    "long_long_float", "character", "wide_character", "wide_wide_character",
    "string", "wide_string", "wide_wide_string", "duration"}


def require(condition, message):
    if not condition:
        raise CrossReferenceError(message)


def tokens(text):
    return [(m.group().lower(), m.start(), m.end()) for m in TOKEN.finditer(text)
            if not m.group().startswith(('--', '"'))]


def words(text):
    return [t[0] for t in tokens(text)]


def plain(raw):
    """Remove only our exact markup; reject other or malformed snippet tags."""
    stripped = LINK.sub(lambda m: m[3], raw)
    require('<' not in stripped,
            "unexpected/nested/malformed HTML in Ada snippet")
    return stripped


def decoded_offsets(raw):
    """Keep byte-for-byte entity spelling when wrapping decoded token spans."""
    text, starts, ends = [], [], []
    for match in re.finditer(r"&(?:#[0-9]+|#x[0-9a-fA-F]+|[A-Za-z0-9]+);|.", raw, re.S):
        for char in html.unescape(match.group()):
            text.append(char)
            starts.append(match.start())
            ends.append(match.end())
    return ''.join(text), starts, ends


class Source:
    def __init__(self, path):
        self.lines = path.read_text(encoding="utf-8").splitlines()
        self.code = '\n'.join(code_tokens(line) for line in self.lines)
        package = re.search(r"\bpackage\s+(" + NAME + r")\s+is\b", self.code, re.I)
        require(package is not None, f"no library package in {path}")
        self.package = package[1].lower()
        self.instance = bool(re.match(r"\s+new\b", self.code[package.end():], re.I))
        self.imports = set()
        # Only context-clause withs establish external qualified visibility.
        context = self.code[:package.start()]
        for match in re.finditer(r"(?:^|;)\s*with\s+([^;]+);", context, re.I):
            self.imports.update(n.strip().lower() for n in match[1].split(','))
        self.uses = set()
        for match in re.finditer(r"\buse\s+(?!type\b|all\b)(" + NAME +
                                 r"(?:\s*,\s*" + NAME + r")*)\s*;", self.code, re.I):
            self.uses.update(n.strip().lower() for n in match[1].split(','))
        # Nested packages, renamings, local use clauses and task/protected
        # scopes require a fuller resolver. Do not infer their visibility.
        self.supported = not re.search(
            r"\brenames\b|\b(task|protected)\b", self.code, re.I)
        self.supported &= len(re.findall(r'\bpackage\s+' + NAME + r'\s+is\b',
                                         self.code, re.I)) == 1
        self.supported &= not re.search(r'\buse\s+(?!type\b|all\b)' + NAME,
                                        self.code[package.end():], re.I)
        private = next((i + 1 for i, line in enumerate(self.lines)
                        if code_tokens(line).strip().lower() == 'private'), len(self.lines) + 1)
        indexed = {} if self.instance else declaration_index(self.lines)
        self.declarations = [d for values in indexed.values() for d in values
                             if d['start'] < private]
        # The warning index reports generic formal types both while scanning
        # the header and while attaching formals. Deduplicate identical source
        # locations, not distinct declarations or HTML identities.
        self.declarations = list({(d['start'], d['column'], d['scope'], d['signature']): d
                                  for d in self.declarations}.values())
        self.members = {}
        self.formals = set()
        for d in self.declarations:
            scope = d['scope'].lower()
            if scope.startswith('generic '):
                self.formals.add(d['name'].lower())
            elif scope.rpartition('.')[0] == self.package:
                self.members.setdefault(d['name'].lower(), []).append(d)
            elif scope.startswith(self.package + '.'):
                # Enumeration literals are package-visible. Conservatively
                # also treat deeper component names as blockers; never infer
                # a parent type through a possible source-level shadow.
                self.members.setdefault(d['name'].lower(), []).append(d)

    def match(self, raw):
        profile = words(html.unescape(raw))
        require(profile, "empty Ada declaration")
        matches = []
        for d in self.declarations:
            if len(profile) > 1 and profile[0] in {'type', 'subtype', 'function', 'procedure'}:
                if d['name'].lower() != profile[1]:
                    continue
            full = '\n'.join(self.lines[d['start'] - 1:d['end']])
            if d['scope'].startswith('generic '):
                full = d['signature']
            source = words(full)
            # GNATdoc drops a subprogram's terminating semicolon and aspects.
            # Other profiles are emitted intact, including record bodies.
            remainder = source[len(profile):]
            complete = not remainder or (
                profile[0] in {'function', 'procedure'} and
                remainder[0] in {';', 'with', 'is'})
            if source[:len(profile)] == profile and complete:
                matches.append(d)
        require(len(matches) == 1, f"source profile not unique in {self.package}: {raw[:100]}")
        return matches[0]


def sources(root):
    result = {}
    for path in sorted(root.glob('*.ads')):
        source = Source(path)
        require(source.package not in result, "duplicate source package")
        result[source.package] = source
    return result


def pages_and_targets(api, source_map):
    pages, targets = {}, {}
    for path in sorted(api.glob('*.html')):
        text = path.read_text(encoding="utf-8")
        headings = re.findall(r"<h1>([^<]+)</h1>", text)
        if path.name == 'index.html':
            continue
        require(len(headings) == 1, f"unexpected package heading: {path.name}")
        package = headings[0].lower()
        require('internal' not in package.split('.'), "internal package published")
        require(package in source_map and package not in pages,
                f"unknown/duplicate public package: {package}")
        sections = list(SECTION.finditer(text))
        require(len(sections) == text.count('<pre class=ada-code-snippet>'),
                f"unexpected snippet structure: {path.name}")
        ids = re.findall(r'\bid=([^ >]+)', text)
        require(len(ids) == len(set(ids)), f"duplicate native anchor: {path.name}")
        source = source_map[package]
        pages[package] = (path, text, sections)
        for section in sections:
            raw = plain(section[3])
            declaration = source.match(raw)
            type_header = re.match(r"\s*(type|subtype)\s+(" + IDENT + r")\b",
                                   html.unescape(raw), re.I)
            if not type_header or declaration['scope'].startswith('generic '):
                continue
            require(type_header[2].lower() == section[2].lower(),
                    "type heading/profile mismatch")
            identity = package + '.' + type_header[2].lower()
            require(identity not in targets, f"conflicting type identity: {identity}")
            targets[identity] = (path.name, section[1])
    return pages, targets


def type_positions(text):
    """Recognize type marks, not arbitrary identifiers or expressions.

    Colon profiles (including nested access-to-subprogram profiles), return
    profiles, array component definitions, subtype bases and derived bases.
    Constraints/defaults/attributes are never scanned as type references.
    """
    ts = tokens(text)
    ws = [t[0] for t in ts]
    require(bool(ws), "missing declaration")
    depth = 0
    for word in ws:
        depth += (word == '(') - (word == ')')
        require(depth >= 0, "unbalanced Ada profile")
    require(depth == 0, "unbalanced Ada profile")
    if ws[0] not in {'function', 'procedure', 'type', 'subtype'}:
        return []
    positions = set()
    for i, word in enumerate(ws):
        candidate = word in {':', 'return'}
        if ws[0] in {'type', 'subtype'}:
            candidate |= word == 'of' and 'array' in ws[:i]
            candidate |= word == 'is' and ws[0] == 'subtype'
            candidate |= word == 'new' and i > 1 and ws[i - 1] == 'is'
            candidate |= word == 'is' and ws[0] == 'type' and ws[i + 1:i + 2] == ['access']
        if not candidate:
            continue
        j = i + 1
        while j < len(ws) and ws[j] in MODIFIERS:
            j += 1
        if j < len(ws) and re.fullmatch(NAME, ws[j]) and ws[j] not in {
                'procedure', 'function', 'array', 'record', 'range', 'digits', 'delta'}:
            positions.add(j)
    return [ts[i] for i in sorted(positions)]


def resolve(name, package, declaration, source_map, targets):
    source = source_map[package]
    if not source.supported or name in source.formals:
        return None, 'unsupported'
    # Parameters/discriminants may hide outer declarations in nested profiles.
    full = '\n'.join(source.lines[declaration['start'] - 1:declaration['end']])
    parameter_names = set()
    for match in re.finditer(r'\b(' + IDENT + r'(?:\s*,\s*' + IDENT + r')*)\s*:(?!=)', full):
        parameter_names.update(n.strip().lower() for n in match[1].split(','))
    if name.split('.')[0] in parameter_names:
        return None, 'unsupported'
    scopes = []
    scope = package
    while scope:
        scopes.append(scope)
        scope = scope.rpartition('.')[0]
    if '.' in name:
        for scope in scopes:
            if scope in source_map and (
                    name.split('.')[0] in source_map[scope].formals or
                    any(d['start'] < declaration['start'] or scope != package
                        for d in source_map[scope].members.get(name.split('.')[0], []))):
                return None, 'unsupported'
        owner = name.rpartition('.')[0]
        if owner not in scopes and owner not in source.imports:
            return None, 'unsupported'
        return (name, 'linked') if name in targets else (None, 'unsupported')
    for scope in scopes:
        if scope not in source_map:
            return None, 'unsupported'
        parent = source_map[scope]
        if not parent.supported:
            return None, 'unsupported'
        if name in parent.formals:
            return None, 'unsupported'
        members = [d for d in parent.members.get(name, [])
                   if scope != package or d['start'] < declaration['start']]
        # Non-type declarations also block lookup into enclosing scopes.
        if members:
            identity = scope + '.' + name
            if len(members) == 1 and identity in targets:
                return identity, 'linked'
            return None, 'ambiguous'
    if name in STANDARD:
        return None, 'unsupported'
    candidates = []
    for owner in sorted(source.uses):
        if (owner not in source.imports or owner not in source_map or
                not source_map[owner].supported):
            return None, 'unsupported'
        if name in source_map[owner].members or name in source_map[owner].formals:
            candidates.append(owner + '.' + name)
    if len(candidates) == 1 and candidates[0] in targets:
        return candidates[0], 'linked'
    return None, 'ambiguous' if candidates else 'unsupported'


def render(raw, package, declaration, source_map, targets, filename, counts, families):
    text, starts, ends = decoded_offsets(raw)
    inserts = []
    for name, start, end in type_positions(text):
        identity, status = resolve(name, package, declaration, source_map, targets)
        counts[status] += 1
        if not identity:
            continue
        target_file, anchor = targets[identity]
        href = ('' if target_file == filename else target_file) + '#' + anchor
        label = raw[starts[start]:ends[end - 1]]
        inserts.append((starts[start], ends[end - 1],
                        f'<a class="type-reference" href="{href}" '
                        f'data-type="{identity}">{label}</a>'))
        families[identity.rsplit('.', 1)[1]] += 1
    result = raw
    for start, end, markup in reversed(inserts):
        result = result[:start] + markup + result[end:]
    require(plain(result) == raw, "Ada text preservation failure")
    return result


def outside_hash(text):
    return hashlib.sha256(SECTION.sub(lambda m: m[0].replace(m[3], '', 1), text)
                          .encode('utf-8')).hexdigest()


def process(api, source_root, check=False, minimum_links=0, minimum_pages=0):
    api = api.resolve()
    require(api.name == 'api', "cross-references must operate in a generated api directory")
    source_map = sources(source_root)
    pages, targets = pages_and_targets(api, source_map)
    manifest_path = api / 'type-crossrefs.json'
    existing = manifest_path.exists()
    require(existing or not check, "missing cross-reference integrity manifest")
    manifest = json.loads(manifest_path.read_text()) if existing else {
        'version': 1, 'pages': {}}
    require(manifest.get('version') == 1, "unexpected cross-reference manifest version")
    if existing:
        require(set(manifest['pages']) == set(pages), "manifest package coverage mismatch")
    require(set(pages) == set(source_map), "public source/page coverage mismatch")
    counts, families, changed = Counter(), Counter(), {}
    snippets = enhanced = 0
    for package, (path, text, sections) in sorted(pages.items()):
        entry = manifest['pages'].get(package)
        if existing:
            require(entry['file'] == path.name and entry['outside'] == outside_hash(text),
                    f"non-snippet HTML changed: {package}")
            require(len(entry['snippets']) == len(sections), "snippet count changed")
        else:
            require('type-reference' not in text, "linked HTML lacks integrity manifest")
            entry = {'file': path.name, 'outside': outside_hash(text), 'snippets': []}
            manifest['pages'][package] = entry
        replacements = []
        before = counts['linked']
        for i, section in enumerate(sections):
            snippets += 1
            raw = entry['snippets'][i] if existing else section[3]
            require(plain(section[3]) == raw, "original Ada declaration text changed")
            declaration = source_map[package].match(raw)
            expected = render(raw, package, declaration, source_map, targets,
                              path.name, counts, families)
            if existing:
                require(section[3] == expected,
                        f"type identity/destination/markup mismatch: {package}.{section[2]}")
            else:
                entry['snippets'].append(raw)
            replacements.append((section.start(3), section.end(3), expected))
        enhanced += counts['linked'] > before
        result = text
        for start, end, replacement in reversed(replacements):
            result = result[:start] + replacement + result[end:]
        require(outside_hash(result) == entry['outside'], "HTML outside snippets changed")
        if result != text:
            changed[path] = result
    require(counts['linked'] >= minimum_links and enhanced >= minimum_pages,
            f"insufficient safe coverage: {counts['linked']} links on {enhanced} pages")
    # All input and output integrity checks complete before any site writes.
    if not check and not existing:
        for path, result in changed.items():
            path.write_text(result, encoding="utf-8")
        manifest_path.write_text(json.dumps(manifest, sort_keys=True, indent=2) + '\n',
                                 encoding="utf-8")
    print('Type cross-references:')
    for label, value in (
            ('Public package pages inspected', len(pages)),
            ('Declaration snippets inspected', snippets),
            ('Resolved type links', counts['linked']),
            ('Package pages enhanced', enhanced),
            ('Ambiguous references skipped', counts['ambiguous']),
            ('Unsupported references skipped', counts['unsupported']),
            ('Invalid targets', 0), ('Structural errors', 0)):
        print(f'  {label}: {value}')
    print('  Links by type family: ' + ', '.join(f'{k}={v}' for k, v in sorted(families.items())))
    return counts, enhanced


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('api', type=Path)
    parser.add_argument('--sources', type=Path,
                        default=Path(__file__).resolve().parent.parent / 'src')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    try:
        process(args.api, args.sources, args.check, minimum_links=500, minimum_pages=100)
    except (CrossReferenceError, ValueError, KeyError, WarningComparisonError) as error:
        raise SystemExit(f'error: type cross-references: {error}') from error


if __name__ == '__main__':
    main()