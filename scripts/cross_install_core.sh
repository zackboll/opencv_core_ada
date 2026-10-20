#!/bin/sh
# Thin bootstrap; cross_build_core.sh owns validation, snapshot, build/install.
set -eu
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
usage() {
    printf '%s\n' 'usage: cross_install_core.sh --target TRIPLE --toolchain-bin DIR --runtime DIR --sysroot DIR --prefix DIR [--profile release|development|validation] [--source-root DIR]'
}
root=$(CDPATH= cd -- "${OPENCV_CROSS_SOURCE_ROOT:-$(dirname -- "$0")/..}" && pwd -P)
target=${OPENCV_CROSS_TARGET:-}
toolchain_bin=
runtime=${OPENCV_CROSS_RUNTIME:-}
sysroot=${ENV_PREFIX:-}
prefix=${OPENCV_CROSS_INSTALL_PREFIX:-}
profile=${OPENCV_CROSS_PROFILE:-release}
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --target|--toolchain-bin|--runtime|--sysroot|--prefix|--profile|--source-root)
            [ "$#" -ge 2 ] || fail "missing value for $1"
            option=$1; value=$2; shift 2
            case "$option" in
                --target) target=$value ;;
                --toolchain-bin) toolchain_bin=$value ;;
                --runtime) runtime=$value ;;
                --sysroot) sysroot=$value ;;
                --prefix) prefix=$value ;;
                --profile) profile=$value ;;
                --source-root) root=$(CDPATH= cd -- "$value" && pwd -P) ;;
            esac ;;
        *) usage >&2; fail "unknown option: $1" ;;
    esac
done
sh "$root/scripts/validate_cross_target.sh" "$target"
[ -n "$toolchain_bin" ] || fail '--toolchain-bin is required'
toolchain_bin=$(CDPATH= cd -- "$toolchain_bin" && pwd -P)
[ -n "$runtime" ] || fail '--runtime is required'
runtime=$(CDPATH= cd -- "$runtime" && pwd -P)
[ -n "$sysroot" ] || fail '--sysroot is required'
sysroot=$(CDPATH= cd -- "$sysroot" && pwd -P)
[ -n "$prefix" ] || fail '--prefix is required'
case "$prefix" in /*) ;; *) fail 'installation prefix must be absolute' ;; esac
prefix=$(realpath -m -- "$prefix")
case "$profile" in release|development|validation) ;; *) fail 'invalid build profile' ;; esac
PATH=$toolchain_bin:$PATH; export PATH
# Resolve actual selected paths, including explicit executable overrides.
ada=$(command -v "${OPENCV_CROSS_ADA:-$toolchain_bin/$target-gcc}") || fail 'Ada compiler unavailable'
cxx=$(command -v "${OPENCV_CROSS_CXX:-$toolchain_bin/$target-g++}") || fail 'C++ compiler unavailable'
ada=$(realpath -e -- "$ada")
cxx=$(realpath -e -- "$cxx")
OPENCV_CROSS_TARGET=$target
OPENCV_CROSS_ADA=$ada
OPENCV_CROSS_CXX=$cxx
OPENCV_CROSS_RUNTIME=$runtime
OPENCV_CROSS_SOURCE_ROOT=$root
OPENCV_CROSS_INSTALL_PREFIX=$prefix
OPENCV_CROSS_PROFILE=$profile
ENV_PREFIX=$sysroot
export OPENCV_CROSS_TARGET OPENCV_CROSS_ADA OPENCV_CROSS_CXX OPENCV_CROSS_RUNTIME
export OPENCV_CROSS_SOURCE_ROOT OPENCV_CROSS_INSTALL_PREFIX OPENCV_CROSS_PROFILE ENV_PREFIX
# Only supply defaults for target-local metadata. Explicit overrides are checked
# by the existing preflight, including rejection of host pkg-config paths.
if [ -z "${PKG_CONFIG_LIBDIR:-}" ]; then
    PKG_CONFIG_LIBDIR=
    for directory in "$sysroot/usr/lib/pkgconfig" "$sysroot/usr/lib/$target/pkgconfig" "$sysroot/usr/share/pkgconfig" "$sysroot/lib/pkgconfig"; do
        if [ -d "$directory" ]; then
            PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR:+$PKG_CONFIG_LIBDIR:}$directory
        fi
    done
    export PKG_CONFIG_LIBDIR
fi
# This run owns only this mktemp directory. Failures retain it, success removes
# it after copying logs to the installation prefix; no caller directory is erased.
run=$(mktemp -d "${TMPDIR:-/tmp}/opencv-core-cross.XXXXXXXX")
run=$(realpath -e -- "$run")
finish() {
    result=$?
    trap - EXIT
    if [ "$result" -eq 0 ]; then
        rm -rf -- "$run"
    else
        printf 'Cross-install failed (%s); workspace and logs retained: %s\n' "$result" "$run" >&2
    fi
    exit "$result"
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
case "$prefix/" in "$run/"*) fail 'installation prefix must outlive the temporary workspace' ;; esac
case "$run/" in "$prefix/"*) fail 'installation prefix overlaps temporary workspace' ;; esac
unset GPR_PROJECT_PATH ADA_PROJECT_PATH
if [ -z "${OPENCV_CROSS_GPR_CONFIG:-}" ]; then
    OPENCV_CROSS_GPR_CONFIG=$run/target.cgpr
    export OPENCV_CROSS_GPR_CONFIG
    "${OPENCV_CROSS_GPRCONFIG:-gprconfig}" --batch --target="$target" \
        --config="Ada,,$runtime,$(dirname -- "$ada"),GNAT" \
        --config="C++,,,$(dirname -- "$cxx"),$(basename -- "$cxx")" \
        -o "$OPENCV_CROSS_GPR_CONFIG" > "$run/gprconfig.log" 2>&1 || {
            result=$?; cat "$run/gprconfig.log" >&2; exit "$result"
        }
else
    OPENCV_CROSS_GPR_CONFIG=$(realpath -e -- "$OPENCV_CROSS_GPR_CONFIG")
    export OPENCV_CROSS_GPR_CONFIG
fi
sh "$root/scripts/cross_build_core.sh" --build "$run/build" > "$run/workflow.log" 2>&1 || {
    result=$?; cat "$run/workflow.log" >&2; exit "$result"
}
cat "$run/workflow.log"
logs=$prefix/share/gprconfig/$target-logs
mkdir -p "$logs"
for log in "$run/gprconfig.log" "$run/workflow.log" "$run/build/toolchain-probe.log" \
    "$run/build/toolchain-probe-elf.log" "$run/build/build.log" "$run/build/install.log" \
    "$run/build/installed-archives-elf.log"; do
    [ ! -f "$log" ] || cp "$log" "$logs/"
done
printf '\nLogs: %s\nInstalled-consumer example (from an external consumer directory):\n' "$logs"
printf 'GPR_PROJECT_PATH="%s/share/gpr" %s --config="%s/share/gprconfig/%s.cgpr" -P installed_ada.gpr -p -v -R -cargs:Ada "--sysroot=%s" -largs "--sysroot=%s"\n' \
    "$prefix" "${OPENCV_CROSS_GPRBUILD:-gprbuild}" "$prefix" "$target" "$sysroot" "$sysroot"