#!/usr/bin/env python3
"""Core-owned publication oracle. Never imports the enhancer implementation.

Native bytes are bound to reviewed acquisition hashes, not output metadata.
The retained legacy source parser, linker, highlighter, instance renderer and
guide renderer independently reconstruct public semantics. Toolkit metadata,
CSS and router are separately reviewed, checksum-bound presentation contracts.
"""
import hashlib
import html
import json
import re
import argparse
from collections import Counter
from pathlib import Path

from link_gnatdoc_types import (SECTION, LINK, sources, pages_and_targets, render,
                               plain, require)
from highlight_gnatdoc_ada import strip_highlighting, highlight
from enhance_gnatdoc_instances import (discover, qualified_instances, render as summary,
                                      native_instance, VECTORS, title)
from enhance_gnatdoc_navigation import native_index, symbol_navigation, CONTROL
from install_gnatdoc_theme import NATIVE, METADATA
from render_gnatdoc_guides import validate as check_guides, GUIDES

ROOT = Path(__file__).resolve().parent.parent
QUALIFICATION = ROOT / 'docs/enhancer-qualification'
GENERIC_SHA = '146a6f6375be14788996e04585ac141bfc308c5be87b040198f5d74c5c74bcfc'
AUTHORED_SHA = '97a3351cbe0f852d5aeddea64fcffab9f66fdf56499b717caab82d06e9f67b65'
ASSETS = {
    'gnatdoc-theme.css': 'cf06637732a8b047a7191bfb991a5c3da7cd31a52076876880d5f8a3f63929bc',
    'gnatdoc-navigation.js': '97dcc75055842e98a6294809b8e8c4e7436a427039d19c8afb6fdd1ca21ea310',
}


def digest(payload):
    return hashlib.sha256(payload).hexdigest()


def record(name, expected):
    payload = (QUALIFICATION / name).read_bytes()
    require(digest(payload) == expected, 'unreviewed Core qualification record')
    return json.loads(payload)


def is_enhancer(api):
    path = api / 'presentation.json'
    return path.is_file() and json.loads(path.read_text()).get('enhancer_version') == '0.1.1'


