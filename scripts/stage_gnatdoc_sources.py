#!/usr/bin/env python3
"""Stage exact public inputs: GNATdoc excludes the separate internal project.

v0.1.2 scans source directories recursively and has no exclusion option. Keep
the original src/*.ads paths and bytes, but never authorize src/internal units.
The destination is a fixed disposable documentation-only directory.
"""
import shutil
from pathlib import Path

from link_gnatdoc_types import sources, require
from verify_core_enhancer import record, AUTHORED_SHA


def stage(root):
    destination = root / 'obj/docs/enhancer-input'
    require(not destination.is_symlink(), 'symlink documentation input root')
    if destination.exists():
        shutil.rmtree(destination)
    (destination / 'src').mkdir(parents=True)
    inventory = sources(root / 'src')
    require(len(inventory) == 195, 'public source inventory changed')
    for path in sorted((root / 'src').glob('*.ads')):
        require(not path.is_symlink(), 'symlink public specification')
        shutil.copyfile(path, destination / 'src' / path.name)
    (destination / 'docs').mkdir(exist_ok=True)
    shutil.copyfile(root / 'docs/gnatdoc-enhancer.toml', destination / 'docs/gnatdoc-enhancer.toml')
    shutil.copytree(root / 'docs/enhancer-qualification', destination / 'docs/enhancer-qualification')
    authored = record('gnatdoc-authored.json', AUTHORED_SHA)
    for name in authored['inputs']:
        source = root / name
        require(source.resolve().is_relative_to(root) and not any(p.is_symlink() for p in (source, *source.parents)),
                'unsafe authored source')
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    print('Staged 195 exact public specifications and hash-bound authored inputs')


if __name__ == '__main__':
    stage(Path(__file__).resolve().parent.parent)