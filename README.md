# opencvcore_ada

A thick, idiomatic Ada binding for the **OpenCV Core** module.

`opencvcore_ada` is intended to provide a safe Ada-facing API over OpenCV's Core data structures and array operations without exposing C++ ABI details to Ada applications. The binding uses a stable C ABI shim between Ada and C++, preserves OpenCV ownership and numeric semantics, and presents common OpenCV concepts through Ada types, controlled objects, overloads, generics, ranges, and exceptions.

> **Project status:** active development, `0.1.0-dev`.
>
> **Current baseline:** the current `main` branch passes **128/128 AUnit tests** as of August 2026.
>
> **Current practical completion:** approximately **35–40%** of a broad, portable, user-facing dense-`Mat` OpenCV Core binding, with approximately **60–65%** of the Core foundation likely to be needed by downstream Ada OpenCV modules already in place.

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
- catches `cv::Exception`, `std::exception`, and unknown exceptions;
- translates failures into stable status codes plus a diagnostic message;
- does not allow C++ exceptions to cross into Ada;
- does not pass C++ objects, references, STL types, or templates across the boundary.

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

Views such as `Region`, `Row_View`, `Column_View`, and `Reshape` also create distinct `Mat` headers that share storage where OpenCV defines a no-copy view.

Functions that compute a new result, such as `Add`, `Normalize`, `Convert_To`, `In_Range`, and bitwise operations, return independently owned result storage.

---

## Requirements

The build currently expects:

- an Ada toolchain supported by Alire;
- **Alire**;
- a C++17 compiler;
- **pkg-config**;
- OpenCV development files providing the `opencv4` pkg-config package;
- the OpenCV Core library (`opencv_core`).

The project file compiles the shim as C++17 and links against:

```text
opencv_core
libstdc++
```

OpenCV include and library paths are discovered automatically by:

```text
scripts/configure_opencv.sh
```

using:

```text
pkg-config --variable=includedir opencv4
pkg-config --variable=libdir opencv4
```

Development and behavioral validation have primarily targeted **OpenCV 4.10**. Compatibility across every OpenCV 4.x release is not yet formally characterized.

---

## Building

Clone the repository and build it with Alire:

```sh
git clone https://github.com/zackboll/opencvcore_ada.git
cd opencvcore_ada
alr build
```

The Alire pre-build action runs `scripts/configure_opencv.sh`, which generates the local OpenCV GPR configuration from `pkg-config`.

If configuration fails, first verify:

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

- AUnit 26;
- the local `opencvcore_ada` crate;
- GNATprove;
- GNATcov.

These development dependencies are intentionally not dependencies of the public library crate.

Current baseline:

```text
128 tests run
128 successful
0 failed assertions
0 unexpected errors
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

## Multi-channel `Vec3` access

Three-channel UInt8 and Float32 accessors are currently provided.

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

The predefined Vec3 types are intentionally component-oriented rather than assigning RGB/BGR semantics. OpenCV channel interpretation belongs to the caller or higher-level module.

---

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

Bulk row APIs are currently available for:

- UInt8 single-channel;
- Float32 single-channel;
- UInt8 Vec3;
- Float32 Vec3.

---

# Views and copies

## Region of interest

`Region` uses a `Rect` and returns a shallow view.

```ada
declare
   Source : Mat :=
     Create (480, 640, (Depth => UInt8, Channels => 1));

   ROI : Mat :=
     Source.Region
       ((X      => 100,
         Y      => 50,
         Width  => 200,
         Height => 100));
begin
   null;
end;
```

`ROI` has its own `Mat` header but shares source storage through OpenCV reference counting.

## Row and column views

```ada
declare
   R1 : Mat := Source.Row_View (10);
   R2 : Mat := Source.Row_View ((Start => 10, Stop => 20));

   C1 : Mat := Source.Column_View (5);
   C2 : Mat := Source.Column_View ((Start => 5, Stop => 15));
begin
   null;
