# Finite practical Core backlog — CORE-CLOSE-001B

Feature-local reconciliation (CORE-FIN-02): CORE-FIN-01 was implemented and
merged in PR #90; the scalar planning text below is historical scope, not a
claim that scalar modes are still missing. The additive
[numerical norms feature](numerical-norms.md) is implemented on its feature
branch; FIN-02 remains qualification-pending until exact-head review gates
complete. The JSON planning ledger and forensic snapshots are deliberately
unchanged; broader roadmap status reconciliation is a separate task.

**Planning proposal; no production changes in this PR.** The first three are
implementation tasks ready to start in separate feature PRs against main.
They do **not** depend on closing the forensic declaration census, merging the
large audit PR, or implementing one another. Each implementer revalidates the
focused source/ABI behavior in its own PR and adjusts naming through normal
API review. The [portable matrix](core-portable-capabilities.md) defines the
bounded required scope; native overload/template parity is not a release gate.

All source references are pinned in [practical evidence](core-portable-evidence.json),
with older seed mappings retained in [coverage JSON](core-api-coverage.json).
Approximate complexity means review size, not a promised delivery schedule.

## First three: implementation-ready

### CORE-FIN-01 — portable Mat/scalar arithmetic and C1 comparison

**Required for 0.6.** Benefit: Imgproc/Video intensity scaling and offsets,
Features threshold masks, Calib3D/navigation residual preprocessing without
allocating a full constant matrix. Medium; one cohesive feature PR with small
vertical arithmetic/comparison commits, not all native arithmetic overloads.

- **Exact scope:** add/subtract/multiply/divide a `Mat` and channel-ordered
  `OpenCV.Scalar`, plus scalar-minus-Mat/scalar-divided-by-Mat. Functions return
  independently owned Mat; procedures use a real caller-owned destination.
  Compare a C1 Mat with a `Float64_Value` using existing `Comparison_Kind` and
  return/write a UInt8 C1 0/255 mask. A reverse Compare overload is unnecessary:
  callers can invert the relation explicitly.
- **Initial supported limits:** nonempty 2-D UInt8/Int8/UInt16/Int16/Int32/
  Float32/Float64; arithmetic C1..C4, comparison C1. Reject Float16 and C>4
  explicitly in Ada; no speculative widening fallback. Default/typed empty
  inputs are rejected consistently for these *new* modes (existing matrix/matrix
  empty semantics unchanged). Source-depth output, unmasked only. N-D, dtype,
  mixed storage and masked scalar variants are outside this task.
- **Expected API additions:** descriptive overloads `Add`, `Subtract`,
  `Multiply`, `Divide` taking Scalar; explicit `Subtract_From`/`Divide_Into`
  names are recommended for reverse operands to make direction unmistakable.
  `Compare (Self : Mat; Value : Float64_Value; Kind : Comparison_Kind)` plus
  destination form fits existing naming without adding a public type/package.
  Use all active Scalar components; no Python-style tuple/single-number
  broadcasting convention. A uniform value is `Make_Scalar (v,v,v,v)`.
- **All four native releases:** 4.1.0, 4.6.0, 4.10.0, 5.0.0. `arithm_op`
  handles scalar detection and reversed subtraction/division in each pinned
  source. Native coefficient/work-depth conversion differs; do not promise
  bit-identical cross-version floating results. Compare scalar integer
  out-of-range/fractional behavior is handled by native Compare, **not** by
  narrowing the scalar to the Mat's depth first.
- **Thin/shim work:** exact fixed-width selectors, existing packed scalar
  record/double representation; native `cv::add/subtract/multiply/divide/compare`
  with `cv::Scalar`/numeric scalar input and actual output header. No constant
  full-Mat materialization, expression-template bridge or Ada algorithm.
  Separate new unambiguous `opencv_core_...` symbols/imports as needed, preserving
  all existing ABI signatures. Initialize outputs, reject unsafe pointer/selector
  representations, contain exceptions; public semantic policy stays in Ada.
- **Ownership/aliasing:** function sources unchanged; destination reuses compatible
  storage or detaches on mismatch. Permit exact/same-layout source alias only
  after focused native probes; initial conservative rejection is acceptable if
  stated before API review. No arbitrary overlapping ROI guarantee. Reject
  temporary external/selected destinations; keep inputs valid for the call.
  Preflight failure preserves destination; do not promise rollback after native
  exceptions. Compare must not silently rebind storage of retained source aliases
  in a way that violates existing destination rules.
- **Positive tests:** every seven-depth family; C1/C3/C4 distinct components,
  non-contiguous ROI, negative/reverse operands, fractional coefficients,
  saturation and non-saturating Int32 overflow comparison to native (not a
  mathematically exact overflow promise), integer/floating zero division,
  six comparison relations and fractional/out-of-range numeric values, reused
  destination/rebind/retained parent, source/clone independence.
- **Negative/safety tests:** empty policy, Float16/C>4/multi-channel Compare,
  temporary destinations, forbidden aliases, malformed raw ABI outputs/scalars/
  selectors, preflight preservation and exception translation. Include NaN/Inf,
  signed zero and Ada validity/assertion profile without accidental
  `Constraint_Error`; no NaN payload/SIMD bit-stability promise.
