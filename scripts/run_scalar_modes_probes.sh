#!/bin/sh
# Focused native and actual-shim probes. Native backend is pkg-config selected.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
package=
for candidate in opencv5 opencv4; do
    if pkg-config --exists "$candidate"; then package=$candidate; break; fi
done
test -n "$package"
out="$root/tests/probes/obj-scalar-native"
mkdir -p "$out"
cxx=${CXX:-g++}
flags=$(pkg-config --cflags "$package")
libs=$(pkg-config --libs-only-L "$package")
# Intentional splitting of compiler/pkg-config switch lists.
# shellcheck disable=SC2086
"$cxx" -std=c++17 -Wall -Wextra -Wpedantic -Werror $flags \
    "$root/tests/probes/scalar_modes_probe.cpp" $libs -lopencv_core \
    -o "$out/native"
"$out/native"
# shellcheck disable=SC2086
"$cxx" -std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror \
    -fsanitize=address,undefined -fno-omit-frame-pointer $flags \
    "$root/tests/probes/scalar_modes_shim_probe.cpp" $libs -lopencv_core \
    -o "$out/shim"
"$out/shim"