end;
```

`Index_Range` uses half-open semantics:

```text
Start <= index < Stop
```

Equal endpoints produce an empty range view where OpenCV allows it.

## Clone a view

```ada
Independent_Copy : Mat := ROI.Clone;
```

Changes to the original ROI storage no longer affect `Independent_Copy`.

---

# Arithmetic

The current first-generation arithmetic API intentionally favors simple, explicit Mat/Mat operations with matching shape and type.

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

This maps to OpenCV `addWeighted` behavior while preserving the input depth.

## Convert depth, scale, and offset

```ada
Converted : Mat :=
  Image.Convert_To
    (Depth  => Float32,
     Scale  => 1.0 / 255.0,
     Offset => 0.0);
```

The channel count is preserved.

---

# Normalization and reductions

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

For `L1`, `L2`, and `Infinity`, `Alpha` is the target norm and `Beta` is ignored. For `Min_Max`, `Alpha` and `Beta` are the destination range bounds.

## Sum

```ada
S : Scalar := Image.Sum;
```

## Mean

```ada
M : Scalar := Image.Mean;
```

## Mean and standard deviation

```ada
Stats : Mean_Std_Dev_Result := Image.Mean_Std_Dev;
```

`Mean` and `Mean_Std_Dev` currently use `Scalar` result storage and therefore deliberately support one through four channels.

## Norm

```ada
Magnitude : Long_Float := Image.Norm (L2);
```

Current norm kinds:

- `L1`
- `L2`
- `Infinity`

## Minimum and maximum location

```ada
Extrema : Min_Max_Result := Image.Min_Max_Loc;
```

`Min_Max_Loc` currently targets non-empty, 2-D, single-channel matrices. Locations use:

```text
Point.X = column
Point.Y = row
```

---

# Bitwise operations and masks

Unmasked bitwise operations are available:

```ada
A_And_B : Mat := A.Bitwise_And (B);
A_Or_B  : Mat := A.Bitwise_Or (B);
A_Xor_B : Mat := A.Bitwise_Xor (B);
Not_A   : Mat := A.Bitwise_Not;
```

OpenCV bitwise behavior is preserved even for floating-point matrices, where the operation applies to the element bit representation.

## Common mask contract

Masks are represented by ordinary `Mat` values rather than a second owning wrapper type.

A valid mask is:

```text
Depth    = UInt8
Channels = 1
Rows     = source Rows
Columns  = source Columns
```

Any nonzero mask value selects the corresponding matrix element.

Masked bitwise overloads are available:

```ada
Result := A.Bitwise_And (B, Mask);
Result := A.Bitwise_Or  (B, Mask);
Result := A.Bitwise_Xor (B, Mask);
Result := A.Bitwise_Not (Mask);
```

For fresh OpenCV destination matrices, unselected elements are zero.

---

# Generate masks with `In_Range`

`In_Range` currently accepts Scalar lower and upper bounds for sources with one through four channels.

```ada
Mask : Mat :=
  Image.In_Range
    (Lower => Make_Scalar (10.0),
     Upper => Make_Scalar (200.0));
```

The returned mask is:

```text
UInt8
single-channel
same rows/columns as source
255 for selected elements
0 otherwise
```

Bounds are inclusive.

For multi-channel matrices, all channel values for an element must lie within the corresponding lower/upper bounds for that element to be selected.

The resulting mask can be consumed directly by masked operations:

```ada
Mask :=
  Image.In_Range
    (Lower => Make_Scalar (10.0),
     Upper => Make_Scalar (200.0));

Selected := Image.Bitwise_And (Image, Mask);
```

---

# Float32 non-finite values

OpenCV arithmetic can legitimately produce IEEE infinity or NaN values.

The current finite `Float32_Access.Get` conversion is intentionally not used to transport non-finite values through the ordinary Ada numeric conversion boundary.

Use `Classify` when a result may be non-finite:

```ada
with OpenCV.Core.Float32_Access;

declare
   Kind : OpenCV.Core.Float32_Access.Float32_Classification;
begin
   Kind := OpenCV.Core.Float32_Access.Classify (Image, 0, 0);
end;
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

It provides:

```ada
type Vector is array (Component_Index) of Element_Type;
```

Predefined Vec3 packages currently exist for UInt8 and Float32.

## Fixed matrices / Matx-style values

A pure-Ada fixed matrix generic is available:

```ada
generic
   type Element_Type is private;
   Row_Count : Positive;
   Column_Count : Positive;
package OpenCV.Core.Fixed_Matrices;
```

A predefined Float32 3×3 matrix and copy-only conversion to/from `Mat` are currently implemented.

The C++ `cv::Matx` object itself is not passed through the ABI.

---

# Current public Core functionality

The current `OpenCV.Core` API includes the following major features.

## Types

- `Depth_Type`
  - `UInt8`
  - `Int8`
  - `UInt16`
  - `Int16`
  - `Int32`
  - `Float32`
  - `Float64`
  - `Float16`
- `Mat_Type`
- `Channel_Count`
- `Mat_Size`
- `Size_Coordinate`
- `Point_Coordinate`
- `Size`
- `Point`
- `Rect`
- `Index_Range`
- `Scalar`
- `Mat`
- `Min_Max_Result`
- `Mean_Std_Dev_Result`
- `Norm_Kind`
- `Normalize_Kind`

## Matrix creation and lifetime

- `Create (Rows, Columns, Mat_Type)`
- `Create (Size, Mat_Type)`
- controlled lifetime
- shallow Ada assignment
- `Clone`

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

## Views

- `Region`
- `Row_View`
- `Row_View (Index_Range)`
- `Column_View`
- `Column_View (Index_Range)`
- `Reshape`

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

## Arithmetic and conversion

- `Convert_To`
- `Normalize`
- `Add`
- `Subtract`
- `Multiply`
- `Divide`
- `Abs_Diff`
- `Add_Weighted`

## Bitwise / masks

- `Bitwise_And`
- `Bitwise_Or`
- `Bitwise_Xor`
- `Bitwise_Not`
- masked overloads for all four bitwise operations
- `In_Range`

## Reductions / statistics

- `Sum`
- `Mean`
- `Mean_Std_Dev`
- `Norm`
- `Min_Max_Loc`

## Value-like generic support

- generic vectors
- predefined UInt8 / Float32 Vec3
- generic fixed matrices
- predefined Float32 3×3 fixed matrix
- copy conversion between Float32 3×3 fixed matrix and `Mat`

---

# Current project state

The project has moved beyond an initial proof of concept. The difficult cross-language foundation is largely established:

- stable C ABI;
- exception containment;
- controlled Ada lifetime;
- OpenCV shallow-copy semantics;
- explicit deep copy;
- safe ROI/view lifetime;
- checked numeric conversions;
- strong depth/channel representation;
- typed element access;
- safe bulk row access;
- non-contiguous matrix handling;
- generic Vec pattern;
- generic fixed-matrix pattern;
- common mask representation and validation;
- IEEE non-finite Float32 classification;
- tested saturation and rounding behavior;
- repeatable vertical AUnit feature implementation.

This means much of the remaining work is expansion of already-proven patterns rather than redesign of the binding.

## Estimated completion

These percentages are estimates for a **portable, user-facing OpenCV Core binding**, not literal coverage of every internal/backend symbol in the OpenCV `core` module.

| Area | Estimated completion | Notes |
|---|---:|---|
| Mat ownership/lifetime/basic structure | ~75% | Strong foundation; several useful Mat operations remain |
| Basic Core value types / Vec / fixed matrices | ~40% | Core patterns established; breadth remains |
| Typed data access | ~35–40% | UInt8/Float32 plus Vec3 and rows currently |
| Element-wise arithmetic/conversion | ~60–65% | Basic Mat/Mat family is strong |
| Masks/comparison/selection | ~50% | Common mask contract and `In_Range` implemented |
| Reductions/statistics | ~35–40% | Core reductions present; masked and axis reductions remain |
| Channel manipulation | ~5–10% | Major gap |
| Matrix layout/manipulation | ~15% | Views are strong; transpose/flip/concat/etc. remain |
| Linear algebra | ~5–10% | Major gap |
| Element-wise mathematical functions | ~5% | Mostly not started |
| Fourier/DCT/spectral operations | 0% | Not started |
| Random numbers / sorting | ~0–5% | Not started |
| Clustering | 0% | Not started |
| Persistence | 0% | Not started |
| N-D / SparseMat / UMat / Async | ~0–5% | Advanced future scope |

