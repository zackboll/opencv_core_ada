# Numerical norms and binary distances — CORE-FIN-02

This additive API uses native `cv::norm` without difference Mats, saturated
subtraction, automatic conversion, or squaring the existing Ada L2 result.
Version remains **0.5.2**. Existing `Norm`, `Norm_Kind`, `Batch_Distance_Kind`,
defaults, named parameters, and Float16 behavior are unchanged.

## Public profiles

```ada
type Binary_Norm_Kind is (One_Bit, Two_Bits);

function Difference_Norm
  (Left, Right : Mat;
   Kind        : Norm_Kind := L2;
   Relative    : Boolean := False) return Long_Float;
function Difference_Norm
  (Left, Right : Mat;
   Mask        : Mat;
   Kind        : Norm_Kind := L2;
   Relative    : Boolean := False) return Long_Float;
function Squared_L2_Norm (Self : Mat) return Long_Float;
function Squared_L2_Norm (Self, Mask : Mat) return Long_Float;
function Squared_L2_Difference_Norm (Left, Right : Mat) return Long_Float;
function Squared_L2_Difference_Norm (Left, Right, Mask : Mat) return Long_Float;
function Hamming_Norm
  (Self : Mat; Kind : Binary_Norm_Kind := One_Bit) return Long_Float;
function Hamming_Pairwise_Norm
  (Left, Right : Mat;
   Kind        : Binary_Norm_Kind := One_Bit) return Long_Float;
```

**Naming decision:** use `Hamming_Pairwise_Norm`, not a new function named
`Hamming_Distance`. The latter is already a `Batch_Distance_Kind` enumeration
literal. This avoids adding any overload-resolution burden to existing
consumers. Tests compile and execute the existing named-parameter
`K_Nearest_Neighbors (..., Kind => Hamming_Distance)` pattern.

## Numeric contract

New numeric operations accept UInt8, Int8, UInt16, Int16, Float32 and Float64.
Pairwise inputs require identical native rank, every extent, depth and channel
count. All channels participate in one reduction. Matching N-D, noncontiguous
ROIs and borrowed strided views are supported without copying storage.

**Int32 and Float16 are rejected**, even for empty inputs. OpenCV 4.1 can
subtract Int32 extrema before widening; portable Float16 kernel safety is not
established. Explicit caller conversion is supported:
`Difference_Norm (Left.Convert_To (Float64), Right.Convert_To (Float64))`.

Numeric masks must be UInt8 C1 with the operand's complete native shape.
Every nonzero byte selects the entire logical element and all its channels.
Values 1, 2, 127 and 255 are equivalent selectors, not weights. All-zero masks
give zero for absolute norms of finite input. Relative empty selection is
backend-defined: OpenCV 5.0 with IPP 2026.0 returns NaN for C1 UInt8, UInt16,
and Float32 L1/L2/Infinity; disabling IPP gives zero through the generic
epsilon path. C2..C4 and the other supported depths use the finite generic
result in the tested configuration. The binding preserves native classification,
without forcing zero or rejecting NaN. These masks are **not binary bit masks**.

Relative L1/L2/Infinity passes `NORM_RELATIVE` to the native two-input overload.
The generic implementation uses `norm(Left,Right)/(norm(Right)+DBL_EPSILON)`;
zero or near-zero Right is not an Ada divide-by-zero error. IPP can handle
relative calls before the generic fallback, so backend behavior remains native.
Relative squared L2 and relative binary distance are intentionally absent.

Float32 intermediates may round or overflow before the C double result, and
backend reductions may differ. NaN/Infinity behavior, including native maximum
handling of NaNs, is preserved rather than normalized. No cross-version
bit-identical floating result or NaN-payload preservation is promised.

## Binary contract and count safety

Binary operations require UInt8 with exactly one channel. `One_Bit` counts
set/differing bits. `Two_Bits` counts nonzero adjacent two-bit cells in the
byte/XOR: `11` against `00` has bit distance 2 and cell distance 1. Hamming2 is
not Hamming divided by two. No implicit byte conversion, masks, or approximate
binary implementation is provided.

