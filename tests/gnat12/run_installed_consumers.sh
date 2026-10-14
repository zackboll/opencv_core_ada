#!/bin/sh
# Run inside an isolated Linux build environment after installing production.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work=${CONSUMER_WORK:?fresh absolute consumer evidence directory required}
case "$work" in /*) ;; *) exit 1;; esac
test ! -e "$work"
mkdir -p "$work"
cd "$root"
gprinstall -P opencv_core.gpr -p -r --prefix="$work/prefix-a" > "$work/install.log" 2>&1
package=
for candidate in opencv5 opencv4 opencv; do
    if pkg-config --exists "$candidate"; then package=$candidate; break; fi
done
test -n "$package"
include=$(pkg-config --cflags-only-I "$package" | tr ' ' '\n' | grep '^\-I' | tail -1)
test -n "$include"
for mode in installed relocated; do
    prefix="$work/prefix-a"
    if [ "$mode" = relocated ]; then
        prefix="$work/longer-relocated-prefix"
        mv "$work/prefix-a" "$prefix"
        test ! -e "$work/prefix-a"
    fi
    mkdir "$work/$mode"
    cp tests/installed_mat_consumer.adb tests/installed_mixed_consumer.adb \
        tests/installed_application.cpp tests/gnat12/installed_ada.gpr \
        tests/gnat12/installed_mixed.gpr "$work/$mode/"
    (
        unset ADA_PROJECT_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
        unset LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH
        export GPR_PROJECT_PATH="$prefix/share/gpr"
        cd "$work/$mode"
        for project in installed_ada installed_mixed; do
            gprbuild -P "$project.gpr" -p -v "-XCONSUMER_INCLUDE=$include" \
                > "$work/$mode-$project-build.log" 2>&1
        done
        for main in installed_mat_consumer installed_mixed_consumer; do
            "bin/$main" > "$work/$mode-$main-run.log" 2>&1
            readelf -d "bin/$main" > "$work/$mode-$main-elf.log"
            ldd -r "bin/$main" > "$work/$mode-$main-ldd.log" 2>&1
            grep 'libopencv_core' "$work/$mode-$main-ldd.log"
            grep 'libstdc++' "$work/$mode-$main-ldd.log"
            if grep -E 'not found|undefined symbol' "$work/$mode-$main-ldd.log"; then exit 1; fi
        done
        if grep -F "$root/" "$work/$mode-"*-build.log; then exit 1; fi
        if [ "$mode" = relocated ]; then
            if grep -F 'prefix-a/' "$work/$mode-"*-build.log "$work/$mode-"*-elf.log; then exit 1; fi
        fi
    )
done
echo 'PASS independent installed and relocated Ada/mixed consumers and ELF resolution'