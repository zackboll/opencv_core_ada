#!/usr/bin/env python3
"""Source-backed summaries for two verified Ada generic templates (GNATdoc 26).

No synthetic declarations, native anchors, or declaration snippets are created.
The original empty instance page is independently reconstructed from its source
introduction and the pinned native layout, not trusted from a generated manifest.
"""

import argparse
import html
import json
import re
from pathlib import Path

from link_gnatdoc_types import (NAME, sources, pages_and_targets, require, words,
                               CrossReferenceError)
from install_gnatdoc_theme import NATIVE, METADATA
from compare_gnatdoc_warnings import declaration_index, WarningComparisonError


VECTORS = 'opencv.core.vectors'
MATRICES = 'opencv.core.fixed_matrices'
TEMPLATES = {
    VECTORS: ('Length',),
    MATRICES: ('Row_Count', 'Column_Count'),
}
MEMBERS = {
    VECTORS: {
        'Component_Index': 'subtype Component_Index is Natural range 0 .. Length - 1;',
        'Vector': 'type Vector is array (Component_Index) of Element_Type;',
    },
    MATRICES: {
        'Row_Index': 'subtype Row_Index is Natural range 0 .. Row_Count - 1;',
        'Column_Index': 'subtype Column_Index is Natural range 0 .. Column_Count - 1;',
        'Matrix': 'type Matrix is array (Row_Index, Column_Index) of Element_Type;',
    },
}
ELEMENTS = {
    'UInt8_Value': ('opencv', 'subtype UInt8_Value is Interfaces.Unsigned_8;'),
    'Int8_Value': ('opencv', 'subtype Int8_Value is Interfaces.Integer_8;'),
    'UInt16_Value': ('opencv', 'subtype UInt16_Value is Interfaces.Unsigned_16;'),
    'Int16_Value': ('opencv', 'subtype Int16_Value is Interfaces.Integer_16;'),
    'Int32_Value': ('opencv', 'subtype Int32_Value is Interfaces.Integer_32;'),
    'Float16_Value': ('opencv.core', 'type Float16_Value is private;'),
    'Float32_Value': ('opencv', 'subtype Float32_Value is Interfaces.IEEE_Float_32;'),
    'Float64_Value': ('opencv', 'subtype Float64_Value is Interfaces.IEEE_Float_64;'),
}
PREFIX = ('<!DOCTYPE html>\n<html class=main>\n' + NATIVE + '<body class=content>')
SUMMARY_ANCHOR = 'instance-members-summary'


def qualified_instances():
    """The independently qualified source identities, not a suffix allowlist."""
    result = {'opencv.core.' + depth.lower() + '_vec' + str(length):
              (VECTORS, depth + '_Value', [length])
              for depth in ('UInt8', 'Int8', 'UInt16', 'Int16', 'Int32',
                            'Float16', 'Float32', 'Float64')
              for length in (2, 3, 4)}
    result['opencv.core.float32_matx3x3'] = (MATRICES, 'Float32_Value', [3, 3])
    return result


def title(source):
    return re.search(r'\bpackage\s+(' + NAME + r')\s+is\b', source.code, re.I)[1]


def native_instance(source):
    """Exact layout qualified only for these plain-text introductions.

    Reject markup/tag-bearing comments rather than emulate GNATdoc's general
    comment language. GNATdoc folds each paragraph's whitespace and emits p
    start tags without end tags in its pinned HTML5 serialization.
    """
    declaration = next(i for i, line in enumerate(source.lines)
                       if re.search(r'\bpackage\s+' + NAME + r'\s+is\b', line, re.I))
    intro = []
    i = declaration - 1
    while i >= 0 and (source.lines[i].lstrip().startswith('--') or
                      not source.lines[i].strip()):
        intro.append(re.sub(r'^\s*--\s?', '', source.lines[i]))
        i -= 1
    text = '\n'.join(reversed(intro)).strip()
    require(text and not re.search(r'[<>&@]', text),
            f'unsupported instance introduction: {source.package}')
    paragraphs = [' '.join(p.split()) for p in re.split(r'\n\s*\n', text)]
    return (PREFIX + '<h1>' + title(source) + '</h1><h2>Entities</h2>'
            '<h2>Description</h2>' + ''.join('<p>' + p for p in paragraphs))


def check_ancestor_visibility(package, owner, element, source_map):
    """Conservative parent lookup, not a general Ada visibility resolver.

    Public child visible parts do not generally see ancestor private parts;
    private descendants can. We deliberately reject private blockers too rather
    than model placement-dependent visibility. Do not use Source.members here:
    it omits private declarations for native public type-link generation.
    """
    scope = package.rpartition('.')[0]
    while True:
        require(scope in source_map, f'missing ancestor scope: {scope}')
        ancestor = source_map[scope]
        require(ancestor.supported and not ancestor.instance and
                not ancestor.uses and not ancestor.formals and
                not re.search(r'\b(generic|renames|use)\b', ancestor.code, re.I),
                f'unsupported ancestor visibility: {scope}')
        if scope == owner:
            # Public expected declaration is separately matched below. Private
            # completions (notably Float16_Value) do not denote a new type.
            require(len(ancestor.members.get(element.lower(), [])) == 1,
                    f'ambiguous ancestor owner declaration: {scope}.{element}')
            break
        indexed = declaration_index(ancestor.lines)
        require(not any(d['name'].lower() == element.lower()
                        for entries in indexed.values() for d in entries),
                f'potentially shadowing ancestor declaration: {scope}.{element}')
        scope = scope.rpartition('.')[0]