Checked preflight products impose these conservative native signed-int bounds:

| Operation | Limit |
| --- | --- |
| New numeric operations | `Total * Channels <= INT32_MAX/8 = 268435455` |
| One-bit binary | `Total bytes <= INT32_MAX/8 = 268435455` |
| Two-bit binary | `Total bytes <= INT32_MAX/4 = 536870911` |

Products are checked by division before multiplication. Counts include all
planes. Native byte strides must fit INT32_MAX because IPP narrows strides
before storage access; a small logical count does not imply a small stride.
There is no huge-allocation test: bounded synthetic native headers exercise
the preflight, including channel products. OpenCV 5 fixtures synchronize
`size[]` and legacy `rows/cols` explicitly.

Type/complete-shape/mask validation occurs before empty handling. Compatible
default-empty and typed-empty inputs return zero. Default headers do not become
compatible with typed zero-extent headers just because both have zero elements.
Incompatible types/shapes are rejected even when empty. Inputs and aliases are
not modified; borrowed views are consumed only within their existing callback
lifetime (they still cannot escape through shallow copying).

Invalid public arguments, unsafe counts/strides and translated native failures
raise `OpenCV_Error`. Nonfinite results are not reclassified as input failures.
As elsewhere in the API, unrelated Ada allocation/runtime failures are not
converted into native status codes.

## ABI and validation ownership

Four new entry points use borrowed Mat handles and `double *` output:
`opencv_core_mat_numeric_norm`, `opencv_core_mat_difference_norm`,
`opencv_core_mat_binary_norm`, `opencv_core_mat_binary_difference_norm`.
New numeric selector values 1/2/3/4 map to L1/L2/INF/L2SQR; unary accepts 4.
Relative is int32 0/1 and only allowed for pairwise selectors 1..3. Binary cell
selector is int32 1/2. A null numeric mask means no mask, not a missing source.
Existing norm selectors and symbols are unchanged. Writable outputs are zeroed
before validation and stay zero on failure; errors use existing status and
thread-local diagnostics. C++ exceptions remain contained.

Ada owns public type/shape/mask policy. Retained duplicated conditions have
specific `ABI safety:` comments:

* Count/channel products: native signed int lengths and accumulation bounds.
* Strides: native IPP narrowing before storage access.
* Float16: legacy undersized multichannel conversion buffers.
* Pairwise Int32: native subtraction before widening. Unary Int32 is rejected
  only in Ada, not by a second shim semantic policy.
* Mask shape/type: OpenCV 5 HAL dispatch precedes generic mask validation and
  can access mask bytes using source extents.
* Empty-input type/shape checks: avoid returning a successful zero for headers
  that native validation would reject, while keeping null empty storage out of
  vendor kernels. General nonempty pairwise rejection is left to OpenCV.

The [pinned source findings](../tests/probes/numerical_norms_source_findings.md)
record commits, files, line ranges, backend behavior and arithmetic reasoning.

## Example and qualification

The compiled [Ada example](../tests/probes/numerical_norms_example.adb)
demonstrates a numerical residual and descriptor bit/cell distance:

```sh
alr -C tests exec -- gprbuild -P probes/numerical_norms_example.gpr -p
tests/probes/bin-numerical-example/numerical_norms_example
sh scripts/run_numerical_norms_probes.sh
```

The focused AUnit package adds **15 registrations**, for **2037 + 15 = 2052**.
It includes native-oracle comparisons, six depths, extrema, masks, N-D/ROI/
strided views, empty/negative contracts, aliases/repetition, explicit Int32
conversion, binary patterns and nonfinite parity. Standalone controls include
the actual production shim under ASan/UBSan and compare direct native results;
they do not claim system OpenCV is sanitizer-instrumented.

Implementation is not a release or a qualification waiver. Final exact-head
hosted evidence and any unavailable proprietary-target limitations are reported
in the feature PR. Broader stale roadmap/audit planning statuses remain a
separate cleanup task; forensic artifacts and PR #91 are not rewritten here.