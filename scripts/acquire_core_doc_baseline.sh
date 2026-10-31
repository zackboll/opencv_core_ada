#!/bin/sh
# Authenticated historical comparison input; never substitute a local cache.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
directory=obj/docs/historical
mkdir -p "$directory"
gh api repos/zackboll/opencv_core_ada/actions/runs/41163519341 > "$directory/run.json"
gh api repos/zackboll/opencv_core_ada/actions/artifacts/13028630518 > "$directory/artifact.json"
python3 - "$directory" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
run = json.loads((root / 'run.json').read_text())
asset = json.loads((root / 'artifact.json').read_text())
assert run['id'] == 41163519341 and run['conclusion'] == 'success'
assert run['head_sha'] == '75e170c5b78b21aff14f0145a7d3d2e9df99a62e'
assert asset['id'] == 13028630518 and not asset['expired']
assert asset['workflow_run']['id'] == run['id']
assert asset['workflow_run']['head_sha'] == run['head_sha']
assert asset['name'] == 'ada-api-' + run['head_sha']
assert asset['digest'] == 'sha256:23d770643d04386fdc199b57e6a8ebd738a95963c253798f699c0e1ed1b98835'
PY
gh api repos/zackboll/opencv_core_ada/actions/artifacts/13028630518/zip > "$directory/publication.zip"
test "$(sha256sum "$directory/publication.zip" | cut -d ' ' -f 1)" = 23d770643d04386fdc199b57e6a8ebd738a95963c253798f699c0e1ed1b98835
python3 - "$directory" <<'PY'
import hashlib, json, sys, zipfile
from pathlib import Path
root = Path(sys.argv[1])
policy = Path('docs/enhancer-qualification/search-publication-inventory.json').read_bytes()
assert hashlib.sha256(policy).hexdigest() == '100af3824ee113bf1e58e166501d3fba2141bdb4386540cf1d768f2df3812851'
expected = json.loads(policy)
with zipfile.ZipFile(root / 'publication.zip') as archive:
    assert len(archive.namelist()) == len(set(archive.namelist())) == 209
    assert {name: hashlib.sha256(archive.read(name)).hexdigest()
            for name in archive.namelist()} == expected
    output = root / 'publication'
    assert not output.exists(), 'historical input must be freshly acquired'
    archive.extractall(output)
print('Authenticated historical publication: 209 files; all reviewed hashes match')
PY