def discover(source_map):
    instances = {}
    for package, source in source_map.items():
        if not source.instance:
            continue
        # Other existing families are out of scope, never guessed. New instances
        # of supported templates (or vector/matrix-named targets) must qualify.
        match = re.search(r'\bpackage\s+(' + NAME + r')\s+is\s+new\s+('
                          + NAME + r')\s*\(([^;]*)\)\s*;\s*$', source.code, re.I)
        targeted = bool(re.search(r'_(?:vec\d+|matx\d+x\d+)$', package))
        supported = bool(match and match[2].lower() in TEMPLATES)
        mentions = any(t in source.code.lower() for t in TEMPLATES)
        if not (targeted or supported or mentions):
            continue
        require(match is not None, f'malformed targeted instantiation: {package}')
        template = match[2].lower()
        require(template in TEMPLATES, f'unsupported generic template: {package}')
        require(template in source.imports, f'template not imported: {package}')
        associations = {}
        for part in match[3].split(','):
            assoc = re.fullmatch(r'\s*([A-Za-z][\w]*)\s*=>\s*(' + NAME + r'|[0-9]+)\s*', part)
            require(assoc is not None, f'unsupported generic association: {package}')
            formal, actual = assoc[1].lower(), assoc[2]
            require(formal not in associations, f'duplicate generic association: {package}')
            associations[formal] = actual
        formals = ('Element_Type',) + TEMPLATES[template]
        require(set(associations) == {f.lower() for f in formals},
                f'unresolved generic formals: {package}')
        actual = associations['element_type']
        candidates = [name for name in ELEMENTS if name.lower() == actual.lower()]
        require(len(candidates) == 1, f'unknown/ambiguous actual type: {package}: {actual}')
        element = candidates[0]
        owner, declaration = ELEMENTS[element]
        require(owner in source_map, f'missing actual owner: {owner}')
        require(words(declaration) in [words('\n'.join(source_map[owner].lines[
                    d['start'] - 1:d['end']]))
                    for d in source_map[owner].members.get(element.lower(), [])],
                f'changed actual type declaration: {element}')
        # Unqualified actual visibility comes only from the parent hierarchy.
        require(package.startswith(owner + '.'), f'actual not parent-visible: {package}')
        check_ancestor_visibility(package, owner, element, source_map)
        require(not source.uses and element.lower() not in source.members,
                f'ambiguous actual visibility: {package}')
        # Instantiation-only compilation units may not introduce local aliases,
        # renamings or extra context that could change the visibility contract.
        context = source.code[:match.start()]
        require(words(context) == words('with ' + match[2] + ';'),
                f'unsupported/ambiguous instance context: {package}')
        dimensions = []
        for formal in TEMPLATES[template]:
            value = associations[formal.lower()]
            require(re.fullmatch(r'[1-9][0-9]*', value) is not None,
                    f'non-positive/non-literal dimension: {package}')
            dimensions.append(int(value))
        instances[package] = (template, element, dimensions)
    for template in {v[0] for v in instances.values()}:
        require(template in source_map, f'missing template source: {template}')
        source = source_map[template]
        expected = ('generic type Element_Type is private; ' +
                    ' '.join(f'{f} : Positive;' for f in TEMPLATES[template]) +
                    f' package {title(source)} is ' +
                    ' '.join(MEMBERS[template].values()) + f' end {title(source)};')
        require(words(source.code) == words(expected),
                f'unsupported template declarations: {template}')
    return instances


def link(target, label):
    return '<a href="' + html.escape(target, quote=True) + '">' + html.escape(label) + '</a>'


