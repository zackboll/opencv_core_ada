# Practical portable Core completion scope — CORE-CLOSE-001B

Current feature note: scalar modes landed in PR #90 (CORE-FIN-01). See
[numerical norms](numerical-norms.md) for the bounded CORE-FIN-02 API and
qualification boundary. The historical proposal/JSON ledger below is not a
current implementation-status certificate; forensic artifacts remain unchanged.

**Proposal for independent review, not API approval or exhaustive coverage.**
This document and the [finite backlog](core-finish-backlog.md) supersede the
earlier roadmap's requirement to finish the entire native census **before any
feature implementation**. A focused feature needs its own source/ABI/mode review,
not individual reconciliation of 9,000–10,000 declaration occurrences.

Baseline: `bd60e969e2a2471c1bb4b90d3006e53f3f6e09eb`; fetched main remains
`64d8a60b59acfe4334045280e430c4774b5cad89`. The original 26 records, complete
header-path proofs, source/Clang ledgers and unresolved blockers are preserved
byte-for-byte. `UPSTREAM_DISCOVERY_BLOCKED` and `COVERAGE_AUDIT_BLOCKED` remain
honest forensic results, **not blockers to selecting these three features**.

## Three different objectives

| Objective | Completion meaning | What it is not |
| --- | --- | --- |
| **A — portable Core capabilities** | Owned Mat/value/access/interoperability, common numerical/mask/layout/statistical/linear/spectral operations, practical sparse/persistence and native diagnostic identity, with explicit supported modes | Binding every native overload, all scalar depths or accelerator parity |
| **B — optional/version-specific capabilities** | Add only with a named consumer and a bounded safe native/version strategy | Automatically mandatory because declared/exported, or guaranteed GPU execution |
| **C — native implementation surface** | Preserve as research/provenance; inspect relevant parts when wrapping a capability | A backlog of C++ specializations, generated operators, HAL/dispatch or STL syntax to reproduce in Ada |

Proposed 0.6 completion target: retain and qualify the existing documented
portable baseline, add the three `REQUIRED_FOR_0_6` capabilities below, fix any
demonstrated safety defects, and document the explicit limits. This is a finite
**scope proposal**, not a claim that every important portable family has already
passed a complete implementation/test audit. Existing broad mode qualification
remains in `unreviewed_scope`; particularly external-buffer lifetime, unusual
depth/rank/channel combinations, linear solver flags and native failure behavior
still need feature-local review. A discovered defect stays a release blocker.

## Header-family scope review (planning level only)

The authenticated [complete header manifest](core-api-header-manifest.json)
contains 113/141/149/145 paths for 4.1/4.6/4.10/5.0. We do **not** change the raw
header records' `scope_review`, exclusions or native declaration dispositions.
The following are reviewed **binding-target boundaries**, not per-declaration
approval. Unlisted utility/header declarations retain the existing unresolved
ledger; they are neither silently deleted nor made mandatory by installation.

