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

## Milestones (historical branch bases; current status below)

| # | Branch | PR base | Family | Before | After | PR |
| --- | --- | --- | --- | ---: | ---: | --- |
| 1 | `feature/doc-campaign-01` | `main` | Phase A: all of `src/opencv-core.ads` | 4134 | 3158 | #65 |
| 2 | `feature/doc-campaign-02` | `feature/doc-campaign-01` | Phases B, C and non-typed D: Sparse, Persistence, module interop, transfers, Matx3x3, 24 Vec instances | 3158 | 2897 | #66 |
| 3 | `feature/doc-campaign-03` | `feature/doc-campaign-02` | Phases E-H: typed element, row, buffer, Mat-view and sparse typed access, 8 depths x (C1, C2, C3, C4) | 2897 | 0 | recorded in final report |

Historical hosted CI observation: PR #65 had 19 passing, 5 skipped and 18 pending jobs on the
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

## Earlier audit (superseded by CORE-DOC-067A audit below)

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

The earlier audit reported no discrepancies in element access, row access or the sparse
validation order. Known, accepted omissions: byte-count overflow and
native-allocation failures are not listed in every exception clause; the
Vec3 row access also checks a `Natural'Last / 3` length limit that is not
mentioned. `Float32_Mat_View` names its 2-D strided writable overload
`With_Writable_Mat_View (Row_Stride_Elements)`, unlike the other 31
packages; the comments match the code.

Historical open items (superseded below):

1. Decide the generic-instance formatter conflict above.
2. Hosted CI: #65 and #66 were green on the last inspection (19 and 18
   passing, rest skipped); #67 was pending. Re-inspect once and record.
3. Independent human review of all three PRs, in order.

## CORE-DOC-067A final qualification and reconciliation

### History and status

- Actual current main: `f580af11369eac91ff0c95f6b32251fcfa12655c`.
- PR #65 merged at `5496a9f3e6bcf2640484b8f1f647bb34c4c43e0c`;
  PR #66 merged at current main. Both are contained in main.
- Main tree equals PR #66 head `dde8bef3` tree:
  `29c6d4135ac3bcb071fd4d0589a4a1bf91e83e58`.
- PR #67 is open, non-draft, unmerged, auto-merge disabled, now against
  `main` on `feature/doc-campaign-03`. Retargeting preserved starting head
  `e2433accd3c7f45e9ef003744a794da1928e47b9`.
- The installed `gh pr edit` failed on deprecated classic-project metadata;
  the same base change succeeded through GitHub's REST API.
- GitHub reported CLEAN/MERGEABLE. Starting-head prospective merge tree
  equals source tree `968f1d1045f25bedaadf95353beb236b2c4870d3`.
- Final corrective head is the ordinary commit containing this reconciliation;
  resolve its literal SHA with `git rev-parse HEAD`. The final PR report
  records SHA parity and hosted run IDs: a commit cannot embed its own SHA.
  Existing commits `0885b028`, `a9c1baa`, `e2433ac` are not rewritten.
- All extant worktrees were checked before editing and were clean. No separate
  Claude/Cline process was identified; VS Code extension sessions cannot be
  excluded solely by process names. No downstream open PR depended on #67.
  No other worktree was modified; remote head was rechecked before correction.

### Corrected warning accounting

Committed structured baselines, counted without regenerating them:

| Revision | Remaining warnings |
| --- | ---: |
| PR #66 head `dde8bef3` | 2897 |
| Exemplar `0885b028` | 2782 |
| Main typed-access commit `a9c1baa` | 0 |
| Previous corrective head `e2433ac` | 0 |
| CORE-DOC-067A correction | 0 |

Milestone 1 removed 976 (4134 -> 3158); milestone 2 removed 261
(3158 -> 2897). Milestone 3 removed **115 + 2782 = 2897**.
The historical `0 added, 2782 removed` delta above was only the subsequent
batch, not the full milestone. The final baseline has no entries (one newline)
and is unchanged by this correction. Campaign total removal is **4134**.

### Semantic audit matrix

Scope: UInt8, Int8, UInt16, Int16, Int32, Float16, Float32 and Float64,
each C1/C2/C3/C4: 32 packages per family, 160 typed packages. Repeated
behavior was checked using shared helpers and depth/channel/size bindings;
divergent profiles were inspected separately. Evidence is implementation and
tests, not formal proof of the foreign ABI.

