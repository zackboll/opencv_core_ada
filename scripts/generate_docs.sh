#!/bin/sh
# Documentation tools are installed separately; never add library dependencies.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
command -v alr >/dev/null
command -v python3 >/dev/null
python=${DOC_PYTHON:-python3}
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
rm -rf -- "$root/_site"
mkdir -p _site/api obj/docs obj/docs-internal
if ! alr exec -- "$prefix/bin/gnatdoc" -P docs_api.gpr \
    --backend html --generate public --style leading --warnings \
    -O "$root/_site/api" > obj/docs/gnatdoc.log 2>&1; then
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
cp docs/index.html _site/index.html
python3 scripts/enhance_gnatdoc_instances.py _site/api
python3 scripts/install_gnatdoc_theme.py _site/api
python3 scripts/link_gnatdoc_types.py _site/api
python3 scripts/highlight_gnatdoc_ada.py _site/api
python3 scripts/enhance_gnatdoc_navigation.py _site/api
"$python" scripts/render_gnatdoc_guides.py _site
"$python" scripts/validate_docs.py _site