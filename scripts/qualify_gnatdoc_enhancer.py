#!/usr/bin/env python3
"""Explicit acquisition of reviewable enhancer inputs, never a generation step.

Run after independent native/legacy acquisition. Review the emitted records and
their hashes before copying them into docs/ and changing consumer policy.
No enhancer implementation is used to authorize instances or authored inputs.
"""
import argparse
import hashlib
import json
from pathlib import Path
from urllib.parse import urlsplit

from enhance_gnatdoc_instances import discover, title
from link_gnatdoc_types import sources, pages_and_targets
from render_gnatdoc_guides import GUIDES, GITHUB, markdown


def hashes(directory):
    return {p.relative_to(directory).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(directory.rglob('*')) if p.is_file()}


def acquire(root, native, output):
    from markdown_it import MarkdownIt
    source = sources(root / 'src')
    pages, _ = pages_and_targets(native / 'api', source)
    if len(pages) != 195 or set(pages) != set(source):
        raise ValueError('incomplete independently acquired public inventory')
    instances = discover(source)
    if len(instances) != 25:
        raise ValueError('unexpected generic inventory')
    inputs = {'docs/index.html', 'docs/assets/gnatdoc-guides.css', 'docs/example.adb',
              'docs/example.gpr', *(f'docs/{name}.md' for name in GUIDES)}
    links = {}
    parser = MarkdownIt('commonmark').enable('table')
    for name in GUIDES:
        text = (root / f'docs/{name}.md').read_text()
        markdown(text)
        for token in parser.parse(text):
            for child in token.children or []:
                if child.type != 'link_open':
                    continue
                link = child.attrGet('href')
                url = urlsplit(link)
                if url.scheme or not url.path:
                    continue
                path = (root / 'docs' / url.path).resolve()
                if path.parent == root / 'docs' and path.stem in GUIDES:
                    continue
                relative = path.relative_to(root).as_posix()
                inputs.add(relative)
                links[link] = {'source': relative, 'url': GITHUB + relative +
                               ('#' + url.fragment if url.fragment else '')}
    native_hashes = hashes(native)
    generic = {
        'schema_version': 1,
        'instances': {key: {'package': title(source[key]), 'template': template,
                            'element_type': element,
                            'element_owner': 'opencv.core' if element == 'Float16_Value' else 'opencv',
                            'dimensions': dimensions}
                      for key, (template, element, dimensions) in instances.items()},
        'source_sha256': {f'src/{p.name}': hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in sorted((root / 'src').glob('*.ads'))},
        'native_sha256': native_hashes}
    authored = {
        'schema_version': 2, 'home': {'source': 'docs/index.html', 'path': 'index.html'},
        'stylesheet': {'source': 'docs/assets/gnatdoc-guides.css', 'path': 'guides/gnatdoc-guides.css'},
        'guides': [{'id': name, 'label': label, 'source': f'docs/{name}.md',
                    'path': f'guides/{name}.html', 'entry_points': list(entries)}
                   for name, (label, entries) in GUIDES.items()],
        'inputs': {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in inputs},
        'native_sha256': native_hashes, 'site_map': None, 'anchors': None, 'groups': [],
        'examples': [], 'languages': ['ada', 'sh', 'shell', 'text', ''],
        'source_links': links, 'attribution_base': GITHUB, 'title_suffix': 'OpenCV Core Ada',
        'api_label': 'GNATdoc API browser', 'source_inventory': None,
        'landing_example': 'docs/example.adb', 'ada_policy': 'source-text',
        'example_project': None, 'landing_project': 'docs/example.gpr',
        'directory_pages': [], 'renderer_exceptions': []}
    output.mkdir(parents=True, exist_ok=False)
    for name, record in [('gnatdoc-generic-qualification.json', generic),
                         ('gnatdoc-authored.json', authored)]:
        payload = (json.dumps(record, indent=2, sort_keys=True) + '\n').encode()
        (output / name).write_bytes(payload)
        print(hashlib.sha256(payload).hexdigest(), name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    acquire(Path(__file__).resolve().parent.parent, args.native, args.output)