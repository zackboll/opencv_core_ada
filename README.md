# opencvcore_ada

A thick, idiomatic Ada binding for the **OpenCV Core** module.

`opencvcore_ada` provides a safe Ada-facing API over OpenCV Core data structures and array operations without exposing C++ ABI details to Ada applications. The binding uses a stable C ABI shim between Ada and C++, preserves OpenCV ownership and numeric semantics, and presents common OpenCV concepts through Ada controlled types, strong enums and records, overloads, generics, ranges, and exceptions.

> **Project status:** active development, `0.1.0-dev`.
>
> **Current baseline:** **235 AUnit tests** in the current development suite as of August 2026.
>
> **Current milestone status:** the mask/selection and channel-manipulation milestones are complete; the core 2-D matrix layout/rearrangement milestone is largely complete; reductions now include `Trace` and axis-based `Reduce`.

## Goals

The project is designed around several principles:

- Provide an **idiomatic Ada API**, rather than mechanically translating the C++ interface.
- Keep C++ implementation details behind a **stable `extern "C"` ABI**.
- Never expose `cv::Mat`, C++ references, templates, STL containers, exceptions, or `std::string` directly across the ABI.
- Represent OpenCV resources with Ada controlled types and preserve OpenCV reference-counted ownership semantics.
- Use strong Ada types, enums, overloads, records, generics, ranges, and exceptions where they improve safety and readability.
- Preserve OpenCV's actual numeric behavior, including integer saturation, rounding, non-contiguous matrices, masks, and IEEE floating-point edge cases.
- Build features vertically: public Ada API → thin Ada interop → C++ shim → OpenCV → AUnit tests.
- Keep the public library independent from test-only dependencies such as AUnit, GNATprove, and GNATcov.
- Prefer explicit Ada abstractions over C++-specific encodings such as integer mode constants, flattened channel maps, output parameters, and STL collections.

This crate is focused on **OpenCV Core**. Higher-level modules such as image processing, image codecs, GUI, video I/O, calibration, features, and DNN functionality are expected to live in separate Ada crates that depend on `opencvcore_ada`.

---

## Architecture

The binding is intentionally layered:

```text
Ada application
     |
     v
+---------------------------+
| Thick Ada API             |
| OpenCV.Core               |
| strong types / exceptions |
+---------------------------+
     |
     v
+---------------------------+
| Thin Ada interop          |
| OpenCV.Internal.C_API     |
| fixed-width ABI types     |
+---------------------------+
     |
     v
+---------------------------+
| C++ shim / stable C ABI   |
| extern "C"                |
| opaque handles            |
+---------------------------+
     |
     v
+---------------------------+
| OpenCV Core               |
| cv::Mat / cv::*           |
+---------------------------+
```

### ABI rules

The C++ shim:

- exports only `extern "C"` functions;
- uses opaque handles for `cv::Mat`;
- uses fixed-width integers and simple C-compatible records;
- catches OpenCV, standard C++, and unknown exceptions;
- translates failures into stable status codes plus a diagnostic message;
- does not allow C++ exceptions to cross into Ada;
- does not pass C++ objects, references, STL types, or templates across the boundary.

C++ containers may be used **inside** the shim when OpenCV requires them, but they never cross the ABI.

### `Mat` ownership model

`OpenCV.Core.Mat` is a tagged private Ada controlled type.

Ada assignment follows OpenCV's normal shallow/reference-counted semantics:

```ada
B := A;
```

`B` receives a distinct `cv::Mat` header sharing the underlying OpenCV storage with `A`.

Use `Clone` when independent storage is required:

```ada
B := A.Clone;
```

Views such as:

- `Region`
- `Row_View`
- `Column_View`
- `Reshape`
- `Diagonal_View`

create distinct `Mat` headers that share storage where OpenCV defines a no-copy view.

Operations that compute a new result, including arithmetic, conversions, transforms, channel extraction/splitting, concatenation, diagonal-matrix construction, and reductions such as `Reduce`, return independently owned result storage unless explicitly documented otherwise.

---

## Requirements

The build currently expects:

- an Ada toolchain supported by Alire;
- **Alire**;
- a C++17 compiler;
- **pkg-config**;
- OpenCV development files providing the `opencv4` pkg-config package;
- the OpenCV Core library (`opencv_core`).

The project compiles the shim as C++17 and links against:

```text
opencv_core
libstdc++
```

OpenCV include and library paths are discovered automatically by:

```text
scripts/configure_opencv.sh
```

using the `opencv4` pkg-config package.

The binding targets portable OpenCV 4.x Core behavior. Release-by-release compatibility across all OpenCV 4.x versions is not yet formally characterized, so authoritative OpenCV declarations/source are checked when each feature is integrated.

---

## Building

Clone the repository and build it with Alire:

```sh
git clone https://github.com/zackboll/opencvcore_ada.git
cd opencvcore_ada
alr build
```

The Alire pre-build action runs `scripts/configure_opencv.sh`, which generates the local OpenCV GPR configuration from `pkg-config`.