def render(instance, source_map, pages, targets):
    template, element, dimensions = instance
    require(template in pages, f'missing generic template page: {template}')
    template_title = title(source_map[template])
    template_file = pages[template][0].name
    owner = ELEMENTS[element][0]
    identity = owner + '.' + element.lower()
    require(identity in targets, f'missing actual type anchor: {identity}')
    element_title = title(source_map[owner]) + '.' + element
    actual_link = link('#'.join(targets[identity]), element_title)
    args = [('Element_Type', actual_link)] + list(zip(TEMPLATES[template], map(str, dimensions)))
    meanings = {}
    if template == VECTORS:
        length = dimensions[0]
        meanings = {'Component_Index': f'Natural range 0 .. {length - 1}',
                    'Vector': f'Array of {length} {element} components, indexed by Component_Index'}
    else:
        rows, columns = dimensions
        meanings = {'Row_Index': f'Natural range 0 .. {rows - 1}',
                    'Column_Index': f'Natural range 0 .. {columns - 1}',
                    'Matrix': f'{rows} × {columns} array of {element} elements, indexed by (Row_Index, Column_Index)'}
    member_rows = []
    for member, meaning in meanings.items():
        identity = template + '.' + member.lower()
        require(identity in targets, f'missing template member anchor: {identity}')
        member_rows.append('<tr><th scope="row">' + link('#'.join(targets[identity]), member)
                           + '</th><td>' + html.escape(meaning) + '</td></tr>')
    result = ('<section class="generic-instance-summary" id="' + SUMMARY_ANCHOR +
              '"><h2>Instantiated Members</h2>'
              '<p>Explanatory instantiated equivalents, not additional source declarations.</p>'
              '<p>Generic template: ' + link(template_file, template_title) + '</p>'
              '<h3>Actual generic arguments</h3><table><thead><tr><th scope="col">Formal</th>'
              '<th scope="col">Actual</th></tr></thead><tbody>' +
              ''.join('<tr><th scope="row">' + f + '</th><td>' + a + '</td></tr>' for f, a in args) +
              '</tbody></table><h3>Instantiated members</h3>'
              '<p>Member links lead to the generic template declarations, not native instance-member declarations.</p>'
              '<table><thead><tr><th scope="col">Member</th><th scope="col">Meaning</th></tr></thead><tbody>'
              + ''.join(member_rows) + '</tbody></table>'
              '<p>This is an ordinary Ada array, not a cv::Mat. Assignment follows Ada value semantics '
              'for the actual element type; this generic introduces no native handle.</p>')
    if template == VECTORS:
        result += ('<p>With the corresponding typed OpenCV APIs, each vector value represents one '
                   'complete multi-channel element. Component indices specify channel positions, '
                   'not semantic channel names.</p>')
    else:
        conversions = 'opencv.core.float32_matx3x3_conversions'
        require(conversions in pages, 'missing separate matrix conversion package')
        result += ('<p>The separate ' + link(pages[conversions][0].name, title(source_map[conversions])) +
                   ' package copies between this array and Mat storage; it does not imply shared native storage.</p>')
    if element == 'Float16_Value':
        result += ('<p>Float16_Value stores exact IEEE-754 binary16 encodings. Stored representation '
                   'and numerical interpretation are distinct; numeric conversion uses To_Float32/To_Float16.</p>')
    return result + '</section>'


def process(api, source_root, check=False, expected_count=None):
    source_map = sources(source_root)
    instances = discover(source_map)
    if expected_count is not None:
        require(len(instances) == expected_count, 'generic instance source count mismatch')
    if expected_count == 25:
        require(instances == qualified_instances(),
                'generic instance baseline identities/associations mismatch')
    pages, targets = pages_and_targets(api, source_map)
    metadata = api / 'generic-instances.json'
    existing = metadata.exists()
    require(existing or not check, 'missing generic instance integrity metadata')
    manifest = {'version': 1, 'pages': {}}
    results = {}
    links = 0
    for package, instance in sorted(instances.items()):
        require(package in pages, f'missing instance page: {package}')
        path, current, sections = pages[package]
        require(not sections and '<h4' not in current, f'unapproved native instance sections: {package}')
        original = native_instance(source_map[package])
        summary = render(instance, source_map, pages, targets)
        # Insert before Description: retains every native byte and cannot nest
        # the section inside GNATdoc's deliberately unclosed introductory p.
        result = original.replace('<h2>Description</h2>', summary + '<h2>Description</h2>', 1)
        require(current.count('generic-instance-summary') == int(existing),
                f'missing/duplicate/unapproved summary: {package}')
        if existing:
            approved = result.replace(NATIVE, NATIVE + METADATA, 1) if METADATA in current else result
            require(current == approved, f'summary/native integrity mismatch: {package}')
        else:
            require(current == original, f'unsupported HTML insertion point/native introduction: {package}')
        manifest['pages'][package] = {'file': path.name, 'original': original}
        links += summary.count('<a href=')
        results[path] = result
    enriched = {p for p, (_, text, _) in pages.items() if 'generic-instance-summary' in text}
    require(enriched == (set(instances) if existing else set()), 'unapproved enriched page coverage')
    if existing:
        require(json.loads(metadata.read_text(encoding='utf-8')) == manifest,
                'tampered generic instance integrity metadata')
    else:
        require(not (api / 'presentation.json').exists(), 'enrich before theme installation')
        for path, text in results.items():
            path.write_text(text, encoding='utf-8')
        metadata.write_text(json.dumps(manifest, sort_keys=True, indent=2) + '\n', encoding='utf-8')
    print(f'Generic instances: {len(instances)} pages; {links} template/member/type links; integrity errors: 0')
    return instances, links


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('api', type=Path)
    parser.add_argument('--sources', type=Path, default=Path(__file__).resolve().parent.parent / 'src')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    try:
        process(args.api, args.sources, args.check, expected_count=25)
    except (CrossReferenceError, ValueError, KeyError, WarningComparisonError) as error:
        raise SystemExit(f'error: generic instances: {error}') from error