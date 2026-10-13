#!/bin/sh
# Host-side Docker/Podman driver: consumer container never mounts the checkout.
set -eu
engine=${CONTAINER_ENGINE:-docker}
image=${CORE_CONSUMER_IMAGE:-opencv-core-ci-4.6}
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
evidence=${CORE_CONSUMER_EVIDENCE:-$(mktemp -d /tmp/core-ext-001.XXXXXXXX)}
mkdir -p "$evidence"
evidence=$(CDPATH= cd -- "$evidence" && pwd)
artifacts=${CORE_CONSUMER_ARTIFACTS:-"$evidence-artifacts"}
mkdir -p "$artifacts"
artifacts=$(CDPATH= cd -- "$artifacts" && pwd)
case "$artifacts/" in
    "$evidence/"*) echo 'error: artifacts must be outside private evidence' >&2; exit 1 ;;
esac
test -z "$(ls -A "$artifacts")" || {
    echo 'error: artifact destination must be empty' >&2; exit 1;
}
stage_on_exit() {
    primary_status=$?
    trap - EXIT
    printf 'Qualification exit status: %s\n' "$primary_status" > "$evidence/qualification-status.log"
    staging_status=0
    "$engine" run --rm -v "$evidence:/evidence:ro" -v "$artifacts:/artifacts" \
        -v "$root/scripts/stage_debian12_consumer_evidence.sh:/stage.sh:ro" \
        "$image" sh /stage.sh /evidence /artifacts "$primary_status" || staging_status=$?
    if [ "$staging_status" -ne 0 ]; then
        echo "error: evidence staging failed (status $staging_status)" >&2
    fi
    if [ "$primary_status" -ne 0 ]; then
        exit "$primary_status"
    fi
    exit "$staging_status"
}
trap stage_on_exit EXIT
echo "Debian 12 independent qualification evidence: $evidence"
echo "Runner-readable qualification artifacts: $artifacts"
prepare_status=0
"$engine" run --rm -v "$root:/workspace" -v "$evidence:/evidence" \
    -e TMPDIR=/evidence -e CORE_INSTALLED_PREPARE_ONLY=True "$image" sh -c '
    set -eu
    test "$(pkg-config --modversion opencv4)" = 4.6.0
    cat /etc/debian_version
    alr --version
    alr toolchain
    dpkg-query -W libopencv-dev libopencv-core406 libstdc++6 libc6 binutils
    sh scripts/validate_installed_mat_consumer.sh /workspace
    cp -a /root/.local/share/alire/toolchains /evidence/toolchains
    ' > "$evidence/prepare.log" 2>&1 || prepare_status=$?
cat "$evidence/prepare.log"
if [ "$prepare_status" -ne 0 ]; then
    exit "$prepare_status"
fi
consume_status=0
"$engine" run --rm -v "$evidence:/evidence" \
    -v "$evidence/toolchains:/root/.local/share/alire/toolchains:ro" \
    -e CORE_DEBIAN_QUALIFICATION=True "$image" sh -c '
    set -eu
    test ! -e /workspace/src/opencv-core.ads
    # Remove Alire itself: accidental consumer-side invocation cannot succeed.
    rm /usr/local/bin/alr
    work=$(cat /evidence/prepared-work.txt)
    cd /evidence
    sh "$work/consume.sh" --consume "$work" /workspace
    ' > "$evidence/consume.log" 2>&1 || consume_status=$?
cat "$evidence/consume.log"
if [ "$consume_status" -ne 0 ]; then
    exit "$consume_status"
fi
echo 'Debian 12 checkout-free, Alire-free consumer qualification PASS'