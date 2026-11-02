#!/usr/bin/env python3
"""CORE-DOC-VER-001R1 explicit delta acquisition; never a generation step.

Compares a fresh pristine native output and complete publication of the base
commit with those of the comment-only revision. Every "before" value must equal
the frozen qualification records, and the base generation must reproduce them,
so the record cannot introduce new history. The emitted record is reviewed and
pinned in core_doc_requalification.py before any validator accepts it.
"""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

from link_gnatdoc_types import SECTION, require
from core_doc_requalification import prose_only, comment_text, paragraphs

ROOT = Path(__file__).resolve().parent.parent
FROZEN = {
    'generic': ('docs/enhancer-qualification/gnatdoc-generic-qualification.json',
                '146a6f6375be14788996e04585ac141bfc308c5be87b040198f5d74c5c74bcfc'),
    'search': ('docs/enhancer-qualification/search-publication-inventory.json',
               '100af3824ee113bf1e58e166501d3fba2141bdb4386540cf1d768f2df3812851'),
    'examples': ('docs/enhancer-qualification/examples-publication-inventory.json',
                 '2d2a628b00534d30bfc7eb6b5568cad8584a5ff7846cfbd3081b68e70a5f318e'),
}
# Files whose existing validators already apply structural, non-byte checks.
STRUCTURAL = {'api/presentation.json', 'index.html'}
CAUSES = {
    'api/gnatdoc-search-index.json': 'search records embed declaration comment text',
    'api/index.html': 'search authority digest of the requalified search index',
}


def digest(payload):
    return hashlib.sha256(payload).hexdigest()


def hashes(directory):
    return {p.relative_to(directory).as_posix(): digest(p.read_bytes())
            for p in sorted(directory.rglob('*')) if p.is_file()}


def frozen(name):
    path, pin = FROZEN[name]
    payload = (ROOT / path).read_bytes()
    require(digest(payload) == pin, 'frozen record changed: ' + path)
    return json.loads(payload)


def acquire(base, base_native, native, base_site, site, environment, maps):
    generic, search, examples = frozen('generic'), frozen('search'), frozen('examples')
    old_native, new_native = hashes(base_native), hashes(native)
    require(old_native == generic['native_sha256'], 'base native does not reproduce frozen acquisition')
    require(old_native.keys() == new_native.keys(), 'native inventory changed')
    commit = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', base + '^{commit}'], text=True).strip()
    tree = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', base + '^{tree}'], text=True).strip()
    old_text = {name: subprocess.check_output(['git', '-C', str(ROOT), 'show', f'{commit}:{name}'])
                for name in generic['source_sha256']}
    require({n: digest(b) for n, b in old_text.items()} == generic['source_sha256'],
            'base sources do not reproduce frozen acquisition')
    sources = {}
    for name, payload in old_text.items():
        current = (ROOT / name).read_bytes()
        if digest(current) == digest(payload):
            continue
        old_lines, new_lines = payload.decode().splitlines(), current.decode().splitlines()
        require(len(old_lines) == len(new_lines), 'requalified source changed line count: ' + name)
        changed = [(a, b) for a, b in zip(old_lines, new_lines) if a != b]
        require(all(a.lstrip().startswith('--') and b.lstrip().startswith('--') for a, b in changed),
                'requalified source changed outside full-line comments: ' + name)
        sources[name] = {'before': digest(payload), 'after': digest(current), 'lines': len(new_lines),
                         'changed_comment_lines': len(changed)}
    native_delta = {}
    for name in sorted(n for n in new_native if new_native[n] != old_native[n]):
        before, after = (base_native / name).read_text(), (native / name).read_text()
        package = re.search(r'<h1>([^<]+)</h1>', after)[1]
        owners = ['src/' + package.lower().replace('.', '-') + '.ads']
        require(owners[0] in sources, 'native change has no edited source: ' + name)
        old_sections, new_sections = list(SECTION.finditer(before)), list(SECTION.finditer(after))
        require([(m[1], m[2], m[3]) for m in old_sections] == [(m[1], m[2], m[3]) for m in new_sections],
                'native heading/anchor/profile changed: ' + name)
        old_comments = comment_text(old_text[owners[0]].decode())
        changes = [(a, b) for a, b in zip(paragraphs(before), paragraphs(after)) if a != b]
        require(all(a in old_comments for a, _ in changes), 'previous native prose not from base comments')
        count = prose_only(before, after, (ROOT / owners[0]).read_text(), len(changes))
        native_delta[name] = {'package': package, 'source': owners[0], 'before': old_native[name], 'after': new_native[name],
                              'sections': len(new_sections), 'paragraphs': len(paragraphs(after)),
                              'changed_paragraphs': count,
                              'cause': 'description text of edited source comments only'}
    old_site, new_site = hashes(base_site), hashes(site)
    require(old_site.keys() == new_site.keys() == examples.keys(), 'publication inventory changed')
    require(all(old_site[n] == examples[n] for n in examples if n not in STRUCTURAL),
            'base publication differs from frozen qualified publication')
    publication = {}
    for name in sorted(n for n in new_site if new_site[n] != old_site[n] and n not in STRUCTURAL):
        require(search.get(name) == examples[name] == old_site[name], 'inconsistent frozen baselines: ' + name)
        publication[name] = {'before': old_site[name], 'after': new_site[name],
                             'cause': CAUSES.get(name, native_delta.get(name, {}).get('cause'))}
        require(publication[name]['cause'], 'unexplained publication change: ' + name)
    require(native_delta.keys() <= publication.keys(), 'native change missing from publication delta')
    return {'schema_version': 1, 'task': 'CORE-DOC-VER-001R1',
            'scope': 'CORE-DOC-VER-001 comment-only edits to two public Ada specifications '
                     '(plus C header comments outside the documentation inventory)',
            'base': {'commit': commit, 'tree': tree}, 'sources': sources, 'native': native_delta,
            'publication': publication, 'compiler_maps': json.loads(maps.read_text()),
            'environment': json.loads(environment.read_text())}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', required=True, help='base commit whose evidence is frozen')
    for name in ('base-native', 'native', 'base-site', 'site', 'environment', 'compiler-maps', 'output'):
        parser.add_argument('--' + name, required=True, type=Path)
    args = parser.parse_args()
    record = acquire(args.base, args.base_native, args.native, args.base_site, args.site,
                     args.environment, args.compiler_maps)
    payload = (json.dumps(record, indent=2, sort_keys=True) + '\n').encode()
    with args.output.open('xb') as stream:
        stream.write(payload)
    print(digest(payload), args.output)
