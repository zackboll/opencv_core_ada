"""CORE-DOC-VER-001R1 successor qualification boundary; no enhancer imports.

CORE-DOC-VER-001 edited only Ada comments in two public specifications. The
frozen predecessor records stay byte-identical and pinned here. Each successor
record must equal its predecessor except for the exact source, native and
publication entries declared in the reviewed requalification record, whose
"before" values must equal the frozen predecessor values. Nothing here grants
link or content authority: the independent oracles still reconstruct every
page, search record and compiler destination from current source and native
bytes. This module only bounds which previously qualified bytes may differ.
"""
import hashlib
import html
import json
import re
from pathlib import Path

from link_gnatdoc_types import require

ROOT = Path(__file__).resolve().parent.parent
QUALIFICATION = 'docs/enhancer-qualification'
RECORD = QUALIFICATION + '/core-doc-ver-001-requalification.json'
RECORD_SHA = 'REQUALIFICATION_SHA_PLACEHOLDER'
# (frozen predecessor, its original pin), (successor, its reviewed pin)
GENERIC = ((QUALIFICATION + '/gnatdoc-generic-qualification.json',
            '146a6f6375be14788996e04585ac141bfc308c5be87b040198f5d74c5c74bcfc'),
           (QUALIFICATION + '/gnatdoc-generic-qualification-core-doc-ver-001.json',
            '7356b7a95a9edc1cb8c1189d803cf61f952868297403c27125a4adcf4bcc7a77'))
AUTHORED = ((QUALIFICATION + '/gnatdoc-authored.json',
             '97a3351cbe0f852d5aeddea64fcffab9f66fdf56499b717caab82d06e9f67b65'),
            (QUALIFICATION + '/gnatdoc-authored-core-doc-ver-001.json',
             '8ff8d3ce6b48f658c196abe11ea39a821e03bf50a85c10fea6c026dde3b9eff3'))
PUBLIC_GENERIC = (('docs/verified-examples/public-generic-qualification.json',
                   '2623a2d5746241e567434fe0db4b86ea7b87ad518311cb24e45c71bd67e329be'),
                  ('docs/verified-examples/public-generic-qualification-core-doc-ver-001.json',
                   'PUBLIC_7356b7a95a9edc1cb8c1189d803cf61f952868297403c27125a4adcf4bcc7a77'))
PARAGRAPH = re.compile(r'<p>([^<]*)')


def digest(payload):
    return hashlib.sha256(payload).hexdigest()


def pinned(root, name, expected):
    path = Path(root) / name
    require(path.is_file() and not path.is_symlink(), 'missing qualification record: ' + name)
    payload = path.read_bytes()
    require(digest(payload) == expected, 'unreviewed qualification record: ' + name)
    return json.loads(payload)


def requalification(root=ROOT):
    data = pinned(root, RECORD, RECORD_SHA)
    require(set(data) == {'schema_version', 'task', 'scope', 'base', 'sources', 'native',
                          'publication', 'compiler_maps', 'environment'} and
            data['schema_version'] == 1 and data['task'] == 'CORE-DOC-VER-001R1',
            'unapproved requalification record')
    for table in ('sources', 'native', 'publication'):
        require(data[table] and all(set(v) >= {'before', 'after'} and v['before'] != v['after']
                                    for v in data[table].values()),
                'requalification entries must record distinct before/after hashes')
    require(set(data['sources']) == {'src/opencv-core.ads', 'src/opencv-core-persistence.ads'},
            'requalification source scope changed')
    require(set(data['native']) <= set(data['publication']) and
            set(data['publication']) - set(data['native']) ==
            {'api/gnatdoc-search-index.json', 'api/index.html'},
            'requalification publication scope changed')
    return data


def successor(root, pair, table, prefix=''):
    """Successor equals frozen predecessor except the declared delta entries."""
    (old_name, old_sha), (new_name, new_sha) = pair
    old, new = pinned(root, old_name, old_sha), pinned(root, new_name, new_sha)
    delta = requalification(root)
    require(old.keys() == new.keys(), 'successor record fields changed')
    for key in old:
        if key not in table:
            require(old[key] == new[key], f'successor record changed outside boundary: {key}')
            continue
        changes = delta['sources'] if key == 'source_sha256' else delta['native']
        changes = {prefix + n.removeprefix('src/') if key == 'source_sha256' and prefix else n: v
                   for n, v in changes.items()}
        require(old[key].keys() == new[key].keys(), f'successor inventory changed: {key}')
        for name in old[key]:
            if name in changes:
                require(old[key][name] == changes[name]['before'] and
                        new[key][name] == changes[name]['after'],
                        f'successor entry differs from reviewed delta: {name}')
            else:
                require(old[key][name] == new[key][name], f'successor entry changed: {name}')
        require(changes.keys() <= old[key].keys(), f'requalified entry not in predecessor: {key}')
    return new


def generic(root=ROOT):
    return successor(root, GENERIC, {'source_sha256', 'native_sha256'})


def authored(root=ROOT):
    return successor(root, AUTHORED, {'native_sha256'})


def public_generic(root=ROOT):
    return successor(root, PUBLIC_GENERIC, {'source_sha256', 'native_sha256'}, prefix='public/')


def publication(root=ROOT):
    return requalification(root)['publication']


def unchanged_or_requalified(baseline, current, exempt, root=ROOT):
    """Compare a frozen publication inventory with current hashes.

    Files in `exempt` keep their pre-existing structural checks. Requalified
    files must have their recorded frozen hash and exactly the reviewed new
    hash. Every other baseline file must be byte-identical.
    """
    changes = publication(root)
    require(changes.keys() <= baseline.keys(), 'requalified file absent from frozen baseline')
    for name, sha in baseline.items():
        if name in exempt:
            continue
        if name in changes:
            require(sha == changes[name]['before'], f'requalified file has wrong frozen hash: {name}')
            require(current.get(name) == changes[name]['after'], f'requalified publication bytes differ: {name}')
        else:
            require(current.get(name) == sha, f'previously qualified publication bytes changed: {name}')


def comment_text(source):
    return ' '.join(' '.join(m[1].strip() for m in re.finditer(r'(?m)^\s*--(.*)$', source)).split())


def paragraphs(page):
    return [' '.join(html.unescape(m[1]).split()) for m in PARAGRAPH.finditer(page)]


def prose_only(before, after, source, expected):
    """Pristine native page delta is confined to comment-derived description text.

    With every paragraph text run removed, the authenticated previous page and
    the current page must be byte-identical (headings, anchors, profiles, entity
    lists and markup). Each changed paragraph must be verbatim current source
    comment text and absent from it in its previous form.
    """
    require(PARAGRAPH.sub('<p>', before) == PARAGRAPH.sub('<p>', after),
            'native change outside comment-derived description text')
    old, new = paragraphs(before), paragraphs(after)
    require(len(old) == len(new), 'native paragraph inventory changed')
    comments = comment_text(source)
    changed = [(a, b) for a, b in zip(old, new) if a != b]
    require(all(b in comments and a not in comments for a, b in changed),
            'changed native prose is not the edited source comment text')
    require(len(changed) == expected, 'native prose delta count differs from reviewed record')
    return len(changed)
