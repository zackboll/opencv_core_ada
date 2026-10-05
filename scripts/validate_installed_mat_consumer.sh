#!/bin/sh
# Recursive GPRinstall, then fresh prefix-only Mat consumers before/after moving.
# Run directly, not inside alr exec. Keep the evidence directory on failure.
set -eu
root=$(CDPATH= cd -- "${1:-$(dirname -- "$0")/..}" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/core-installed-consumer.XXXXXXXX")
echo "Core installed consumer evidence: $work"
unset GPR_PROJECT_PATH ADA_PROJECT_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
unset LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH LD_LIBRARY_PATH DYLD_LIBRARY_PATH
cd "$root"
alr -n build
alr -n exec -- gprinstall -f -p -r --prefix="$work/prefix-a" -P opencv_core.gpr
cmp cpp/opencv_core_module_bridge.hpp "$work/prefix-a/include/opencv_core_module_bridge.hpp"
alr -n exec -- sh -c '
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -up "$PATH"
    else
        printf "%s\n" "$PATH"
    fi
' > "$work/toolchain-path.txt"
tr ':' '\n' < "$work/toolchain-path.txt" | while IFS= read -r directory; do
    case "$directory" in
        "$root"|"$root"/*) ;;
        *) printf '%s\n' "$directory" ;;
    esac
done > "$work/sanitized-path.txt"
PATH=$(paste -sd ':' "$work/sanitized-path.txt"); export PATH
unset OPENCV_CORE_ALIRE_PREFIX ALIRE
driver=$(sed -n 's/.*Cxx_Driver := "\(.*\)";/\1/p' config/opencv_core_install.gpr)
native_bin=
case "$(uname -s)" in
    MINGW*|MSYS*)
        native_bin=$(cygpath -u "$(dirname "$driver")")
        for name in libopencv_core_shim.dll libopencv_core_shim.dll.a; do
            cmp "lib/$name" "$work/prefix-a/lib/opencv_core_shim/$name"
        done
        test -f "$work/prefix-a/bin/libopencv_core_shim.dll"
        test ! -f "$work/prefix-a/lib/opencv_core_shim/libopencv_core_shim.a"
        "$native_bin/objdump.exe" -p "$work/prefix-a/bin/libopencv_core_shim.dll" \
            > "$work/installed-shim-pe.log"
        grep -i 'DLL Name.*opencv_core' "$work/installed-shim-pe.log"
        echo 'External Core DLL/import archive installed VERIFIED' ;;
esac
for mode in installed relocated; do
    prefix="$work/prefix-a"
    if [ "$mode" = relocated ]; then
        prefix="$work/relocated-longer-prefix-b"
        mv "$work/prefix-a" "$prefix"
        test ! -e "$work/prefix-a" && test ! -L "$work/prefix-a"
        echo 'Original Core prefix removed VERIFIED'
    fi
    consumer="$work/$mode"
    mkdir -p "$consumer"
    cp tests/installed_mat_consumer.adb "$consumer/"
    cat > "$consumer/consumer.gpr" <<'GPR'
with "opencv_core";
project Consumer is
   for Source_Dirs use (".");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("installed_mat_consumer.adb");
   type Static_Runtime_Kind is ("False", "True");
   Static_Runtime : Static_Runtime_Kind :=
     external ("CORE_CONSUMER_STATIC_RUNTIME", "False");
   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2022", "-gnatwa", "-gnatwe");
   end Compiler;
   package Binder is
      case Static_Runtime is
         when "True" =>
            for Switches ("Ada") use ("-static");
         when "False" =>
            null;
      end case;
   end Binder;
   package Linker is
      for Driver use "gcc";
      case Static_Runtime is
         when "True" =>
            for Trailing_Switches ("Ada") use ("-static-libgcc");
         when "False" =>
            null;
      end case;
   end Linker;
end Consumer;
GPR
    (
        trace_prefix="$prefix"
        trace_root="$root"
        case "$(uname -s)" in
            MINGW*|MSYS*)
                GPR_PROJECT_PATH=$(cygpath -m "$prefix/share/gpr")
                trace_prefix=$(cygpath -m "$prefix")
                trace_root=$(cygpath -m "$root")
                export CORE_CONSUMER_STATIC_RUNTIME=True ;;
            *) GPR_PROJECT_PATH="$prefix/share/gpr" ;;
        esac
        export GPR_PROJECT_PATH
        cd "$consumer"
        gprbuild -p -v -vP2 -P consumer.gpr > "$work/$mode-build.log" 2>&1 || {
            cat "$work/$mode-build.log"; exit 1;
        }
        grep -F "$trace_prefix/share/gpr/opencv_core.gpr" "$work/$mode-build.log"
        grep -F "$trace_prefix/lib/opencv_core" "$work/$mode-build.log"
        if grep -F "$trace_root/lib" "$work/$mode-build.log"; then
            echo 'error: installed consumer used source library path' >&2; exit 1
        fi
        if [ "$mode" = relocated ] && grep -F 'prefix-a/' "$work/$mode-build.log"; then
            echo 'error: relocated consumer used original prefix' >&2; exit 1
        fi
        runtime_dirs=$(find "$prefix/lib" "$prefix/bin" -type d 2>/dev/null | paste -sd ':' -)
        binary=bin/installed_mat_consumer
        case "$(uname -s)" in
            Linux) export LD_LIBRARY_PATH="$runtime_dirs" ;;
            Darwin) export DYLD_LIBRARY_PATH="$runtime_dirs" ;;
            MINGW*|MSYS*)
                binary="$binary.exe"
                PATH="$runtime_dirs:$native_bin:$PATH"; export PATH
                "$native_bin/objdump.exe" -p "$binary" > "$work/$mode-pe.log"
                grep -i 'DLL Name.*opencv_core_shim' "$work/$mode-pe.log" ;;
        esac
        "$binary" > "$work/$mode-run.log" 2>&1 || {
            cat "$work/$mode-run.log"; exit 1;
        }
        cat "$work/$mode-run.log"
        grep -Fx 'opencv_core installed Mat consumer ok' "$work/$mode-run.log"
    )
    echo "Core $mode consumer PASS"
done
echo 'Core recursive install and fresh relocation PASS'