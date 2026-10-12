# GNATdoc documentation campaign progress

Persistent resumption record for the CORE-DOC-FULL campaign. Documentation
only: no executable Ada, C/C++ shim, ABI, manifest or toolchain changes.

## Identity

- Campaign starting main SHA: `324337096201ce1719863a69d5d2a304219de0bf`
  (verified as current `origin/main`, PR #64 merged).
- Worktree: `/home/zboll/git/opencv/core-doc-campaign`
- Documentation generator is run with
  `GNATDOC_PREFIX=/home/zboll/git/opencv/core-doc-005/.doc-tools/gnatdoc-26.0.0`
  (GNATdoc 26.0.0 (20260415), Alire 2.1.1, GNAT 16.1.0, GPRbuild 26.0.0 /
  Alire 26.0.1).

## Milestones

| # | Branch | Parent | Family | Warnings before | After | Status |
| --- | --- | --- | --- | ---: | ---: | --- |
| 1 | `feature/doc-campaign-01` | `main` | Phase A: all of `src/opencv-core.ads` | 4134 | 3158 | locally qualified; PR in review |

## Warning totals

| Point | Total |
| --- | ---: |
| Initial baseline | 4134 |
| After milestone 1 | 3158 |

Remaining by family (from `docs/gnatdoc-warning-baseline.txt`):
`opencv-core.ads` 0 (was 976); the other 3158 are in Phases B-H.

## Milestone 1 qualification (Phase A)

- Executable-token check: comment/blank-stripped `src/opencv-core.ads`
  identical to the starting file.
- `gnatformat --check -P opencv_core.gpr src/opencv-core.ads`: pass.
- `scripts/generate_docs.sh`: `3158` warnings, `0 added, 976 removed`
  against the previous baseline; 195 public packages, 197 HTML pages;
  links, anchors and assets valid.
- Baseline regenerated with `--write-baseline`; rerun reports
  `0 added, 0 removed`.
- Comparator unit tests: 26 passed.
- `alr -n test` (AUnit): 2025 run, 2025 successful, 0 failed assertions.
- `git diff --check`: clean.
- New narrow HTML check: `OPERATION_DOCS` in `scripts/validate_docs.py`
  (overload-keyed checks for Sqrt destination forms, `With_Selected_View`,
  `Mix_Channels`, and Mat/UMat `Polar_To_Cart` destination forms).

## Pending

- Hosted CI: see the PR record below once opened (`HOSTED_CI_PENDING` until
  inspected).
- Open campaign PRs: recorded in the PR table below.
- Blockers: none.

## PRs (merge in this order; none merged, auto-merge disabled)

See the final report for URLs and head SHAs.

## Next

Milestone 2 (`feature/doc-campaign-02`, branched from milestone 1's head,
PR targets `feature/doc-campaign-01`): Phase B (`OpenCV.Core.Sparse` and
typed Sparse children) and Phase C (`OpenCV.Core.Persistence`).
List targets with
`grep '^opencv-core-sparse.ads\|^opencv-core-persistence' docs/gnatdoc-warning-baseline.txt`.
