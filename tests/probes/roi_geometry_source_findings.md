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
uses unsigned size arithmetic in 4.1 (including modular negative movement).

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
**swapped**, in all six inspected implementations. This can enlarge an ROI
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