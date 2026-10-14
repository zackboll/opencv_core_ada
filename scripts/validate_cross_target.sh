#!/bin/sh
# Naming only; callers separately verify compiler and GPR target agreement.
set -eu
target=${1:-}
[ -n "$target" ] || { echo 'error: OPENCV_CROSS_TARGET is required' >&2; exit 1; }
# Exact architecture, optional vendor component, explicit Linux OS, optional
# nonempty ABI components. No whitespace, punctuation, or empty components.
printf '%s\n' "$target" | LC_ALL=C grep -Eq \
    '^aarch64-([A-Za-z0-9_]+-)?linux(-[A-Za-z0-9_]+)*$' || {
    echo 'error: only well-formed AArch64 Linux targets are supported' >&2
    exit 1
}