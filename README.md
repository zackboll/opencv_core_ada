# opencv_core_ada

A thick, idiomatic Ada binding for the **OpenCV Core** module.

`opencvcore_ada` provides an Ada-facing API over OpenCV Core data structures,
array operations, numerical routines, linear algebra, and persistence without
exposing the C++ ABI to Ada applications. The binding uses a stable C ABI shim
between Ada and C++, preserves OpenCV ownership and numerical behavior where
practical, and represents common OpenCV concepts with Ada controlled types,
strong enums, records, overloads, generics, ranges, discriminated results, and
exceptions.

> **Project status:** active development, `0.1.0-dev`.
>
> **Current verification baseline:** **683 registered AUnit tests** across
> **11 test suites**, warning-free builds enforced with `-Werror`, plus targeted
> **SPARK / GNATprove** proof for signed-32-bit dimensional product safety.
>
> **Current scope:** substantial 2-D dense `Mat` coverage, including ownership
> and views, typed access, conversion and arithmetic, masks, channel
> manipulation, element-wise mathematics, reductions/statistics, sorting,
> matrix rearrangement, covariance, symmetric eigen decomposition, PCA,
> compact SVD, SVD back-substitution, pseudoinverse, reciprocal condition
> number, vector transforms, and XML/YAML/JSON persistence to disk or memory.
>
> The API is pre-1.0 and may still evolve as larger OpenCV Core families are
> added.

## Contents

