#!/bin/sh
# Released wheel only; documentation dependencies never enter the Alire crate.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
python=${DOC_BOOTSTRAP_PYTHON:-python3}
"$python" -c 'import sys; assert sys.version_info[:2] in ((3,11),(3,12),(3,13)), "supported documentation Python required"'
mkdir -p .doc-tools/enhancer-release
release="$root/.doc-tools/enhancer-release"
base=https://github.com/zackboll/ada-gnatdoc-enhancer/releases/download/v0.1.5
wheel=ada_gnatdoc_enhancer-0.1.5-py3-none-any.whl
for asset in "$wheel" SHA256SUMS release-provenance.json; do
    curl --fail --location --output "$release/$asset" "$base/$asset"
done
test "$(sha256sum "$release/SHA256SUMS" | cut -d ' ' -f 1)" = 93e061866d52e13b6266c6fa0efb3b9c2e3a1bd1b4c818981a11a802ded74756
(cd "$release" && sha256sum --check --ignore-missing SHA256SUMS)
test "$(sha256sum "$release/release-provenance.json" | cut -d ' ' -f 1)" = 6c30b7a4ec987ab4f74a44d04586dcd57308dd592ac13f33c9444ef3acf0a8f3
test "$(sha256sum "$release/$wheel" | cut -d ' ' -f 1)" = d712d330f213fc1909a66c47bc2c7e5e15d5ec687222bea3c4922f5243db4247
"$python" -c 'import json,sys; from pathlib import Path; d=json.loads(Path(sys.argv[1]).read_text()); assert d["release_version"] == "0.1.5" and d["expected_source_commit"] == "0120bee2f2455e4c832d1d5ddae0a4cb03cb9477" and d["expected_source_tree"] == "01900ddb099c801eeb92fba718f4c528f87d865f"' "$release/release-provenance.json"
"$python" -m venv .doc-tools/enhancer
.doc-tools/enhancer/bin/python -m pip install --no-index --force-reinstall --no-deps "$release/$wheel"
.doc-tools/enhancer/bin/python -m pip install -r docs/requirements.txt
test "$(.doc-tools/enhancer/bin/gnatdoc-enhancer --version)" = 0.1.5
.doc-tools/enhancer/bin/python -c 'from importlib.metadata import distribution; import json; d=distribution("ada-gnatdoc-enhancer"); assert d.version == "0.1.5"; u=json.loads(d.read_text("direct_url.json")); assert not u.get("dir_info") and u["url"].endswith("/ada_gnatdoc_enhancer-0.1.5-py3-none-any.whl"); assert u.get("archive_info", {}).get("hashes", {}).get("sha256") == "d712d330f213fc1909a66c47bc2c7e5e15d5ec687222bea3c4922f5243db4247"'