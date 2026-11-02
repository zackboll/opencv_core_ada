"""Core's deliberately finite example policy, independent of enhancer code.

The hash-bound authored sources are the authority for text. This reviewed list
authorizes only specific spellings in specific original fences, not arbitrary
resolver output. Native filenames/anchors are observed and complete profiles
are matched by Core's retained source parser. Output metadata grants nothing.
"""
import html
import re

from highlight_gnatdoc_ada import LEXEME, highlight_text, strip_highlighting
from link_gnatdoc_types import sources, pages_and_targets, plain, require
from core_verified_examples import compiler_destinations

STYLESHEET = 'assets/gnatdoc-examples.css'
CSS_SHA = '86ee3667f123c5f718e07c8b0c97c8e2844fa28d6d3c93e97c889e4e6fb6a395'
MAT = 'OpenCV.Core.Mat'
# Fence numbers include non-Ada fences. No generated HTML or manifest supplies
# this authorization. Every occurrence below was reviewed in the original source.
LINKS = {
    'index': {0: [('Mat', MAT, 2)]},
    'ownership-and-views': {
        0: [('OpenCV.Size', 'OpenCV.Size', 1)],
        2: [(s, s, 1) for s in (
            'OpenCV.Core.Float32_Row_Access.Row_Array',
            'OpenCV.Core.Float32_Row_Access.With_Read_Only_Row')],
        3: [(s, s, 1) for s in ('OpenCV.Core.UInt8_Mat_View.Buffer_Array', MAT)],
        4: [(s, s, 1) for s in ('OpenCV.Core.Float32_Mat_View.Buffer_Array', MAT)],
        5: [(s, s, 1) for s in ('OpenCV.Core.UInt8_Mat_View.Buffer_Array', MAT)],
        8: [(s, s, 1) for s in ('OpenCV.Core.UInt16_Mat_View.Buffer_Array', MAT)],
        9: [(s, s, 1) for s in ('OpenCV.Core.Float32_Mat_View.Buffer_Array', MAT,
                               'OpenCV.Core.Float32_Mat_View.With_Writable_Strided_Mat_View')],
        10: [('Mat', MAT, 2)],
        17: [(s, s, 1) for s in ('OpenCV.Core.UMat', 'OpenCV.Core.Transfers.To_UMat',
                                MAT, 'OpenCV.Core.Transfers.To_Mat')],
    },
    'sparse-and-persistence-guide': {
        0: [('OpenCV.Core.Sparse.UInt8_Access.For_Each_Stored',
             'OpenCV.Core.Sparse.UInt8_Access.For_Each_Stored', 1)]},
}
FENCE = re.compile(r'<pre><code class="language-([a-z]+)">(.*?)</code></pre>', re.S)


def native_destinations(root, site):
    """Resolve all kinds through exact native/source profiles, never output links."""
    source = sources(root / 'src')
    pages, _ = pages_and_targets(site / 'api', source)
    result = {}
    for owner, (path, _, sections) in pages.items():
        pkg = source[owner]
        for section in sections:
            raw = plain(strip_highlighting(section[3]))
            declaration = pkg.match(raw)
            identity = declaration['scope'].lower()
            if identity.rpartition('.')[0] != owner:
                continue
            group = [d for d in pkg.declarations if d['scope'].lower() == identity]
            if len(group) != 1 or not pkg.supported:
                continue
            kind = re.match(r'(type|subtype|procedure|function)\s', raw, re.I)
            if kind:
                require(identity not in result, 'duplicate native example destination')
                result[identity] = (path.name + '#' + section[1], kind[1].lower())
    return result


def example_code(text, policy, destinations, landing=False, verified=()):
    # Comments, literals and attributes cannot grant API references.
    masked = list(text)
    for token in LEXEME.finditer(text):
        if token.lastgroup in ('comment', 'string', 'character', 'attribute'):
            masked[token.start():token.end()] = ' ' * len(token[0])
    masked = ''.join(masked)
    positions = [(call['start'], call['end'], call['href']) for call in verified]
    for spelling, identity, count in policy:
        require(identity.lower() in destinations, 'example destination not unique/public/native')
        href, kind = destinations[identity.lower()]
        matches = list(re.finditer(r'(?<![\w.])' + re.escape(spelling) + r'(?![\w.])', masked))
        require(len(matches) == count, 'reviewed example occurrence count changed')
        for match in matches:
            if kind in ('type', 'subtype'):
                require(re.search(r':\s*(?:(?:constant|aliased|in|out)\s+)*$', masked[:match.start()]),
                        'example link is not a reviewed type mark')
            else:
                require(re.match(r'\s*\(', masked[match.end():]), 'example link is not a call')
                require('.' in spelling, 'unqualified operations are not authorized by Core')
            positions.append((match.start(), match.end(), href))
    positions.sort()
    parts, end = [], 0
    for start, stop, href in positions:
        require(start >= end, 'overlapping example links')
        parts.append(highlight_text(html.escape(text[end:start], quote=False)))
        prefix = 'api/' if landing else '../api/'
        parts.append(f'<a class="ada-api-reference" href="{prefix}{href}">' +
                     highlight_text(html.escape(text[start:stop], quote=False)) + '</a>')
        end = stop
    parts.append(highlight_text(html.escape(text[end:], quote=False)))
    if text.endswith('\n'):
        parts.append('<span class="ada-example-end"></span>')
    return ''.join(parts)


def guide_examples(page, slug, destinations):
    fence = -1
    used = set()

    def replace(match):
        nonlocal fence
        fence += 1
        if match[1] != 'ada':
            return match[0]
        used.add(fence)
        text = html.unescape(match[2])
        return ('<pre class="ada-example" tabindex="0"><code class="language-ada">' +
                example_code(text, LINKS.get(slug, {}).get(fence, []), destinations) +
                '</code></pre>')

    result = FENCE.sub(replace, page)
    require(set(LINKS.get(slug, {})) <= used, 'reviewed Ada fence missing')
    return result.replace('</head>',
                          f'<link rel="stylesheet" href="../{STYLESHEET}"></head>', 1)


def landing_example(root, site):
    home = (root / 'docs/index.html').read_text(encoding='utf-8')
    text = (root / 'docs/example.adb').read_text(encoding='utf-8').rstrip('\n')
    # Core's unchanged homepage contract is exactly two plain pre blocks. The
    # first is the shell command; the second is exactly the original Ada source.
    blocks = list(re.finditer(r'<pre>([^<]*)</pre>', home))
    require(len(blocks) == 2 and blocks[0][1] == 'alr with opencv_core' and
            html.unescape(blocks[1][1]) == text, 'exact authorized landing example mismatch')
    match = blocks[1]
    code = example_code(text, LINKS['index'][0], native_destinations(root, site), landing=True,
                        verified=compiler_destinations(root, site))
    result = home[:match.start()] + '<pre class="ada-example" tabindex="0">' + code + '</pre>' + home[match.end():]
    return result.replace('<body>', f'<link rel="stylesheet" href="{STYLESHEET}"><body>', 1).encode()