If configuration fails, verify:

```sh
pkg-config --exists opencv4
```

and make sure the OpenCV development package and `pkg-config` are installed.

The library supports the normal GPR library kinds through `LIBRARY_TYPE` / `OPENCVCORE_ADA_LIBRARY_TYPE`, with `static` as the default.

---

## Running the test suite

Tests are maintained as a separate Alire crate under `tests/`.

```sh
alr -C tests build
alr -C tests run
```

The test crate currently depends on:

- AUnit `^26.0.0`;
- the local `opencvcore_ada` crate;
- GNATprove `^16.1.0`;
- GNATcov `^26.2.1`.

These development dependencies are intentionally not dependencies of the public library crate.

The test suite is organized into:

- `Mat_Basic_Tests`
- `Mat_Access_Tests`
- `Mat_View_Tests`
- `Mat_Conversion_Tests`
- `Mat_Arithmetic_Tests`
- `Mat_Channel_Tests`
- `Mat_Mask_Tests`
- `Mat_Reduction_Tests`
- `Mat_Transform_Tests`

Current development baseline:

```text
235 AUnit tests
```

---

# Quick start

## Create and access a single-channel matrix

```ada
with Ada.Text_IO;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;

procedure Example is
   use OpenCV.Core;

   Image : Mat :=
     Create
       (Rows         => 480,
        Columns      => 640,
        Element_Type => (Depth => UInt8, Channels => 1));

   Value : UInt8_Value;
begin
   OpenCV.Core.UInt8_Access.Set
     (Image  => Image,
      Row    => 10,
      Column => 20,
      Value  => 255);

   Value :=
     OpenCV.Core.UInt8_Access.Get
       (Image  => Image,
        Row    => 10,
        Column => 20);

   Ada.Text_IO.Put_Line (UInt8_Value'Image (Value));
end Example;
```

## Use `Size`

```ada
with OpenCV.Core;

procedure Size_Example is
   use OpenCV.Core;

   Image : Mat :=
     Create
       (Dimensions   => (Width => 640, Height => 480),
        Element_Type => (Depth => Float32, Channels => 1));

   Dims : constant Size := Image.Dimensions;
begin
   null;
end Size_Example;
```

`Dimensions.Width` corresponds to `Columns`; `Dimensions.Height` corresponds to `Rows`.

---

# Typed access

The public `Depth_Type` represents:

```text
UInt8
Int8
UInt16
Int16
Int32
Float32
Float64
Float16
```

Typed element-access packages currently concentrate on UInt8 and Float32.

## Scalar element access

Available scalar accessors include:

- UInt8 `Get` / `Set`;
- Float32 `Get` / `Set`;
- Float32 non-finite classification.

## Multi-channel `Vec3` access

Three-channel UInt8 and Float32 accessors are provided.

```ada
with OpenCV.Core;
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;

procedure Vec3_Example is
   use OpenCV.Core;

   Image : Mat :=
     Create
       (Rows         => 100,
        Columns      => 100,
        Element_Type => (Depth => UInt8, Channels => 3));

   Pixel : OpenCV.Core.UInt8_Vec3.Vector;
begin
   OpenCV.Core.UInt8_Vec3_Access.Set
     (Image,
      Row    => 0,
      Column => 0,
      Value  => (10, 20, 30));

   Pixel := OpenCV.Core.UInt8_Vec3_Access.Get (Image, 0, 0);
end Vec3_Example;
```

The predefined Vec3 types are component-oriented rather than assigning RGB/BGR semantics. Channel interpretation belongs to the caller or a higher-level module.

## Bulk row access

Safe copied row access avoids exposing raw OpenCV pointers to public Ada code.

```ada
with OpenCV.Core;
with OpenCV.Core.UInt8_Row_Access;

procedure Row_Example is
   use OpenCV.Core;

   Image : Mat :=
     Create
       (Rows         => 2,
        Columns      => 4,
        Element_Type => (Depth => UInt8, Channels => 1));

   Data : OpenCV.Core.UInt8_Row_Access.Row_Array (1 .. 4) :=
     (10, 20, 30, 40);

   Readback : OpenCV.Core.UInt8_Row_Access.Row_Array (10 .. 13);
begin
   OpenCV.Core.UInt8_Row_Access.Write_Row (Image, 0, Data);
   OpenCV.Core.UInt8_Row_Access.Read_Row (Image, 0, Readback);
end Row_Example;
```

Row arrays may use arbitrary Ada lower bounds. Their ordered elements map to matrix columns `0 .. Columns - 1`.

Bulk row APIs currently exist for:

- UInt8 single-channel;
- Float32 single-channel;
- UInt8 Vec3;
- Float32 Vec3.

---

# Views, copies, and shape

## Region of interest

`Region` returns a shallow view:

```ada
ROI : Mat :=
  Source.Region
    ((X      => 100,
      Y      => 50,
      Width  => 200,
      Height => 100));
```

`ROI` has its own `Mat` header but shares source storage through OpenCV reference counting.

## Row and column views

