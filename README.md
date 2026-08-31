# opencv_core_ada

[![OpenCV Compatibility](https://github.com/zackboll/opencv_core_ada/actions/workflows/opencv-compatibility.yml/badge.svg)](https://github.com/zackboll/opencv_core_ada/actions/workflows/opencv-compatibility.yml)

A thick, idiomatic Ada 2022 binding for the **OpenCV Core** module.

`opencv_core_ada` exposes OpenCV Core through Ada-controlled resources, strong
types, records, overloads, discriminated results, generics, scoped zero-copy
access, and Ada exceptions while keeping the C++ ABI behind a small stable C
interface. It is intentionally an Ada API over OpenCV rather than a mechanical
translation of the C++ headers.

> **Version:** `0.1.0`
>
> **OpenCV compatibility:** **4.1 through 5.0**, inclusive. The public Ada API
> is intended to remain the same across this range. Not every intermediate
> OpenCV release is explicitly tested.
>
> **Development status:** active, pre-1.0 API.
>
> **Current test baseline:** 948 AUnit tests, with Ada and C++ warnings promoted
> to errors. GitHub Actions exercises the full test suite against four OpenCV
> compatibility targets, plus a native Ubuntu 24.04 ARM64 job.
>
> **Scope:** OpenCV **Core** only. Higher-level modules such as `imgproc`,
> `imgcodecs`, `highgui`, `videoio`, `features2d`, `calib3d`, and `dnn` belong
> in separate Ada crates that can depend on this Core binding.

## Project names

Several related names appear in the repository:

| Purpose | Name |
| --- | --- |
| GitHub repository | `opencv_core_ada` |
| Alire crate | `opencv_core` |
| GPR project | `OpenCV_Core` |
| Ada API root | `OpenCV.Core` |
| Built library name | `opencv_core_ada` |

## Contents

- [Goals and scope](#goals-and-scope)
- [OpenCV compatibility](#opencv-compatibility)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Building](#building)
- [Running the tests](#running-the-tests)
- [Quick start](#quick-start)
- [Ownership, views, and zero-copy access](#ownership-views-and-zero-copy-access)
- [Typed access matrix](#typed-access-matrix)
- [Public API overview](#public-api-overview)
- [Linear algebra and decomposition](#linear-algebra-and-decomposition)
- [Spectral transforms](#spectral-transforms)
- [Random numbers, clustering, and nearest neighbors](#random-numbers-clustering-and-nearest-neighbors)
- [Persistence](#persistence)
- [Safety and validation boundary](#safety-and-validation-boundary)
- [SPARK and GNATprove](#spark-and-gnatprove)
- [Known limitations](#known-limitations)
- [Project layout](#project-layout)
- [Development approach](#development-approach)
- [Contributing](#contributing)
- [Versioning](#versioning)
- [License](#license)

---

## Goals and scope

The project is designed around the following principles:

- Provide an **idiomatic Ada API** rather than reproducing C++ syntax.
- Keep C++ implementation details behind a stable **`extern "C"` ABI**.
- Never expose `cv::Mat`, C++ references, templates, STL containers,
  `std::string`, C++ exceptions, raw C status codes, or `Interfaces.C` types in
  the normal public Ada API.
- Represent OpenCV resources with Ada controlled types and preserve OpenCV's
  reference-counted ownership semantics where that is the correct model.
- Prefer strong Ada enums, records, subtypes, discriminated result types,
  generics, overloads, and exceptions over integer flags and output-parameter
  conventions.
- Preserve important OpenCV behavior such as saturation, rounding,
  non-contiguous Regions, multi-channel layouts, floating-point edge cases,
  and version-specific numerical behavior where it affects correctness or
  safety.
- Keep compatibility handling below the public Ada layer whenever practical.
- Keep AUnit, GNATprove, GNATcov, formatting tools, and other development-only
  dependencies out of the public crate.
- Use SPARK selectively for small pure-Ada safety properties where formal proof
  gives a concrete guarantee.
- Inspect authoritative OpenCV declarations and source when exact behavior or
  safety differs from a high-level API description.

Features are built vertically:

```text
public Ada API
     -> thin private Ada C interop
     -> stable C ABI / C++ shim
     -> OpenCV Core
     -> focused AUnit coverage
```

Literal symbol-for-symbol coverage of every internal OpenCV Core implementation
surface is not a goal. The target is broad coverage of portable, user-facing
Core functionality with a coherent Ada design.

---

## OpenCV compatibility

The supported compatibility range is **OpenCV 4.1 through 5.0**. One public Ada
API is used across the range; callers do not select version-specific Ada
packages or conditional APIs.

GitHub Actions currently tests these representative targets:

| OpenCV target | CI environment | OpenCV installation |
| --- | --- | --- |
| `4.1.0` | Debian 12 | Core-focused source build |
| `4.6` | Debian 12 | Distribution development package |
| `4.10` | Debian 13 | Distribution development package |
| `5.0.0` | Debian 13 | Core-focused source build |

These are **validation points, not an exhaustive list of supported releases**.
Intermediate releases within the supported range are not all individually run
in CI.

GitHub Actions also runs the same public test path natively on Ubuntu 24.04
ARM64 against the distribution OpenCV packages. That job is for architecture
portability, not another OpenCV-version matrix entry.

Version differences are isolated in the configuration and C++ shim layers.
Depending on the linked OpenCV release, the shim may use a native API, a
compatible older signature, or a behavior-preserving fallback. This includes
older Core APIs whose signatures or availability changed over the lifetime of
OpenCV 4.x and empty-`Mat` behavior that changed in OpenCV 5.

OpenCV discovery is intentionally version-tolerant. `scripts/configure_opencv.sh`
probes the following pkg-config package names in order:

```text
opencv5
opencv4
opencv
```

It also handles the legacy include-directory variable used by early supported
4.x pkg-config files.

---

## Architecture

The binding is deliberately layered:

```text
Ada application
     |
     v
+-------------------------------------------+
| Thick Ada API                             |
| OpenCV.Core / child packages              |
| controlled types, strong enums, records   |
| exceptions, generics, scoped callbacks    |
+-------------------------------------------+
     |
     v
+-------------------------------------------+
| Thin private Ada interop                  |
| OpenCV.Internal.C_API                     |
| fixed-width C ABI types                   |
+-------------------------------------------+
     |
     v
+-------------------------------------------+
| C++ shim / stable C ABI                   |
| extern "C"                                |
| opaque handles, exception containment     |
| OpenCV-version compatibility handling     |
+-------------------------------------------+
     |
     v
+-------------------------------------------+
| OpenCV Core                               |
| cv::Mat / cv::FileStorage / cv::*         |
+-------------------------------------------+
```

### Thick Ada layer

The public layer is Ada-shaped:

- `Mat` is a tagged controlled type.
- ordinary `Mat` assignment is shallow, matching `cv::Mat` header semantics;
- `Clone` is the explicit deep-copy operation;
- `File_Storage` is a limited controlled type with exclusive ownership;
- normal failures raise `OpenCV_Error`, while mathematically meaningful
  success/failure states use discriminated result types where appropriate;
- multi-result OpenCV operations return Ada records instead of exposing output
  parameters;
- typed data access is exposed through dedicated child packages rather than raw
  pointers.

### Thin Ada interop

`OpenCV.Internal.C_API` defines the fixed C ABI used by the thick layer. It is
an implementation detail, not the normal application interface.

### C++ shim

The shim:

- exports only C-compatible functions;
- uses opaque handles for C++ objects;
- uses fixed-width integers and simple C-compatible records;
- validates raw ABI and memory-safety conditions;
- contains OpenCV-version-specific compatibility code;
- initializes caller-visible outputs before work that may fail;
- catches OpenCV, standard C++, and unknown exceptions;
- converts failures into stable status codes and diagnostic text;
- never allows a C++ exception or C++ object lifetime to cross directly into
  Ada.

---

## Requirements

A normal build requires:

- an Ada toolchain supported by Alire;
- **Alire**;
- a C++17 compiler;
- **pkg-config**;
- OpenCV development headers and libraries in the supported 4.1-5.0 range;
- the OpenCV Core library (`opencv_core`).

The project links against:

```text
opencv_core
libstdc++   (Linux)
libc++      (macOS)
```

On macOS the C++ shim is compiled with Apple `clang++` and linked against
`libc++` so it matches Homebrew OpenCV. Ada remains on the GNAT toolchain.
Linux continues to compile C++ with `g++` and link `libstdc++`.

The compatibility containers currently use Alire 2.1.1, GNAT 16.1.0, and
GPRbuild 26.0.1. Those pinned versions make CI reproducible; they are not a
claim that every local build must use exactly those versions.

OpenCV include and library paths are discovered by:

```text
scripts/configure_opencv.sh
```

The script accepts pkg-config metadata under `opencv5`, `opencv4`, or `opencv`.

---

## Building

Clone and build:

```sh
git clone https://github.com/zackboll/opencv_core_ada.git
cd opencv_core_ada
alr build
```

The Alire pre-build action runs `scripts/configure_opencv.sh`, which creates the
local OpenCV GPR configuration from pkg-config metadata.

If configuration fails, first check what OpenCV pkg-config name is available:

```sh
pkg-config --modversion opencv5 || \
pkg-config --modversion opencv4 || \
pkg-config --modversion opencv
```

The GPR project supports the standard library kinds through
`OPENCV_CORE_LIBRARY_TYPE` (falling back to `LIBRARY_TYPE`):

```text
static-pic    (default)
static
relocatable
```

For example:

```sh
OPENCV_CORE_LIBRARY_TYPE=relocatable alr build
```

Both Ada and C++ are compiled with warnings promoted to errors. C++ is compiled
as C++17 with `-Wall -Wextra -Wpedantic -Werror`.

---

## Running the tests

Tests live in a separate Alire crate under `tests/`:

```sh
alr -C tests build
alr -C tests run
```

The test crate carries development-only dependencies such as AUnit, GNATprove,
and GNATcov. They are intentionally not dependencies of the public library
crate.

At the time of this README update, the full suite contains **948 AUnit tests**.
Coverage includes ordinary behavior, invalid input, shape/depth/channel
compatibility, empty Mats, non-contiguous Regions, shallow-versus-independent
ownership, callback lifetimes, arbitrary Ada array lower bounds, failure
atomicity, persistence, numerical boundary behavior, and version compatibility.

The `OpenCV Compatibility` GitHub Actions workflow runs the same test suite
against all four compatibility targets listed above, and on native Ubuntu 24.04
ARM64. `fail-fast` is disabled so a failure on one target does not hide the
state of the others.

---

## Quick start

### Create and access a matrix

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
     (Image, Row => 10, Column => 20, Value => 255);

   Value :=
     OpenCV.Core.UInt8_Access.Get
       (Image, Row => 10, Column => 20);

   Ada.Text_IO.Put_Line (UInt8_Value'Image (Value));
end Example;
```

`Create` follows native `cv::Mat` allocation semantics: newly allocated element
storage is **not automatically zero-filled**. Initialize explicitly when a
known initial value is required:

```ada
Image.Set_To (Make_Scalar (0.0));
```

### Create from `Size`

```ada
Image : Mat :=
  Create
    (Dimensions   => (Width => 640, Height => 480),
     Element_Type => (Depth => Float32, Channels => 1));

Dims : constant Size := Image.Dimensions;
```

`Size.Width` maps to columns and `Size.Height` maps to rows.

### Create a shared Region

```ada
ROI : Mat :=
  Image.Region
    ((X      => 100,
      Y      => 50,
      Width  => 200,
      Height => 100));
```

A Region has its own `Mat` header but shares the parent's storage.

### Borrow a row without copying

```ada
with OpenCV.Core.Float32_Row_Access;

procedure Inspect_Row
  (Data : aliased OpenCV.Core.Float32_Row_Access.Row_Array)
is
begin
   -- Data (0) is column 0 of the borrowed row.
   null;
end Inspect_Row;

OpenCV.Core.Float32_Row_Access.With_Read_Only_Row
  (Image   => Image,
   Row     => 0,
   Process => Inspect_Row'Access);
```

The callback is the lifetime boundary. The row directly aliases `Mat` storage
and no pixel values are copied.

### Wrap caller-owned packed storage in a temporary `Mat`

```ada
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;

procedure External_Buffer_Example is
   Data : aliased OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
     (11 => 10,
      12 => 20,
      13 => 30,
      14 => 40,
      15 => 50,
      16 => 60);

   procedure Process (Image : in out OpenCV.Core.Mat) is
   begin
      OpenCV.Core.UInt8_Access.Set
        (Image, Row => 1, Column => 0, Value => 200);
      -- Data (14) is now 200 immediately. There is no copy-back phase.
   end Process;
begin
   OpenCV.Core.UInt8_Mat_View.With_Writable_Mat_View
     (Data, Rows => 2, Columns => 3, Process => Process'Access);
end External_Buffer_Example;
```

`Data'Length` must equal `Rows * Columns`. The Ada lower bound is arbitrary.
The temporary `Mat` does not own the caller's storage.

### Wrap row-strided Float32 storage

`OpenCV.Core.Float32_Mat_View` also provides a row-strided overload:

```ada
OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
  (Data                => Data,
   Rows                => 3,
   Columns             => 4,
   Row_Stride_Elements => 8,
   Process             => Process'Access);
```

Each logical row exposes the first `Columns` Float32 elements of its stride.
Padding remains outside the `Mat`. `Row_Stride_Elements` must be at least
`Columns`, and the caller retains ownership of the complete backing buffer.

---

## Ownership, views, and zero-copy access

`OpenCV.Core.Mat` is a tagged private Ada controlled type.

### Ordinary assignment is shallow

```ada
B := A;
```

`B` receives a distinct `cv::Mat` header sharing the same OpenCV-owned storage
with `A`. Mutations through either alias are visible through the other.

### `Clone` is deep

```ada
B := A.Clone;
```

The clone owns independent pixel storage.

### Shared-storage views

The public API includes no-copy views such as:

- `Region`
- `Row_View`
- `Column_View`
- row-range and column-range view overloads
- `Slice`
- `Reshape`
- `Diagonal_View`

For ordinary OpenCV-owned Mats, these headers retain the shared allocation by
normal OpenCV reference counting.

### Copied row access

The UInt8, Float32, UInt8 Vec3, and Float32 Vec3 row packages provide
`Read_Row` / `Write_Row` APIs. Caller arrays may use arbitrary lower bounds;
values map in iteration order to matrix columns.

These are copy-based APIs and are useful when the caller wants an ordinary Ada
array with no borrowed lifetime.

### Scoped zero-copy row borrowing

The same four row-access families provide:

```text
With_Read_Only_Row
With_Writable_Row
```

The callback receives a zero-based array that directly overlays one logical
OpenCV row. Row borrowing works with non-contiguous 2-D Regions because only
the active logical row is exposed; inter-row padding is never exposed.

A shallow `Mat` lease is retained during the callback so the underlying OpenCV
allocation cannot disappear merely because another header is rebound or
finalized. The lease is a lifetime mechanism, not thread synchronization.

### Scoped continuous whole-buffer borrowing

The four matching buffer-access packages provide:

```text
With_Read_Only_Buffer
With_Writable_Buffer
```

The callback receives a flat zero-based row-major array of `Image.Total`
elements. Nonempty Mats must be continuous. Continuous Regions are accepted.
There is no per-row copy and no write-back phase.

### Caller-owned buffer -> temporary `Mat`

The four Mat-view packages provide the reverse zero-copy direction:

```text
OpenCV.Core.UInt8_Mat_View
OpenCV.Core.Float32_Mat_View
OpenCV.Core.UInt8_Vec3_Mat_View
OpenCV.Core.Float32_Vec3_Mat_View
```

`With_Writable_Mat_View` creates a callback-scoped `cv::Mat` header over the
actual caller-owned Ada array. The public buffer formal is explicitly
`aliased in out`, so the native header directly denotes the caller's storage.

Packed views are available for all four typed layouts above. Float32 C1 also
supports an explicit row stride through `Row_Stride_Elements`, allowing a Mat
to represent the logical columns of a padded caller-owned row layout without
copying the padding.

Important lifetime rule: a temporary external-buffer Mat may not create a
shallow alias that could outlive the callback. Ordinary `Mat` assignment and
no-copy view operations are therefore rejected for these temporary external
views. `Clone` remains allowed because it creates independent OpenCV-owned
storage that can safely outlive the callback.

The external-data `Mat` header is destroyed at callback exit, including during
exception unwinding; the caller's Ada array is never freed by OpenCV.

For a row-strided external view, `Is_Continuous` reflects OpenCV's actual layout
rules. A multirow view with padding is non-contiguous, so operations requiring a
single packed buffer must reject it; row-based and other non-contiguous-aware
operations can still be used.

---

## Typed access matrix

Direct typed access currently concentrates on four common layouts:

| Layout | Element Get/Set | Copied row | Borrowed row | Continuous buffer borrow | Packed caller buffer -> `Mat` | Strided caller buffer -> `Mat` |
| --- | --- | --- | --- | --- | --- | --- |
| UInt8 C1 | `UInt8_Access` | `UInt8_Row_Access` | `UInt8_Row_Access` | `UInt8_Buffer_Access` | `UInt8_Mat_View` | — |
| Float32 C1 | `Float32_Access` | `Float32_Row_Access` | `Float32_Row_Access` | `Float32_Buffer_Access` | `Float32_Mat_View` | `Float32_Mat_View` |
| UInt8 C3 | `UInt8_Vec3_Access` | `UInt8_Vec3_Row_Access` | `UInt8_Vec3_Row_Access` | `UInt8_Vec3_Buffer_Access` | `UInt8_Vec3_Mat_View` | — |
| Float32 C3 | `Float32_Vec3_Access` | `Float32_Vec3_Row_Access` | `Float32_Vec3_Row_Access` | `Float32_Vec3_Buffer_Access` | `Float32_Vec3_Mat_View` | — |

For Vec3 APIs, **one Ada vector is one complete OpenCV element/pixel**, not one
scalar channel:

- UInt8 Vec3: 24 bits / 3 bytes per element, native alignment 1;
- Float32 Vec3: 96 bits / 12 bytes per element, native scalar alignment 4.

The predefined Vec3 packages are component-oriented and do not impose RGB,
BGR, XYZ, or any other semantic channel interpretation.

Generic pure-Ada value abstractions are also provided:

```ada
generic
   type Element_Type is private;
   Length : Positive;
package OpenCV.Core.Vectors;
```

and:

```ada
generic
   type Element_Type is private;
   Row_Count : Positive;
   Column_Count : Positive;
package OpenCV.Core.Fixed_Matrices;
```

A predefined Float32 3x3 fixed matrix and copy conversions to/from `Mat` are
included. C++ `cv::Matx` objects do not cross the ABI.

---

## Public API overview

The following is a practical overview of the current public surface. Exact
shape, depth, channel, continuity, and numerical restrictions are documented on
the Ada declarations and covered by tests.

### Core types

Major public abstractions include:

- `Mat`, `Mat_Type`, `Depth_Type`, `Channel_Count`, `Mat_Size`
- `Size`, `Point`, `Point_Array`, `Rect`, `Index_Range`, `Index_Range_Array`, `Scalar`
- `Mat_Array`
- `Random_Number_Generator`
- `Min_Max_Result`, `Mean_Std_Dev_Result`, `Range_Check_Result`
- `Inversion_Result`, `Solve_Result`, `Linear_Program_Result`
- `Polar_Coordinates`, `Cartesian_Coordinates`
- `Covariance_Result`, `Eigen_Decomposition_Result`
- `Principal_Component_Analysis_Result`
- `Linear_Discriminant_Analysis_Result`
- `Singular_Value_Decomposition_Result`
- `K_Means_Result`, `Nearest_Neighbor_Result`
- cubic and polynomial solution result types
- channel routing records and arrays.

The public depth enumeration contains:

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

### Creation, shape, metadata, and views

Creation and structure:

- `Create`
- `Clone`
- `Copy_To`
- masked `Copy_To`
- `Region`
- `Row_View`
- `Column_View`
- range views
- `Slice`
- `Reshape`
- `Diagonal_View`
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

`Index_Range` is half-open:

```text
Start <= index < Stop
```

### Conversion and element-wise mathematics

Conversion/mapping:

- `Convert_To`
- `Convert_Scale_Abs`
- `Apply_LUT`
- `Normalize`

Element-wise mathematics and coordinate conversion:

- `Sqrt`
- `Exp`
- `Log`
- `Pow`
- `Magnitude`
- `Phase`
- `Cart_To_Polar`
- `Polar_To_Cart`

### Arithmetic

Explicit Mat/Mat operations include:

- `Add`
- `Subtract`
- `Multiply` — element-wise
- `Divide` — element-wise
- `Abs_Diff`
- `Minimum`
- `Maximum`
- `Add_Weighted`
- `Scale_Add`

Algebraic multiplication is deliberately separate as `Matrix_Multiply`.

### Masks and selection

Mask production and selection include:

- `In_Range`
- `Compare`
- `Count_Non_Zero`
- `Has_Non_Zero`
- `Find_Non_Zero`

Masked consumers include:

- `Copy_To`
- `Set_To`
- bitwise operations
- `Mean`
- `Mean_Std_Dev`
- `Norm`
- `Min_Max_Loc`

The common mask model is a same-shape UInt8 C1 Mat; any nonzero mask value
selects the complete source element.

### Bitwise operations

Available masked/unmasked families include:

- `Bitwise_And`
- `Bitwise_Or`
- `Bitwise_Xor`
- `Bitwise_Not`

OpenCV's stored-bit interpretation is preserved for floating-point Mats.

### Channel manipulation

Current channel operations include:

- `Split`
- `Merge`
- `Extract_Channel`
- `Insert_Channel`
- `Mix_Channels`
- `Channel_Route`
- explicit zero-fill routing

Collection APIs respect Ada array iteration order instead of assuming lower
bound zero.

### Layout, rearrangement, and borders

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
- `Border_Interpolate`

Border modes use strong Ada values rather than exposing OpenCV integer flags.
`Border_Interpolate` returns an Ada discriminated result for constant-border
coordinates instead of exposing OpenCV's `-1` sentinel.

### Sorting, reductions, and statistics

Sorting:

- `Sort`
- `Sort_Indices`

Scalar/statistical operations include:

- `Sum`
- `Trace`
- `Mean`
- `Mean_Std_Dev`
- `Norm`
- `Min_Max_Loc`
- `Count_Non_Zero`
- `Has_Non_Zero`
- `Find_Non_Zero`
- `Dot_Product`
- `Mahalanobis_Distance`
- `Covariance`
- `Peak_Signal_To_Noise_Ratio`

Axis reduction:

- `Reduce` with Sum, Average, Maximum, Minimum, and Sum of Squares
- explicit output-depth overloads
- `Arg_Minimum`
- `Arg_Maximum`
- first/last equal-extremum selection through `Extremum_Occurrence`

Range/non-finite operations:

- `Check_Range`
- bounded `Check_Range`
- `Patch_NaNs`

### In-place initialization and symmetry

- `Set_To`
- `Set_Identity`
- `Complete_Symmetry`

### Per-element transforms

- `Transform`
- `Perspective_Transform`

These transform channel vectors stored at each element. They are not image
resampling/warping operations; those belong in an `imgproc` binding.

### Polynomial and optimization helpers

The current Core slice also includes:

- `Solve_Cubic`
- `Solve_Polynomial`
- `Solve_Linear_Program`

These APIs use Ada result types to represent mathematically meaningful status
rather than exposing raw OpenCV integer return conventions.

---

## Linear algebra and decomposition

Dense linear-algebra coverage is substantial.

### Basic algebra

- `Trace`
- `Determinant`
- LU `Invert`
- LU `Solve`
- `Solve_Least_Squares` using SVD
- `Dot_Product`
- `Cross_Product`
- `Mahalanobis_Distance`
- `Matrix_Multiply`
- `Matrix_Multiply_Add`
- centered and uncentered `Transposed_Product`
- `Set_Identity`
- `Complete_Symmetry`

`Multiply` remains element-wise. `Matrix_Multiply` is algebraic multiplication.

### Covariance and eigen decomposition

- `Covariance`
- symmetric `Eigen_Decomposition`
- `Non_Symmetric_Eigen_Decomposition`

The symmetric API requires a caller-supplied real symmetric matrix. The
non-symmetric API follows OpenCV's real-eigenvalue assumptions rather than
inventing complex-eigenvalue behavior.

### PCA

- `Principal_Component_Analysis`
- explicit component-count selection
- retained-variance selection
- `PCA_Project`
- `PCA_Back_Project`

Both row-oriented and column-oriented sample layouts are represented explicitly
through `Sample_Orientation`.

### LDA

- `Linear_Discriminant_Analysis`
- explicit component-count overload
- `LDA_Project`
- `LDA_Reconstruct`

LDA uses a dedicated result record and keeps OpenCV's basis representation
behind an Ada-friendly API.

### SVD family

- compact `Singular_Value_Decomposition`
- `SVD_Back_Substitute`
- `SVD_Solve_Zero`
- `Pseudo_Inverse`
- `Reciprocal_Condition_Number`

### LU versus SVD APIs

`Invert` and `Solve` deliberately remain LU-specific. Least-squares and
rank-deficient SVD pseudo-solutions, SVD back substitution, pseudoinverse,
condition number, and null-space solving are separate explicit APIs instead of
being hidden behind a C++ decomposition flag. Rank-deficient
`Solve_Least_Squares` is a residual-minimizing `cv::solve(DECOMP_SVD)` result,
not a uniquely specified Moore-Penrose minimum-norm vector.

---

## Spectral transforms

The current spectral slice includes full-complex and packed real-input DFT
support, plus orthonormal DCT support:

- `Discrete_Fourier_Transform`
- `Inverse_Discrete_Fourier_Transform`
- `Inverse_Real_Discrete_Fourier_Transform`
- `Packed_Discrete_Fourier_Transform`
- `Inverse_Packed_Discrete_Fourier_Transform`
- `Discrete_Fourier_Transform_Rows`
- `Inverse_Discrete_Fourier_Transform_Rows`
- `Inverse_Real_Discrete_Fourier_Transform_Rows`
- `Discrete_Cosine_Transform`
- `Inverse_Discrete_Cosine_Transform`
- `Discrete_Cosine_Transform_Rows`
- `Inverse_Discrete_Cosine_Transform_Rows`
- `Multiply_Spectra`
- `Multiply_Packed_Spectra`
- `Optimal_DFT_Size`

Two Fourier representations are available. `Discrete_Fourier_Transform`
returns a full two-channel (`C2`) complex spectrum. For real (`C1`) input,
`Packed_Discrete_Fourier_Transform` returns OpenCV's native same-shape,
same-depth packed CCS (`C1`) spectrum. The packed representation is opaque and
is primarily intended for efficient spectral pipelines and inverse
transformation; its physical storage layout follows OpenCV. Both inverse paths
are scaled, so a forward/inverse round trip approximately recovers the source
without an extra caller scale factor.
`Inverse_Real_Discrete_Fourier_Transform` provides the real-output path for
conjugate-symmetric spectra. The corresponding `_Rows` operations use
`DFT_ROWS` to transform every row as an independent 1-D signal while preserving
the same full-complex representation and scaled inverse convention.
The corresponding row-wise DCT operations use `DCT_ROWS` and OpenCV's
orthonormal inverse convention. Only the row length must be one or even; the
number of independent rows may be odd.

`Multiply_Spectra` operates on full-complex C2 spectra, while
`Multiply_Packed_Spectra` operates on packed CCS C1 spectra. Both distinguish
ordinary spectral multiplication from conjugate-right multiplication with
`Spectrum_Multiplication_Kind`. Spectrum multiplication does not automatically
inverse-transform, pad, crop, or otherwise construct a complete convolution or
correlation pipeline.

Packed row transforms, packed spectrum division, CCS-bin accessors,
representation conversion, and in-place transforms are not yet exposed.

---

## Random numbers, clustering, and nearest neighbors

### RNG

The API supports both OpenCV's thread-local default RNG and caller-owned RNG
state:

- `Set_Random_Seed`
- `Make_Random_Number_Generator`
- `Next_Random`
- `Uniform_Random`
- `Fill_Uniform`
- `Fill_Normal`
- `Shuffle`

`Fill_Uniform`, `Fill_Normal`, and `Shuffle` have overloads using an explicit
caller-owned generator, allowing deterministic sequences without mutating the
calling thread's default OpenCV RNG state.

The RNG is deterministic pseudorandom state, not a cryptographic RNG.

### K-means

`K_Means` supports:

- random centers;
- k-means++ centers;
- configurable count+epsilon criteria;
- multiple attempts;
- an overload using caller-supplied initial labels.

The result record contains independently owned labels, centers, and compactness.

### K-nearest neighbors / batch distance

`K_Nearest_Neighbors` exposes a focused nearest-neighbor slice over OpenCV
batch-distance behavior. Supported distance kinds include:

- L1
- L2
- squared L2
- Hamming
- Hamming2

The result contains independent distance and zero-based candidate-index Mats.

---

## Persistence

Persistence is provided by:

```ada
OpenCV.Core.Persistence
```

through a limited controlled `File_Storage` abstraction over `cv::FileStorage`.

### Formats and backends

Supported formats:

```text
XML
YAML
JSON
```

Disk `Open` selects the format from the filename extension:

```text
.xml
.yml
.yaml
.json
```

Memory writers select the format explicitly with `Create_Memory`; memory
readers use `Open_Memory`, letting OpenCV detect the serialized format.

### Supported values

Named and sequence values currently include:

- `Mat`
- `Integer`
- `Long_Float`
- `String`

### Nested mappings and sequences

The current persistence API supports hierarchy without exposing `FileNode`.

Writing:

- named and unnamed `Begin_Map`
- named and unnamed `Begin_Sequence`
- `End_Structure`
- named `Write`
- sequence `Append`

Reading:

- named/indexed `Enter_Map`
- named/indexed `Enter_Sequence`
- `Leave_Structure`
- `Sequence_Length`
- named/indexed `Read_Mat`
- named/indexed `Read_Integer`
- named/indexed `Read_Real`
- named/indexed `Read_String`

Example:

```ada
with OpenCV.Core.Persistence;

declare
   package P renames OpenCV.Core.Persistence;
   Storage : P.File_Storage := P.Create_Memory (P.JSON);
begin
   Storage.Begin_Map ("Camera");
   Storage.Write ("Name", "Front Camera");

   Storage.Begin_Sequence ("Distortion");
   Storage.Append (0.1);
   Storage.Append (-0.05);
   Storage.Append (0.001);
   Storage.End_Structure;

   Storage.End_Structure;

   declare
      Text : constant String := Storage.Close_And_Get_Text;
   begin
      null;
   end;
end;
```

The implicit FileStorage root is a mapping. Hierarchy is navigated by the
controlled `File_Storage` object itself; no public `FileNode` lifetime is
exposed.

### Type policy and edge conditions

The API avoids surprising lossy conversions:

```text
integer node -> Read_Integer    allowed
real node    -> Read_Integer    rejected

real node    -> Read_Real       allowed
integer node -> Read_Real       allowed by widening

string node  -> Read_String     allowed
other node   -> Read_String     rejected
```

Missing nodes raise `OpenCV_Error`; actual stored zero, empty string, empty Mat,
empty map, and empty sequence remain distinguishable from absence.

Integer writes use OpenCV's signed 32-bit file node. The binding currently
supports the write range:

```text
-2_147_483_647 .. 2_147_483_647
```

The signed 32-bit minimum is rejected rather than entering an unsafe native
integer-formatting path present in affected supported releases.

Embedded NUL is rejected in filenames, node names, String values, and memory
input because those paths cross NUL-terminated native interfaces.

---

## Safety and validation boundary

The project separates **public semantic validation** from **raw ABI safety**.

### Ada layer

The thick API normally validates caller-facing rules such as:

- shape compatibility;
- depth and channel restrictions;
- index and Region bounds;
- continuity requirements for whole-buffer borrowing;
- legal enum/mode combinations;
- non-empty requirements;
- exact caller-buffer shape/stride requirements for external views;
- string restrictions that cannot safely cross the underlying native
  interface.

### C++ shim

The shim defensively validates conditions a raw C caller could violate and
conditions needed to keep the C++ call safe:

- null handles and output pointers;
- fixed ABI enum decoding;
- pointer/count and byte-count relationships;
- signed arithmetic before OpenCV receives arguments;
- pointer alignment and row-step arithmetic for external Mat storage;
- failure-atomic handle publication;
- C++ exception containment.

### Source-backed safety boundaries

Where a supported OpenCV implementation contains signed intermediate arithmetic
or other source-level hazards, the binding establishes an Ada/C-ABI boundary
before the native call instead of relying on undefined behavior.

Examples in the current codebase include:

- signed product guards around SVD/pseudoinverse and related workspaces;
- eigensolver and decomposition size guards;
- DFT/DCT dimension and work-buffer arithmetic checks;
- persistence integer and embedded-NUL restrictions;
- exact external-buffer byte-count, stride, and alignment checks;
- prevention of shallow aliases escaping callback-scoped external-buffer Mats.

Compatibility code follows the same rule: version-dependent details belong in
the configuration/C++ boundary rather than leaking into the thick Ada API.

---

## SPARK and GNATprove

Formal verification is focused on small pure-Ada safety helpers rather than
foreign-resource ownership or OpenCV numerical algorithms.

The current proof island is:

```text
OpenCV.Internal.Safe_Arithmetic
```

with `SPARK_Mode => On`.

It currently contains proved contracts for:

- `Product_Exceeds_Signed_Int32`
- `Fits_Signed_Int32`
- `To_Signed_Int32`

This supports safe dimensional and ABI conversions without trying to prove the
C++ library itself.

GNATprove is supplied by the separate `tests` Alire environment.

---

## Known limitations

The current limitations are intentional and help keep the public API coherent:

1. **The dense public `Mat` model is primarily 2-D.**  
   N-dimensional construction, UInt8/Float32 C1 Get/Set, and `Slice` views are
   available. N-D reshape and dimension-dropping scalar indexing are not yet
   exposed as a complete Ada model.

2. **No public `SparseMat` or `UMat` abstraction.**

3. **Typed direct/zero-copy access is focused on UInt8 and Float32 C1/C3.**  
   Other OpenCV depths are available to general Mat operations but do not yet
   have the same typed Get/Set, row, buffer-borrow, and external-view families.

4. **External caller-buffer views are writable and callback-scoped.**  
   Packed 2-D views are available for UInt8/Float32 C1/C3. Row-strided external
   storage is currently exposed only for Float32 C1. A general stride model for
   every typed layout and a separate read-only external Mat abstraction are not
   yet exposed.

5. **Whole-buffer borrowing requires a continuous nonempty Mat.**  
   Use row borrowing for non-contiguous 2-D Regions or row-strided Mats.

6. **Scalar-valued APIs represent at most four components.**  
   Operations returning `Scalar` validate channel limits rather than silently
   discarding channels.

7. **Arithmetic overloads are intentionally conservative.**  
   The public API does not mirror the full C++ Mat/Scalar, masked, mixed-depth,
   and expression-template overload matrix.

8. **`Invert` and ordinary `Solve` are LU-specific.**  
   Least-squares, SVD back-substitution, null-space solving, pseudoinverse, and
   condition-number behavior are exposed as separate explicit APIs.

9. **No general public `cv::MatExpr` equivalent.**  
   The Ada interface favors explicit operations and explicit ownership.

10. **No raw public pixel pointers or `System.Address` API.**  
    Zero-copy use cases are expressed through callback-scoped typed views.

11. **No public raw OpenCV integer mode flags.**  
    Wrapped modes use strong Ada types or deliberately narrower operations.

12. **Persistence hides `FileNode`.**  
    Nested maps and sequences are supported, but map-key enumeration, public
    FileNode iterators, file append mode, Base64, comments, gzip controls, FLOW
    formatting, and raw persistence APIs are not part of the current slice.

13. **The spectral API is deliberately focused.**  
    Full-complex DFT/DCT workflows are supported, but packed CCS, `DFT_ROWS`,
    and in-place transform APIs are not exposed.

14. **The supported OpenCV range is not exhaustively tested release-by-release.**  
    CI validates four representative OpenCV-version targets across 4.1-5.0, plus
    native Ubuntu 24.04 ARM64 against distribution OpenCV. Compatibility
    fixes are kept below the public Ada API, but an untested intermediate
    release may still expose an undiscovered upstream difference.

15. **The API is pre-1.0.**  
    Names and overloads may still evolve as N-D matrices, broader typed access,
    additional strided layouts, persistence features, and future cross-module
    integration are designed.

---

## Project layout

```text
opencv_core_ada/
├── .github/
│   └── workflows/
│       └── opencv-compatibility.yml
├── .clinerules/
├── alire.toml
├── opencv_core.gpr
├── LICENSE
├── README.md
├── containers/
│   └── ... compatibility container definitions ...
├── cpp/
│   ├── opencv_core_shim.cpp
│   └── opencv_core_shim.h
├── scripts/
│   └── configure_opencv.sh
├── src/
│   ├── opencv.ads
│   ├── opencv-core.ads
│   ├── opencv-core.adb
│   ├── opencv-core-persistence.ads
│   ├── opencv-core-persistence.adb
│   ├── opencv-core-*_access.*
│   ├── opencv-core-*_row_access.*
│   ├── opencv-core-*_buffer_access.*
│   ├── opencv-core-*_mat_view.*
│   ├── opencv-core-*_vec3*
│   ├── opencv-core-vectors.ads
│   ├── opencv-core-fixed_matrices.ads
│   ├── opencv-core-float32_matx3x3*
│   └── internal/
└── tests/
    ├── alire.toml
    ├── tests.gpr
    └── src/
        ├── tests.adb
        ├── mat_tests.*
        ├── mat_*_tests.*
        ├── persistence_tests.*
        ├── cubic_tests.*
        ├── polynomial_tests.*
        ├── k_means_tests.*
        ├── k_nearest_neighbor_tests.*
        ├── random_tests.*
        └── linear_discriminant_analysis_tests.*
```

`config/opencv_core_install.gpr` is generated locally by
`scripts/configure_opencv.sh` and is not a hand-maintained public interface.

---

## Development approach

New vertically integrated features generally follow this sequence:

1. Inspect authoritative OpenCV declarations, implementation source, and tests
   for the target operation and supported-version differences.
2. Inspect existing repository conventions and nearby Ada abstractions.
3. Design the public thick Ada API and its deliberate restrictions.
4. Separate public semantic validation from raw C ABI/memory-safety validation.
5. Add only the C ABI surface actually required.
6. Implement the C++ shim with exception containment, compatibility handling,
   and failure-atomic output publication.
7. Add/update the thin Ada import.
8. Implement the thick Ada operation.
9. Add focused AUnit coverage, including non-contiguous Regions and ownership
   cases where relevant.
10. Build the public crate with warnings as errors.
11. Build and run the complete tests crate.
12. Let the compatibility workflow exercise all CI OpenCV targets.
13. Run targeted GNATprove when a SPARK proof boundary changes.
14. Inspect the final diff and keep the change vertically focused.

For typed zero-copy work, additional rules apply:

- prove the Ada element representation before overlaying native storage;
- keep raw addresses internal;
- use callback-scoped lifetimes;
- retain OpenCV storage with a controlled lease while borrowed;
- require explicit `aliased` formals where caller-owned Ada storage is passed
  directly to native code;
- validate row strides and byte-step arithmetic before constructing external
  native headers;
- prohibit shallow escape from temporary external-buffer Mats;
- never silently fall back to copying when an API is documented as zero-copy.

---

## Contributing

Contributions should preserve the central abstraction boundary:

```text
idiomatic Ada
    |
    v
thin fixed C ABI
    |
    v
C++ shim
    |
    v
OpenCV Core
```

Please avoid:

- exposing `Interfaces.C`, status codes, raw handles, or raw pointers in the
  normal public API;
- passing C++ objects through Ada;
- leaking OpenCV-version conditionals into the public Ada API when the shim can
  absorb them;
- mechanically reproducing C++ overloads without considering Ada ergonomics;
- exposing raw OpenCV integer flags when a strong Ada type is suitable;
- silently changing shallow/deep ownership semantics;
- adding test/proof/coverage tooling to the public crate merely for development
  convenience;
- manually reimplementing an OpenCV algorithm when a corresponding Core
  primitive exists and is available across the compatibility strategy;
- suppressing warnings simply to make a build pass;
- broad unrelated cleanup in otherwise focused feature changes.

Small, vertically complete features with focused tests are preferred over large
partially integrated batches.

---

## Versioning

The Alire crate version is currently:

```text
0.1.0
```

The API should still be considered experimental until 1.0. Public names and
some overloads may evolve as broader typed access, N-dimensional matrices,
additional strided layouts, persistence extensions, and cross-module
integration reveal better Ada abstractions.

---

## License

`opencv_core_ada` is licensed under the **Apache License 2.0**.

See `LICENSE` for the full license text.

OpenCV is a separate project with its own license and copyright holders.

---

## Summary

`opencv_core_ada` provides a broad Ada foundation for OpenCV Core with one thick
Ada API across the supported 4.1-5.0 compatibility range:

- controlled `Mat` ownership, shallow aliases, Regions, ranges, reshape, and
  explicit deep cloning;
- typed UInt8/Float32 C1 and C3 element access;
- copied rows plus scoped zero-copy row and continuous-buffer borrowing;
- callback-scoped zero-copy `Mat` views over caller-owned UInt8/Float32 C1/C3
  packed buffers and row-strided Float32 C1 storage;
- conversions, arithmetic, masks, bitwise operations, channel routing, sorting,
  rearrangement, borders, reductions, arg-reductions, statistics, PSNR, and
  range handling;
- element-wise mathematics, coordinate transforms, per-element linear and
  perspective transforms;
- DFT, inverse DFT, real inverse DFT, DCT, inverse DCT, spectral multiplication,
  and optimal transform-size selection;
- deterministic default/caller-owned RNG workflows, uniform/normal fills,
  shuffle, K-means, and K-nearest neighbors;
- determinant, LU solve/invert, least squares, GEMM, covariance, symmetric and
  non-symmetric eigen decomposition, PCA, LDA, compact SVD, SVD
  back-substitution, null-space solving, pseudoinverse, and reciprocal condition
  number;
- cubic and polynomial solving plus continuous linear programming;
- XML/YAML/JSON FileStorage persistence on disk and in memory, including nested
  maps and sequences while keeping `FileNode` private;
- version-aware compatibility handling behind a stable error-isolated C++ ABI;
- warnings-as-errors builds, targeted SPARK proof, and a four-target OpenCV
  compatibility workflow.

The cross-language architecture and typed zero-copy ownership model are
established. Future work can focus on genuinely new Core capabilities and
broader Ada abstractions without fragmenting the public API by OpenCV version.
