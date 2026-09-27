# Changelog

## Unreleased

- Added UInt8 C4 / Vec4b typed access: 2-D/N-D Get/Set, copied and
  zero-copy borrowed rows and continuous buffers, writable and read-only
  packed/strided 2-D/N-D caller-owned views, and Merge/Split, Scalar and
  Transform interoperability.

- Added read-only zero-copy caller-owned external Mat views to all sixteen
  typed layouts: packed and strided 2-D/N-D, including aliased constant data.
  Mode-in callbacks prevent normal Ada mutation; the existing temporary-view
  no-escape rule and independent `Clone` behavior apply unchanged. No new C
  constructors or native read-only handle type are introduced.

- Added public persistence `Node_Kind` and named/indexed `Kind` for recursive
  map/sequence inspection. Persisted Mats report `Mapping_Node`.

- Added `OpenCV.Core.Persistence.Map_Length` and `Map_Key` for read-only
  root and entered mappings. Zero-based keys follow OpenCV iteration order;
  returned Ada strings own their bytes and enumeration preserves navigation.

- Added callback-scoped dimension-dropping N-D selected views. New public
  `OpenCV.Core.Dimension_Selection_Kind` (`Keep_Range`, `Fix_Index`),
  discriminated `Dimension_Selection` (`Bounds : Index_Range` for
  `Keep_Range`, `Index : Size_Coordinate` for `Fix_Index`), and
  `Dimension_Selection_Array` types, plus
  `With_Selected_View (Self, Selections, Process)`. One selector is required
  per source dimension in iteration order (lower bounds are irrelevant).
  `Fix_Index` selects one index and drops that dimension; `Keep_Range` keeps
  it restricted to a nonempty half-open range. The result keeps depth,
  channels, source order of kept dimensions, and source strides, so it is
  continuous when only leading dimensions are dropped and gapped otherwise.
  For example, Shape `(2, 3, 2, 4)` with `(Fix 1, Keep [0, 3), Fix 1,
  Keep [0, 4))` yields a `(3, 4)` view whose `(J, K)` is source
  `(1, J, 1, K)`. The source must be nonempty with at least three dimensions,
  at least one dimension must be fixed, at least two must be kept, and the
  final source dimension must be kept, because OpenCV always uses
  `elemSize()` as a Mat's last step and a dropped final axis cannot be
  represented without copying. No 1-D or scalar selected Mat is produced.
  The view shares storage (writes are visible both ways), keeps the source
  allocation alive during the callback, and follows the temporary-view
  no-escape rules: shallow copies, `Slice`, `Reshape`, `Row_View`, `Region`,
  and `Module_Interop` output handles are rejected, while `Clone` and
  `Module_Interop` input succeed. Temporary caller-buffer sources are
  rejected. `Slice` is unchanged.
- Added the private C ABI operation `opencv_core_mat_select_nd_view`
  (`drop_flags`/`starts`/`stops`; a dropped axis is the singleton interval
  `[start, start + 1)`). It rejects null pointers, temporary external sources,
  sources without allocated reference-counted storage, invalid or mismatched
  dimension counts, invalid drop flags, invalid intervals, zero drops, fewer
  than two kept dimensions, and a dropped final dimension, and always clears
  `*out_mat` on failure. Offset, nested-step, header-span, and logical-end
  arithmetic is checked `size_t`/`uintptr_t` arithmetic. The logical span must
  fit between the selected base and the source `datalimit`, and the reduced
  header is built over the source `datastart` (whose `size[0] * step[0]`
  carrier span must fit the allocation) with a full `result_dims`-entry native
  step array (OpenCV 4.1 `setSize()` reads `_steps[dims-1]`). It is then
  retargeted like an OpenCV ROI: `data` is the selected base,
  `datastart`/`dataend`/`datalimit` are inherited from the source, and the
  submatrix flag is set, so no header field claims memory past the source
  allocation.
- The private `opencv_core_mat_handle` now carries an optional
  reference-counted `storage_guard`, declared before the Mat value so it
  outlives the header. Ordinary handles leave it empty; selected views retain
  the source allocation through it, and
  `opencv_core_mat_acquire_borrow_lease` copies it, so nested row and buffer
  borrows keep the allocation alive even if the selected view header is
  rebound during the borrow. Ordinary Mat copy semantics are unchanged.

