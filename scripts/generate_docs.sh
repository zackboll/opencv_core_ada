#!/bin/sh
# Documentation tools are installed separately; never add library dependencies.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
command -v alr >/dev/null
command -v python3 >/dev/null
python=${DOC_PYTHON:-"$root/.doc-tools/enhancer/bin/python"}
enhancer="$(dirname -- "$python")/gnatdoc-enhancer"
test -x "$enhancer" || { echo 'error: run sh scripts/install_doc_enhancer.sh first' >&2; exit 1; }
test "$("$enhancer" --version)" = 0.1.4
"$python" -c 'import sys, json; from importlib.metadata import distribution; assert sys.prefix != sys.base_prefix; assert sys.version_info[:2] in ((3,11),(3,12),(3,13)); d=distribution("ada-gnatdoc-enhancer"); assert d.version == "0.1.4"; u=json.loads(d.read_text("direct_url.json")); assert not u.get("dir_info") and u["url"].endswith("/ada_gnatdoc_enhancer-0.1.4-py3-none-any.whl"); assert u.get("archive_info", {}).get("hashes", {}).get("sha256") == "057b7945a71d3afb10cbabec32111b4ac2d94a116c6b8553f70c71229a68ffc7"'
test "$(alr --version)" = 'alr 2.1.1' || {
    echo 'error: documentation requires Alire 2.1.1' >&2; exit 1;
}
prefix=${GNATDOC_PREFIX:-"$root/.doc-tools/gnatdoc-26.0.0"}
if [ ! -x "$prefix/bin/gnatdoc" ]; then
    alr -n install --prefix="$prefix" gnatdoc_bin=26.0.0
fi
# This release prints its version successfully but returns status 1.
version=$("$prefix/bin/gnatdoc" --version 2>&1 || true)
test "$version" = 'GNATdoc 26.0.0 (20260415)' || {
    echo "error: unqualified GNATdoc: $version" >&2; exit 1;
}
echo "$version"
# Resolve the library environment and its supported OpenCV configuration.
# This builds only the library, not the test crate or unrelated applications.
alr -n build
# Consume the complete version output: grep -q can close the pipe early and
# make Alire report SIGPIPE (-1) for an otherwise successful version command.
alr exec -- gnat --version | grep '^GNAT 16\.1\.0$' > /dev/null || {
    echo 'error: documentation requires GNAT 16.1.0' >&2; exit 1;
}
alr exec -- gprbuild --version | grep '^GPRBUILD 26\.0\.0 (2026-04-15)' > /dev/null || {
    echo 'error: documentation requires the GPRbuild 26.0.1 Alire release' >&2; exit 1;
}
# Fixed repository-owned output path: never delete a caller-selected directory.
rm -rf -- "$root/obj/docs/native"
mkdir -p obj/docs/native/api obj/docs-internal
if ! alr exec -- "$prefix/bin/gnatdoc" -P docs_api.gpr \
    --backend html --generate public --style leading --warnings \
    -O "$root/obj/docs/native/api" > obj/docs/gnatdoc.log 2>&1; then
    cat obj/docs/gnatdoc.log >&2
    exit 1
fi
# GNATdoc can report parsing/resolution errors while producing partial output.
if grep -Ei '(^|[[:space:]])(error:|fatal:|ignore file due to)' obj/docs/gnatdoc.log; then
    echo 'error: GNATdoc reported incomplete generation' >&2
    exit 1
fi
warnings=$(grep -c 'warning:' obj/docs/gnatdoc.log || true)
echo "GNATdoc: $warnings documentation warnings (see obj/docs/gnatdoc.log)"
python3 scripts/compare_gnatdoc_warnings.py \
    docs/gnatdoc-warning-baseline.txt obj/docs/gnatdoc.log
# The installed toolkit recursively scans sources. Stage only the exact public
# source set used by docs_api.gpr; src/internal belongs to its excluded project.
"$python" scripts/stage_gnatdoc_sources.py
"$python" scripts/verify_core_enhancer.py --native obj/docs/native
input="$root/obj/docs/enhancer-input"
rm -rf -- "$root/_site"
cp -a obj/docs/native _site
"$enhancer" inventory --source-root "$input" --config docs/gnatdoc-enhancer.toml --site "$root/_site" > obj/docs/enhancer-inventory.json
"$enhancer" enhance --dry-run --source-root "$input" --config docs/gnatdoc-enhancer.toml --site "$root/_site" > obj/docs/enhancer-dry-run.json
"$enhancer" enhance --source-root "$input" --config docs/gnatdoc-enhancer.toml --site "$root/_site" > obj/docs/enhancer-result.json
"$enhancer" verify --source-root "$input" --config docs/gnatdoc-enhancer.toml --site "$root/_site" > obj/docs/enhancer-verification.json
"$python" scripts/validate_docs.py _site