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
shasum -a 256 "$resource/lib/darwin/libclang_rt.asan_osx_dynamic.dylib" \
    "$resource/lib/darwin/libclang_rt.ubsan_osx_dynamic.dylib"
otool -tvV "$tbb/lib/libtbb.dylib" > "$out/tbb-disassembly.txt"
# Actions uses a shallow checkout. Retrieve only the immutable starting-main
# object needed by control C, without changing the feature checkout or branch.
baseline=aa8a378ab614e9a5fc4f43765cd3ff1bbcf6a44d
if ! git cat-file -e "$baseline^{commit}"; then
    git fetch --depth=1 origin "$baseline"
fi
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
# Qualify the demonstrated same-library lifetime correction independently on
# native, unchanged-main shim and full feature. Default failures above remain
# recorded as failures, not reclassified as successful sanitizer executions.
needed="-Wl,-needed_library,$tbb/lib/libtbbmalloc.dylib"
"$cxx" $common $san $flags -DCONTROL_NATIVE "$source" $libs -lopencv_core \
    "$needed" -o "$out/native-needed-allocator"
"$cxx" $common $san $flags \
    "-DCONTROL_SHIM=\"$out/baseline/cpp/opencv_core_shim.cpp\"" \
    "$source" $libs -lopencv_core "$needed" -o "$out/baseline-needed-allocator"
"$cxx" $common $san $flags "$root/tests/probes/numerical_norms_shim_probe.cpp" \
    $libs -lopencv_core "$needed" \
    -o "$out/feature-needed-allocator"
for probe in native baseline feature; do
    dsymutil "$out/$probe-needed-allocator"
    otool -L "$out/$probe-needed-allocator"
    for repeat in 1 2 3; do
        run "$probe-needed-$repeat" "$out/$probe-needed-allocator"
    done
done
run asan-needed-positive "$out/native-needed-allocator" asan-positive
run ubsan-needed-positive "$out/native-needed-allocator" ubsan-positive
DYLD_PRINT_LIBRARIES=1 run feature-loader "$out/feature"
DYLD_PRINT_LIBRARIES=1 run allocator-loader "$out/feature-needed-allocator"
cat "$out/statuses.txt"
# A compatible configuration must preserve instrumentation AND normal teardown.
grep -qx 'clean 0' "$out/statuses.txt"
grep -qx 'native-mask 0' "$out/statuses.txt"
grep -qx 'allocator-loader 0' "$out/statuses.txt"
for probe in native baseline feature; do
    for repeat in 1 2 3; do
        grep -qx "$probe-needed-$repeat 0" "$out/statuses.txt"
    done
done
for prefix in '' needed-; do
    grep -q 'ERROR: AddressSanitizer: heap-use-after-free' "$out/asan-${prefix}positive.log"
    grep -q 'runtime error: signed integer overflow' "$out/ubsan-${prefix}positive.log"
    test "$(awk -v n="asan-${prefix}positive" '$1==n {print $2}' "$out/statuses.txt")" != 0
    test "$(awk -v n="ubsan-${prefix}positive" '$1==n {print $2}' "$out/statuses.txt")" != 0
done
echo 'PASS actual-shim ASan/UBSan with required same allocator and normal process exit'