| Pattern | Verified semantics and evidence | Result |
| --- | --- | --- |
| Dense elements | Scalar bodies across all eight depths, vector validation/bindings, `Internal.Typed_Access`, native `validate_typed_at`/`prepare_nd_typed_at`; element and Vec2/Vec3 N-D tests: complete elements, zero-based indices, index counts, bounds, exact layout and shallow-storage writes | Accurate. Some 2-D wrappers delegate explicit dimensionality rejection to the native helper. |
| Float16 / classification | Scalar and vector bit paths, Float16 tests; Float32/Float64 Classify bodies and native entry points | Binary16 encodings preserved; classification is the scalar 2-D operation, not an invented vector/N-D operation. |
| Copied rows | Per-depth row bodies and native row calls; integer and Float16 Vec3 row tests: arbitrary array bounds, first element maps column zero, Read owns values, Write changes shared storage, Regions supported | All eight Vec3 specs corrected: Read_Row/Write_Row also reject Data'Length > Natural'Last / 3 for their three-scalar conversion buffer. This limit does not apply to zero-copy callbacks. |
| Borrowed rows | `Typed_Row_Borrowing`, `Row_Data`, native lease; row and lifetime-probe tests | 2-D/row validation, zero-based logical row excluding padding, immediate writes/no copy-back, unchanged callback exceptions, non-contiguous Regions; lease is lifetime management, not synchronization. |
| Buffers | `Typed_Continuous_Borrowing`, `Continuous_Data`, depth/channel instantiations, N-D and integer/Float16 buffer tests | Nonempty continuity required, final dimension fastest, vector entries are complete elements, Total counts elements not channels/bytes, Natural'Last limit; correctly typed empty matrices receive null range 1 .. 0. |
| Packed 2-D views (both modes) | All 32 `Typed_External_Mat_View` instantiations, external constructors and copy rejection; Mat-view/read-only tests | Exact Rows*Columns length, caller ownership, temporary non-owning header, callback scope, shallow escape rejected and Clone independent; read-only is Ada mode-in, not OS protection. |
| Packed N-D views (both modes) | `Packed_Element_Count`, native capacity guards, all view specs, `nd_mat_view_checks` | Positive shape, exact product, final dimension fastest, lower bounds not geometry; general 2..32 dimensions, at most 10 on OpenCV 5.0, preserved in all 32 contracts. |
| Strided 2-D views (both modes) | `Create_Strided_2D`, native constructor; gap/read-only tests; Float32 forwarding body | Complete-element/vector stride, >= Columns, capacity includes final padding (Rows*stride), checked products/byte/native extent. Float32 special writable Row_Stride_Elements overload uses the same helper. |
| Strided N-D views (both modes) | `Strided_Required_Capacity`, native strided helpers, `nd_strided_mat_view_checks` | One positive stride per axis, final stride 1, nested blocks covered, capacity includes complete outer padding (Shape(first)*Strides(first)), checked sums/products, version dimension cap. No blanket operation-safety claim. |
| Sparse access / iteration | Sparse Check_Layout/Check_Indices, scalar/vector/iteration helpers; native sparse_get/set/iterator_next; sparse vector zero-node and callback tests | Missing Get is zero without insertion, Set zero creates/retains stored node, shape/layout/index validation, stored-node iteration only, callback exceptions propagate; native failure may follow earlier callbacks. Not dense storage/view semantics. |

Authoritative native evidence also includes installed OpenCV 4.x mat.hpp
external-data declarations and upstream OpenCV 4.6.0 matrix.cpp constructors,
setSize and finalizeHdr. The 5.0 cap is enforced by the shim's
MatShape::MAX_DIMS == 10 static assertion and successful prior 5.0 job.

Qualified limitations: callback references must not escape; leases do not
extend caller-owned external buffer lifetime or provide locks. Read-only
formals do not protect against unsafe native writes or other writable aliases.
No concurrency guarantee or certification of every Core/native operation is
claimed. Temporary views reject shallow aliases/general destination use;
supported typed writes are immediate and Clone is independent. Resource and
overflow failures are not exhaustively listed in every exception paragraph.
Extreme Natural'Last allocations were code-reviewed, not allocated. Sparse
partial-iteration failure was established by control flow, not injected.
No new unresolved safety-critical assertion was found.

