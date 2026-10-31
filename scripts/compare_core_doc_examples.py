#!/usr/bin/env python3
"""Record the authenticated historical/candidate comparison after reconstruction."""
import json
from pathlib import Path

from link_gnatdoc_types import require
from verify_core_enhancer import (validate, digest, record, HISTORICAL_SHA,
                                  EXAMPLE_CHANGES)
from verify_core_examples import STYLESHEET

ROOT = Path(__file__).resolve().parent.parent


def compare():
    site = ROOT / '_site'
    validate(site)
    historical = record('search-publication-inventory.json', HISTORICAL_SHA)
    directory = ROOT / 'obj/docs/historical'
    artifact = json.loads((directory / 'artifact.json').read_text())
    require(artifact['id'] == 13028630518 and
            artifact['workflow_run']['id'] == 41163519341 and
            artifact['digest'] == 'sha256:23d770643d04386fdc199b57e6a8ebd738a95963c253798f699c0e1ed1b98835',
            'historical artifact identity differs')
    require(digest((directory / 'publication.zip').read_bytes()) == artifact['digest'][7:],
            'historical archive digest differs')
    before = {p.relative_to(directory / 'publication').as_posix(): digest(p.read_bytes())
              for p in (directory / 'publication').rglob('*') if p.is_file()}
    require(before == historical, 'authenticated publication differs from reviewed baseline')
    after = {p.relative_to(site).as_posix(): digest(p.read_bytes())
             for p in site.rglob('*') if p.is_file()}
    changed = {name: {'before': before[name], 'after': after[name]}
               for name in sorted(before.keys() & after.keys()) if before[name] != after[name]}
    require(changed.keys() == EXAMPLE_CHANGES and after.keys() - before.keys() == {STYLESHEET}
            and not before.keys() - after.keys(), 'unexpected publication delta')
    result = {
        'historical_run': 41163519341, 'historical_artifact': artifact['id'],
        'historical_archive_sha256': artifact['digest'][7:],
        'baseline_files': len(before), 'candidate_files': len(after),
        'added': sorted(after.keys() - before.keys()), 'removed': [], 'changed': changed,
        'unchanged': {name: before[name] for name in sorted(before) if name not in changed}}
    (ROOT / 'obj/docs/examples-publication-comparison.json').write_text(
        json.dumps(result, sort_keys=True, indent=2) + '\n')
    print(f'Historical comparison: {len(before)} -> {len(after)} files; '
          f'{len(changed)} authorized changes; {len(result["unchanged"])} byte-identical resources')


if __name__ == '__main__':
    compare()