- Added strided N-D caller-owned Mat views. A new public
  `OpenCV.Core.Dimension_Stride_Array` (one `Positive` stride per dimension,
  measured in complete Mat elements, never bytes) and a new
  `With_Writable_Strided_Mat_View (Data, Shape, Strides, Process)` overload in
  all sixteen typed `*_Mat_View` packages expose gapped N-D caller storage
  without copying. For C2/C3/C4 layouts one stride unit is one complete
  Vec2/Vec3/Vec4 element. Zero-based index `(I1, .., In)` maps to
  `Data (Data'First + I1 * S1 + .. + In * Sn)`; no array lower bound is
  visible. `Shape'Length` must be in 2 .. 32 (10 on OpenCV 5.0, enforced by
  the shim), `Strides'Length = Shape'Length`, the final stride must be 1, and
  each outer stride must cover its nested block
  (`Strides (I) >= Strides (I + 1) * Shape (I + 1)`); overlapping or backwards
  layouts are rejected before `Process` runs. `Data'Length` must be at least
  `Shape (first) * Strides (first)`: OpenCV's header spans the complete outer
  stride, so padding after the final logical outer block must exist; extra
  trailing storage is allowed. Padding is never touched. `Is_Continuous`
  reports the real layout (gapped views are non-continuous and whole-buffer
  borrowing rejects them; packed-equivalent strides are continuous). The same
  temporary external-view no-escape rules apply, and `Clone` returns
  independent packed storage holding only the logical values. The existing
  packed and 2-D row-strided overloads are unchanged.
- Added the private C ABI operation
  `opencv_core_mat_create_external_nd_strided`, taking `ndims` int32 extents
  and `ndims` uint64 complete-element strides (no native `size_t` arrays cross
  the ABI). It validates dimension count and the native dimension limit, null
  pointers, extents, zero/final/nested strides, depth, channels, checked
  `size_t` stride/byte/capacity/logical-end arithmetic, capacity against the
  complete outer stride, data alignment, and address-span wrap, and always
  clears `*out_mat` on failure. The shim builds its own full `ndims`-entry
  native step array with the final entry set to `elemSize()`, because OpenCV
  4.1 `setSize()` reads `_steps[ndims-1]` despite documenting `ndims-1` steps.

- Added a packed N-D `With_Writable_Mat_View (Data, Shape, Process)` overload
  to all sixteen typed `*_Mat_View` packages (UInt8, Int8, UInt16, Int16,
  Int32, Float16, Float32, Float64 C1; Float32/Float64 C2; UInt8/Float16/
  Float32/Float64 C3; Float32/Float64 C4). It creates a callback-scoped,
  continuous N-D Mat that directly aliases caller-owned Ada storage.
  `Shape'Length` must be in 2 .. 32 with positive extents, and `Data'Length`
  must equal `product (Shape)` complete elements exactly. Storage uses
  OpenCV element order (final dimension fastest), matching N-D Get/Set and
  N-D buffer borrowing; neither Ada lower bound is visible. The existing
  `Rows`/`Columns` and 2-D row-strided overloads are unchanged. The same
  temporary external-view no-escape rules apply: shallow copies, `Slice`,
  `Reshape`, and output handles are rejected, while `Clone` is the
  independent escape path.
  OpenCV 5.0's native `MatShape` capacity is 10 dimensions; the binding
  rejects longer shapes as `OpenCV_Error` before invoking the native
  constructor, so the callback never runs. OpenCV 4.x retains the historic
  32-dimensional limit. Public signatures are unchanged.
- Enforced OpenCV 5.0's native Mat dimension capacity
  (`MatShape::MAX_DIMS = 10`) in the C++ shim before every native path that
  establishes a new Mat shape from a caller dimension count:
  `opencv_core_mat_create_nd`, `opencv_core_mat_reshape_nd`, and
  `opencv_core_mat_create_external_nd`. On OpenCV 5.0, N-D `Create`,
  Shape-based `Reshape`, and packed N-D views with 11 .. 32 dimensions now
  raise `OpenCV_Error` (raw ABI: invalid argument, null output) instead of
  depending on OpenCV to reject them. OpenCV 4.x behavior is unchanged.
- Added the private C ABI operation `opencv_core_mat_create_external_nd`,
  which builds the header with OpenCV's longstanding
  `Mat(int ndims, const int *sizes, int type, void *data, const size_t *steps)`
  constructor and null steps (packed layout, 4.1 through 5.0). It validates
  dimension count, extents, depth, channels, data pointer, alignment, checked
  `size_t` element/byte products, an exact byte count, and address-span wrap,
  and always clears `*out_mat` on failure.

