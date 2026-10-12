# GNATdoc documentation campaign progress

Persistent resumption record for the CORE-DOC-FULL campaign. Documentation
only: no executable Ada, C/C++ shim, ABI, manifest or toolchain changes.

## Identity

- Campaign starting main SHA: `324337096201ce1719863a69d5d2a304219de0bf`
  (verified as current `origin/main`, PR #64 merged).
- Worktree: `/home/zboll/git/opencv/core-doc-campaign`
- Current milestone branch: `feature/doc-campaign-01` (targets `main`)
- Toolchain verified: Alire 2.1.1, GNATdoc 26.0.0 (20260415), GNAT 16.1.0,
  GPRbuild 26.0.0 (Alire 26.0.1). Documentation generator invoked with
  `GNATDOC_PREFIX=/home/zboll/git/opencv/core-doc-005/.doc-tools/gnatdoc-26.0.0`.

## Warning totals

| Point | Total |
| --- | ---: |
| Initial baseline | 4134 |
| After batch 1-3 (Core types, Float16, math/bitwise/polar, spectral, UMat arithmetic) | 3407 |

Remaining in `src/opencv-core.ads`: 249 (initially 976).

## Completed so far

`src/opencv-core.ads`, up to and including the Mat `In_Range`,
`Rotate`, `Repeat`, `HConcat`, `VConcat` and `Compare` declarations:
Float16 classification, result/option records and enumerations, K_Means,
nearest neighbors, channel routing, Reshape, Diagonal, Sort, border,
channel split/merge, Sqrt/Exp/Log/Pow, Magnitude/Phase/polar conversions,
DFT/DCT and spectrum products, Normalize, Mat/UMat arithmetic and
destination procedures, Add_Weighted/Scale_Add, Mat/UMat bitwise,
Mat/UMat In_Range/Compare.

## Verification of the last qualified batch

- Executable-token check: comment/blank-stripped `src/opencv-core.ads`
  identical to `HEAD`.
- `gnatformat --check` on `src/opencv-core.ads`: pass.
- `scripts/generate_docs.sh`: 3407 warnings, `0 added, 727 removed`;
  195 public packages, 197 HTML pages, links/anchors/assets valid.
- Baseline regenerated with `--write-baseline`; rerun reports `0 added, 0 removed`.
- Comparator unit tests: 26 passed.
- Not yet run for this milestone: `alr -n test` (AUnit), representative HTML
  inspection beyond the validator.

## Pending

- Hosted CI: no PR opened yet.
- Open campaign PRs: none.
- Blockers: none.

## Next

Continue `src/opencv-core.ads` after `Compare` (Mat `Mean`/`Sum`/norm and
reduction, statistics, linear algebra, decompositions, random fills,
`With_Selected_View`, `Set_To`, `Set_Identity`, `Patch_NaNs`, `Shuffle`,
`Initialize`/`Finalize`). List the remaining declarations with the
`opencv-core.ads` entries of `docs/gnatdoc-warning-baseline.txt`.
