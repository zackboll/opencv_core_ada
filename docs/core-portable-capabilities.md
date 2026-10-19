# Practical portable Core completion roadmap

This PR integrates the practical completion roadmap, not the unfinished exhaustive audit.

Baseline: `26bf5e2e8151cb0545b928b72d3d87677543c1ae` (main, including
[CORE-FIN-01, PR #90](https://github.com/zackboll/opencv_core_ada/pull/90)).
The public crate remains **0.5.1**. This plan does not create a 0.6.0 release,
promise a delivery date, approve new API signatures, or certify exhaustive native
coverage. See the [finite backlog](core-finish-backlog.md),
[standalone ledger](core-portable-scope.json), its [schema](core-portable-scope-schema.md),
and [audit provenance and unresolved gaps](core-audit-provenance.md).

## What practically complete means

Retain and qualify the documented portable baseline; complete the bounded
general-norm and runtime-identity tasks; fix demonstrated safety defects; and
publish explicit supported modes and limitations. Existing broad mode review is
not finished: external-buffer lifetimes, unusual depth/rank/channel combinations,
linear-solver flags and native failure paths still need feature-local review.
A known defect cannot be hidden by declaring its family optional.

### A. Portable user-facing capabilities

The existing API already supplies controlled Mat ownership and shallow assignment,
explicit deep Clone, views/N-D shape, typed access and interop; shared point,
size, rectangle and scalar values; generic vectors/fixed matrices; arithmetic,
masks, layout, reductions/statistics, RNG/clustering, linear algebra and spectra.
Sparse storage and persistence have useful, intentionally limited public APIs.
Read the existing [operations](core-operations-guide.md),
[ownership](ownership-and-views.md), [typed access](typed-access-guide.md),
[sparse/persistence](sparse-and-persistence-guide.md), and
[interop](interop-and-compatibility.md) guides for contracts, not a new claim that
every native overload or mode has been audited.

GEMM is exposed as `Matrix_Multiply` / `Matrix_Multiply_Add`; transposed product,
SVD, PCA, covariance, extrema, packed spectral multiplication/DFT/DCT and batch
distance/top-K already exist under Ada names. Do not reopen them merely because
C++ spellings differ. The ledger's local declaration checks credit presence,
not complete semantic or test qualification.

CORE-FIN-01 now provides **14 public overloads**: Mat/Scalar Add, Subtract,
Multiply, Divide, reverse Subtract_From and Divide_Into, and C1 scalar Compare,
each with owned-result and reusable-destination forms. Arithmetic is nonempty
2-D C1..C4, seven non-Float16 depths, source-depth/unmasked output. Scalar Compare
is C1 with a Float64 value and UInt8 0/255 result. Active scalar component,
coefficient, integer zero-denominator, alias and temporary-destination policies
remain those of the merged API. There is no new UMat, N-D or masked scalar mode.

### B. Optional/version-specific capabilities

Optional does not mean absent upstream, promised, or a release blocker. Require
a named downstream consumer, source/version review and bounded ownership/ABI
design first. UMat CPU fallback remains supported without a GPU-execution promise.
N-D tensor helpers, selected UMat destination parity, native ticks/global controls,
append/Base64, OpenCV 5 finite masks/new depths, and quaternion/affine value
utilities stay in a finite optional/research queue. Gzip, async, direct mapping,
UMat reshape/transforms and spectral division have unresolved research contracts.
Geometry consumers need not adopt a Core Mat bridge.

### C. Native machinery without direct Ada parity

Template specializations, expression/iterator syntax, STL, generated operators,
legacy C wrappers, HAL/SIMD/dispatch and loaders are not a mandatory Ada API
denominator. Public depth/channel encodings in `hal/interface.h` are nevertheless
real representation constraints, not private machinery to ignore. Public
AsyncPromise under `detail/async_promise.hpp` is not excluded merely by its path.
Platform/device headers (CUDA/OpenCL/OpenGL/DirectX/VA, Eigen, buffer pools,
parallel backends) remain consumer-dependent, not universally available.
Logging/filesystem/TLS/Algorithm/Ptr and command-line/parallel frameworks need
no syntax-parity wrapper where Ada facilities or existing owners suffice.

## All 24 practical decisions

IDs are preserved from the pinned source audit. `REQUIRED` is an inclusion
decision, **separate** from implementation status. `EXISTING_LIMITED` is not
`BOUND_FULL`. All four references mean 4.1.0, 4.6.0, 4.10.0 and 5.0.0.

| Stable ID | Decision / current status | Boundary, value and version constraints |
| --- | --- | --- |
| `scalar-modes` | REQUIRED / IMPLEMENTED_IN_MAIN | CORE-FIN-01, PR #90; intensity/residual offsets, scales and threshold masks; all four, bounded modes above |
| `general-norms` | REQUIRED / PLANNED_REQUIRED | CORE-FIN-02; pairwise/relative/squared numeric and binary descriptor distances; all four; existing two-Mat Norm is masked unary, not pairwise |
| `runtime-identity` | REQUIRED / PLANNED_REQUIRED | CORE-FIN-03; copied native version/build strings for every downstream module; all four; no setters |
| `transpose-nd` | OPTIONAL_LATER / OPTIONAL | CORE-OPT-01; tensor consumers; native 4.6/4.10/5.0 only, continuous C1, no same-data output; no 4.1 backport |
| `flip-broadcast-nd` | OPTIONAL_LATER / OPTIONAL | CORE-OPT-01; native 4.10/5.0 only; axis/shape/permutation/count review and explicit version gate |
| `runtime-timing` | OPTIONAL_LATER / OPTIONAL | CORE-OPT-02; native tick parity for benchmarks, all four; Ada.Real_Time suffices normally |
| `runtime-optimization` | OPTIONAL_LATER / OPTIONAL | CORE-OPT-02; task oversubscription controls, all four; process-global state, no concurrent setter safety or worker-count guarantee |
| `umat-copy-set` | OPTIONAL_LATER / OPTIONAL | CORE-OPT-03; confirmed missing destination/masked subset; all four; allocation-stable UMat consumers, no hidden host staging |
| `umat-reshape-transforms` | DEFERRED_RESEARCH / RESEARCH_REQUIRED | Shared-storage reshape and UMat DFT/DCT backend/alias/lifetime modes need probes; existing Mat spectra are credited |
| `spectral-division` | DEFERRED_RESEARCH / RESEARCH_REQUIRED | Core native entry only in 5.0 among references; packed CCS and zero denominators; no speculative numerical backport |
| `finite-mask` | OPTIONAL_LATER / OPTIONAL | CORE-OPT-01; 5.0 Float32/64 C1..C4 to UInt8 C1; Check_Range already diagnoses invalid data; X=X is not an infinity filter |
| `sparse-baseline` | ALREADY_SUFFICIENT / EXISTING_LIMITED | Owned N-D Sparse_Mat, 32 typed layouts/traversal, dense conversion/scaling, Float32/64 C1 norms/extrema; all four; baseline sufficiency, not full member parity |
| `sparse-extra-arithmetic` | DEFERRED_RESEARCH / RESEARCH_REQUIRED | No established general native SparseMat add/subtract family; do not invent a sparse algorithm library or call it a confirmed missing binding |
| `sparse-minmax` | INTENTIONALLY_EXCLUDED / INTENTIONALLY_EXCLUDED | Native sparse normalization forbids shifting implicit zeros; explicit To_Dense is the alternative, all four |
| `persistence-baseline` | ALREADY_SUFFICIENT / EXISTING_LIMITED | XML/YAML/JSON disk/memory, typed/Mat copied reads and scoped map/sequence navigation; all four; strict integer/string and limited-owner rules |
| `persistence-append-base64` | OPTIONAL_LATER / OPTIONAL | CORE-OPT-04; flags available all four but public file-open modes missing; sequence Append is not file APPEND; native MEMORY+APPEND incompatible |
| `persistence-gzip` | DEFERRED_RESEARCH / RESEARCH_REQUIRED | Public spec excludes gzip; filename validation alone does not reject .gz; native zlib/build/close/suffix behavior needs review, not universal runtime absence or qualification |
| `escaping-file-nodes` | INTENTIONALLY_EXCLUDED / INTENTIONALLY_EXCLUDED | Avoid borrowed node/iterator lifetimes; copied indexed/map-key traversal already exists; safe callback design can be proposed separately |
| `quaternion-affine` | OPTIONAL_LATER / OPTIONAL | Affine3 all four, Quat/DualQuat absent 4.1; pose/navigation consumer and unit/interpolation/singularity conventions first; no 4.1 math backport |
| `async-promise` | DEFERRED_RESEARCH / RESEARCH_REQUIRED | AsyncArray/AsyncPromise public in 4.6/4.10/5.0; task cancellation, finalization and exception transport unresolved |
| `new-depths-shape` | OPTIONAL_LATER / OPTIONAL | 5.0 BF16/Bool/UInt32/UInt64/Int64 extensions; existing eight-depth API/shape adaptation remains; 5.0 rank 10/channels 128 vs 4.x channels 512; conversion safety is mandatory |
| `device-backends` | INTENTIONALLY_EXCLUDED / INTENTIONALLY_EXCLUDED | Excluded from mandatory portable scope, not absent upstream; device/context/allocator interop requires consumer and dependency/lifetime review |
| `cpp-machinery` | INTENTIONALLY_EXCLUDED / INTENTIONALLY_EXCLUDED | Exact specialization/operator/HAL/dispatch/STL/legacy-C parity is not useful Ada capability completeness; keep relevant public value/representation constraints |
| `renamed-numerics` | ALREADY_SUFFICIENT / EXISTING_LIMITED | Existing GEMM, transposed product, SVD/PCA/covariance/extrema, packed spectra and batch distance; all four within documented modes, no duplicate-name wrappers |

## Qualification and maintenance boundary

FIN-01 evidence covers 2,037 registered AUnit tests, the four reference native
versions, hosted Ubuntu/macOS ARM64, Debian 12 GNAT 12, GNAT Pro 25.2 with
Scarthgap OpenCV 4.9, native x86_64/ARM64 sanitizers, and full-system target
ASan/UBSan/LSan. This is **not** whole-Core qualification. Preserve the eight
existing validation-profile exceptions, Windows/MSYS2 and MacPorts policy skips,
and physical target hardware **NOT TESTED**; see the
[FIN-01 record](core-finish-backlog.md).

Future native releases and compiler/security updates require maintained tests,
representation checks and explicit unsupported-mode handling. Any future stable
API freeze must review names, ownership/exception semantics, native/compiler
rebuild boundaries, supported platforms and semantic-versioning policy. Optional
scope is not automatically promoted. The [validator](../scripts/check_core_portable_scope.py)
certifies planning consistency only; it neither rediscovers upstream nor proves
Ada coverage, numerical correctness or source authenticity from remote bytes.