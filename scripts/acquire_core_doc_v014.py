#!/usr/bin/env python3
"""Authenticate the exact-main v0.1.4 publication; never accept a cache substitute."""
import json
from pathlib import Path
import subprocess
import zipfile

from verify_core_enhancer import record, EXAMPLES_SHA, digest
from link_gnatdoc_types import require

ROOT = Path(__file__).resolve().parent.parent
RUN = 41245425725
ARTIFACT = 13059214885
COMMIT = 'dbdb410c0d86b640271733d7b999ede5a5f92267'
ARCHIVE_SHA = '247967ff696da66ea9d791b4584c4901adabe19c7e691d65a07234911d699334'


def acquire():
    directory = ROOT / 'obj/docs/v014'
    directory.mkdir(parents=True, exist_ok=True)
    for name, endpoint in [('run', f'actions/runs/{RUN}'), ('artifact', f'actions/artifacts/{ARTIFACT}')]:
        payload = subprocess.check_output(['gh', 'api', 'repos/zackboll/opencv_core_ada/' + endpoint])
        (directory / (name + '.json')).write_bytes(payload)
    run = json.loads((directory / 'run.json').read_bytes())
    artifact = json.loads((directory / 'artifact.json').read_bytes())
    require(run['id'] == RUN and run['head_sha'] == COMMIT and run['conclusion'] == 'success',
            'unqualified v0.1.4 exact-main run')
    require(artifact['id'] == ARTIFACT and not artifact['expired'] and
            artifact['workflow_run']['id'] == RUN and artifact['workflow_run']['head_sha'] == COMMIT and
            artifact['name'] == 'ada-api-' + COMMIT and artifact['digest'] == 'sha256:' + ARCHIVE_SHA,
            'unqualified v0.1.4 artifact')
    payload = subprocess.check_output(['gh', 'api',
        f'repos/zackboll/opencv_core_ada/actions/artifacts/{ARTIFACT}/zip'])
    require(digest(payload) == ARCHIVE_SHA, 'v0.1.4 archive digest mismatch')
    archive_path = directory / 'publication.zip'
    archive_path.write_bytes(payload)
    expected = record('examples-publication-inventory.json', EXAMPLES_SHA)
    with zipfile.ZipFile(archive_path) as archive:
        require(len(archive.namelist()) == len(set(archive.namelist())) == 210 and
                {name: digest(archive.read(name)) for name in archive.namelist()} == expected,
                'v0.1.4 publication inventory mismatch')
        output = directory / 'publication'
        require(not output.exists(), 'v0.1.4 input must be freshly acquired')
        archive.extractall(output)
    print('Authenticated v0.1.4 exact-main publication: 210 reviewed files')


if __name__ == '__main__':
    acquire()