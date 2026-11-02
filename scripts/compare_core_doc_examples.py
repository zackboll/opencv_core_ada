#!/usr/bin/env python3
"""Record the authenticated historical/candidate comparison after reconstruction."""
import json
from pathlib import Path

from link_gnatdoc_types import require
from verify_core_enhancer import (validate, digest, record, HISTORICAL_SHA,
                                  EXAMPLE_CHANGES)
from verify_core_examples import STYLESHEET
from core_verified_examples import compiler_destinations, staged_config, PUBLIC
from acquire_core_doc_v014 import ARCHIVE_SHA, ARTIFACT, RUN
from verify_core_enhancer import EXAMPLES_SHA

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
    compare_v014(site)


def compare_v014(site):
    directory = ROOT / 'obj/docs/v014'
    require(digest((directory / 'publication.zip').read_bytes()) == ARCHIVE_SHA,
            'v0.1.4 authenticated archive changed')
    before = {p.relative_to(directory / 'publication').as_posix(): digest(p.read_bytes())
              for p in (directory / 'publication').rglob('*') if p.is_file()}
    require(before == record('examples-publication-inventory.json', EXAMPLES_SHA),
            'v0.1.4 authenticated publication changed')
    after = {p.relative_to(site).as_posix(): digest(p.read_bytes()) for p in site.rglob('*') if p.is_file()}
    changed = {name for name in before.keys() & after.keys() if before[name] != after[name]}
    require(before.keys() == after.keys() and changed == {'index.html', 'api/presentation.json'},
            'unexpected v0.1.4 adoption publication delta')
    candidate = (site / 'index.html').read_text()
    for call in compiler_destinations(ROOT, site):
        anchor = f'<a class="ada-api-reference" href="api/{call["href"]}">{call["text"]}</a>'
        require(candidate.count(anchor) == 1, 'missing/duplicate authenticated homepage call')
        candidate = candidate.replace(anchor, call['text'])
    require(candidate.encode() == (directory / 'publication/index.html').read_bytes(),
            'homepage differs beyond four authenticated call wrappers')
    previous = json.loads((directory / 'publication/api/presentation.json').read_bytes())
    current = json.loads((site / 'api/presentation.json').read_bytes())
    require(previous.keys() == current.keys(), 'unexpected presentation metadata fields')
    normalized = json.loads(json.dumps(current))
    normalized['enhancer_version'] = '0.1.4'
    normalized['source_sha256'] = {n.replace(PUBLIC + '/', 'src/', 1): v
                                   for n, v in current['source_sha256'].items()}
    require(normalized['source_sha256'] == previous['source_sha256'], 'public export identity drift')
    require(current['theme_source']['config_sha256'] == digest(staged_config(ROOT)),
            'staged configuration identity differs')
    normalized['theme_source']['config_sha256'] = previous['theme_source']['config_sha256']
    normalized['output_sha256']['index.html'] = previous['output_sha256']['index.html']
    require(normalized == previous, 'unexplained presentation metadata delta')
    result = {'baseline_run': RUN, 'baseline_artifact': ARTIFACT, 'archive_sha256': ARCHIVE_SHA,
              'baseline_files': len(before), 'candidate_files': len(after),
              'changed': {n: {'before': before[n], 'after': after[n]} for n in sorted(changed)},
              'unchanged_files': len(before) - len(changed), 'added': [], 'removed': [],
              'homepage_change': 'Exactly four independently reconstructed call anchor wrappers',
              'metadata_changes': ['enhancer_version', 'public source path prefix',
                                   'staged configuration hash', 'homepage output hash']}
    (ROOT / 'obj/docs/v015-publication-comparison.json').write_text(json.dumps(result, indent=2) + '\n')
    print('v0.1.4 comparison: 210 files; exactly 2 justified changes; 208 byte-identical files')


if __name__ == '__main__':
    compare()
