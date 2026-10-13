#!/bin/sh
# Host-side Docker/Podman driver: consumer container never mounts the checkout.
set -eu
engine=${CONTAINER_ENGINE:-docker}
image=${CORE_CONSUMER_IMAGE:-opencv-core-ci-4.6}
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
evidence=${CORE_CONSUMER_EVIDENCE:-$(mktemp -d /tmp/core-ext-001.XXXXXXXX)}
mkdir -p "$evidence"
evidence=$(CDPATH= cd -- "$evidence" && pwd)
echo "Debian 12 independent qualification evidence: $evidence"
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
    '
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
    '
echo 'Debian 12 checkout-free, Alire-free consumer qualification PASS'