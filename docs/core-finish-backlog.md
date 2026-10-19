# Finite Core completion backlog

This is documentation/planning, not implementation or a release announcement.
Version remains **0.5.1**. The [capability decisions](core-portable-capabilities.md)
and [ledger](core-portable-scope.json) bound the target. FIN-02 and FIN-03 are the
next required implementation PRs; they do not depend on one another, importing
PR #89, or closing its forensic census. Expected API below remains subject to
focused API review. Approximate size is review complexity, not a schedule.

## CORE-FIN-01 — IMPLEMENTED_IN_MAIN

[PR #90](https://github.com/zackboll/opencv_core_ada/pull/90) merged source HEAD
`365d22dfd76520c85e0c24ea1b228c39a424d57e` through main merge
`26bf5e2e8151cb0545b928b72d3d87677543c1ae`.
Fourteen public overloads implement Mat/Scalar addition, subtraction,
multiplication, division, reverse scalar subtraction/division, C1 scalar
comparison, owned results and reusable destinations. It is no longer proposed
work. The [public declarations](../src/opencv-core.ads) define the exact bounded
modes and integer-division/alias policies; no blanket native overload parity.

Qualification: 2,037 registered AUnit tests; four reference OpenCV versions;
hosted Ubuntu/macOS ARM64; Debian 12 GNAT 12; GNAT Pro 25.2 / Scarthgap OpenCV
4.9; full-system target ASan/UBSan/LSan; native x86_64/ARM64 sanitizers.
Read [R1](core-fin-01-r1-qualification.md), [R2](core-fin-01-r2-sanitizers.md),
and [R3](core-fin-01-r3-target-sanitizers.md) as historical evidence at their
recorded heads, not as current PR-state descriptions. R3 resolves the target
sanitizer blocker; physical hardware remains **NOT TESTED**.

The validation profile still has **eight pre-existing unexpected exceptions**,
not a clean validation-profile pass: Magnitude Phase special classifications;
Polar special classifications; Mat Float16 Minimum and Maximum special C3;
N-D extrema native floating specials; Sparse non-finite extrema; Sparse
one-sided extrema boundaries; UMat Float16 min max special values; UMat sqrt
special values. The corrected FIN-01 result is 2037 run / 2029 successful /
zero assertions / eight unexpected exceptions, with no added failures versus
baseline. Windows/MSYS2 and MacPorts policy skips are **not passes**. None of
this certifies the entire Core binding or authorizes a release.

## CORE-FIN-02 — General Numerical Norms and Binary Distances

**PLANNED_REQUIRED.** Medium, independent feature PR. Features descriptor
comparisons and Calib3D/navigation residual/convergence checks are the consumers.
Existing Norm and top-K squared/Hamming modes are credited, not rewritten.

- **Exact scope:** direct-native pairwise L1/L2/Infinity, unary and pairwise
  squared L2, pairwise relative numeric modes, optional same-shape UInt8 C1
  numeric selector masks; unary/pairwise unmasked UInt8 C1 Hamming/Hamming2.
  Numeric depths: UInt8/Int8/UInt16/Int16/Float32/Float64, channels folded as
  native, matching complete N-D shapes including strided views.
- **Expected Ada API:** `Difference_Norm` with existing `Norm_Kind := L2` and
  `Relative : Boolean := False`, masked/unmasked forms;
  `Squared_L2_Norm`, `Squared_L2_Difference_Norm`; strong binary cell kind for
  `Hamming_Norm` / `Hamming_Distance`. Do not overload two-Mat `Norm`: existing
  `Norm (Self, Mask, Kind)` is masked unary. Preserve `Norm_Kind (L1,L2,Infinity)`
  and defaults; an added enum literal can break exhaustive downstream cases.
- **Versions/source prerequisite:** inspect declarations and unary, pairwise,
  relative, mask, dispatch and count paths on **all four** pinned 4.1.0, 4.6.0,
  4.10.0, 5.0.0 sources before API/ABI approval. Ledger observations `norm-41`,
  `norm-46`, `norm-410`, `norm-50` and `norm-int32-safety-41` are selected
  evidence, not a complete kernel review. Recheck backend/HAL paths and signed
  arithmetic, not just generic source snippets.
- **Numerical safety:** new functions reject **Int32 and Float16**. Generic 4.1
  difference kernels subtract before widening, risking opposite Int32 extrema
  overflow. Existing Norm remains unchanged. Explicit `Convert_To (Float64)` is
  the supported alternative; no hidden whole-Mat promotion or unsafe overflow
  parity test. Call `cv::norm(left,right,flags,mask)` directly, never saturated
  `Abs_Diff`/subtract. Generic relative denominator is norm(Right)+DBL_EPSILON;
  retain native/backend behavior and test zero/near-zero references rather than
  imposing a new zero-division exception. Document precision/overflow limits.
- **Mask distinction:** numeric nonzero mask bytes select whole logical
  elements. Native binary masking instead ANDs the XOR result bitwise. Defer
  binary masked/relative modes rather than silently give `Mask` two meanings.
  Hamming2 counts nonzero two-bit cells, not bit count divided by two.
- **ABI/count safety:** fixed-width selectors and double output; initialize
  outputs, validate pointers/handles, contain exceptions. Before native casts
  or execution, bound plane/channel products and signed native accumulation.
  UInt8 total bytes must be at most INT32_MAX/8 for Hamming and INT32_MAX/4 for
  Hamming2, or a stricter documented common bound. No big-integer reduction.
  Public semantic policy stays in thick Ada; any necessary duplicate ABI guard
  needs its concrete `ABI safety` reason in the shim.
- **Tests:** direct native parity on all four; unary/pairwise; squared/L2
  relation within tolerance; signed 8/16-bit opposite extrema; numeric C1 and
  multichannel masks including nonzero bytes, N-D/strides, relative zero and
  near-zero Right, binary cell examples (11 vs 00 counts once in Hamming2).
  Reject full-shape/type mismatch, Int32/Float16, binary non-UInt8/C1, bad
  selectors/output pointers. Test explicit Int32-to-Float64 alternative,
  count preflight without huge allocations, NaN/Inf, unchanged inputs/shallow
  aliases, installed/relocated consumers. Review/document empty/mask policy;
  native zero-size shortcut only after safe shape checks. Tests belong in the
  tests crate; ordinary assertions use the thick public API.
- **Omissions/review gate:** no UMat, masked/relative binary extensions, existing
  Norm changes, native-overflow emulation, hidden conversion, or unrelated
  arithmetic. Four-version declaration/kernel review, naming, empty/mask
  contracts, count-bound proof/tests and validation-boundary review precede
  acceptance. Additive, low ongoing cost after qualification; no FIN-01 dependency.

## CORE-FIN-03 — Native OpenCV Runtime Identity

**PLANNED_REQUIRED.** Small, independent feature PR; all downstream modules need
the actually linked native identity in support reports.

- **Exact API:** `Native_Version_String return String` and
  `Native_Build_Information return String` in existing `OpenCV.Core`, with existing
  `OpenCV_Error` translation. No new public package or controlled owner.
- **Versions/source prerequisite:** all four pinned 4.1.0/4.6.0/4.10.0/5.0.0
  declarations and `system.cpp` implementations (`runtime-41/46/410/50` in the
  ledger). `getVersionString` returns CV_VERSION; `getBuildInformation` references
  a native-owned static build description. Query the linked native library, not
  crate 0.5.1, consumer header version or a cached compile-time substitute.
- **Caller-buffer ABI:** byte buffer/capacity, explicit required/written count
  and status, outputs safely initialized. Review a size-query then copy protocol;
  specify whether counts exclude NUL. Validate null output/count pointers,
  null buffer/capacity combinations, zero/short capacities, truncation and native
  size_t/fixed-width conversion bounds. Copy inside the shim; no escaping
  `std::string`, native pointer, allocation ownership or borrowed diagnostic
  storage. Thin Ada copies into **owned Ada String** results immediately.
- **Lifetime/error safety:** results survive later/interleaved queries and
  wrapper finalization; no global mutable state or data in last-error storage.
  Preserve multiline/non-ASCII native text without a parsed schema or exact
  format promise. Allocation failure is not success; contain native exceptions.
- **Tests:** version equals each job's linked reference; nonempty build text;
  repeated/interleaved calls retain independent strings; installed/relocated
  consumer without source checkout or working-directory dependency. Negative
  ABI tests cover null output/count, zero/short buffer, conversion overflow and
  failure initialization/diagnostics, plus Ada error translation. Do not snapshot
  compiler flags/revision text.
- **Omissions/review gate:** no timing, global threading/optimization setters,
  error callbacks, build parser, or new lifetime framework. Four-version source
  review and an explicit caller-buffer protocol/negative-test design precede
  implementation approval. Very low maintenance; no FIN-01/FIN-02 dependency.

## Finite optional queue — not required completion blockers

| Task | Bounded scope, prerequisites and tests |
| --- | --- |
| CORE-OPT-01 | One consumer-selected N-D transpose (4.6+), flip/broadcast (4.10+) or finite mask (5.0) per PR. Strong permutation/axis/shape types, native version gates, no algorithm backports. Review continuous C1/no same-data transpose, Float32/64 C1..C4 to UInt8 C1 finite mask, strides/counts, ROI/empty/alias/NaN/Inf and unavailable-version failures. |
| CORE-OPT-02 | Native ticks/frequency OR optimization/thread controls per PR, all four. Exact-width values, explicit process-global setters only after tasking/global-state review. Restore state on every test exit, no concurrent OpenCV calls during setters, positive frequency/progression without timing thresholds or exact worker-count guarantees. |
| CORE-OPT-03 | Actual UMat destination unmasked/masked Copy_To and masked Set_To; mirror Mat profiles, all four. No mapping/host staging/mixed operands/reshape/DFT/DCT/GPU promise. Test fresh-mask zeroing vs reused preservation, nonzero masks, ROI/disjoint/exact aliases, reject partial overlap/temporary output, rebind/retained parent, ABI failures, OpenCL-disabled and available smoke. |
| CORE-OPT-04 | File append then Base64 in separate small PRs, all four, only for real model/calibration/log consumers. Strong options, limited owner/copied reads, reject native MEMORY+APPEND. Test existing/new files, documented duplicate keys, malformed input/close errors, XML/YAML/JSON/Mat, NUL/integer limits; gzip qualification not assumed. |

Quaternion/affine utilities and OpenCV 5 new types remain optional, not new ready
implementation tasks without consumers/conventions. UMat reshape/transforms,
spectral division, sparse extra arithmetic, gzip, async and direct UMat mapping
remain research. Excluded escaping FileNodes, sparse min-max shifts, device
parity and C++ syntax parity are not silently added to the queue. The
[provenance](core-audit-provenance.md) preserves the separate unfinished audit.