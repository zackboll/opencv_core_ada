#!/bin/sh
# Linux AArch64-only preflight. Native configuration never calls this implicitly.
set -eu
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
tool() {
    [ -n "$2" ] || fail "$1 is required"
    command -v "$2" || fail "$1 executable is unavailable: $2"
}
target=${OPENCV_CROSS_TARGET:-}
sh "$(dirname -- "$0")/validate_cross_target.sh" "$target"
[ -n "${ENV_PREFIX:-}" ] || fail 'ENV_PREFIX is required'
[ -d "$ENV_PREFIX" ] || fail 'target sysroot does not exist'
sysroot=$(CDPATH= cd -- "$ENV_PREFIX" && pwd -P)
[ "$sysroot" != / ] || fail 'a dedicated target sysroot is required'
case "$sysroot" in *' '*|*'	'*|*\"*|*\\*) fail 'whitespace/quotes/backslashes in sysroot are unsupported' ;; esac
ada=$(tool OPENCV_CROSS_ADA "${OPENCV_CROSS_ADA:-}")
[ "$("$ada" -dumpmachine)" = "$target" ] || fail 'Ada compiler target mismatch'
cxx=$(tool OPENCV_CROSS_CXX "${OPENCV_CROSS_CXX:-}")
[ "$("$cxx" -dumpmachine)" = "$target" ] || fail 'C++ compiler target mismatch'
# Compiler search-path variables can bypass --sysroot and project settings.
for variable in CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH ADA_INCLUDE_PATH ADA_OBJECTS_PATH ADA_PRJ_INCLUDE_FILE ADA_PRJ_OBJECTS_FILE; do
    eval "value=\${$variable:-}"
    [ -z "$value" ] || fail "cross mode requires empty $variable"
