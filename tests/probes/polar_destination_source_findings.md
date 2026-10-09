# Task 054: paired polar destinations

## Exact sources

Reconfirmed using `git ls-remote` peeled tags and the local source checkout
HEADs (not moving upstream branches):

| Tag | Peeled commit |
| --- | --- |
| 4.1.0 | 371bba8f54560b374fbcd47e7e02f015ac4969ad |
| 4.6.0 | b0dc474160e389b9c9045da5db49d03ae17c6a6b |
| 4.10.0 | 71d3237a093b60a27601c20e9ee6c3e52154e8b1 |
| 5.0.0 | 40738fb16ceddb5fb3fea747585f7ce6abb0605b |

Source links use `https://github.com/opencv/opencv/blob/<commit>/` followed
by the paths below. Installed host declarations in `opencv2/core.hpp`,
`polarToCart` and `cartToPolar`, confirm InputArray/two OutputArray signatures.

## Dispatch and output creation

`modules/core/src/mathfuncs.cpp`:

* 4.1: cartToPolar 267-313 obtains source Mat headers, validates the native
  float pair, creates Magnitude then Angle (278-279), then obtains output
  headers. HAL magnitude is followed by fastAtan within the single transform.
  There is no exact-output identity guard. Replacing a source with the first
  result can destroy values needed by the subsequent angle calculation.
* 4.6: cartToPolar 268 and polarToCart 565 both assert every exact source/output
  identity is different (273-274 and 570-571). They do not provide the newer
  identical-output assertion. Polar creation 581-582 follows Angle, not Mag.
* 4.10: cartToPolar 278-324 rejects identical outputs at 283; dispatch now uses
  combined cartToPolar HAL. polarToCart 584-711 rejects identical outputs at
  588, identifies exact in-place sources, disables IPP for in-place execution,
  and uses buffers for that case. Output creation remains first then second.
* 5.0: cartToPolar 280-326 and polarToCart 383-433 reject identical outputs
  (285/388); both use combined HAL dispatch and retain Angle-authoritative
  polar output creation (398-399). OpenCL uses explicit source/destination
  identity macros as in 4.10 rather than the 4.6 prohibition.

`mathfuncs_core.dispatch.cpp` routes 4.1/4.6 magnitude/fastAtan to HAL,
optional IPP, then CPU dispatch. 4.10 adds combined cartToPolar HAL dispatch.
5.0 also moves polarToCart into combined HAL/CPU dispatch.
`mathfuncs_core.simd.hpp` implements the approximate fast-angle polynomial,
SIMD/scalar square roots, combined transforms, and (5.0) sine/cosine kernels.
In particular 5.0 `cartToPolar64f` (161-180) narrows blocks to Float32 before
the combined kernel and widens both results. This native precision difference
is preserved rather than replaced with independent Float64 operations.
The legacy `SinCos_32f` and IPP polar implementation live in mathfuncs.cpp.
The 4.6 IPP adapter (507-562) invokes ippsPolarToCart_32f/64f by row for 2-D
or NAryMatIterator plane for N-D, returning false on IPP failure. Container
4.1/4.6 builds disable IPP; no universal IPP-specific result is promised.
No binding-side numerical normalization or independent transforms are used.

`opencl/arithm.cl`, OP_CTP_AD/AR and OP_PTC_AD/AR, calculates both outputs in
one kernel. 4.10/5.0 add SRC1/SRC2_IS_DST macros. `ocl_cartToPolar` creates
both outputs before kernel arguments; `ocl_polarToCart` requires nonempty
Magnitude and <=2-D Angle at dispatch. CPU N-D iteration remains available.
Requested OpenCL is not proof of a successful kernel or GPU execution.

## Storage and empties

`matrix_wrap.cpp`, `_OutputArray::create`, forwards mutable Mat/UMat creation
to the existing object. `matrix.cpp`, `Mat::create`, and `umatrix.cpp`,
`UMat::create`, return for existing compatible storage/shape/type. Otherwise
they release and reconstruct only that output header. On 4.1 these are
matrix.cpp 318-375 and umatrix.cpp 403-461; the same logic persists in newer
versions, including 5.0 matrix.cpp 1085 and umatrix.cpp 601. This permits
compatible non-contiguous Regions without preallocation in the binding.
Creation is sequential, not transactional: exceptions after native dispatch
do not imply rollback of two outputs.

`UMat::getMat` returns a default empty Mat for storage-free UMat; thus a
test transfer is not a valid typed-empty UMat metadata observer. The existing
empty UMat helper reconstruction is preserved, not generalized. Mat empty
output metadata follows native create/release rather than a new policy.

Legacy Float64 unit magnitude: 4.1/4.6 `polarToCart` converts angles into
Float32 buffers then incorrectly memcpy's float bytes to double outputs
(4.6 652-653), leaving partially uninitialized results. 4.10 696-700 uses
numeric conversion; 5.0 HAL is corrected. The unchanged production helper
converts Angle to native Float32, performs one polar transform, and converts
each result into the caller's Float64 destination on pre-4.10. No unsafe
direct-native legacy comparison is performed in the probe.

## Binding boundary

Four exports preflight nulls, 0/1 flags, identical outputs and all exact
source/output identities before any native call. Mat also preflights both
temporary external/selected capabilities. Ada independently validates these
capabilities and native identities. The guards have concrete `ABI safety:`
comments: prevent destructive source reads, two results overwriting one
native object, and capability-severing output header rebinding.
Ordinary public float/shape/channel policy remains Ada-only.

