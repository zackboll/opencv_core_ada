#!/bin/bash
# Additional runtime controls, after a successful qualify_aunit.sh campaign.
# Use a reviewed OPENCV_CROSS_GPR_CONFIG with Ada, C and C++ target drivers.
# Existing O2/-gnatp layout policy is intentional; never apply it to AUnit.
set -euo pipefail
root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd -P)
campaign=${1:?supply successful AUnit campaign directory}
evidence=${2:?supply fresh additional-control evidence directory}
test "$(cat "$campaign/aunit-qemu.exit")" = 0
python3 "$root/tests/adacore25/verify_outputs.py" --summary \
    "$campaign/logs/aunit-qemu.log"
test ! -e "$evidence"
case "$evidence" in /*) ;; *) echo 'absolute evidence required' >&2; exit 1;; esac
case "${QUALIFY_EMULATOR:?supply explicit absolute QEMU executable}" in
    /*) ;; *) echo 'absolute emulator required' >&2; exit 1;;
esac
sh "$root/scripts/configure_cross_opencv.sh" --check
mkdir -p "$evidence/logs"
git -c "safe.directory=$root" -C "$root" rev-parse HEAD > "$evidence/tooling-source-revision.txt"
test -z "$(git -c "safe.directory=$root" -C "$root" status --porcelain)"
work=$campaign/core-work
export GPR_PROJECT_PATH="$work:$campaign/aunit/lib/gnat"
cd "$work"
build() {
    local name=$1 project=$2
    shift 2
    "$OPENCV_CROSS_GPRBUILD" --config="$OPENCV_CROSS_GPR_CONFIG" \
        -P "$project" -p -j4 -v -R "$@" \
        -cargs:Ada "--sysroot=$ENV_PREFIX" \
        -cargs:C "--sysroot=$ENV_PREFIX" \
        -cargs:C++ "--sysroot=$ENV_PREFIX" \
        -largs "--sysroot=$ENV_PREFIX" "-L$ENV_PREFIX/usr/lib" \
        > "$evidence/logs/$name-build.log" 2>&1
    if grep -n 'warning:' "$evidence/logs/$name-build.log"; then return 1; fi
}
execute() {
    local name=$1 binary=$2 result
    readelf -h -l -d -V "$binary" > "$evidence/logs/$name-elf.log"
    printf '%s\n' "$QUALIFY_EMULATOR -L $ENV_PREFIX $binary" \
        > "$evidence/logs/$name-command.txt"
    set +e
    "$QUALIFY_EMULATOR" -L "$ENV_PREFIX" "$binary" \
        > "$evidence/logs/$name-qemu.log" 2>&1
    result=$?
    set -e
    printf '%s\n' "$result" > "$evidence/$name.exit"
    test "$result" -eq 0
}
verify() {
    local directory=$1 name=$2
    shift 2
    python3 "$root/tests/adacore25/verify_outputs.py" "$directory" "$@" \
        > "$evidence/logs/$name-abi.json"
}
build k-means tests/probes/k_means_attempts_controls.gpr
verify "$work/tests/probes" k-means "$work/tests/probes/k_means_attempts_controls"
execute k-means "$work/tests/probes/k_means_attempts_controls"
build all-family tests/layout/all_family_controls.gpr \
    "-XLAYOUT_OPENCV_INCLUDE=-I$ENV_PREFIX/usr/include/opencv4"
verify "$work/tests/layout" all-family "$work/tests/layout/bin-family/all_family_controls"
execute all-family "$work/tests/layout/bin-family/all_family_controls"
grep -qx 'Total Tests Run:   2025' "$evidence/logs/all-family-qemu.log"
grep -qx 'Successful Tests:  2025' "$evidence/logs/all-family-qemu.log"
grep -qx 'Failed Assertions: 0' "$evidence/logs/all-family-qemu.log"
grep -qx 'Unexpected Errors: 0' "$evidence/logs/all-family-qemu.log"
grep -qx 'PASS all-family public API suite with live constructor/lease controls' \
    "$evidence/logs/all-family-qemu.log"
for profile in o0 o2; do
    case "$profile" in o0) flags=(-O0);; o2) flags=(-O2 -gnatp);; esac
    "$OPENCV_CROSS_GPRBUILD" --config="$OPENCV_CROSS_GPR_CONFIG" \
        -P tests/layout/layout_controls.gpr -p -j4 -v -R \
        "-XLAYOUT_PROFILE=$profile" "-XLAYOUT_SHIM=$work/lib/libopencv_core_shim.a" \
        -cargs:Ada "${flags[@]}" "--sysroot=$ENV_PREFIX" \
        -cargs:C "--sysroot=$ENV_PREFIX" \
        -largs "--sysroot=$ENV_PREFIX" "-L$ENV_PREFIX/usr/lib" \
        > "$evidence/logs/layout-$profile-build.log" 2>&1
    if grep -n 'warning:' "$evidence/logs/layout-$profile-build.log"; then exit 1; fi
    binaries=()
    for main in production_negative_controls opencv-core-internal-object_size_negative \
        opencv-core-internal-layout_guard_controls representation_measurements \
        float16_boundary_controls; do
        binaries+=("$work/tests/layout/bin-$profile/$main")
    done
    verify "$work/tests/layout" "layout-$profile" "${binaries[@]}"
    for binary in "${binaries[@]}"; do
        execute "$profile-$(basename "$binary")" "$binary"
    done
done
echo 'PASS additional Core controls (QEMU, not hardware)'