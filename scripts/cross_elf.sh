# Shared Linux AArch64 ELF validation, including every ELF archive member.
# Sourced by the cross preflight and production installer; fail() is supplied.
cross_elf() {
    [ -f "$1" ] || fail "missing target library: $1"
    details=$("${OPENCV_CROSS_READELF:-readelf}" -h "$1") || fail "cannot inspect ELF: $1"
    printf '%s\n' "$details" | grep -q 'Machine:.*AArch64' || fail "not AArch64 ELF: $1"
    if printf '%s\n' "$details" | grep 'Machine:' | grep -v 'AArch64' >/dev/null; then
        fail "mixed architecture archive: $1"
    fi
    printf '%s\n' "$details" | grep -q 'Class:.*ELF64' || fail "not ELF64: $1"
    if printf '%s\n' "$details" | grep 'Class:' | grep -v 'ELF64' >/dev/null; then
        fail "mixed ELF class archive: $1"
    fi
}