- Extended `With_Read_Only_Buffer` / `With_Writable_Buffer` in all sixteen
  typed `*_Buffer_Access` packages (UInt8, Int8, UInt16, Int16, Int32,
  Float16, Float32, Float64 C1; Float32/Float64 C2; UInt8/Float16/Float32/
  Float64 C3; Float32/Float64 C4) to any continuous Mat, including genuine
  N-D Mats and continuous N-D Slices. The flat array uses OpenCV element
  order (final dimension fastest) and one entry per complete Mat element.
  Non-contiguous Regions and N-D Slices are still rejected before the
  callback runs. The public API is unchanged; this is source compatible.
  Previously the typed borrow obtained its base address through the 2-D row
  API, which rejected every N-D Mat.
- Added the private C ABI operation `opencv_core_mat_borrow_contiguous_data`,
  which returns `mat.data` and exactly `product(extents) * elemSize()` bytes
  computed with checked `size_t` arithmetic. Zero-element Mats return a null
  address and zero bytes. It is an implementation operation, not a public
  pointer API. `opencv_core_mat_borrow_row_data` remains strictly 2-D.

- Added complete Float32/Float64 C4 Vec4 typed access: 2-D and N-D elements,
  copied/borrowed 2-D rows, continuous buffers, and packed/strided caller-owned
  Mat views. Explicit four-scalar C ABI records preserve Float64 precision and
  reject equal-size wrong layouts. Generalized shared N-D channel diagnostics
  and native Vec3/Vec4 row validation. Transform C3-to-C4 and C4 identity
  results can be inspected directly as Vec4; Merge/Split and Scalar interoperate.

- Added Float64 C3 Vec3 typed 2-D/N-D access, copied and borrowed rows,
  continuous buffer borrowing, and packed/strided caller-owned Mat views.
  The C ABI transports three doubles component-wise, checks the 24-byte
  layout and rejects same-width wrong-depth Mats. Perspective_Transform
  and Transform results can now be inspected directly without narrowing.

- Added Float32/Float64 C2 Vec2 typed 2-D and N-D element access, copied and
  zero-copy borrowed rows, continuous buffer borrowing, and packed/strided
  caller-owned views. C ABI uses explicit two-scalar structs and checks depth,
  channels, element size, storage, and indices before typed OpenCV access.
  Full-complex DFT spectra can now be inspected as Vec2 elements without
  changing the existing spectral signatures.

- Added `Mat.Shape`, the all-dimensional counterpart of 2-D `Dimensions`.
  The result uses bounds `1 .. Dimension_Count`.
- Added Shape-based `Mat.Reshape` overloads. They create a distinct header
  that shares storage, preserve scalar order, and may change channel count.
  Target extents must be nonzero, the dimension count must be `2 .. 32`, the
  scalar count including channels must stay identical, and the source must be
  continuous. OpenCV's zero-extent preserve-dimension sentinel is not exposed.
  The existing 2-D `Reshape` overloads are unchanged.
- Added the C ABI operation `opencv_core_mat_reshape_nd`.

- Added N-D `Index_Array` Get/Set to `UInt8_Vec3_Access`,
  `Float16_Vec3_Access`, and `Float32_Vec3_Access`. One vector remains one
  complete three-channel element. Float16 N-D access copies the stored
  binary16 component encodings without numeric conversion.
- Added the complete Int8 C1 typed data plane: `OpenCV.Int8_Value`, 2-D and
  N-D Get/Set, copied and borrowed rows, continuous-buffer borrowing, and
  packed or row-strided caller-owned Mat views. Values stay in the signed
  domain `-128 .. 127` with no unsigned or floating-point conversion.
- Added row-strided caller-owned views for UInt8 C1, UInt8 C3, and Float32 C3.
  C3 row strides count complete Vec3 pixels, not scalar channels.

- Completed the single-channel integer access plane: UInt16 and Int16 now have
  continuous-buffer borrowing plus packed and row-strided caller-owned Mat
  views; Int32 now also has copied and borrowed rows, continuous-buffer
  borrowing, and packed or row-strided caller-owned Mat views.
- Tightened the strided external-view capacity contract to match OpenCV's
  `datalimit = datastart + step * rows` header extent. Migrate buffers that
  stopped after the final logical element by allocating complete
  `Rows * Row_Stride` backing elements, including final-row padding.
- Established feature/corrective branch development through real open pull
  requests. Local validation precedes submission, auto-merge remains disabled,
  and corrective review work continues on the same PR branch.
