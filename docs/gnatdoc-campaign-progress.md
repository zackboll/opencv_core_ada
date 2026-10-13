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

## Milestones (merge in this order; none merged, auto-merge disabled)

| # | Branch | PR base | Family | Before | After | PR |
| --- | --- | --- | --- | ---: | ---: | --- |
| 1 | `feature/doc-campaign-01` | `main` | Phase A: all of `src/opencv-core.ads` | 4134 | 3158 | #65 |
| 2 | `feature/doc-campaign-02` | `feature/doc-campaign-01` | Phases B, C and the non-typed part of D: `OpenCV.Core.Sparse`, `Sparse.Module_Interop`, `Persistence`, `Module_Interop`, `Transfers`, `Float32_Matx3x3` and conversions, 24 `*_VecN` instances | 3158 | 2897 | recorded below |

Hosted CI for milestone 1 (PR #65) was `HOSTED_CI_PENDING` when last
inspected (workflow runs 38324552788 and 38324565816).

## Warning totals

| Point | Total |
| --- | ---: |
| Initial baseline | 4134 |
| After milestone 1 | 3158 |
| After milestone 2 | 2897 |

Remaining 2897 warnings are all in the typed access families:
element access (`*_access`), row access (`*_row_access`), buffer access
(`*_buffer_access`) and Mat views (`*_mat_view`), including the typed
Sparse children (`opencv-core-sparse-*_access`).

## Qualification of milestone 2

- Executable-token check on all 31 changed sources: comment/blank-stripped
  files identical to the parent commit.
- `scripts/generate_docs.sh`: 2897 warnings, `0 added, 261 removed`;
  195 public packages, 197 HTML pages valid.
- Baseline regenerated; rerun `0 added, 0 removed`.
- Comparator unit tests: 26 passed.
- `alr -n test`: 2025 run, 2025 successful, 0 failed.
- `git diff --check`: clean.
- New HTML checks: package-level phrases for Sparse, Persistence, Transfers,
  both Module_Interop packages, a Vec instance and the Matx3x3 instance.

## Known tool conflict (needs a decision)

`gnatformat --check` fails on 25 generic-instance specs
(`opencv-core-<type>_vec{2,3,4}.ads` and `opencv-core-float32_matx3x3.ads`).
For a generic instantiation `gnatformat` inserts a blank line between the
leading comment and the `package ... is new` line, and GNATdoc 26.0.0 then
does not attach the comment to the package (the "entity not documented"
warning returns). Alternatives tried (comment before `with`, comment inside
the instantiation, trailing comment) also leave the warning. The files are
kept in the GNATdoc-valid form. All other changed sources are
`gnatformat --check` clean. Revisit if GNATdoc or GNATformat changes.

## Next

Milestone 3 (`feature/doc-campaign-03`, from milestone 2's head, PR base
`feature/doc-campaign-02`): typed element access (`*_access` packages,
including `opencv-core-sparse-*_access`). Inspect the package pattern
first (`opencv-core-uint8_access.ads`), then document one depth family at a
time. Target list:
`grep '_access\.ads' docs/gnatdoc-warning-baseline.txt`.
Later milestones: row access, buffer access, then Mat views (the
safety-sensitive family; verify each view contract against its package and
`tests/` before writing).