```ada
R1 : Mat := Source.Row_View (10);
R2 : Mat := Source.Row_View ((Start => 10, Stop => 20));

C1 : Mat := Source.Column_View (5);
C2 : Mat := Source.Column_View ((Start => 5, Stop => 15));
```

`Index_Range` uses half-open semantics:

```text
Start <= index < Stop
```

## Reshape

```ada
Reshaped : Mat := Source.Reshape (Channels => 1);
```

`Reshape` follows OpenCV no-copy semantics and therefore returns a new header sharing the original storage where valid.

## Diagonal view

`Diagonal_View` exposes OpenCV's shared-storage diagonal view without leaking the raw C++ `diag(int)` interface:

```ada
Main  : Mat := Matrix.Diagonal_View;
Above : Mat := Matrix.Diagonal_View (1);
Below : Mat := Matrix.Diagonal_View (-1);
```

Offsets are:

- `0`: main diagonal;
- positive: diagonals above the main diagonal;
- negative: diagonals below the main diagonal.

The returned matrix is a single-column view sharing source storage.

## Clone and Copy_To

```ada
Independent : Mat := Source.Clone;

Source.Copy_To (Destination);
Source.Copy_To (Destination, Mask);
```

`Clone` always provides an independent deep copy.

`Copy_To` follows OpenCV destination allocation/reallocation behavior. Masked `Copy_To` uses the common mask contract described below.

---

# Arithmetic and conversion

The current first-generation arithmetic API intentionally favors explicit Mat/Mat operations with matching shape and complete element type.

```ada
Sum_Mat        : Mat := A.Add (B);
Difference     : Mat := A.Subtract (B);
Product        : Mat := A.Multiply (B);
Quotient       : Mat := A.Divide (B);
Abs_Difference : Mat := A.Abs_Diff (B);
```

For these operations:

- rows must match;
- columns must match;
- depth must match;
- channel count must match;
- results own independent storage.

OpenCV numeric behavior is preserved, including integer saturation and OpenCV's defined divide behavior.

## Weighted addition

```ada
Blended : Mat :=
  A.Add_Weighted
    (Alpha => 0.25,
     Right => B,
     Beta  => 0.75,
     Gamma => 2.0);
```

## Scaled addition

```ada
Scaled : Mat := A.Scale_Add (Scale => 2.0, Right => B);
```

The result is `Scale * A + B` with independent storage. UInt8, Int8, UInt16,
and Int16 follow OpenCV saturation; Int32 does not saturate. Float32 and
Float64 use OpenCV's dedicated scaleAdd kernels.

## Convert depth, scale, and offset

```ada
Converted : Mat :=
  Image.Convert_To
    (Depth  => Float32,
     Scale  => 1.0 / 255.0,
     Offset => 0.0);
```

The channel count is preserved.

## Normalize

```ada
Normalized : Mat :=
  Image.Normalize
    (Kind  => L2,
     Alpha => 1.0);
```

Supported normalization kinds:

- `L1`
- `L2`
- `Infinity`
- `Min_Max`

---

# Masks and selection

## Common mask contract

Masks are ordinary `Mat` values.

A valid mask is:

```text
Depth    = UInt8
Channels = 1
Rows     = source Rows
Columns  = source Columns
```

Any nonzero mask value selects the corresponding complete matrix element.

## Generate masks with `In_Range`

```ada
Mask : Mat :=
  Image.In_Range
    (Lower => Make_Scalar (10.0),
     Upper => Make_Scalar (200.0));
```

The returned mask is UInt8, single-channel, source-sized, with `255` for selected elements and `0` otherwise.

## Compare matrices

```ada
Mask : Mat := A.Compare (B, Greater_Than);
```

Comparison kinds are:

- `Equal`
- `Not_Equal`
- `Less_Than`
- `Less_Or_Equal`
- `Greater_Than`
- `Greater_Or_Equal`

`Compare` currently targets compatible single-channel Mats and returns a UInt8 single-channel mask.

## Mask consumers

Masked operations currently include:

- `Bitwise_And`
- `Bitwise_Or`
- `Bitwise_Xor`
- `Bitwise_Not`
- `Copy_To`
- `Set_To`
- `Mean`
- `Mean_Std_Dev`
- `Norm`
- `Min_Max_Loc`

Example:

```ada
Image.Set_To (Make_Scalar (255.0), Mask);

Copied_Source.Copy_To (Destination, Mask);

Selected_Mean : Scalar := Image.Mean (Mask);
```

## Nonzero queries

```ada
Count     : Mat_Size    := Mask.Count_Non_Zero;
Any_Set   : Boolean     := Mask.Has_Non_Zero;
Locations : Point_Array := Mask.Find_Non_Zero;
```

`Find_Non_Zero` returns points in row-major order with:

```text
Point.X = column
Point.Y = row
```

For a `Region`, locations are relative to the region.

---

# Channel manipulation

The public collection type is:

```ada
type Mat_Array is array (Natural range <>) of Mat;
```