- [Goals and scope](#goals-and-scope)
- [Architecture](#architecture)
- [Safety and validation boundary](#safety-and-validation-boundary)
- [Requirements](#requirements)
- [Building](#building)
- [Running the tests](#running-the-tests)
- [SPARK and GNATprove](#spark-and-gnatprove)
- [Quick start](#quick-start)
- [Ownership, views, and copies](#ownership-views-and-copies)
- [Typed access](#typed-access)
- [Public API overview](#public-api-overview)
- [Linear algebra and decomposition](#linear-algebra-and-decomposition)
- [Persistence](#persistence)
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
- Never expose `cv::Mat`, `cv::FileStorage`, C++ references, templates, STL
  containers, exceptions, or `std::string` directly across the ABI.
- Represent OpenCV resources with Ada controlled types and preserve OpenCV
  reference-counted ownership semantics.
- Use strong Ada types, enums, records, overloads, discriminated result types,
  generics, ranges, and exceptions where they improve safety and readability.
- Preserve important OpenCV numerical behavior, including saturation,
  rounding, non-contiguous matrices, masks, IEEE floating-point edge cases,
  and source-version-specific behavior where it materially affects safety or
  results.
- Build features vertically:

  ```text
  public Ada API -> thin Ada interop -> C ABI/C++ shim -> OpenCV -> AUnit tests
  ```

- Keep the public library independent from test/development dependencies such
  as AUnit, GNATprove, and GNATcov.
- Use SPARK selectively for small pure-Ada safety properties where formal proof
  adds value, without attempting to prove OpenCV or foreign-resource ownership.
- Prefer explicit Ada abstractions over C++-specific encodings such as integer
  mode constants, output-parameter APIs, and STL collections.
- Use authoritative OpenCV declarations and source when exact behavior differs
  from a high-level description.

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
+----------------------------------+
| Thick Ada API                    |
| OpenCV.Core                      |
| OpenCV.Core.Persistence          |
| strong types / exceptions        |
+----------------------------------+
     |
     v
+----------------------------------+
| Thin Ada interop                 |
| OpenCV.Internal.C_API            |
| fixed ABI types                  |
+----------------------------------+
     |
     v
+----------------------------------+
| C++ shim / stable C ABI          |
| extern "C"                       |
| opaque Mat/FileStorage handles   |
+----------------------------------+
     |
     v
+----------------------------------+
| OpenCV Core                      |
| cv::Mat / cv::FileStorage / cv::*|
+----------------------------------+
```

### Thick Ada API

The public layer is intentionally Ada-shaped:

- `Mat` is a tagged controlled type with OpenCV-style shallow assignment.
- `File_Storage` is a limited controlled type with exclusive ownership.
- OpenCV integer flags are represented by strong Ada enums where practical.
- Multiple-output OpenCV operations return Ada records instead of exposing
  output parameters.
- Normal semantic failures either raise `OpenCV_Error` or use a discriminated
  result type when failure is part of the normal mathematical result.
- `Interfaces.C`, raw opaque handles, and C++ implementation details remain
  private.

### Thin Ada interop

`OpenCV.Internal.C_API` defines the fixed-width C ABI contract used by the
thick Ada layer. It is an implementation detail, not the normal application
API.

### C++ shim

The shim:

- exports only C-compatible functions;
- uses opaque handles for `cv::Mat` and `cv::FileStorage`;
- uses fixed-width integers and simple C-compatible records;
- validates raw ABI and memory-safety conditions;
- initializes caller-visible outputs before operations that may fail;
- catches OpenCV, standard C++, and unknown exceptions;
- translates failures into stable status codes plus diagnostic text;
- never allows a C++ exception to cross into Ada;
- never passes C++ objects, references, STL types, templates, or `std::string`
  ownership across the boundary.

C++ containers may be used **inside** the shim when OpenCV requires them, but
they do not cross the ABI.

---

## Safety and validation boundary

The project deliberately separates **public semantic validation** from
**raw ABI safety**.

### Ada layer

The thick Ada API normally validates caller-facing semantic rules such as:

- shape compatibility;
- depth and channel restrictions;
- row/column bounds;
- mode restrictions;
- non-empty requirements;
- allowed enum-like choices;
- persistence names and strings that cannot be represented safely by the
  underlying OpenCV 4.10 interface.

### C++ shim

The shim defensively validates conditions that a raw C caller could violate and
that are needed to keep the C++ call safe, including:

- null handles and output pointers;
- raw enum decoding;
- pointer/count and row-buffer sizes;
- signed arithmetic that could overflow before OpenCV validates an argument;
- output initialization and failure atomicity;
- ownership publication;
- exception containment.

A semantic-looking duplicate check belongs in C++ only when it has a concrete
ABI/memory-safety reason.

### Warnings are errors

The public project compiles:

- Ada with `-Werror`;
- C++17 with `-Wall -Wextra -Wpedantic -Werror`.

The test project also compiles Ada with `-Werror`.

Warnings are treated as issues rather than routinely suppressed.

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

The binding targets the OpenCV 4.x Core API, with detailed feature semantics
and safety boundaries checked against **OpenCV 4.10** where implementation
details matter. Compatibility across every OpenCV 4.x release has not yet been
characterized release by release.

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

The current test tree contains 11 suites:

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
- `Persistence_Tests`

Current registration baseline:

```text
683 AUnit tests
```

New operations routinely test:

- ordinary behavior;
- invalid input;
- shape/depth/channel compatibility;
- empty Mats;
- non-contiguous Regions;
- shallow versus independent ownership;
- source/result lifetime;
- raw-ABI failure atomicity where applicable;
- OpenCV-specific numerical and implementation boundaries;
- persistence missing-versus-empty semantics;
- disk and memory persistence modes.

---

## SPARK and GNATprove

Formal verification is used selectively where it proves a concrete property
inside the Ada layer.

The current proof boundary is:

```text
OpenCV.Internal.Safe_Arithmetic
```

with `SPARK_Mode => On`.

The first proved production helper is:

```ada
function Product_Exceeds_Signed_Int32
  (Left, Right : Natural) return Boolean
with
  Global => null,
  Post =>
    Product_Exceeds_Signed_Int32'Result =
      (Long_Long_Integer (Left) * Long_Long_Integer (Right)
         > 2_147_483_647);
```

Its implementation uses division rather than evaluating the potentially
overflowing `Natural` product. The helper is used by dimensional guards in SVD
back-substitution and pseudoinverse handling.

The intended proof strategy is **small proof islands**, not a wholesale
conversion of the foreign-resource layer to SPARK:

```text
OpenCV / C++ numerical implementation
              |
              v
        tested + reviewed

C ABI / controlled ownership
              |
              v
        tested + reviewed

pure Ada safety arithmetic
              |
              v
        SPARK / GNATprove
```

GNATprove is provided by the `tests` Alire environment and is not a dependency
of the public crate.

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

## Compute a compact SVD

```ada
use OpenCV.Core;

Basis : constant Singular_Value_Decomposition_Result :=
  Singular_Value_Decomposition (A);

--  For A with shape M x N:
--    Basis.Singular_Values : R x 1
--    Basis.U               : M x R
--    Basis.V_Transpose     : R x N
--  where R = min (M, N).
```

## Compute a pseudoinverse

```ada
A_Plus : constant Mat := Pseudo_Inverse (A);
```

`Pseudo_Inverse` supports square, tall, wide, and rank-deficient
single-channel Float32/Float64 matrices.

## Persist named values to YAML

```ada
with OpenCV.Core.Persistence;

declare
   package Persistence renames OpenCV.Core.Persistence;

   Storage : Persistence.File_Storage :=
     Persistence.Open ("calibration.yml", Persistence.Write_Only);
begin
   Storage.Write ("Frame_Count", 120);
   Storage.Write ("RMS_Error", 0.18);
   Storage.Write ("Camera_Name", "Front Camera");
   Storage.Write ("Camera_Matrix", Camera_Matrix);
end;
```

`File_Storage` closes automatically when finalized.

## Serialize entirely in memory

```ada
with OpenCV.Core.Persistence;

declare
   package Persistence renames OpenCV.Core.Persistence;

   Writer : Persistence.File_Storage :=
     Persistence.Create_Memory (Persistence.JSON);
begin
   Writer.Write ("Name", "Front Camera");
   Writer.Write ("Matrix", Camera_Matrix);

   declare
      Text   : constant String := Writer.Close_And_Get_Text;
      Reader : constant Persistence.File_Storage :=
        Persistence.Open_Memory (Text);
      Matrix : constant OpenCV.Core.Mat :=
        Reader.Read_Mat ("Matrix");
   begin
      null;
   end;
end;
```

`Close_And_Get_Text` consumes and closes the memory writer.

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
- conversion and element-wise mathematics;
- `Transpose`, `Flip`, `Rotate`, `Repeat`;
- sorting;
- `Copy_Make_Border`;
- channel extraction/splitting/merging;
- concatenation;
- `Diagonal_Matrix`;
- matrix multiplication;
- covariance;
- eigen, PCA, and SVD outputs;
- pseudoinverse;
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
- `Covariance_Result`
- `Eigen_Decomposition_Result`
- `Principal_Component_Analysis_Result`
- `Singular_Value_Decomposition_Result`
- channel-routing records and arrays.

Strong enums include:

- normalization;
- comparison;
- flipping;
- border modes;
- rotation;
- reduction axes and kinds;
- angle units;
- sorting axes/orders;
- transposed-product orientation;
- symmetry source;
- sample orientation;
- covariance scaling.

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

Conversions and mapping:

- `Convert_To`
- `Convert_Scale_Abs`
- `Apply_LUT`
- `Normalize`

Mathematical functions:

- `Sqrt`
- `Exp`
- `Log`
- `Pow`
- `Magnitude`
- `Phase`
- `Cart_To_Polar`
- `Polar_To_Cart`

`Magnitude`, `Phase`, and polar/cartesian routines operate component-wise on
matching Float32/Float64 Mats and preserve multi-channel layouts where
supported.

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

These remain intentionally distinct from algebraic `Matrix_Multiply`.

The first-generation arithmetic API favors explicit operations with controlled
compatibility rules rather than reproducing the entire C++ operator matrix.

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

Scalar/statistical operations include:

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
- `Covariance`

Axis-based `Reduce` supports:

- `Sum`
- `Average`
- `Maximum`
- `Minimum`
- `Sum_Of_Squares`

with an overload for explicit output depth.

`Covariance` supports samples stored by rows or by columns and returns both the
covariance matrix and the OpenCV-computed mean. `By_Sample_Count` uses
OpenCV's `1/N` scaling; it is not the unbiased `1/(N-1)` convention.

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

## Per-element vector transforms

`Transform` applies an MxN linear or Mx(N+1) affine coefficient matrix to the
channel vector at every Mat element.

`Perspective_Transform` applies homogeneous 2-D/3-D vector transformations:

- C2 source -> 3x3 transform matrix
- C3 source -> 4x4 transform matrix

These transform channel/vector values at each element. They do not perform
image resampling or warping; those operations belong in an `imgproc` binding.

---

# Linear algebra and decomposition

Current linear-algebra coverage includes:

- `Trace`
- `Determinant`
- LU `Invert`
- LU `Solve`
- `Dot_Product`
- `Cross_Product`
- `Mahalanobis_Distance`
- `Matrix_Multiply`
- `Matrix_Multiply_Add`
- centered and uncentered `Transposed_Product`
- `Covariance`
- `Eigen_Decomposition`
- `Principal_Component_Analysis`
- `PCA_Project`
- `PCA_Back_Project`
- `Singular_Value_Decomposition`
- `SVD_Back_Substitute`
- `Pseudo_Inverse`
- `Reciprocal_Condition_Number`
- `Set_Identity`
- `Complete_Symmetry`

## Determinant, LU inversion, and LU solving

`Determinant` supports non-empty square single-channel Float32/Float64 Mats.

`Invert` currently means ordinary **DECOMP_LU** inversion:

```ada
Result : Inversion_Result := Matrix.Invert;

if Result.Invertible then
   --  Result.Inverse is available here.
   null;
end if;
```

A singular matrix returns `Invertible => False`; singularity is not represented
as an exception.

`Solve` currently means **DECOMP_LU** solving:

```ada
Result : Solve_Result := A.Solve (B);

if Result.Solved then
   --  Result.Solution is available here.
   null;
end if;
```

A singular coefficient matrix returns `Solved => False`.

Least-squares, minimum-norm, and rank-deficient solving are available through
the SVD APIs rather than being silently folded into the LU operations.

## Dot and cross products

`Dot_Product` sums corresponding element/channel products and returns
`Long_Float`. It is not matrix multiplication and does not reinterpret C2 as a
complex inner product.

`Cross_Product` implements the 3-D vector cross product for one vector encoded
as:

- `3x1 C1`;
- `1x3 C1`; or
- `1x1 C3`.

Float32 and Float64 are supported.

## Algebraic matrix multiplication

`Matrix_Multiply` performs algebraic multiplication through OpenCV GEMM
semantics:

```ada
C : Mat := Matrix_Multiply (A, B);
```

It is deliberately separate from element-wise `Multiply`.

Float32/Float64 single-channel real matrices are supported, along with
two-channel complex matrices where channel 0 is the real part and channel 1 is
the imaginary part.

`Matrix_Multiply_Add` exposes:

```text
Product_Scale * Left * Right + Addend_Scale * Addend
```

without exposing raw GEMM bit flags.

## Transposed products

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

## Covariance

`Covariance` is an explicit statistical API over OpenCV
`calcCovarMatrix`.

With `Samples_Are_Rows`, an `M x N` matrix represents `M` observations of
`N` features and returns:

```text
Mean        : 1 x N
Covariance  : N x N
```

With `Samples_Are_Columns`, the dimensions are transposed accordingly.

The default `By_Sample_Count` scaling is OpenCV's population-style `1/N`
factor, not unbiased `1/(N-1)` covariance.

## Symmetric eigen decomposition

`Eigen_Decomposition` wraps OpenCV's real symmetric eigensolver.

For an `N x N` source:

```text
Eigenvalues  : N x 1
Eigenvectors : N x N, one eigenvector per row
```

Important contract points:

- source must be Float32 or Float64, non-empty, square, and single-channel;
- symmetry is a caller precondition; the binding does not invent a floating
  tolerance that OpenCV itself does not use;
- eigenvector sign is mathematically arbitrary;
- repeated eigenspaces do not have a unique basis;
- the current OpenCV 4.10 safety boundary limits `N` to **8,460** because the
  fallback eigensolver forms an internal iteration bound using signed integer
  arithmetic.

## Principal component analysis

`Principal_Component_Analysis` supports:

- all available components;
- an explicit component count;
- OpenCV's retained-variance selection.

The result contains:

```text
Mean
Eigenvalues
Eigenvectors
```

with one principal direction per row of `Eigenvectors`.

`PCA_Project` projects samples through an existing basis without recomputing
PCA.

`PCA_Back_Project` reconstructs feature-space samples from principal
coordinates.

Both row-oriented and column-oriented sample layouts are supported with an
explicit `Sample_Orientation`.

OpenCV 4.10's retained-variance behavior is preserved, including its
strict-`>` cumulative-energy selection and minimum-two-component behavior. The
same **8,460** safety boundary applies where the OpenCV 4.10 eigensolver path
can overflow its signed iteration bound.

## Compact SVD

`Singular_Value_Decomposition` computes OpenCV's default compact/economy SVD.

For source `A` with shape `M x N` and:

```text
R = min (M, N)
```

the result is:

```text
Singular_Values : R x 1
U               : M x R
V_Transpose     : R x N
```

The decomposition represents:

```text
A ~= U * diag(Singular_Values) * V_Transpose
```

Rank-deficient matrices and zero singular values are valid.

## SVD back-substitution

`SVD_Back_Substitute` reuses an existing compact SVD basis:

```text
X ~= V * diag(W)^+ * U'T * B
```

This supports:

- ordinary full-rank square solving;
- overdetermined least-squares solving;
- underdetermined minimum-norm solving;
- rank-deficient bases according to OpenCV 4.10's internal threshold.

There is intentionally no caller-configurable tolerance in this first API.

## Moore-Penrose pseudoinverse

`Pseudo_Inverse` returns an independent `N x M` result for an `M x N` source.

It supports:

- square matrices;
- tall matrices;
- wide matrices;
- rank-deficient matrices;
- the zero matrix.

Numerical rank follows OpenCV 4.10 SVD back-substitution behavior. This is
deliberately distinct from LU `Invert`.

## Reciprocal condition number

`Reciprocal_Condition_Number` returns the mathematical 2-norm reciprocal
condition number based on the singular values OpenCV actually computes:

```text
rcond(A) = sigma_min / sigma_max
```

If the largest singular value is exactly zero, the result is `0.0`.

The operation is distinct from:

- OpenCV `invert(DECOMP_SVD)`'s return metric;
- the rank threshold used by pseudoinverse / SVD back-substitution.

---

# Persistence

Persistence is provided by the child package:

```ada
OpenCV.Core.Persistence
```

using a limited controlled `File_Storage` abstraction over
`cv::FileStorage`.

## Supported formats

The current public formats are:

```text
XML
YAML
JSON
```

### Disk

Disk format is selected from the filename extension:

```text
.xml
.yml
.yaml
.json
```

Example:

```ada
Storage : File_Storage := Open ("data.yml", Write_Only);
```

### Memory

Memory writers use an explicit strong Ada `Storage_Format`:

```ada
Storage : File_Storage := Create_Memory (JSON);
```

`Close_And_Get_Text` finalizes the writer and returns the serialized document
as an independent Ada `String`.

Memory readers use:

```ada
Storage : File_Storage := Open_Memory (Text);
```

OpenCV 4.10 auto-detects OpenCV FileStorage XML/YAML/JSON documents from their
contents.

## Named value types

The current top-level named persistence API supports:

- `Mat`
- `Integer`
- `Long_Float`
- `String`

Write overloads share the same API for disk and memory backends.

Reads use explicit names:

- `Read_Mat`
- `Read_Integer`
- `Read_Real`
- `Read_String`

## Type policy

The Ada API deliberately avoids surprising lossy conversions:

```text
integer node -> Read_Integer    allowed
real node    -> Read_Integer    rejected

real node    -> Read_Real       allowed
integer node -> Read_Real       allowed, exact widening

string node  -> Read_String     allowed
other node   -> Read_String     rejected
```

A missing name raises `OpenCV_Error`.

Actually stored values such as:

```text
0
0.0
""
empty Mat
```

remain distinguishable from a missing node.

## OpenCV 4.10 persistence safety notes

### Signed minimum integer

OpenCV 4.10 formats integer nodes through an internal `abs(int)` path, so the
single value:

```text
-2_147_483_648
```

cannot safely be written.

The supported `Write(Integer)` range is therefore:

```text
-2_147_483_647 .. 2_147_483_647
```

The Ada layer and raw C ABI both reject the unsafe minimum before it reaches
OpenCV.

This is an OpenCV 4.10 writer limitation, not an Ada or file-format
limitation. `Read_Integer` remains able to return a preexisting signed-32-bit
minimum node when OpenCV successfully parses one.

### Embedded NUL

OpenCV 4.10 persistence emitters and memory-read handling use NUL-terminated
strings / `strlen`.

Accordingly the current public API rejects embedded NUL in:

- filenames;
- node names;
- persisted String values;
- memory documents passed to `Open_Memory`.

### Memory output ownership

`releaseAndGetString()` is a one-shot OpenCV operation that closes the writer.
The shim calls it once, caches the returned C++ string internally, and exposes
the bytes through a caller-owned query/copy buffer ABI.

No C++ string ownership crosses into Ada.

## Persistence not yet exposed

The current persistence slice intentionally does **not** yet expose:

- public `File_Node`;
- `FileNodeIterator`;
- nested maps;
- nested sequences;
- append mode;
- Base64;
- comments;
- gzip controls;
- raw `readRaw` / `writeRaw`;
- explicit disk format override.

Nested maps and sequences are the natural next expansion while keeping
`FileNode` private until its lifetime model provides enough public value.

---

# Current milestone status

The roadmap tracks portable, user-facing OpenCV Core functionality rather than
every internal/backend symbol.

## Milestone 0 — binding foundation

- [x] stable `extern "C"` shim
- [x] opaque `cv::Mat` handles
- [x] opaque `cv::FileStorage` handles
- [x] C++ exception containment
- [x] Ada controlled lifetime
- [x] shallow `Mat` assignment semantics
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
- [x] warning-free `-Werror` policy
- [x] first targeted SPARK/GNATprove production proof
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
- [x] `Covariance`

Remaining candidates:

- [ ] two-Mat norm / distance overloads
- [ ] relative norm support
- [ ] additional norm kinds where useful
- [ ] `Min_Max_Idx`
- [ ] arg-min / arg-max reduction APIs
- [ ] PSNR

## Milestone 7 — linear algebra and decomposition

Implemented:

- [x] `Cross_Product`
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
- [x] `Covariance`
- [x] symmetric `Eigen_Decomposition`
- [x] `Principal_Component_Analysis`
- [x] PCA retained-variance selection
- [x] `PCA_Project`
- [x] `PCA_Back_Project`
- [x] compact `Singular_Value_Decomposition`
- [x] `SVD_Back_Substitute`
- [x] `Pseudo_Inverse`
- [x] `Reciprocal_Condition_Number`

Future candidates:

- [ ] non-symmetric eigen decomposition
- [ ] `SVD::solveZ` / null-space solving
- [ ] additional `Solve` decomposition modes
- [ ] additional `Invert` decomposition modes
- [ ] LDA
- [ ] cubic solving
- [ ] polynomial solving

**Status: advanced dense linear algebra now has substantial coverage.**

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

The overloaded C++ RNG API should be redesigned as an Ada-friendly abstraction
rather than mechanically exposed.

## Milestone 11 — persistence

Implemented:

- [x] `OpenCV.Core.Persistence`
- [x] controlled `File_Storage`
- [x] XML disk persistence
- [x] YAML disk persistence
- [x] JSON disk persistence
- [x] named `Mat` read/write
- [x] named `Integer` read/write
- [x] named `Long_Float` read/write
- [x] named `String` read/write
- [x] strict node-type read policy
- [x] missing-node versus empty/zero distinction
- [x] non-contiguous `Mat` persistence
- [x] in-memory XML serialization/deserialization
- [x] in-memory YAML serialization/deserialization
- [x] in-memory JSON serialization/deserialization
- [x] consuming `Close_And_Get_Text`
- [x] independent returned-value lifetime
- [x] raw-ABI lifetime and output-buffer safety

Future persistence scope:

- [ ] nested mappings
- [ ] nested sequences
- [ ] public `File_Node` if a robust Ada lifetime model justifies it
- [ ] `FileNodeIterator` only if it adds sufficient value
- [ ] append mode
- [ ] Base64
- [ ] comments
- [ ] gzip controls
- [ ] raw persistence APIs

**Status: top-level named persistence to disk and memory is complete for the
current value types.**

## Milestone 12 — advanced matrix structures

Potential later scope:

- [ ] broader predefined Vec/Matx families
- [ ] typed access for remaining depths
- [ ] N-dimensional `Mat`
- [ ] N-dimensional reshape/views
- [ ] `SparseMat`
- [ ] external/shared-buffer Mat construction
- [ ] `UMat` if a concrete use case requires it
- [ ] async Core APIs if a concrete use case requires them

These areas require more substantial architectural decisions.

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
   Several mathematical/sorting operations reject Float16, while other APIs
   such as `Set_Identity` can accept it.

6. **Arithmetic overloads are intentionally conservative.**  
   The public API does not reproduce the large Mat/Scalar, mixed-depth, and
   masked overload matrix from C++.

7. **`Invert` and `Solve` remain LU-specific.**  
   SVD-based least-squares, minimum-norm, pseudoinverse, and condition-number
   functionality is exposed through separate explicit APIs rather than hidden
   behind a decomposition-mode integer.

8. **Eigen decomposition is currently symmetric-only.**  
   `Eigen_Decomposition` assumes a real symmetric caller-supplied matrix.

9. **Some OpenCV 4.10 safety boundaries are intentionally stricter than the
   nominal OpenCV signature.**  
   The symmetric eigen/PCA path is limited to dimensions at most 8,460 where
   OpenCV 4.10 otherwise forms an unsafe signed integer iteration bound.
   SVD/pseudoinverse paths also guard signed-index products identified in the
   OpenCV 4.10 implementation.

10. **No general `cv::MatExpr` equivalent.**  
    The Ada interface uses explicit operations.

11. **No raw public pixel pointers.**  
    Safe typed access and copied-row APIs are preferred over leaking OpenCV
    memory-layout details.

12. **No public raw OpenCV flag integers.**  
    Current wrapped modes use strong Ada enums or deliberately narrower APIs.

13. **Persistence currently exposes top-level named values, not a general
    hierarchical node API.**  
    Maps, sequences, `FileNode`, append, Base64, comments, and raw persistence
    remain future work.

14. **OpenCV 4.10 persistence has explicit safety restrictions.**  
    `Write(Integer)` cannot write `-2_147_483_648`, and embedded NUL is rejected
    in persistence strings/names/documents because OpenCV 4.10 uses
    NUL-terminated handling internally.

15. **No spectral or RNG family yet.**  
    DFT/DCT, spectrum operations, RNG, K-means, and related algorithms remain
    roadmap items.

16. **OpenCV 4.x compatibility is not characterized release by release.**

17. **The API is pre-1.0.**  
    Public signatures may evolve as hierarchical persistence, spectral,
    broader typed access, N-dimensional arrays, and advanced structures are
    added.

---

# Project layout

```text
opencvcore_ada/
├── .clinerules/
│   ├── 01-architecture.md
│   ├── 02-ada-design.md
│   ├── 03-cpp-interop.md
│   ├── 04-testing.md
│   ├── 05-quality.md
│   └── 06-agent-workflow.md
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
│   ├── opencv-core-persistence.ads
│   ├── opencv-core-persistence.adb
│   ├── opencv-core-*_access.*           # typed element access
│   ├── opencv-core-*_row_access.*       # copied row access
│   ├── opencv-core-*_vec3*              # predefined Vec3 support
│   ├── opencv-core-vectors.ads
│   ├── opencv-core-fixed_matrices.ads
│   ├── opencv-core-float32_matx3x3.ads
│   ├── opencv-core-float32_matx3x3_conversions.*
│   └── internal/
│       ├── opencv-internal-c_api.ads
│       ├── opencv-internal-c_api.adb
│       ├── opencv-internal-safe_arithmetic.ads
│       ├── opencv-internal-safe_arithmetic.adb
│       └── opencv-core-internal-typed_access.*
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
        ├── mat_transform_tests.*
        └── persistence_tests.*
```

---

# Development approach

New features generally follow this sequence:

1. Inspect authoritative OpenCV declarations, implementation source, and tests
   for the exact target behavior.
2. Inspect existing repository conventions.
3. Decide the thick Ada API and deliberate restrictions.
4. Identify which validation belongs in Ada and which checks are required at
   the raw C ABI for memory/overflow safety.
5. Add only the required stable C ABI surface.
6. Implement the C++ shim with exception containment and failure-atomic output
   handling.
7. Add/update the thin Ada import.
8. Implement the thick Ada operation.
9. Add focused AUnit coverage.
10. Include non-contiguous Region cases where applicable.
11. Include ownership/independence/view lifetime tests where applicable.
12. Include invalid-input and source-version boundary behavior.
13. Format modified Ada sources with the repository's Ada formatting workflow.
14. Build the public crate warning-free.
15. Build and run the complete tests crate warning-free.
16. Run targeted GNATprove when a SPARK proof boundary is modified.
17. Inspect the final diff and keep it focused.

Important public API decisions should be made deliberately rather than
discovered accidentally through a mechanical translation of the C++ API.

## Source-backed safety review

When an OpenCV implementation contains signed indexing, raw pointer access, or
other operations whose safety depends on preconditions, the binding reviews
the actual OpenCV 4.10 source and establishes a safe boundary before calling
it.

Examples already reflected in the public implementation include:

- signed product guards around SVD/pseudoinverse indexing;
- the 8,460 eigen/PCA dimension boundary;
- the OpenCV 4.10 FileStorage `INT_MIN` write restriction;
- string/NUL restrictions where OpenCV uses `strlen`;
- failure-atomic opaque-handle publication.

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
- source/result lifetime;
- arbitrary Ada array lower bounds for collection APIs;
- mismatched rows/columns;
- mismatched depth/channel count;
- mask type and dimensions;
- NaN and infinity where OpenCV naturally produces them;
- exact OpenCV boundary semantics;
- result-handle failure atomicity for newly allocated Mats;
- caller-buffer capacity and ownership for returned strings;
- persistence missing-versus-empty semantics;
- disk versus memory storage state transitions.

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
- suppressing warnings simply to make a build pass;
- broad unrelated cleanup in otherwise focused feature commits.

Small, vertically complete features with focused tests are preferred over large
partially integrated batches.

Formal proof should also stay focused: prove small pure-Ada safety properties
when it produces a concrete guarantee, rather than adding contracts
decoratively.

---

# Versioning

The crate is currently:

```text
0.1.0-dev
```

The API should be considered experimental until a 1.0 release.

Before 1.0, names and overloads may evolve as hierarchical persistence,
spectral operations, broader typed access, N-dimensional arrays, and advanced
matrix structures reveal better Ada abstractions.

---

# License

`opencvcore_ada` is licensed under the **Apache License 2.0**.

See `LICENSE` for the full license text.

OpenCV is a separate project with its own license and copyright holders.

---

## Summary

`opencvcore_ada` now provides a substantial, tested Ada foundation for OpenCV
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
- determinant and explicit LU inversion/solving;
- dot and 3-D cross products;
- real/complex matrix multiplication;
- centered and uncentered transposed products;
- covariance and Mahalanobis distance;
- symmetric eigen decomposition;
- PCA basis construction, projection, back-projection, and retained-variance
  selection;
- compact SVD and SVD back-substitution;
- Moore-Penrose pseudoinverse;
- reciprocal 2-norm condition number;
- per-element linear/affine and perspective vector transforms;
- XML/YAML/JSON persistence for Mat/scalar/string values on disk and in memory;
- a first targeted SPARK/GNATprove production proof;
- a stable error-isolated C++ interoperability layer;
- warning-free builds enforced with `-Werror`;
- 683 registered AUnit tests in the current development baseline.

The cross-language architecture is established. Remaining work is primarily
coverage expansion: hierarchical persistence, spectral operations, RNG and
algorithms, broader typed access, generalized decomposition modes,
N-dimensional arrays, and advanced matrix structures.
