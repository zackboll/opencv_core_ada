#!/bin/sh
# Manual public-reference qualification, inside a prepared Debian 12 container.
# Install public prerequisites separately; this script never installs tools.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
base=${1:?supply a new absolute evidence directory}
case "$base" in /*) ;; *) echo 'absolute evidence directory required' >&2; exit 1 ;; esac
test ! -e "$base"
mkdir -p "$base/sysroot/usr/lib/pkgconfig" "$base/sysroot/usr/include" "$base/tools"
cp -a /usr/aarch64-linux-gnu/include/. "$base/sysroot/usr/include/"
cp -a /usr/aarch64-linux-gnu/lib/. "$base/sysroot/usr/lib/"
cp -a /usr/include/opencv4 "$base/sysroot/usr/include/"
cp -L /usr/lib/aarch64-linux-gnu/libopencv_core.so "$base/sysroot/usr/lib/libopencv_core.so"
cp "$root/tests/fixtures/cross-reference/opencv4.pc" "$base/sysroot/usr/lib/pkgconfig/"
ln -s /usr/bin/aarch64-linux-gnu-g++ "$base/tools/g++"
export ENV_PREFIX="$base/sysroot"
export OPENCV_CROSS_TARGET=aarch64-linux-gnu
export OPENCV_CROSS_ADA=/usr/bin/aarch64-linux-gnu-gcc
export OPENCV_CROSS_CXX="$base/tools/g++"
export OPENCV_CROSS_RUNTIME=/usr/lib/gcc-cross/aarch64-linux-gnu/12
export OPENCV_CROSS_GPR_CONFIG="$base/target.cgpr"
export PKG_CONFIG_LIBDIR="$base/sysroot/usr/lib/pkgconfig"
export PKG_CONFIG_PATH=
export OPENCV_CROSS_GPRBUILD=${OPENCV_CROSS_GPRBUILD:-gprbuild}
"${OPENCV_CROSS_GPRCONFIG:-gprconfig}" --batch --target="$OPENCV_CROSS_TARGET" \
    --config="Ada,,$OPENCV_CROSS_RUNTIME" --config="C++,,,$base/tools" \
    -o "$OPENCV_CROSS_GPR_CONFIG"
dpkg-query -W gnat-12-aarch64-linux-gnu g++-12-aarch64-linux-gnu \
    libopencv-core-dev:arm64 libgnat-12-arm64-cross > "$base/packages.log"
"$OPENCV_CROSS_ADA" --version > "$base/ada-version.log"
"$OPENCV_CROSS_CXX" --version > "$base/cxx-version.log"
readelf -d "$base/sysroot/usr/lib/libopencv_core.so" > "$base/opencv-elf.log"
sh "$root/scripts/cross_build_core.sh" --build "$base/workspace" \
    > "$base/cross-build.log" 2>&1 || {
        cat "$base/cross-build.log"
        echo 'Production cross-build failed; no consumer/runtime qualification.' >&2
        exit 1
    }