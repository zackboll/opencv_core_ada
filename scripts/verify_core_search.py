"""Core-owned search oracle; no enhancer imports or output-derived authority.

Only previously reconciled native sections and public source declarations may
authorize API destinations. Guide bytes are independently reconstructed by the
Core guide verifier before this module is called.
"""
import html
import hashlib
import json
import re
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

from highlight_gnatdoc_ada import strip_highlighting
from link_gnatdoc_types import require, plain
from render_gnatdoc_guides import GUIDES, expected as original_guides

COUNTS = {'package': 195, 'symbol': 215, 'operation': 1047, 'guide': 5}
# Additions already in Core's hash-qualified source/native acquisition but not
# the older released search fixture. Preserve the fixture baseline explicitly.
FIXTURE_ADDITIONS = {
    'Binary_Norm_Kind': 1, 'Add': 2, 'Compare': 2, 'Difference_Norm': 2,
    'Divide': 2, 'Divide_Into': 2, 'Hamming_Norm': 1, 'Hamming_Pairwise_Norm': 1,
    'Multiply': 2, 'Native_Build_Information': 1, 'Native_Version_String': 1,
    'Squared_L2_Difference_Norm': 2, 'Squared_L2_Norm': 2, 'Subtract': 2,
    'Subtract_From': 2,
}
CURRENT_COUNTS = {**COUNTS, 'symbol': 216, 'operation': 1071}
RECONCILIATION_SHA = 'a89090f9e2315ef15826659777ffa4bbd0877e0cd29219c338c31efdad7bf4b0'
INDEX = 'api/gnatdoc-search-index.json'
INDEX_SHA = '91f0b80713ecad655e5560330a794244745ea0c19a71e60ce175f1adaac00bba'
STYLE = '<link rel="stylesheet" href="gnatdoc-search.css">'


class MainText(HTMLParser):
    """Collect guide main-content text, excluding navigation and metadata."""
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.active = False
        self.parts = []
        self.feed(text)
        self.close()

    def handle_starttag(self, tag, attrs):
        if tag == 'main':
            self.active = True

    def handle_endtag(self, tag):
        if tag == 'main':
            self.active = False

    def handle_data(self, text):
        if self.active:
            self.parts.append(text)


def expected_records(site, source, pages):
    records = []
    for key, (path, text, sections) in sorted(pages.items()):
        package = re.search(r'<h1>([^<]+)</h1>', text)[1]
        require(package.lower() == source[key].package and 'internal' not in key.split('.'),
                'search package not public/source-backed')
        records.append(dict(kind='package', name=package, label=package,
                            href=path.name, text=''))
        declarations = []
        for section in sections:
            declaration = source[key].match(plain(strip_highlighting(section[3])))
            raw = '\n'.join(source[key].lines[declaration['start'] - 1:declaration['end']]).strip()
            header = re.match(r'(type|subtype|function|procedure)\s+(\w+)\b', raw, re.I)
            if not header or declaration['scope'].startswith('generic '):
                continue
            require(declaration['scope'].lower() == key + '.' + header[2].lower(),
                    'unsupported nested search declaration')
            # The released cache includes the leading source comment block in
            # the signature excerpt, followed by the declaration itself. Keep
            # source spelling and whitespace; never take text from the cache.
            start = declaration['start'] - 1
            while start and (not source[key].lines[start - 1].strip() or
                             source[key].lines[start - 1].lstrip().startswith('--')):
                start -= 1
            excerpt = '\n'.join(source[key].lines[start:declaration['end']]).strip()
            declarations.append((declaration['start'], section, excerpt, header))
        # Overload ordinals are source order, never the index or GNATdoc order.
        declarations.sort(key=lambda item: item[0])
        totals = Counter(item[3][2].lower() for item in declarations)
        ordinal = Counter()
        for _, section, raw, header in declarations:
            kind, short = header[1].lower(), header[2]
            ordinal[short.lower()] += 1
            name = package + '.' + short
            label = name
            if totals[short.lower()] > 1:
                label += f' (overload {ordinal[short.lower()]}/{totals[short.lower()]})'
            code = ' '.join(re.sub(r'(?m)^\s*--[^\n]*', '', raw).split())
            description = ' '.join(raw.split())
            records.append(dict(kind='symbol' if kind in ('type', 'subtype') else 'operation',
                                name=name, label=label, href=path.name + '#' + section[1],
                                text=(code + ' ' + description)[:64000]))
    # Highlight spans split HTML text events. The original source renderer,
    # not enhanced HTML or an output cache, defines legacy search whitespace.
    guides = original_guides(Path(__file__).resolve().parent.parent, site, examples=False)
    for slug, (label, _) in GUIDES.items():
        parser = MainText(guides[f'{slug}.html'].decode('utf-8'))
        records.append(dict(kind='guide', name=label, label=label,
                            href=f'../guides/{slug}.html',
                            text=' '.join(' '.join(parser.parts).split())))
    records.sort(key=lambda item: (item['name'].lower(), item['kind']))
    counts = Counter(r['kind'] for r in records)
    require(counts == CURRENT_COUNTS,
            f'source/native search coverage differs from qualified Core fixture: {counts}')
    require(len({r['href'] for r in records}) == 1462 + sum(FIXTURE_ADDITIONS.values()),
            'duplicate independent search destination')
    reconciliation = (Path(__file__).resolve().parent.parent /
                      'docs/enhancer-qualification/search-reconciliation.json').read_bytes()
    require(hashlib.sha256(reconciliation).hexdigest() == RECONCILIATION_SHA,
            'unreviewed search fixture reconciliation')
    additions = json.loads(reconciliation)['additions']
    require(Counter(r['name'].removeprefix('OpenCV.Core.') for r in additions) == FIXTURE_ADDITIONS,
            'fixture addition identities differ')
    require(all(r in records for r in additions), 'fixture additions lack independent source/native identity')
    baseline = Counter(r['kind'] for r in records if r not in additions)
    require(baseline == COUNTS, 'qualified fixture baseline not preserved')
    return records


def validate_search(site, source, pages):
    records = expected_records(site, source, pages)
    expected = (json.dumps(dict(schema_version=1, records=records), sort_keys=True,
                           indent=2, ensure_ascii=False) + '\n').encode()
    require((site / INDEX).read_bytes() == expected,
            'search schema/records differ from independent public source/native/guide identities')
    require(hashlib.sha256(expected).hexdigest() == INDEX_SHA,
            'qualified search-index bytes changed')
    return expected, records


def search_markup(payload, records, sha256):
    links = ''.join(
        '<a href="' + html.escape(r['href'], quote=True) + '"' +
        (' target="document-content"' if r['kind'] != 'guide' else '') +
        ' data-search-name="' + html.escape(r['name'], quote=True) +
        '" data-search-kind="' + r['kind'] + '"></a>' for r in records)
    return ('<div id="documentation-search-authority" hidden data-schema="1" data-sha256="' +
            sha256(payload) + '" data-count="' + str(len(records)) + '">' + links + '</div>' +
            '<ul id="documentation-search-results" aria-label="Search results" hidden></ul>')