### Fresh local qualification after comments changed

- Comparator: **26/26 passed**.
- Pinned GNATdoc 26.0.0 generator (prefix recorded above), successful library
  build: **0 warnings, 0 added, 0 removed**.
- **195 public packages, 197 HTML pages**; existing link/anchor/asset,
  internal/filesystem leakage and overload-specific checks passed.
- Rendered UInt8 element, Float16 Vec3 element, UInt8 Vec3 row limit,
  Int16 Vec2 buffer, Float32 special stride and UInt8 Vec4 view text checked.
- GNATformat applied to eight corrected specs; all milestone-3 changed specs
  passed checks; git diff --check clean. The accepted PR #66 exception for
  25 generic-instance specs remains untouched; no configuration changes.
- All **160** milestone-3 changed specs have identical executable text to
  current main after stripping comments/whitespace. No executable changes.
- Fresh `alr -n test`: **2025/2025 passed**, zero failed assertions and
  unexpected errors. The earlier 2025/2025 result above is historical.

### Hosted evidence and remaining review gate

- Prior push compatibility 38327865539 and PR compatibility 38327869831
  succeeded at e2433accd3c7f45e9ef003744a794da1928e47b9: nine successful
  jobs each. Windows MSYS2 and macOS MacPorts were skipped, not passed.
  These results are historical once the corrective commit changes head.
- No documentation branch run existed when checked after retargeting. The
  workflow is to be dispatched once on the pushed corrective branch and
  inspected once. New documentation/compatibility evidence must identify
  that exact head; old runs do not qualify the new SHA.
- Status of this committed record: **HOSTED_CI_PENDING**. Local semantic
  audit and qualification passed; exact-head hosted evidence remains to be
  established in the final PR report with run URLs and literal final SHA.
- Recheck local/remote/PR SHA parity, worktree cleanliness, GitHub mergeability
  and prospective merge-tree equality after pushing. Then independent review
  of #67 and maintainer merge decision remain. Leave PR open/non-draft,
  unmerged, auto-merge disabled. Do not rewrite history or delete branches.

Earlier pending-CI observations are historical, superseded by #65/#66's
merged status and the exact-head evidence above. Documentation is not declared
complete pending review until required hosted qualification is established.

## Pre-campaign warning inventory (historical)

The following inventory and recommendations were recorded before PRs #65,
#66 and #67 completed the campaign. They are retained for history only: the
current baseline is empty and there is no remaining warning cleanup backlog.

The current baseline contains 4,134 identities. It was 4,484 raw warnings on
main `53c14c469b22ba1c608836d9a16c0947e2c80323`, 4,460 after documenting the
six polar record-destination overloads, 4,395 after documenting the shared
`OpenCV` value types and the `Fixed_Matrices` and `Vectors` generic foundations
(65 warnings removed, none added), 4,299 after documenting the foundational
`OpenCV.Core` types on main `73bf27f7c04fc650fbfcecf175517c2487e9af24`
(96 removed, none added), and 4,134 after documenting the Mat and UMat
lifecycle, metadata and region APIs on main
`4b0a4dcdeb6f068b2293ac8871ac5b8a1ddf8614` (165 removed, none added).
Regenerate it only from a complete pinned
GNATdoc 26.0.0 log and the sources of that same revision:

```sh
python3 scripts/compare_gnatdoc_warnings.py --write-baseline \
    docs/gnatdoc-warning-baseline.txt obj/docs/gnatdoc.log
```

Do not replace the baseline with a raw copy of the log. Old line numbers do
not remain attached to the same declaration after later comment edits.

### Remaining warning backlog

Counts below are the 4,134 baseline warnings, grouped by GNATdoc category:

| Category | Warnings |
| --- | ---: |
| Undocumented parameter | 2,900 |
| Undocumented entity | 836 |
| Undocumented return | 312 |
| Undocumented component | 49 |
| Undocumented enumeration literal | 37 |