- **Dependencies:** none of CORE-FIN-02/03, AUD-01..07, optional GPU work or
  proprietary campaigns. Focused native probes/tests are ordinary implementation
  work, not a prerequisite global audit.
- **Completion:** all four references and applicable installed/cross-platform
  CI; contracts/examples and explicit exclusions; no warnings/ABI regression.
  Additive API, old modes unchanged; expected low maintenance.

### CORE-FIN-02 — general pairwise/numerical norms and binary distances

**Required for 0.6.** Benefit: Features descriptor pair comparisons and
Calib3D/navigation residual/convergence checks. Medium, separate feature PR.
Existing top-K squared/Hamming support is credited, not rewritten.

- **Exact scope:** direct-native difference L1/L2/Infinity and squared L2;
  unary squared L2; optional **numeric** same-shape UInt8 C1 selector mask;
  relative numeric difference against Right; unmasked unary/pairwise Hamming
  and Hamming2 for UInt8 C1. Initial numeric depths: UInt8/Int8/UInt16/Int16/
  Float32/Float64, channels folded as native, full matching N-D shape and strided views.
  **Int32 and Float16 are rejected by new functions.** In 4.1 generic difference
  kernels subtract before widening (`norm.cpp:218..279`), so opposite Int32
  extrema can overflow. Existing Norm remains unchanged; callers can explicitly
  `Convert_To (Float64)` before new difference operations. No unsafe native
  integer-overflow parity test or hidden whole-matrix promotion is required.
  Enforce native count bounds before casting/accumulating. No UMat or binary
  masked/relative extension in the first PR.
- **Expected API:** `Difference_Norm` with `Kind : Norm_Kind := L2` and explicit
  `Relative : Boolean := False`, masked and unmasked profiles; separate
  `Squared_L2_Norm` / `Squared_L2_Difference_Norm`; a strong binary cell kind
  for `Hamming_Norm` / `Hamming_Distance`. **Do not add** a two-Mat `Norm`
  overload that collides with existing `Norm (Self, Mask, Kind)`. Keep existing
  `Norm_Kind (L1,L2,Infinity)` and defaults unchanged; extending an enum can
  break downstream exhaustive Ada case statements.
- **Native strategy, all four:** call pairwise `cv::norm(left,right,flags,mask)`
  directly. Never implement difference via saturated `Abs_Diff` or subtract.
  Pinned 4.x and 5.0 implementations use a norm of Right plus `DBL_EPSILON` on
  the generic relative path; backend/HAL behavior remains native. Test zero
  references instead of imposing a new divide-by-zero exception contract.
  Binary norms use 1-bit/2-bit **cells** (Hamming2 is not bit count divided by 2).
- **Explicit mask decision:** numeric masks select whole logical elements
  using nonzero bytes. Native Hamming masks bitwise-AND the XOR result, unlike
  numeric selection. Defer that mode rather than reuse an ambiguous “Mask”
  overload with different semantics. Do not claim native Hamming masks absent.
- **Thin/shim work:** new exact selector mapping, scalar double output and
  two input handles, optional mask handle; no new object lifetime. ABI output
  initialization, pointer safety and exception containment. Inspect native
  signed `int` Hamming result accumulation: bound total UInt8 bytes by
  `INT32_MAX/8` for bit distance and `/4` for two-bit cells (or a stricter
  conservative common bound) **before native execution**. Retain documented
  numerical precision/overflow limits, no invented big-integer reduction.
- **Positive tests:** known binary cell examples (`11` vs `00` counts once in
  Hamming2), unary/pairwise, squared-versus-L2 within tolerance, signed integer
  8/16-bit extrema (exposes saturated-difference bug), masked C1/multichannel numeric
  planes, nonzero mask bytes, N-D/strided layouts, relative zero/near-zero
  reference and native parity on all references.
- **Negative/safety tests:** mismatched complete shape/type, Int32/Float16,
  explicit Float64 conversion of Int32 extrema as the supported alternative, Hamming
  non-UInt8/C1, invalid options/selectors/output pointer, count-bound preflight
  without huge allocation, empty/mask policy documented and tested (native
  zero-size short-circuit only after safe shape checks), NaN/Inf/native result
  validity under assertions. Inputs and shallow aliases remain unchanged.
- **Dependencies:** none; independent of CORE-FIN-01. Source evidence ids
  `norm-41/46/410/50`; existing Norm declarations and batch-distance modes checked.
- **Completion/compatibility:** additive distinct functions, four-version
  positive/negative native parity and installed-consumer tests. No change to
  existing masked Norm policy; low ongoing cost.

### CORE-FIN-03 — portable native runtime information and diagnostics

**Required for 0.6.** All downstream modules need the actually linked OpenCV
version/build in support reports. Small, separate feature PR; no global state
mutation or new controlled object.

- **Exact scope/API:** `Native_Version_String return String` and
  `Native_Build_Information return String` in existing `OpenCV.Core`. Existing
  `OpenCV_Error` model. No hierarchy decision, compiler-default alias, timer,
  optimizer/thread setter, error callback or structured build-schema parser.
