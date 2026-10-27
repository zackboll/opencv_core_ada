#!/bin/sh
# Released wheel only; documentation dependencies never enter the Alire crate.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
python=${DOC_BOOTSTRAP_PYTHON:-python3}
"$python" -c 'import sys; assert sys.version_info[:2] in ((3,11),(3,12),(3,13)), "supported documentation Python required"'
mkdir -p .doc-tools/enhancer-release
release="$root/.doc-tools/enhancer-release"
base=https://github.com/zackboll/ada-gnatdoc-enhancer/releases/download/v0.1.1
wheel=ada_gnatdoc_enhancer-0.1.1-py3-none-any.whl
for asset in "$wheel" SHA256SUMS release-provenance.json; do
    curl --fail --location --output "$release/$asset" "$base/$asset"
done
test "$(sha256sum "$release/SHA256SUMS" | cut -d ' ' -f 1)" = 7b508545299c7c84ac5a95ec5a164b4e43cad8620574e02b0c78055c5460179b
(cd "$release" && sha256sum --check --ignore-missing SHA256SUMS)
test "$(sha256sum "$release/$wheel" | cut -d ' ' -f 1)" = 8b896683a65623a7e7d626701a4cd68c8b89cb65792f9ffd5525bfa8cfa257ab
"$python" -c 'import json,sys; from pathlib import Path; d=json.loads(Path(sys.argv[1]).read_text()); assert d["release_version"] == "0.1.1" and d["source_commit"] == "dd100f026e13cdd9e97b283d50130241d71bdb9d" and d["source_tree"] == "2873e5f7e0c200ec24a6706610d3bc0527303a7d"' "$release/release-provenance.json"
"$python" -m venv .doc-tools/enhancer
.doc-tools/enhancer/bin/python -m pip install --no-deps "$release/$wheel"
.doc-tools/enhancer/bin/python -m pip install -r docs/requirements.txt
test "$(.doc-tools/enhancer/bin/gnatdoc-enhancer --version)" = 0.1.1
.doc-tools/enhancer/bin/python -c 'from importlib.metadata import distribution; import json; d=distribution("ada-gnatdoc-enhancer"); assert d.version == "0.1.1"; u=json.loads(d.read_text("direct_url.json")); assert not u.get("dir_info") and u["url"].endswith(".whl")'