Overall:

- approximately **35–40%** of a broad portable dense-`Mat` Core API;
- approximately **60–65%** of the Core foundation expected to be routinely needed by downstream Ada OpenCV crates;
- approximately **65–70%** of the difficult architectural groundwork.

---

# Remaining work / roadmap

The following roadmap prioritizes useful, portable Core functionality rather than attempting a mechanical one-for-one translation of every C++ symbol.

## Milestone 1 — complete the mask and selection ecosystem

High-priority next features:

- [ ] `Compare`
  - Equal
  - Not equal
  - Less than
  - Less than or equal
  - Greater than
  - Greater than or equal
- [ ] `Count_Non_Zero`
- [ ] `Has_Non_Zero`
- [ ] `Find_Non_Zero`
- [ ] `Copy_To`
- [ ] masked `Copy_To`
- [ ] masked `Set_To`
- [ ] masked `Mean`
- [ ] masked `Mean_Std_Dev`
- [ ] masked `Norm`
- [ ] masked `Min_Max_Loc`

Expected result: a complete basic mask production/consumption workflow.

---

## Milestone 2 — channel manipulation

This is one of the largest practical gaps.

- [ ] `Split`
- [ ] `Merge`
- [ ] `Extract_Channel`
- [ ] `Insert_Channel`
- [ ] `Mix_Channels`

This milestone will likely require an Ada design for variable collections of `Mat` objects, for example a `Mat_Array` abstraction.

The design should preserve clear ownership semantics and avoid exposing C++ container types.

---

## Milestone 3 — matrix layout and rearrangement

- [ ] `Transpose`
- [ ] `Flip`
- [ ] `Rotate`
- [ ] `Repeat`
- [ ] horizontal concatenation
- [ ] vertical concatenation
- [ ] diagonal views / `Diag`
- [ ] `Copy_Make_Border` if it remains appropriate for the Core crate
- [ ] stride / step metadata where useful
- [ ] ROI location/adjustment helpers if needed

N-dimensional variants should be postponed until the N-D `Mat` model is designed.

---

## Milestone 4 — finish everyday arithmetic

The current Mat/Mat same-type layer is intentionally narrow. Future expansion may include:

- [ ] Mat/Scalar `Add`
- [ ] Mat/Scalar and Scalar/Mat `Subtract`
- [ ] Mat/Scalar `Multiply`
- [ ] Mat/Scalar and Scalar/Mat `Divide`
- [ ] Scalar `Abs_Diff`
- [ ] Scalar bitwise variants
- [ ] masked `Add`
- [ ] masked `Subtract`
- [ ] explicit result depth where OpenCV supports it
- [ ] mixed-depth arithmetic policy
- [ ] configurable multiply/divide scale
- [ ] `Scale_Add`
- [ ] element-wise `Min`
- [ ] element-wise `Max`
- [ ] `Convert_Scale_Abs`
- [ ] lookup-table (`LUT`) operations

Mixed-depth and Scalar overload proliferation should be added deliberately rather than simply mirroring every C++ overload.

---

## Milestone 5 — element-wise mathematical functions

Likely candidates:

- [ ] `Sqrt`
- [ ] `Pow`
- [ ] `Exp`
- [ ] `Log`
- [ ] `Magnitude`
- [ ] `Phase`
- [ ] Cartesian-to-polar conversion
- [ ] polar-to-Cartesian conversion

Most of these should reuse the existing independent-result Mat pattern.

---

## Milestone 6 — reductions and statistics

Remaining useful reductions include:

- [ ] two-Mat norm/distance
- [ ] relative norm support where appropriate
- [ ] additional norm kinds where useful
- [ ] `Trace`
- [ ] `Min_Max_Idx`
- [ ] `Reduce`
- [ ] arg-min reduction
- [ ] arg-max reduction
- [ ] `PSNR`
- [ ] `Check_Range`
- [ ] `Patch_NaNs`
- [ ] covariance matrix
- [ ] Mahalanobis distance

Result types should remain idiomatic Ada records/enums rather than C++ output-parameter translations where possible.

---

## Milestone 7 — linear algebra

Basic high-value linear algebra:

- [ ] `Dot`
- [ ] `Cross`
- [ ] `Trace`
- [ ] `GEMM`
- [ ] `Mul_Transposed`
- [ ] `Set_Identity`
- [ ] `Complete_Symm`
- [ ] `Determinant`
- [ ] `Invert`
- [ ] `Solve`

Decomposition/statistical linear algebra:

- [ ] eigenvalues / eigenvectors
- [ ] non-symmetric eigen decomposition
- [ ] SVD
- [ ] PCA
- [ ] LDA
- [ ] covariance
- [ ] Mahalanobis distance
- [ ] cubic solving
- [ ] polynomial solving

These features will require careful Ada result-type design, particularly for decompositions returning multiple matrices/vectors.

---

## Milestone 8 — spectral operations

- [ ] DFT
- [ ] inverse DFT
- [ ] DCT
- [ ] inverse DCT
- [ ] spectrum multiplication
- [ ] optimal DFT size

OpenCV integer flag sets should be represented by strongly typed Ada enums/options rather than leaking C++ constants into the public interface.

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

These areas are intentionally later because they require new architectural decisions rather than simple extension of existing wrappers.

---

# Typed access still to be expanded

The binding's `Depth_Type` already represents all of:

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

but public typed element/row access currently concentrates on UInt8 and Float32.

Potential future access packages include:

- [ ] Int8
- [ ] UInt16
- [ ] Int16
- [ ] Int32
- [ ] Float64
- [ ] Float16
- [ ] additional multi-channel typed access

Before creating many repetitive packages, the implementation should be reviewed for opportunities to reuse Ada generics while preserving strict public typing and safe C ABI behavior.

---

# Known limitations

Current intentional limitations include:

1. **Primarily 2-D dense `Mat`.**  
   N-dimensional Mat support has not yet been designed as a public Ada abstraction.

2. **No `SparseMat` or `UMat` public layer.**

3. **Typed access is not yet available for every depth.**

4. **Scalar-valued APIs are naturally limited to at most four represented components.**  
   Operations returning `Scalar`, such as current `Mean`, are intentionally restricted where necessary rather than silently losing channel data.

5. **`In_Range` currently uses Scalar bounds and therefore supports one through four source channels.**

6. **Basic arithmetic currently emphasizes same-shape, same-depth, same-channel Mat/Mat operations.**  
   Scalar operands, masks, mixed depth, and explicit output-depth variants remain future work.

7. **No general C++ expression-template equivalent.**  
   `cv::MatExpr` is intentionally not exposed. The Ada API uses explicit operations.

8. **No raw public data pointers.**  
   Safe typed and row-copy access is preferred over leaking OpenCV memory layout into public Ada code.

9. **OpenCV 4.x compatibility is not yet characterized release by release.**  
   Development behavior has primarily been checked against OpenCV 4.10.

10. **The API is still pre-1.0.**  
    Public signatures may change as larger Core families reveal better Ada abstractions.

---

# Scope and non-goals

The long-term goal is broad coverage of **portable, user-facing OpenCV Core functionality**.

Literal wrapping of every symbol under OpenCV's `core` source tree is not currently a goal.

The following OpenCV implementation/backend surfaces are expected to remain out of scope unless a concrete need appears:

- HAL implementation interfaces;
- SIMD/intrinsics internals;
- DirectX interoperability;
- OpenGL interoperability;
- VA-API interoperability;
- internal OpenCL implementation details;
- IPP backend integration;
- internal parallel backend/plugin interfaces;
- other implementation-specific plumbing that is not part of a normal portable Core workflow.

