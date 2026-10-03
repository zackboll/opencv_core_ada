# Task 040: retained ROI geometry and header adjustment

## Exact sources inspected

All declarations and both implementations were read, not just documentation.
Paths relative to each upstream tag are `modules/core/include/opencv2/core/mat.hpp`,
`modules/core/src/matrix.cpp`, and `modules/core/src/umatrix.cpp`.

| Tag / peeled commit | Mat declaration / implementation | UMat declaration / implementation |
|---|---|---|
| 4.1.0 / `371bba8f54560b374fbcd47e7e02f015ac4969ad` | mat.hpp:1569-1609 / matrix.cpp:755-794 | mat.hpp:2494-2497 / umatrix.cpp:643-683 |
| 4.10.0 / `71d3237a093b60a27601c20e9ee6c3e52154e8b1` | mat.hpp:1613-1653 / matrix.cpp:1097-1136 | mat.hpp:2555-2558 / umatrix.cpp:898-938 |
| 5.0.0 / `40738fb16ceddb5fb3fea747585f7ce6abb0605b` | mat.hpp:1959-1999 / matrix.cpp:1631-1676 | mat.hpp:2916-2919 / umatrix.cpp:932-972 |

Authoritative files: [4.1](https://github.com/opencv/opencv/tree/4.1.0/modules/core),
[4.10](https://github.com/opencv/opencv/tree/4.10.0/modules/core),
[5.0](https://github.com/opencv/opencv/tree/5.0.0/modules/core).

The corrective additionally inspected the complete `Mat::adjustROI` bodies and
`MatStep` declarations at these exact tags. The displacement lines below are
in `modules/core/src/matrix.cpp`:

| Tag / peeled commit | adjustROI body | Displacement line |
|---|---|---|
| 4.1.0 / `371bba8f54560b374fbcd47e7e02f015ac4969ad` | 776-794 | 789 |
| 4.6.0 / `b0dc474160e389b9c9045da5db49d03ae17c6a6b` | 1118-1136 | 1131 |
| 4.7.0 / `725e440d278aca07d35a5e8963ef990572b07316` | 1118-1136 | 1131 |
| 4.8.0 / `f9a59f2592993d3dcc080e495f4f5e02dd8ec7ef` | 1118-1136 | 1131 |
| 4.9.0 / `dad8af6b17f8e60d7b95a1203a1b4d22f56574cf` | 1118-1136 | 1131 |
| 4.10.0 / `71d3237a093b60a27601c20e9ee6c3e52154e8b1` | 1118-1136 | 1131 |
| 5.0.0 / `40738fb16ceddb5fb3fea747585f7ce6abb0605b` | 1652-1676 | 1670 (2-D) |

## Per-version findings

**4.1 Mat:** both operations assert `dims <= 2 && step[0] > 0`.
Locate subtracts `data - datastart` and `dataend - datastart`. It derives Y
from the first delta divided by row step, and X from the remainder divided
by **complete element size**, not scalar-channel size. Whole height is
`max((delta2 - (ofs.x + cols)*esz)/step[0] + 1, ofs.y + rows)`;
whole width is `max((delta2 - step*(height-1))/esz, ofs.x + cols)`.
The retained `datastart`/`dataend` survive ordinary shallow copying, so nested
Regions refer to the original allocation, not their immediate parent header.
Adjust clamps four boundary expressions, swaps crossed endpoints, modifies
`data`, rows/cols/size, and calls `updateContinuityFlag`. Its pointer displacement
uses unsafe unsigned size arithmetic for negative movement before 4.9; see the
compatibility correction below.

**4.10 Mat:** the same location formulas, assertions, clipping, swapping, and
flags apply. Pointer displacement explicitly casts row step and element size
to `std::ptrdiff_t`, unlike 4.1.

**5.0 Mat:** locate retains the same `dims <= 2` assertion and formulas.
Adjust also asserts `dims <= 2`, but adds a separate `dims == 1` branch that
only changes columns/size[0] and does not update continuity. The exactly-2-D
path is otherwise the 4.10 path. The binding deliberately excludes 1-D.

**4.1 UMat:** location asserts `dims <= 2 && step[0] > 0`, and uses
`(ptrdiff_t)offset` and **`(ptrdiff_t)u->size`** as its two deltas, not Mat
pointers. The remainder of the formulas matches Mat. Adjust uses identical
clamped/swapped boundary expressions, updates unsigned byte `offset` instead
of `data`, then rows/cols/size and continuity. Neither operation maps storage.

**4.10 UMat:** both implementations are equivalent to 4.1 for this feature;
the unsigned offset displacement remains, unlike Mat's ptrdiff_t change.

**5.0 UMat:** locate still asserts `dims <= 2`; **adjust asserts `dims == 2`**.
The 2-D formulas, unsigned offset update, clipping, swapping, and continuity
are unchanged. This confirms that 5.0 must not be inferred from 4.x.

## Pre-4.9 Mat pointer compatibility correction

Exact source in **4.1.0, 4.6.0, 4.7.0, and 4.8.0**, respectively at
[789](https://github.com/opencv/opencv/blob/4.1.0/modules/core/src/matrix.cpp#L789),
[1131](https://github.com/opencv/opencv/blob/4.6.0/modules/core/src/matrix.cpp#L1131),
[1131](https://github.com/opencv/opencv/blob/4.7.0/modules/core/src/matrix.cpp#L1131),
and [1131](https://github.com/opencv/opencv/blob/4.8.0/modules/core/src/matrix.cpp#L1131):

```cpp
data += (row1 - ofs.y)*step + (col1 - ofs.x)*esz;
```

`esz` is declared `size_t esz = elemSize();`; `step` is `MatStep`, whose
conversion operator returns `size_t` and whose indexed entries are `size_t`.
A valid top/left expansion makes one or both signed deltas negative. The usual
arithmetic conversions turn them into unsigned values before multiplication.
Unsigned multiplication/addition wrap modulo the unsigned range, but adding the
resulting huge unsigned displacement to a native pointer is not portable, safe
C++ pointer arithmetic, even when the intended earlier address is in bounds.
Current compilers/platforms commonly wrap address calculations to that intended
address, so existing tests can pass despite this latent source defect. No
upstream crash was observed or is claimed: this is a
**portability/native-pointer-safety correction**.

**4.9.0 is the compatibility boundary.** Its
[line 1131](https://github.com/opencv/opencv/blob/4.9.0/modules/core/src/matrix.cpp#L1131)
introduces the signed casts:

```cpp
data += (row1 - ofs.y)*(std::ptrdiff_t)step + (col1 - ofs.x)*(std::ptrdiff_t)esz;
```

4.10.0 retains this exact line; 5.0.0 retains it in the 2-D branch. Therefore only
`CV_VERSION_MAJOR == 4 && CV_VERSION_MINOR < 9` bypasses native Mat adjustment.
All other supported versions still call `candidate.adjustROI(...)` unchanged.
Neither Mat nor UMat location is replaced.

The private `adjust_mat_roi_legacy_safe` helper calls `candidate.locateROI` and
preserves the native 4.x algorithm exactly apart from signed displacement:

```cpp
row1 = min(max(ofs.y - top, 0), whole.height);
row2 = max(0, min(ofs.y + rows + bottom, whole.height));
col1 = min(max(ofs.x - left, 0), whole.width);
col2 = max(0, min(ofs.x + cols + right, whole.width));
if (row1 > row2) swap(row1, row2);
if (col1 > col2) swap(col1, col2);
candidate.data +=
    (row1 - ofs.y) * static_cast<std::ptrdiff_t>(candidate.step[0])
    + (col1 - ofs.x) * static_cast<std::ptrdiff_t>(candidate.elemSize());
```

It updates rows, cols, size.p[0], size.p[1], then calls
`candidate.updateContinuityFlag()`. It does not modify SUBMATRIX_FLAG, datastart,
dataend, datalimit, or u, and does not clone pixel storage. Existing native-storage,
exact-2-D, parent-span, signed-expression, and final-pointer preflights remain
unchanged; the helper assumes they succeeded and adds no validation or limits.
For these retained allocations, row step and element size fit the allocation;
the already bounded allocation span makes their ptrdiff_t conversions and the
signed displacement representable. No speculative conversion restriction is
needed. `cv::Mat candidate = self->value` retains shared storage, and only a
successful adjustment publishes `self->value = std::move(candidate)`.

**UMat does not use this helper.** Its `offset += ...` updates an unsigned integer
byte offset, not a native pointer. That modular integer representation is distinct
from the old Mat pointer defect. The production UMat candidate/native adjustROI
path remains unchanged, with no getMat, To_Mat, To_UMat, or host mapping.

## Shared behavior and native arithmetic

Default empties are not safe inputs: Mat pointer subtraction on null storage
must not be relied upon, and UMat location dereferences `u->size` (typed
empty headers can have a positive step but null `u`). The binding rejects
all empties, including typed 0x0 and headers made empty by adjustment.
Public and raw paths require exactly two dimensions. No depth/channel policy
is imposed; tests cover every supported depth with C1, C3, and C128.
Exact 5.0 `hal/interface.h:50` defines CV_CN_MAX as 128, unlike 4.x's 512;
the portable test samples therefore stop at 128 without restricting ROI policy.

Positive top/left subtract from the starting offset (outward); positive
bottom/right add to the ending offset. Negative values contract. Each endpoint
is clamped independently to [0, whole extent], then reversed endpoints are
**swapped**, in every inspected implementation. This can enlarge an ROI
after an extreme contraction; it is not silently normalized to empty.
Equal endpoints can produce an empty header. No allocation, pixel access,
copy, clone, synchronization, or mapping occurs in these native operations.
Shallow candidate copying changes reference counts and header metadata only.
Native move assignment publishes that candidate; the shared allocation stays
retained while the original header reference is released.

All versions compute these as signed native `int` **before clipping**:

```
ofs.y - dtop
ofs.y + rows + dbottom
ofs.x - dleft
ofs.x + cols + dright
```

The shim checks them in int64_t, including the left-associative intermediate
sums, against the linked native int range. Bottom/right `INT32_MAX` and
top/left `INT32_MIN` on an interior ROI are rejected failure-atomically.

`locateROI` also computes signed `ofs.x + cols` and `ofs.y + rows`, and
converts byte spans/UMat offsets through ptrdiff_t. Ordinary rectangular
Regions stay within their original int-sized axes; more general Core-owned
reshaped headers can retain larger parent byte spans. The boundary preflight
must therefore protect native narrowing before calling locate, not only after.
`wholeSize.height - 1` is safe for nonempty valid reconstructed geometry.
Step products stay within retained allocation spans. UMat's unsigned offset
displacement is intentional modular arithmetic, not signed overflow.
Mat's signed displacement is representable when the allocation span is
representable in ptrdiff_t. No unrelated speculative dimension cap is added.
One further reachable Mat hazard exists even for small valid Regions:
collapsing both row endpoints at the parent bottom while retaining X > 0
would form `datastart + height*step + X*esz`, beyond the allocation's one-past
end. The Mat-only raw guard checks the prospective top-left pointer span
against datalimit and rejects failure-atomically. It does not publish geometry
or replace native clipping. UMat updates an integer offset rather than forming
a pointer, so that duplicate guard is not imposed on UMat. Equal endpoints
inside the parent remain allowed. Raw tests pin rejection and unchanged header.

`updateContinuityFlag` masks/recomputes **CONTINUOUS_FLAG only**, preserving
SUBMATRIX_FLAG. Thus expanding a Region to cover the whole allocation leaves
Is_Submatrix true; shrinking a formerly whole header leaves it false.
Use Locate_Region plus Rows/Columns for current geometry, not that flag.

## Binding boundary / residency review

Ada owns the nonempty/2-D policy, native-result validation, and rejection of
callback temporary capabilities. Its private marker is set at all four typed
external constructors and With_Selected_View. The raw Mat wrapper's existing
`temporary_external_view` remains authoritative for raw callers. Both guards
prevent exposing caller padding or synthetic storage beyond its logical view;
neither `storage_guard` nor data limit is used to infer temporary parent size.

Raw duplicates are justified by concrete safety reasons: empty pointer/storage
access; 2-D fields used by the native arithmetic preflight; temporary logical
capability/lifetime escape; and signed/narrowing byte-span arithmetic.
Every retained condition has an `ABI safety:` comment. There are no depth or
channel checks. All supplied locate outputs clear before any fallible work;
required null outputs/handles fail safely. Candidate adjustment publishes only
on success. Exceptions are contained with the existing four-status model.

Corrective boundary audit: the legacy helper's endpoint clamps and crossed-
endpoint swaps reproduce OpenCV's native operation; they are not a second public
clipping policy or validation guards. Public adjustment semantics still come
from OpenCV. Only old Mat pointer-displacement mechanics are replaced, with an
`ABI safety:` comment identifying the unsafe unsigned pointer addition. No new
public semantic restriction or duplicated semantic validation is added. Existing
retained duplicate guards remain justified above: native-storage access, 2-D
field access, temporary capability escape, signed/narrowing arithmetic, and the
prospective Mat pointer exceeding the allocation's one-past end.

The new production UMat path uses its actual cv::UMat header's locateROI and
adjustROI only. There is no getMat, ACCESS_READ/WRITE, To_Mat/To_UMat, or raw
transfer call. Transfers in ROI tests are observation-only, never production.

## Behavioral evidence

The shared Mat/UMat AUnit cases pin nested (10,8) parent/(3,3) offset,
non-contiguous interior headers, full clipped expansion, ordinary contraction,
crossed contraction from (2,2,4,3) to (1,1,6,5), whole shrink to (1,1,8,6),
continuity/submatrix flag behavior, independent alias geometry/shared pixels,
deep clone independence, parent-variable finalization, and UInt16 C3 exact
offset (2,1). They also verify unchanged depth/channels/element/channel size,
empty/N-D rejection and failure-atomic signed-overflow rejection. Mat-specific
tests reject row-strided caller storage and a legal synthetic 2-D selected view
without changing data or geometry. Separate raw cases cover null handles,
each missing output, cleared outputs, empty/N-D/temporary headers, valid whole
and Region headers, all four overflowing boundary expressions, and unchanged
geometry after failure. The same suite is run on the four compatibility images;
an additional research executable is unnecessary for these settled semantics.

All 28 ROI tests are retained without adding cases. In particular, `ROI Mat
aliases` starts with an interior Region at (2,2), applies positive Top=1 and
Left=1, and asserts the new offset (1,1) and extents (5,4). It writes through both
the original shared pixel and the newly exposed top/left margin, checking parent
pixels (2,2) and (1,1), unchanged alias geometry/pixels, and independent explicit
Clone storage. This is true backward pointer movement on both axes on 4.1/4.6.
`ROI Mat nested`, clipped expansion to (0,0), and retained-parent lifetime cases
also move backward. Ordinary/crossed contraction, empty-result safety, alias
geometry independence, and external/synthetic temporary rejection remain covered.
