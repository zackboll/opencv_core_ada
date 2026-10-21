#!/bin/sh
# Actual production shim, native oracle, negative ABI and sanitizer campaign.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
package=
for candidate in opencv5 opencv4; do
    if pkg-config --exists "$candidate"; then package=$candidate; break; fi
done
test -n "$package"
out="$root/tests/probes/obj-numerical-native"
mkdir -p "$out"
cxx=${CXX:-g++}
flags=$(pkg-config --cflags "$package")
case "$(uname -s)" in
    Darwin) flags="$flags -Wno-error=c11-extensions" ;;
esac
libs=$(pkg-config --libs-only-L "$package")
# Independent control records all depths/C1..C4, both orders, empty/partial
# selection and optimized/IPP-disabled/generic dispatch, before shim testing.
# shellcheck disable=SC2086
"$cxx" -std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror $flags \
    "$root/tests/probes/numerical_norms_native_mask.cpp" $libs -lopencv_core \
    -o "$out/native-mask"
"$out/native-mask"
# Intentional splitting of compiler/pkg-config switches.
# shellcheck disable=SC2086
"$cxx" -std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror $flags \
    "$root/tests/probes/numerical_norms_shim_probe.cpp" $libs -lopencv_core \
    -o "$out/native"
"$out/native"
# shellcheck disable=SC2086
"$cxx" -std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror \
    -fsanitize=address,undefined -fno-omit-frame-pointer $flags \
    "$root/tests/probes/numerical_norms_shim_probe.cpp" $libs -lopencv_core \
    -o "$out/shim"
leaks=1
case "$(uname -s)" in
    Darwin)
        # Apple's ASan runtime does not implement LeakSanitizer.
        leaks=0
        echo 'LeakSanitizer unsupported by Apple runtime; ASan/UBSan remain enabled'
        ;;
esac
ASAN_OPTIONS=detect_leaks=$leaks:halt_on_error=1 \
UBSAN_OPTIONS=halt_on_error=1 "$out/shim"