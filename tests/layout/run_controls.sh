#!/bin/sh
# Run after building Core; all outputs stay in the test crate.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
cd "$root"
for profile in o0 o2; do
    case "$profile" in
        o0) set -- -O0 ;;
        o2) set -- -O2 -gnatp ;;
    esac
    alr -n exec -- gprbuild -P tests/layout/layout_controls.gpr -p \
        "-XLAYOUT_PROFILE=$profile" \
        "-XLAYOUT_SHIM=$root/lib/libopencv_core_shim.a" -cargs:Ada "$@"
    for main in float16_boundary_controls \
        opencv-core-internal-object_size_negative \
        opencv-core-internal-layout_guard_controls; do
        "tests/layout/bin-$profile/$main"
    done
done