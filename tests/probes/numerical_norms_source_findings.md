# CORE-FIN-02 native source review

Starting main: `aa8a378ab614e9a5fc4f43765cd3ff1bbcf6a44d` (0.5.2).
References below are immutable OpenCV Git commits; line numbers are one-based.
This is feature-local evidence, not a modification of the forensic audit.

| Release | Commit | Public declarations (`modules/core/include/opencv2/core.hpp`) | Implementation |
| --- | --- | --- | --- |
| 4.1.0 | `371bba8f54560b374fbcd47e7e02f015ac4969ad` | 632–682 | `modules/core/src/norm.cpp`: kernels 152–353; unary 536–712; pairwise 1014–1192 |
| 4.6.0 | `b0dc474160e389b9c9045da5db49d03ae17c6a6b` | 647–697 | `modules/core/src/norm.cpp`: kernels 212–410; unary 597–785; pairwise 1077–1276 |
| 4.10.0 | `71d3237a093b60a27601c20e9ee6c3e52154e8b1` | 696–746 | `modules/core/src/norm.cpp`: Hamming HAL 53–150; pairwise 1073–1263; generic block reduction 1191–1247 |
| 5.0.0 | `40738fb16ceddb5fb3fea747585f7ce6abb0605b` | 616–666 | `modules/core/src/norm.dispatch.cpp`: unary 286–426; pairwise 521–685; `norm.simd.hpp`: kernels 1694–1854, depth tables 1923–2045 |

All implementation paths are relative to the OpenCV repository. Reproducible
inspection: `git show <commit>:<path> | nl -ba`. The 5.0 implementation is
`norm.dispatch.cpp`, not the historical `norm.cpp`.

## Numeric reduction and layout

All six selected depths have unary and difference kernel table entries. Native
L2SQR selects the L2 sum kernel without the final square root. The binding must
pass `NORM_L2SQR`, not square its existing `Norm` result. The native IPP backend
may itself square an IPP L2 result; that is native behavior, not a binding
fallback (4.1 `norm.cpp` 994–999; 5.0 `hal/ipp/src/norm_ipp.cpp` 338–345).

Unmasked generic kernels reduce `len * cn` scalar components; masked kernels
test `mask[i] != 0` and iterate all `cn` channels, without scaling by mask value.
`NAryMatIterator` splits matching N-D/noncontiguous storage into planes. No
continuous-storage requirement or temporary difference image is needed.

4.1 `norm.cpp` 218–279 and `core/base.hpp` 450–496 subtract integer operands
before widening. UInt8/Int8/UInt16/Int16 differences fit native int; opposite
Int32 extrema do not. Int32 is excluded even for unary additions to keep one
portable numeric contract. Float16 is excluded: 4.1 conversion buffers and
counts at `norm.cpp` 663–686 and 1138–1165 do not establish safe multichannel
support. The existing Norm and its version-specific Float16 path are unchanged.

## Relative and floating behavior

Generic relative calls divide native two-input norm by the native **Right**
unary norm plus `DBL_EPSILON`: 4.1 `norm.cpp` 1032–1034; 4.6 1096–1098;
4.10 1092–1094; 5.0 `norm.dispatch.cpp` 551–553. Zero and near-zero references
are not Ada divide-by-zero errors. IPP relative dispatch precedes this fallback
(4.1 791–876; 4.6 1094; 4.10 1090; 5.0
`hal/ipp/src/norm_ipp.cpp` 132–226). Do not replace native backend results by an
Ada formula or promise identical backend rounding/epsilon handling.

Float32 differences, SIMD operations, multiplication and intermediate sums may
round in Float32 even though the public result is double. Infinity reductions
use native maximum operations; NaNs need not propagate like a sum. Nonfinite
results must be compared to direct native results by classification, not
rejected or normalized by the binding. Finite inputs can overflow floating
intermediates. C double to Long_Float is the only result conversion.

## Count and ABI safety