The Mat/UMat lifecycle task (DOC-005) removed 165 warnings: 33 undocumented
entities, 88 undocumented parameters and 44 undocumented return values; none
were added. By family: lifecycle and conversion 55 (`Create` 12,
`Create_UMat` 7, `Clone` 6, `Copy_To` 8, `Convert_To` 22), metadata 82 and
regions and slicing 28 (`Region`, `Slice`, `Locate_Region` and
`Adjust_Region`, Mat and UMat). Every overload was documented
individually. `Dimensions` is documented for Mat only, and the UMat
`Copy_To` function is documented as the only UMat form, so the Mat and UMat
`Copy_To` overload sets are explicitly not symmetrical. `Set_To`,
`Reshape`, `Row_View`, `Column_View`, `Diagonal_View`, arithmetic and the private
controlled-type hooks were deliberately left alone. All 165 targeted warnings were
eliminated, and no targeted warning remains. Decisions: the two stale
trailing UMat comments were replaced by leading blocks, because leading
style would otherwise attach them to the next declaration; `Rows`, `Columns`
and `Dimensions` raise only for Mats of more than two dimensions (a default
Mat reports 0 x 0), and no cross-version claim about empty headers was made
beyond what the existing contracts already state.

`validate_docs.py` now checks these APIs per overload. Sections are keyed by
the complete normalized declaration and by native GNATdoc anchor, never by
the bare name, so one overload's text cannot satisfy another overload's
check; the leading prose, `Parameters` and `Return Value` text are each
required inside the correct section. The older simplified section key used
for type declarations is unchanged and is not used for overloaded operations.

The Core type task (DOC-004) removed 96 warnings: 18 undocumented entities,
52 enumeration literals and 26 record components. It covered the
`OpenCV.Core` package itself; `Mat` and `UMat`; `Depth_Type`, `Norm_Kind`,
`Normalize_Kind`, `Comparison_Kind`, `Flip_Kind`, `Rotation_Kind`,
`Reduction_Axis`, `Reduction_Kind`, `Extremum_Occurrence`, `Sort_Axis`,
`Sort_Order`, `Transposed_Product_Order`, `Symmetry_Source`,
`Sample_Orientation`, `Covariance_Scaling`, `Spectrum_Multiplication_Kind` and
`Dimension_Selection_Kind`; `Channel_Count`, `Mat_Size`, `Region_Location`,
`Border_Interpolation_Result`, `Index_Range` and `Dimension_Selection`; and
`Mat_Type`, `Min_Max_Result`, `ND_Min_Max_Result`, `Mean_Std_Dev_Result` and
`Range_Check_Result`. All 96 targeted warnings were eliminated; none remain in
that scope. Of the 49 remaining component and 37 remaining enumeration-literal
warnings, none belong to those types.

GNATdoc 26.0.0 limitation observed: enumeration literals and record
components are documented from the type's leading block with `@enum` and
`@field`. The same block documents discriminants and variant components of a
discriminated record; each appears under "Record fields" and the prose must
state which variant component exists, because GNATdoc does not render the
variant condition beside the field.

By public package family:

| Family | Warnings |
| --- | ---: |
| `OpenCV.Core` typed `*_mat_view` packages | 1,245 |
| `OpenCV.Core` (`opencv-core.ads`) | 976 |
| `OpenCV.Core` typed `*_access` packages | 890 |
| `OpenCV.Core` typed `*_row_access` packages | 554 |
| `OpenCV.Core` typed `*_buffer_access` packages | 208 |
| `OpenCV.Core.Sparse` | 101 |
| `OpenCV.Core.Persistence` | 100 |
| Fixed-size value instances | 25 |
| `OpenCV.Core.Module_Interop` | 15 |
| `OpenCV.Core.Sparse` typed children | 8 |
| Typed conversions | 7 |
| `OpenCV.Core.Transfers` | 5 |

Recommended cleanup order, one family per review:

1. `OpenCV`, `OpenCV.Core.Fixed_Matrices` and `OpenCV.Core.Vectors` (done).
2. `OpenCV.Core` foundational types, enumerations and result records (done).
3. `Mat`/`UMat` lifecycle, metadata and region APIs in `opencv-core.ads`
   (done, DOC-005). Next: Mat/UMat mutation (`Set_To`), `Reshape`, and the
   remaining view APIs (`Row_View`, `Column_View`, `Diagonal_View`), then the
   arithmetic and destination-operation families.
4. `Persistence`, `Sparse`, `Transfers`, and `Module_Interop`.
5. One typed-access generic pattern (`Get`/`Set`, row, buffer, then mat view),
   applied consistently to its instances rather than documented one depth at a
   time with copied text.
