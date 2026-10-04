# Task 042: normalization into native destinations

Starting gate: fetched `origin/main` was
`d031fbcc02c3f493adf954a18497c0d1e592c846` (the expected PR #41 merge).
Worktree was clean; `gh pr list --state open` returned no PRs. Complete host
baseline: 1632 registered / executed / passed, 0 failed assertions, 0 errors.

## Exact upstream source review

Clean local upstream checkouts were checked with `describe --exact-match` and
their HEADs against peeled tags in the OpenCV upstream repository. All paths
below are relative to `modules/core/`. These are source inspections, not just
documentation; complete normalize/conversion bodies and relevant create branches
were read, including the no-scale copy path.

| Tag | Peeled commit SHA | normalize + OpenCL normalization | norm reduction | minMax reduction |
|---|---|---|---|---|
| 4.1.0 | `371bba8f54560b374fbcd47e7e02f015ac4969ad` | src/convert_scale.dispatch.cpp:124-257 | src/norm.cpp:358-402,536-712 | src/minmax.cpp:104-116,240-350,757-828 |
| 4.6.0 | `b0dc474160e389b9c9045da5db49d03ae17c6a6b` | src/norm.cpp:1287-1419 | src/norm.cpp:418-462,597-784 | src/minmax.cpp:833-845,969-1082,1490-1561 |
| 4.10.0 | `71d3237a093b60a27601c20e9ee6c3e52154e8b1` | src/norm.cpp:1283-1415 | src/norm.cpp:424-468,603-790 | src/minmax.cpp:835-847,971-1084,1498-1591 |
| 5.0.0 | `40738fb16ceddb5fb3fea747585f7ce6abb0605b` | src/norm.dispatch.cpp:712-844 | src/norm.dispatch.cpp:226-273,286-461; src/norm.simd.hpp | src/minmax.dispatch.cpp:148-391; src/minmax.simd.hpp:368-389 |

| Tag | Mat / UMat convertTo | Mat / UMat N-D create | OutputArray create / release |
|---|---|---|---|
| 4.1.0 | src/convert.dispatch.cpp:174-225 / src/umatrix.cpp:976-1039 | src/matrix.cpp:318-375 / src/umatrix.cpp:403-461 | src/matrix_wrap.cpp:1189-1342 / 1657-1673 |
| 4.6.0 | src/convert.dispatch.cpp:174-225 / src/umatrix.cpp:1236-1299 | src/matrix.cpp:659-718 / src/umatrix.cpp:653-717 | src/matrix_wrap.cpp:1160-1339 / 1665-1681 |
| 4.10.0 | src/convert.dispatch.cpp:174-341 (shared OpenCL converter, Mat and UMat) | src/matrix.cpp:659-718 / src/umatrix.cpp:653-717 | src/matrix_wrap.cpp:1160-1339 / 1665-1681 |
| 5.0.0 | src/convert.dispatch.cpp:56-246 | src/matrix.cpp:1085-1144 / src/umatrix.cpp:601-671 | src/matrix_wrap.cpp:1466-1663 / 2042-2058 |

Declarations: `include/opencv2/core.hpp` normalize at 4.1:779-780,
4.6:794-795, 4.10:843-844, 5.0:768-769; Mat/UMat convertTo in
`include/opencv2/core/mat.hpp` at 4.1:1212-1225/2442-2443,
4.6:1234-1247/2473-2474, 4.10:1235-1248/2495-2496,
5.0:1478-1491/2847-2848.

Identity copy bodies: `src/copy.cpp` 4.1:239-322, 4.6/4.10:305-388,
5.0:441-538; `src/umatrix.cpp` 4.1:873-925, 4.6/4.10:1133-1185,
5.0:1233-1298. SIMD conversion bodies: `src/convert_scale.simd.hpp`
4.1/4.6/4.10:91-195, 5.0:71-177. OpenCL element conversion kernel:
`src/opencl/convert.cl` 4.1/4.6:54-81, 4.10/5.0:61-88.
OpenCL sum/squared-sum reductions (synchronous result before conversion):
`src/sum.dispatch.cpp` 4.1:31-120, 4.6:31-123, 4.10:33-125, 5.0:25-117.
5.0 half norm dispatch: `src/norm.simd.hpp:1936-1990`.

Authoritative exact trees:
[4.1.0](https://github.com/opencv/opencv/tree/4.1.0/modules/core),
[4.6.0](https://github.com/opencv/opencv/tree/4.6.0/modules/core),
[4.10.0](https://github.com/opencv/opencv/tree/4.10.0/modules/core),
[5.0.0](https://github.com/opencv/opencv/tree/5.0.0/modules/core).

## Semantics, reuse, aliasing, and dimensions

Every tag first computes the entire norm/minmax, then converts with scalar
scale and shift. L1/L2/Infinity use `alpha/norm` if norm exceeds DBL_EPSILON,
otherwise zero scale; beta is ignored. Min_Max sorts alpha/beta with MIN/MAX,
uses zero scale for source range <= DBL_EPSILON, and shifts to the lower bound.
Thus alpha > beta is not a reversed mapping; equal bounds give a constant;
constant input maps to min(alpha,beta). Float32 coefficients are narrowed by
native normalization, and integer results use native saturate_cast/rounding.

The unmasked OpenCL normalization branch calls UMat convertTo on the actual
OutputArray, not normalizek. The fallback obtains native Mat and invokes Mat
convertTo. This is OpenCV's internal mapping, not a binding transfer. Conversion
uses source depth and channel count, not the current mutable destination type.
Matching create returns without allocation, including strided interior Regions;
offsets/strides remain native. Mismatches release/recreate the destination header,
detaching Regions while old aliases keep the parent allocation alive.

Exact self and distinct shallow headers with identical storage/layout are
supported: reductions complete before writes; normalize retains a source
Mat/UMat before conversion; conversion also retains source before create. SIMD
tails avoid reprocessing pixels when source/destination addresses coincide.
OpenCL conversion reads each element before writing its corresponding element;
the norm reduction completes before that conversion is enqueued. Identity
conversion delegates to copyTo, whose matching-storage path is a no-op.
The isolated CPU probe found zero difference from independent results for all
four kinds, Mat/UMat, 257 elements, on every exact tag. No arbitrary partially
overlapping Regions are promised; copyTo explicitly excludes partial overlap.

Norm and minMaxIdx use NAryMatIterator for N-D fallback. Unmasked minMaxIdx allows
multichannel input when location pointers are absent, as normalize uses it;
there is no 2-D or C1 restriction here. OpenCL reduction/conversion generally
gates dimensions <=2; N-D falls back inside OpenCV. Focused AUnit checks real
2x3x4 reuse and every numerical value for Infinity and Min_Max, plus C3 global
normalization. This is not the 2-D minMaxLoc API.

## Empty behavior and unchanged dense_normalize compatibility

The destination exports call the existing `dense_normalize` directly with the
actual caller destination. Its code is unchanged. UMat empty non-half input,
and empty half norm-family input, release the output before entering native
OpenCL reduction; empty half Min_Max deliberately remains native/version-specific.
This must not be inferred from an unguarded cv::normalize UMat probe.

Native UMat getMat returns default Mat for no storage:
`src/umatrix.cpp` 4.1:816-819, 4.6/4.10:1071-1074, 5.0:1171-1174.
OpenCL vector selection filters empty inputs then dereferences min_element:
`src/ocl.cpp` 4.1:6288-6317, 4.6:7248-7277, 4.10:7266-7295,
5.0:7249-7278. The original safety workaround is retained exactly.

For binding-created default/typed 0x0 sources and a preallocated destination:

| Source/kind | 4.1 / 4.6 / 4.10 | 5.0 |
|---|---|---|
| Mat default / all kinds | released pixels, 0x0, old destination type retained | recreated empty UInt8 C1 |
| Mat typed Float32 C3 / all kinds | released pixels, old destination type retained | recreated empty Float32 C3 |
| UMat default or non-half typed / all kinds | helper release, old destination type retained | helper release, old destination type retained |
| Mat empty half / norm kinds | native release, old destination type retained | native recreate, source half type |
| UMat empty half / norm kinds | helper release, old destination type retained | helper release, old destination type retained |
| Mat empty half / Min_Max | OpenCV_Error (null half minmax dispatch) | succeeds, recreated empty half type |
| UMat empty half / Min_Max, CPU | OpenCV_Error before conversion (input half dispatch) | succeeds; mapping loses empty type, conversion recreates half C1 |

Geometry details remain native (release metadata differs, including native
dimension counts). In 5.0, UMat helper release sets dims=0, giving a null public
Shape, unlike the 4.x retained two zero extents. Empty half Min_Max CPU conversion
recreates two zero extents even on 5.0. The probe also uses typed 0x3: 5.0 Mat
retains 0x3, while
4.x release gives 0x0. AUnit pins binding-created 0x0 metadata, type, channels,
and survival of the old destination alias. Return-value functions start with
fresh destinations, so released metadata need not equal preallocated metadata.
No new cross-version empty metadata policy is imposed.

## Float16 audit (CPU, source [3,4], alpha=10, beta=2)

`normalize_destination_probe.cpp` compiled with C++17 and all requested warnings
as errors in each exact image, OpenCL explicitly disabled for native empty safety.

| Kind | 4.1.0 | 4.6.0 | 4.10.0 | 5.0.0 |
|---|---|---|---|---|
| L1 | [4.28515625,5.71484375] | same | same | same |
| L2 | [6,8] | same | same | same |
| Infinity | [0,5.96046448e-8] | [0,0] | [7.5,10] | [7.5,10] |
| Min_Max | error -215 | error -215 | error -215 | [2,10] |

Old half Infinity reduction reads the wrong accumulator representation:
4.1 `norm.cpp:683-707`, 4.6:743-777; 4.10:749-783 uses result.f correctly.
4.x minmax half table entries are null; 5.0 supplies half dispatch. Half L1/L2
are internally widened by native reductions, not by this binding. 4.1 half
multichannel reduction has additional block/channel defects; no new guarantee
is made or workaround added. Backend/precision can vary. Public half tests
compare procedure results and errors with the existing function for every kind,
and use explicit CPU isolation with test-only controls restored on exceptions.
Do not assert mathematically correct Infinity on old releases or add widening.

The host AMD OpenCL compiler emitted missing-header AST diagnostics; OpenCV
normally fell back. An unisolated empty-half UMat test terminated in native
execution. Empty half Min_Max remains intentionally native; its tests/probes
run with OpenCL disabled, not with a new production workaround. Usable GPU
execution is not claimed by this CPU compatibility matrix/source review.

## ABI safety, failure boundary, and residency review

Both exports reject null source/destination and invalid raw kind representations
before native mutation. Numerical policy is not revalidated. The Mat destination
capability guard is repeated independently in Ada (`Temporary_View`) and C++
(`temporary_external_view`), including presently compatible views: releasing or
rebinding would sever the callback-scoped logical capability over caller or
selected storage. Its `ABI safety:` comment names that failure mode. Temporary
sources remain allowed; tests cover strided external padding and selected views.

Those pre-native validation failures preserve geometry/type/pixels/padding.
After dense_normalize starts, native errors are translated but arbitrary failure
atomicity is not guaranteed. No ownership/header replacement is added.

Production additions contain no To_Mat/To_UMat, getMat, ACCESS_READ/WRITE,
host staging, or intermediate normalized matrix. UMat source and destination
values flow directly to dense_normalize. OpenCV chooses OpenCL/fallback;
neither GPU execution nor absence of native internal mapping is guaranteed.

The only repeated public condition added is temporary Mat destination rejection,
justified above by ABI capability safety. Null checks and raw kind mapping are
pointer/representation safety. No shape/type/channel/empty/numeric/overlap policy
is duplicated in the new exports. The original empty compatibility guard remains
unchanged. No SPARK-compatible computation changes; these are controlled-wrapper
foreign calls and a Boolean capability check, with no new formal-proof claim.