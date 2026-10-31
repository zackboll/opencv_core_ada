#!/bin/sh
# Released wheel only; documentation dependencies never enter the Alire crate.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
python=${DOC_BOOTSTRAP_PYTHON:-python3}
"$python" -c 'import sys; assert sys.version_info[:2] in ((3,11),(3,12),(3,13)), "supported documentation Python required"'
mkdir -p .doc-tools/enhancer-release
release="$root/.doc-tools/enhancer-release"
base=https://github.com/zackboll/ada-gnatdoc-enhancer/releases/download/v0.1.4
wheel=ada_gnatdoc_enhancer-0.1.4-py3-none-any.whl
for asset in "$wheel" SHA256SUMS release-provenance.json; do
    curl --fail --location --output "$release/$asset" "$base/$asset"
done
test "$(sha256sum "$release/SHA256SUMS" | cut -d ' ' -f 1)" = 351eef92c834fde9cc65948a4ca3db27cd4c42f681c3e3537a057a2a09f9cbf0
(cd "$release" && sha256sum --check --ignore-missing SHA256SUMS)
test "$(sha256sum "$release/release-provenance.json" | cut -d ' ' -f 1)" = f9d99604808efc5bb9bc4274c36ef8a387250649269d45a92d0ed8a5efcced9c
test "$(sha256sum "$release/$wheel" | cut -d ' ' -f 1)" = 057b7945a71d3afb10cbabec32111b4ac2d94a116c6b8553f70c71229a68ffc7
"$python" -c 'import json,sys; from pathlib import Path; d=json.loads(Path(sys.argv[1]).read_text()); assert d["release_version"] == "0.1.4" and d["expected_source_commit"] == "2200eb0e95e769a70d3d38a6c8b7facce8205924" and d["expected_source_tree"] == "a0c1038b8332c3ff040b678d393f2871e7d5eeb4"' "$release/release-provenance.json"
"$python" -m venv .doc-tools/enhancer
.doc-tools/enhancer/bin/python -m pip install --no-index --force-reinstall --no-deps "$release/$wheel"
.doc-tools/enhancer/bin/python -m pip install -r docs/requirements.txt
test "$(.doc-tools/enhancer/bin/gnatdoc-enhancer --version)" = 0.1.4
.doc-tools/enhancer/bin/python -c 'from importlib.metadata import distribution; import json; d=distribution("ada-gnatdoc-enhancer"); assert d.version == "0.1.4"; u=json.loads(d.read_text("direct_url.json")); assert not u.get("dir_info") and u["url"].endswith("/ada_gnatdoc_enhancer-0.1.4-py3-none-any.whl"); assert u.get("archive_info", {}).get("hashes", {}).get("sha256") == "057b7945a71d3afb10cbabec32111b4ac2d94a116c6b8553f70c71229a68ffc7"'