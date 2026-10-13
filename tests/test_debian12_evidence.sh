#!/bin/sh
# Independent inventory, byte stability, restrictive root ownership, and failures.
set -eu
engine=${CONTAINER_ENGINE:-docker}
image=${CORE_CONSUMER_IMAGE:-opencv-core-ci-4.6}
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
artifacts=$1
evidence=$2
test_dir=$(mktemp -d /tmp/core-evidence-test.XXXXXXXX)
"$engine" run --rm -v "$root:/checks:ro" -v "$artifacts:/published:ro" \
    -v "$evidence:/evidence:ro" -v "$test_dir:/test" "$image" sh -c '
    set -eu
    find /published -maxdepth 1 -type f -printf "%f\n" | LC_ALL=C sort > /test/actual.txt
    diff -u /checks/tests/debian12_evidence_expected.txt /test/actual.txt
    test "$(find /published -type d | wc -l)" -eq 1
    work=$(cat /evidence/prepared-work.txt)
    for name in $(cat /checks/tests/debian12_evidence_expected.txt); do
        case "$name" in
            prepare.log|consume.log|qualification-status.log) original=/evidence/$name ;;
            opencv_core.gpr|opencv_core_shim.gpr)
                original=$work/relocated-longer-prefix-b/share/gpr/$name ;;
            *) original=$work/$name ;;
        esac
        cmp "$original" "/published/$name"
    done
    mkdir -m 0700 /test/private
    cp -a "$work" /test/private/core-installed-consumer.fixture
    # Deliberately restricted root-owned tree, including a forbidden binary.
    chmod 0700 /test/private/core-installed-consumer.fixture
    mkdir -m 0700 /test/private/toolchains
    cp /bin/true /test/private/toolchains/compiler
    cp /evidence/prepare.log /evidence/consume.log /evidence/qualification-status.log /test/private/
    sh /checks/scripts/stage_debian12_consumer_evidence.sh /test/private /test/staged 0
    find /test/staged -type f -printf "%f\n" | LC_ALL=C sort > /test/fixture.txt
    diff -u /checks/tests/debian12_evidence_expected.txt /test/fixture.txt
    chmod 0755 /test
    # nobody is a distinct unprivileged UID: private evidence stays inaccessible.
    su -s /bin/sh nobody -c "test ! -r /test/private/core-installed-consumer.fixture/toolchain-identities.log"
    su -s /bin/sh nobody -c "find /test/staged -type f -exec cat {} + > /dev/null"
    for name in $(cat /checks/tests/debian12_evidence_expected.txt); do
        cmp "/published/$name" "/test/staged/$name"
    done
    rm /test/private/core-installed-consumer.fixture/relocated-run.log
    status=0
    sh /checks/scripts/stage_debian12_consumer_evidence.sh /test/private /test/missing 0 || status=$?
    test "$status" -ne 0
    sh /checks/scripts/stage_debian12_consumer_evidence.sh /test/private /test/partial 37
    test -r /test/partial/installed-run.log
    mkdir /test/empty
    sh /checks/scripts/stage_debian12_consumer_evidence.sh /test/empty /test/early 37
    # An existing unusable evidence entry must fail even on a partial run.
    mkdir /test/empty/prepare.log
    status=0
    sh /checks/scripts/stage_debian12_consumer_evidence.sh /test/empty /test/unusable 37 || status=$?
    test "$status" -ne 0
    '
echo 'Evidence inventory, byte stability, root-0700 isolation and partial staging PASS'