Each element has the normal controlled `Mat` ownership model. Arrays may use arbitrary Ada lower bounds.

## Split and Merge

```ada
Channels : constant Mat_Array := Image.Split;
Rebuilt  : Mat := Merge (Channels);
```

`Split` returns one independent single-channel Mat per source channel.

`Merge` concatenates channels in Ada array iteration order. Input Mats may themselves have multiple channels when allowed by OpenCV.

## Extract and insert a channel

```ada
Green : Mat := Image.Extract_Channel (1);

Destination.Insert_Channel
  (Source  => Green,
   Channel => 1);
```

Channel indices are zero-based.

## Mix channels

`Mix_Channels` uses an Ada-native route representation rather than exposing OpenCV's flat integer `fromTo` array.

Routes can:

- copy a source channel to a destination channel;
- broadcast a source channel to multiple destination channels;
- explicitly zero-fill a destination channel.

Route Mat indices refer to the **actual Ada indices** of the supplied `Mat_Array` values, including arrays whose lower bound is not zero.

Duplicate destination targets are rejected by the thick Ada API.

---

# Matrix layout and transforms

## Transpose

```ada
T : Mat := Image.Transpose;
```

Rows and columns are exchanged; depth and channel count are preserved.

## Flip

```ada
Horizontal_Flip : Mat := Image.Flip (Horizontal);
Vertical_Flip   : Mat := Image.Flip (Vertical);
Both            : Mat := Image.Flip (Both_Axes);
```

## Rotate

```ada
CW  : Mat := Image.Rotate (Clockwise_90);
R180 : Mat := Image.Rotate (Half_Turn);
CCW : Mat := Image.Rotate (Counterclockwise_90);
```

## Repeat

```ada
Tiled : Mat :=
  Image.Repeat
    (Row_Repetitions    => 2,
     Column_Repetitions => 3);
```

## Concatenation

```ada
Wide : Mat :=
  HConcat ((0 => Left, 1 => Right));

Tall : Mat :=
  VConcat ((0 => Top, 1 => Bottom));
```

`HConcat` processes inputs left-to-right in Ada array iteration order.

`VConcat` processes inputs top-to-bottom in Ada array iteration order.

Both return independent storage and accept arbitrary `Mat_Array` lower bounds.

## Diagonal-matrix construction

```ada
D : Mat := Diagonal_Matrix (Values);
```

`Values` must be a row or column vector.

The result is square, stores the vector values on its main diagonal, zero-fills all off-diagonal elements, preserves the complete element type, and owns independent storage.

---

# Reductions and statistics

## Sum

```ada
S : Scalar := Image.Sum;
```

## Trace

```ada
T : Scalar := Matrix.Trace;
```

`Trace` returns the per-channel sum of the main diagonal.

It accepts rectangular and non-contiguous Mats. Because the result is represented by `Scalar`, it supports up to four channels. OpenCV's trace implementation does not support Float16 in the current binding.

## Mean

```ada
M  : Scalar := Image.Mean;
MM : Scalar := Image.Mean (Mask);
```

## Mean and standard deviation

```ada
Stats        : Mean_Std_Dev_Result := Image.Mean_Std_Dev;
Masked_Stats : Mean_Std_Dev_Result := Image.Mean_Std_Dev (Mask);
```

## Norm

```ada
Magnitude        : Long_Float := Image.Norm (L2);
Masked_Magnitude : Long_Float := Image.Norm (Mask, L2);
```

Current norm kinds:

- `L1`
- `L2`
- `Infinity`

## Minimum and maximum location

```ada
Extrema        : Min_Max_Result := Image.Min_Max_Loc;
Masked_Extrema : Min_Max_Result := Image.Min_Max_Loc (Mask);
```

Locations use:

```text
Point.X = column
Point.Y = row
```

## Axis reduction

`Reduce` uses Ada enums rather than OpenCV's integer `dim` and reduction constants.

```ada
Column_Sums : Mat :=
  Image.Reduce
    (Axis         => Across_Rows,
     Kind         => Sum,
     Output_Depth => Float32);

Row_Maxima : Mat :=
  Image.Reduce
    (Axis => Across_Columns,
     Kind => Maximum);
```

Axis semantics:

- `Across_Rows` reduces rows and produces one row;
- `Across_Columns` reduces columns and produces one column.

Reduction kinds:

- `Sum`
- `Average`
- `Maximum`
- `Minimum`
- `Sum_Of_Squares`

An overload without `Output_Depth` preserves OpenCV's default `dtype = -1` behavior.

---

# Bitwise operations

Unmasked operations:

```ada
A_And_B : Mat := A.Bitwise_And (B);
A_Or_B  : Mat := A.Bitwise_Or (B);
A_Xor_B : Mat := A.Bitwise_Xor (B);
Not_A   : Mat := A.Bitwise_Not;
```

Masked overloads exist for all four operations.

OpenCV bitwise behavior is preserved for floating-point matrices as well, where the operation applies to the underlying element bit representation.

---

# Float32 non-finite values

