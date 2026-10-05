# opencv_core_ada

[![OpenCV Compatibility](https://github.com/zackboll/opencv_core_ada/actions/workflows/opencv-compatibility.yml/badge.svg)](https://github.com/zackboll/opencv_core_ada/actions/workflows/opencv-compatibility.yml)

A thick, idiomatic Ada 2022 binding for the **OpenCV Core** module.

`opencv_core_ada` exposes OpenCV Core through Ada-controlled resources, strong
types, records, overloads, discriminated results, generics, scoped zero-copy
access, and Ada exceptions while keeping the C++ ABI behind a small stable C
interface. It is intentionally an Ada API over OpenCV rather than a mechanical
translation of the C++ headers.

> **Version:** `0.4.0`
>
> **OpenCV compatibility:** **4.1 through 5.0**, inclusive. The public Ada API
> is intended to remain the same across this range. Not every intermediate
> OpenCV release is explicitly tested.
>
> **Development status:** active, pre-1.0 API.
>
> **Current test baseline:** 1686 AUnit tests, with Ada and C++ warnings promoted
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
| Ada API root | `OpenCV` |
| Core Mat API | `OpenCV.Core` |
| Built library name | `opencv_core_ada` |

## Contents

- [Goals and scope](#goals-and-scope)
- [OpenCV compatibility](#opencv-compatibility)
- [Architecture](#architecture)
- [Cross-module interoperability](#cross-module-interoperability)
- [Requirements](#requirements)
- [Building](#building)
- [Running the tests](#running-the-tests)
- [Quick start](#quick-start)
- [Shared value types](#shared-value-types)
- [Ownership, views, and zero-copy access](#ownership-views-and-zero-copy-access)
- [Sparse matrices](#sparse-matrices)
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

## Cross-module interoperability

Module crates such as `opencv_imgproc`, `opencv_imgcodecs`,
`opencv_highgui`, `opencv_videoio`, `opencv_features2d`, and
`opencv_calib3d` depend on `opencv_core`. Application code continues to use
the public Core types such as `OpenCV.Core.Mat`, `OpenCV.Core.UMat`, and
`OpenCV.Core.Sparse.Sparse_Mat`; no public raw-pointer API is introduced.

`OpenCV.Core.Module_Interop` is a deliberately low-level binding
implementation interface for those crates. Its callback-scoped input and
output handles are passed only to a module's private Ada/C++ interop. Core
provides the installed `opencv_core_module_bridge.hpp` header for the module
shim. The header is installed in the dependent project's `include` artifact
directory by the Core GPR project, rather than being found through a
repository-relative path.

The bridge does not copy pixel data. Core remains the sole creator, owner, and
destroyer of Core `cv::Mat` headers and opaque wrappers. A cooperating module
shim may borrow the native header only for its callback/call scope, must never
store or delete it, and must be compiled against the same compatible OpenCV ABI
and installation as Core. Input handles permit inspection, including temporary
external-buffer views. Output handles expose the actual Core header so an
OutputArray operation can allocate or rebind it; temporary external-buffer
views are rejected for output because rebinding would violate their no-escape
ownership contract.

UMat capabilities in `OpenCV.Core.Module_Interop` likewise borrow the actual
Core-owned header through callback-scoped `Input_UMat_Handle` and
`Output_UMat_Handle`. The installed typed C++ bridge performs no Mat transfer
or mapping. Output operations may rebind that header, including ordinary UMat
Regions. Core retains ownership; modules must neither retain nor delete the
borrowed header and must use the same compatible OpenCV ABI and installation.
This is module implementation infrastructure, not an application raw-handle API.

`OpenCV.Core.Sparse.Module_Interop` is the same kind of implementation
interface for `Sparse_Mat`. OpenCV 4.1.0, 4.10.0, and 5.0.0 Imgproc all
declare `calcHist` with a mutable `SparseMat&` output and `calcBackProject`
and `compareHist` with `const SparseMat&` inputs. The installed bridge
therefore exposes callback-scoped input and output resolvers. Core remains
the sole owner of the opaque wrapper and the native `cv::SparseMat` header.
A module shim borrows that header only during the callback, must neither
delete nor retain it, and does not copy node storage. Output resolution
returns the actual Core header so `SparseMat::create` can replace its shape
in place. SparseMat has no temporary external-buffer view, so output
resolution does not apply the Mat external-view rejection. Imgproc histogram
operations themselves are not part of this Core crate.

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

Row-strided external views use the longstanding
`cv::Mat(rows, cols, type, data, step)` constructor. The OpenCV 4.1.0 and 5.0.0
headers both declare this overload with `size_t step`; both document `step` in
bytes, including row-end padding, and state that data is neither copied nor
automatically deallocated. The binding uses the same ABI path across the
supported range.

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
| OpenCV shared values / OpenCV.Core        |
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

The crate also defines a root test action, which is the release
entry-point gate:

```sh
alr test
```

The test crate carries development-only dependencies such as AUnit, GNATprove,
and GNATcov. They are intentionally not dependencies of the public library
crate.

At the time of this README update, the full suite contains **1461 AUnit tests**.
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
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;

procedure Example is
   use OpenCV.Core;

   Image : Mat :=
     Create
       (Rows         => 480,
        Columns      => 640,
        Element_Type => (Depth => UInt8, Channels => 1));

   Value : OpenCV.UInt8_Value;
begin
   OpenCV.Core.UInt8_Access.Set
     (Image, Row => 10, Column => 20, Value => 255);

   Value :=
     OpenCV.Core.UInt8_Access.Get
       (Image, Row => 10, Column => 20);

   Ada.Text_IO.Put_Line (OpenCV.UInt8_Value'Image (Value));
end Example;
```

`Create` follows native `cv::Mat` allocation semantics: newly allocated element
storage is **not automatically zero-filled**. Initialize explicitly when a
known initial value is required:

```ada
Image.Set_To (OpenCV.Make_Scalar (0.0));
```

### Create from `Size`

```ada
Image : Mat :=
  Create
    (Dimensions   => (Width => 640, Height => 480),
     Element_Type => (Depth => Float32, Channels => 1));

Dims : constant OpenCV.Size := Image.Dimensions;
```

`OpenCV.Size.Width` maps to columns and `OpenCV.Size.Height` maps to rows.

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
`OpenCV.Rect` origins are signed so they can represent general OpenCV rectangles,
including negative `X`/`Y`. `Mat.Region` still requires a nonnegative
zero-based ROI origin that fits inside the source.

---

## Shared value types

`OpenCV` owns the shared public values used across Core and later module
crates. The `opencv_core` crate still distributes the parent package.
`OpenCV.Core` continues to own `Mat` and matrix-specific abstractions.

Shared root types include numeric value subtypes (`OpenCV.UInt8_Value`,
`OpenCV.Int8_Value`, `OpenCV.UInt16_Value`, `OpenCV.Int16_Value`,
`OpenCV.Int32_Value`, `OpenCV.Float32_Value`, `OpenCV.Float64_Value`),
integer coordinates
and geometry (`OpenCV.Point_Coordinate`, `OpenCV.Size_Coordinate`,
`OpenCV.Point`, `OpenCV.Point_Array`, `OpenCV.Point_3D`,
`OpenCV.Point_3D_Array`, `OpenCV.Size`, `OpenCV.Rect`),
floating-point geometry (`OpenCV.Float32_Point`, `OpenCV.Float32_Point_3D`,
`OpenCV.Float32_Point_3D_Array`, `OpenCV.Float32_Size`,
`OpenCV.Rotated_Rect`), the shared scalar (`OpenCV.Scalar`,
`OpenCV.Make_Scalar`), and shared options (`OpenCV.Border_Kind` with
literals such as `OpenCV.Reflect_101`, and `OpenCV.Angle_Unit`).

The 3-D point families are ordinary Ada values with signed 32-bit integer
or binary32 coordinates, all defaulting to zero. Their arrays preserve
arbitrary `Natural` bounds, including null ranges. Binary32 values may
represent NaN and infinities; each consuming operation defines its own
finiteness policy. Root ownership follows native OpenCV's Core `Point3`
value concept, allowing Geometry, Calib3D, and future 3-D module bindings
to reuse these shared coordinates rather than redeclare them. These
additive types belong to the `0.5.0-dev` development line, not the immutable
`0.4.0` release.

The earlier relocation of existing values to the root was source-breaking.
Callers that previously wrote
`OpenCV.Core.Point` or `OpenCV.Core.Make_Scalar` must update
qualification and visibility to the root `OpenCV` package. Clients that
use `"="` or other operators on those values need `with OpenCV;` so the
operators are visible. Core does not keep compatibility aliases for the
moved names.

Representative spellings:

| Old | New |
| --- | --- |
| `OpenCV.Core.Point` | `OpenCV.Point` |
| `OpenCV.Core.Point_Coordinate` | `OpenCV.Point_Coordinate` |
| `OpenCV.Core.Size` | `OpenCV.Size` |
| `OpenCV.Core.Rect` | `OpenCV.Rect` |
| `OpenCV.Core.Scalar` | `OpenCV.Scalar` |
| `OpenCV.Core.Make_Scalar` | `OpenCV.Make_Scalar` |
| `OpenCV.Core.Point_Array` | `OpenCV.Point_Array` |
| `OpenCV.Core.Reflect_101` | `OpenCV.Reflect_101` |

---

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

### Wrap caller-owned packed N-D storage in a temporary `Mat`

Every `*_Mat_View` package also overloads `With_Writable_Mat_View` with a
`Shape` parameter that selects a genuine packed N-dimensional `Mat`:

```ada
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Mat_View;

procedure External_Volume_Example is
   Volume : aliased OpenCV.Core.Float32_Mat_View.Buffer_Array :=
     (11 .. 34 => 0.0);

   procedure Process (Image : in out OpenCV.Core.Mat) is
   begin
      --  Image.Shape = (2, 3, 4) and Image.Is_Continuous.
      OpenCV.Core.Float32_Access.Set (Image, (1, 2, 3), 1.5);
      --  Volume (34) is now 1.5 immediately.
   end Process;
begin
   OpenCV.Core.Float32_Mat_View.With_Writable_Mat_View
     (Volume, Shape => (2, 3, 4), Process => Process'Access);
end External_Volume_Example;
```

`Shape'Length` must be in `2 .. 32`, every extent must be positive, and
`Data'Length` must equal `product (Shape)` exactly. Shape iteration order is
OpenCV dimension order regardless of `Shape'First`, and neither Ada lower bound
is visible through the `Mat`. The final dimension varies fastest: for
`Shape => (D1, ..., Dn)` the zero-based index `(I1, ..., In)` is
`Data (Data'First + ((I1 * D2 + I2) * D3 + ...) * Dn + In)`, the same order used
by N-D `Get`/`Set` and N-D continuous buffer borrowing. For Vec2/Vec3/Vec4
packages one `Data` entry is one complete Mat element, so a `(2, 3, 4)` Float64
C4 view takes 24 `Vector` values, not 96 scalars. `Shape => (Rows, Columns)`
produces the same 2-D geometry as the `Rows`/`Columns` overload, which is
unchanged. Gapped N-D storage uses the strided N-D overload described below.
OpenCV 5.0's native `MatShape` capacity is 10 dimensions
(`MatShape::MAX_DIMS`). The binding rejects N-D construction, view, and
reshape requests above that native capacity with `OpenCV_Error` before
invoking the affected OpenCV constructor or reshape, so on OpenCV 5.0 an
11 .. 32 dimensional view never runs `Process`. OpenCV 4.x retains the
historic 32-dimensional limit. Public signatures are unchanged: the
compatibility restriction is enforced below the Ada API, in the C++ shim.

### Read-only caller-owned storage

The same thirty-two typed `*_Mat_View` packages also provide
`With_Read_Only_Mat_View` (packed 2-D and N-D) and
`With_Read_Only_Strided_Mat_View` (row-strided 2-D and arbitrary-strided N-D).
For example, an aliased constant may be passed without copying pixels:

```ada
with Ada.Text_IO;
with OpenCV;
with OpenCV.Core;
with OpenCV.Core.UInt8_Access;
with OpenCV.Core.UInt8_Mat_View;

procedure Inspect_Constant_Example is
   Data : aliased constant OpenCV.Core.UInt8_Mat_View.Buffer_Array :=
     (11 => 1, 12 => 2, 13 => 3, 14 => 4, 15 => 5, 16 => 6);

   procedure Inspect (Image : OpenCV.Core.Mat) is
   begin
      Ada.Text_IO.Put_Line
        (OpenCV.UInt8_Value'Image
           (OpenCV.Core.UInt8_Access.Get (Image, 1, 2)));
   end Inspect;
begin
   OpenCV.Core.UInt8_Mat_View.With_Read_Only_Mat_View
     (Data, Rows => 2, Columns => 3, Process => Inspect'Access);
end Inspect_Constant_Example;
```

Read-only views provide zero-copy input to Core algorithms and cooperating Ada
OpenCV modules via `Module_Interop.With_Input_Handle`. The callback receives
`Image` by mode `in`, so normal in-place Ada operations and output handles
requiring `in out Mat` cannot accept it. This is an Ada capability restriction,
**not** OS/page protection: the native external-data header uses OpenCV's
mutable pointer representation. The caller retains ownership; shallow escape
is rejected and `Clone` creates independent storage. Read-only views obey the
same geometry, full-stride capacity, and callback lifetime rules as writable
views. Input-only operations remain available during the callback.

### Wrap row-strided caller-owned storage

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

`OpenCV.Core.Float64_Mat_View` provides a separately named operation whose
stride is also measured in complete Ada elements rather than bytes:

```ada
OpenCV.Core.Float64_Mat_View.With_Writable_Strided_Mat_View
  (Data       => Data,
   Rows       => 3,
   Columns    => 4,
   Row_Stride => 6,
   Process    => Process'Access);
```

`Row_Stride` is the number of `Float64_Value` elements from the start of one
logical row to the next and must be at least `Columns`. `Data'Length` must be
at least `Rows * Row_Stride`, including a complete final-row stride. A buffer
that reaches only the last logical element is rejected. Padding and extra
trailing storage are not logical Mat elements and are left untouched.

The same full-stride rule applies to the integer C1 view packages. For example,
this UInt16 buffer contains two complete six-element strides for a `2 x 4`
logical Mat. The two padding elements after each logical row remain outside the
Mat and must still exist after the final row:

```ada
with OpenCV.Core;
with OpenCV.Core.UInt16_Access;
with OpenCV.Core.UInt16_Mat_View;

procedure Padded_UInt16_Example is
   Data : aliased OpenCV.Core.UInt16_Mat_View.Buffer_Array :=
     (11 => 10, 12 => 20, 13 => 30, 14 => 40, 15 => 999, 16 => 999,
      17 => 50, 18 => 60, 19 => 70, 20 => 80, 21 => 999, 22 => 999);

   procedure Process (Image : in out OpenCV.Core.Mat) is
   begin
      OpenCV.Core.UInt16_Access.Set
        (Image, Row => 1, Column => 2, Value => 65_535);
      --  Data (19) changes immediately. Padding Data (15), Data (16),
      --  Data (21), and Data (22) remains outside the logical Mat.
   end Process;
begin
   OpenCV.Core.UInt16_Mat_View.With_Writable_Strided_Mat_View
     (Data, Rows => 2, Columns => 4, Row_Stride => 6,
      Process => Process'Access);
   --  The caller still owns Data. The temporary Mat was callback-scoped.
end Padded_UInt16_Example;
```

### Wrap gapped (strided) N-D caller-owned storage

Every `*_Mat_View` package also overloads `With_Writable_Strided_Mat_View`
with a `Shape` and a `Strides : Dimension_Stride_Array`, supplying one stride
per dimension:

```ada
with OpenCV.Core;
with OpenCV.Core.Float32_Access;
with OpenCV.Core.Float32_Mat_View;

procedure Gapped_Volume_Example is
   --  2 planes of 3 rows of 4 elements, each row padded to 6 elements and
   --  each plane padded to 20 elements: 2 * 20 = 40 elements in total.
   Volume : aliased OpenCV.Core.Float32_Mat_View.Buffer_Array :=
     (0 .. 39 => 0.0);

   procedure Process (Image : in out OpenCV.Core.Mat) is
   begin
      --  Image.Shape = (2, 3, 4); Image.Is_Continuous is False.
      OpenCV.Core.Float32_Access.Set (Image, (1, 2, 3), 1.5);
      --  Volume (1 * 20 + 2 * 6 + 3) = Volume (35) is now 1.5.
   end Process;
begin
   OpenCV.Core.Float32_Mat_View.With_Writable_Strided_Mat_View
     (Volume,
      Shape   => (2, 3, 4),
      Strides => (20, 6, 1),
      Process => Process'Access);
end Gapped_Volume_Example;
```

Strides are measured in **complete Mat elements**, never bytes. For Vec2,
Vec3, and Vec4 packages one stride unit is one complete vector element (for
example one 32-byte Float64 Vec4), not one scalar channel. For
`Shape => (D1, ..., Dn)` and `Strides => (S1, ..., Sn)` the zero-based index
`(I1, ..., In)` is `Data (Data'First + I1 * S1 + ... + In * Sn)`. The
lower bounds of `Shape`, `Strides`, and `Data` are irrelevant.

The contract is:

- `Shape'Length` in `2 .. 32` (OpenCV 5.0: at most 10, enforced by the shim)
  with positive extents, and `Strides'Length = Shape'Length`;
- the final stride is exactly `1`;
- every outer stride covers its complete nested block:
  `Strides (I) >= Strides (I + 1) * Shape (I + 1)`, so overlapping or
  backwards layouts are rejected;
- `Data'Length >= Shape (first) * Strides (first)`. OpenCV's native header
  spans the complete outer stride (`datalimit = data + size[0] * step[0]`),
  so the padding after the final logical outer block must exist. Storage that
  ends at the final logical element is rejected. Extra trailing storage beyond
  that extent is allowed and lies outside the header.

Padding is never a logical element and is never touched. `Is_Continuous`
reports the actual layout: a gapped layout is non-continuous, so whole-buffer
borrowing rejects it before its callback runs, while packed-equivalent strides
such as `(12, 4, 1)` for `(2, 3, 4)` are continuous and can be borrowed.
`Shape => (Rows, Columns)`, `Strides => (Row_Stride, 1)` has exactly the same
geometry as the 2-D row-strided overload. Ownership, callback lifetime, and
the no-escape rules are identical to the packed views; `Clone` returns
independent packed storage holding only the logical values.

### Select a lower-dimensional view by fixing dimensions

`With_Selected_View` fixes chosen source dimensions to one index and **drops**
them, while the other dimensions keep ordinary half-open ranges. The result
aliases the source; no data is copied.

```ada
with OpenCV.Core;
with OpenCV.Core.Float32_Access;

procedure Selected_Plane_Example is
   use OpenCV.Core;

   Volume : Mat :=
     Create (Shape => (2, 3, 2, 4), Element_Type => (Float32, 1));

   procedure Process (View : in out Mat) is
   begin
      --  View.Shape = (3, 4); View (J, K) is Volume (1, J, 1, K).
      OpenCV.Core.Float32_Access.Set (View, (2, 3), 1.5);
      --  Volume (1, 2, 1, 3) is now 1.5.
   end Process;
begin
   With_Selected_View
     (Volume,
      ((Kind => Fix_Index,  Index  => 1),
       (Kind => Keep_Range, Bounds => (Start => 0, Stop => 3)),
       (Kind => Fix_Index,  Index  => 1),
       (Kind => Keep_Range, Bounds => (Start => 0, Stop => 4))),
      Process'Access);
end Selected_Plane_Example;
```

There is one selector per source dimension, applied in iteration order; the
array's lower bound is irrelevant. `Keep_Range` requires
`Start < Stop <= extent`; `Fix_Index` requires `Index < extent`. The source
must be a nonempty OpenCV-owned Mat with at least three dimensions; an
ordinary `Slice` is a valid source. At least one dimension must be fixed and
at least two must be kept, so no 1-D or scalar view is produced.

The **final source dimension must be kept**. This is an OpenCV `Mat`
representation rule, not an implementation shortcut: OpenCV always uses the
element size as the step of a Mat's last dimension, so dropping the source's
final axis would leave a last axis with a larger stride that no ordinary Mat
header can describe without copying.

Retained source strides are inherited. Dropping only leading dimensions
yields a continuous view that whole-buffer borrowing accepts. Dropping a
middle dimension keeps the outer stride, so the example above is
non-continuous (rows begin eight elements apart): whole-buffer borrowing
rejects it while 2-D row borrowing works. `View` is valid only during
`Process`. It keeps the source allocation alive even if the source is rebound
inside the callback, but shallow copies, `Slice`, `Reshape`, and
`Module_Interop` output handles are rejected. `Clone` is the escape path.
Selecting from a temporary caller-buffer view is rejected; `Clone` it first.

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
- `Reshape`, including Shape-based N-D overloads
- `Diagonal_View`

For ordinary OpenCV-owned Mats, these headers retain the shared allocation by
normal OpenCV reference counting.

`With_Selected_View` is the callback-scoped, dimension-dropping counterpart.
Its view keeps the source allocation alive for the callback and follows the
temporary-view no-escape rules; `Slice` itself is unchanged and never drops
dimensions.

### Retained ROI geometry and header adjustment

Both `Mat` and `UMat` provide `Locate_Region` and `Adjust_Region` for nonempty,
**exactly 2-D** headers, at any supported depth/channel count. `Slice` remains
the N-D view abstraction. `Region_Location` contains `Whole_Size : OpenCV.Size`
and `Offset : OpenCV.Point`: X is a zero-based column, Y a zero-based row.
Nested Regions locate against the original retained allocation, not merely
their immediate parent view. Whole_Size describes OpenCV's retained storage
geometry; it is not a parent Ada Mat, an ownership handle, or evidence that
the original parent variable is still alive. Reference-counted Region storage
remains usable after that variable finalizes.

```ada
Location : constant Region_Location := ROI.Locate_Region;
--  Move each boundary outward by one, clipping to the retained parent.
ROI.Adjust_Region (Top => 1, Bottom => 1, Left => 1, Right => 1);
```

Each argument has the strong signed type `Region_Adjustment` (32 bits).
Positive top/left moves upward/leftward, positive bottom/right downward/rightward;
negative adjustments contract inward. Native clipping permits over-large
expansion requests. After clipping, OpenCV **swaps crossed opposing boundaries**,
so extreme contraction can have a non-intuitive nonempty result. Equal endpoints
can produce an empty header, which these operations subsequently reject.
Requests whose native signed intermediates would overflow raise `OpenCV_Error`
without changing the header.
Unsafe native parent-span arithmetic or empty-result Mat pointers are likewise
rejected rather than invoking undefined native behavior.

Adjustment changes only that header, never clones or allocates pixel storage.
Shallow aliases and the parent keep independent geometry while overlapping
pixels remain shared; Clone remains independent. Ordinary whole headers can
also shrink. Continuity is recomputed, but native `Is_Submatrix` is **not**:
it can remain true after full expansion or false after whole-header shrink.
Use `Locate_Region` and `Rows`/`Columns` as authoritative geometry.

Callback-scoped caller-buffer and synthetic selected Mat views reject both
parent-geometry operations, protecting their logical storage/lifetime contract
(including row padding). UMat operates directly on its native header and
requires **no host mapping or transfer**.

### Copied row access

The UInt8, Int8, UInt16, Int16, Int32, Float16, Float32, and Float64 C1 row
packages and all twenty-four Vec2/Vec3/Vec4 row packages provide `Read_Row` /
`Write_Row` APIs. Caller arrays may use
arbitrary lower bounds; values map in iteration order to matrix columns.

These are copy-based APIs and are useful when the caller wants an ordinary Ada
array with no borrowed lifetime.

### Scoped zero-copy row borrowing

The same row-access families provide:

```text
With_Read_Only_Row
With_Writable_Row
```

The callback receives a zero-based array that directly overlays one logical
OpenCV row. Row borrowing works with non-contiguous 2-D Regions because only
the active logical row is exposed; inter-row padding is never exposed.

A shallow `Mat` lease is retained during the callback so the underlying OpenCV
allocation cannot disappear merely because another header is rebound or
finalized. Integer whole-buffer tests observe that specific allocation: it
remains live after the ordinary owners are released, and its deallocation is
observed exactly once when the lease ends. That is test instrumentation, not
a formal lifetime proof. The lease is a lifetime mechanism, not thread
synchronization.


### Scoped continuous whole-buffer borrowing

The thirty-two matching buffer-access packages provide:

```text
With_Read_Only_Buffer
With_Writable_Buffer
```

The callback receives one flat zero-based array of `Natural (Image.Total)`
elements. Nonempty Mats must be continuous (`Is_Continuous`); this applies to
ordinary 2-D Mats and to genuine N-D Mats alike. Continuous Regions and
continuous N-D `Slice` views are accepted; gapped Regions and gapped N-D
Slices are rejected before the callback runs.

Elements appear in ordinary OpenCV contiguous order: the final dimension
varies fastest. For a Mat with `Shape => (D1, D2, ..., Dn)`, zero-based index
`(I1, I2, ..., In)` is at flat offset
`((I1 * D2 + I2) * D3 + ...) * Dn + In`. For example, in a `(2, 3, 4)` Mat,
`(I, J, K)` is `Data (((I * 3) + J) * 4 + K)`. For a 2-D Mat this is the
familiar `Data (Row * Image.Columns + Column)`. One array element is always
one complete Mat element: a `(2, 3, 4)` Float64 C4 Mat yields
`Data'Length = 24` Vec4 values, not 96 scalars.
There is no per-row copy and no write-back phase. The callback lifetime bounds
the borrowed view; callers must not retain a reference or address afterward.
Float64 C1 buffer access directly overlays native CV_64F storage without
conversion. Use Float64 row access for non-contiguous 2-D Regions. Float16
C2, C3, and C4 buffer access likewise overlays native CV_16FC2/C3/C4 elements
as packed `Float16_Vec2`/`Float16_Vec3`/`Float16_Vec4` vectors without
converting through Float32.

### Caller-owned buffer -> temporary `Mat`

The thirty-two Mat-view packages provide the reverse zero-copy direction:

```text
OpenCV.Core.UInt8_Mat_View
OpenCV.Core.Int8_Mat_View
OpenCV.Core.UInt16_Mat_View
OpenCV.Core.Int16_Mat_View
OpenCV.Core.Int32_Mat_View
OpenCV.Core.Float32_Mat_View
OpenCV.Core.Float64_Mat_View
OpenCV.Core.Float16_Mat_View
OpenCV.Core.UInt8_Vec2_Mat_View
OpenCV.Core.Int8_Vec2_Mat_View
OpenCV.Core.UInt16_Vec2_Mat_View
OpenCV.Core.Int16_Vec2_Mat_View
OpenCV.Core.Int32_Vec2_Mat_View
OpenCV.Core.Float16_Vec2_Mat_View
OpenCV.Core.Float32_Vec2_Mat_View
OpenCV.Core.Float64_Vec2_Mat_View
OpenCV.Core.UInt8_Vec3_Mat_View
OpenCV.Core.Int8_Vec3_Mat_View
OpenCV.Core.UInt16_Vec3_Mat_View
OpenCV.Core.Int16_Vec3_Mat_View
OpenCV.Core.Int32_Vec3_Mat_View
OpenCV.Core.Float32_Vec3_Mat_View
OpenCV.Core.Float16_Vec3_Mat_View
OpenCV.Core.Float64_Vec3_Mat_View
OpenCV.Core.UInt8_Vec4_Mat_View
OpenCV.Core.Int8_Vec4_Mat_View
OpenCV.Core.UInt16_Vec4_Mat_View
OpenCV.Core.Int16_Vec4_Mat_View
OpenCV.Core.Int32_Vec4_Mat_View
OpenCV.Core.Float16_Vec4_Mat_View
OpenCV.Core.Float32_Vec4_Mat_View
OpenCV.Core.Float64_Vec4_Mat_View
```

`With_Writable_Mat_View` creates a callback-scoped `cv::Mat` header over the
actual caller-owned Ada array. The public buffer formal is explicitly
`aliased in out`, so the native header directly denotes the caller's storage.

Packed views are available for all thirty-two typed layouts above, both as 2-D
(`Rows`, `Columns`) and as genuine N-D (`Shape`, 2 .. 32 dimensions) views.
Packed N-D views are always continuous, so the matching `*_Buffer_Access`
package can borrow the same caller storage again inside the callback without
copying. Every listed layout also supports strided storage, both as a 2-D
explicit row stride and as genuine gapped N-D storage
(`With_Writable_Strided_Mat_View (Data, Shape, Strides, Process)`), so a Mat
can represent the logical elements of padded caller-owned rows, planes, or
higher blocks without copying their padding. N-D strides are expressed in
complete Mat elements, one per dimension, and the final dimension's stride is
`1`. Except for the established Float32 2-D overload, the 2-D row-strided
views use `With_Writable_Strided_Mat_View` and measure `Row_Stride` in
complete Ada elements rather than bytes. For Vec2/Vec3/Vec4 layouts, one
element (and one stride unit) is one complete vector pixel, not one scalar
channel.

Important lifetime rule: a temporary external-buffer Mat may not create a
shallow alias that could outlive the callback. Ordinary `Mat` assignment and
no-copy view operations (including `Region`, `Slice`, and `Reshape`) are
therefore rejected for these temporary external views, whether 2-D or N-D.
This is the external-buffer lifetime policy, not a missing N-D capability.
`Clone` remains allowed because it creates independent OpenCV-owned storage
that can safely outlive the callback, and a clone can then be sliced or
reshaped normally.

The external-data `Mat` header is destroyed at callback exit, including during
exception unwinding; the caller's Ada array is never freed by OpenCV.

For a row-strided or N-D strided external view, `Is_Continuous` reflects
OpenCV's actual layout rules. A view with padding between logical elements is
non-contiguous, so operations requiring a single packed buffer must reject it;
row-based, N-D element access, and other non-contiguous-aware operations can
still be used. Strides that describe packed storage are continuous.

Caller storage must remain alive throughout the callback, and OpenCV never
owns or frees it. Row borrowing remains zero-copy and exposes exactly the
logical `Columns` elements, never padding. Whole-buffer borrowing rejects a
non-contiguous multirow strided view before invoking its callback.

---

## Sparse matrices

`OpenCV.Core.Sparse.Sparse_Mat` is a controlled, pointer-free wrapper around
`cv::SparseMat`. A default instance is unallocated (dimension count and stored
node count zero, null `Shape`). `Clear` is a no-op on it; operations needing a
shape or type raise `OpenCV_Error`. `Create` takes 2..32 strictly positive
extents (any Ada array lower bound); `Clear` removes nodes but retains shape
and type. Ordinary assignment makes a separate native header sharing the
reference-counted node storage; `Clone` makes independent node storage.

`Contains` checks node existence and `Erase` removes a node. The
`Stored_Element_Count` is OpenCV's `nzcount()`: the number of stored hash-table
nodes, **not** the count of mathematically nonzero values. Setting a zero with
any typed `Set` creates a node; `Contains` then returns True and the count
increases. Missing typed `Get` returns zero. All access uses full N-D index
arrays and validates each extent. Direct typed node access covers all eight
depths in C1, C2, C3, and C4 (32 layouts) through `Sparse.UInt8_Access` /
`UInt8_Vec2_Access` / `UInt8_Vec3_Access` / `UInt8_Vec4_Access` and the matching
`Int8`, `UInt16`, `Int16`, `Int32`, `Float16`, `Float32`, and `Float64`
packages. One `Vec2`, `Vec3`, or `Vec4` is one complete SparseMat element;
components are channels `0 .. N-1` with no RGB, XY, or complex meaning.
Float16 components use exact `Float16_Bits`/`Float16_From_Bits` binary16
encodings, including signed zero and NaN payload bits.

Each of these 32 typed access packages also provides callback-scoped,
read-only `For_Each_Stored`:

```ada
OpenCV.Core.Sparse.UInt8_Access.For_Each_Stored (Image, Visit'Access);
--  Visit (Indices : Index_Array; Value : UInt8_Value)
```

It calls `Visit` once per **stored hash node**, including explicitly stored
numeric zero; missing positions (whose `Get` would return zero) are not
visited. An allocated sparse matrix with no nodes calls it zero times;
unallocated or wrong-depth/wrong-channel matrices raise `OpenCV_Error`
before the
callback. Each copied index vector has Ada bounds `1 .. Dimension_Count`,
with zero-based coordinate values. Values are copied, not borrowed; Float16
preserves exact binary16 encodings, including signed zero and NaN payloads.
Native hash-table traversal determines the **unspecified order**: never rely
on callback order. No native iterator, node, or pointer escapes the callback.
Do not structurally mutate the source or any shallow alias (for example with
`Set`, `Erase`, or `Clear`) while traversal is active: such changes can
invalidate native traversal. Iterator ownership preserves storage lifetime,
but provides no thread synchronization. Callback exceptions propagate
unchanged after iterator cleanup.

`From_Dense` copies complete elements of an owned nonempty dense Mat,
including non-contiguous Regions and multi-channel Mats; it does not share
dense pixels. Native construction omits elements only when **every byte of the
entire element is zero**. In particular, negative IEEE zero may be stored,
NaNs are stored, and any nonzero byte in a C3 element stores the whole C3
element. `To_Dense` independently copies stored nodes and fills missing
positions with zero, preserving shape, depth, and channels. Sparse matrices
support 32 dimensions, but on OpenCV 5 `To_Dense` rejects more than the linked
native dense Mat capacity (`MatShape::MAX_DIMS`, 10 in supported 5.0); on
OpenCV 4.x the dense capacity remains 32. No public node pointers or
iterators are exposed.

`Convert_To` is native `SparseMat::convertTo` into an independent sparse
matrix. Shape and channel count stay the same; only the depth changes. OpenCV
walks stored nodes, so a missing coordinate stays missing and an explicitly
stored zero stays a stored node. Each component becomes
`saturate_cast (source * Scale)`. There is no offset. A scale that maps a
stored value to zero still leaves that node stored. `Scale => 1.0` uses
OpenCV's unscaled conversion.

```ada
Scaled := Source.Convert_To (OpenCV.Core.Float32, Scale => 2.0);
```

The numeric `To_Dense` overload is the native sparse-to-dense conversion, not
plain `To_Dense` followed by dense `Convert_To`:

```ada
Dense :=
  Source.To_Dense (OpenCV.Core.Float32, Scale => 2.0, Offset => 5.0);
```

A stored component becomes `saturate_cast (source * Scale + Offset)`. A
missing element is initialized with OpenCV `Scalar(Offset)`: channel 0
receives `Offset` and channels 1..3 receive 0, because `cv::Scalar` has one
value and three zeros. Both results own independent storage and leave the
source unchanged. The same OpenCV 5 dense-dimension capacity rule as plain
`To_Dense` applies; sparse-to-sparse conversion still accepts the full 32
dimensions.

Float16 is not a supported numeric source or destination. OpenCV 4.1.0,
4.10.0, and 5.0.0 leave every `CV_16F` entry null in the sparse
`getConvertElem` / `getConvertScaleElem` tables, and this binding does not
invent a Float32 fallback. `Convert_To` and numeric `To_Dense` raise
`OpenCV_Error` before the ABI call. Exact-bit Float16 `Get`/`Set` and plain
`To_Dense` are unchanged. The other seven depths convert in every
source/destination direction, using OpenCV saturation.

`Norm` and `Normalize` use the existing `Norm_Kind` (`L1`, `L2`, `Infinity`)
and require an allocated Float32 or Float64 matrix with exactly one channel.
Integer depths, Float16, and every multi-channel layout are rejected before
the ABI call. `Min_Max` normalization is deliberately unavailable: shifting
the implicit sparse zero would materialize nodes and change sparse semantics.

```ada
Magnitude := Values.Norm (OpenCV.Core.L2);
Unit      := Values.Normalize (Target_Norm => 1.0, Kind => OpenCV.Core.L2);
```

Both operations consider stored nodes only. A missing coordinate contributes
zero and is not created. An explicitly stored zero contributes zero to the
norm and remains a stored node. `Norm` does not modify the matrix and returns
`0.0` when an allocated matrix has no stored nodes. `L1` is the sum of
absolute stored values, `L2` is the square root of the sum of their squares,
and `Infinity` is the maximum absolute stored value.

`Normalize` returns an independent matrix with the same shape, depth, channel
count, and stored-node coordinates. OpenCV scales every stored value by
`Target_Norm / Norm` when that norm exceeds `DBL_EPSILON`. Otherwise the scale
is `0.0`: stored values become zero, stored nodes remain stored, and an empty
allocated matrix stays empty. A negative `Target_Norm` is supported and
reverses the sign of every stored value. The source is unchanged. Because no
dense `Mat` is constructed, both 5-D and 32-D sparse matrices are accepted.

`Min_Max_Loc` uses the same allocated Float32 or Float64 single-channel
restriction. It returns a `Sparse_Extrema` value whose `Has_Minimum` and
`Has_Maximum` flags are independent:

```ada
Extrema := Values.Min_Max_Loc;
--  Extrema.Has_Minimum, Has_Maximum, Minimum, Maximum
--  Minimum_Location (1 .. Extrema.Dimensions)
--  Maximum_Location (1 .. Extrema.Dimensions)
```

Only stored nodes participate. A missing coordinate is not a candidate and is
not created. An explicitly stored zero is a candidate, and negative zero
compares equal to positive zero. Comparisons are strict, so equal extrema keep
the earliest node in OpenCV's hash traversal. That traversal order is
unspecified and is not insertion order. NaN never replaces a finite extremum.

Each flag is True only when native OpenCV wrote that location. Empty storage
and a NaN-only matrix establish neither side. Positive infinity, and a stored
Float32 `FLT_MAX` or Float64 `DBL_MAX`, establish only the maximum. Negative
infinity, and a stored `-FLT_MAX` or `-DBL_MAX`, establish only the minimum.
A side that was not established returns `0.0` and an all-zero location. The
native initialization sentinels are not exposed as public extrema.

On an established side, each location is a fixed 32-coordinate array; only
`1 .. Dimensions` is meaningful, and those coordinates are zero-based. The
source is not modified. Because no dense `Mat` is constructed, both 5-D and
32-D sparse matrices are accepted.

## Typed access matrix

Direct typed access covers thirty-two layouts: every supported depth in
C1/C2/C3/C4:

| Layout | 2-D Get/Set | N-D Get/Set | Classification | Copied row | Borrowed row | Continuous buffer borrow | Packed caller buffer -> `Mat` | Strided caller buffer -> `Mat` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| UInt8 C1 | `UInt8_Access` | `UInt8_Access` | — | `UInt8_Row_Access` | `UInt8_Row_Access` | `UInt8_Buffer_Access` | `UInt8_Mat_View` | `UInt8_Mat_View` |
| Int8 C1 | `Int8_Access` | `Int8_Access` | — | `Int8_Row_Access` | `Int8_Row_Access` | `Int8_Buffer_Access` | `Int8_Mat_View` | `Int8_Mat_View` |
| UInt16 C1 | `UInt16_Access` | `UInt16_Access` | — | `UInt16_Row_Access` | `UInt16_Row_Access` | `UInt16_Buffer_Access` | `UInt16_Mat_View` | `UInt16_Mat_View` |
| Int16 C1 | `Int16_Access` | `Int16_Access` | — | `Int16_Row_Access` | `Int16_Row_Access` | `Int16_Buffer_Access` | `Int16_Mat_View` | `Int16_Mat_View` |
| Int32 C1 | `Int32_Access` | `Int32_Access` | — | `Int32_Row_Access` | `Int32_Row_Access` | `Int32_Buffer_Access` | `Int32_Mat_View` | `Int32_Mat_View` |
| Float16 C1 | `Float16_Access` | `Float16_Access` | `Float16_Value` helpers | `Float16_Row_Access` | `Float16_Row_Access` | `Float16_Buffer_Access` | `Float16_Mat_View` | `Float16_Mat_View` |
| Float32 C1 | `Float32_Access` | `Float32_Access` | — | `Float32_Row_Access` | `Float32_Row_Access` | `Float32_Buffer_Access` | `Float32_Mat_View` | `Float32_Mat_View` |
| Float64 C1 | `Float64_Access` | `Float64_Access` | `Float64_Access` | `Float64_Row_Access` | `Float64_Row_Access` | `Float64_Buffer_Access` | `Float64_Mat_View` | `Float64_Mat_View` |
| UInt8 C2 | `UInt8_Vec2_Access` | `UInt8_Vec2_Access` | — | `UInt8_Vec2_Row_Access` | `UInt8_Vec2_Row_Access` | `UInt8_Vec2_Buffer_Access` | `UInt8_Vec2_Mat_View` | `UInt8_Vec2_Mat_View` |
| Int8 C2 | `Int8_Vec2_Access` | `Int8_Vec2_Access` | — | `Int8_Vec2_Row_Access` | `Int8_Vec2_Row_Access` | `Int8_Vec2_Buffer_Access` | `Int8_Vec2_Mat_View` | `Int8_Vec2_Mat_View` |
| UInt16 C2 | `UInt16_Vec2_Access` | `UInt16_Vec2_Access` | — | `UInt16_Vec2_Row_Access` | `UInt16_Vec2_Row_Access` | `UInt16_Vec2_Buffer_Access` | `UInt16_Vec2_Mat_View` | `UInt16_Vec2_Mat_View` |
| Int16 C2 | `Int16_Vec2_Access` | `Int16_Vec2_Access` | — | `Int16_Vec2_Row_Access` | `Int16_Vec2_Row_Access` | `Int16_Vec2_Buffer_Access` | `Int16_Vec2_Mat_View` | `Int16_Vec2_Mat_View` |
| Int32 C2 | `Int32_Vec2_Access` | `Int32_Vec2_Access` | — | `Int32_Vec2_Row_Access` | `Int32_Vec2_Row_Access` | `Int32_Vec2_Buffer_Access` | `Int32_Vec2_Mat_View` | `Int32_Vec2_Mat_View` |
| Float16 C2 | `Float16_Vec2_Access` | `Float16_Vec2_Access` | — | `Float16_Vec2_Row_Access` | `Float16_Vec2_Row_Access` | `Float16_Vec2_Buffer_Access` | `Float16_Vec2_Mat_View` | `Float16_Vec2_Mat_View` |
| Float32 C2 | `Float32_Vec2_Access` | `Float32_Vec2_Access` | — | `Float32_Vec2_Row_Access` | `Float32_Vec2_Row_Access` | `Float32_Vec2_Buffer_Access` | `Float32_Vec2_Mat_View` | `Float32_Vec2_Mat_View` |
| Float64 C2 | `Float64_Vec2_Access` | `Float64_Vec2_Access` | — | `Float64_Vec2_Row_Access` | `Float64_Vec2_Row_Access` | `Float64_Vec2_Buffer_Access` | `Float64_Vec2_Mat_View` | `Float64_Vec2_Mat_View` |
| UInt8 C3 | `UInt8_Vec3_Access` | `UInt8_Vec3_Access` | — | `UInt8_Vec3_Row_Access` | `UInt8_Vec3_Row_Access` | `UInt8_Vec3_Buffer_Access` | `UInt8_Vec3_Mat_View` | `UInt8_Vec3_Mat_View` |
| Int8 C3 | `Int8_Vec3_Access` | `Int8_Vec3_Access` | — | `Int8_Vec3_Row_Access` | `Int8_Vec3_Row_Access` | `Int8_Vec3_Buffer_Access` | `Int8_Vec3_Mat_View` | `Int8_Vec3_Mat_View` |
| UInt16 C3 | `UInt16_Vec3_Access` | `UInt16_Vec3_Access` | — | `UInt16_Vec3_Row_Access` | `UInt16_Vec3_Row_Access` | `UInt16_Vec3_Buffer_Access` | `UInt16_Vec3_Mat_View` | `UInt16_Vec3_Mat_View` |
| Int16 C3 | `Int16_Vec3_Access` | `Int16_Vec3_Access` | — | `Int16_Vec3_Row_Access` | `Int16_Vec3_Row_Access` | `Int16_Vec3_Buffer_Access` | `Int16_Vec3_Mat_View` | `Int16_Vec3_Mat_View` |
| Int32 C3 | `Int32_Vec3_Access` | `Int32_Vec3_Access` | — | `Int32_Vec3_Row_Access` | `Int32_Vec3_Row_Access` | `Int32_Vec3_Buffer_Access` | `Int32_Vec3_Mat_View` | `Int32_Vec3_Mat_View` |
| Float16 C3 | `Float16_Vec3_Access` | `Float16_Vec3_Access` | — | `Float16_Vec3_Row_Access` | `Float16_Vec3_Row_Access` | `Float16_Vec3_Buffer_Access` | `Float16_Vec3_Mat_View` | `Float16_Vec3_Mat_View` |
| Float32 C3 | `Float32_Vec3_Access` | `Float32_Vec3_Access` | — | `Float32_Vec3_Row_Access` | `Float32_Vec3_Row_Access` | `Float32_Vec3_Buffer_Access` | `Float32_Vec3_Mat_View` | `Float32_Vec3_Mat_View` |
| Float64 C3 | `Float64_Vec3_Access` | `Float64_Vec3_Access` | — | `Float64_Vec3_Row_Access` | `Float64_Vec3_Row_Access` | `Float64_Vec3_Buffer_Access` | `Float64_Vec3_Mat_View` | `Float64_Vec3_Mat_View` |
| UInt8 C4 | `UInt8_Vec4_Access` | `UInt8_Vec4_Access` | — | `UInt8_Vec4_Row_Access` | `UInt8_Vec4_Row_Access` | `UInt8_Vec4_Buffer_Access` | `UInt8_Vec4_Mat_View` | `UInt8_Vec4_Mat_View` |
| Int8 C4 | `Int8_Vec4_Access` | `Int8_Vec4_Access` | — | `Int8_Vec4_Row_Access` | `Int8_Vec4_Row_Access` | `Int8_Vec4_Buffer_Access` | `Int8_Vec4_Mat_View` | `Int8_Vec4_Mat_View` |
| UInt16 C4 | `UInt16_Vec4_Access` | `UInt16_Vec4_Access` | — | `UInt16_Vec4_Row_Access` | `UInt16_Vec4_Row_Access` | `UInt16_Vec4_Buffer_Access` | `UInt16_Vec4_Mat_View` | `UInt16_Vec4_Mat_View` |
| Int16 C4 | `Int16_Vec4_Access` | `Int16_Vec4_Access` | — | `Int16_Vec4_Row_Access` | `Int16_Vec4_Row_Access` | `Int16_Vec4_Buffer_Access` | `Int16_Vec4_Mat_View` | `Int16_Vec4_Mat_View` |
| Int32 C4 | `Int32_Vec4_Access` | `Int32_Vec4_Access` | — | `Int32_Vec4_Row_Access` | `Int32_Vec4_Row_Access` | `Int32_Vec4_Buffer_Access` | `Int32_Vec4_Mat_View` | `Int32_Vec4_Mat_View` |
| Float16 C4 | `Float16_Vec4_Access` | `Float16_Vec4_Access` | — | `Float16_Vec4_Row_Access` | `Float16_Vec4_Row_Access` | `Float16_Vec4_Buffer_Access` | `Float16_Vec4_Mat_View` | `Float16_Vec4_Mat_View` |
| Float32 C4 | `Float32_Vec4_Access` | `Float32_Vec4_Access` | — | `Float32_Vec4_Row_Access` | `Float32_Vec4_Row_Access` | `Float32_Vec4_Buffer_Access` | `Float32_Vec4_Mat_View` | `Float32_Vec4_Mat_View` |
| Float64 C4 | `Float64_Vec4_Access` | `Float64_Vec4_Access` | — | `Float64_Vec4_Row_Access` | `Float64_Vec4_Row_Access` | `Float64_Vec4_Buffer_Access` | `Float64_Vec4_Mat_View` | `Float64_Vec4_Mat_View` |

The **Continuous buffer borrow** column applies to every continuous Mat of the
listed layout, including genuine N-D Mats and continuous N-D `Slice` views.
The flat array uses OpenCV element order with the final dimension varying
fastest (see "Scoped continuous whole-buffer borrowing" above). The
**Packed caller buffer -> `Mat`** column likewise covers both 2-D and genuine
packed N-D caller storage in that same element order. **Strided caller buffer
-> `Mat`** covers both 2-D row strides and genuine N-D element strides
(`Dimension_Stride_Array`, one complete-element stride per dimension, final
stride `1`). The row columns remain 2-D concepts.

For UInt8, UInt16, Int16, Int32, Float16, Float32 and Float64 Vec2 APIs, **one
vector is one complete two-channel Mat element**. Components are indexed 0 and 1; the vector
packages attach no semantic meaning to either channel. All seven depths support
2-D and N-D Get/Set,
copied and borrowed 2-D rows, continuous 2-D or N-D whole-buffer borrowing, and
packed or strided 2-D/N-D caller-owned views. Strides count complete Vec2
elements, not scalar channels. Borrowed references must not escape
callbacks.
UInt8 C2 elements occupy 2 bytes (scalar alignment 1); UInt16, Int16, and
Float16 C2 elements occupy 4 bytes (scalar alignment 2); Int32 and Float32 C2
elements occupy 8 bytes (scalar alignment 4); Float64 C2 elements
occupy 16 bytes. The predefined semantic-neutral value
types include `OpenCV.Core.UInt8_Vec2`, `OpenCV.Core.UInt16_Vec2`,
`OpenCV.Core.Int16_Vec2`, `OpenCV.Core.Int32_Vec2`, and
`OpenCV.Core.Float16_Vec2`, with component indices `0 .. 1`. UInt8, UInt16,
Int16, Int32, Float16, Float32, and Float64 each have complete C1/C2/C3/C4
typed and zero-copy access, and so does Int8 (see below): every supported
depth is complete. The 32 layouts include 24 vector layouts, with 24 vector
row packages and 32 buffer-access and 32 Mat-view packages.

For Vec3 APIs, **one Ada vector is one complete OpenCV element/pixel**, not one
scalar channel:

- UInt8 Vec3: 24 bits / 3 bytes per element, native alignment 1;
- UInt16 Vec3: 48 bits / 6 bytes per element, native alignment 2;
- Int16 Vec3: 48 bits / 6 bytes per element, native alignment 2;
- Int32 Vec3: 96 bits / 12 bytes per element, native alignment 4;
- Float16 Vec3: 48 bits / 6 bytes per element, native scalar alignment 2;
- Float32 Vec3: 96 bits / 12 bytes per element, native scalar alignment 4;
- Float64 Vec3: 192 bits / 24 bytes per element, native scalar alignment 8.

The predefined Vec3 packages are component-oriented and do not impose RGB,
BGR, XYZ, or any other semantic channel interpretation. All seven predefined
Vec3 layouts support 2-D Row/Column Get/Set and N-D `Index_Array` Get/Set.
One vector remains one complete OpenCV element. `Float16_Vec3` is an exact
three-component binary16 pixel type: indices `0 .. 2` are OpenCV channel
indices, not RGB or BGR names.

`UInt8_Vec4`, `UInt16_Vec4`, `Int16_Vec4`, `Int32_Vec4`, `Float16_Vec4`,
`Float32_Vec4`, and `Float64_Vec4` provide semantic-neutral components `0 .. 3`:
one Vec4 is one complete four-channel Mat element, not a single scalar.
No package assigns RGBA, BGRA, or XYZW meanings to channels. Each has
2-D/N-D Get/Set, copied and callback-scoped borrowed 2-D rows, continuous
whole-buffer borrowing, packed 2-D/N-D caller-owned views, and row-strided
2-D caller-owned views. Row strides count complete Vec4 elements, including
final-row padding.
UInt8 C4 elements occupy 4 bytes; UInt16, Int16, and Float16 C4 elements occupy
8 bytes (scalar alignment 2);
Int32 C4 elements occupy 16 bytes (native scalar alignment 4);
Float32 C4 elements occupy 16 bytes;
Float64 C4 elements occupy 32 bytes.
Float32 and Float64 now have complete typed C1/C2/C3/C4 families.

`UInt16_Access` provides scalar 2-D and N-D Get/Set for single-channel `CV_16U`
Mats. `UInt16_Row_Access` adds copied and callback-scoped zero-copy row access
for 2-D C1 Mats, including non-contiguous Regions. `UInt16_Buffer_Access` adds
continuous whole-buffer borrowing, and `UInt16_Mat_View` adds packed and
row-strided callback-scoped caller-owned views.

`OpenCV.Core.Int16_Vec2`, `Int16_Vec3`, and `Int16_Vec4` use
`OpenCV.Int16_Value` components in the full `-32768 .. 32767` signed domain.
Indexes are respectively `0 .. 1`, `0 .. 2`, and `0 .. 3`, with no semantic
channel names. One vector is one complete `CV_16S` Mat element (4, 6, or
8 bytes; native scalar alignment 2). Each width has matching `_Access`,
`_Row_Access`, `_Buffer_Access`, and `_Mat_View` packages: 2-D/N-D Get/Set,
copied and leased zero-copy 2-D rows, continuous whole-buffer borrowing,
and writable/read-only packed or strided 2-D/N-D caller-owned views. Strides
count complete vector elements. A Region row can be borrowed despite gaps;
non-contiguous whole buffers are rejected. Caller storage remains owned by
the caller, shallow Mat escape is forbidden, and Clone can escape independently.

`OpenCV.Core.Int32_Vec2`, `Int32_Vec3`, and `Int32_Vec4` model OpenCV
`cv::Vec2i`, `cv::Vec3i`, and `cv::Vec4i` as semantic-neutral complete Mat
elements. They preserve the exact `OpenCV.Int32_Value` signed 32-bit domain,
with component indices `0 .. 1`, `0 .. 2`, and `0 .. 3`. Elements occupy
8, 12, and 16 bytes respectively, with 4-byte native scalar alignment.
Each width has matching `_Access`, `_Row_Access`, `_Buffer_Access`, and
`_Mat_View` packages, including 2-D and N-D access, copied/borrowed rows,
continuous whole-buffer borrowing, and read-only/writable packed and strided
2-D/N-D caller-owned views. Strides count complete vectors, not channels.
The stable C ABI uses `int32_t` records and row buffers; OpenCV stores native
`int` vectors. The shim proves identical signed ranges and converts components
explicitly without assuming C++ type identity or aliasing the representations.

`Int8_Access` provides scalar 2-D and N-D Get/Set for single-channel `CV_8S`
Mats. `Int8_Row_Access` adds copied and callback-scoped zero-copy row access
for 2-D C1 Mats, including non-contiguous Regions. `Int8_Buffer_Access` adds
continuous whole-buffer borrowing, and `Int8_Mat_View` adds packed and
row-strided callback-scoped caller-owned views. All paths preserve the exact
signed 8-bit domain, `-128 .. 127`, without unsigned or floating-point
intermediates.

`OpenCV.Core.Int8_Vec2`, `Int8_Vec3`, and `Int8_Vec4` complete the signed
8-bit family: Int8 now has full C1/C2/C3/C4 typed and zero-copy coverage, so
every supported depth (UInt8, Int8, UInt16, Int16, Int32, Float16, Float32,
Float64) is complete for C1 through C4. Components are `OpenCV.Int8_Value`
in the exact signed `-128 .. 127` domain, indexed `0 .. 1`, `0 .. 2`, and
`0 .. 3` as OpenCV channel order with no XY, RGB, or other semantic meaning.
One vector is one complete `CV_8SC2`/`CV_8SC3`/`CV_8SC4` Mat element:
C2 = 2 bytes, C3 = 3 bytes, C4 = 4 bytes, native alignment 1. Each width has
matching `_Access` (2-D and N-D Get/Set), `_Row_Access` (copied rows and
callback-scoped zero-copy leased rows), `_Buffer_Access` (continuous 2-D/N-D
whole-buffer borrowing), and `_Mat_View` (writable and read-only packed and
strided 2-D/N-D caller-owned views; strides count complete vectors, not
scalar channels) packages. OpenCV defines no named signed-8 vector alias:
`Vec2b`/`Vec3b`/`Vec4b` are unsigned `Vec<uchar, N>` and are never used for
these layouts. Native storage is `cv::Vec<schar, N>`, where OpenCV's `schar`
is `signed char` in 4.1/4.10 and `int8_t` in 5.0; the stable C ABI uses
`opencv_core_int8_vec2`/`_vec3`/`_vec4` records and `int8_t` row buffers.
The shim statically proves that `schar` and `int8_t` cover exactly the same
one-byte signed domain (without requiring C++ type identity) and converts
every component explicitly; ABI buffers are never aliased as native vectors.

`Int16_Access` provides scalar 2-D and N-D Get/Set for single-channel `CV_16S`
Mats. `Int16_Row_Access` adds copied and callback-scoped zero-copy row access
for 2-D C1 Mats, including non-contiguous Regions. `Int16_Buffer_Access` adds
continuous whole-buffer borrowing, and `Int16_Mat_View` adds packed and
row-strided callback-scoped caller-owned views.

`Int32_Access` provides scalar 2-D and N-D Get/Set for single-channel `CV_32S`
Mats. `Int32_Row_Access` adds copied and callback-scoped zero-copy row access,
`Int32_Buffer_Access` adds continuous whole-buffer borrowing, and
`Int32_Mat_View` adds packed and row-strided callback-scoped caller-owned views.
All paths preserve exact signed 32-bit values without floating-point
intermediates.

`Float16_Access` provides scalar 2-D and N-D Get/Set for single-channel
`CV_16F` Mats. Access is bit-preserving: every binary16 encoding, including
signed zeros, subnormals, infinities, and NaN payloads, round-trips through
`Float16_From_Bits` / `Float16_Bits`. `Float16_Row_Access` adds copied and
callback-scoped zero-copy row access for 2-D C1 Mats, including
non-contiguous Regions, and likewise preserves exact binary16 object bits
without converting through Float32. `Float16_Buffer_Access` adds
callback-scoped zero-copy whole-buffer borrowing for continuous 2-D or N-D C1
Mats. Non-contiguous Regions still require row access. `Float16_Mat_View`
adds callback-scoped packed and row-strided caller-owned CV_16FC1 storage.
Packed views overlay a contiguous Ada array. Row-strided views use
`With_Writable_Strided_Mat_View` so a 2-D `Row_Stride` can skip padding
between logical rows; the `Shape`/`Strides` overload adds gapped N-D storage.
The caller owns the backing storage, OpenCV does not free it, and it must
remain alive for the callback lifetime. The main C1 FP16 data plane is now complete:
exact value representation, Float32 conversion, scalar access, row access,
continuous-buffer borrowing, packed external views, and strided external
views. `Add`, `Subtract`, `Multiply`, `Divide`, `Abs_Diff`, `Minimum`, and
`Maximum` additionally support Float16 with native OpenCV 5.x arithmetic and
an internal Float32 compatibility path on OpenCV 4.x. This does not add broad OpenCV 4.x FP16
algorithm coverage.
`Float16_Vec3` / `Float16_Vec3_Access` add exact-bit 2-D and N-D Get/Set for
ordinary three-channel `CV_16FC3` Mats. N-D `Index_Array` access addresses one
complete six-byte pixel and preserves every binary16 component encoding. `Float16_Vec3_Row_Access` adds copied and
callback-scoped zero-copy row access for 2-D C3 Mats, including non-contiguous
Regions, and likewise preserves exact binary16 component bits without converting
through Float32. `Float16_Vec3_Buffer_Access` adds callback-scoped zero-copy
whole-buffer borrowing for continuous 2-D or N-D C3 Mats. `Float16_Vec3_Mat_View` adds
callback-scoped packed and row-strided caller-owned CV_16FC3 storage. Packed
views overlay a contiguous Ada array of `Float16_Vec3.Vector` pixels.
Row-strided views use `With_Writable_Strided_Mat_View` so a 2-D `Row_Stride`
measured in complete C3 pixels can skip padding between logical rows. The main
C3 FP16 storage/access data plane is now complete: exact-bit pixel Get/Set,
copied rows, borrowed zero-copy rows, continuous whole-buffer borrowing, packed
caller-owned Mat views, and row-strided caller-owned Mat views. `Add`,
`Subtract`, `Multiply`, and `Divide` support Float16 C3 with the same
native-or-fallback policy as C1. This does not add broad OpenCV 4.x FP16 algorithm coverage. Component 0, 1,
and 2 correspond to OpenCV channels 0, 1, and 2; Core does not assign RGB or
BGR meaning.

`Float16_Vec2` and `Float16_Vec4` complete the Float16 family: Float16 now has
full C1/C2/C3/C4 typed and zero-copy coverage. Each component is a
`Float16_Value`, i.e. the exact stored IEEE-754 binary16 encoding, indexed
`0 .. 1` or `0 .. 3` as OpenCV channel order with no real/imaginary, XY, RGB,
or RGBA meaning. One vector is one complete Mat element: C2 = 4 bytes,
C3 = 6 bytes, C4 = 8 bytes, with native storage alignment 2. Each width has
`_Access` (exact-bit 2-D and N-D Get/Set), `_Row_Access` (copied rows and
callback-scoped zero-copy leased rows), `_Buffer_Access` (continuous 2-D/N-D
whole-buffer borrowing), and `_Mat_View` (writable and read-only packed and
strided 2-D/N-D caller-owned views; strides count complete vectors, not
scalar channels). Signed zeros, subnormals, infinities, and signaling or
quiet NaN payloads are never converted or canonicalized. The stable C ABI
uses `opencv_core_float16_vec2`/`opencv_core_float16_vec4` records and
`uint16_t` row buffers carrying raw binary16 bit patterns. The shim copies
exactly 4 or 8 bytes of untyped Mat storage; it never names a C++ half type
or half-vector alias. OpenCV 4.1, 4.10, and 5.0 define no such alias in
`matx.hpp` (only `Vec2b`/`s`/`w`/`i`/`f`/`d` and friends), and the public half
type itself is spelled differently across releases (`cv::float16_t` versus
`cv::hfloat`), so the binding relies only on the stable `CV_16FC2`/`CV_16FC4`
storage representation. The existing channel-agnostic Float16 arithmetic
path accepts C2/C4 operands (`Add` and `Multiply` are regression-tested with
exact finite values); no new arithmetic API was added, and `Transform` still
rejects Float16 sources.

`Float64_Access` provides scalar 2-D and N-D Get/Set plus non-finite value
classification. `Float64_Row_Access` adds copied and callback-scoped zero-copy
row access for 2-D C1 Mats, including non-contiguous Regions.
`Float64_Buffer_Access` adds callback-scoped zero-copy whole-buffer borrowing
for continuous 2-D or N-D Mats. `Float64_Mat_View` adds callback-scoped packed and
row-strided caller-owned CV_64FC1 storage. Packed views overlay a contiguous
Ada array. Row-strided views use `With_Writable_Strided_Mat_View` so a 2-D
`Row_Stride` can skip padding between logical rows; the `Shape`/`Strides`
overload adds gapped N-D storage. The caller owns the backing storage, OpenCV
does not free it, and it must remain alive for the callback lifetime.

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

- `OpenCV.Core.Mat`, `Mat_Type`, `Depth_Type`, `Channel_Count`, `Mat_Size`
- `OpenCV.Size`, `OpenCV.Point`, `OpenCV.Point_Array`, `OpenCV.Rect`, `OpenCV.Scalar`
- `OpenCV.Point_3D`, `OpenCV.Point_3D_Array`, `OpenCV.Float32_Point_3D`,
  `OpenCV.Float32_Point_3D_Array`
- `Index_Range`, `Index_Range_Array`
- `Float16_Value`
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

`Float16_Value` is a private 16-bit type for the exact IEEE-754 binary16
encoding used by OpenCV `CV_16F`. `Float16_From_Bits` / `Float16_Bits` preserve
every pattern, including signed zeros, subnormals, infinities, and NaN
payloads. Classification helpers inspect those stored bits. `To_Float16` /
`To_Float32` convert numerically between binary16 and binary32 using
round-to-nearest, ties-to-even. `OpenCV.Core.Float16_Access` provides scalar
C1 2-D and N-D Get/Set that store and load the exact encoding. Copied row
access, borrowed row access, whole-buffer borrowing, and packed or row-strided
external Mat views are available for Float16 C1, C2, C3, and C4. `Add`, `Subtract`,
`Multiply`, `Divide`, `Abs_Diff`, `Minimum`, `Maximum`, `Add_Weighted`, and
`Scale_Add` accept Float16 Mats
and return Float16; they use native OpenCV FP16 arithmetic where the supported
OpenCV version implements a conforming operation and an internal Float32
compatibility path otherwise. Storage
and access bit preservation is distinct from arithmetic numeric semantics.
This does not imply broad Float16 coverage of every Core algorithm.

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
- `With_Selected_View` (callback-scoped dimension-dropping N-D selection)
- `Reshape`, including the existing 2-D overloads and Shape-based N-D overloads
- `Diagonal_View`
- `Diagonal_Matrix`

Metadata:

- `Is_Empty`
- `Rows`
- `Columns`
- `Dimensions`
- `Dimension_Count`
- `Extent`
- `Shape`
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

Continuous genuine N-D Mats, including continuous N-D `Slice` views, can also
be borrowed as one flat typed array through every `*_Buffer_Access` package;
the final dimension varies fastest. A gapped Slice (for example one that
restricts a middle axis while keeping several outer blocks) is rejected
before the callback runs.

`Dimensions` is the 2-D `Size` view: width is `Columns` and height is `Rows`.
`Shape` is the all-dimensional counterpart. It returns every extent in Mat
dimension order, indexed `1 .. Dimension_Count`. A default Mat returns a null
array. A typed empty `0 x 0` Mat returns two zero extents. A normal 2-D Mat
returns `(Rows, Columns)`. A genuine N-D Mat reports `Extent` for every axis
rather than `Rows` or `Columns`.

Shape-based reshape creates another header over the same storage:

```ada
Volume := Image.Reshape (Shape => (2, 3, 4));
Pixels := Scalars.Reshape (Channels => 3, Shape => (2, 2, 3));
```

The `Dimension_Array` is read in Ada iteration order, regardless of its lower
bound. Every target extent must be nonzero: this API does not expose OpenCV's
zero-sentinel "preserve this dimension" convention. The target dimension count
must be `2 .. 32` (on OpenCV 5.0, at most its native 10-dimension capacity;
longer targets raise `OpenCV_Error` before native reshape). The scalar count,
including channels, must stay identical,
and depth is unchanged. Shape-based reshape requires continuous storage. The
result shares storage; `Clone` creates independent storage. The existing
`Reshape (Channels)` and `Reshape (Channels, Rows)` overloads are unchanged.

### Conversion and element-wise mathematics

Mat and UMat provide both return-value and destination-taking conversions:

```ada
Result := Source.Convert_To
  (Depth => OpenCV.Core.UInt8, Scale => 2.0, Offset => 3.0);
Source.Convert_To
  (Destination => Existing, Depth => OpenCV.Core.UInt8,
   Scale => 2.0, Offset => 3.0);
```

The function returns independent storage. The procedure converts directly into
`Existing`'s native header: compatible shape/type permits allocation reuse;
incompatible shape/type triggers native reallocation. Nonempty results keep the
source shape and channel count, selecting only the destination depth, and use
OpenCV's `saturate_cast<Depth>(Source * Scale + Offset)` semantics. Genuine N-D
arrays are supported, and Float16 follows the existing native conversion policy.

A compatible destination `Region` remains attached to its original parent:
conversion modifies only the selected pixels, visible through the parent and
other shallow aliases, leaving surrounding guard pixels untouched. This is
verified by parent/alias pixel tests, not inferred from `Is_Submatrix`. If native
reallocation is required, an incompatible Region can detach; its old parent and
other headers keep their original allocation and pixels. Exact self-conversion,
including a depth change, is supported. Same-layout shallow aliases follow
native sharing; arbitrary partially overlapping views are not supported.

Temporary callback-scoped external/selected Mat views are permitted as sources,
but rejected as destinations with `OpenCV_Error`, independently enforced by the
raw ABI. Null handles, invalid raw depth identifiers, and temporary destinations
are rejected before native mutation and leave existing destination data/header
unchanged. No failure-atomicity guarantee is made for exceptions after native
conversion begins. UMat conversion uses native UMat destinations without any
binding-side host mapping or staging; OpenCV may itself choose CPU fallback.

Empty sources produce empty destinations, but metadata deliberately follows
the installed OpenCV: 4.1/4.6/4.10 release storage while retaining destination
type metadata; 5.0 recreates empty metadata. In 5.0 Mat retains source channels,
whereas the native empty UMat depth-only path creates one channel. See
[`tests/probes/convert_destination_source_findings.md`](tests/probes/convert_destination_source_findings.md)
for exact-tag source references and the isolated probe results.

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

`Mat` and `UMat` support both allocation-returning and destination-taking
`Add` / `Subtract` / `Multiply` / `Divide` / `Abs_Diff` / `Minimum` / `Maximum`
forms. All require matching **2-D**
operands (shape, depth, and channels); Destination does not participate in
validation.

```ada
Result := Add (A, B);
Result := Subtract (A, B);
Result := Multiply (A, B);
Result := Divide (A, B);
Result := Abs_Diff (A, B);
Low  := Minimum (A, B);
High := Maximum (A, B);

Add
  (Left        => A,
   Right       => B,
   Destination => Existing);
Subtract
  (Left        => A,
   Right       => B,
   Destination => Existing);
Multiply
  (Left        => A,
   Right       => B,
   Destination => Existing);
Divide
  (Left        => A,
   Right       => B,
   Destination => Existing);
Abs_Diff
  (Left        => A,
   Right       => B,
   Destination => Existing);
```

Functions retain their independent-result contract. Procedures pass the
caller's actual native destination header to arithmetic, reusing compatible
whole storage or an interior `Region`: its parent/geometry and preexisting
shallow aliases remain attached, and outside parent pixels remain unchanged.
An incompatible shape, depth, or channel count permits native reallocation;
a Region may detach while its old aliases/parent retain their storage.

Destination may be Left or Right, or a distinct same-layout shallow alias of
either, including order-sensitive `Subtract (A, B, B)` computing `A - old(B)`.
Operands may themselves share the same layout/storage: `A + A`, `A - A`, and
`A * A` retain native numeric semantics. Arbitrarily partially overlapping Regions
are **not supported**. Temporary external/selected Mat views are allowed as
sources, but never as destinations, even with compatible shape/type.
Operand/capability validation occurs before mutation; arbitrary post-native
failure atomicity is not promised. Integer saturation remains native (UInt8
and Int16 saturate; Int32 does not saturate and overflow may change sign).

Float16 follows the existing function policy: Float32 widening on OpenCV 4.x,
native half arithmetic on 5.x. The 4.x final narrowing writes into the actual
destination and can reuse compatible half whole/Region storage. No extra half
compatibility layer or cross-architecture bitwise guarantee is introduced.
UMat arithmetic remains UMat-native at the binding boundary; OpenCV chooses
OpenCL execution or CPU fallback, not necessarily GPU residency/execution.

Reusable elementwise extrema are available for both Mat and UMat:

```ada
Minimum
  (Left        => A,
   Right       => B,
   Destination => Existing_Low);

Maximum
  (Left        => A,
   Right       => B,
   Destination => Existing_High);
```

These pass the actual native Destination to the unchanged `dense_min_max`
helper. Compatible whole/Region storage is reused, preserving shallow aliases
and parent geometry; shape/depth/channel mismatches can reallocate/detach the
destination without changing the old parent or its aliases. Destination may be
Left or Right or an exact same-layout shallow alias of either; operands may
alias each other. Arbitrary partially overlapping Regions are unsupported.
The public contract remains matching **2-D** operands, with Destination excluded
from operand validation. Temporary external/selected Mat views remain valid
sources but cannot be destinations. Pre-native rejection preserves Destination;
arbitrary post-native failure atomicity is not promised.

Integer extrema are direct, channel-independent element selection, without
arithmetic overflow or saturation (including Int16 and Int32 extrema). Ordinary
finite values retain numerical correctness in place. Floating NaN and
signed-zero selection follows native OpenCV, **not IEEE `fmin`/`fmax`**: neither
unconditional NaN propagation nor bitwise commutativity/payload identity is
promised. Independent destinations match the allocation-returning functions.
Exact/shallow aliases instead retain native aliased-output behavior. In OpenCV
5.0, fresh outputs can use a final SIMD block where exact aliases use a scalar
tail; this can change NaN classification or zero sign at affected tail positions.
This is native behavior, not a binding-created discrepancy or a memory-safety
defect. The tested 4.1/4.6/4.10 CPU builds retained fresh/alias parity in these
cases; that observation is not imposed on other versions/backends/architectures.

Float16 policy is unchanged: 4.x widens both operands to Float32 Dense and
narrows into the actual half Destination (reusing compatible whole/Region
storage); 5.0 uses native half min/max, including its native alias/tail boundary.
No normalization, copy-back or defensive preallocation is added. UMat remains
native at the binding boundary, including Dense half intermediates; OpenCV may
fall back internally to CPU, and GPU execution is not guaranteed. Empty output
metadata remains native/version-specific. The existing helper avoids the known
default-empty Mat and typed-empty UMat/OpenCL hazards. See
[`tests/probes/min_max_destination_source_findings.md`](tests/probes/min_max_destination_source_findings.md)
for the exact four-version source audit and actual-helper evidence.

`Abs_Diff` passes the actual destination to the unchanged `dense_abs_diff`
helper. Compatible whole/Region storage is reused; mismatched shape, depth or
channels may detach/reallocate without changing the old parent or aliases.
Destination may be Left or Right, including distinct same-layout shallow
aliases; arbitrary partially overlapping Regions are unsupported. Public
operands remain matching **2-D** arrays, not scalars or N-D arithmetic.
UInt8 differences do not wrap (`10` vs `200` gives `190`), channels are
independent, and Int16 saturates (`-32768` vs `0` gives `32767`). Int32 overflow
has no saturation guarantee and may yield negative native values; the binding
does not normalize it. Ordinary finite/integer `Abs_Diff (A, A)` is zero, but
equal infinities and NaNs produce native NaNs. Finite vs either infinity gives
positive infinity; NaN operands propagate NaN classification, without payload
preservation promises. Signed-zero pairs produced positive zero in the exact
four-version CPU matrix; no stronger architecture-independent bit contract is
introduced. Float16 policy is unchanged (4.x Float32 widening/final narrowing
into the actual destination; 5.0 native half), and UMat stays native at the
binding boundary. Typed/default Mat empty order differs on 4.x, whereas 5.0
Mat releases early; the established UMat typed-empty compatibility path remains
unchanged. OpenCV 5's same-width scalar helper cannot introduce an old-output
write-width mismatch here, so no preallocation correction was added. See
[`tests/probes/abs_diff_destination_source_findings.md`](tests/probes/abs_diff_destination_source_findings.md)
for exact-tag paths, empty metadata, alias boundaries, and actual-helper probes.

`Divide` passes the actual destination to the unchanged division compatibility
helper. `Divide (A, B, A)` and `Divide (A, B, B)` are supported: the latter still
computes **old Left / old Right**, including exact-layout shallow aliases.
Partial overlap is unsupported. Scale remains 1.0 and output preserves operand
depth. Zero denominators are **not invalid**: native integer storage returns
zero; Float32/Float64 preserve infinity/NaN, including the denominator zero sign
where native execution preserves it. Integer quotients use OpenCV conversion/
rounding, not Ada integer `/` (for example UInt8 `7 / 2 = 4`). `A / A` is one
only for ordinary nonzero finite inputs: integer `0 / 0` is zero and ordinary
floating `0 / 0` is NaN. Float16 policy is unchanged and procedure results match
the existing function under the same build; no NaN payload guarantee is added.
OpenCV 5.0 typed-empty Mat division releases the destination, unlike ordinary
4.x typed-empty Mat creation; the existing UMat empty helper remains unchanged.
No Divide old-destination-depth selector or preallocation correction exists.
See [`tests/probes/divide_destination_source_findings.md`](tests/probes/divide_destination_source_findings.md)
for the four exact-tag source audit, empty metadata, and actual-helper probe.

Accepted empty operands release destination storage or create typed-empty
headers through the established native/helper path. Old aliases keep their
allocation. Release retains the old destination depth/channels, unlike a
fresh return-value result; 4.x release retains zeroed dimensional extents,
whereas 5.0 clears dimensionality. Typed-empty UMat outputs retain operand
type/2-D shape through the existing helper; typed-empty Mat outputs differ
between 4.x and 5.0. See the exact-version table and source/probe evidence in
[`tests/probes/add_subtract_destination_source_findings.md`](tests/probes/add_subtract_destination_source_findings.md).

`Multiply` uses the existing multiplication helper with the actual destination,
including its empty and Float16 compatibility paths. Exact `Multiply (A, B, A)`
and `Multiply (A, B, B)`, same-layout shallow aliases of either operand, and
`Multiply (A, A, A)` are supported; arbitrary partial Region overlap is not.
UInt8 products saturate (`20 * 20 = 255`), signed Int16 products saturate at both
limits, and Int32 retains OpenCV's non-saturating contract; no binding overflow
policy is added. Scale remains 1.0 and output depth remains the operand depth.
Multiply's typed-empty Mat path retains operand type/2-D shape except Float16
on 4.x (release); typed-empty UMat retains operand metadata. Default/mixed Mat
empties release output, whereas mixed UMat empties take the typed operand's
metadata. Release preserves old destination depth/channels and old aliases;
the released shape is zeroed 2-D on 4.x and dimensionless on 5.0.
Native HAL configuration can also reject typed-empty Mat multiplication:
OpenCV 5.0's KleidiCV `mul8u` does so on macOS ARM64. Both forms preserve the
translated `OpenCV_Error`; the procedure may have created typed-empty output
before that native failure. No cross-platform empty normalization is added.
The helper narrowly corrects the old UInt16/Int16 destination layout before
byte multiplication on OpenCV 4.10+/5.x, preventing an extended HAL kernel from
writing 16-bit values into recreated byte storage. Compatible destinations,
fresh results, and empty operands are unaffected. See
[`tests/probes/multiply_destination_source_findings.md`](tests/probes/multiply_destination_source_findings.md)
for the exact four-version source audit, native-call layout probe, and empty
metadata table. No guaranteed GPU execution or cross-platform Float16 bit
identity is implied.

`Add`, `Subtract`, `Multiply`, `Divide`, `Abs_Diff`, `Minimum`, and `Maximum`
accept Float16 operands with the same shape, depth, and channel-count
compatibility rules as the other public depths. The result is always Float16;
the public result type does not change on older OpenCV releases. Finite results
for `Add`, `Subtract`, `Multiply`, `Divide`, and `Abs_Diff` are defined as

```text
To_Float16 (To_Float32 (Left) +/- To_Float32 (Right))
To_Float16 (To_Float32 (Left) * To_Float32 (Right))
To_Float16 (To_Float32 (Left) / To_Float32 (Right))
To_Float16 (abs (To_Float32 (Left) - To_Float32 (Right)))
```

with a nonzero finite denominator required for Divide. OpenCV 5.x native
`CV_16F` paths for these operations are used only while they satisfy this
established Float32-to-Float16 result model. OpenCV 4.1, 4.6, and 4.10 expose
Float16 storage and `convertTo` but do not implement these arithmetic kernels,
so the binding widens internally to Float32, performs the operation, and
narrows back to Float16. That fallback exists only for compatibility.

### Reusable weighted arithmetic destinations

Both Mat and UMat retain allocation-returning weighted functions with
independent result storage, and also provide direct destination procedures:

```ada
Weighted := Add_Weighted (Left, 0.75, Right, 0.25, Gamma => 2.0);
Add_Weighted
  (Left        => Left,
   Alpha       => 0.75,
   Right       => Right,
   Beta        => 0.25,
   Destination => Existing,
   Gamma       => 2.0);

Scaled := Scale_Add (A, 1.5, B);
Scale_Add
  (Self        => A,
   Scale       => 1.5,
   Right       => B,
   Destination => Existing);
```

Gamma stays last/defaulted. `Add_Weighted` accepts identical N-D source shape,
depth and channels; `Scale_Add` intentionally requires matching 2-D sources.
Destination is not an operand: incompatible shape, depth or channels reallocate
or detach it. Compatible whole storage and interior Regions are reused, including
the final Float16 compatibility narrowing, so retained aliases see writes and
Regions stay attached to their Parent. Old aliases retain old storage after
detachment. Exact Left/Self/Right and distinct same-layout shallow aliases are
supported, using the old operand values. Operands may share storage with each
other. Arbitrary partially overlapping Regions are **unsupported**; there is no
overlap detection or hidden temporary-result/copy-back.

Independent compatible output follows the allocation-returning function's
same-build numerical contract. Floating alias rounding follows direct native
execution: specifically, OpenCV 5.0 weighted Float32 kernels can use an overlapping
SIMD last block for fresh output but a scalar tail for aliases, exposing FMA/order
rounding differences at width 257. This does not relax ordinary integer exactness
or floating numerical correctness. NaN payload identity, universal signed-zero
identity, cross-architecture bits and fused/non-fused equivalence are not promised.

Coefficients are passed as double without added finiteness checks. Generic CPU
weighted UInt8/Int16 kernels narrow coefficients to Float32; the generic Int32
fallback uses double work/coefficient precision, but a platform HAL can preempt
that fallback with different native precision. On 4.x weighted Float32 CPU
scalar tails use double coefficients while SIMD lanes use Float32;
5.0 narrows Float32 coefficients on both
paths. Float64 retains double. OpenCL arithmetic narrows scalars whenever its work
depth is Float32 (including integer weighted work); double work retains double.
Scale_Add narrows Scale for Float32, retains double for Float64, and delegates
integer CPU arithmetic to addWeighted. UInt8 and Int16 saturate; Int32 has **no
overflow/saturation promise**. OpenCL Float32 work and platform CPU backends can
round large Int32 values differently from the generic double fallback. Native
backend behavior is authoritative for function and destination forms, rather
than normalized by the binding. Disabling OpenCL does not force generic CPU
execution or disable CPU HALs. Exact integer observations use typed access,
not Float64 conversion; portable exact mathematics is tested separately from
deliberately precision-sensitive large-integer native parity.

Temporary external/selected Mat views may be sources, but cannot be Destination:
native output creation/rebinding could sever their callback-scoped capability.
Source-validation and raw null/capability failures preserve output; arbitrary
post-native failure atomicity is not promised. Empty output metadata follows the
existing helper, version and argument order, not normalization: weighted mixed
default/typed empties are rejected by rank validation, whereas scale-add accepts
the compatible UInt8 mixes. UMat stays UMat-native at the binding boundary,
including Float16 intermediates; OpenCV may fall back to CPU. No GPU execution is
claimed. See [exact source and probe findings](tests/probes/weighted_destination_source_findings.md).

`Add_Weighted` accepts Float16 operands with the same shape, depth, and
channel-count compatibility rules as the other public depths. Its result is
always Float16. On OpenCV 4.1, 4.6, and 4.10, the binding widens Float16
operands to Float32, executes OpenCV's optimized Float32 `addWeighted` with
the public `double` coefficients, and narrows once to Float16. On OpenCV 5.0,
the binding uses native `CV_16F` `addWeighted` with those same public `double`
coefficients. The optimized paths may use SIMD, fused multiply-add, differing
vector widths, and scalar tails, so exact Float16 result bits may differ
between OpenCV versions and platforms. NaN payload identity and signed-zero
identity are not promised.

For `Scale_Add`, OpenCV 4.1 through 5.0 expose dedicated CPU `scaleAdd`
kernels only for Float32 and Float64, not Float16. Float16 `Scale_Add` is
implemented by widening the operands to Float32, narrowing Scale to Float32,
executing OpenCV's optimized Float32 `scaleAdd` operation, and narrowing the
result back to Float16. Unlike `Add_Weighted`, this path preserves OpenCV's
optimized SIMD and fused-multiply-add execution rather than imposing
binding-controlled rounding. Numerical results therefore follow the OpenCV
Float32 execution path and may exhibit platform- or SIMD-dependent last-bit
differences after conversion to Float16. Exact Float16 bits are not promised
to be independent of architecture, SIMD dispatch, or scalar-tail placement.
This compatibility path is used across OpenCV 4.1-5.0 because those supported
versions do not expose a `CV_16F` `scaleAdd` kernel. `Scale_Add` remains
intentionally 2-D.
For finite numerically unequal operands, `Minimum` and `Maximum` select the
smaller or larger binary16 operand exactly. Their signed-zero, infinity, and
NaN behavior follows the established Float32 `cv::min` / `cv::max` semantics
through the compatibility model; they are not advertised as IEEE `fmin` or
`fmax`. OpenCV 5.x uses native Float16 min/max only while it conforms to that
model. This is an arithmetic semantic policy, distinct from Float16 storage and
typed access, which preserve exact binary16 object bits including NaN payloads.
Arithmetic does not promise NaN-payload preservation; it preserves numeric and
classification behavior. This does not imply broad Float16 support for other
Core algorithms.

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

`Min_Max_Loc` remains the 2-D Point-based API (`X = column`, `Y = row`).
`Min_Max_Indices` adds dense N-D extrema for non-empty C1 Mats of depth UInt8,
Int8, UInt16, Int16, Int32, Float32, or Float64; Float16 is unsupported in the
portable Ada API. Its `ND_Min_Max_Result` holds independent `Has_Minimum` and
`Has_Maximum` flags and 32-entry locations. Coordinates are zero-based in
`Shape` / `Extent` / `Index_Array` / `Slice` dimension order: for 2-D, entry 1
is row and entry 2 is column. `Dimensions = Self.Dimension_Count`; only
`1 .. Dimensions` location entries are meaningful, and unused entries are zero.
Non-contiguous N-D Slices are supported with coordinates relative to the Slice.

The masked overload requires UInt8 C1 and equality of the **entire N-D shape**;
any nonzero mask element selects its corresponding dense element. An all-zero
mask returns zero values/locations with both flags false. Unlike sparse extrema,
all logical dense elements selected by the mask participate. Inputs and shallow
aliases remain unchanged. Ordinary finite extrema are the portable guarantee;
NaN/Infinity values and index validity follow native version/backend behavior,
not mathematical normalization. See the
[exact-version research note](tests/probes/nd_min_max_source_findings.md).

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

`Perspective_Transform` outputs can be inspected directly with
`Float32_Vec2_Access` for Float32 C2, `Float64_Vec2_Access` for Float64 C2,
`Float32_Vec3_Access` for Float32 C3, and `Float64_Vec3_Access` for Float64 C3.
`Transform` C4 outputs can be inspected directly with `UInt8_Vec4_Access`,
`UInt16_Vec4_Access`, `Int32_Vec4_Access`, `Float32_Vec4_Access`, or `Float64_Vec4_Access`, without splitting channels or
narrowing Float64.

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
- `Packed_Discrete_Fourier_Transform_Rows`
- `Inverse_Packed_Discrete_Fourier_Transform_Rows`
- `Discrete_Cosine_Transform`
- `Inverse_Discrete_Cosine_Transform`
- `Discrete_Cosine_Transform_Rows`
- `Inverse_Discrete_Cosine_Transform_Rows`
- `Multiply_Spectra`
- `Multiply_Packed_Spectra`
- `Multiply_Packed_Spectra_Rows`
- `Optimal_DFT_Size`

Four forward Fourier forms are available: ordinary full-complex, ordinary
packed CCS, row-wise full-complex, and row-wise packed CCS.
`Discrete_Fourier_Transform` returns a full two-channel (`C2`) complex spectrum.
Use `Float32_Vec2_Access` or `Float64_Vec2_Access` to inspect full-complex
spectra: for these spectral APIs, component 0 is real and component 1 is
imaginary. Vec2 values outside this context remain semantic-neutral.
For real (`C1`) input, `Packed_Discrete_Fourier_Transform` returns OpenCV's
native same-shape, same-depth packed CCS (`C1`) spectrum. The `_Rows` forms
perform each row as an independent 1-D transform. In particular,
`Packed_Discrete_Fourier_Transform_Rows` returns a same-shape C1 Mat containing
one independent packed CCS representation per row, rather than an ordinary 2-D
spectrum. The packed representation is opaque and its physical storage layout
follows OpenCV. All inverse paths are scaled, so a forward/inverse round trip
approximately recovers the source without an extra caller scale factor.
`Inverse_Real_Discrete_Fourier_Transform` provides the real-output path for
The corresponding `_Rows` operations use `DFT_ROWS` to transform every row as
an independent 1-D signal. Full-complex C2 and packed CCS C1 row spectra have
distinct inverse operations.
The corresponding row-wise DCT operations use `DCT_ROWS` and OpenCV's
orthonormal inverse convention. Only the row length must be one or even; the
number of independent rows may be odd.

`Multiply_Spectra` operates on full-complex C2 spectra interpreted as one
spectrum. `Multiply_Packed_Spectra` operates on packed CCS C1 spectra using
ordinary non-row-wise spectrum geometry. `Multiply_Packed_Spectra_Rows`
expects packed CCS C1 input containing one independent spectrum per row, such
as output from `Packed_Discrete_Fourier_Transform_Rows`, and uses `DFT_ROWS`.
These operations distinguish ordinary multiplication from conjugate-right
multiplication with `Spectrum_Multiplication_Kind`.

Spectrum multiplication does not automatically perform forward or inverse
transforms, scale, pad, crop, or construct a complete convolution or
correlation pipeline. Callers are responsible for those operations and for
deciding whether their padding and geometry represent circular or linear
convolution or correlation. Packed spectrum division, CCS-bin accessors,
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
- `Map_Length` and zero-based `Map_Key` (root or entered map)
- named/indexed `Kind` for structural node categories
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

For an open read-only storage, keys at the root or entered mapping are returned
as independent Ada strings in OpenCV's mapping iteration order, not sorted.
When the current node is a mapping with no entries, `Map_Length` returns zero;
map enumeration in a sequence context is invalid. For example:

```ada
Count := Reader.Map_Length;
if Count > 0 then
   for I in 0 .. Count - 1 loop
      Put_Line (Reader.Map_Key (I));
   end loop;
end if;
```

`Node_Kind` describes the **OpenCV FileNode structure**, not the type of an
arbitrary serialized OpenCV object. A persisted 2-D or N-D `Mat` is a mapping
(`opencv-matrix` or `opencv-nd-matrix`), so `Kind ("Matrix")` returns
`Mapping_Node`, not a separate Mat kind. Use `Read_Mat` when Mat conversion is
intended. Named `Kind` works at the root or in an entered map; indexed `Kind`
works in an entered sequence. Both leave navigation unchanged. For example:

```ada
declare
   Count : constant Natural := Reader.Map_Length;
begin
   if Count > 0 then
      for I in 0 .. Count - 1 loop
         declare
            Key : constant String := Reader.Map_Key (I);
         begin
            case Reader.Kind (Key) is
               when P.Integer_Node  => Put_Line (Key & ": integer");
               when P.Real_Node     => Put_Line (Key & ": real");
               when P.String_Node   => Put_Line (Key & ": string");
               when P.Sequence_Node => Put_Line (Key & ": sequence");
               when P.Mapping_Node  => Put_Line (Key & ": mapping");
            end case;
         end;
      end loop;
   end if;
end;
```

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

Missing nodes raise `OpenCV_Error`; stored zero, empty string, empty Mat, and
empty sequence remain distinguishable from absence. Empty mapping preservation
depends on OpenCV and the persistence format; when OpenCV parses a node as a
mapping with no entries, `Map_Length` reports zero.

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

## UMat and the Transparent API baseline

UMat-native `Bitwise_And`, `Bitwise_Or`, `Bitwise_Xor`, `Bitwise_Not`
and their masked overloads operate on stored bits (including exact Float16
bits). `Compare` and scalar-bounded `In_Range` return UInt8 C1 UMat masks;
these masks feed masked UMat operations directly, without a Mat round-trip.
Masked UMat operations require UMat masks; Mat operations still require Mat
inputs and masks. Mixed Mat/UMat operands or masks are not supported. OpenCL
is optional, and UMat does not guarantee GPU execution.
Binary bitwise operands require matching 2-D rows, columns, depth and channels;
unmasked `Bitwise_Not` also accepts N-D. Masks require matching rows and
columns, UInt8 depth and one channel. `Compare` requires compatible 2-D C1
operands; scalar `In_Range` accepts N-D with at most four channels and returns
one mask value per element. Empty `In_Range` raises `OpenCV_Error`. A typed
empty bitwise result retains its source type and 2-D shape; empty `Compare`
releases its result, as with the established Mat overload.

`OpenCV.Core.UMat` is a controlled, Core-owned `cv::UMat` header behind an
opaque C handle. Default construction yields an empty native UMat. Use
`Create_UMat (Rows, Columns, Element_Type)` or
`Create_UMat (Shape, Element_Type)` for 2-D or N-D storage. Shape arrays are
read in Ada iteration order; UMat uses the existing `Mat_Type`, `Depth_Type`,
`Channel_Count`, `Dimension_Array`, and `Mat_Size`. On OpenCV 4.1 through 4.10,
shapes may contain 2 through 32 dimensions; OpenCV 5.0's native MatShape
capacity limits both Mat and UMat to 10. UMat provides `Is_Empty`,
`Dimension_Count`, `Extent`, `Shape`, `Rows`, `Columns`, `Depth`, `Channels`,
`Element_Type`, `Total`, `Element_Size`, `Channel_Size`, `Is_Continuous`, and
`Is_Submatrix`. As for Mat, Rows and Columns reject genuine N-D arrays.

Ada assignment creates a distinct native UMat header sharing underlying
storage; finalizing either header leaves the other usable. `Clone` is an
explicit independent deep copy. `Region` and half-open N-D `Slice` are shallow
views that retain the allocation; `Copy_To` returns an independent UMat via
native UMat copy, not a Mat round-trip. `Set_To` fills complete C1 through C4
elements using `OpenCV.Scalar`. The `Convert_To` function returns an independent
native UMat conversion; its destination-taking procedure permits native storage
reuse/reallocation. Nonempty conversion retains shape and channels; see
[conversion semantics](#conversion-and-element-wise-mathematics) for Regions,
self-conversion, and version-dependent empty metadata.

Because Ada forbids one dispatching operation on *two* unrelated tagged
types, independent host transfers live in `OpenCV.Core.Transfers`:

```ada
with OpenCV.Core.Transfers;
Device : OpenCV.Core.UMat := OpenCV.Core.Transfers.To_UMat (Host);
Copy   : OpenCV.Core.Mat  := OpenCV.Core.Transfers.To_Mat (Device);
```

Both transfers copy logical contents independently of source lifetime, even
for a non-contiguous Mat Region. They do not expose a mapped Mat view.
For typed inspection of UMat contents, transfer to an independent Mat and use
the existing Mat typed access packages. There is no direct mapped typed UMat
access or public OpenCL context/device/queue/raw pointer API in this release.

Cooperating OpenCV Ada module crates can borrow callback-scoped
`Input_UMat_Handle` and `Output_UMat_Handle` capabilities through
`OpenCV.Core.Module_Interop`. This is module implementation infrastructure,
not the normal application API: applications should use `OpenCV.Core.UMat`.
The installed `opencv_core_module_bridge.hpp` lets private module shims
resolve these capabilities to the actual borrowed `const cv::UMat *` or
`cv::UMat *` header. No Mat transfer, host representation, or `getMat()` mapping
occurs in the bridge. Modules can pass these headers directly to OpenCV
InputArray/OutputArray operations; output operations may rebind the actual
Core UMat header, and Core observes that rebinding after the callback.
Core retains ownership of the opaque wrapper and native header. Neither the
handle nor the native pointer may be saved for later use; the pointer must
not be retained or deleted after the callback/call scope. No ownership
transfer occurs. All cooperating shims must use a compatible OpenCV ABI and
installation with Core. OpenCL remains optional, and GPU execution is not
guaranteed.

All public allocations use `USAGE_DEFAULT`; host/device/shared allocation
preferences are intentionally deferred. OpenCL need not be compiled in,
available, enabled, or backed by a device: CPU fallback is required behavior,
and the test suite explicitly disables OpenCL while exercising the public
operations. **UMat enables OpenCV's Transparent API dispatch where native
operations support it. It is not a guarantee that an operation executes on a
GPU.** `Add`, `Subtract`, `Multiply`, `Divide`, `Abs_Diff`, `Minimum`,
`Maximum`, `Add_Weighted`, and `Scale_Add` accept two UMat operands and return
independent UMat results. No Mat transfer or mapping is used in these paths.
The first seven operations and `Scale_Add` require matching 2-D shape, depth,
and channels. `Add_Weighted` accepts matching N-D shape, depth, and channels,
just like its Mat overload. On OpenCV 4.x Float16 `Add_Weighted` widens UMat
operands to Float32 UMat, computes using double Alpha/Beta/Gamma, then narrows
once; OpenCV 5 uses native Float16. Float16 `Scale_Add` widens UMat operands on
all supported versions, narrows Scale to Float32 before the native Float32
kernel, then narrows the result once. SIMD/FMA rounding may vary by platform.
`Normalize`, `Sqrt`, `Exp`, `Log`, `Pow`, `Magnitude`, `Phase`,
`Cart_To_Polar`, and `Polar_To_Cart` also execute UMat-native, through shared
typed Mat/UMat helpers with no binding-side Mat temporaries or transfers.
Normalize keeps the source depth, accepts N-D, and offers L1, L2, Infinity,
and Min_Max without masks. Float16 norm normalization uses native support;
Float16 Min_Max is unsupported in OpenCV 4.x and supported in OpenCV 5.
Float16 Infinity also retains native version/backend differences (CPU 4.1/4.6
have incorrect half reduction results; 4.10/5.0 correct them). No new half
widening or normalization policy is introduced.

Both `Mat` and `UMat` offer independent results and reusable destinations:

```ada
Result := Source.Normalize (Kind => L2, Alpha => 1.0);
Source.Normalize
  (Destination => Existing,
   Kind        => L2,
   Alpha       => 1.0);
```

The procedure uses the actual native destination header. Compatible shape,
source depth, and channels reuse storage, including interior `Region` storage
still shared with its parent and existing shallow aliases. Incompatible shape
or type can reallocate; an incompatible Region may detach while old aliases
retain the original parent storage. Exact self (`Source.Normalize (Source, ...)`)
and distinct same-layout shallow aliases are supported. Arbitrarily partially
overlapping Regions are **not** guaranteed. N-D and unmasked multichannel
normalization remain supported; there is no destination depth parameter.

For L1/L2/Infinity, Alpha is the target norm, Beta is ignored, and a zero norm
uses native zero scale. Min_Max uses the sorted Alpha/Beta bounds; equal bounds
produce a constant, and constant input maps to the lower bound. Native integer
rounding/saturation and floating approximation remain unchanged.

Empty sources release destination pixels. OpenCV 4.x Mat release retains the
old destination type; OpenCV 5.0 Mat recreates the empty source type. The existing
UMat empty-storage safety helper releases ordinary empty outputs, retaining old
type metadata even on 5.0 (where release resets dimension count to zero, giving
a null `Shape`). Empty Float16 Min_Max remains native/version-sensitive
(4.x rejects; 5.0 CPU succeeds); no new empty OpenCL guarantee is introduced.
Temporary external/selected Mat views may be sources but are never mutable
normalization destinations, even when currently compatible. Pre-native null,
raw-kind, and temporary-destination rejection preserves the destination;
arbitrary failure atomicity after native execution begins is not promised.
UMat normalization introduces no binding-side host mapping/transfers. Exact-tag
source ranges and probes are recorded in
`tests/probes/normalize_destination_source_findings.md`.

Sqrt/Exp/Log require Float32 or
Float64, process channels independently, and accept N-D. Their approximation
and special-value contracts match the Mat operations. Pow rejects Float16;
floating depths accept integer and non-integer powers, while integer depths
accept only nonnegative integer powers. UInt8/Int8/UInt16/Int16 saturate;
Int32 overflow remains native and non-saturating.

Magnitude, Phase, and Cart_To_Polar require matching 2-D Float32/Float64
operands, including channels. Angles use radians by default or `Degrees`.
`UMat_Polar_Coordinates` owns Magnitude/Angle UMat results, and
`UMat_Cartesian_Coordinates` owns X/Y UMat results; both fields are produced
failure-atomically by one native call and have independent storage. Empty
Magnitude (default or typed), or angle-only Polar_To_Cart, means unit magnitude.
Non-empty Magnitude must match Angle's 2-D layout. Typed-empty unary/vector
results retain type and shape; Normalize preserves the empty compatibility
behavior described above.
Empty-storage safety bypasses avoid native OpenCL vector-width crashes.
OpenCL is optional and the public math family is tested with it disabled;
there is no GPU-execution guarantee.

Compatibility handling includes OpenCV 4.10 UMat empty-storage safety and
legacy pre-4.10 Float64 empty-magnitude `polarToCart` behavior. OpenCL is
optional; CPU fallback is tested. Mixed Mat/UMat operands, UMat reshape,
DFT/DCT UMat overloads, callback-scoped CPU mapping, and downstream Imgproc
UMat overloads remain unsupported.

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
   N-dimensional construction, UInt8/Int8/UInt16/Int16/Int32/Float16/Float32/Float64 C1
   Get/Set, UInt8/UInt16/Int16/Int32/Float16/Float32/Float64 C2 Vec2,
   UInt8/UInt16/Int16/Int32/Float16/Float32/Float64 C3 Vec3, and
   UInt8/UInt16/Int16/Int32/Float16/Float32/Float64 C4 Vec4 Get/Set, `Slice` views, `Shape`, and
   Shape-based N-D reshape are available. Callback-scoped whole-buffer
   borrowing is provided for continuous N-D Mats of every typed layout.
   Packed and strided (gapped) caller-owned external views support genuine
   N-D shapes for every typed layout. Callback-scoped dimension-dropping
   selected views (`With_Selected_View`) are available: any non-final
   dimensions may be fixed to one index and dropped while the others keep
   half-open ranges. The final source dimension must remain, because OpenCV
   always uses the element size as a Mat's last step, and at least two result
   dimensions must remain; there is no 1-D or scalar selected Mat
   representation yet. This is not a general NumPy-style indexing model:
   there is no step slicing, axis reordering, broadcasting, or
   dimension-dropping shallow `Mat` returned outside a callback. N-D row APIs
   are not provided because a row is a 2-D concept. OpenCV 5.0's native Mat
   shape capacity remains 10 dimensions.

2. **SparseMat and UMat are not complete native APIs.**
   UMat has no direct mapped typed access, public OpenCL controls or raw OpenCL
   handles, masked Set_To, mixed Mat/UMat operands, reshape, DFT/DCT overloads,
   or downstream Imgproc UMat overloads. Its arithmetic, bitwise/mask, and math
   subset and callback-scoped module bridge are available as described above.
   Direct typed node access and read-only stored-node traversal cover all eight
   depths in C1/C2/C3/C4 (32 layouts). One vector is one complete element.
   Explicit all-zero vectors remain stored nodes; missing reads return zero and
   do not create a node. Float16 components keep exact binary16 bits.
   `Convert_To` and numeric `To_Dense` cover stored-node scaling and
   sparse-to-dense scale/offset conversion for every depth except Float16,
   which OpenCV 4.1 through 5.0 does not implement in the sparse conversion
   tables. `Norm` and `Normalize` are restricted to Float32 and Float64 with
   exactly one channel; only stored nodes participate, and `Min_Max`
   normalization is unavailable. Broader sparse arithmetic, C5+ typed layouts,
   and native 1-D SparseMat are not wrapped. Native 1-D
   SparseMat is deliberately omitted because the dense interoperability model
   begins at 2-D.

3. **Typed direct/zero-copy access covers C1/C2/C3/C4 only.**
   Every supported depth — UInt8, Int8, UInt16, Int16, Int32, Float16,
   Float32, and Float64 — has complete C1/C2/C3/C4 typed and zero-copy
   coverage (32 layouts). UInt8, Int8, UInt16, Int16 and Int32 C1/C2/C3/C4 have 2-D and N-D Get/Set, copied and borrowed
   2-D rows, continuous whole-buffer borrowing, and packed or row-strided
   2-D caller-buffer views. Int8 preserves the exact signed domain `-128 .. 127`
   without unsigned or floating-point intermediates. Float16 C1 has 2-D and N-D Get/Set that
   preserve the exact binary16 encoding, plus copied and borrowed 2-D row
   access, continuous 2-D/N-D whole-buffer borrowing, and packed or row-strided
   2-D caller-buffer views. Float16 C2, C3, and C4 have 2-D and N-D
   Vec2/Vec3/Vec4 Get/Set, copied and borrowed 2-D rows, continuous 2-D/N-D
   whole-buffer borrowing, and packed or strided 2-D/N-D caller-buffer views
   that preserve exact binary16 encodings per channel, so Float16 has complete
   C1/C2/C3/C4 coverage. UInt8, UInt16, Int16, Int32, Float32, and Float64 C3
   likewise have 2-D and N-D Vec3 Get/Set. No C1–C4 typed-layout gap remains;
   the deliberate typed-layout limitation is C5+.
   One vector remains one complete three-channel element; neither N-D access
   nor N-D buffer borrowing flattens channels into scalar indices. Rows
   remain 2-D concepts; packed and strided external views accept N-D shapes,
   with strides counted in complete vectors.
   Float64 C1 has 2-D and N-D Get/Set, classification, 2-D row access,
   continuous 2-D/N-D whole-buffer borrowing, and packed or row-strided 2-D
   caller-buffer views. Every packed caller-buffer view listed in this item
   also accepts an N-D `Shape`, and every strided view an N-D `Shape` with
   per-dimension `Strides` (see item 4). Other OpenCV
   depths are available to general Mat operations but do not yet have the same
   typed access families. Float16 now has an exact 16-bit public value
   representation, IEEE-754 classification helpers, numeric
   Float32 <-> Float16 conversion, scalar C1 2-D/N-D Get/Set, copied and
   borrowed row access, continuous buffer borrowing, packed or strided
   external caller-buffer Mat views, and C2/C3/C4 2-D and N-D vector Get/Set
   plus 2-D rows, continuous buffer borrowing, and packed or strided external
   caller-buffer Mat views. All eight supported depths have complete
   C1/C2/C3/C4 typed coverage; C5+ typed families remain unavailable. N-D row
   APIs remain unavailable.

4. **External caller-buffer views are callback-scoped.**
   Packed 2-D and packed N-D (`Shape`, 2 .. 32 dimensions) views are available
   for UInt8, Int8, UInt16, Int16, Int32, Float16, Float32, and Float64 C1,
   UInt8/Int8/UInt16/Int16/Int32/Float16/Float32/Float64 C2,
   UInt8/Int8/UInt16/Int16/Int32/Float16/Float32/Float64 C3, and
   UInt8/Int8/UInt16/Int16/Int32/Float16/Float32/Float64 C4. Packed views require exact logical
   capacity: `Data'Length` equals
   `Rows * Columns` or `product (Shape)`.
   Strided storage is exposed for the same layouts both as 2-D row strides
   and as N-D per-dimension strides (`Dimension_Stride_Array`). C2, C3, and C4
   strides count complete vectors, not scalar channels. N-D strides require a
   final stride of `1` and non-overlapping nesting. Strided backing storage
   must contain the complete outer extent (`Rows * Row_Stride` or
   `Shape (first) * Strides (first)` elements), including padding after the
   final logical row or outer block. Both read-only and writable scoped views
   exist; read-only is an Ada mode/capability restriction, not page protection.
   C5+ typed external layouts are not available.

5. **Whole-buffer borrowing requires continuous storage.**
   Genuine continuous N-D Mats and continuous N-D Slices are supported, in
   OpenCV element order with the final dimension varying fastest. A typed
   empty Mat invokes the callback with an empty array. Use row borrowing for
   non-contiguous 2-D Regions or row-strided Mats. A non-contiguous N-D Slice
   has no row-based alternative; use `Clone` to obtain continuous storage.

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
    Nested maps and sequences are supported, but public FileNode objects or iterators,
    file append mode, Base64, comments, gzip controls, FLOW
    formatting, and raw persistence APIs are not part of the current slice.

13. **The spectral API is deliberately focused.**
    Full-complex and packed CCS DFT/DCT workflows, including `DFT_ROWS` and
    `DCT_ROWS` forms, are supported. Packed-spectrum division, CCS-bin
    accessors, packed/full representation conversion, and in-place transforms
    are not yet exposed.

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

New work starts on a feature branch, or on a corrective branch for focused
repairs. A larger cohesive vertical bundle is acceptable when its public API,
ABI, ownership, tests, and documentation are reviewed together; unrelated
speculative batches and broad rewrites remain prohibited.

Complete local formatting, builds, and tests before final submission. Cline
then commits and pushes the source branch and opens a real pull request against
`main`. Pull requests remain open and unmerged pending review, with auto-merge
disabled. Corrective review work continues on the same pull-request branch and
must be revalidated at its new head. Completion reports identify the exact
locally tested and pushed source SHA rather than relying only on a PR merge-ref
result.

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
0.4.0
```

See `CHANGELOG.md` for the 0.4.0 UMat additions, the historical 0.3.0 typed
Mat and SparseMat additions, and the 0.2.0 shared-value relocation.

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
- controlled `UMat`, explicit independent Mat/UMat transfers, and a UMat-native
  arithmetic, mask/bitwise, normalization, and unary/vector math subset with
  OpenCL-optional CPU fallback;
- callback-scoped Mat/UMat/SparseMat module interoperability through the
  installed native bridge, without transferring ownership;
- typed C1 element access and C2/C3/C4 Vec2/Vec3/Vec4 access for every
  supported depth: UInt8, Int8, UInt16, Int16, Int32, Float16, Float32 and
  Float64;
- copied rows plus scoped zero-copy row and continuous-buffer borrowing;
- callback-scoped zero-copy packed and row-strided caller-owned `Mat` views
  for the supported typed C1/C2/C3/C4 layouts;
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
