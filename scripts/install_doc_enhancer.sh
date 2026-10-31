#!/bin/sh
# Released wheel only; documentation dependencies never enter the Alire crate.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
python=${DOC_BOOTSTRAP_PYTHON:-python3}
"$python" -c 'import sys; assert sys.version_info[:2] in ((3,11),(3,12),(3,13)), "supported documentation Python required"'
mkdir -p .doc-tools/enhancer-release
release="$root/.doc-tools/enhancer-release"
base=https://github.com/zackboll/ada-gnatdoc-enhancer/releases/download/v0.1.3
wheel=ada_gnatdoc_enhancer-0.1.3-py3-none-any.whl
for asset in "$wheel" SHA256SUMS release-provenance.json; do
    curl --fail --location --output "$release/$asset" "$base/$asset"
done
test "$(sha256sum "$release/SHA256SUMS" | cut -d ' ' -f 1)" = 80dba07d94b8bc2dc25242e31460a2acc641a3b047459b79ec3aca6d9129d3e5
(cd "$release" && sha256sum --check --ignore-missing SHA256SUMS)
test "$(sha256sum "$release/release-provenance.json" | cut -d ' ' -f 1)" = 1f6f0c3dd34fe391977c1dc01d7d2b780cf40f314de4f76e7375aa86f202362d
test "$(sha256sum "$release/$wheel" | cut -d ' ' -f 1)" = f03f20ee4bcb6a918013bac7577300ab2bfb42714c22dc4677139e5359a7bac9
"$python" -c 'import json,sys; from pathlib import Path; d=json.loads(Path(sys.argv[1]).read_text()); assert d["release_version"] == "0.1.3" and d["expected_source_commit"] == "ce117aedc7eeb8c45aafc07dea9357166caadf0d" and d["expected_source_tree"] == "e87c8500165c119753843f71e34868b7133523d1"' "$release/release-provenance.json"
"$python" -m venv .doc-tools/enhancer
.doc-tools/enhancer/bin/python -m pip install --no-deps "$release/$wheel"
.doc-tools/enhancer/bin/python -m pip install -r docs/requirements.txt
test "$(.doc-tools/enhancer/bin/gnatdoc-enhancer --version)" = 0.1.3
.doc-tools/enhancer/bin/python -c 'from importlib.metadata import distribution; import json; d=distribution("ada-gnatdoc-enhancer"); assert d.version == "0.1.3"; u=json.loads(d.read_text("direct_url.json")); assert not u.get("dir_info") and u["url"].endswith(".whl")'