def validate(site):
    api = site / 'api'
    acquisition = record('gnatdoc-generic-qualification.json', GENERIC_SHA)
    authored = record('gnatdoc-authored.json', AUTHORED_SHA)
    for name, sha in {**acquisition['source_sha256'], **authored['inputs']}.items():
        require(digest((ROOT / name).read_bytes()) == sha, f'authoritative input changed: {name}')
    source = sources(ROOT / 'src')
    pages, targets = pages_and_targets(api, source)
    require(len(pages) == 195 and set(pages) == set(source), 'public inventory mismatch')
    instances = discover(source)
    require(instances == qualified_instances(), 'changed instance associations')
    manifest = json.loads((api / 'presentation.json').read_text())
    require(manifest.get('enhancer_version') == '0.1.1', 'wrong enhancer version')
    require(set(manifest) == {'schema_version', 'enhancer_version', 'gnatdoc_version', 'project',
                             'original_api_html', 'native_css_sha256', 'source_sha256', 'output_sha256', 'counts'}
            and manifest['schema_version'] == 1 and manifest['gnatdoc_version'] == '26.0.0'
            and manifest['project'] == 'OpenCV Core Ada', 'unapproved presentation metadata')
    require(manifest['source_sha256'] == acquisition['source_sha256'] and
            manifest['native_css_sha256'] == acquisition['native_sha256']['api/gnatdoc.css'],
            'presentation input identities mismatch')
    originals = manifest['original_api_html']
    require(set(originals) | {'api/gnatdoc.css'} == set(acquisition['native_sha256']),
            'native acquisition inventory mismatch')
    for name, text in originals.items():
        require(digest(text.encode()) == acquisition['native_sha256'][name],
                f'original native bytes changed: {name}')
    require(digest((api / 'gnatdoc.css').read_bytes()) == acquisition['native_sha256']['api/gnatdoc.css'],
            'native stylesheet changed')
    for name, sha in ASSETS.items():
        require(digest((api / name).read_bytes()) == sha, f'unreviewed asset: {name}')
    # Explanatory targets remain separate from native type destinations.
    for key, (template, _, _) in instances.items():
        targets[key + ('.vector' if template == VECTORS else '.matrix')] = (
            pages[key][0].name, 'instance-members-summary')
    total = links = summaries = 0
    incoming = Counter()
    for key, (path, current, sections) in pages.items():
        original = originals['api/' + path.name]
        native_sections = list(SECTION.finditer(original))
        require(len(native_sections) == len(sections), 'fabricated/missing native declaration')
        replacements = []
        for before, after in zip(native_sections, sections):
            require((before[1], before[2]) == (after[1], after[2]), 'native heading/anchor changed')
            require(plain(strip_highlighting(after[3])) == before[3], 'native signature changed')
            declaration = source[key].match(before[3])
            expected = render(before[3], key, declaration, source, targets, path.name,
                              Counter(), Counter())
            # Three independently reviewed parent-owned Size references. The
            # legacy resolver conservatively blocks these on a callable name.
            if key == 'opencv.core' and before[2] in ('Create', 'Dimensions', 'Region_Location'):
                filename, anchor = targets['opencv.size']
                expected = re.sub(r'(?<![\w.>])Size\b',
                                  f'<a class="type-reference" href="{filename}#{anchor}" '
                                  'data-type="opencv.size">Size</a>', expected)
            expected = LINK.sub(lambda m: m[0].replace('href="#', f'href="{path.name}#'), expected)
            require(after[3] == highlight(expected), f'type identity/highlighting mismatch: {key}.{before[2]}')
            links += len(LINK.findall(after[3]))
            incoming.update(m[2] for m in LINK.finditer(after[3]) if m[2].endswith(('.vector', '.matrix')))
            replacements.append((before.start(3), before.end(3), after[3]))
            total += 1
        expected = original
        for start, end, replacement in reversed(replacements):
            expected = expected[:start] + replacement + expected[end:]
        if key in instances:
            require(original == native_instance(source[key]), 'native instance introduction changed')
            extra = summary(instances[key], source, pages, targets)
            extra = extra.replace('<p>Generic template:', f'<p>Instance: {title(source[key])}</p><p>Generic template:', 1)
            extra = extra.replace('this generic introduces no native handle.',
                                  'this generic introduces no native handle. Ada array assignment is distinct from OpenCV Mat storage ownership.')
            extra = extra.encode('ascii', 'xmlcharrefreplace').decode('ascii')
            expected = expected.replace('<h2>Description</h2>', extra + '<h2>Description</h2>', 1)
            summaries += 1
        expected = document(expected, title(source[key]) + ' — OpenCV Core Ada')
        require(current == expected, f'native prose/structure/summary changed: {key}')
    index, inventory = native_index(api)
    require(index == originals['api/index.html'], 'native index source/destination mismatch')
    symbols = symbol_navigation(api).replace('id="type-navigation" hidden',
                                            'id="type-navigation" hidden data-default-package="OpenCV.Core"')
    symbol_links = {name.lower(): markup for markup, name in re.findall(
        r'(<a href="[^"]+" data-symbol="([^"]+)"></a>)', symbols)}
    ordered = [symbol_links[d['scope'].lower()]
               for key in sorted(source) for d in source[key].declarations
               if d['scope'].lower() in symbol_links]
    symbols = '<div id="type-navigation" hidden data-default-package="OpenCV.Core">' + ''.join(ordered) + '</div>'
    explanations = '<div id="instance-reference-navigation" hidden>' + ''.join(
        f'<a href="{pages[key][0].name}#instance-members-summary" '
        f'data-instance="{key}.{"vector" if value[0] == VECTORS else "matrix"}"></a>'
        for key, value in sorted(instances.items())) + '</div>'
    index = index.replace('<h2 id=compilation-units>',
                          CONTROL.replace('Search packages', 'Search documentation') + symbols +
                          '<h2 id=compilation-units>', 1)
    # Instance metadata is appended after the standard navigation enhancement.
    index = index.replace('<body class=main>',
                          '<script src="gnatdoc-navigation.js" defer></script><body class=main>', 1)
    index = index.replace('<h2 id=compilation-units>', explanations + '<h2 id=compilation-units>', 1)
    require((api / 'index.html').read_text() == document(index, 'API Reference — OpenCV Core Ada'),
            'navigation shell/source destinations changed')
    require((total, links, summaries) == (1293, 2758, 25), 'Core declaration/link/summary baseline mismatch')
    require(incoming == Counter({key + ('.vector' if v[0] == VECTORS else '.matrix'):
                                 10 if v[0] == VECTORS else 2 for key, v in instances.items()}),
            'incoming instance-reference mismatch')
    check_guides(ROOT, site)
    require((site / 'index.html').read_bytes() == (ROOT / 'docs/index.html').read_bytes(), 'landing changed')
    names = set(acquisition['native_sha256']) | {'api/presentation.json',
            'api/gnatdoc-theme.css', 'api/gnatdoc-navigation.js', 'index.html',
            'guides/gnatdoc-guides.css', *(f'guides/{name}.html' for name in GUIDES)}
    require({p.relative_to(site).as_posix() for p in site.rglob('*') if p.is_file()} == names,
            'exact publication file inventory mismatch')
    require(not any(p.is_symlink() for p in site.rglob('*')), 'symlink publication')
    require(manifest['output_sha256'] == {
        name: digest((site / name).read_bytes()) for name in names - {'api/presentation.json', 'api/gnatdoc.css'}},
        'presentation output inventory/hash mismatch')
    require(manifest['counts'] == {
        'declaration_snippets': 1293, 'generic_actual_type_links': 25,
        'generic_conversion_package_links': 1, 'generic_member_links': 51,
        'generic_summary_links': 102, 'generic_template_links': 25,
        'linked_external_types': 0, 'linked_local_types': 2758, 'linked_types': 2758,
        'matrix_summaries': 1, 'native_instance_member_declarations': 0,
        'presentation_only_anchors': 25, 'public_packages': 195,
        'qualified_generic_instances': 25, 'unrendered_renderer_exceptions': 0,
        'unsupported_instances': [], 'vector_summaries': 24}, 'publication accounting mismatch')
    print(f'Core independent oracle: {len(inventory)} packages; {total} native sections; '
          f'{links} type links; {summaries} summaries; 242 incoming references; exact publication inventory')
    return inventory


def document(text, label):
    require(text.startswith('<!DOCTYPE html>\n<html class=main>\n'), 'unknown native prologue')
    return text.replace('<html class=main>\n', '<html class=main lang="en">\n<head><meta charset="utf-8">'
                        f'<title>{html.escape(label)}</title>', 1).replace(
                            NATIVE, NATIVE + METADATA, 1).replace('<body ', '</head><body ', 1)


def validate_native(site):
    acquisition = record('gnatdoc-generic-qualification.json', GENERIC_SHA)
    require({p.relative_to(site).as_posix(): digest(p.read_bytes())
             for p in site.rglob('*') if p.is_file()} == acquisition['native_sha256'],
            'pristine native inventory/hash mismatch; independent requalification required')
    source = sources(ROOT / 'src')
    pages, _ = pages_and_targets(site / 'api', source)
    require(set(pages) == set(source) and len(pages) == 195, 'native/source inventory mismatch')
    print('Pristine native/source inventory: 195 packages; reviewed hashes verified')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', required=True, type=Path)
    validate_native(parser.parse_args().native)