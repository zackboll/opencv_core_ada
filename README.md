# opencvcore_ada

A thick, idiomatic Ada binding for the **OpenCV Core** module.

`opencvcore_ada` provides an Ada-facing API over OpenCV Core data structures,
array operations, numerical routines, and linear algebra without exposing the
C++ ABI to Ada applications. The binding uses a stable C ABI shim between Ada
and C++, preserves OpenCV ownership and numerical behavior where practical, and
represents common OpenCV concepts with Ada controlled types, enums, records,
overloads, generics, ranges, and exceptions.

> **Project status:** active development, `0.1.0-dev`.
>
> **Current test baseline:** **543 registered AUnit tests** across 10 test suites
> on the current `main` development state.
>
> **Current scope:** substantial 2-D dense `Mat` coverage, including views,
> typed access, conversion and arithmetic, masks, channel manipulation,
> element-wise mathematics, reductions/statistics, sorting, matrix
> rearrangement, linear algebra, and per-element vector transforms.
>
> The API is pre-1.0 and may still evolve as larger Core families are added.

## Contents

- [Goals and scope](#goals-and-scope)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Building](#building)
- [Running the tests](#running-the-tests)
- [Quick start](#quick-start)
- [Ownership, views, and copies](#ownership-views-and-copies)
- [Typed access](#typed-access)
- [Public API overview](#public-api-overview)
- [Linear algebra examples](#linear-algebra-examples)
- [Current milestone status](#current-milestone-status)
- [Known limitations](#known-limitations)
- [Project layout](#project-layout)
- [Development approach](#development-approach)
- [Contributing](#contributing)
- [Versioning](#versioning)
- [License](#license)

---

## Goals and scope

The project is designed around several principles:

- Provide an **idiomatic Ada API**, rather than mechanically translating the
  C++ interface.
- Keep C++ implementation details behind a stable **`extern "C"` ABI**.
- Never expose `cv::Mat`, C++ references, templates, STL containers,
  exceptions, or `std::string` directly across the ABI.
- Represent OpenCV resources with Ada controlled types and preserve OpenCV
  reference-counted ownership semantics.
- Use strong Ada types, enums, records, overloads, discriminated result types,
  generics, ranges, and exceptions where they improve safety and readability.
- Preserve important OpenCV numerical behavior, including saturation,
  rounding, non-contiguous matrices, masks, and IEEE floating-point edge
  cases.
- Build features vertically:

  ```text
  public Ada API -> thin Ada interop -> C ABI/C++ shim -> OpenCV -> AUnit tests
  ```

- Keep the public library independent from test/development dependencies such
  as AUnit, GNATprove, and GNATcov.
- Prefer explicit Ada abstractions over C++-specific encodings such as integer
  mode constants, output-parameter APIs, and STL collections.
- Use authoritative OpenCV declarations and source when exact behavior differs
  from what a high-level description might suggest.

This crate is intentionally focused on **OpenCV Core**. Higher-level modules
such as `imgproc`, `imgcodecs`, `highgui`, `videoio`, `features2d`, `calib3d`,
and `dnn` are expected to live in separate Ada crates that depend on
`opencvcore_ada`.

Literal symbol-for-symbol coverage of every internal implementation surface
under OpenCV Core is not a goal. The target is broad coverage of portable,
user-facing Core functionality with a coherent Ada design.

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
| fixed ABI types           |
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

- exports only C-compatible functions;
- uses opaque handles for `cv::Mat`;
- uses fixed-width integers and simple C-compatible records;
- validates ABI-level arguments;
- catches OpenCV, standard C++, and unknown exceptions;
- translates failures into stable status codes plus diagnostic text;
- never allows C++ exceptions to cross into Ada;
- never passes C++ objects, references, STL types, or templates across the
  boundary.

C++ containers may be used **inside** the shim when an OpenCV API requires
them, but they do not cross the ABI.

### Error handling

Public callers see Ada exceptions rather than C-style status codes.

The usual path is:

1. the thick Ada layer validates public preconditions where practical;
2. the C++ shim validates ABI-level arguments;
3. OpenCV is called inside exception containment;
4. C++ exceptions are translated to a stable internal status/diagnostic;
5. the thick Ada layer raises `OpenCV_Error` or returns an idiomatic result
   type where failure is part of the operation's normal meaning.

For example, LU inversion and solving use discriminated Ada results so a
singular matrix can be reported without inventing a placeholder output.

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

OpenCV include and library paths are discovered by:

```text
scripts/configure_opencv.sh
```

using the `opencv4` pkg-config package.

The binding currently targets the OpenCV 4.x Core API, with feature behavior
checked against OpenCV 4.10 where the implementation has relevant
version-specific details. Compatibility across every OpenCV 4.x release has
not yet been formally characterized.

---

## Building

Clone the repository and build with Alire:

```sh
git clone https://github.com/zackboll/opencvcore_ada.git
cd opencvcore_ada
alr build
```

The Alire pre-build action runs:

```text
scripts/configure_opencv.sh
```

which uses `pkg-config` to generate the local OpenCV GPR configuration.

If configuration fails, verify that OpenCV is visible:

```sh
pkg-config --exists opencv4
```

The library supports normal GPR library kinds through
`OPENCVCORE_ADA_LIBRARY_TYPE` / `LIBRARY_TYPE`:

```text
static        (default)
static-pic
relocatable
```

---

## Running the tests

Tests are maintained in a separate Alire crate under `tests/`:

```sh
alr -C tests build
alr -C tests run
```

The test crate depends on:

- AUnit `^26.0.0`;
- the local `opencvcore_ada` crate;
- GNATprove `^16.1.0`;
- GNATcov `^26.2.1`.

These development dependencies are intentionally **not** dependencies of the
public library crate.

The current test tree contains 10 suites:

- `Mat_Basic_Tests`
- `Mat_Access_Tests`
- `Mat_View_Tests`
- `Mat_Conversion_Tests`
- `Mat_Arithmetic_Tests`
- `Mat_Channel_Tests`
- `Mat_Mask_Tests`
- `Mat_Reduction_Tests`
- `Mat_Range_Tests`
- `Mat_Transform_Tests`

Current registration baseline:

```text
543 AUnit tests
```

New operations routinely test:

- ordinary behavior;
- invalid input;
- shape/depth/channel compatibility;
- empty Mats;
- non-contiguous Regions;
- shallow versus independent ownership;
- source lifetime;
- OpenCV-specific numerical boundary behavior.

---

# Quick start

## Create and access a matrix

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
     (Image,
      Row    => 10,
      Column => 20,
      Value  => 255);

   Value :=
     OpenCV.Core.UInt8_Access.Get
       (Image,
        Row    => 10,
        Column => 20);

   Ada.Text_IO.Put_Line (UInt8_Value'Image (Value));
end Example;
```

## Create from `Size`

```ada
Image : Mat :=
  Create
    (Dimensions   => (Width => 640, Height => 480),
     Element_Type => (Depth => Float32, Channels => 1));

Dims : constant Size := Image.Dimensions;
```

`Dimensions.Width` corresponds to `Columns`; `Dimensions.Height` corresponds
to `Rows`.

## Use a Region

```ada
ROI : Mat :=
  Image.Region
    ((X      => 100,
      Y      => 50,
      Width  => 200,
      Height => 100));
```

A Region has its own `Mat` header but shares storage with its parent.

---

# Ownership, views, and copies

`OpenCV.Core.Mat` is a tagged private Ada controlled type.

## Assignment is shallow

Ordinary Ada assignment follows OpenCV's reference-counted `cv::Mat`
semantics:

```ada
B := A;
```

`B` receives a distinct matrix header sharing the same underlying pixel
storage with `A`.

Mutating shared storage through either alias is visible through the other.

## `Clone` is deep

Use `Clone` when independent storage is required:

```ada
B := A.Clone;
```

## Shared-storage views

The following operations create distinct headers sharing storage where OpenCV
defines a no-copy view:

- `Region`
- `Row_View`
- `Column_View`
- `Reshape`
- `Diagonal_View`

Views remain valid after the source header is finalized because OpenCV
reference counting retains the underlying allocation.

## Independent-result operations

Operations that compute new values generally return independently owned
storage. Examples include:

- arithmetic;
- `Convert_To`;
- `Convert_Scale_Abs`;
- element-wise mathematical functions;
- `Transpose`, `Flip`, `Rotate`, `Repeat`;
- sorting;
- `Copy_Make_Border`;
- channel extraction/splitting/merging;
- concatenation;
- `Diagonal_Matrix`;
- matrix multiplication;
- transposed products;
- per-element transforms;
- reductions that return a `Mat`.

Mutating an independent result does not mutate its inputs.

---

# Typed access

The public depth model includes:

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

Direct typed element and copied-row access currently focuses on **UInt8** and
**Float32**.

## Scalar access

Available scalar typed access includes:

- UInt8 `Get` / `Set`;
- Float32 `Get` / `Set`;
- Float32 non-finite classification.

## Vec3 access

Three-component UInt8 and Float32 vector packages and accessors are provided:

```ada
with OpenCV.Core.UInt8_Vec3;
with OpenCV.Core.UInt8_Vec3_Access;

Pixel : OpenCV.Core.UInt8_Vec3.Vector;

OpenCV.Core.UInt8_Vec3_Access.Set
  (Image,
   Row    => 0,
   Column => 0,
   Value  => (10, 20, 30));

Pixel := OpenCV.Core.UInt8_Vec3_Access.Get (Image, 0, 0);
```

The predefined Vec3 types are component-oriented. They do not impose RGB,
BGR, or another semantic interpretation.

## Copied row access

Safe copied-row APIs avoid exposing raw OpenCV data pointers in public Ada
code.

Current row-access families include:

- UInt8 single-channel;
- Float32 single-channel;
- UInt8 Vec3;
- Float32 Vec3.

Ada arrays may use arbitrary lower bounds; their ordered values map to matrix
columns `0 .. Columns - 1`.

## Generic value types

A generic zero-based vector abstraction is provided:

```ada
generic
   type Element_Type is private;
   Length : Positive;
package OpenCV.Core.Vectors;
```

A pure-Ada fixed-matrix generic is also provided:

```ada
generic
   type Element_Type is private;
   Row_Count : Positive;
   Column_Count : Positive;
package OpenCV.Core.Fixed_Matrices;
```

A predefined Float32 3x3 fixed matrix and copy conversion to/from `Mat` are
available. The C++ `cv::Matx` object itself is not exposed through the ABI.

---

# Public API overview

This section summarizes the current public `OpenCV.Core` surface. Exact
depth/channel restrictions are documented on individual declarations and
covered by tests.

## Core types and result types

Public abstractions include:

- `Mat`
- `Mat_Type`
- `Depth_Type`
- `Channel_Count`
- `Mat_Size`
- `Size`
- `Point`
- `Point_Array`
- `Rect`
- `Index_Range`
- `Scalar`
- `Mat_Array`
- `Min_Max_Result`
- `Mean_Std_Dev_Result`
- `Range_Check_Result`
- `Inversion_Result`
- `Solve_Result`
- `Polar_Coordinates`
- `Cartesian_Coordinates`
- channel-routing records and arrays.

Strong enums are used for:

- normalization;
- comparison;
- flipping;
- border modes;
- rotation;
- reduction axes and kinds;
- angle units;
- sorting axes/orders;
- transposed-product orientation;
- symmetry source.

## Creation, shape, and metadata

Creation:

- `Create (Rows, Columns, Element_Type)`
- `Create (Dimensions, Element_Type)`
- `Diagonal_Matrix`

Metadata:

- `Is_Empty`
- `Rows`
- `Columns`
- `Dimensions`
- `Channels`
- `Depth`
- `Total`
- `Element_Size`
- `Channel_Size`
- `Is_Continuous`
- `Is_Submatrix`

## Views and copies

Shared-storage operations:

- `Region`
- `Row_View`
- `Column_View`
- `Reshape`
- `Diagonal_View`

Copy/independent operations:

- `Clone`
- `Copy_To`
- masked `Copy_To`

`Index_Range` uses half-open semantics:

```text
Start <= index < Stop
```

## Conversion and element-wise mathematics

Implemented conversions and mapping:

- `Convert_To`
- `Convert_Scale_Abs`
- `Apply_LUT`
- `Normalize`

Implemented mathematical functions:

- `Sqrt`
- `Exp`
- `Log`
- `Pow`
- `Magnitude`
- `Phase`
- `Cart_To_Polar`
- `Polar_To_Cart`

`Magnitude`, `Phase`, and the polar/cartesian routines operate component-wise
on matching Float32/Float64 Mats and preserve multi-channel layouts where
supported.

`Cart_To_Polar` and `Polar_To_Cart` return idiomatic Ada records containing
independently owned Mats rather than exposing C++ output parameters.

## Arithmetic

Current explicit Mat/Mat operations include:

- `Add`
- `Subtract`
- `Multiply` — element-wise
- `Divide` — element-wise
- `Abs_Diff`
- `Minimum`
- `Maximum`
- `Add_Weighted`
- `Scale_Add`

These are distinct from algebraic `Matrix_Multiply`.

The first-generation arithmetic API intentionally favors explicit operations
with controlled compatibility rules rather than reproducing every C++
operator/overload.

## Masks and selection

Mask-producing/selection operations include:

- `In_Range`
- `Compare`
- `Count_Non_Zero`
- `Has_Non_Zero`
- `Find_Non_Zero`

Masked consumers include:

- `Copy_To`
- `Set_To`
- bitwise operations;
- `Mean`
- `Mean_Std_Dev`
- `Norm`
- `Min_Max_Loc`

The common mask contract is an UInt8, single-channel Mat with the same 2-D
shape as the source. Any nonzero mask value selects the complete element.

## Bitwise operations

Available unmasked and masked forms include:

- `Bitwise_And`
- `Bitwise_Or`
- `Bitwise_Xor`
- `Bitwise_Not`

OpenCV's stored-bit behavior is preserved for floating-point Mats.

## Channel manipulation

The public channel workflow includes:

- `Split`
- `Merge`
- `Extract_Channel`
- `Insert_Channel`
- `Mix_Channels`
- `Mat_Array`
- `Channel_Route`
- `Channel_Route_Array`
- explicit zero-fill routing.

Collection operations honor Ada array iteration order rather than assuming a
zero lower bound.

## Matrix layout and rearrangement

Implemented operations include:

- `Transpose`
- `Flip`
- `Rotate`
- `Repeat`
- `HConcat`
- `VConcat`
- `Diagonal_View`
- `Diagonal_Matrix`
- `Copy_Make_Border`

`Copy_Make_Border` exposes typed Ada border kinds and supports Region-isolation
semantics without leaking OpenCV integer flags.

## Sorting

Implemented sorting operations:

- `Sort`
- `Sort_Indices`

Axes and order are strong Ada enums:

```text
Each_Row
Each_Column

Ascending
Descending
```

`Sort_Indices` returns zero-based original row/column indices in an
independently owned Int32 Mat.

## Reductions and statistics

Implemented scalar/statistical operations include:

- `Sum`
- `Trace`
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
- `Dot_Product`
- `Mahalanobis_Distance`

Axis-based `Reduce` supports:

- `Sum`
- `Average`
- `Maximum`
- `Minimum`
- `Sum_Of_Squares`

with an overload for explicit output depth.

## Range and non-finite handling

Implemented validation/mutation operations:

- `Check_Range`
- bounded `Check_Range`
- `Patch_NaNs`

`Check_Range` returns a discriminated `Range_Check_Result`. When invalid,
`First_Invalid` uses:

```text
Point.X = column
Point.Y = row
```

and Region coordinates are relative to the Region.

`Patch_NaNs` is an in-place Float32 operation matching OpenCV's depth
restriction. It patches NaNs but does not remove infinities.

## Matrix initialization and symmetry

Implemented in-place operations:

- `Set_Identity`
- `Complete_Symmetry`

`Set_Identity` works for rectangular Mats and preserves their shape and type.

`Complete_Symmetry` uses `Symmetry_Source` to express whether the upper or
lower triangle is authoritative instead of exposing OpenCV's Boolean flag.

## Linear algebra

Current linear-algebra coverage includes:

- `Trace`
- `Determinant`
- `Invert`
- `Solve`
- `Dot_Product`
- `Mahalanobis_Distance`
- `Matrix_Multiply`
- `Matrix_Multiply_Add`
- `Transposed_Product`
- centered `Transposed_Product`
- `Set_Identity`
- `Complete_Symmetry`

### Determinant

`Determinant` supports non-empty, square, single-channel Float32/Float64 Mats.

### Invert

`Invert` currently represents ordinary **LU inversion** only.

```ada
Result : Inversion_Result := Matrix.Invert;

if Result.Invertible then
   --  Result.Inverse is available here.
   null;
end if;
```

A singular matrix returns `Invertible => False`; singularity is not represented
as an exception.

### Solve

`Solve` currently represents **DECOMP_LU** solving only.

```ada
Result : Solve_Result := A.Solve (B);

if Result.Solved then
   --  Result.Solution is available here.
   null;
end if;
```

A singular coefficient matrix returns `Solved => False`.

### Matrix multiplication

`Matrix_Multiply` performs algebraic multiplication through OpenCV GEMM
semantics:

```ada
C : Mat := Matrix_Multiply (A, B);
```

It is deliberately separate from element-wise `Multiply`.

Float32/Float64 single-channel real matrices are supported, along with
two-channel complex matrices where OpenCV treats channel 0 as real and
channel 1 as imaginary.

`Matrix_Multiply_Add` exposes:

```text
Product_Scale * Left * Right + Addend_Scale * Addend
```

without exposing raw GEMM bit flags.

### Transposed products

`Transposed_Product` supports both orientations:

```text
Scale * Self'T * Self
Scale * Self * Self'T
```

and centered forms:

```text
Scale * (Self - Offset)'T * (Self - Offset)
Scale * (Self - Offset) * (Self - Offset)'T
```

The centered overloads preserve OpenCV's useful offset broadcasting while
presenting it with an Ada-friendly `Offset` formal.

### Dot product

`Dot_Product` is the scalar sum of corresponding element/channel products. It
is not matrix multiplication and C2 data is not treated as a complex inner
product.

### Mahalanobis distance

`Mahalanobis_Distance` treats inputs as mathematical 1-D, single-channel
Float32/Float64 row or column vectors:

```ada
Distance : Long_Float :=
  First.Mahalanobis_Distance
    (Other              => Second,
     Inverse_Covariance => Inverse_Covariance);
```

The inverse covariance Mat must have matching depth and exact `N x N`
dimensions.

## Per-element vector transforms

`Transform` applies an MxN linear or Mx(N+1) affine coefficient matrix to the
channel vector at every Mat element:

```text
Result(I) = Coefficients * Self(I)
```

or:

```text
Result(I) = Coefficients * [Self(I); 1]
```

This is a channel/vector transform at the same spatial location; it does not
move pixels.

`Perspective_Transform` applies homogeneous 2-D/3-D vector transformations:

- C2 source -> 3x3 transform matrix
- C3 source -> 4x4 transform matrix

It transforms vector coordinates at each element and is intentionally
distinct from image-warping APIs in `imgproc`.

---

# Linear algebra examples

## Dot product

```ada
Value : Long_Float := Left.Dot_Product (Right);
```

## Algebraic matrix multiplication

```ada
Product : Mat := Matrix_Multiply (Left, Right);
```

## Weighted matrix multiply-add

```ada
Result : Mat :=
  Matrix_Multiply_Add
    (Left          => A,
     Right         => B,
     Addend        => C,
     Product_Scale => 2.0,
     Addend_Scale  => 0.5);
```

## Centered transposed product

```ada
Centered : Mat :=
  Samples.Transposed_Product
    (Offset => Mean,
     Order  => Transpose_Times_Self,
     Scale  => 1.0);
```

This is useful as a building block for covariance-like calculations while
remaining a general transposed-product API.

## Mahalanobis distance

```ada
Distance : Long_Float :=
  Sample_A.Mahalanobis_Distance
    (Other              => Sample_B,
     Inverse_Covariance => Inverse_Covariance);
```

---

# Current milestone status

The roadmap tracks portable, user-facing OpenCV Core functionality rather than
every internal/backend symbol.

## Milestone 0 — binding foundation

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
- [x] bulk copied-row access
- [x] generic vector abstraction
- [x] generic fixed-matrix abstraction
- [x] common mask contract
- [x] separate development/test crate
- [x] vertically integrated AUnit workflow

**Status: complete as the current architectural foundation.**

## Milestone 1 — masks and selection

- [x] `In_Range`
- [x] `Compare`
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

**Status: complete for the planned basic mask production/consumption
workflow.**

## Milestone 2 — channel manipulation

- [x] `Mat_Array`
- [x] `Split`
- [x] `Merge`
- [x] `Extract_Channel`
- [x] `Insert_Channel`
- [x] `Channel_Route` / `Channel_Route_Array`
- [x] explicit zero-fill routing
- [x] `Mix_Channels`

**Status: complete for the planned channel-manipulation workflow.**

## Milestone 3 — 2-D layout and rearrangement

- [x] `Transpose`
- [x] `Flip`
- [x] `Rotate`
- [x] `Repeat`
- [x] `HConcat`
- [x] `VConcat`
- [x] `Diagonal_View`
- [x] `Diagonal_Matrix`
- [x] `Copy_Make_Border`
- [ ] additional stride/step metadata where it provides public value
- [ ] ROI location/adjustment helpers if a clear Ada use case emerges

N-dimensional variants remain deferred until an N-D public `Mat` model is
designed.

**Status: planned 2-D rearrangement coverage is largely complete.**

## Milestone 4 — everyday arithmetic

Implemented:

- [x] Mat/Mat `Add`
- [x] Mat/Mat `Subtract`
- [x] Mat/Mat element-wise `Multiply`
- [x] Mat/Mat element-wise `Divide`
- [x] Mat/Mat `Abs_Diff`
- [x] `Minimum`
- [x] `Maximum`
- [x] `Add_Weighted`
- [x] `Scale_Add`
- [x] `Convert_To`
- [x] `Convert_Scale_Abs`
- [x] `Normalize`
- [x] `Apply_LUT`

Potential future expansion:

- [ ] Mat/Scalar arithmetic families
- [ ] Scalar/Mat asymmetric subtraction/division
- [ ] Scalar bitwise variants
- [ ] masked arithmetic
- [ ] explicit result depth where OpenCV supports it
- [ ] deliberate mixed-depth arithmetic policy
- [ ] configurable scale for additional multiply/divide forms

Overload growth should remain deliberate rather than mechanically mirroring
the C++ API.

## Milestone 5 — element-wise mathematics and coordinates

- [x] `Sqrt`
- [x] `Exp`
- [x] `Log`
- [x] `Pow`
- [x] `Magnitude`
- [x] `Phase`
- [x] `Cart_To_Polar`
- [x] `Polar_To_Cart`

**Status: the planned first mathematical-function family is complete.**

## Milestone 6 — reductions, statistics, and range handling

Implemented:

- [x] `Sum`
- [x] `Trace`
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
- [x] `Reduce` with Sum/Average/Maximum/Minimum/Sum_Of_Squares
- [x] explicit `Reduce` output depth
- [x] `Check_Range`
- [x] `Patch_NaNs`
- [x] `Dot_Product`
- [x] `Mahalanobis_Distance`

Remaining candidates:

- [ ] two-Mat norm / distance overloads
- [ ] relative norm support
- [ ] additional norm kinds where useful
- [ ] `Min_Max_Idx`
- [ ] arg-min / arg-max reduction APIs
- [ ] PSNR
- [ ] covariance matrix + mean result

## Milestone 7 — linear algebra

Implemented:

- [x] `Dot_Product`
- [x] `Trace`
- [x] `Determinant`
- [x] LU `Invert`
- [x] LU `Solve`
- [x] algebraic `Matrix_Multiply`
- [x] weighted `Matrix_Multiply_Add`
- [x] uncentered `Transposed_Product`
- [x] centered `Transposed_Product`
- [x] `Set_Identity`
- [x] `Complete_Symmetry`
- [x] `Mahalanobis_Distance`

Not yet implemented on the documented `main` state:

- [ ] 3-D vector cross product
- [ ] covariance matrix
- [ ] eigenvalues / eigenvectors
- [ ] non-symmetric eigen decomposition
- [ ] SVD
- [ ] PCA
- [ ] LDA
- [ ] cubic solving
- [ ] polynomial solving

Some of these will require new Ada result records containing multiple owned
Mats rather than direct translations of C++ output parameters.

## Milestone 8 — vector transforms

- [x] `Transform` for per-element linear/affine channel vectors
- [x] `Perspective_Transform` for C2/C3 floating vectors

Image resampling/warping is intentionally outside this Core crate and belongs
in an `imgproc` binding.

## Milestone 9 — spectral operations

Future scope:

- [ ] DFT
- [ ] inverse DFT
- [ ] DCT
- [ ] inverse DCT
- [ ] spectrum multiplication
- [ ] optimal DFT size

OpenCV flag sets should be represented with strong Ada options rather than raw
C++ constants.

## Milestone 10 — sorting, RNG, and algorithms

Implemented:

- [x] `Sort`
- [x] `Sort_Indices`

Future candidates:

- [ ] random generator abstraction
- [ ] uniform random fill
- [ ] normal random fill
- [ ] random shuffle
- [ ] random seed support
- [ ] batch distance
- [ ] K-means
- [ ] partitioning if useful

The overloaded C++ RNG API should be redesigned as an Ada-friendly
abstraction rather than mechanically exposed.

## Milestone 11 — persistence and advanced structures

Potential later scope:

- [ ] XML/YAML/JSON persistence
- [ ] `FileStorage`
- [ ] `FileNode`
- [ ] Mat serialization
- [ ] broader predefined Vec/Matx families
- [ ] typed access for remaining depths
- [ ] N-dimensional `Mat`
- [ ] N-dimensional reshape/views
- [ ] `SparseMat`
- [ ] external/shared-buffer Mat construction
- [ ] `UMat` if a concrete use case requires it
- [ ] async Core APIs if a concrete use case requires them

These areas require more substantial architectural decisions and are
intentionally later.

---

# Known limitations

Current intentional limitations include:

1. **The public dense `Mat` model is primarily 2-D.**  
   N-dimensional Mat support has not yet been designed as an idiomatic Ada
   abstraction.

2. **No public `SparseMat` or `UMat` layer.**

3. **Typed direct access does not cover every depth.**  
   Public typed element/row access currently concentrates on UInt8 and
   Float32, including Vec3 forms.

4. **Scalar-valued APIs represent at most four components.**  
   Operations returning `Scalar` validate channel limits instead of silently
   losing data.

5. **OpenCV depth restrictions are preserved.**  
   For example, several mathematical/sorting operations reject Float16, while
   other APIs such as `Set_Identity` can accept it.

6. **Arithmetic overloads are intentionally conservative.**  
   The public API does not yet reproduce the large Mat/Scalar, mixed-depth,
   and masked overload matrix from C++.

7. **`Invert` and `Solve` currently expose LU behavior only.**  
   SVD/QR/Cholesky/eigen decomposition modes need deliberate Ada designs.

8. **No general `cv::MatExpr` equivalent.**  
   The Ada interface uses explicit operations.

9. **No raw public pixel pointers.**  
   Safe typed access and copied-row APIs are preferred over leaking OpenCV
   memory-layout details.

10. **No public raw OpenCV flag integers.**  
    Current wrapped modes use strong Ada enums or deliberately narrower APIs.

11. **OpenCV 4.x compatibility is not characterized release by release.**

12. **The API is pre-1.0.**  
    Public signatures may evolve as decomposition, spectral, N-D, and
    persistence families are added.

---

# Project layout

```text
opencvcore_ada/
├── .clinerules/
├── alire.toml
├── opencvcore_ada.gpr
├── LICENSE
├── README.md
├── config/
│   ├── opencvcore_ada_config.gpr
│   └── opencvcore_ada_opencv.gpr        # generated/configured locally
├── cpp/
│   ├── opencv_core_shim.cpp
│   └── opencv_core_shim.h
├── scripts/
│   └── configure_opencv.sh
├── src/
│   ├── opencv-core.ads
│   ├── opencv-core.adb
│   ├── opencv-core-*_access.*           # typed element access
│   ├── opencv-core-*_row_access.*       # copied row access
│   ├── opencv-core-*_vec3*              # predefined Vec3 support
│   ├── opencv-core-vectors.ads
│   ├── opencv-core-fixed_matrices.ads
│   ├── opencv-core-float32_matx3x3.ads
│   ├── opencv-core-float32_matx3x3_conversions.*
│   └── internal/
│       └── opencv-internal-c_api.ads
└── tests/
    ├── alire.toml
    ├── tests.gpr
    └── src/
        ├── tests.adb
        ├── mat_tests.*
        ├── mat_basic_tests.*
        ├── mat_access_tests.*
        ├── mat_view_tests.*
        ├── mat_conversion_tests.*
        ├── mat_arithmetic_tests.*
        ├── mat_channel_tests.*
        ├── mat_mask_tests.*
        ├── mat_reduction_tests.*
        ├── mat_range_tests.*
        └── mat_transform_tests.*
```

---

# Development approach

New features generally follow this sequence:

1. Inspect authoritative OpenCV declarations/source and exact semantics.
2. Inspect existing repository conventions.
3. Decide the thick Ada API and deliberate restrictions.
4. Add only the required stable C ABI surface.
5. Implement the C++ shim with exception containment and failure-atomic output
   handling.
6. Add/update the thin Ada import.
7. Implement the thick Ada operation.
8. Add focused AUnit coverage.
9. Include non-contiguous Region cases where applicable.
10. Include ownership/independence/view lifetime tests where applicable.
11. Include invalid-input and boundary behavior.
12. Format modified Ada sources with the repository's Ada formatting workflow.
13. Build the public crate.
14. Build and run the complete tests crate.
15. Inspect the final diff and keep it focused.

Important public API decisions should be made deliberately rather than
discovered accidentally through a mechanical translation of the C++ API.

## Development dependency policy

Testing, proof, coverage, formatting, and other development-only tools must not
be added as dependencies of the public `opencvcore_ada` crate merely to make
them available to development workflows.

Use the separate `tests` Alire environment for development tooling that belongs
there.

---

# Testing expectations for new operations

Depending on the operation, tests should consider:

- ordinary UInt8 behavior;
- Float32 behavior;
- Float64 behavior where supported;
- signed integer behavior;
- integer saturation and rounding;
- Vec3/multi-channel behavior;
- empty Mat behavior;
- non-contiguous Region input;
- shallow aliases versus independent storage;
- source lifetime;
- arbitrary Ada array lower bounds for collection APIs;
- mismatched rows/columns;
- mismatched depth/channel count;
- mask type and dimensions;
- NaN and infinity where OpenCV naturally produces them;
- exact OpenCV boundary semantics;
- result-handle failure atomicity for newly allocated Mats.

Installed/target OpenCV declarations and source are authoritative. Tests should
not assume C++ behavior from memory when it can be inspected directly.

---

# Contributing

Contributions should preserve the central abstraction boundary:

```text
idiomatic Ada
    |
    v
thin fixed ABI
    |
    v
C++ shim
    |
    v
OpenCV Core
```

Please avoid:

- exposing `Interfaces.C` types in the normal public API;
- passing C++ objects through Ada;
- reproducing C++ overloads without considering Ada ergonomics;
- exposing raw OpenCV integer mode flags when a strong Ada type is suitable;
- adding raw pointers to the public API;
- silently changing ownership semantics;
- introducing test/development dependencies into the public library crate;
- manually reimplementing OpenCV algorithms when a corresponding Core
  primitive exists;
- broad unrelated cleanup in otherwise focused feature commits.

Small, vertically complete features with focused tests are preferred over
large partially integrated batches.

---

# Versioning

The crate is currently:

```text
0.1.0-dev
```

The API should be considered experimental until a 1.0 release.

Before 1.0, names and overloads may evolve as decomposition APIs, covariance
and PCA, spectral operations, broader typed access, N-dimensional arrays, and
persistence reveal better Ada abstractions.

---

# License

`opencvcore_ada` is licensed under the **Apache License 2.0**.

See `LICENSE` for the full license text.

OpenCV is a separate project with its own license and copyright holders.

---

## Summary

`opencvcore_ada` now provides a substantial tested Ada foundation for OpenCV
Core, including:

- controlled `Mat` ownership and shared-storage views;
- typed UInt8/Float32 and Vec3 access;
- safe copied-row access;
- conversions and element-wise mathematics;
- arithmetic and bitwise operations;
- mask production and consumption;
- channel splitting/merging/routing;
- 2-D layout, border, concatenation, and sorting operations;
- scalar and axis reductions;
- range checking and NaN patching;
- determinant, LU inversion and solving;
- real/complex matrix multiplication;
- centered and uncentered transposed products;
- dot product and Mahalanobis distance;
- per-element linear/affine and perspective vector transforms;
- a stable error-isolated C++ interoperability layer.

The cross-language architecture is established. Much of the remaining work is
coverage expansion: covariance/decompositions, spectral operations, RNG and
algorithms, broader typed access, persistence, and eventually N-dimensional
and advanced matrix structures.