Input/input identity is permitted. Distinct overlapping shared-storage
headers and arbitrary partial Regions are unsupported. Disjoint common-Parent
output Regions are qualified by the corrective tests below. No refcount/UMatData inspection,
hidden source copies, output copies, or host staging is added.

The probe includes the production shim, exercising its actual helpers and
all four exports. It checks Float32/64 C1/C3 width 257 in radians/degrees,
Region attachment, one/both shape mismatches, typed empties, raw preflight
preservation, input/input aliases, and the legacy Float64 correction.
Special values are logged as same-build classifications and finite values,
not a universal signed-zero/NaN/infinity policy.
The public AUnit suite separately observes whole/Region attachment through
reciprocal shallow-alias writes and empty metadata through direct observers.

## Host observation

Host OpenCV 4.10.0 helper/direct-native probe passed. Strict C++17 warnings
as errors and shared-shim `--no-undefined` passed. Requested OpenCL on the
host encounters AMD runtime kernel compilation errors: its precompiled
OpenCL AST references missing `clang/17/include/opencl-c-base.h`. CPU fallback
passes; GPU execution is not verified. OpenCL-disabled tests restore prior
state even on exception.

## Corrective qualification

The corrective adds separately registered Mat/UMat common-Parent and reverse
polar reconstruction tests, plus a complete empty-input permutation test.
Production helpers, validators, exports and numerical behavior are unchanged.

* Common Parent: 5x600 storage, two 2x257 outputs at (2,1) and (300,1),
  Float32/Float64 C1/C3, radians/degrees, both transforms and angle-only.
  Every Parent element is compared to an independently constructed expected
  Parent, including all guards. Retained aliases and reciprocal writes prove
  attachment and independence. Native probes also compare original offsets,
  whole sizes and row steps. This arrangement is supported; partial overlap
  remains unsupported. The audited create/dispatch ordering described above
  does not require the two outputs to have different owning allocations.
* Selected raw outputs: actual `Mat_Select_ND_View` fixes the first dimension
  of an owning 3x5x7 Parent and retains interior 2x3 storage. Both positions of
  both exports reject compatible, shape-, depth- and channel-incompatible
  layouts with Error_Invalid_Argument. Full Parent/source/output snapshots,
  rank/shape/depth/channels, data pointers, steps and capability flags are
  preserved. `Mat_Copy` intentionally rejects temporary capabilities; a
  second independent selection retains an alias over the same storage rather
  than bypassing that restriction. Existing external/padding tests remain.
* Reverse reconstruction: positive magnitudes 0.25 through 22.25 and original
  canonical angles spanning all quadrants, width 257, two rows, all four
  float/channel formats and both units. Recovered magnitude uses relative
  tolerance 2e-6; angular wrap distance uses the existing source-backed
  0.3-degree fast-angle bound. Original values, not recovered angles, are the
  oracle. Both Cartesian coordinate metadata are checked.
* Exact alias rejection: raw tests retain source/output/Parent shallow aliases
  and deep snapshots; check all values and rank/shape/depth/channels after
  every exact identity rejection. Interior Region Parents include untouched
  guards. Input/input identity remains accepted. UMat transfers here observe
  nonempty pixel data only, not authoritative empty metadata.
* Empty permutations: Float32/64 matching typed empties, default empties,
  both directions of empty/nonempty Cartesian mismatch, mismatched empty
  channels and depths; polar default/typed Magnitude, nonempty Magnitude,
  typed/default Angle and angle-only. Empty Magnitude deliberately has an
  unrelated UInt8 C2 old layout. Fresh and reused outputs are compared with
  functions using direct Mat/UMat rank/shape/depth/channel observers. Rejected
  cases preserve recognizable outputs and aliases; successful empty results
  preserve old aliases. No new empty metadata normalization is added.
* Standalone probe: actual helpers and separate direct-native execution use
  whole outputs, independent Regions and disjoint common-Parent Regions,
  each/both shape/depth/channel mismatch and reciprocal alias writes. Every
  Parent guard is checked before and after writes. Legacy Float64 unit
  magnitude uses the safe Float32-native/conversion oracle, never the known
  uninitialized direct-native legacy path; final conversions reuse Regions.

OpenCL requested/enabled remains distinct from verified GPU execution. The
host's AMD compilation failure still causes CPU fallback; no GPU claim is made.

Final corrective qualification (same Ada/probe/shim sources as the corrective
commit; no production changes):

| Environment | Registered | Executed | Passed | Failed assertions | Errors |
| --- | ---: | ---: | ---: | ---: | ---: |
| Host 4.10.0 | 2024 | 2024 | 2024 | 0 | 0 |
| Exact 4.1.0 | 2024 | 2024 | 2024 | 0 | 0 |
| Exact 4.6.0 | 2024 | 2024 | 2024 | 0 | 0 |
| Exact 4.10.0 | 2024 | 2024 | 2024 | 0 | 0 |
| Exact 5.0.0 | 2024 | 2024 | 2024 | 0 | 0 |

All five actual-helper/direct-native probes pass, including direct-native
disjoint-Region execution and the raw selected geometry checks. Strict C++17
`-Wall -Wextra -Wpedantic -Werror`, shared-shim `--no-undefined`, Ada warnings
as errors, GNATformat, changed Ada 79-column checks and `git diff --check`
pass. GNATprove is not applicable: no SPARK-compatible computation changes.