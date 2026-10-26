#!/bin/sh
# Native parity and raw ABI controls against the actual production shim.
set -eu
root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
package=
for candidate in opencv5 opencv4; do
    if pkg-config --exists "$candidate"; then package=$candidate; break; fi
done
test -n "$package"
out="$root/tests/probes/obj-runtime-identity"
mkdir -p "$out"
cxx=${CXX:-g++}
flags=$(pkg-config --cflags "$package")
libs=$(pkg-config --libs-only-L "$package")
leaks=1
lifetime_link=
case "$(uname -s)" in
    Darwin)
        flags="$flags -Wno-error=c11-extensions"
        leaks=0
        echo 'Apple LeakSanitizer unsupported; ASan/UBSan enabled'
        # Preserve the previously qualified Apple ASan/TBB allocator lifetime.
        core_lib=$(pkg-config --variable=libdir "$package")/libopencv_core.dylib
        if otool -L "$core_lib" | grep -q libtbb; then
            allocator=$(brew --prefix tbb)/lib/libtbbmalloc.dylib
            test -f "$allocator"
            lifetime_link="-Wl,-needed_library,$allocator"
        fi
        ;;
esac
for mode in native sanitized; do
    sanitizers=
    if [ "$mode" = sanitized ]; then
        sanitizers='-fsanitize=address,undefined -fno-omit-frame-pointer'
    fi
    # Intentional splitting of compiler/pkg-config switches.
    # shellcheck disable=SC2086
    "$cxx" -std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror \
        $flags $sanitizers "$root/tests/probes/runtime_identity_shim_probe.cpp" \
        $libs -lopencv_core $lifetime_link -o "$out/$mode"
    # Execute outside the checkout; no runtime source-tree or cwd dependency.
    (cd /; ASAN_OPTIONS=detect_leaks=$leaks:halt_on_error=1 \
        UBSAN_OPTIONS=halt_on_error=1 "$out/$mode")
done