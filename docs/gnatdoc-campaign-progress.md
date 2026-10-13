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
| 2 | `feature/doc-campaign-02` | `feature/doc-campaign-01` | Phases B, C and non-typed D: Sparse, Persistence, module interop, transfers, Matx3x3, 24 Vec instances | 3158 | 2897 | #66 |
| 3 | `feature/doc-campaign-03` | `feature/doc-campaign-02` | Phases E-H: typed element, row, buffer, Mat-view and sparse typed access, 8 depths x (C1, C2, C3, C4) | 2897 | 0 | recorded in final report |

Hosted CI: PR #65 had 19 passing, 5 skipped and 18 pending jobs on the
single inspection made after PR #66 opened (`HOSTED_CI_PENDING`). #66 and
the milestone 3 PR were not yet inspected.

## Warning totals

GNATdoc warnings: 4134 -> 3158 -> 2897 -> **0**. The structured baseline
`docs/gnatdoc-warning-baseline.txt` is empty (no entries).

## Qualification of milestone 3

- Executable-token check on all 153 changed `.ads` files: comment/blank
  stripped files identical to the parent commit.
- Line-length check (max 79), `gnatformat --check` on all changed files
  except the 25 known generic-instance conflicts: clean.
- `scripts/generate_docs.sh`: 0 warnings, `0 added, 2782 removed`; 195
  public packages, 197 HTML pages valid.
- Baseline rewritten (0 identities); rerun `0 added, 0 removed`.
- Comparator unit tests: 26 passed.
- `alr -n test`: 2025 run, 2025 successful, 0 failed.
- `git diff --check`: clean.
- Eight sub-agents wrote the per-depth typed-access comments from four
  lead-written exemplars; each agent reported its token-identity and format
  checks and its unverified points (see below).

## Known tool conflict

`gnatformat --check` fails on 25 generic-instance specs
(`opencv-core-<type>_vec{2,3,4}.ads`, `opencv-core-float32_matx3x3.ads`):
the formatter inserts a blank line between the leading comment and the
instantiation, and GNATdoc 26.0.0 then drops the comment. Files are kept in
the GNATdoc-valid form.

## Remaining work: final audit (documentation is NOT yet declared complete)

A zero warning count does not prove accuracy. Open items:

1. Sub-agent claims copied from exemplars and not re-traced per package:
   Mat-view limits for Vec2/3/4 bodies, sparse `For_Each_Stored` error text,
   Vec row/buffer exception lists. The helpers they share
   (`Typed_External_Mat_View`, `Typed_Row_Borrowing`,
   `Typed_Continuous_Borrowing`, `Sparse.Typed_*_Impl`) were read for the
   UInt8 exemplars and match.
2. Buffer-access `@exception` lists omit the case where `Total` exceeds
   `Natural'Last` (raised by the shared helper).
3. Some scalar row-access `Read_Row`/`Write_Row` comments (Int8, UInt16)
   omit "non-contiguous Regions are supported" because it was not verified
   per package.
4. Decide the generic-instance formatter conflict above.
5. Hosted CI for all three PRs must be inspected once and recorded.
