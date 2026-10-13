#!/usr/bin/env python3
"""Fail-closed GNATdoc 26 browser-shell enhancement; hashes are discovered."""
import argparse
import html
import re
from pathlib import Path

from link_gnatdoc_types import sources, pages_and_targets, require

ROOT = Path(__file__).resolve().parent.parent
ASSET = ROOT / 'docs/assets/gnatdoc-navigation.js'
SCRIPT = '<script src="gnatdoc-navigation.js" defer></script>'
CONTROL = ('<div id="package-navigation" hidden><label for="package-search">'
           'Search packages</label><input id="package-search" type="search" '
           'autocomplete="off" spellcheck="false"><button id="package-clear" '
           'type="button">Clear</button><p id="package-results" role="status" '
           'aria-live="polite"></p></div>')
START = '<!DOCTYPE html>\n<html class=main>\n<link rel=stylesheet href=gnatdoc.css><body class=main><div class=side-navigation><ul class=tab-bar><li class=tab><a href=#compilation-units>Compilation Units</a><li class=tab><a href=#tagged-types>Tagged Types</a></ul><div class=content-column><h2 id=compilation-units>Compilation Units</h2><ul>'
MIDDLE = '</ul><h2 id=tagged-types>Tagged types</h2><ul>'
END = '</ul></div></div><div class=document-content><iframe name=document-content></iframe></div>'
TAGGED = ('opencv.core.mat', 'opencv.core.persistence.file_storage',
          'opencv.core.sparse.sparse_mat', 'opencv.core.umat')


def native_index(api):
    """Reconstruct the qualified shell independently of presentation.json.

    Source supplies names, actual h1 headings supply filenames, source-matched
    native declarations supply tagged-type anchors. Exact serialization is a
    deliberate version safety gate, not a generic HTML rewriting engine.
    """
    source_map = sources(ROOT / 'src')
    pages, targets = pages_and_targets(api, source_map)
    require(set(pages) == set(source_map) and len(pages) == 195,
            'incomplete native package inventory')
    inventory = {}
    for identity in sorted(source_map):
        source = source_map[identity]
        name = re.search(r'\bpackage\s+([\w.]+)\s+is\b', source.code, re.I)[1]
        path, text, _ = pages[identity]
        require(re.findall(r'<h1>([^<]+)</h1>', text) == [name],
                'noncanonical native package heading')
        require(re.fullmatch(r'[a-f0-9]{64}\.html', path.name),
                'unsupported native package filename')
        inventory[name] = path.name
    anchors = ''.join(f'<li><a href={href} target=document-content>{name}</a>'
                      for name, href in inventory.items())
    tagged = []
    for identity in TAGGED:
        require(identity in targets, 'missing native tagged declaration')
        filename, anchor = targets[identity]
        owner, _ = identity.rsplit('.', 1)
        section = next(s for s in pages[owner][2] if s[1] == anchor)
        require('tagged' in html.unescape(re.sub(r'<[^>]+>', '', section[3])).lower()
                or 'new Ada.Finalization' in html.unescape(re.sub(r'<[^>]+>', '', section[3])),
                'unsupported tagged declaration')
        name = next(n for n in inventory if n.lower() == owner) + '.' + section[2]
        tagged.append(f'<li><a href={filename}#{anchor} target=document-content>{name}</a>')
    return START + anchors + MIDDLE + ''.join(tagged) + END, inventory


def augmented(text):
    return text.replace('<h2 id=compilation-units>',
                        CONTROL + '<h2 id=compilation-units>', 1).replace(
                            '<body class=main>', SCRIPT + '<body class=main>', 1)


def check_navigation(api):
    from install_gnatdoc_theme import themed
    native, inventory = native_index(api)
    require((api / 'index.html').read_text() == augmented(themed(native)),
            'unapproved navigation shell, links, controls or scripts')
    require((api / 'gnatdoc-navigation.js').read_bytes() == ASSET.read_bytes(),
            'navigation asset differs from repository script')
    return inventory


def enhance(api):
    from install_gnatdoc_theme import themed
    native, _ = native_index(api)
    path = api / 'index.html'
    if path.read_text() == augmented(themed(native)):
        check_navigation(api)
        return
    require(path.read_text() == themed(native), 'unsupported native index structure')
    path.write_text(augmented(themed(native)))
    (api / 'gnatdoc-navigation.js').write_bytes(ASSET.read_bytes())
    check_navigation(api)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('api', type=Path)
    enhance(parser.parse_args().api)