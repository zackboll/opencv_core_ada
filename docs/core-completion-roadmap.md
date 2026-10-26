# Core completion and freeze roadmap — provisional, audit blocked

## Current implementation overlay — CORE-CLOSE-001D

**Current crate version:** `0.5.2`. CORE-FIN-01 and CORE-FIN-02 are
**IMPLEMENTED_IN_MAIN** (merged PRs #90 and #94); CORE-FIN-03 remains
**PLANNED_REQUIRED**. The bounded optional queue is unchanged. See the
[reconciliation ledger and qualification](core-roadmap-reconciliation.md),
[current-status JSON](core-current-status.json) and [finite backlog](core-finish-backlog.md).
The merged FIN-02 campaign has 2,052 successful registered tests on each of
OpenCV 4.1/4.6/4.10/5.0; FIN-01's 2,037-test campaign is historical.
This does not establish exhaustive Core coverage or a new release.

PR #89 is merged. Its historical findings, the original 26 records and
**UPSTREAM_DISCOVERY_BLOCKED / COVERAGE_AUDIT_BLOCKED** remain intact. All
sections below retain historical ordering/proposals; they do not supersede
this current implementation overlay. In particular, merging the forensic
audit or finishing AUD-07 is not a prerequisite to FIN-03.

## CORE-CLOSE-001B: practical execution supersedes audit-first ordering

The [portable capability scope](core-portable-capabilities.md) and
[finite feature backlog](core-finish-backlog.md) introduced the proposal for
implementation sequencing. **CORE-FIN-01 scalar modes, CORE-FIN-02 general norms,
and CORE-FIN-03 native runtime identity may start independently on main without
waiting for AUD-01..AUD-07 or merging raw discovery data.** They require their
own focused source/ABI/mode tests, not reconciliation of every C++ occurrence.

The original sections below are retained as audit history. Their blanket
“all tasks depend on AUD-07” and audit-first wording is **superseded**, as are
their earlier P0/P1/P2 priorities where the new matrix differs. In particular
tensor additions, UMat extensions, global controls and advanced persistence
are optional/consumer-backed, not automatic stabilization requirements.
`UPSTREAM_DISCOVERY_BLOCKED` and `COVERAGE_AUDIT_BLOCKED` remain unchanged;
planning readiness does not certify either forensic gate.

The [artifact retention proposal](core-audit-artifact-policy.md) preserves every
existing raw artifact. Its pre-merge lightweight-successor recommendation is
historical: the audit history is already on main. No artifact is removed by
this reconciliation. Original 26 semantic records are intact.

This is a proposal for independent review, **not** an approved release promise.
The [coverage audit](core-api-coverage.md) has not established discovery closure.
Therefore no claim is made that implementing the candidate backlog below would
complete portable Core. No production implementation is part of this PR.

## CORE-CLOSE-001A status: upstream discovery still blocked

The full tracked header-path census now has offline Git tree proofs rooted at
all four pinned upstream trees: 113 / 141 / 149 / 145 paths. The separate source
CST and active-configuration Clang censuses expose, rather than hide, unresolved
macro/conditional/overload cases. All header scope dispositions and new native
owner/header buckets remain provisional. The 26 original Ada-coverage records
are preserved. This does **not** complete AUD-01 or AUD-07 below.

Next finite discovery steps, before resuming broad Ada mode qualification:

1. Review every entry and proposed exclusion in the header-scope JSON. Retain
   public APIs such as `detail/async_promise.hpp` and depth macros in
   `hal/interface.h`; distinguish true dispatch/private implementation from
   installed-but-optional backend API.
2. Resolve every source uncertainty and unmatched Clang occurrence using the
   exact paths/ranges in the blocker report, including macro-generated enum
   operators, conversion templates, multiple declarators and CUDA/OpenCL helpers.
3. Review semantic grouping beyond provisional header/owner buckets and reconcile
   renamed Ada equivalents; record no new `BOUND_FULL` result without mode and
   implementation evidence. Independently canonicalize version overload diffs.
4. Record independent coverage of every in-scope file and guarded branch in the
   review lock; only then permit `UPSTREAM_DISCOVERY_COMPLETE`. Keep
   `ADA_COVERAGE_AUDIT_COMPLETE` and legacy global acceptance false until the
   remaining Ada work is independently qualified.

Exact per-version unresolved paths and evidence requirements are in
`docs/core-api-discovery-blockers.json`; counts are in the coverage report.

## 1. First finish the audit, in a finite sequence

These are evidence tasks, not feature work. Each slice must add stable semantic
IDs, all four exact-release references, mode/depth/channel/dimension and
ownership analysis, positive implementation links for bound APIs, independent
test mappings, and explicit exclusions/research dispositions. A capability is
not full solely because an equivalent Ada declaration exists.

| ID | Concrete scope | Deliverable and dependency | Approximate size |
| --- | --- | --- | --- |
| AUD-01 | All public Core headers: classify applicable capabilities and header exclusions; catalog macros/templates/inline methods missed by extractor | Reviewed reference discovery closure; depends on pinned source metadata | Large, 3–5 focused reviews |
| AUD-02 | Root values, every public typed-access/fixed vector/matrix spec/body, Mat/UMat lifecycle/shape/stride/view/external-buffer/interop | Domain A and data-type records; include native 5.0 MAX_DIMS/channel/depth changes; depends AUD-01 | Large, 3–4 reviews |
| AUD-03 | All arithmetic, scalar, comparison, masks, transcendental, channel, border, layout, reduction/statistical destination modes | Dense/UMat per-mode inventory and actual registered tests; depends AUD-02 | Large, 3–4 reviews |
| AUD-04 | Linear algebra, spectral, RNG/kmeans/distances/non-finite support | Full flags/outputs/numerical policy matrix; resolve named Ada equivalents; depends AUD-02 | Large, 3–4 reviews |
| AUD-05 | Sparse access/traversal/conversion/reductions and persistence formats/nodes/append/Base64/compression | Native table/guard/lifetime evidence, tests and exclusions; depends AUD-02 | Medium-large, 2–3 reviews |
| AUD-06 | Runtime, Algorithm/Ptr/affine/quaternions, accelerators/async, remaining utility headers | Portable versus backend exclusions; unsafe compatibility candidates remain explicit research; depends AUD-01 | Large, 3–4 reviews |
| AUD-07 | Cross-check coverage closure against all primary/additional headers; exact declaration parsing where feasible; independently review uncertainty | Final defined semantic/mode denominators and finite feature list; depends AUD-01..06 | Medium, 1–2 reviews |

AUD-07 must not clear `discovery_complete` just because every seed has a status.
It must establish that all discovered in-scope capabilities have records, while
RESEARCH dispositions identify concrete unresolved implementation decisions.
Audit acceptance must separately resolve required evidence gaps. Existing test
counts are not per-capability coverage percentages.

## 2. Conditional implementation backlog

All tasks below depend on AUD-07 confirming their necessity and exact scope.
Sizes are rough review estimates, **not** schedules. Each feature must be
reviewable vertically across public Ada, thin imports, minimal C ABI/native
shim, tests, formatting and documentation. Do not add a generic native-object
framework or historical fallback merely to increase a coverage percentage.

### P0 — proposed before 0.6.0 stabilization target

#### CORE-FIN-01 — scalar numeric and comparison modes

- **Capability:** Mat/scalar add, subtract, multiply, divide and compare;
  distinguish reverse subtraction/division. Inventory currently shows only
  same-layout matrix operands. Confirm masked arithmetic and output-depth needs
  rather than binding every overload by default.
- **Compatibility:** native Core on 4.1.0, 4.6.0, 4.10.0 and 5.0.0; preserve
  saturating conversions and non-saturating Int32 behavior.
- **Ada direction:** strong scalar/options and a small coherent overload set;
  separate reverse operations if that avoids confusing argument meaning.
  Reuse root Scalar; do not introduce C++ InputArray publicly.
- **Safety:** explicit channel limits, rounding/out-of-range scalar policy,
  scalar finite/non-finite validation where required, mask shape, rebind and
  exact/partial alias contracts. No blanket transactional guarantee.
- **Tests:** every supported depth/channel family, C1/C4 boundary and unsupported
  C>4, empty, strided ROI, scalar extremes/NaN/Inf, reverse operands, masks,
  destination reuse/rebind, raw invalid ABI and unchanged inputs on preflight
  rejection, all four native versions.
- **Value/size:** high for Imgproc/calibration and ordinary users; medium-large,
  roughly 2–3 cohesive vertical PRs. Depends AUD-03 and destination policy.
- **Release impact:** additive pre-1.0 API; no semantic change to existing
  matrix/matrix overloads. Low expected long-term maintenance with shared policy.

#### CORE-FIN-02 — general norm modes

- **Capability:** pairwise difference norms, squared L2, Hamming/Hamming2 and
  relative norms. Existing K_Nearest_Neighbors already covers some distances;
  this task is specifically general norm semantics.
- **Compatibility:** all four releases; source-review flag/mask restrictions.
  Do not emulate integer pairwise norms with saturated Abs_Diff.
- **Ada direction:** strong norm/distance kinds and explicit relative option or
  operation; choose a readable API without exposing native flag arithmetic.
- **Safety:** Hamming byte interpretation, relative zero denominator, integer
  overflow, selected channels, non-finite results, and N-D masks. Scalar output,
  read-only inputs, no new lifetime model.
- **Tests:** exact binary distances, squared/unsquared equivalence within
  tolerance, masked and pairwise boundaries, all-zero denominator, signed
  integer extrema, NaN/Inf, empty/mismatched inputs, ROI/N-D, native parity and
  ABI selector/output initialization, all four releases.
- **Value/size:** high for Features and numerical consumers; medium, 1–2 PRs.
  Depends AUD-04; can follow or run independently of CORE-FIN-01.
- **Release impact/maintenance:** additive; old Norm defaults unchanged; low
  expected maintenance with explicit native semantics.

#### CORE-FIN-03 — runtime diagnostic identity

- **Capability:** copied getVersionString and getBuildInformation results;
  add CPU capability reporting only after AUD-06 resolves stable representation.
- **Compatibility:** both identity queries declared in all four releases.
- **Ada direction:** String-returning native runtime queries, explicitly distinct
  from crate version and compile-time compatibility configuration.
- **Safety:** copy strings, bounded length/conversion and exception containment;
  no std::string or borrowed pointer ownership escapes.
- **Tests:** nonempty results, version matches actual linked native library,
  repeated-call ownership, diagnostic failure behavior and installed consumer,
  all four versions. Avoid exact build-text snapshots.
- **Value/size:** all downstream support/bug reports; small, one PR. Depends
  AUD-06; no dependency on scalar/norm work.
- **Release impact/maintenance:** additive, no new dependencies; low.

### P1 — strongly recommended if validated by the completed audit

#### CORE-FIN-04 — UMat basic destination parity

- **Capability:** masked Set_To, masked/unmasked caller-owned Copy_To; audit
  reshape separately rather than silently bundling a new zero-copy lifetime.
- **Compatibility:** native UMat methods exist in all four references; preserve
  CPU fallback and do not promise GPU execution.
- **Ada direction:** mirror established Mat procedures with UMat operands and
  masks, native UMat path, no implicit host staging.
- **Safety/tests:** mask type/shape, zero and nonzero masks, reused output versus
  new allocation initialization, aliases, disjoint ROIs, unsupported partial
  overlap, detachment, retained parent, empty results and invalid ABI; OpenCL
  disabled and available-backend smoke, all four versions.
- **Value/size:** high for allocation-stable accelerator pipelines; medium,
  1–2 PRs. Depends AUD-02/03 and destination contracts.
- **Release impact/maintenance:** additive, existing function Copy_To remains
  independent-result semantics; low-medium backend testing cost.

#### CORE-FIN-05 — tensor manipulation with honest compatibility

- **Capability:** transposeND, flipND, explicit broadcast, and UMat reshape only
  if its native safety/overload contracts are established.
- **Compatibility:** transposeND begins by 4.6 among reference tags;
  flipND/broadcast by 4.10. 5.0 adds MatShape overload. 4.1 lacks all three.
- **Ada direction:** shape/permutation/axis value types already established by
  Core; prefer native version-gated operations over an unproven Ada algorithm.
  Decide/document unavailable-operation behavior before stabilization.
- **Safety/tests:** rank limits, permutation uniqueness, multiplication bounds,
  continuity, zero extents, arbitrary Ada bounds, N-D strided views, shared
  storage reshape, broadcast growth and failures, all applicable native versions.
- **Value/size:** tensor consumers; medium-large, 2–3 PRs. Depends AUD-02/03,
  and RESEARCH-01 if uniform older-version behavior is required.
- **Release impact/maintenance:** additive but version-dependent capabilities
  must be discoverable/documented. Avoid perpetual custom fallback maintenance.

#### CORE-FIN-06 — persistence essentials

- **Capability:** file append and Base64 modes; gzip only after feature-guard
  and current validation research. Do not conflate sequence Append with opening
  a file in native APPEND mode.
- **Compatibility:** append/Base64 documented in all four releases; APPEND plus
  MEMORY rejected by native code. Compression depends on native build support;
  5.0 adds documented compression-level filename suffixes.
- **Ada direction:** extend strong modes/options while retaining limited
  File_Storage and storage-scoped map/sequence navigation.
- **Safety/tests:** append existing/missing files, duplicate keys, malformed
  input, close/failure behavior, formats XML/YAML/JSON, binary matrix round trips,
  embedded NUL, integer write minimum restriction, non-contiguous and N-D Mat,
  optional compression present/absent; all four versions as supported.
- **Value/size:** persisted model/configuration consumers; medium, 2 PRs plus
  optional compression PR. Depends AUD-05 and RESEARCH-03.
- **Release impact/maintenance:** additive; preserve existing strict typed reads
  and ownership, moderate format/build-feature test matrix.

#### CORE-FIN-07 — runtime controls

- **Capability:** get/set thread count, query/set optimization, CPU reporting.
  Timing tick/frequency queries are optional P2, not stabilization blockers.
- **Compatibility:** requested controls declared on all four releases;
  actual parallel backend behavior varies.
- **Ada direction:** explicit process-global configuration, not object-local
  properties; do not encourage mutation during concurrent OpenCV operations.
- **Safety/tests:** document native parallel-region/thread-safety limits, strong
  count/reset meanings, restore prior state even on test exceptions, test
  optimized-state changes without numeric-bit promises, all four versions and
  Linux/macOS/Windows. Do not assert exact worker counts across backends.
- **Value/size:** Ada tasking integration and support diagnostics; small-medium,
  1–2 PRs. Depends AUD-06 and global-state policy review.
- **Release impact/maintenance:** additive; low API churn, backend-sensitive tests.

#### CORE-FIN-08 — spectral destination and representation closure

- **Capability:** prioritize reusable Mat transform/spectrum destinations and
  explicit representation contracts. Audit need for CCS conversion/full complex
  row modes/nonzeroRows/scaling before adding overloads. UMat DFT/DCT are a
  separate optional parity decision, not an automatic mandatory feature.
- **Compatibility:** DFT/DCT/mulSpectrums exist in all four; Core divSpectrums
  exists only in 5.0 among references and remains research-gated.
- **Ada direction:** preserve existing full/packed/row naming and default inverse
  normalization; never expose raw integer native flags as public API.
- **Safety/tests:** size-arithmetic limits, even DCT extents, Hermitian input,
  odd/even CCS edges, non-contiguous ROIs, exact in-place versus partial overlap,
  reuse/rebind, parent retention, failure behavior and numerical round trips;
  both floating depths, row-wise and ordinary transforms, all four versions.
- **Value/size:** high for repeated spectral pipelines; medium-large, 2–3 PRs.
  Depends AUD-04 and RESEARCH-02 for spectrum division/fallbacks.
- **Release impact/maintenance:** additive; retain existing functional behavior;
  moderate alias/backend regression burden.

### P2 — optional coherent value/convenience capabilities

| Task | Concrete scope and API direction | Compatibility and safety/tests | Value, dependencies, size and impact |
| --- | --- | --- | --- |
| CORE-OPT-01 | Native tick/frequency queries, optionally Ada elapsed-time helper | All four; exact signed 64-bit ticks, positive frequency, no epoch/cross-host promises; monotonic-duration tests, no wall-time thresholds | Profiling parity; AUD-06; small; additive/low maintenance; Ada.Real_Time may suffice |
| CORE-OPT-02 | Quat value record, core rotation/normalization/interpolation subset, explicit Affine3 conversions | Absent 4.1; inspect 4.6/4.10/5.0 implementations, unit assumptions, singularities, antipodal interpolation and round trips; no unproved numerical backport | Pose consumers; AUD-02/06; large, 2–3 PRs; additive but public type/convention design requires approval |
| CORE-OPT-03 | DualQuat rigid-transform subset only after demonstrated consumer need | Same header presence versions as Quat; rigid versus general transformations, normalization and interpolation tests | Depends CORE-OPT-02 and reviewed Affine3 direction; large, 1–2 PRs; consider exclusion if marginal value |
| CORE-OPT-04 | Safe storage-scoped persistence iteration and remaining batch-distance convenience modes | All four where native modes exist; callback exceptions, lifetime, masks/crosscheck/tie order, all-pairs output sizing | Depends AUD-04/05; medium per family; additive, avoid escaping iterator/native graph |

### EXCLUDED — proposed deliberate boundaries

- **Sparse MINMAX normalization:** cannot shift implicit zeros without changing
  semantics/densifying; documented upstream prohibition, not an unbound native
  requirement. Explicit dense conversion stays available.
- **Escaping native FileNode/FileNodeIterator objects:** keep storage navigation
  and copied values. Exclusion does not prohibit safe iteration conveniences.
- **C++ expression/template/overload identity:** exact MatExpr or STL syntax is
  not a semantic completeness requirement; record supported operations instead.
- **Backend-specific API surface:** CUDA/OpenGL/DirectX/VA device handles are
  proposed outside the mandatory portable target, but individual records and
  evidence remain AUD-06 work. Do not label all accelerator interfaces excluded
  just because no GPU is available locally. UMat CPU functionality is distinct.
- **Generic native Algorithm/allocator/callback framework:** consider exclusion
  absent a concrete downstream use; individual necessary capabilities may still
  merit a small safe API. This is not yet a finalized family disposition.

### RESEARCH — explicit safety decisions, not implementation authorization

| ID | Exact research question | Evidence needed / possible disposition | Dependency and finite exit criterion |
| --- | --- | --- | --- |
| RESEARCH-01 | Can historical tensor/finite-mask functionality be safely portable without duplicating native algorithms? | Inspect exact native algorithms, stride/count overflow and floating-bit validity; prefer gated native APIs or explicit unsupported behavior over speculative fallback | AUD-03/04; exit with proof-backed design or justified exclusion; blocks uniform CORE-FIN-05 |
| RESEARCH-02 | Spectrum division and CCS representation conversion on pre-5.0 releases | Numerical denominator/zero/conjugation behavior, CCS edge layouts and native implementation; test reference or explicit 5.0-only policy | AUD-04; exit with supported scope or exclusion; no copied Imgproc dependency |
| RESEARCH-03 | Is gzip a portable required feature, and what does current Ada validation actually reject? | Exact zlib compile guards, error behavior, suffix handling all four versions; no assumption that unrestricted filenames imply supported contract | AUD-05; exit with capability gate or explicit optional exclusion |
| RESEARCH-04 | Direct mapped typed UMat access and mixed operands | getMat/map lifetime, synchronization, callback exceptions, storage retention, native backend behavior; explicit transfer remains safe alternative | AUD-02/06; exit with minimal callback design or exclusion; large lifetime risk |
| RESEARCH-05 | AsyncArray and native backend integration | Identify portable producer, timeout/state/finalization semantics and Ada task cancellation/exception transport; no producer means no stabilization requirement | AUD-06; exit with consumer-backed design or exclusion |
| RESEARCH-06 | OpenCV 5 additional depths and MatShape/channel boundary | Exact type encodings, conversion dispatch/null tables, public representation and native operation support, 4.x rejection policy | AUD-02/03; exit with precise per-type gates; large compatibility risk |

Research tasks do not authorize production compatibility code. Runtime checks,
formal proof, trusted native behavior and empirical tests must be distinguished.

## 3. Proposed 0.6.0 completion target

Adopt only after independent review of AUD-07 and the finite backlog:

1. Mandatory portable target: coherent owned dense Mat/N-D memory/view/access,
   copy/conversion, scalar and matrix arithmetic/comparison/selection, general
   norms, channels/layout/borders, reductions/statistics, existing linear
   algebra/spectral/RNG/clustering, safe sparse and persistence, and native
   version/build diagnostics. Resolve P0 gaps and any newly discovered essential
   portable family explicitly; do not silently grandfather an unsafe full label.
2. UMat baseline: safe ownership, transfer, basic operations/destinations and
   CPU fallback contracts. Full device/Mat parity and guaranteed GPU execution
   are not mandatory. Every omitted UMat mode must be documented.
3. Explicit limits: exact supported depth/channel/dimension sets per operation;
   Float16 restrictions, native 5.0 rank/channel changes, no arbitrary partial
   overlap, callback lifetimes, external storage rules and global state policy.
   No universal bit-identical floating-point guarantee across SIMD/backends.
4. Compatibility: qualify exact 4.1.0/4.6.0/4.10.0/5.0.0 references; version-gated
   operations discoverable and predictable. Any broader native range needs
   source review and testing, not just accepting a major version number.
5. Tests: every supported semantic mode has positive and negative tests; ownership
   operations exercise assignment/sharing/clone/finalization, destination
   rebind/retention, callbacks and ABI malformed inputs. Existing 2,025 tests
   must not regress. Add mode-matrix evidence; do not set a meaningless raw test
   count or arbitrary line-coverage percentage as the definition of completion.
6. Documentation: stable inventory IDs, source-backed availability, complete
   mode/ownership/alias contracts, exclusions, examples and migration notes;
   generated docs warning baseline must not be weakened.
7. Installed consumers: clean Alire and non-Alire GPR install/relocation,
   root-values-only and Mat consumers; cooperating module bridge with compatible
   native installation and callback-only borrow rules.
8. Qualification: hosted Linux x86_64 native version matrix, Linux AArch64,
   Windows/MSYS2 and macOS using established compiler/runtime isolation; approved
   GNAT compiler range and all existing native/ABI checks. Proprietary Scarthgap
   evidence remains prior qualification, not newly rerun for this audit.

0.6.0 remains pre-1.0: additive API is preferred, but any necessary break must
have explicit rationale and migration guidance. No stabilization promise is
implied by this initial snapshot.

## 4. Separate 1.0.0 stabilization gates

- Complete independent review of 0.6.0 scope and dispositions, resolve mandatory
  research, and obtain evidence of real downstream use across module crates.
- Freeze public package/type naming and ownership/alias/exception semantics.
  Document supported limitation changes as compatibility changes, not only
  declaration changes.
- Semantic versioning: compatible additions in minor releases, compatible defect
  fixes in patch releases, breaking supported source/behavior changes in a major
  release. Do not silently expand a formerly rejected unsafe mode as a patch
  without reviewing observable behavior and contracts.
- Define source versus ABI boundaries: Ada source compatibility within the
  documented compiler/native range; rebuild requirements across GNAT/runtime,
  C++ toolchain or OpenCV ABI changes. Do not promise binary compatibility
  between arbitrary OpenCV 4/5 installations or compiler families.
- Publish supported native versions, compiler/runtime combinations, platforms
  and architectures as a qualification table with exact artifacts and CI.
  Unsupported versions/platforms must fail clearly or be explicitly unqualified,
  not inherit a claim from a nearby tested version.
- Exercise installed/relocated consumers and cooperating downstream bindings
  without exposing C++ ownership or adding module-specific responsibilities to
  Core. Maintain root value-type and bridge stability boundaries.
- After feature freeze, prefer defect/security/compatibility maintenance;
  reopen feature scope only through consumer-backed proposals with explicit
  maintenance cost and independent review. Optional additions need not force
  churn in existing stable Core APIs.
- Continue validating new OpenCV releases, compiler/runtime changes, security
  fixes and platform toolchains. The goal is **minimal feature churn**, not zero
  maintenance or a promise that new upstream versions work without testing.