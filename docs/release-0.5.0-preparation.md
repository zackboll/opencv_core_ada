# CORE-REL-005-PREP: OpenCV Core 0.5.0 preparation

**Prepared candidate, not published.** Latest indexed version: **0.4.1**.
No release tag, GitHub release, source push, main PR or index PR is part of this
task. Follow [the final publication runbook](release-0.5.0-runbook.md) only in
the later authorized publication task.

## Source and isolation

- Fetched main: `c50336a807c5311219947cf82f4261c5f0b3fad6`.
- Verified PR #81 source: `242299eee7bc1bf98d52b3a1e619dc3552491a94`.
- Preparation branch: `release/0.5.0-preparation`, created from that exact PR
  source, initially clean. Its local commit is recorded in the external
  qualification evidence; it is not the final public release commit.
- Delta: manifest version, release documentation and the version expectation
  of `scripts/validate_root_value_consumer.sh` only. No `src/`, C++ shim, GPR,
  dependency, public API, production semantics or test action change.
- Earlier compiler/cross-build records remain historical evidence. The guides
  now direct readers to the completed GNAT 12 qualification without rewriting
  those earlier results. All historical changelog release entries are retained.

Evidence is outside the source package, in the sibling qualification campaign
`core-rel-005-prep`: command logs and exits, compiler/runtime identities,
consumer installation/relocation logs, source archive/list/hashes, local
candidate SHA and preparation patch. The draft index file lives there under
`index/op/opencv_core/opencv_core-0.5.0.toml`, not in a configured index.
Its origin is deliberately
`UNRESOLVED_FINAL_PUBLIC_0_5_0_RELEASE_COMMIT_DO_NOT_SUBMIT`.

## GNAT 12 release-candidate qualification

Disposable Debian 12 x86_64 environment, Alire **2.1.1**, explicit
`gnat_external=12.2.0`, detected `gprbuild=18.0.0` (Debian package 2023.0.0-3),
GCC/GNAT/libgnat package **12.2.0-14+deb12u1**, OpenCV **4.6.0**, pkg-config
**1.8.1**. Compiler and runtime resolve to `/usr/bin` and
`/usr/lib/gcc/x86_64-linux-gnu/12/adalib`. No GNAT 16 compiler/runtime is used.
The unchanged tests crate resolves GNATprove/GNATcov as development tools;
their presence is not selection of a GNAT 16 compiler. `gnatls`, ALI version
records and ELF/`ldd -r` independently establish the compiler/runtime used.

| Check | Result |
| --- | --- |
| Actual root Alire dependency resolution | OpenCV 4.6.0 and pkg_config 1.8.1 system packages |
| Tests dependency resolution | AUnit 26.0.0, GNATprove 16.1.0, GNATcov 26.2.1, local Core 0.5.0 |
| Normal root `alr -n build` | Pass, default development profile |
| Root `alr -n test` on fresh sources | Pass, 2,025/2,025, zero assertions/errors |
| Root `alr -n build --release` | Pass, also with `ADAFLAGS='-gnatwa -gnatwe'` |
| Tests `alr -n build --profiles=opencv_core=release` then `alr -n run` | Pass, 2,025/2,025, checked development test harness |
| Installed Ada-only and mixed Ada/C++ consumers | Both execute successfully |
| Both consumers after prefix relocation | Both execute successfully, no checkout dependency |
| ELF and `ldd -r` | OpenCV `.406`, libstdc++, libgnat-12; no missing/undefined dependencies |
| Updated root-value consumer/version gate | Pass, exported bridge header installed and matches |
| Explicit Core development profile + full tests | Expected failure: 2,017 successes, eight Constraint_Error errors |
| Root test after persisted development override | Fails with the same eight errors; diagnostic state is not pristine |

Native/cross qualification and the GNAT 16 four-OpenCV matrix from PR #81 are
recorded in [GNAT 12 completion](gnat12-completion.md). This preparation task
does not rerun the AArch64 cross-build or four-version matrix, claim target
execution, or extend support to proprietary Yocto Scarthgap.

