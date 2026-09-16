#!/bin/sh

# Pinned-source validation of a clean opencv_core consumer.
# This is not a pin-free index-resolution test.
#
# Usage:
#   scripts/validate_root_value_consumer.sh <core-source-dir> [work-dir]
#
# The Core source directory must contain the candidate being validated.
# The optional work directory defaults to a unique directory under TMPDIR.

set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "usage: $0 <core-source-dir> [work-dir]" >&2
    exit 1
fi

core_source=$(cd "$1" && pwd)
work_root=${2:-"${TMPDIR:-/tmp}/opencv_core_root_value_consumer.$$"}
fixture="$core_source/scripts/root_value_consumer.adb"
header="cpp/opencv_core_module_bridge.hpp"

if [ ! -f "$core_source/alire.toml" ]; then
    echo "error: $core_source is not an opencv_core source tree" >&2
    exit 1
fi

if ! grep -q 'version = "0.2.0"' "$core_source/alire.toml"; then
    echo "error: expected opencv_core 0.2.0 in $core_source/alire.toml" >&2
    exit 1
fi

if [ ! -f "$fixture" ]; then
    echo "error: missing consumer fixture: $fixture" >&2
    exit 1
fi

if [ ! -f "$core_source/$header" ]; then
    echo "error: missing exported header source: $core_source/$header" >&2
    exit 1
fi

mkdir -p "$work_root"
cd "$work_root"

alr -n init --bin root_value_consumer
cd root_value_consumer

cp "$fixture" src/root_value_consumer.adb

alr -n with opencv_core --use="$core_source"
alr -n build
alr -n run

prefix="$work_root/prefix"
mkdir -p "$prefix"
alr exec -- gprinstall -f -p -r --prefix="$prefix" -P "$core_source/opencv_core.gpr"

if [ ! -f "$prefix/include/opencv_core_module_bridge.hpp" ]; then
    echo "error: exported header missing: $prefix/include/opencv_core_module_bridge.hpp" >&2
    find "$prefix" -name '*bridge*' -o -name '*.hpp' || true
    exit 1
fi

echo "pinned source consumer passed"
echo "exported header: $prefix/include/opencv_core_module_bridge.hpp"
echo "work directory: $work_root"
