# CORE-REL-006: opencv_core 0.5.1 source release candidate

**0.5.1 is a candidate, not published or indexed.** The latest indexed release
is **0.5.0**. This task stops at an open, non-draft source PR for independent
review. It does not authorize merging, tagging, a GitHub release, an Alire
index PR, or any Geometry release.

## Scope and source provenance

| Input | Exact identity |
| --- | --- |
| Verified starting main / merged PR #87 | `dca020f7003f39ed93ce7238793ac49df223d345` |
| Reviewed GNAT Pro tooling head of PR #87 | `a2e47ea4dd9bc1ffd6c656d0e8b13f317a09191a` |
| Immutable 0.5.0 release source | `f8aef00c5366b4275ccd3d934f9c73ea5b83cd4f` |
| Starting main Git tree | `d838ecd3ba21da4b2a159bce75a65c75cf7dba67` |
| Production `src/`, both releases | `1391492417e408bd0b5bdc0327a1d659d229feed` |
| Production `cpp/`, both releases | `7b6e6b34cf23e0c635a3e821e5e428bbb78aa7d8` |

Before editing, origin/main was fetched and PR #87 verified MERGED with the
expected source and merge identities. There were no commits after that merge.
No 0.5.1 tag or index entry existed. PR #81 is merged and 0.5.0 is indexed.

This compatibility-preserving patch includes the already merged corrections
from PRs #83–#87: matching-GNATLS runtime discovery, target C++ probe sysroots
and archiver selection, full GNAT Pro qualification tooling, macOS SDK linking,
and GNATdoc declaration bookmarks/history restoration. See the changelog.
The release-preparation delta is version metadata, the consumer version gate
and documentation only. Dependencies, actions and existing test policy remain
unchanged. No production algorithms, public Ada API, private C ABI, Mat/UMat
ownership or exception semantics change. No public semantic validation is
duplicated in the C++ shim by this release; the shim tree is unchanged.

## Starting-main hosted qualification

Every applicable post-merge job completed successfully on the exact starting
main before release edits began. No job was counted as a pass while running
or skipped.

