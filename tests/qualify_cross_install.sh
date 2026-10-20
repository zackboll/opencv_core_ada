#!/bin/sh
# Real SDK qualification, never target execution. Accept the installer's options.
set -eu
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
source_root=${OPENCV_CROSS_SOURCE_ROOT:-$root}
target=${OPENCV_CROSS_TARGET:-}
prefix=${OPENCV_CROSS_INSTALL_PREFIX:-}
sysroot=${ENV_PREFIX:-}
toolchain_bin=
previous=
for argument do
    case "$previous" in
        --source-root) source_root=$argument ;;
        --target) target=$argument ;;
        --prefix) prefix=$argument ;;
        --sysroot) sysroot=$argument ;;
        --toolchain-bin) toolchain_bin=$argument ;;
    esac
    previous=$argument
done
[ -n "$prefix" ] && [ -n "$sysroot" ] && [ -n "$target" ] || fail 'supply --prefix, --sysroot and --target'
# Qualification deliberately requires bootstrap and a fresh installation.
[ -z "${OPENCV_CROSS_GPR_CONFIG:-}" ] || fail 'unset OPENCV_CROSS_GPR_CONFIG to qualify automatic generation'
[ ! -e "$prefix" ] && [ ! -L "$prefix" ] || fail 'qualification prefix must not exist'
[ -n "$toolchain_bin" ] || fail 'supply --toolchain-bin'
toolchain_bin=$(realpath -e -- "$toolchain_bin")
PATH=$toolchain_bin:$PATH; export PATH
build=${OPENCV_CROSS_GPRBUILD:-gprbuild}
help=$("$build" --help)
printf '%s\n' "$help" | grep -Eq '^[[:space:]]*-R[[:space:]]+Do not use run path option' || fail 'GPRbuild must support -R (no run path)'
sh "$root/scripts/cross_install_core.sh" "$@"
prefix=$(realpath -e -- "$prefix")
sysroot=$(realpath -e -- "$sysroot")
source_root=$(realpath -e -- "$source_root")
# cross_install_core has now removed its owned temporary build workspace.
consumer=$(mktemp -d "${TMPDIR:-/tmp}/opencv-core-installed-consumer.XXXXXXXX")
printf 'External consumer evidence retained: %s\n' "$consumer"
cp "$source_root/tests/installed_mat_consumer.adb" "$source_root/tests/gnat12/installed_ada.gpr" "$consumer/"
unset GPR_PROJECT_PATH ADA_PROJECT_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
unset LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH
unset ADA_INCLUDE_PATH ADA_OBJECTS_PATH ADA_PRJ_INCLUDE_FILE ADA_PRJ_OBJECTS_FILE
GPR_PROJECT_PATH=$prefix/share/gpr; export GPR_PROJECT_PATH
cd "$consumer"
"$build" --config="$prefix/share/gprconfig/$target.cgpr" -P installed_ada.gpr \
    -p -v -R -cargs:Ada "--sysroot=$sysroot" \
    -largs "--sysroot=$sysroot" -Wl,-t "-Wl,-rpath-link,$sysroot/usr/lib" \
    > build.log 2>&1 || { result=$?; cat build.log >&2; exit "$result"; }
readelf=${OPENCV_CROSS_READELF:-readelf}
"$readelf" -h -l -d bin/installed_mat_consumer > executable-elf.log
grep -q 'Class:.*ELF64' executable-elf.log || fail 'consumer is not ELF64'
grep -q 'Data:.*little endian' executable-elf.log || fail 'consumer is not little endian'
grep -q 'Machine:.*AArch64' executable-elf.log || fail 'consumer is not AArch64'
grep -q 'Requesting program interpreter:' executable-elf.log || fail 'missing consumer interpreter'
grep -q 'NEEDED.*libopencv_core' executable-elf.log || fail 'missing OpenCV dynamic dependency'
if grep -E '\((RPATH|RUNPATH)\)' executable-elf.log; then
    fail 'consumer contains a deployment run path despite -R'
fi
for archive in lib/opencv_core/libopencv_core_ada.a lib/opencv_core_shim/libopencv_core_shim.a; do
    grep -F "$prefix/$archive" build.log >/dev/null || fail "consumer did not link installed archive: $archive"
done
# The generated configuration contains absolute selected drivers, also printed
# by verbose compilation/linking. Do not infer tool identity from target alone.
ada=${OPENCV_CROSS_ADA:-$toolchain_bin/$target-gcc}
cxx=${OPENCV_CROSS_CXX:-$toolchain_bin/$target-g++}
for compiler in "$ada" "$cxx"; do
    [ -n "$compiler" ] || fail 'cannot determine qualification compiler'
    compiler=$(command -v "$compiler")
    compiler=$(realpath -e -- "$compiler")
    grep -F "$compiler" build.log >/dev/null || fail "consumer trace lacks selected tool: $compiler"
done
cat executable-elf.log
printf 'PASS automatic bootstrap, build, recursive install and independent installed consumer cross-link.\nTarget execution: NOT PERFORMED. Evidence: %s\n' "$consumer"