## Alire profiles: publication is a separate gate

Official [Alire 2.1.1 publishing documentation](https://github.com/alire-project/alire/blob/v2.1.1/doc/publishing.md)
and [publisher source](https://github.com/alire-project/alire/blob/v2.1.1/src/alire/alire-publish.adb)
were inspected, not inferred from a passing release-profile suite.

`Check_Build` invokes **`alr --non-interactive build`** in freshly deployed
sources: default root development profile. That build passes; it does **not**
execute AUnit or invoke `alr test`. `--skip-submit` suppresses online submission,
not the build check. Do not use `--skip-build` or `--for-private-index` to evade
community-index validation.

The [stable index checks](https://github.com/alire-project/alire-index-checks/blob/stable-1.4.0/scripts/gh-build-crate.sh)
separately invoke **`alr test`**. The source manifest's first action performs
the root development build; the second enters `tests` and runs Alire there.
On a fresh deployment, Core is then a **release-profile dependency**, while
the tests themselves keep their default checked development profile. This
explains why normal root actions pass without disabling validity checks.

Forcing `opencv_core=development` in the tests crate retains `-gnatVa` on
production and raises Constraint_Error for IEEE NaN/infinity in eight tests.
Alire persists that explicit override, so a subsequent root test in that
diagnostic workspace can fail too. Qualification must use clean deployed
sources, or explicitly restore the documented release dependency profile.
No manifest profile override, validity suppression, test filtering, changed
IEEE semantics or weakened subtype checks has been introduced.

## Publication requirements and draft

- Installed `alr publish --help` supports `--skip-submit` and URL + commit.
  The final invocation will be against the final public release SHA, not the
  PR source or local preparation SHA.
- Required index-release fields (name, description, version, maintainers) and
  community `maintainers-logins` are present. Authors, SPDX `Apache-2.0`,
  website and tags are also retained; the full `LICENSE` ships.
- Existing published 0.4.1 manifest was inspected on **stable-1.4.0** at
  index commit `068f3873c7732229d4d586836882266494a6d50d`. This is the newest
  stable branch observed and the branch selected by installed Alire 2.1.1.
- The index-checks source observed was
  `0e8bb4c996d9e9f7795c479cc0ba5691e321bfa3`; recheck current index policy
  before final submission.
- GitHub is an allowed Git host. Use public
  `git+https://github.com/zackboll/opencv_core_ada.git` and an immutable full
  40-hex final release commit. It must exist remotely and contain 0.5.0.
- Submission belongs at `index/op/opencv_core/opencv_core-0.5.0.toml`.
  The draft duplicates source metadata/actions/dependencies and adds only
  `[origin]`; its unresolved marker intentionally makes it unpublishable.
- `zackboll` is the existing authorized maintainer login in 0.4.1. A later
  index PR must be authored by an authorized maintainer; no credentials were
  requested or exposed and no authenticated submission was attempted.
- Root system dependencies, Windows-only mingw_w64_gcc, pre-build script,
  both test actions and MSYS2 path environment are unchanged. Referenced
  scripts and `tests` sources ship in the source archive. All test/proof/
  coverage dependencies remain in the tests crate.
- API reference, documentation home/developer guides and indexed 0.4.1 links
  were fetched successfully. No link to a nonexistent 0.5.0 release is added.

## Remaining gates

No concrete candidate packaging or pristine-profile validation blocker has
been identified. The explicit development IEEE mismatch remains a documented
limitation; it is not hidden by release-profile success. This disposition is
**RELEASE_PREPARATION_COMPLETE**, conditional on the recorded exact-source
archive qualification and integrity checks.

Still required: #81 passes and merges; verify exact merged source; replay only
this delta; rerun release and pristine publication-profile checks; publish the
final source commit/tag only with later authorization; run the actual
`alr publish --skip-submit` against that public commit; independently review
the generated index entry and leave the index PR open. Final publication and
multi-platform index CI are **not verified by this local preparation**.

The C++ shim is unchanged. No public semantic validation is duplicated in the
C++ shim by this release-preparation delta.