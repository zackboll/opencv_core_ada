#!/bin/sh
# Run in the qualification image as root, with /evidence and /artifacts mounted.
# No recursive copies or traversal of the toolchain/source/archive trees.
set -eu
source_dir=$1
destination=$2
qualification_status=$3
mkdir -p "$destination"
chmod 0755 "$destination"
missing=0
collect() {
    source_file=$1
    target_name=$2
    if [ -e "$source_file" ]; then
        test -f "$source_file" && test -r "$source_file" || {
            echo "error: unreadable/nonregular evidence: $source_file" >&2
            exit 1
        }
        cp "$source_file" "$destination/$target_name"
        chmod 0644 "$destination/$target_name"
    else
        echo "Missing evidence: $target_name" >&2
        missing=1
    fi
}
for name in prepare.log consume.log qualification-status.log; do
    collect "$source_dir/$name" "$name"
done
# The work directory can exist even if preparation failed before its marker.
work=
for candidate in "$source_dir"/core-installed-consumer.*; do
    [ -d "$candidate" ] || continue
    if [ -n "$work" ]; then
        echo 'error: ambiguous evidence work directories' >&2
        exit 1
    fi
    work=$candidate
done
if [ -n "$work" ]; then
    collect "$work/toolchain-identities.log" toolchain-identities.log
    collect "$work/build-install.gpr" build-install.gpr
    for mode in installed relocated; do
        for suffix in build run mixed-build mixed-run resolution resolution-paths build-paths; do
            collect "$work/$mode-$suffix.log" "$mode-$suffix.log"
        done
        for consumer in installed_mat_consumer installed_mixed_consumer; do
            for suffix in elf ldd; do
                collect "$work/$mode-$consumer-$suffix.log" "$mode-$consumer-$suffix.log"
            done
        done
    done
    prefix="$work/prefix-a"
    if [ -d "$work/relocated-longer-prefix-b" ]; then
        prefix="$work/relocated-longer-prefix-b"
    fi
    for project in opencv_core opencv_core_shim; do
        collect "$prefix/share/gpr/$project.gpr" "$project.gpr"
    done
else
    echo 'Missing evidence: qualification work directory' >&2
    missing=1
fi
if [ "$qualification_status" -eq 0 ] && [ "$missing" -ne 0 ]; then
    echo 'error: successful qualification has incomplete mandatory evidence' >&2
    exit 1
fi
echo "Evidence staged in $destination (qualification status $qualification_status)"