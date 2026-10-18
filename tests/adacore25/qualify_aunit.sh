#!/bin/sh
# Opt-in GNAT Pro campaign. No downloading, compiler selection or native policy changes.
# Required cross inputs are those of scripts/configure_cross_opencv.sh.
# QUALIFY_PRODUCTION_WORK is the preserved Core cross_build_core.sh workspace;
# QUALIFY_AUNIT_ROOT is pristine AUnit 26.0.0 source. EVIDENCE must not exist.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd -P)
evidence=${1:?supply a fresh absolute evidence directory}
production=${QUALIFY_PRODUCTION_WORK:?supply qualified Core production workspace}
aunit=${QUALIFY_AUNIT_ROOT:?supply pristine AUnit 26.0.0 source}
case "$evidence" in /*) ;; *) echo 'absolute evidence required' >&2; exit 1;; esac
test ! -e "$evidence"
test -f "$production/source-revision.txt"
test "$(cat "$production/source-revision.txt")" = "${QUALIFY_CORE_COMMIT:?supply qualified Core source SHA}"
test -f "$production/lib/libopencv_core_ada.a"
test -f "$production/lib/libopencv_core_shim.a"
test -f "$aunit/lib/gnat/aunit.gpr"
test -z "$(find "$production/tests/src" "$production/tests/cpp" "$aunit" -name '*.ali' -o -name '*.o')"
# Reuse only the exact production and test sources under review.
diff -qr "$root/src" "$production/src"
diff -qr "$root/cpp" "$production/cpp"
diff -qr "$root/tests/src" "$production/tests/src"
diff -qr "$root/tests/cpp" "$production/tests/cpp"
sh "$root/scripts/configure_cross_opencv.sh" --check
mkdir -p "$evidence/logs"
printf '%s\n' "$QUALIFY_CORE_COMMIT" > "$evidence/production-source-revision.txt"
git -c "safe.directory=$root" -C "$root" rev-parse HEAD > "$evidence/tooling-source-revision.txt"
test -z "$(git -c "safe.directory=$root" -C "$root" status --porcelain)"
cp -a "$production" "$evidence/core-work"
cp -a "$aunit" "$evidence/aunit"
work=$evidence/core-work
cp "$root/scripts/build_module_bridge_probe.sh" "$work/scripts/"
mkdir -p "$work/tests/config"
cp "$root/tests/adacore25/tests_config.gpr" "$work/tests/config/"
cp "$OPENCV_CROSS_GPR_CONFIG" "$evidence/target.cgpr"
export GPR_PROJECT_PATH="$work:$evidence/aunit/lib/gnat"
unset ADA_PROJECT_PATH ADA_INCLUDE_PATH ADA_OBJECTS_PATH LD_LIBRARY_PATH
cd "$work"
sh -x scripts/build_module_bridge_probe.sh > "$evidence/logs/probes.log" 2>&1
"$OPENCV_CROSS_GPRBUILD" --config="$evidence/target.cgpr" \
    -P tests/tests.gpr -p -j4 -v -R \
    -cargs:Ada "--sysroot=$ENV_PREFIX" \
    -cargs:C++ "--sysroot=$ENV_PREFIX" \
    -largs "--sysroot=$ENV_PREFIX" > "$evidence/logs/aunit-build.log" 2>&1
if grep -n 'warning:' "$evidence/logs/aunit-build.log" "$evidence/logs/probes.log"; then
    echo 'error: build warnings' >&2
    exit 1
fi
python3 "$root/tests/adacore25/verify_outputs.py" "$evidence" \
    "$work/tests/bin/tests" > "$evidence/logs/qualification.json"
emulator=${QUALIFY_EMULATOR:?supply explicit absolute QEMU AArch64 executable}
case "$emulator" in /*) ;; *) echo 'absolute emulator required' >&2; exit 1;; esac
"$emulator" --version > "$evidence/logs/qemu-version.log"
printf '%s\n' "OPENCV_CORE_CI=1 $emulator -L $ENV_PREFIX $work/tests/bin/tests" \
    > "$evidence/logs/qemu-command.txt"
set +e
OPENCV_CORE_CI=1 "$emulator" -L "$ENV_PREFIX" "$work/tests/bin/tests" \
    > "$evidence/logs/aunit-qemu.log" 2>&1
result=$?
set -e
printf '%s\n' "$result" > "$evidence/aunit-qemu.exit"
test "$result" -eq 0
python3 "$root/tests/adacore25/verify_outputs.py" --summary \
    "$evidence/logs/aunit-qemu.log" > "$evidence/logs/aunit-summary.json"
echo 'PASS Core AUnit 2037/2037 (QEMU, not hardware)'