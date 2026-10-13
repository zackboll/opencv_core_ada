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

## Audit status (documentation is NOT yet declared complete)

A zero warning count does not prove accuracy. A read-only audit sub-agent
re-checked the sparse, Mat-view, row-access and element-access claims against
the `.adb` files, the shared `Typed_*` helpers and the shim. Findings fixed
on the milestone 3 branch:

- N-D Mat-view comments said 2 .. 32 dimensions; the shim limits external
  N-D views to `cv::MatShape::MAX_DIMS` (10) on OpenCV 5.0. All 32 Mat-view
  specs now qualify this and the exception text.
- Buffer-access exceptions now include `Total` above `Natural'Last`.
- Sparse `For_Each_Stored` exception wording now says a native iteration
  failure can follow earlier callbacks; sparse `Get`/`Set` mention native
  failures.

No discrepancies were found in element access, row access or the sparse
validation order. Known, accepted omissions: byte-count overflow and
native-allocation failures are not listed in every exception clause; the
Vec3 row access also checks a `Natural'Last / 3` length limit that is not
mentioned. `Float32_Mat_View` names its 2-D strided writable overload
`With_Writable_Mat_View (Row_Stride_Elements)`, unlike the other 31
packages; the comments match the code.

Open items:

1. Decide the generic-instance formatter conflict above.
2. Hosted CI: #65 and #66 were green on the last inspection (19 and 18
   passing, rest skipped); #67 was pending. Re-inspect once and record.
3. Independent human review of all three PRs, in order.