- Corrected integer zero-copy regression coverage: required-capacity overflow
  is tested separately from stride narrowing, and empty integer buffers
  document and test the `1 .. 0` null range. Borrow-lease tests observe the
  original allocation's release rather than reading poisoned storage. The
  observation records that the allocation stays live after ordinary owners
  are released and is deallocated once when the lease ends, including when
  the callback raises. This is allocator-event evidence, not a proof that
  freed memory was never accessed.


## 0.2.0

Source-breaking release. This is not a relocation-only drop: it also
contains the Core work committed after indexed `0.1.0`
(`7788f7da8457d74a7e6fe8da9312ccf863cdae3d`).

### Shared public values moved to `OpenCV`

The `opencv_core` crate still owns and distributes the root `OpenCV`
package. Shared public values now belong to `OpenCV`, not
`OpenCV.Core`. There are no compatibility aliases.

Relocated public declarations:

- numeric value subtypes: `UInt8_Value`, `UInt16_Value`, `Int16_Value`,
  `Int32_Value`, `Float32_Value`, `Float64_Value`
- integer coordinates and geometry: `Point_Coordinate`,
  `Size_Coordinate`, `Point`, `Point_Array`, `Size`, `Rect`
- floating-point geometry: `Float32_Point`, `Float32_Size`,
  `Rotated_Rect`
- shared scalar: `Scalar`, `Make_Scalar`
- shared options: `Border_Kind`, `Angle_Unit`

Enumeration literals move with their owning types:

- `Border_Kind`: `Constant_Border`, `Replicate`, `Reflect`,
  `Reflect_101`, `Wrap`
- `Angle_Unit`: `Radians`, `Degrees`

`Make_Scalar` moves with `Scalar`.

`OpenCV.Core` continues to own `Mat`, matrix-specific types such as
`Depth_Type`, `Mat_Type`, `Channel_Count`, `Mat_Size`,
`Dimension_Array`, `Index_Array`, `Index_Range`, `Index_Range_Array`,
and `Float16_Value`, plus Core operations.

Intended runtime semantics and the C ABI are unchanged. Mat ownership,
shallow assignment, explicit `Clone`, and C++ runtime isolation are
unchanged.

External Ada clients must:

- qualify shared values from `OpenCV` (`OpenCV.Point`, `OpenCV.Size`,
  `OpenCV.Rect`, `OpenCV.Scalar`, `OpenCV.Make_Scalar`, and the other
  relocated names)
- `with OpenCV;` when they need operator/`=` visibility for those
  values
- keep `OpenCV.Core.Mat` and other Core-specific abstractions in
  `OpenCV.Core`

Spellings such as `OpenCV.Core.Point` and `OpenCV.Core.Make_Scalar` no
longer exist.

### Other material work since indexed 0.1.0

Indexed `0.1.0` is commit `7788f7da8457d74a7e6fe8da9312ccf863cdae3d`.
Later Core work included:

- packed CCS and row-wise DFT/DCT plus spectral multiplication
- Float64 C1 typed access, rows, continuous buffers, and packed or
  row-strided external views
- Int32, UInt16, and Int16 C1 typed access and row access
- `Float16_Value` encoding and Float16/Float32 conversion
- Float16 C1/C3 typed access, rows, buffers, and packed or row-strided
  views
- native-first Float16 `Add`, `Subtract`, `Multiply`, `Divide`,
  `Abs_Diff`, `Minimum`, `Maximum`, `Add_Weighted`, and `Scale_Add`
- cross-module Mat interop bridge and installed
  `opencv_core_module_bridge.hpp`
- signed `Rect` origins, with `Mat.Region` still rejecting negative ROI
  origins
- `Float32_Point`, `Float32_Size`, and `Rotated_Rect`
- Windows MinGW64 GPR path canonicalization and platform-specific
  module-bridge probe builds

### Packaging

The root `alire.toml` now declares the native dependencies that were
already present in the published `0.1.0` index manifest:

- `opencv = "*"` (native OpenCV system package)
- `pkg_config = "*"`
- Windows-only `mingw_w64_gcc = "*"`

Ordinary publication should no longer require adding those declarations
by hand.

`opencv_core.gpr` now installs `cpp/opencv_core_module_bridge.hpp` into
the prefix `include` directory. The previous destination/source
`Artifacts` mapping did not export the header.

## 0.1.0

Initial indexed release at commit
`7788f7da8457d74a7e6fe8da9312ccf863cdae3d`.