Header links use the pinned
[5.0 Core source directory](https://github.com/opencv/opencv/tree/40738fb16ceddb5fb3fea747585f7ce6abb0605b/modules/core/include/opencv2/core)
and exact per-version blob identities in the manifest/scope JSON.

| Header family | Practical category | Source-backed disposition |
| --- | --- | --- |
| `core.hpp` | Portable user-facing API | Arithmetic, norms, reductions, decomposition, spectra/RNG/clustering are user capabilities; overload and flag spelling are not independent features |
| `mat.hpp`, `mat.inl.hpp` | Portable API + supporting public inline API | Mat/UMat/SparseMat ownership, views/shape, access and copying matter. MatExpr/template iterator machinery is not mandatory syntax parity; limits must be stated |
| `matx.hpp`, `matx.inl.hpp`, `types.hpp`, `operations.hpp` | Supporting public value/inline API | Preserve useful Scalar/Point/Rect/Size, small vectors/fixed matrices and their value semantics. Generic specialization/operator count is not a semantic denominator |
| `persistence.hpp` | Portable user-facing API | FileStorage XML/YAML/JSON, owned reads and scoped hierarchy navigation are primary; optional storage flags and escaping FileNode objects are separate decisions |
| `utility.hpp` | Portable utilities + optional global/backend controls | Version/build information is required; ticks, optimization/thread setters, command-line/parallel wrappers are not mandatory when Ada facilities or targeted controls suffice |
| `affine.hpp` | Optional public value API | Public `Affine3<T>` is real capability, useful for Calib3D/navigation if shared pose conventions are agreed. Do not force a new representation without a consumer |
| `quaternion.hpp`, `dualquaternion.hpp` and inline companions | Optional/version-specific public math | Public Quat/DualQuat numerical family; absent 4.1 reference. Unit, interpolation and conversion semantics need coherent design, not mechanical overload import |
| `async.hpp`, **`detail/async_promise.hpp`** | Optional public asynchronous API | AsyncArray/AsyncPromise are documented public result/producer types. `detail/` is **not** an exclusion reason; Ada task/lifetime/exception model remains research |
| `ocl.hpp`, `cuda.hpp`, CUDA/OpenCL helpers, buffer pools and parallel backend API | Optional backend/public API | Native device/context/queue/allocator controls exist but are outside mandatory portable target. UMat CPU fallback baseline stays supported independently |
| `directx.hpp`, `opengl.hpp`, `va_intel.hpp`, `eigen.hpp`, FP-control utilities | Platform/external-library API | Optional interoperability/dependencies; existence does not establish availability on every target |
| **`hal/interface.h`**, `cvdef.h` public depth/channel definitions | Supporting public value/representation API | Account for `CV_CN_MAX`, encodings, Float16 and new 5.0 depths. Reject unsupported input safely; do not expose private native type codes publicly. Other HAL routines are not thereby mandatory |
| `private*`, dispatch helpers, SIMD intrinsic/HAL kernels, generated runtime loaders | Internal implementation machinery | Keep raw evidence for ABI/safety research; no direct Ada public counterparts required. Public exceptions such as depth macros remain explicitly separated |
| `core/core.hpp`, legacy `core_c.h` / `types_c.h` | Legacy compatibility machinery | Forwarding headers/legacy C object syntax do not add mandatory capabilities beyond modern Core equivalents. Retain availability/removal evidence |
| Other public utility types (logging/filesystem/TLS/Algorithm/Ptr) | Optional unless a concrete portable consumer requires a subset | Source is retained; no assumption “unreviewed means absent.” Ada logging/filesystem/tasking and existing owned wrappers avoid a generic C++ framework |

## Evidence and status vocabulary

All four exact references: **4.1.0 / 4.6.0 / 4.10.0 / 5.0.0**. Source links below
are commit-pinned, never current online documentation. [Seed JSON](core-api-coverage.json)
records exact native/Ada/shim/test locations; [new practical evidence](core-portable-evidence.json)
adds four-version **implementation** excerpts for the first tasks. The
[machine-readable decisions](core-portable-scope.json) are checked separately
without weakening forensic validation.

- **Existing/limited**: implementation evidence exists and the bounded baseline
  is sufficient for this scope decision; **not `BOUND_FULL`** or all-mode proof.
- **Partial**: useful modes exist, while named missing modes are verified in the
  public profiles; the missing part is not assumed implemented by a similar name.
- **Missing confirmed**: the named public behavior is absent from inspected
  public profiles, corroborated by body/thin/shim mappings and the seed audit.
- **Optional / Research / Excluded**: scope decisions, not claims that OpenCV
  lacks the capability. No family is certified “full” by this matrix.

### Current portable baseline — credit what already exists

| Native semantic family | Ada equivalent / implementation evidence | Status / reference versions | Limits, safety and downstream relevance |
| --- | --- | --- | --- |
| Mat ownership, create/clone, shape/strides, ROI/slice/reshape | `Mat`, `Create`, `Clone`, `Region`, `Slice`, `With_Selected_View`, `Reshape`; [public spec](../src/opencv-core.ads), [body](../src/opencv-core.adb), [ownership guide](ownership-and-views.md) | Existing/limited; all four, native 5.0 rank differs | Callback-scoped external storage; assignment shares backing data, Clone copies; no arbitrary partial-overlap promise. Foundation for all six downstream module families |
| Public scalar/geometry values and typed access | [Root values](../src/opencv.ads), [typed-access guide](typed-access-guide.md), fixed vector/matrix helpers | Existing/limited; all four | Reuse root values, don't add competing Point/Scalar; Float16 bit access is not universal Float16 arithmetic. All module interoperability |
| Conversion/copy/masks/channels/layout/borders | `Convert_To`, `Copy_To`, `Set_To`, `Split/Merge/Mix_Channels`, `Transpose/Flip/Rotate/Repeat/HConcat/VConcat`, border operations; [operations guide](core-operations-guide.md) | Existing/limited, partial matrix/scalar modes; all four | Preserve order/nonzero Ada bounds, documented 2-D/N-D and per-depth limits, caller-owned destination rebind policy. Imgproc/Video/Features |
| Statistics/reductions/nonfinite checks | Sum/Mean/Mean_Std_Dev/Reduce/Arg_Minimum/Arg_Maximum, `Min_Max_Indices` = **minMaxIdx**, Check_Range/Patch_NaNs/PSNR | Existing/limited; all four, compatibility helpers where needed | Native NaN/index behavior is not normalized; finiteMask is different. Numeric/Calib3D/Video validation |
| GEMM and transposed products | **Matrix_Multiply / Matrix_Multiply_Add = gemm; Transposed_Product = mulTransposed**; spec/body plus native mappings in seed `core.linear.gemm` | Existing/limited; all four | Float32/64 C1/C2 matrix products versus real elementwise Multiply; transpose/addend/output flags not exhaustively certified. Calib3D/navigation |
| Decomposition, regression, subspaces | **Singular_Value_Decomposition = SVDecomp**, SVD_Back_Substitute, Pseudo_Inverse, Reciprocal_Condition_Number, SVD_Solve_Zero; Solve_Least_Squares, eigen, PCA/LDA | Existing/limited; all four | Don't reopen all native method overloads as mandatory; preserve tolerance, finite-input and solver success contracts. Features/Calib3D/navigation |
| Covariance, polynomial solvers and LP | **Covariance = calcCovarMatrix**, Solve_Cubic/Polynomial/Linear_Program; [spec](../src/opencv-core.ads) and body | Existing/limited; all four | Bounded documented modes; no generic optimizer callback framework needed. Numerical users |
| DFT/DCT/complex/CCS and multiplication | Full/packed/inverse-real/row functions, **Multiply_Spectra / Multiply_Packed_Spectra[_Rows] = mulSpectrums**; seed spectral records and transform tests | Existing/limited; all four | Owned outputs, Float32/64, DCT length/buffer limits; no reusable/UMat/in-place or general spectrum-division claim. Spectral consumers |
| RNG, kmeans and batch distance | RNG helpers, K_Means, **K_Nearest_Neighbors = batchDistance**, including squared L2/Hamming/Hamming2 | Existing/limited; all four | Top-K UInt8/Float32 C1 row vectors; no mask/update/crosscheck/all-pairs guarantee. Features is already served; general pairwise norms still absent |
| Sparse storage/access/reductions | [Sparse spec/body](../src/opencv-core-sparse.ads), From_Dense/To_Dense/Convert_To, 32 layouts and For_Each_Stored, Norm/Normalize/Min_Max_Loc | Existing/limited; all four | Stored zeros ≠ missing nodes; traversal mutation prohibited; native sparse reductions Float32/64 C1. Numerical/model consumers |
| Persistence and cooperative interop | [Persistence](../src/opencv-core-persistence.ads), limited storage/map/sequence APIs; [module interop](../src/opencv-core-module_interop.ads), sparse bridge, transfers | Existing/limited; all four | Returned values copied/owned, no escaping borrowed native objects; same compatible native installation required. All module crates/configuration |

### Ranked candidates — every requested gap gets a disposition

IDs below match the checked planning ledger. Consumer names describe expected
value, **not a claim of measured demand or a mandatory feature request**.

| Stable planning ID / native behavior | Existing Ada / status | Native reference availability | Decision and specific reason / consumers | Safety and evidence |
| --- | --- | --- | --- | --- |
| `scalar-modes`: add/subtract/multiply/divide/compare scalar modes | Matrix/matrix functions and destinations exist; **partial family / missing scalar modes confirmed** | All four | **REQUIRED_FOR_0_6**, task CORE-FIN-01: avoid allocating constant Mats for scales/offsets/thresholds; Imgproc, Features, Calib3D, Video | Initial seven non-Float16 depths, 2-D arithmetic C1..C4, scalar compare C1; native rounding/zero rules, reverse operands; seed scalar records; pinned arithm excerpts |
| `general-norms`: difference/relative/squared/Hamming | Unary/masked Norm L1/L2/Infinity only; **missing confirmed** general modes; batch distance already has binary/squared modes | All four | **REQUIRED_FOR_0_6**, CORE-FIN-02: residual/error and descriptor comparisons across Features/Calib3D/navigation | Distinct Difference_Norm avoids existing mask-profile collision; new numeric subset excludes Int32/Float16 (legacy subtraction-before-widening), UInt8 C1 Hamming; bit masks deferred; [4.1 norm](https://github.com/opencv/opencv/blob/371bba8f54560b374fbcd47e7e02f015ac4969ad/modules/core/src/norm.cpp#L1014), [Int32 safety source](https://github.com/opencv/opencv/blob/371bba8f54560b374fbcd47e7e02f015ac4969ad/modules/core/src/norm.cpp#L218), [5.0 norm](https://github.com/opencv/opencv/blob/40738fb16ceddb5fb3fea747585f7ce6abb0605b/modules/core/src/norm.dispatch.cpp#L521) |
| `runtime-identity`: getVersionString/getBuildInformation | No public equivalents found; **missing confirmed** | All four | **REQUIRED_FOR_0_6**, CORE-FIN-03: actual runtime identity for all downstream bug reports, tiny maintenance surface | Ada-owned copied strings, not std::string/borrowed pointer; four pinned system.cpp excerpts |
| `transpose-nd`: transposeND | Only ordinary 2-D Transpose; **optional** | absent 4.1; present 4.6/4.10/5.0 | **OPTIONAL_LATER**, tensor consumer first; not needed for ordinary Geometry point collections | [4.10 implementation](https://github.com/opencv/opencv/blob/71d3237a093b60a27601c20e9ee6c3e52154e8b1/modules/core/src/matrix_transform.cpp#L292) requires continuous C1 and different data pointers; no blanket strided/in-place support |
| `flip-broadcast-nd`: flipND/broadcast | No equivalent established; **optional** | absent 4.1/4.6; present 4.10/5.0; 5 adds MatShape overload | **OPTIONAL_LATER**, tensor layout consumer needed | Source/version gate, shape/permutation/overflow checks; no speculative historical fallback; seed native locations |
| `runtime-timing`: ticks/frequency | No public binding; **optional** | All four | **OPTIONAL_LATER**, Ada.Real_Time already covers portable application timing | Exact int64 tick width, frequency and epoch limits; seed runtime.timing |
| `runtime-optimization`: use/setOptimized and thread controls | No public binding; **optional** | All four; backend behavior varies | **OPTIONAL_LATER**, diagnostics/tasking consumer first; no setters in runtime identity PR | Native [optimization docs](https://github.com/opencv/opencv/blob/40738fb16ceddb5fb3fea747585f7ce6abb0605b/modules/core/include/opencv2/core/utility.hpp#L642) require no concurrent OpenCV execution; restore state in tests |
| `umat-copy-set`: masked set/copy, caller-owned copy | Unmasked Set_To, Copy_To returns new UMat; **partial / omissions confirmed** | All four | **OPTIONAL_LATER**, CORE-OPT-03 if an allocation-stable UMat pipeline needs it | No host staging; fresh masked output vs reused unselected elements, alias/rebind/parent retention; UMat mat.hpp and seed mappings |
| `umat-reshape-transforms`: reshape, DFT/DCT parity | Mat reshape/spectra only; UMat overloads unsupported; **research** | UMat reshape declared all four; spectral InputArray presence is not backend qualification | **DEFERRED_RESEARCH**, choose a consumer subset rather than universal UMat parity | Shared header continuity/rank, transform alias/work buffers and native backend probes; [existing documented boundary](ownership-and-views.md) |
| `spectral-division`: divSpectrums/CCS division | Ordinary Divide is not equivalent; **research** | Core entry only 5.0 among references | **DEFERRED_RESEARCH**, deconvolution consumer first; no pre-5 algorithm clone | [5.0 source](https://github.com/opencv/opencv/blob/40738fb16ceddb5fb3fea747585f7ce6abb0605b/modules/core/src/dxt.cpp#L3776) Float32/64 C1/C2, explicitly non-in-place, epsilon denominator handling |
| `finite-mask`: finiteMask | Check_Range rejects/diagnoses, Float16 Is_Finite is scalar; **optional**, not equivalent per-element mask | 5.0 only | **OPTIONAL_LATER**, robust filtering consumer; no requirement to backport | [Source](https://github.com/opencv/opencv/blob/40738fb16ceddb5fb3fea747585f7ce6abb0605b/modules/core/src/nan_mask.dispatch.cpp#L118): Float32/64 C1..C4, UInt8 C1 output, N-D host path; X=X fails to detect infinity |
| `sparse-baseline` | Owned N-D, access/traversal, conversion and reductions present; **existing/limited** | All four | **ALREADY_SUFFICIENT** for baseline; no automatic sparse feature PR | Float32/64 C1 reduction boundary and stored-node semantics retained, not BOUND_FULL |
| `sparse-extra-arithmetic` | No general add/subtract binding established; **research**, not verified native gap | Not established as a general native family | **DEFERRED_RESEARCH**; existing conversion/scaling enough until a concrete sparse operation is identified | Do not invent an algorithm or densify implicitly; inspect SparseMat exact member family |
| `sparse-minmax` | Deliberately unsupported | Native docs prohibit range shift on sparse arrays | **INTENTIONALLY_EXCLUDED**: implicit zeros would change; explicit To_Dense instead | [4.1 native prohibition](https://github.com/opencv/opencv/blob/371bba8f54560b374fbcd47e7e02f015ac4969ad/modules/core/include/opencv2/core.hpp#L731); Sparse spec Normalize contract |
| `persistence-baseline` | XML/YAML/JSON, disk/memory, typed/Mat reads, scoped maps/sequences; **existing/limited** | All four | **ALREADY_SUFFICIENT** for ordinary module configuration | Strict integer/string rules, copied results, limited owner; no promise every FileStorage mode is bound |
| `persistence-append-base64` | Storage_Mode only Read_Only/Write_Only; options absent; **missing confirmed** | Flags in all four | **OPTIONAL_LATER**, CORE-OPT-04 only on actual large model/log consumer need | Sequence Append is not file-open APPEND; native APPEND+MEMORY incompatible; seed evidence |
| `persistence-gzip` | Public spec excludes gzip, filename validator merely checks empty/NUL; **research** | Native docs all four; zlib build dependent | **DEFERRED_RESEARCH**, do not call runtime .gz behavior universally absent or qualified | Resolve implementation/build flags, close errors and 5.0 suffix differences; retain current explicit unsupported contract |
| `escaping-file-nodes` | Scoped navigation already iterates; **excluded abstraction**, not missing iteration | FileNode/iterator native all four | **INTENTIONALLY_EXCLUDED**: avoid borrowed lifetime framework for marginal value | Safe copied/indexed/map-key traversal remains, callback proposal possible later |
| `quaternion-affine` | Fixed matrix helpers exist; no Quat/DualQuat API established; **optional** | Affine3 all four; Quat/DualQuat absent 4.1, present other references | **OPTIONAL_LATER**, pose/navigation consumer and agreed conventions first | Unit assumptions, singularities/interpolation, value ownership; no reimplementation for 4.1 |
| `async-promise` | No public Ada async model; **research** | AsyncArray/AsyncPromise absent 4.1 headers, present others | **DEFERRED_RESEARCH**; public native producer explicitly retained despite detail/ | Task cancellation, exception transport, outstanding result/finalization; [public Promise](https://github.com/opencv/opencv/blob/40738fb16ceddb5fb3fea747585f7ce6abb0605b/modules/core/include/opencv2/core/detail/async_promise.hpp#L19) |
| `new-depths-shape` | Eight-depth public API; 5.0 shape adaptation exists; **optional additions** | 5.0 BF16/Bool/UInt32/UInt64/Int64; MatShape MAX_DIMS 10, CN_MAX 128 vs 512 in 4.x | **OPTIONAL_LATER** new types; mandatory safety of existing conversions is not optional | [HAL public encodings](https://github.com/opencv/opencv/blob/40738fb16ceddb5fb3fea747585f7ce6abb0605b/modules/core/include/opencv2/core/hal/interface.h#L50); native operation support is per depth |
| `device-backends` | UMat baseline exists, device control/interop not required; **excluded from primary target** | Header/backend dependent | **INTENTIONALLY_EXCLUDED** from mandatory 0.6, but documented optional capabilities remain present | No GPU execution or portability promise; opaque handles/lifetimes need consumer-backed decision |
| `cpp-machinery` | Idiomatic Ada records/operations replace exact C++ syntax; **excluded surface parity** | Native templates/HAL/dispatch vary | **INTENTIONALLY_EXCLUDED** as mandatory entry points; no business value in reproducing every specialization | Keep raw blockers and public macro/type evidence; exclusion is not “not upstream” |
| `renamed-numerics` | GEMM/transposed product/top-K/SVD/extrema/covariance and CCS multiply **already implemented under Ada names** | All four with documented limits | **ALREADY_SUFFICIENT** baseline; no duplicate-name wrappers | Preserve outstanding mode/test qualification; no full classification by name alone |

## Decision and verification boundary

Only scalar modes, general norms and runtime identity are proposed as new
mandatory features. Optional tasks must remain separate PRs, not creep into one
“finish Core” wrapper batch. All require existing warning/error/ABI/lifetime
policy and four-version tests where supported. Geometry stays point/value based;
this plan does not require it to take a Core Mat bridge.

`python3 scripts/check_core_portable_scope.py` checks required decisions, the
first-three dependency-free tasks, local Ada declarations, pinned source excerpt
identities, readable document entries and preservation of all nine forensic JSON
artifacts. It certifies **planning consistency only**, not implementation success,
test completeness, source-discovery closure or API stability. Separate forensic
checks remain unchanged; no completeness percentage is published.