OpenCV arithmetic can legitimately produce IEEE infinity or NaN values.

Use `Classify` when a result may be non-finite:

```ada
Kind := OpenCV.Core.Float32_Access.Classify (Image, 0, 0);
```

Classification values are:

```text
Finite
Positive_Infinity
Negative_Infinity
Not_A_Number
```

---

# Generic vectors and fixed matrices

## Generic vectors

The generic vector package is:

```ada
generic
   type Element_Type is private;
   Length : Positive;
package OpenCV.Core.Vectors;
```

Predefined Vec3 packages currently exist for UInt8 and Float32.

## Fixed matrices / Matx-style values

A pure-Ada fixed-matrix generic is available:

```ada
generic
   type Element_Type is private;
   Row_Count : Positive;
   Column_Count : Positive;
package OpenCV.Core.Fixed_Matrices;
```

A predefined Float32 3×3 matrix and copy-only conversion to/from `Mat` are implemented.

The C++ `cv::Matx` object itself is not passed through the ABI.

---

# Current public Core functionality

## Types and enums

- `Depth_Type`
- `Mat_Type`
- `Channel_Count`
- `Mat_Size`
- `Size_Coordinate`
- `Point_Coordinate`
- `Size`
- `Point`
- `Point_Array`
- `Rect`
- `Index_Range`
- `Scalar`
- `Mat`
- `Mat_Array`
- `Min_Max_Result`
- `Mean_Std_Dev_Result`
- `Norm_Kind`
- `Normalize_Kind`
- `Comparison_Kind`
- `Flip_Kind`
- `Rotation_Kind`
- `Reduction_Axis`
- `Reduction_Kind`
- `Channel_Source_Kind`
- `Channel_Route`
- `Channel_Route_Array`

## Matrix creation, lifetime, and views

- `Create`
- controlled lifetime
- shallow Ada assignment
- `Clone`
- `Copy_To`
- `Region`
- `Row_View`
- `Column_View`
- `Reshape`
- `Diagonal_View`
- `Diagonal_Matrix`

## Shape, type, and storage metadata

- `Rows`
- `Columns`
- `Dimensions`
- `Channels`
- `Depth`
- `Total`
- `Element_Size`
- `Channel_Size`
- `Is_Empty`
- `Is_Continuous`
- `Is_Submatrix`

## Data access

- UInt8 scalar `Get` / `Set`
- Float32 scalar `Get` / `Set`
- Float32 non-finite `Classify`
- UInt8 Vec3 `Get` / `Set`
- Float32 Vec3 `Get` / `Set`
- safe copied UInt8 rows
- safe copied Float32 rows
- safe copied UInt8 Vec3 rows
- safe copied Float32 Vec3 rows

## Arithmetic / conversion

- `Convert_To`
- `Normalize`
- `Add`
- `Subtract`
- `Multiply`
- `Divide`
- `Abs_Diff`
- `Add_Weighted`
- `Scale_Add`

## Bitwise / masks / selection

- `Bitwise_And`
- `Bitwise_Or`
- `Bitwise_Xor`
- `Bitwise_Not`
- masked bitwise overloads
- `In_Range`
- `Compare`
- masked `Copy_To`
- masked `Set_To`
- `Count_Non_Zero`
- `Has_Non_Zero`
- `Find_Non_Zero`

## Channel manipulation

- `Split`
- `Merge`
- `Extract_Channel`
- `Insert_Channel`
- `Mix_Channels`

## Matrix layout / rearrangement

- `Transpose`
- `Flip`
- `Rotate`
- `Repeat`
- `HConcat`
- `VConcat`
- `Diagonal_View`
- `Diagonal_Matrix`

## Reductions / statistics

- `Sum`
- `Trace`
- `Reduce`
- `Mean`
- masked `Mean`
- `Mean_Std_Dev`
- masked `Mean_Std_Dev`
- `Norm`
- masked `Norm`
- `Min_Max_Loc`
- masked `Min_Max_Loc`
- `Count_Non_Zero`
- `Has_Non_Zero`
- `Find_Non_Zero`

## Value-like generic support

- generic vectors
- predefined UInt8 / Float32 Vec3
- generic fixed matrices
- predefined Float32 3×3 fixed matrix
- copy conversion between Float32 3×3 fixed matrix and `Mat`

---

# Milestone status and roadmap

The roadmap tracks **portable, user-facing OpenCV Core functionality**, not every internal or backend symbol under OpenCV Core.

## Milestone 0 — Core binding foundation

- [x] stable `extern "C"` shim
- [x] opaque `cv::Mat` handles
- [x] C++ exception containment
- [x] Ada controlled lifetime
- [x] shallow assignment semantics
- [x] explicit deep copy with `Clone`
- [x] checked metadata conversion
- [x] 2-D ROI/view lifetime
- [x] non-contiguous Mat handling
- [x] UInt8 / Float32 typed access
- [x] Vec3 access pattern
- [x] bulk row-copy access pattern
- [x] generic vector abstraction
- [x] generic fixed-matrix abstraction
- [x] common mask contract
- [x] vertically integrated AUnit workflow

