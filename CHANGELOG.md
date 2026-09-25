# Changelog

## Unreleased

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
