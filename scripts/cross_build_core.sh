#!/bin/sh
# Opt-in cross build of a clean, exact Git revision in a disposable workspace.
set -eu
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
target=${OPENCV_CROSS_TARGET:-}
[ -n "$target" ] || fail 'OPENCV_CROSS_TARGET is required'
case "$target" in aarch64*-linux-*) ;; *) fail 'only AArch64 Linux targets are supported' ;; esac
[ -n "${ENV_PREFIX:-}" ] || fail 'ENV_PREFIX is required'
[ -d "$ENV_PREFIX" ] || fail 'target sysroot does not exist'
[ "$ENV_PREFIX" != / ] || fail 'a dedicated target sysroot is required'
export OPENCV_CORE_CROSS=True
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
# Preflight runs before source export and never modifies the supplied sysroot.
sh "$root/scripts/configure_cross_opencv.sh" --check
[ "$#" = 2 ] || fail 'usage: cross_build_core.sh --prepare|--build ABSOLUTE_WORKSPACE'
mode=$1
work=$2
case "$mode" in --prepare|--build) ;; *) fail 'unknown operation' ;; esac
case "$work" in /*) ;; *) fail 'workspace must be absolute' ;; esac
[ ! -e "$work" ] && [ ! -L "$work" ] || fail 'workspace must not already exist (stale artifacts)'
# GNU realpath -m resolves parent symlinks and .. even for a new destination.
# Check both containment directions: an ancestor also overlaps protected data.
work=$(realpath -m -- "$work") || fail 'cannot canonicalize workspace'
sysroot=$(realpath -e -- "$ENV_PREFIX") || fail 'cannot canonicalize sysroot'
[ ! -e "$work" ] && [ ! -L "$work" ] || fail 'workspace must not already exist (stale artifacts)'
for protected in "$root" "$sysroot"; do
    case "$work/" in "$protected/"*) fail 'workspace must be outside protected checkout and sysroot' ;; esac
    case "$protected/" in "$work/"*) fail 'workspace overlaps protected checkout or sysroot' ;; esac
done
status=$(git -C "$root" status --porcelain) || fail 'source Git metadata is inaccessible'
[ -z "$status" ] || fail 'source revision must be clean before export'
revision=$(git -C "$root" rev-parse HEAD) || fail 'cannot resolve source revision'
mkdir -p "$work"
printf '%s\n' "$revision" > "$work/source-revision.txt"
git -C "$root" archive --output="$work/source.tar" "$revision"
tar -xf "$work/source.tar" -C "$work"
rm "$work/source.tar"
cd "$work"
mkdir -p config
sh scripts/configure_opencv.sh
profile=${OPENCV_CROSS_PROFILE:-development}
case "$profile" in development|release|validation) ;; *) fail 'invalid build profile' ;; esac
printf 'abstract project OpenCV_Core_Config is\n   Build_Profile := "%s";\n   Ada_Compiler_Switches := ("-gnat2022", "-gnatwa", "-gnatwe");\nend OpenCV_Core_Config;\n' "$profile" > config/opencv_core_config.gpr
cp "$OPENCV_CROSS_GPR_CONFIG" config/target.cgpr
# GPR output directories belong to these physically exported projects, not an
# extending project in the native checkout. Prove the foreign boundary first.
probe="$work/tests/fixtures/cross-reference"
"${OPENCV_CROSS_GPRBUILD:-gprbuild}" --config="$work/config/target.cgpr" \
    -P "$probe/probe.gpr" -p -v -cargs:Ada "--sysroot=$ENV_PREFIX" \
    -largs "--sysroot=$ENV_PREFIX" > "$work/toolchain-probe.log" 2>&1 || {
        cat "$work/toolchain-probe.log"; fail 'GPR target compiler/runtime probe failed';
    }
"${OPENCV_CROSS_READELF:-readelf}" -h "$probe/bin/probe" \
    > "$work/toolchain-probe-elf.log"
grep -q 'Machine:.*AArch64' "$work/toolchain-probe-elf.log" || fail 'GPR probe is not AArch64'
grep -q 'Class:.*ELF64' "$work/toolchain-probe-elf.log" || fail 'GPR probe is not ELF64'
grep -F "$OPENCV_CROSS_ADA" "$work/toolchain-probe.log" >/dev/null || fail 'GPR trace did not select supplied Ada compiler'
grep -F "$OPENCV_CROSS_CXX" "$work/toolchain-probe.log" >/dev/null || fail 'GPR trace did not select supplied linker'
if [ "$mode" = --build ]; then
    unset GPR_PROJECT_PATH ADA_PROJECT_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
    unset LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH
    "${OPENCV_CROSS_GPRBUILD:-gprbuild}" --config=config/target.cgpr \
        -P opencv_core.gpr -p -v -cargs:Ada "--sysroot=$ENV_PREFIX" \
        -cargs:C++ "--sysroot=$ENV_PREFIX"
    "${OPENCV_CROSS_GPRINSTALL:-gprinstall}" --config=config/target.cgpr \
        -P opencv_core.gpr -p -r --prefix="$work/install"
fi
printf 'Cross workspace: %s\nSource revision: %s\n' "$work" "$(cat source-revision.txt)"