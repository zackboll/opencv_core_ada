#!/usr/bin/env python3
"""Render only approved guides; reconstruct expected bytes for validation.

Markdown syntax belongs to markdown-it-py, not to a repository parser. Token
inspection enforces our narrower publishing contract before HTML is emitted.
No manifest can authorize content, destinations, or assets.
"""
import html
import re
import sys
from importlib.metadata import version
from pathlib import Path
from urllib.parse import quote, unquote, urlsplit

from markdown_it import MarkdownIt
from link_gnatdoc_types import Source

GUIDES = {
    'ownership-and-views': ('Ownership and views', ('OpenCV.Core', 'OpenCV.Core.Transfers')),
    'typed-access-guide': ('Typed access guide', ('OpenCV.Core.UInt8_Access', 'OpenCV.Core.Float16_Vec2_Access')),
    'core-operations-guide': ('Core operations guide', ('OpenCV.Core',)),
    'sparse-and-persistence-guide': ('Sparse matrices and persistence', ('OpenCV.Core.Sparse', 'OpenCV.Core.Persistence')),
    'interop-and-compatibility': ('Interoperability, compatibility and contributor architecture', ('OpenCV.Core.Module_Interop', 'OpenCV.Core.Transfers')),
}
GITHUB = 'https://github.com/zackboll/opencv_core_ada/blob/main/'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def slug(text):
    return re.sub(r'[^\w\- ]', '', text.lower()).replace(' ', '-')


def markdown(source, rewrite=None):
    require(version('markdown-it-py') == '3.0.0' and version('mdurl') == '0.1.2',
            'unqualified Markdown dependency version')
    parser = MarkdownIt('commonmark', {'html': True}).enable('table')
    # Do not let the renderer silently demote unsafe links to plain text.
    # All destinations must reach our rejecting policy before rendering.
    parser.validateLink = lambda destination: True
    tokens = parser.parse(source)
    headings, level = [], 0
    for i, token in enumerate(tokens):
        require(token.type not in ('html_block', 'html_inline', 'image'),
                'unsupported raw HTML or image')
        if token.type == 'fence':
            # CommonMark accepts EOF as an implicit close; our source contract does not.
            lines = source.splitlines()
            end = token.map[1] - 1
            require(end > token.map[0] and re.fullmatch(
                r' {0,3}' + re.escape(token.markup[0]) +
                '{' + str(len(token.markup)) + r',}\s*', lines[end]) is not None,
                'unclosed Markdown fence')
            require(token.info.strip() in ('ada', 'sh', 'shell', 'text', ''),
                    'unsupported fenced-code language')
        if token.type == 'heading_open':
            current = int(token.tag[1:])
            require(current <= level + 1 and (current != 1 or not headings),
                    'invalid heading hierarchy')
            level = current
            inline = tokens[i + 1]
            text = ''.join(t.content for t in inline.children
                           if t.type in ('text', 'code_inline'))
            identity = slug(text)
            require(identity, 'empty heading identity')
            base, suffix = identity, 0
            while identity in headings:
                suffix += 1
                identity = f'{base}-{suffix}'
            headings.append(identity)
            token.attrSet('id', identity)
        for child in token.children or []:
            require(child.type not in ('html_inline', 'image'), 'unsupported raw HTML or image')
            if child.type == 'link_open' and rewrite:
                child.attrSet('href', rewrite(child.attrGet('href')))
    require(headings and tokens[0].type == 'heading_open' and tokens[0].tag == 'h1',
            'guide must begin with one document title')
    rendered = parser.renderer.render(tokens, parser.options, {})
    # A scroll container keeps wide tables local without altering any cells.
    rendered = rendered.replace('<table>', '<div class="table-scroll" tabindex="0" role="region" aria-label="Scrollable table"><table>')
    rendered = rendered.replace('</table>', '</table></div>')
    return rendered, headings


def heading_inventory(root):
    result = {}
    for name, (title, _) in GUIDES.items():
        path = root / f'docs/{name}.md'
        require(not path.is_symlink() and not path.parent.is_symlink(),
                f'unsafe authoritative source: {name}')
        source = path.read_text(encoding='utf-8')
        require(source.splitlines()[0] == '# ' + title, f'wrong title: {name}')
        result[name] = markdown(source)[1]
    return result


