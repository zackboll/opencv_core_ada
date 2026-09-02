#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
crate_root=$(dirname "$script_dir")
config="$crate_root/config/opencv_core_install.gpr"

if [ ! -f "$config" ]; then
    echo "error: generated OpenCV Core configuration is missing: $config" >&2
    exit 1
fi

shim_build=$(sed -n 's/.*Shim_Build : Shim_Build_Kind := "\(.*\)";/\1/p' "$config")
case "$shim_build" in
    Static_PIC|Relocatable)
        exit 0
        ;;
    External_Relocatable)
        ;;
    *)
        echo "error: unsupported OpenCV Core shim build: ${shim_build:-<missing>}" >&2
        exit 1
        ;;
esac

cxx_driver=$(sed -n 's/.*Cxx_Driver := "\(.*\)";/\1/p' "$config")
include_switch=$(sed -n 's/.*Include_Switch := "\(.*\)";/\1/p' "$config")
opencv_core_import_library=$(sed -n 's/.*OpenCV_Core_Link_Option := "\(.*\)";/\1/p' "$config")
source="$crate_root/tests/cpp/opencv_core_module_bridge_probe.cpp"
bridge_include="$crate_root/cpp"
object="$crate_root/tests/obj/module_bridge_probe/external/opencv_core_module_bridge_probe.o"
probe_dll="$crate_root/lib/opencv_core_module_bridge_probe.dll"
probe_import_library="$crate_root/lib/libopencv_core_module_bridge_probe.dll.a"
core_shim_import_library="$crate_root/lib/libopencv_core_shim.dll.a"

case "$cxx_driver" in
    *gnat_native*)
        echo "error: external C++ driver resolved to the GNAT toolchain: $cxx_driver" >&2
        exit 1
        ;;
esac

for required in "$cxx_driver" "$source" "$bridge_include" \
                "$opencv_core_import_library" "$core_shim_import_library"
do
    if [ ! -e "$required" ]; then
        echo "error: required module probe build input is missing: $required" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$object")" "$crate_root/lib"
rm -f "$object" "$probe_dll" "$probe_import_library"

compile_source=$source
compile_object=$object
compile_bridge_include=$bridge_include
link_object=$object
link_dll=$probe_dll
link_import_library=$probe_import_library
link_core_shim=$core_shim_import_library
link_opencv_core=$opencv_core_import_library

if command -v cygpath >/dev/null 2>&1; then
    compile_source=$(cygpath -m "$source")
    compile_object=$(cygpath -m "$object")
    compile_bridge_include=$(cygpath -m "$bridge_include")
    link_object=$compile_object
    link_dll=$(cygpath -m "$probe_dll")
    link_import_library=$(cygpath -m "$probe_import_library")
    link_core_shim=$(cygpath -m "$core_shim_import_library")
    link_opencv_core=$(cygpath -m "$opencv_core_import_library")
fi

echo "Building External_Relocatable OpenCV Core module bridge probe"
echo "C++ driver: $cxx_driver"
echo "Bridge include: $bridge_include"
echo "Probe DLL: $probe_dll"
echo "Core shim import library: $core_shim_import_library"

env -u CPATH -u C_INCLUDE_PATH -u CPLUS_INCLUDE_PATH \
    -u LIBRARY_PATH -u GCC_EXEC_PREFIX -u COMPILER_PATH \
    "$cxx_driver" -c -std=c++17 -Wall -Wextra -Wpedantic -Werror \
    "-I$compile_bridge_include" "$include_switch" \
    -o "$compile_object" "$compile_source"

env -u CPATH -u C_INCLUDE_PATH -u CPLUS_INCLUDE_PATH \
    -u LIBRARY_PATH -u GCC_EXEC_PREFIX -u COMPILER_PATH \
    "$cxx_driver" -shared -o "$link_dll" \
    "-Wl,--out-implib,$link_import_library" \
    "$link_object" "$link_core_shim" "$link_opencv_core"