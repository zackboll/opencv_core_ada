#!/bin/sh
# Released wheel only; documentation dependencies never enter the Alire crate.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
python=${DOC_BOOTSTRAP_PYTHON:-python3}
"$python" -c 'import sys; assert sys.version_info[:2] in ((3,11),(3,12),(3,13)), "supported documentation Python required"'
mkdir -p .doc-tools/enhancer-release
release="$root/.doc-tools/enhancer-release"
base=https://github.com/zackboll/ada-gnatdoc-enhancer/releases/download/v0.1.2
wheel=ada_gnatdoc_enhancer-0.1.2-py3-none-any.whl
for asset in "$wheel" SHA256SUMS release-provenance.json; do
    curl --fail --location --output "$release/$asset" "$base/$asset"
done
test "$(sha256sum "$release/SHA256SUMS" | cut -d ' ' -f 1)" = 0d7e16b2e932de982d929049db8bd6039ad39fd9f2a9dd791dc3751a127775b4
(cd "$release" && sha256sum --check --ignore-missing SHA256SUMS)
test "$(sha256sum "$release/release-provenance.json" | cut -d ' ' -f 1)" = adc77b4d906f379d71a4d1db2443a529d4fe68e56e2a3c007c591a79f1c16b00
test "$(sha256sum "$release/$wheel" | cut -d ' ' -f 1)" = cb227554bc0c8f1906ba15875306b5fefac103a50d84a876d0fdbd2754e1657e
"$python" -c 'import json,sys; from pathlib import Path; d=json.loads(Path(sys.argv[1]).read_text()); assert d["release_version"] == "0.1.2" and d["source_commit"] == "d7636cc50154ebb5535c699d2bed6406ebc92e62" and d["source_tree"] == "ca7d4d70f2fc556eafe6b222facacadb16fa272a"' "$release/release-provenance.json"
"$python" -m venv .doc-tools/enhancer
.doc-tools/enhancer/bin/python -m pip install --no-deps "$release/$wheel"
.doc-tools/enhancer/bin/python -m pip install -r docs/requirements.txt
test "$(.doc-tools/enhancer/bin/gnatdoc-enhancer --version)" = 0.1.2
.doc-tools/enhancer/bin/python -c 'from importlib.metadata import distribution; import json; d=distribution("ada-gnatdoc-enhancer"); assert d.version == "0.1.2"; u=json.loads(d.read_text("direct_url.json")); assert not u.get("dir_info") and u["url"].endswith(".whl")'