#!/bin/sh
# Run inside the selected Alire environment, before building OpenCV bindings.
set -eu

test "$(uname -s)" = Darwin
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/core-macos-link.XXXXXXXX")
echo "Native link probe evidence: $work"
git -C "$root" rev-parse HEAD
printf 'Runner image: %s %s\n' "${ImageOS:-unknown}" "${ImageVersion:-unknown}"
xcode-select -p
sdk=$(xcrun --sdk macosx --show-sdk-path)
echo "Selected Xcode SDK: $sdk"
test -f "$sdk/usr/lib/libSystem.tbd"
ls -ld /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
pkgutil --pkg-info=com.apple.pkg.CLTools_Executables
command -v g++
g++ --version
linker=$(g++ -print-prog-name=ld)
echo "GNAT g++ linker: $linker"
"$linker" -v 2>&1
g++ -### "$root/tests/macos_native_link_probe.cpp" -o "$work/default" 2>&1

# These two comparisons are diagnostic, not qualification. Preserve failures
# visibly; the explicit-syslibroot link and execution below must succeed.
if g++ -v "$root/tests/macos_native_link_probe.cpp" -o "$work/default" > "$work/default.log" 2>&1; then
    "$work/default"
    echo 'Default SDK link: PASS'
else
    cat "$work/default.log"
    echo 'Default SDK link: FAIL'
fi
if SDKROOT="$sdk" g++ -v "$root/tests/macos_native_link_probe.cpp" -o "$work/sdkroot" > "$work/sdkroot.log" 2>&1; then
    "$work/sdkroot"
    echo 'SDKROOT-only link: PASS'
else
    cat "$work/sdkroot.log"
    echo 'SDKROOT-only link: FAIL'
fi
if g++ -v "$root/tests/macos_native_link_probe.cpp" \
    "-Wl,-syslibroot,$sdk" -o "$work/linker-only" > "$work/linker-only.log" 2>&1; then
    "$work/linker-only"
    echo 'Linker-only syslibroot: PASS'
else
    cat "$work/linker-only.log"
    echo 'Linker-only syslibroot: FAIL'
fi
g++ -v "$root/tests/macos_native_link_probe.cpp" \
    "--sysroot=$sdk" -o "$work/explicit"
"$work/explicit"
file "$work/explicit"
otool -L "$work/explicit"
echo 'Explicit Xcode SDK native link: PASS'