#!/usr/bin/env python3
"""Separate the 195 public exports from original-path compiler-only evidence.

The released enhancer scans only public/ recursively. The separate src/ tree
authenticates compiler evidence, including internal units, but is not inventoried.
The destination is a fixed disposable documentation-only directory.
"""
import shutil
from pathlib import Path

from link_gnatdoc_types import sources, require
from verify_core_enhancer import record, AUTHORED_SHA, THEME_SOURCE, ASSETS, digest
from core_verified_examples import PUBLIC, selected_mapping, staged_config, regular


def stage(root):
    destination = root / 'obj/docs/enhancer-input'
    require(not destination.is_symlink(), 'symlink documentation input root')
    if destination.exists():
        shutil.rmtree(destination)
    (destination / PUBLIC).mkdir(parents=True)
    inventory = sources(root / 'src')
    require(len(inventory) == 195, 'public source inventory changed')
    for path in sorted((root / 'src').glob('*.ads')):
        require(not path.is_symlink(), 'symlink public specification')
        shutil.copyfile(path, destination / PUBLIC / path.name)
    (destination / 'docs').mkdir(exist_ok=True)
    (destination / 'docs/gnatdoc-enhancer.toml').write_bytes(staged_config(root))
    shutil.copytree(root / 'docs/enhancer-qualification', destination / 'docs/enhancer-qualification')
    shutil.copytree(root / 'docs/verified-examples', destination / 'docs/verified-examples')
    authored = record('gnatdoc-authored.json', AUTHORED_SHA)
    require(digest((root / THEME_SOURCE).read_bytes()) == ASSETS['gnatdoc-theme.css'],
            'unreviewed Core theme source')
    for name in [*authored['inputs'], THEME_SOURCE]:
        source = root / name
        require(source.resolve().is_relative_to(root) and not any(p.is_symlink() for p in (source, *source.parents)),
                'unsafe authored source')
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    (mapping_name, _), mapping = selected_mapping(root)
    # The original src/internal and project paths authenticate compiler evidence,
    # while only public/ is recursively scanned for publishable packages.
    for name in [mapping_name, *mapping['inputs']]:
        source = regular(root, name)
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    require(len(list((destination / PUBLIC).rglob('*.ads'))) == 195, 'public staging inventory changed')
    selected_mapping(destination)
    print(f'Staged 195 public specifications; {len(mapping["inputs"])} separate compiler inputs; {mapping_name}')


if __name__ == '__main__':
    stage(Path(__file__).resolve().parent.parent)