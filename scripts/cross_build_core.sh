#!/bin/sh
# Opt-in isolated cross build of a clean Git revision or explicit source archive.
set -eu
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
target=${OPENCV_CROSS_TARGET:-}
sh "$(dirname -- "$0")/validate_cross_target.sh" "$target"
[ -n "${ENV_PREFIX:-}" ] || fail 'ENV_PREFIX is required'
[ -d "$ENV_PREFIX" ] || fail 'target sysroot does not exist'
[ "$ENV_PREFIX" != / ] || fail 'a dedicated target sysroot is required'
export OPENCV_CORE_CROSS=True
root=$(CDPATH= cd -- "${OPENCV_CROSS_SOURCE_ROOT:-$(dirname -- "$0")/..}" && pwd -P)
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
profile=${OPENCV_CROSS_PROFILE:-development}
case "$profile" in development|release|validation) ;; *) fail 'invalid build profile' ;; esac
prefix=${OPENCV_CROSS_INSTALL_PREFIX:-$work/install}
case "$prefix" in /*) ;; *) fail 'installation prefix must be absolute' ;; esac
prefix=$(realpath -m -- "$prefix")
for protected in "$root" "$sysroot"; do
    case "$prefix/" in "$protected/"*) fail 'installation prefix overlaps source or sysroot' ;; esac
    case "$protected/" in "$prefix/"*) fail 'installation prefix overlaps source or sysroot' ;; esac
done
if [ -e "$root/.git" ] || [ -L "$root/.git" ]; then
    # Never let Git discover and export an unrelated enclosing repository.
    status=$(git -C "$root" status --porcelain) || fail 'source Git metadata is inaccessible'
    [ -z "$status" ] || fail 'source revision must be clean before export'
    top=$(git -C "$root" rev-parse --show-toplevel) || fail 'cannot resolve Git source root'
    [ "$(realpath -e -- "$top")" = "$root" ] || fail 'source root must be the Git checkout root'
    revision=$(git -C "$root" rev-parse HEAD) || fail 'cannot resolve source revision'
    mkdir -p "$work"
    git -C "$root" archive --output="$work/source.tar" "$revision"
    printf 'Git commit: %s\n' "$revision" > "$work/source-identity.txt"
else
    # Explicit build inputs, not wildcard copying or an enclosing Git export.
    # Exclude generated state even from an unpacked tree previously built native.
    for input in alire.toml opencv_core.gpr opencv_core_shim.gpr src cpp scripts tests/fixtures/cross-reference; do
        [ -e "$root/$input" ] || fail "incomplete archive source: $input"
        [ ! -L "$root/$input" ] || fail "archive build input must not be a symlink: $input"
    done
    mkdir -p "$work"
    tar -cf "$work/source.tar" -C "$root" --exclude=.git --exclude=alire \
        --exclude=config --exclude=obj --exclude=lib --exclude=bin --exclude=__pycache__ \
        alire.toml opencv_core.gpr opencv_core_shim.gpr src cpp scripts tests/fixtures/cross-reference
    revision='archive (no Git revision)'
    printf 'Archive source root: %s\nManifest SHA256: %s\nSnapshot SHA256: %s\n' \
        "$root" "$(sha256sum "$root/alire.toml" | cut -d ' ' -f 1)" \
        "$(sha256sum "$work/source.tar" | cut -d ' ' -f 1)" > "$work/source-identity.txt"
fi
printf '%s\n' "$revision" > "$work/source-revision.txt"
tar -xf "$work/source.tar" -C "$work"
rm "$work/source.tar"
cd "$work"
mkdir -p config
sh scripts/configure_opencv.sh
# Match the native project's per-unit language policy. The typed-access body
# selects Ada 2022 in opencv_core.gpr; forcing it here changes warning semantics
# for unrelated units and makes their Ada 2012 array aggregates obsolescent.
printf 'abstract project OpenCV_Core_Config is\n   Build_Profile := "%s";\n   Ada_Compiler_Switches := ("-gnatwa", "-gnatwe");\nend OpenCV_Core_Config;\n' "$profile" > config/opencv_core_config.gpr
cp "$OPENCV_CROSS_GPR_CONFIG" config/target.cgpr
. "$work/scripts/cross_elf.sh"
# Preserve tool failure statuses and full logs, including partially built work.
run_logged() {
    log=$1; shift
    "$@" > "$log" 2>&1 || {
        result=$?
        cat "$log" >&2
        printf 'error: command failed (%s); log: %s\n' "$result" "$log" >&2
        exit "$result"
    }
}
# Project and compiler search-path isolation also applies to the probe.
unset GPR_PROJECT_PATH ADA_PROJECT_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
unset LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH
# GPR output directories belong to these physically exported projects, not an
# extending project in the native checkout. Prove the foreign boundary first.
probe="$work/tests/fixtures/cross-reference"
run_logged "$work/toolchain-probe.log" "${OPENCV_CROSS_GPRBUILD:-gprbuild}" --config="$work/config/target.cgpr" \
    -P "$probe/probe.gpr" -p -v -cargs:Ada "--sysroot=$ENV_PREFIX" \
    -largs "--sysroot=$ENV_PREFIX"
"${OPENCV_CROSS_READELF:-readelf}" -h "$probe/bin/probe" \
    > "$work/toolchain-probe-elf.log"
grep -q 'Machine:.*AArch64' "$work/toolchain-probe-elf.log" || fail 'GPR probe is not AArch64'
grep -q 'Class:.*ELF64' "$work/toolchain-probe-elf.log" || fail 'GPR probe is not ELF64'
grep -F "$OPENCV_CROSS_ADA" "$work/toolchain-probe.log" >/dev/null || fail 'GPR trace did not select supplied Ada compiler'
grep -F "$OPENCV_CROSS_CXX" "$work/toolchain-probe.log" >/dev/null || fail 'GPR trace did not select supplied linker'
if [ "$mode" = --build ]; then
    run_logged "$work/build.log" "${OPENCV_CROSS_GPRBUILD:-gprbuild}" --config=config/target.cgpr \
        -P opencv_core.gpr -p -v -cargs:Ada "--sysroot=$ENV_PREFIX" \
        -cargs:C++ "--sysroot=$ENV_PREFIX"
    run_logged "$work/install.log" "${OPENCV_CROSS_GPRINSTALL:-gprinstall}" --config=config/target.cgpr \
        -P opencv_core.gpr -p -r --prefix="$prefix"
    for project in opencv_core opencv_core_shim; do
        [ -f "$prefix/share/gpr/$project.gpr" ] || fail "missing installed project: $project"
    done
    for archive in lib/opencv_core/libopencv_core_ada.a lib/opencv_core_shim/libopencv_core_shim.a; do
        cross_elf "$prefix/$archive"
        "${OPENCV_CROSS_READELF:-readelf}" -h "$prefix/$archive" >> "$work/installed-archives-elf.log"
    done
    durable="$prefix/share/gprconfig"
    mkdir -p "$durable"
    cp config/target.cgpr "$durable/$target.cgpr"
    cp source-identity.txt "$durable/$target-source.txt"
    printf 'Installed prefix: %s\nConsumer configuration: %s/%s.cgpr\n' "$prefix" "$durable" "$target"
fi
printf 'Cross workspace: %s\nSource revision: %s\n' "$work" "$(cat source-revision.txt)"