#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
crate_root=$(dirname "$script_dir")
config="$crate_root/config/opencv_core_install.gpr"

if [ ! -f "$config" ]; then
    echo "error: generated OpenCV Core configuration is missing: $config" >&2
    exit 1
fi

config_value() {
    sed -n "s/.*$1 := \"\\(.*\\)\";/\\1/p" "$config"
}

shim_build=$(sed -n 's/.*Shim_Build : Shim_Build_Kind := "\(.*\)";/\1/p' "$config")
cxx_toolchain=$(sed -n 's/.*Cxx_Toolchain : Cxx_Toolchain_Kind := "\(.*\)";/\1/p' "$config")
cxx_driver=$(config_value Cxx_Driver)
include_switch=$(config_value Include_Switch)
library_search_switch=$(config_value Library_Search_Switch)
opencv_core_link_option=$(config_value OpenCV_Core_Link_Option)
cxx_runtime_switch=$(config_value Cxx_Runtime_Switch)
cxx_sysroot=$(config_value Cxx_Sysroot)
source="$crate_root/tests/cpp/opencv_core_module_bridge_probe.cpp"
bridge_include="$crate_root/cpp"

case "$shim_build:$cxx_toolchain:$(uname -s)" in
    Static_PIC:*)
        # Linux retains the GPR-built probe object path.
        exit 0
        ;;
    External_Relocatable:*)
        probe_kind=windows
        ;;
    Relocatable:Apple_Clang:Darwin)
        probe_kind=darwin
        ;;
    Relocatable:*)
        echo "error: Relocatable module bridge probes are supported only for Darwin with Apple_Clang" >&2
        exit 1
        ;;
    *)
        echo "error: unsupported OpenCV Core module probe configuration: ${shim_build:-<missing>}/${cxx_toolchain:-<missing>}" >&2
        exit 1
        ;;
esac

case "$cxx_driver" in
    *gnat_native*)
        echo "error: external C++ driver resolved to the GNAT toolchain: $cxx_driver" >&2
        exit 1
        ;;
esac

case "$probe_kind" in
    windows)
        object="$crate_root/tests/obj/module_bridge_probe/external/opencv_core_module_bridge_probe.o"
        probe_library="$crate_root/lib/opencv_core_module_bridge_probe.dll"
        probe_import_library="$crate_root/lib/libopencv_core_module_bridge_probe.dll.a"
        core_shim_library="$crate_root/lib/libopencv_core_shim.dll.a"
        ;;
    darwin)
        object="$crate_root/tests/obj/module_bridge_probe/darwin/opencv_core_module_bridge_probe.o"
        probe_library="$crate_root/lib/libopencv_core_module_bridge_probe.dylib"
        core_shim_library="$crate_root/lib/libopencv_core_shim.dylib"
        ;;
esac

for required in "$cxx_driver" "$source" "$bridge_include" "$core_shim_library"
do
    if [ ! -e "$required" ]; then
        echo "error: required module probe build input is missing: $required" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$object")" "$crate_root/lib"
rm -f "$object" "$probe_library"

compile_source=$source
compile_object=$object
compile_bridge_include=$bridge_include
link_object=$object
link_library=$probe_library
link_core_shim=$core_shim_library

case "$probe_kind" in
    windows)
        rm -f "$probe_import_library"
        if [ ! -e "$opencv_core_link_option" ]; then
            echo "error: required module probe build input is missing: $opencv_core_link_option" >&2
            exit 1
        fi

        link_import_library=$probe_import_library
        link_opencv_core=$opencv_core_link_option

        # Native MinGW g++.exe accepts MSYS paths inconsistently. Preserve the
        # path conversion used by the previously validated Windows CI build.
        if command -v cygpath >/dev/null 2>&1; then
            compile_source=$(cygpath -m "$source")
            compile_object=$(cygpath -m "$object")
            compile_bridge_include=$(cygpath -m "$bridge_include")
            link_object=$compile_object
            link_library=$(cygpath -m "$probe_library")
            link_import_library=$(cygpath -m "$probe_import_library")
            link_core_shim=$(cygpath -m "$core_shim_library")
            link_opencv_core=$(cygpath -m "$opencv_core_link_option")
        fi
        ;;
    darwin)
        if [ -z "$cxx_sysroot" ]; then
            echo "error: Apple_Clang module probe build requires Cxx_Sysroot" >&2
            exit 1
        fi
        ;;
esac

echo "Building ${shim_build} OpenCV Core module bridge probe (${probe_kind})"
echo "C++ driver: $cxx_driver"
echo "Bridge include: $bridge_include"
echo "Probe library: $probe_library"
echo "Core shim library: $core_shim_library"

case "$probe_kind" in
    windows)
        env -u CPATH -u C_INCLUDE_PATH -u CPLUS_INCLUDE_PATH \
            -u LIBRARY_PATH -u GCC_EXEC_PREFIX -u COMPILER_PATH \
            "$cxx_driver" -c -std=c++17 -Wall -Wextra -Wpedantic -Werror \
            "-I$compile_bridge_include" "$include_switch" \
            -o "$compile_object" "$compile_source"

        env -u CPATH -u C_INCLUDE_PATH -u CPLUS_INCLUDE_PATH \
            -u LIBRARY_PATH -u GCC_EXEC_PREFIX -u COMPILER_PATH \
            "$cxx_driver" -shared -o "$link_library" \
            "-Wl,--out-implib,$link_import_library" \
            "$link_object" "$link_core_shim" "$link_opencv_core"
        ;;
    darwin)
        env -u CPATH -u C_INCLUDE_PATH -u CPLUS_INCLUDE_PATH \
            -u LIBRARY_PATH -u GCC_EXEC_PREFIX -u COMPILER_PATH \
            "$cxx_driver" -c -std=c++17 -Wall -Wextra -Wpedantic -Werror \
            -Wno-error=c11-extensions \
            "-I$compile_bridge_include" "$include_switch" \
            -isysroot "$cxx_sysroot" -o "$compile_object" "$compile_source"

        env -u CPATH -u C_INCLUDE_PATH -u CPLUS_INCLUDE_PATH \
            -u LIBRARY_PATH -u GCC_EXEC_PREFIX -u COMPILER_PATH \
            "$cxx_driver" -dynamiclib -isysroot "$cxx_sysroot" \
            -Wl,-install_name,@rpath/libopencv_core_module_bridge_probe.dylib \
            -Wl,-rpath,@loader_path -o "$link_library" "$link_object" \
            "$link_core_shim" "$library_search_switch" \
            "$opencv_core_link_option" "$cxx_runtime_switch"
        ;;
esac