done
runtime=${OPENCV_CROSS_RUNTIME:-}
[ -d "$runtime/adalib" ] && [ -d "$runtime/adainclude" ] || fail 'OPENCV_CROSS_RUNTIME must contain adalib and adainclude'
readelf=$(tool OPENCV_CROSS_READELF "${OPENCV_CROSS_READELF:-readelf}")
elf() {
    [ -f "$1" ] || fail "missing target library: $1"
    details=$("$readelf" -h "$1") || fail "cannot inspect ELF: $1"
    printf '%s\n' "$details" | grep -q 'Machine:.*AArch64' || fail "not AArch64 ELF: $1"
    if printf '%s\n' "$details" | grep 'Machine:' | grep -v 'AArch64' >/dev/null; then
        fail "mixed architecture archive: $1"
    fi
    printf '%s\n' "$details" | grep -q 'Class:.*ELF64' || fail "not ELF64: $1"
}
elf "$runtime/adalib/libgnat.a"
selected_runtime=$(CDPATH= cd -- "$runtime/adalib" && pwd -P)
compiler_runtime=$("$ada" -print-file-name=adalib) || fail 'Ada compiler runtime query failed'
case "$compiler_runtime" in
    /*) [ -d "$compiler_runtime" ] || compiler_runtime= ;;
    *) compiler_runtime= ;;
esac
if [ -n "$compiler_runtime" ]; then
    compiler_runtime=$(CDPATH= cd -- "$compiler_runtime" && pwd -P)
    [ "$compiler_runtime" = "$selected_runtime" ] || fail 'Ada runtime differs from supplied compiler runtime'
else
    # Some GNAT Pro GCC drivers return the unresolved literal "adalib".
    # Never search PATH for a host gnatls, nor force the requested --RTS.
    compiler=$(realpath -e -- "$ada") || fail 'cannot resolve Ada compiler'
    compiler_directory=$(dirname -- "$compiler")
    compiler_name=$(basename -- "$compiler")
    case "$compiler_name" in
        gcc|gcc-[0-9]*|*-gcc|*-gcc-[0-9]*) ;;
        *) fail 'cannot derive matching GNATLS name from Ada compiler' ;;
    esac
    prefix=${compiler_name%%gcc*}
    suffix=${compiler_name#*gcc}
    gnatls=$compiler_directory/${prefix}gnatls${suffix}
    [ -x "$gnatls" ] || fail "matching GNATLS is unavailable: $gnatls"
    gnatls=$(realpath -e -- "$gnatls") || fail 'cannot resolve matching GNATLS'
    [ "$(dirname -- "$gnatls")" = "$compiler_directory" ] || fail 'GNATLS belongs to another toolchain directory'
    # Capture status before filtering: a failing gnatls may still print paths.
    search_paths=$(LC_ALL=C "$gnatls" -v 2>&1) || fail 'matching GNATLS execution failed'
    # Accept whitespace/CRLF variations and optional blank lines, but require
    # both complete sections. Every explicit path must identify this runtime;
    # accepting just one matching entry could hide a higher-priority runtime.
    paths=$(printf '%s\n' "$search_paths" | awk '
        { sub(/\r$/, ""); sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "") }
        /^Source Search Path[ \t]*:/ {
            if ($0 !~ /^Source Search Path[ \t]*:$/ || source++) exit 1
            section = "source"; next
        }
        /^Object Search Path[ \t]*:/ {
            if ($0 !~ /^Object Search Path[ \t]*:$/ || object++) exit 1
            section = "object"; next
        }
        /^[A-Za-z].*Search Path[ \t]*:/ { section = ""; next }
        section && NF {
            if ($0 == "<Current_Directory>") next
            if ($0 !~ /^\//) exit 1
            print section " " $0
            if (section == "source") sources++; else objects++
        }
        END { if (source != 1 || object != 1 || !sources || !objects) exit 1 }
    ') || fail 'missing or malformed GNATLS search paths'
    selected_source=$(CDPATH= cd -- "$runtime/adainclude" && pwd -P)
    printf '%s\n' "$paths" | while IFS=' ' read -r kind directory; do
        [ -d "$directory" ] || fail "GNATLS search directory is unavailable: $directory"
        physical=$(CDPATH= cd -- "$directory" && pwd -P) || fail 'cannot resolve GNATLS search directory'
        case "$kind" in
            source) expected=$selected_source ;;
            object) expected=$selected_runtime ;;
        esac
        [ "$physical" = "$expected" ] || fail "Ada runtime differs from supplied compiler runtime (GNATLS $kind: $directory)"
    done
fi
config=${OPENCV_CROSS_GPR_CONFIG:-}
[ -f "$config" ] || fail 'OPENCV_CROSS_GPR_CONFIG is required'
grep -F "for Target use \"$target\";" "$config" >/dev/null || fail 'GPR target mismatch'
grep -F "\"$ada\"" "$config" >/dev/null || fail 'GPR Ada compiler mismatch'
grep -F "\"$runtime/\"" "$config" >/dev/null || fail 'GPR Ada runtime mismatch'
grep -F "\"$cxx\"" "$config" >/dev/null || fail 'GPR C++ compiler mismatch'
grep -F "for Driver use Compiler'Driver (\"C++\");" "$config" >/dev/null || fail 'GPR linker must use supplied C++ driver'
pkg=$(tool OPENCV_CROSS_PKG_CONFIG "${OPENCV_CROSS_PKG_CONFIG:-pkg-config}")
[ -n "${PKG_CONFIG_LIBDIR:-}" ] || fail 'PKG_CONFIG_LIBDIR is required'
oldifs=$IFS; IFS=:
for directory in $PKG_CONFIG_LIBDIR; do
    [ -d "$directory" ] || fail 'pkg-config metadata directory is missing'
    resolved=$(CDPATH= cd -- "$directory" && pwd -P)
    case "$resolved/" in "$sysroot/"*) ;; *) fail 'host pkg-config contamination' ;; esac
done
IFS=$oldifs
[ -z "${PKG_CONFIG_PATH:-}" ] || fail 'PKG_CONFIG_PATH must be empty in cross mode'
[ "${PKG_CONFIG_SYSROOT_DIR:-$sysroot}" = "$sysroot" ] || fail 'pkg-config sysroot mismatch'
PKG_CONFIG_SYSROOT_DIR=$sysroot; export PKG_CONFIG_SYSROOT_DIR
package=
for candidate in opencv5 opencv4 opencv; do
    if "$pkg" --exists "$candidate"; then package=$candidate; break; fi
done
[ -n "$package" ] || fail 'target OpenCV pkg-config metadata is missing'
version=$("$pkg" --modversion "$package")
case "$version" in 4.[1-9]|4.[1-9].*|4.[1-9][0-9]*|5.0|5.0.*) ;; *) fail "unsupported OpenCV version: $version" ;; esac
# Reject dependency flags that escape the target filesystem. Only the Core
# dependency is linked below; all metadata is nevertheless checked for leakage.
flags=$("$pkg" --cflags --libs "$package")
header_tree() {
    # Follow local directory aliases and reject broken links, escapes and cycles.
    find -L "$1" -exec sh -c '
        sysroot=$1; shift
        for entry do
            canonical=$(realpath -e -- "$entry") || exit 1
            case "$canonical/" in "$sysroot/"*) ;; *)
                printf "error: OpenCV header path escapes sysroot: %s\n" "$entry" >&2
                exit 1 ;;
            esac
        done
    ' sh "$sysroot" {} + || fail 'invalid or escaping target OpenCV header tree'
}
contained_directory() {
    [ -d "$1" ] || fail 'missing pkg-config dependency directory'
    canonical=$(realpath -e -- "$1") || fail 'invalid pkg-config dependency directory'
    case "$canonical/" in "$sysroot/"*) ;; *) fail 'host pkg-config dependency path' ;; esac
}
for flag in $flags; do
    case "$flag" in
        -I*) path=${flag#??}; contained_directory "$path"; header_tree "$path" ;;
        -L*) path=${flag#??}; contained_directory "$path" ;;
        /*) case "$flag" in "$sysroot"/*) ;; *) fail 'host pkg-config dependency library' ;; esac ;;
        -D*|-l*|-pthread) ;;
        *) fail "unsupported target pkg-config flag: $flag" ;;
    esac
done
cflags=$("$pkg" --cflags "$package")
switches="\"--sysroot=$sysroot\""
for flag in $cflags; do
    case "$flag" in *\"*|*\\*) fail 'quoted pkg-config flags are unsupported' ;; esac
    switches="$switches, \"$flag\""
done
resolve() {
    case "$1" in "$sysroot"/*) path=$1 ;; /*) path=$sysroot$1 ;; *) fail 'OpenCV metadata path must be absolute' ;; esac
    [ -d "$path" ] || fail "missing target OpenCV directory: $path"
    path=$(CDPATH= cd -- "$path" && pwd -P)
    case "$path/" in "$sysroot/"*) printf '%s\n' "$path" ;; *) fail 'host OpenCV path' ;; esac
}
include=$(resolve "$("$pkg" --variable=includedir "$package")")
library=$(resolve "$("$pkg" --variable=libdir "$package")")
[ -f "$include/opencv2/core.hpp" ] || fail 'missing target OpenCV headers'
# Follow target-local directory aliases, inspecting every reachable entry.
# realpath -e rejects dangling links; find -L rejects directory-link cycles.
# Validate the whole include tree, since nested headers can escape independently
# of core.hpp. Batch arguments preserve filenames without line-based parsing.
header_tree "$include"
opencv=$library/libopencv_core.so
[ -f "$opencv" ] || opencv=$library/libopencv_core.a
resolved=$(realpath "$opencv") || fail 'missing target OpenCV libraries'
case "$resolved" in "$sysroot"/*) ;; *) fail 'OpenCV library escapes target sysroot' ;; esac
elf "$resolved"
# Inspect concrete target runtime objects; compiler triples alone cannot prove
# that a development sysroot contains matching libc and C++ libraries.
for name in libc.so.6 libstdc++.so.6; do
    found=$(find "$sysroot" -name "$name" -print | head -n 1)
    [ -n "$found" ] || fail "missing target runtime library: $name"
    found=$(realpath "$found") || fail "invalid target runtime symlink: $name"
    case "$found" in "$sysroot"/*) ;; *) fail "target runtime escapes sysroot: $name" ;; esac
    elf "$found"
done
case "$ada$cxx$runtime$sysroot$include$library" in *\"*|*'
'*) fail 'quotes/newlines in cross inputs are unsupported' ;; esac
printf 'Ada: %s\nC++: %s\nTarget: %s\nRuntime: %s\nSysroot: %s\nOpenCV: %s (%s)\n' "$ada" "$cxx" "$target" "$runtime" "$sysroot" "$version" "$resolved"
[ "${1:-}" != --check ] || exit 0
mkdir -p config
printf '%s\n' \
    '-- Generated target-only configuration; do not edit.' \
    'abstract project OpenCV_Core_Install is' \
    '   type Shim_Build_Kind is ("Static_PIC", "Relocatable", "External_Relocatable");' \
    '   type Cxx_Toolchain_Kind is ("GNU", "Apple_Clang");' \
    '   type Ada_Link_Kind is ("Default", "Shared_Shim_Static_GCC_Runtime");' \
    '   Shim_Build : Shim_Build_Kind := "Static_PIC";' \
    '   Cxx_Toolchain : Cxx_Toolchain_Kind := "GNU";' \
    '   Ada_Link : Ada_Link_Kind := "Default";' \
    "   Include_Switch := \"-I$include\";" \
    "   Library_Search_Switch := \"-L$library\";" \
    "   OpenCV_Core_Link_Option := \"$resolved\";" \
    '   Cxx_Runtime_Switch := "-lstdc++";' \
    "   Cxx_Driver := \"$cxx\";" \
    "   Cxx_Sysroot := \"$sysroot\";" \
    "   Cross_Compiler_Switches := ($switches);" \
    "   Cross_Linker_Switches := (\"--sysroot=$sysroot\");" \
    'end OpenCV_Core_Install;' > config/opencv_core_install.gpr