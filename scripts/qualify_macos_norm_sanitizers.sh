#!/bin/sh
# Bounded investigation: retain failures and normal process-exit evidence.
set -eu
test "$(uname -s)" = Darwin
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
out=${NORM_SANITIZER_EVIDENCE:?absolute evidence directory required}
mkdir -p "$out/baseline"
exec > "$out/campaign.log" 2>&1
set -x
cd "$root"
git rev-parse HEAD HEAD^{tree}
uname -a
sw_vers
printf 'ImageOS=%s ImageVersion=%s\n' "${ImageOS-}" "${ImageVersion-}"
cxx=/usr/bin/clang++
"$cxx" --version
"$cxx" -print-resource-dir
xcrun --show-sdk-path
brew list --versions opencv tbb hwloc
brew info --json=v2 opencv tbb hwloc > "$out/brew.json"
package=opencv5
pkg-config --exists "$package" || package=opencv4
pkg-config --modversion "$package"
flags=$(pkg-config --cflags "$package")
libs=$(pkg-config --libs-only-L "$package")
opencv=$(brew --prefix opencv)
tbb=$(brew --prefix tbb)
for library in "$opencv"/lib/libopencv_core*.dylib "$tbb"/lib/libtbb*.dylib; do
    shasum -a 256 "$library"
    otool -L "$library"
done
resource=$("$cxx" -print-resource-dir)
find "$resource/lib/darwin" -name '*asan*' -o -name '*ubsan*'
git archive aa8a378ab614e9a5fc4f43765cd3ff1bbcf6a44d cpp | tar -x -C "$out/baseline"
shasum -a 256 "$out/baseline/cpp/opencv_core_shim.cpp" cpp/opencv_core_shim.cpp
common="-std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror -Wno-c11-extensions"
san="-fsanitize=address,undefined -fno-omit-frame-pointer"
export ASAN_OPTIONS=detect_leaks=0:halt_on_error=1:symbolize=1
export UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1
: > "$out/statuses.txt"
export ASAN_SYMBOLIZER_PATH
ASAN_SYMBOLIZER_PATH=$(xcrun --find llvm-symbolizer 2>/dev/null || true)
if [ -z "$ASAN_SYMBOLIZER_PATH" ]; then unset ASAN_SYMBOLIZER_PATH; fi
run() {
    name=$1; shift
    status=0
    "$@" > "$out/$name.log" 2>&1 || status=$?
    printf '%s %s\n' "$name" "$status" >> "$out/statuses.txt"
    cat "$out/$name.log"
    return 0
}
source="$root/tests/probes/numerical_norms_sanitizer_control.cpp"
# Deliberate splitting of compiler flag lists; all paths passed separately.
"$cxx" $common $san "$source" -o "$out/clean"
"$cxx" $common $san $flags -DCONTROL_NATIVE "$source" $libs -lopencv_core -o "$out/native"
"$cxx" $common $san $flags \
    "-DCONTROL_SHIM=\"$out/baseline/cpp/opencv_core_shim.cpp\"" \
    "$source" $libs -lopencv_core -o "$out/baseline-shim"
"$cxx" $common $san $flags "$root/tests/probes/numerical_norms_shim_probe.cpp" \
    $libs -lopencv_core -o "$out/feature"
for probe in clean native baseline-shim feature; do
    dsymutil "$out/$probe"
    otool -L "$out/$probe"
    run "$probe" "$out/$probe"
done
"$cxx" $common $flags "$root/tests/probes/numerical_norms_native_mask.cpp" \
    $libs -lopencv_core -o "$out/native-mask"
run native-mask "$out/native-mask"
run asan-positive "$out/clean" asan-positive
run ubsan-positive "$out/clean" ubsan-positive
# Hypothesis control, not a waiver: retaining the actual allocator dependency
# may prevent a dynamic-unload callback lifetime issue. Only normal exits count.
"$cxx" $common $san $flags "$root/tests/probes/numerical_norms_shim_probe.cpp" \
    $libs -lopencv_core "-Wl,-needed_library,$tbb/lib/libtbbmalloc.dylib" \
    -o "$out/feature-needed-allocator"
dsymutil "$out/feature-needed-allocator"
otool -L "$out/feature-needed-allocator"
run feature-needed-allocator "$out/feature-needed-allocator"
DYLD_PRINT_LIBRARIES=1 run feature-loader "$out/feature"
DYLD_PRINT_LIBRARIES=1 run allocator-loader "$out/feature-needed-allocator"
cat "$out/statuses.txt"
# A failed default control remains a failed gate, even if the hypothesis works.
grep -qx 'clean 0' "$out/statuses.txt"
grep -qx 'native 0' "$out/statuses.txt"
grep -qx 'baseline-shim 0' "$out/statuses.txt"
grep -qx 'feature 0' "$out/statuses.txt"
grep -q 'ERROR: AddressSanitizer: heap-use-after-free' "$out/asan-positive.log"
grep -q 'runtime error: signed integer overflow' "$out/ubsan-positive.log"
test "$(awk '$1=="asan-positive" {print $2}' "$out/statuses.txt")" != 0
test "$(awk '$1=="ubsan-positive" {print $2}' "$out/statuses.txt")" != 0