The project should favor a coherent Ada interface over a misleading claim of 100% symbol-for-symbol C++ coverage.

---

# Error handling

The public API raises Ada exceptions rather than returning C-style status codes.

Across the language boundary:

1. the C++ shim validates arguments;
2. OpenCV is called inside exception containment;
3. C++ exceptions are caught;
4. a stable status and diagnostic are returned to Ada;
5. the thick Ada layer raises the appropriate Ada exception.

Public callers should not need to interact with the internal C status API.

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
│   └── ...                            # C++ C-ABI shim
├── scripts/
│   └── configure_opencv.sh
├── src/
│   ├── opencv-core.ads
│   ├── opencv-core.adb
│   ├── ...                            # public child packages
│   └── internal/
│       └── ...                        # thin/internal Ada interop
└── tests/
    ├── alire.toml
    ├── ...
    └── ...                            # AUnit test suite
```

The exact source-file list will continue to grow as Core functionality is added.

---

# Development approach

New features should generally follow this sequence:

1. Inspect the authoritative OpenCV declaration and semantics.
2. Decide the thick Ada API.
3. Add only the required stable C ABI surface.
4. Implement the C++ shim with full exception containment.
5. Add/update thin Ada imports.
6. Implement the thick Ada operation.
7. Add focused AUnit coverage.
8. Include non-contiguous Mat/ROI cases where applicable.
9. Include ownership/independence tests where applicable.
10. Include invalid-input and boundary behavior.
11. Format modified Ada sources.
12. Build and run tests.
13. Review the final diff before committing.

Important design decisions should be made before implementation rather than discovered accidentally through a mechanical translation of the C++ API.

---

# Testing expectations for new operations

Depending on the operation, tests should consider:

- ordinary UInt8 behavior;
- Float32 behavior;
- signed integer behavior;
- integer saturation/rounding;
- Vec3 / multi-channel behavior;
- empty Mat behavior;
- non-contiguous Region input;
- shallow versus independent storage;
- source lifetime;
- mismatched rows;
- mismatched columns;
- mismatched depth;
- mismatched channel count;
- mask type/dimensions;
- NaN and infinity where OpenCV can naturally produce them;
- exact OpenCV boundary semantics.

The installed OpenCV headers/behavior are authoritative. Tests should not assume C++ semantics from memory when they can be inspected directly.

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
- manually reimplementing OpenCV arithmetic in Ada when a corresponding OpenCV Core operation exists.

Small, vertically complete features with focused tests are preferred over large partially integrated batches.

---

# Versioning

The crate is currently:

```text
0.1.0-dev
```

The API should be considered experimental until a 1.0 release.

Before 1.0, some names and overloads may evolve as channel manipulation, linear algebra, N-dimensional arrays, and persistence force additional design decisions.

---

# License

`opencvcore_ada` is licensed under the **Apache License 2.0**.

See the repository license file for the full license text.

OpenCV is a separate project with its own license and copyright holders.

---

# Suggested near-term implementation order

A practical next sequence is:

```text
1. Compare
2. Count_Non_Zero
3. Has_Non_Zero
4. Find_Non_Zero
5. Copy_To
6. masked Copy_To
7. masked Set_To
8. masked Mean / Mean_Std_Dev
9. masked Norm
10. masked Min_Max_Loc
11. Split
12. Merge
13. Extract_Channel / Insert_Channel
14. Transpose
15. Flip / Rotate
```

That sequence first completes the mask ecosystem, then addresses the largest everyday Core gap: channel manipulation and matrix rearrangement.

---

## Summary

`opencvcore_ada` already provides a tested and coherent Ada foundation for OpenCV Core:

- safe `Mat` lifetime and views;
- typed access;
- generic vectors/fixed matrices;
- conversion and normalization;
- arithmetic;
- reductions;
- bitwise operations;
- mask handling;
- range-based mask generation;
- stable error-isolated C++ interoperability.

The remaining work is substantial in function count, but much of the difficult architecture is already established. The next phase is primarily about broadening the Core API while keeping the same safety, ownership, testing, and Ada design standards.