**Status: complete as the current architectural foundation.**

---

## Milestone 1 — mask and selection ecosystem

- [x] `In_Range`
- [x] `Compare`
  - [x] Equal
  - [x] Not equal
  - [x] Less than
  - [x] Less than or equal
  - [x] Greater than
  - [x] Greater than or equal
- [x] `Count_Non_Zero`
- [x] `Has_Non_Zero`
- [x] `Find_Non_Zero`
- [x] `Copy_To`
- [x] masked `Copy_To`
- [x] masked `Set_To`
- [x] masked bitwise operations
- [x] masked `Mean`
- [x] masked `Mean_Std_Dev`
- [x] masked `Norm`
- [x] masked `Min_Max_Loc`

**Status: complete for the planned basic mask production/consumption workflow.**

---

## Milestone 2 — channel manipulation

- [x] `Mat_Array`
- [x] `Split`
- [x] `Merge`
- [x] `Extract_Channel`
- [x] `Insert_Channel`
- [x] `Channel_Route` / `Channel_Route_Array`
- [x] explicit zero-fill routing
- [x] `Mix_Channels`

**Status: complete for the planned channel-manipulation milestone.**

---

## Milestone 3 — matrix layout and rearrangement

- [x] `Transpose`
- [x] `Flip`
- [x] `Rotate`
- [x] `Repeat`
- [x] `HConcat`
- [x] `VConcat`
- [x] `Diagonal_View`
- [x] `Diagonal_Matrix`
- [ ] `Copy_Make_Border`
- [ ] stride / step metadata where useful
- [ ] ROI location / adjustment helpers if needed

N-dimensional variants remain deferred until an N-D public `Mat` model is designed.

**Status: core 2-D rearrangement operations largely complete.**

---

## Milestone 4 — everyday arithmetic expansion

Already implemented:

- [x] Mat/Mat `Add`
- [x] Mat/Mat `Subtract`
- [x] Mat/Mat `Multiply`
- [x] Mat/Mat `Divide`
- [x] Mat/Mat `Abs_Diff`
- [x] `Add_Weighted`
- [x] `Convert_To`
- [x] `Normalize`

Remaining candidates:

- [ ] Mat/Scalar `Add`
- [ ] Mat/Scalar and Scalar/Mat `Subtract`
- [ ] Mat/Scalar `Multiply`
- [ ] Mat/Scalar and Scalar/Mat `Divide`
- [ ] Scalar `Abs_Diff`
- [ ] Scalar bitwise variants
- [ ] masked `Add`
- [ ] masked `Subtract`
- [ ] explicit result depth where OpenCV supports it
- [ ] deliberate mixed-depth arithmetic policy
- [ ] configurable multiply/divide scale
- [x] `Scale_Add`
- [x] element-wise `Min`
- [x] element-wise `Max`
- [x] `Convert_Scale_Abs`
- [ ] lookup-table (`LUT`) operations

Mixed-depth and Scalar overload proliferation should be added deliberately rather than by mechanically mirroring every C++ overload.

---

## Milestone 5 — element-wise mathematical functions

- [ ] `Sqrt`
- [ ] `Pow`
- [ ] `Exp`
- [ ] `Log`
- [ ] `Magnitude`
- [ ] `Phase`
- [ ] Cartesian-to-polar conversion
- [ ] polar-to-Cartesian conversion

Most should reuse the established independent-result `Mat` pattern.

---

## Milestone 6 — reductions and statistics

Completed:

- [x] `Sum`
- [x] `Mean`
- [x] masked `Mean`
- [x] `Mean_Std_Dev`
- [x] masked `Mean_Std_Dev`
- [x] `Norm`
- [x] masked `Norm`
- [x] `Min_Max_Loc`
- [x] masked `Min_Max_Loc`
- [x] `Count_Non_Zero`
- [x] `Has_Non_Zero`
- [x] `Find_Non_Zero`
- [x] `Trace`
- [x] axis-based `Reduce`
  - [x] Sum
  - [x] Average
  - [x] Maximum
  - [x] Minimum
  - [x] Sum of squares
  - [x] explicit output depth

Remaining candidates:

- [ ] two-Mat norm / distance
- [ ] relative norm support where appropriate
- [ ] additional norm kinds where useful
- [ ] `Min_Max_Idx`
- [ ] arg-min reduction
- [ ] arg-max reduction
- [ ] `PSNR`
- [ ] `Check_Range`
- [ ] `Patch_NaNs`
- [ ] covariance matrix
- [ ] Mahalanobis distance

Result types should remain idiomatic Ada values rather than C++ output-parameter translations where practical.

---

## Milestone 7 — linear algebra

- [ ] `Dot`
- [ ] `Cross`
- [x] `Trace`
- [ ] `GEMM`
- [ ] `Mul_Transposed`
- [ ] `Set_Identity`
- [ ] `Complete_Symm`
- [ ] `Determinant`
- [ ] `Invert`
- [ ] `Solve`
- [ ] eigenvalues / eigenvectors
- [ ] non-symmetric eigen decomposition
- [ ] SVD
- [ ] PCA
- [ ] LDA
- [ ] covariance
- [ ] Mahalanobis distance
- [ ] cubic solving
- [ ] polynomial solving

