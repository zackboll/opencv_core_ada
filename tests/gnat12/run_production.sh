#!/bin/sh
# Native Debian 12 production qualification, independent of Alire selection.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
root=${GNAT12_SOURCE_ROOT:-$root}
test -f "$root/opencv_core.gpr"
work=${GNAT12_WORK:?set GNAT12_WORK to a fresh absolute directory}
aunit=${GNAT12_AUNIT_ROOT:?set GNAT12_AUNIT_ROOT to unpacked AUnit 26 sources}
case "$work" in /*) ;; *) echo 'absolute workspace required' >&2; exit 1;; esac
case "$root" in /) echo 'source root must not be filesystem root' >&2; exit 1;; esac
case "$work/" in "$root/"*) echo 'workspace overlaps source' >&2; exit 1;; esac
case "$root/" in "$work/"*) echo 'source overlaps workspace' >&2; exit 1;; esac
test ! -e "$work"
test -f "$aunit/lib/gnat/aunit.gpr"
test "$(gcc -dumpfullversion)" = 12.2.0
test "$(gcc -dumpmachine)" = x86_64-linux-gnu
test "$(gcc -print-file-name=adalib)" = /usr/lib/gcc/x86_64-linux-gnu/12/adalib
unset GPR_PROJECT_PATH ADA_PROJECT_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
unset LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH
mkdir -p "$work/source" "$work/aunit" "$work/logs"
cp -a "$root/." "$work/source/"
cp -a "$aunit/." "$work/aunit/"
cd "$work/source"
mkdir -p config tests/config
cp tests/gnat12/opencv_core_config.gpr config/
cp tests/gnat12/tests_config.gpr tests/config/
sh scripts/configure_opencv.sh
test "$(pkg-config --modversion opencv4)" = 4.6.0
{
    cat /etc/os-release
    gcc --version
    gnatls -v
    gprbuild --version
    g++ --version
    pkg-config --modversion opencv4
} > "$work/logs/identities.log" 2>&1
export GPR_PROJECT_PATH="$work/source:$work/aunit/lib/gnat"
gprbuild -P opencv_core.gpr -p -j4 -v > "$work/logs/production.log" 2>&1
sh scripts/build_module_bridge_probe.sh > "$work/logs/probes.log" 2>&1
gprbuild -P tests/tests.gpr -p -j4 -v > "$work/logs/aunit-build.log" 2>&1
tests/bin/tests > "$work/logs/aunit-run.log" 2>&1
gprbuild -P tests/probes/k_means_attempts_controls.gpr -p -j4 \
    > "$work/logs/k-means-build.log" 2>&1
tests/probes/k_means_attempts_controls > "$work/logs/k-means-run.log" 2>&1
gprbuild -P tests/probes/runtime_identity_controls.gpr -p -j4 \
    > "$work/logs/runtime-identity-build.log" 2>&1
tests/probes/bin-runtime-controls/runtime_identity_controls \
    > "$work/logs/runtime-identity-run.log" 2>&1
gprbuild -P tests/layout/all_family_controls.gpr -p -j4 \
    > "$work/logs/all-family-build.log" 2>&1
tests/layout/bin-family/all_family_controls > "$work/logs/all-family-run.log" 2>&1
for profile in o0 o2; do
    case "$profile" in o0) set -- -O0;; o2) set -- -O2 -gnatp;; esac
    gprbuild -P tests/layout/layout_controls.gpr -p -j4 \
        "-XLAYOUT_PROFILE=$profile" "-XLAYOUT_SHIM=$work/source/lib/libopencv_core_shim.a" \
        -cargs:Ada "$@" > "$work/logs/layout-$profile-build.log" 2>&1
    # Run independent negatives before positive production controls.
    for main in production_negative_controls \
        opencv-core-internal-object_size_negative \
        opencv-core-internal-layout_guard_controls \
        representation_measurements float16_boundary_controls; do
        "tests/layout/bin-$profile/$main" > "$work/logs/$profile-$main.log" 2>&1
    done
done
mkdir "$work/consumers"
gprinstall -P opencv_core.gpr -p -r --prefix="$work/consumers/prefix-a" \
    > "$work/logs/install.log" 2>&1
cp tests/installed_mat_consumer.adb tests/installed_mixed_consumer.adb \
    tests/installed_application.cpp tests/installed_mixed_consumer.gpr "$work/consumers/"
cp scripts/validate_installed_mat_consumer.sh "$work/consumers/consume.sh"
cp config/opencv_core_install.gpr "$work/consumers/build-install.gpr"
printf '%s\n' "$PATH" > "$work/consumers/toolchain-path.txt"
CORE_DEBIAN_QUALIFICATION=True sh "$work/consumers/consume.sh" \
    --consume "$work/consumers" "$work/source" > "$work/logs/consumers.log" 2>&1
echo 'PASS complete GNAT 12 production, AUnit, boundaries and installed consumers'