| Workflow | Successful exact-main run |
| --- | --- |
| OpenCV Compatibility | [39050394366](https://github.com/zackboll/opencv_core_ada/actions/runs/39050394366) |
| GNAT 12 native production | [39050394363](https://github.com/zackboll/opencv_core_ada/actions/runs/39050394363) |
| GNAT 12 aggregate source-unit controls | [39050394368](https://github.com/zackboll/opencv_core_ada/actions/runs/39050394368) |
| Cross configuration controls | [39050394370](https://github.com/zackboll/opencv_core_ada/actions/runs/39050394370) |
| Ada API Documentation | [39050394373](https://github.com/zackboll/opencv_core_ada/actions/runs/39050394373) |

The compatibility run passed all twelve jobs: OpenCV 4.1/4.6/4.10/5.0,
Ubuntu ARM64, Homebrew macOS ARM64, MacPorts macOS ARM64, Windows/MSYS2,
Alire Ubuntu/Fedora, release entry point and independent Debian GPR consumer.
This is starting-main evidence, not a substitute for candidate qualification.

## Exact-candidate identity and evidence protocol

The isolated branch is `release/0.5.1-preparation`, based on the verified merge.
Qualification must use its committed, clean HEAD, with fresh Git exports and
new build directories. No earlier ALIs, objects, archives or QEMU results can
stand in for candidate outputs. Preserved compiler, SDK, OpenCV, QEMU and
pristine AUnit prerequisites may be reused, not rebuilt unnecessarily.

The commit containing this document cannot contain its own SHA. Consequently
the final source PR and external evidence record the following *after commit*,
without making an untested documentation-only follow-up commit:

```sh
git rev-parse HEAD HEAD^{tree} HEAD:src HEAD:cpp HEAD:alire.toml
git status --porcelain
sha256sum alire.toml
```

These identify the candidate commit, full tree, production trees and manifest
blob/hash. Each campaign records that same exact candidate revision. The PR
must report the locally tested, pushed and PR-head SHAs and verify equality.
Any candidate correction requires rerunning affected gates at the new commit.
Do not report readiness based solely on a different PR merge-ref build.

Private reproducible evidence is retained outside the source archive at
`/home/zboll/work/opencv-geometry-scarthgap/evidence/core-rel-006`.
Only sanitized summaries belong in the source PR. Build outputs, SDK files,
licensed binaries, local credentials and temporary evidence must not ship.
Missing exit records or incomplete campaigns are not passes.

## Candidate qualification gates

This committed document specifies the gates; **the final source PR records
their observed results and exact tested SHA**. Historical reports are scoped
to their original sources and are not rewritten as candidate results.

### Debian 12 native / GNAT 12.2.0

Use a new isolated Debian 12 environment with real Debian GCC/GNAT 12.2.0,
matching `/usr/lib/gcc/x86_64-linux-gnu/12/adalib`, OpenCV 4.6.0, Alire 2.1.1
and AUnit 26.0.0. No inherited compiler overrides or stale ALIs are permitted.

Required evidence:

- Production/shim build with warnings as errors using the unchanged
  `tests/gnat12/run_production.sh` policy.
- Full 2,025/2,025 AUnit and instrumented all-family runs, no failed assertions
  or unexpected errors, balanced constructor/lease controls.
- K-means forwarding, O0/O2 production negatives, wrong object-size, layout,
  representation and Float16 boundary controls.
- Existing installed Ada-only and mixed Ada/C++ consumers, repeated from new
  consumer objects after moving the installation prefix; installed GPR
  resolution without checkout/original-prefix dependencies.
- ELF and `ldd -r` closure: OpenCV `.406`, libstdc++ and matching GNAT runtime,
  no missing or undefined dependencies.
- Fresh Alire root build/test actions, release build and checked tests with
  Core as a release-profile dependency; clean pinned-source consumer build,
  execution and exported bridge installation.

The existing `-gnatVa` development-profile IEEE NaN/infinity diagnostic remains
documented in the [0.5.0 historical preflight](release-0.5.0-preparation.md).
Do not weaken validity checks, tolerances or test selection to mask it.

### GNAT Pro 25.2 / Scarthgap / explicit QEMU

Reuse the preserved offline, non-root Podman qualification container and its
verified AdaCore GNAT Pro 25.2 / GCC 13.3.1 installation, Scarthgap 5.0
qemuarm64 sysroot, OpenCV 4.9.0, AUnit 26.0.0 and explicit QEMU AArch64.
The [original platform report](adacore25-scarthgap-core-aunit.md) identifies
those prerequisites and their provenance. Their identities must be rechecked.

Run the exact candidate's `scripts/cross_build_core.sh --build` into a new
workspace, then `tests/adacore25/qualify_aunit.sh` and `qualify_controls.sh`
using that newly built production workspace and candidate SHA. Require:

- New complete Core production and C++ shim cross-builds and installation.
- Matching AdaCore runtime discovery and actual fresh `GNAT Lib v25` identity.
- Full 2,025/2,025 QEMU AUnit PASS and instrumented 2,025-test all-family PASS.
- Every applicable additional runtime control PASS at O0/O2.
- Target-only AArch64 ELF/object/archive, compiler-comment and ALI inventory;
  correct interpreter, dynamic closure and symbol versions, no host paths or
  host libraries. Inspect the target loader's actual `--list` output as well.
- The source-unit compiler controls on the actual supplied target compiler.

**Target hardware remains NOT TESTED.** QEMU execution is not hardware evidence.

### Hosted candidate nonregression

Require successful applicable PR jobs for OpenCV Compatibility, GNAT 12 native
production, GNAT 12 aggregate source-unit controls, Cross configuration controls
and Ada API Documentation. Preserve OpenCV 4.1–5.0; 4.9.0 Scarthgap evidence is
separate from the four-version hosted matrix. Do not change workflow policy,
warnings or numerical tolerances to obtain green results.

Windows/MSYS2 and MacPorts are main-push/manual-dispatch jobs under current
policy, so their PR skips must be reported as **SKIPPED**, not PASS. Their
successful exact starting-main runs above are separate platform evidence.
Documentation deployment is likewise not required on PRs; its build is.

### Alire and archive preflight

Keep the crate name `opencv_core` and all existing dependency constraints and
actions. A clean candidate-pinned Alire consumer must resolve the existing
external OpenCV/pkg-config dependency model and build/run normally.

Validate a fresh `git archive` of the exact candidate: required Ada/C++ sources,
exported bridge, build/configuration scripts, GPR projects, manifests, license
and necessary documentation must be present. Reject private/generated content.
Record its listing and checksum outside the source release. This is source
archive validation, not a claim of a published GitHub release asset.

A publisher dry run is optional, only against the final public candidate using
`alr -n publish --skip-submit` with normal build verification. Never use
`--skip-build` to conceal a failure. No generated manifest may be submitted.

## Review boundary and later publication handoff

Push the qualified branch normally and open **Release opencv_core 0.5.1**
against main, non-draft, with auto-merge disabled. Wait for applicable CI and
verify clean local HEAD = remote branch HEAD = PR HEAD. Report
`READY_FOR_INDEPENDENT_REVIEW` only when every mandatory gate passes; otherwise
report `RELEASE_GATE_BLOCKED` with the first actual blocker and retained logs.

Leave the PR open and unmerged. A later authorized task must review and merge,
reconcile/requalify the actual merged source, create the immutable 0.5.1 tag,
prepare the source release and perform the publisher/index handoff. That later
task must independently verify the index state and origin checksum/revision.
This task creates no tag, release or index PR, changes no 0.5.0 release artifact,
does not force-push, and does not publish Geometry 0.3.1.