These operations may require new Ada result types for decompositions returning multiple matrices or vectors.

---

## Milestone 8 — spectral operations

- [ ] DFT
- [ ] inverse DFT
- [ ] DCT
- [ ] inverse DCT
- [ ] spectrum multiplication
- [ ] optimal DFT size

OpenCV flag sets should be represented by strongly typed Ada enums/options rather than leaking C++ constants into the public interface.

---

## Milestone 9 — random numbers, sorting, and algorithms

- [ ] random generator abstraction
- [ ] uniform random fill
- [ ] normal random fill
- [ ] random shuffle
- [ ] random seed support
- [ ] sort
- [ ] sort indices
- [ ] batch distance
- [ ] K-means
- [ ] partitioning if useful

OpenCV's overloaded C++ RNG API should be redesigned as an Ada-friendly abstraction rather than mechanically exposed.

---

## Milestone 10 — persistence and advanced structures

Potential later scope:

- [ ] XML/YAML/JSON persistence
- [ ] `FileStorage`
- [ ] `FileNode`
- [ ] Mat serialization
- [ ] broader predefined Vec/Matx families
- [ ] full typed access for remaining depths
- [ ] N-dimensional `Mat`
- [ ] N-dimensional reshape/views
- [ ] `SparseMat`
- [ ] external/shared-buffer Mat construction
- [ ] `UMat` if a concrete use case requires it
- [ ] async Core APIs if a concrete use case requires them

These areas are intentionally later because they require more substantial architectural decisions.

---

# Typed access still to be expanded

Public typed element/row access currently concentrates on UInt8 and Float32.

Potential future access packages include:

- [ ] Int8
- [ ] UInt16
- [ ] Int16
- [ ] Int32
- [ ] Float64
- [ ] Float16
- [ ] additional multi-channel typed access

Before adding many repetitive packages, the implementation should continue looking for opportunities to reuse Ada generics while preserving strict public typing and a safe C ABI.

---

# Current project state

The difficult cross-language foundation is established and several originally planned feature groups are now complete.

In particular:

- the basic mask production/consumption workflow is complete;
- the planned channel-manipulation milestone is complete;
- the major 2-D layout operations are implemented;
- diagonal view and diagonal construction semantics are represented separately and idiomatically;
- reductions now include both scalar-style statistics and axis-based `Reduce`;
- non-contiguous Regions are routinely included in feature tests;
- ownership/view/copy semantics are explicitly tested for new operations.

Much of the remaining work is breadth rather than reinvention of the binding architecture.

The largest remaining user-facing areas are:

- broader arithmetic overloads;
- element-wise math;
- additional typed-access depths;
- linear algebra;
- spectral operations;
- RNG/sorting/algorithms;
- persistence;
- N-dimensional and advanced matrix structures.

---

# Known limitations

Current intentional limitations include:

1. **Primarily 2-D dense `Mat`.**  
   N-dimensional Mat support has not yet been designed as a public Ada abstraction.

2. **No `SparseMat` or `UMat` public layer.**

3. **Typed access is not yet available for every depth.**  
   Public typed access currently concentrates on UInt8 and Float32, plus Vec3 forms.

4. **Scalar-valued APIs represent at most four components.**  
   Operations returning `Scalar` validate channel limits rather than silently losing data.

5. **Some OpenCV operations have depth-specific restrictions.**  
   The binding preserves those semantics; for example, `Trace` currently rejects Float16.

6. **Basic arithmetic emphasizes same-shape, same-depth, same-channel Mat/Mat operations.**  
   Scalar operands, mixed-depth policies, and many masked arithmetic variants remain future work.

7. **No general C++ expression-template equivalent.**  
   `cv::MatExpr` is intentionally not exposed. The Ada API uses explicit operations.

8. **No raw public data pointers.**  
   Safe typed and copied-row access is preferred over leaking OpenCV memory-layout details.

9. **OpenCV 4.x compatibility is not yet characterized release by release.**

10. **The API is pre-1.0.**  
    Public signatures may evolve as larger Core families reveal better Ada abstractions.

---

# Scope and non-goals

The long-term goal is broad coverage of **portable, user-facing OpenCV Core functionality**.

Literal wrapping of every symbol under OpenCV's `core` source tree is not a goal.

The following implementation/backend surfaces are expected to remain out of scope unless a concrete need appears:

- HAL implementation interfaces;
- SIMD/intrinsics internals;
- DirectX interoperability;
- OpenGL interoperability;
- VA-API interoperability;
- internal OpenCL implementation details;
- IPP backend integration;
- internal parallel backend/plugin interfaces;
- other implementation-specific plumbing that is not part of a normal portable Core workflow.

The project favors a coherent Ada interface over a misleading claim of 100% symbol-for-symbol C++ coverage.