def resolve_link(root, name, link, headings):
    require(not re.search(r'[\x00-\x20\\]', link), f'unsafe link: {link}')
    url = urlsplit(link)
    require(not url.query, f'unexpected query: {link}')
    if url.scheme:
        require(url.scheme == 'https' and url.hostname in
                ('github.com', 'zackboll.github.io') and not url.username and
                not url.password, f'unapproved external scheme: {link}')
        return link
    require(not url.netloc and not url.path.startswith('/'), f'unsafe path: {link}')
    path = unquote(url.path)
    require('%' not in path and '\\' not in path, f'encoded path: {link}')
    if not path:
        require(url.fragment in headings[name], f'missing local heading: {link}')
        return '#' + url.fragment
    # Only the two source-backed parent paths present in these guides are approved.
    require(not any(p in ('.', '..') for p in Path(path).parts) or
            path == '../README.md' or
            re.fullmatch(r'\.\./tests/probes/[A-Za-z0-9_-]+\.md', path),
            f'unapproved parent reference: {link}')
    target = (root / 'docs' / path).resolve()
    source_path = root / 'docs' / path
    require(not any(p.is_symlink() for p in (source_path, *source_path.parents)),
            f'symlink source path: {link}')
    require(target.is_relative_to(root.resolve()) and target.is_file() and
            not (root / 'docs' / path).is_symlink(), f'missing/unsafe source: {link}')
    published = target.parent == root / 'docs' and target.stem in GUIDES
    if url.fragment:
        ids = headings[target.stem] if published else markdown(target.read_text())[1]
        require(url.fragment in ids, f'missing source heading: {link}')
    fragment = '#' + url.fragment if url.fragment else ''
    if published:
        return target.stem + '.html' + fragment
    return GITHUB + quote(target.relative_to(root).as_posix()) + fragment


def packages(root, site):
    authoritative = {Source(p).package for p in (root / 'src').glob('*.ads')}
    result = {}
    for path in sorted((site / 'api').glob('*.html')):
        match = re.search(r'<h1>([^<]+)</h1>', path.read_text())
        if match:
            require(match[1].lower() in authoritative, 'API heading not backed by Ada source')
            require(match[1] not in result, 'duplicate native package heading')
            result[match[1]] = path.name
    for _, identities in GUIDES.values():
        for identity in identities:
            require(identity in result, f'missing native package: {identity}')
    return result


def expected(root, site):
    root, site = root.resolve(), site.resolve()
    headings = heading_inventory(root)
    api = packages(root, site)
    outputs = {'gnatdoc-guides.css': (root / 'docs/assets/gnatdoc-guides.css').read_bytes()}
    for name, (title, identities) in GUIDES.items():
        source = (root / f'docs/{name}.md').read_text(encoding='utf-8')
        content, _ = markdown(source, lambda link: resolve_link(root, name, link, headings))
        nav = '\n'.join(f'<li><a href="{other}.html"' +
                        (' aria-current="page"' if other == name else '') +
                        f'>{html.escape(label)}</a></li>' for other, (label, _) in GUIDES.items())
        entries = '\n'.join(f'<li><a href="../api/{api[identity]}">{identity}</a></li>'
                            for identity in identities)
        page = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} — OpenCV Core Ada</title>
<link rel="stylesheet" href="../api/gnatdoc-theme.css">
<link rel="stylesheet" href="gnatdoc-guides.css">
</head>
<body>
<a class="skip-link" href="#main-content">Skip to content</a>
<header><nav aria-label="Documentation"><a href="../index.html">Documentation home</a> · <a href="../api/index.html">GNATdoc API browser</a></nav></header>
<div class="guide-layout">
<nav class="guide-nav" aria-label="Developer guides"><ul>
{nav}
</ul></nav>
<main id="main-content">
{content}
<section aria-label="Native API entry points"><h2 id="native-api-entry-points">Native API entry points</h2><ul>
{entries}
</ul></section>
<p class="guide-source"><a href="{GITHUB}docs/{name}.md">Original Markdown source on GitHub</a></p>
</main>
</div>
</body>
</html>
'''
        require('native-api-entry-points' not in headings[name] and
                'main-content' not in headings[name], 'reserved heading identity')
        outputs[name + '.html'] = page.encode('utf-8')
    return outputs


def generate(root, site):
    outputs = expected(root, site)
    directory = site / 'guides'
    require(not directory.is_symlink(), 'unsafe guide output directory')
    directory.mkdir(exist_ok=True)
    require({p.name for p in directory.iterdir()} <= outputs.keys(), 'unapproved guide files')
    for name, content in outputs.items():
        require(not (directory / name).is_symlink(), 'unsafe output file')
        (directory / name).write_bytes(content)
    validate(root, site)


def validate(root, site):
    outputs = expected(root, site)
    directory = site / 'guides'
    require(directory.is_dir() and not directory.is_symlink(), 'missing/unsafe guide directory')
    require({p.name for p in directory.iterdir()} == outputs.keys(), 'guide inventory mismatch')
    for name, content in outputs.items():
        require(not (directory / name).is_symlink() and
                (directory / name).read_bytes() == content,
                f'authoritative guide/stylesheet mismatch: {name}')
    print('Guides: 5 authoritative pages; exact content, links and stylesheet verified')


if __name__ == '__main__':
    require(len(sys.argv) == 2, 'usage: render_gnatdoc_guides.py SITE_DIRECTORY')
    generate(Path(__file__).resolve().parent.parent, Path(sys.argv[1]))