Generic lengths, `len*cn`, loop increments, IPP widths, and Hamming results use
signed int. Use a conservative common numeric bound of `INT32_MAX / 8` scalar
components, checking products by division before multiplication. This leaves
headroom for loop increments and byte-width products through Float64, bounds
every iterator plane, and prevents unsafe narrowing of N-D totals. Integer
numeric accumulation is native-blocked: at most 2^23 scalar components for
8-bit L1, or 2^15 for 16-bit L1 and 8-bit squared L2 (4.1 650–692,
1125–1169; 4.6/4.10 block reductions; 5.0 633–665). Worst-case sums are
2^23*255 and 2^15*65535 or 2^15*255^2, all below INT32_MAX. Public channel
limits are below the smallest native block size, so block sizes stay positive.

Hamming/Hamming2 use signed int per-plane and whole-array accumulators:
4.1 `norm.cpp` 53–94, 620–633, 1094–1107; 4.6 53–142;
4.10 53–147; 5.0 `norm.dispatch.cpp` 53–147, 592–614.
One-bit mode admits at most `INT32_MAX/8` bytes; two-bit mode at most
`INT32_MAX/4` bytes. Counts include all planes, not just the largest plane.
The two-bit table/SIMD collapses adjacent bit pairs, not the final bit count.

One-bit HAL dispatch is in each release's `modules/core/src/stat.dispatch.cpp`
and `stat.simd.hpp` (4.1 29–174; 5.0 29–125). SIMD sums remain bounded by the
whole result. 4.1 POPCNT fallback uses typed unaligned loads (63–68, 132–137);
5.0 uses memcpy (49–60, 97–110). This is upstream backend behavior; actual
shim sanitizers do not instrument system OpenCV. Binary ROI parity must exercise
unaligned storage, with no claim of sanitizing the native library itself.

IPP narrows row strides to int: 4.1 `norm.cpp` 413–485, 825, 866–867,
995–996; 5.0 `hal/ipp/src/norm_ipp.cpp` 42, 68–70, 119, 166, 217–218,
257, 283–285, 341–342. The shim must reject strides above INT32_MAX before
native execution, including externally borrowed strided views. A logical count
bound alone does not bound row stride. This check is ABI safety, not a semantic
requirement that input storage be continuous.

5.0 HAL norm dispatch occurs before generic mask validation (unary 307–315,
pairwise 540–548). Raw mask shape/type checks therefore protect against vendor
HAL out-of-bounds reads. This is a justified duplicate of Ada mask validation.
Pairwise input shape/type is checked by OpenCV before HAL dispatch (525–526).
Synthetic count fixtures must update both `cols` and `size[1]`: OpenCV 5 keeps
these separately. An early fixture changed only `cols`; the resulting
contradictory header bypassed the intended size-based preflight and crashed in
Hamming. GDB established this as a test-fixture defect, not a valid-input
OpenCV defect. No extra binary semantic guard is justified by that failure.

## Backend scope

These entry points pass Mat, not UMat: the OpenCL predicates require UMat
(4.1 unary 550 and pairwise 1025; 4.6 pairwise 1089; 4.10 pairwise 1085;
5.0 unary 300 and pairwise 533), so they do not stage a GPU reduction.
4.1/4.6/4.10 numeric kernels and the stat Hamming dispatch use the compiled CPU
optimization variants; no Ada SIMD algorithm replaces them. 5.0 splits numeric
SIMD dispatch into `norm.simd.hpp` and `norm.dispatch.cpp` 277–284.
5.0 IPP dispatch is the HAL adapter `hal/ipp/src/norm_ipp.cpp` 12–129 and
132–352, enabled through `hal/ipp/include/ipp_hal_core.hpp` 35–46. The generic
HAL stubs in `modules/core/src/hal_replacement.hpp` return NOT_IMPLEMENTED;
compiled vendor replacements remain part of native OpenCV's build contract.
RISC-V RVV adapters are not used by the qualified x86_64/ARM64 platforms and
are not claimed as independently qualified targets by this feature.

## Empty inputs and qualification boundary

Validate types, complete native rank/extents, and mask before handling emptiness.
Compatible default-empty and typed-empty inputs reduce to zero; incompatible
empty headers are not made compatible merely because their counts are zero.
Empty native kernels/backends can receive null data, so the new shim returns
zero after validation rather than forwarding null storage to a vendor kernel.
This is not an alteration of existing Norm behavior.

This review establishes a bounded implementation strategy, **not completed
four-version qualification**. Native references, raw controls, AUnit, sanitizers,
platform checks and exact-head evidence are separate required gates.