- **Native support:** `getVersionString` and `getBuildInformation` declared and
  implemented in all four references. `system.cpp` returns `CV_VERSION` and a
  native-owned static build string; these are **native runtime identity**, not
  crate version 0.5.1 or whichever headers the Ada consumer happens to include.
- **Shim requirements:** caller-provided byte buffer/capacity plus explicit
  required/written count, status and safe initialization; a size/query then
  copy protocol is suitable because the native build description is immutable.
  Define whether lengths exclude NUL and enforce it. Check size_t-to-fixed-width
  bounds, null/capacity combinations and truncation status. Copy from the native
  string inside the shim; no std::string, malloc ownership or borrowed pointer
  crosses to public Ada. Thin Ada allocates/copies into owned String immediately.
- **Ownership/safety:** returned Strings survive later queries/finalization;
  no mutable globals or shared thread-local diagnostic buffer reused as data.
  Build output is platform/build dependent text, may have newlines/non-ASCII;
  no exact format guarantee. Do not suppress allocation errors as success.
- **Positive tests:** version matches the actual matrix job's linked native
  release, nonempty build description, repeated and interleaved calls retain
  independent values, consumer after GPR install/relocation, no dependency on
  a working directory or source checkout.
- **Negative tests:** null output/count, zero/short capacity, count overflow
  policy, all outputs initialized on failure; useful diagnostic and Ada native
  failure translation. Don't snapshot compiler flags or revision text.
- **Dependencies:** none; can ship before either arithmetic/norm PR. Four
  references and existing OS/toolchain checks. Additive; very low maintenance.

## Optional feature queue — not stabilization prerequisites

This is the entire optional implementation queue selected here. Research-only
Quat/DualQuat, sparse arithmetic, async, direct UMat mapping and spectral
division are **not** disguised ready tasks. They need a consumer and a focused
design/source decision; their evidence remains in the portable matrix.

| ID | Exact scope / expected API | Native strategy / shim | Ownership/alias/tests | Value / complexity / dependencies |
| --- | --- | --- | --- | --- |
| **CORE-OPT-01** | One consumer-selected native tensor transpose/flip/broadcast **or** finite mask per PR; strong Ada permutation/axis/shape or mask result | transposeND 4.6+ references; flip/broadcast 4.10+; finiteMask 5.0 only. Compile-time native gate and explicit unsupported-version behavior, no algorithm backport. Thin point/count/shape values, call OpenCV | transposeND continuous C1/no same-data output; finiteMask Float32/64 C1..C4→UInt8 C1. Validate permutation/rank/count; tests every available version, absent-version rejection, ROI/empty/alias/NaN/Inf | Tensor/robust numerical consumer; medium per PR; none of required tasks technically needed, but consumer and focused safety design required |
| **CORE-OPT-02** | Native ticks/frequency **or** optimization/thread controls per PR; exact-width values, explicit global controls | All references have queries; backend counts differ. Call native functions, no timer object/lifetime framework | State restoration on all test exits; no concurrent OpenCV calls while setter runs; positive frequency, native tick progression, invalid count/options, no timing thresholds | Benchmark parity/Ada task oversubscription; small-medium; consumer/global-state review, not raw census closure |
| **CORE-OPT-03** | UMat Copy_To actual destination, masked copy, masked Set_To; mirror Mat signatures | UMat methods all four; direct native UMat inputs/output; no mapping or hidden transfer | Test fresh mask zeroing vs retained unselected values, nonzero masks, ROI/disjoint/exact aliases, reject partial overlap/temporary output, rebind/retained parent, empty/invalid ABI, OpenCL disabled and available smoke; no GPU promise | Allocation-stable UMat pipeline; medium; no required feature dependency; reshape and DFT/DCT explicitly out of this PR |
| **CORE-OPT-04** | FileStorage file-open append, then Base64 in a **separate** PR; strong options without raw flags | All four native flags; keep current limited owner and copied reads; forbid native MEMORY+APPEND; small native option mapping | Existing/new files, duplicate-key policy, malformed input and close failures, XML/YAML/JSON/Mat round trips, NUL and integer limits, no escaping nodes | Model/calibration storage; small-medium each; real consumer first; gzip qualification not assumed |

## Release/freeze discipline

0.6 is not “all Core exported symbols.” Review the three required features and
retain documented existing limitations. Qualify safety/behavior of the retained
portable baseline, source docs and installed/cooperating consumers; no unresolved
**known defect** may be hidden by scope exclusion. Newly requested optional
features need their own consumer-value/cost review. 1.0 additionally freezes
names, source/ownership/exception semantics, compiler/native ABI rebuild boundary,
supported native/OS matrix and semantic-versioning policy as in the earlier
roadmap; it does not require C++ expression/template fidelity.

No “zero maintenance” promise: new native releases, security fixes and compilers
still require testing. The [artifact policy](core-audit-artifact-policy.md)
recommends a lightweight successor PR **only after approval** so feature authors
can start from main without importing raw research data or audit infrastructure.