---

# Error handling

The public API raises Ada exceptions rather than returning C-style status codes.

Across the language boundary:

1. the thick Ada layer validates public preconditions where practical;
2. the C++ shim validates ABI-level arguments;
3. OpenCV is called inside exception containment;
4. C++ exceptions are caught;
5. a stable status and diagnostic are returned to Ada;
6. the thick Ada layer raises the appropriate Ada exception.

Public callers do not interact with the internal C status API.

---

# Project layout

```text
opencvcore_ada/
├── alire.toml
├── opencvcore_ada.gpr
├── config/
│   ├── opencvcore_ada_config.gpr
│   └── opencvcore_ada_opencv.gpr     # generated/configured
├── cpp/
│   ├── opencv_core_shim.cpp
│   └── opencv_core_shim.h
├── scripts/
│   └── configure_opencv.sh
├── src/
│   ├── opencv-core.ads
│   ├── opencv-core.adb
│   ├── opencv-core-*_access.*        # typed access
│   ├── opencv-core-*_row_access.*    # copied row access
│   ├── opencv-core-*_vec3*           # predefined Vec3 support
│   ├── opencv-core-fixed_matrices.ads
│   ├── opencv-core-vectors.ads
│   └── internal/
│       └── opencv-internal-c_api.ads
└── tests/
    ├── alire.toml
    └── src/
        ├── mat_basic_tests.*
        ├── mat_access_tests.*
        ├── mat_view_tests.*
        ├── mat_conversion_tests.*
        ├── mat_arithmetic_tests.*
        ├── mat_channel_tests.*
        ├── mat_mask_tests.*
        ├── mat_reduction_tests.*
        └── mat_transform_tests.*
```

---

# Development approach

New features generally follow this sequence:

1. Inspect authoritative OpenCV declaration/source and exact semantics.
2. Inspect existing repository conventions.
3. Decide the thick Ada API.
4. Add only the required stable C ABI surface.
5. Implement the C++ shim with exception containment.
6. Add/update thin Ada imports.
7. Implement the thick Ada operation.
8. Add focused AUnit coverage.
9. Include non-contiguous Mat/Region cases where applicable.
10. Include ownership/independence/view tests where applicable.
11. Include invalid-input and boundary behavior.
12. Format modified Ada sources with GNATformat.
13. Clean-build the main crate.
14. Build and run the tests crate.
15. Run `git diff --check`.
16. Inspect the final diff before committing.

Important public API decisions should be made deliberately rather than discovered accidentally through a mechanical translation of the C++ API.

---

# Testing expectations for new operations

Depending on the operation, tests should consider:

- ordinary UInt8 behavior;
- Float32 behavior;
- signed integer behavior where relevant;
- integer saturation/rounding;
- Vec3 / multi-channel behavior;
- empty Mat behavior;
- non-contiguous Region input;
- shallow versus independent storage;
- source lifetime;
- arbitrary Ada array lower bounds for collection APIs;
- mismatched rows;
- mismatched columns;
- mismatched depth;
- mismatched channel count;
- mask type/dimensions;
- NaN and infinity where OpenCV can naturally produce them;
- exact OpenCV boundary semantics.

Installed OpenCV declarations/source are authoritative. Tests should not assume C++ behavior from memory when it can be inspected directly.

---

# Contributing

Contributions should preserve the project's central abstraction boundary:

```text
idiomatic Ada
    ↓
thin fixed ABI
    ↓
C++ shim
    ↓
OpenCV
```

Please avoid:

- exposing `Interfaces.C` types in the normal public API;
- passing C++ objects through Ada;
- reproducing C++ overloads without considering Ada ergonomics;
- adding raw pointers to the public API;
- silently changing ownership semantics;
- introducing test dependencies into the public library crate;
- manually reimplementing OpenCV operations in Ada when a corresponding OpenCV Core primitive exists.

Small, vertically complete features with focused tests are preferred over large partially integrated batches.

---

# Versioning

The crate is currently:

```text
0.1.0-dev
```

The API should be considered experimental until a 1.0 release.

Before 1.0, names and overloads may evolve as linear algebra, broader typed access, N-dimensional arrays, and persistence force additional design decisions.

---

# License

`opencvcore_ada` is licensed under the **Apache License 2.0**.

See the repository license file for the full license text.

OpenCV is a separate project with its own license and copyright holders.

---

## Summary

`opencvcore_ada` now provides a substantial, tested Ada foundation for OpenCV Core:

- controlled `Mat` ownership and views;
- typed UInt8/Float32 and Vec3 access;
- safe bulk row access;
- conversion, normalization, and arithmetic;
- a complete basic mask/selection workflow;
- complete planned channel manipulation;
- major 2-D matrix transformations and concatenation;
- diagonal views and diagonal-matrix construction;
- scalar and axis reductions;
- stable error-isolated C++ interoperability.

The project remains pre-1.0, but much of the architectural work is established. The next phase is primarily about broadening Core coverage while preserving the same ownership, safety, ABI, and testing standards.