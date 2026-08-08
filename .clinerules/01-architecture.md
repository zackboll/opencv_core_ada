# OpenCV Core Ada Binding Architecture

## Scope

This repository implements an idiomatic thick Ada binding for the OpenCV Core module.

Do not add bindings for other OpenCV modules to this crate.

Other OpenCV modules such as imgproc, imgcodecs, highgui, videoio, features2d, calib3d, and dnn belong in separate Alire crates that may depend on `opencvcore_ada`.

## Layering

The binding must be implemented in three layers:

1. Thick public Ada API
2. Thin Ada interop layer
3. C++ shim

Code dependencies flow downward only:

Thick Ada API -> thin Ada interop -> C++ shim -> OpenCV

Lower layers must never depend on higher layers.

The public Ada API must never directly depend on C++ ABI details.

## C++ Shim

Use a small C-compatible shim to isolate Ada from the unstable C++ ABI.

The shim may:

- construct and destroy C++ objects
- invoke OpenCV C++ methods
- translate C++ exceptions into explicit error results
- expose opaque object handles
- provide simple C-compatible access to OpenCV functionality

The shim must not contain high-level Ada API policy or duplicate functionality that can reasonably be implemented in Ada.

Do not expose C++ classes, references, templates, STL containers, exceptions, or name-mangled symbols directly across the Ada boundary.

## Thin Ada Interop Layer

The thin layer mirrors the C ABI exposed by the shim.

It should remain low-level and mechanically understandable.

The thin layer may contain:

- `Interfaces.C` compatible types
- imported C functions
- opaque handle types
- raw pointer representations
- low-level conversion helpers

Do not expose the thin layer as the preferred user API.

## Thick Ada API

The public API must be idiomatic Ada rather than a transliteration of C++.

Prefer:

- strong Ada types
- controlled types for ownership
- Ada exceptions or explicit Ada error abstractions
- generics where they naturally model C++ templates
- contracts where useful
- ranges and discriminants where useful
- deterministic resource management

Hide raw pointers, opaque C handles, and C++ implementation details from normal users.

## Design Principle

When choosing between matching OpenCV's C++ syntax and providing an idiomatic Ada abstraction, prefer the idiomatic Ada abstraction while preserving OpenCV semantics and expected performance.

Do not mechanically translate the OpenCV C++ API one declaration at a time without considering the appropriate Ada design.

## Object Ownership

Public Ada wrappers for reference-counted OpenCV objects such as `cv::Mat` should normally use `Ada.Finalization.Controlled`.

Ada assignment of a `Mat` must preserve normal OpenCV shallow-copy semantics:

- assignment creates a distinct `cv::Mat` header
- underlying pixel storage remains shared through OpenCV reference counting
- finalization destroys only that wrapper's C++ object/header
- shared pixel storage is released according to OpenCV reference counting

Provide an explicit `Clone` operation for deep copies.

Do not make normal Ada assignment perform an implicit deep copy.

Raw ownership of the underlying C++ object must never be exposed to users of the thick Ada API.

## Generic and Runtime-Typed APIs

Do not make the public `Mat` type generic.

`cv::Mat` is runtime-typed in OpenCV, so the thick Ada binding should preserve that model.

Typed access to `Mat` data should be provided through separate Ada generic packages or generic operations that validate the runtime matrix type before accessing storage.

Use Ada generics where they naturally model compile-time C++ templates, including types such as:

- `Matx<T, M, N>`
- `Vec<T, N>`
- `Point_<T>`
- `Scalar_<T>`

Do not mechanically translate every C++ template into an Ada generic.

Choose between runtime typing, Ada generics, tagged types, and ordinary overloads based on the semantics of the OpenCV abstraction and what produces the most idiomatic Ada API.

## Public Package Hierarchy

The `opencvcore_ada` crate owns the root `OpenCV` Ada package.

Expose the Core API primarily under:

- `OpenCV`
- `OpenCV.Core`
- child packages of `OpenCV.Core` where useful

Future OpenCV module crates should extend the same package hierarchy, for example:

- `OpenCV.Imgproc`
- `OpenCV.Imgcodecs`
- `OpenCV.Videoio`
- `OpenCV.Calib3d`
- `OpenCV.Features2d`
- `OpenCV.Dnn`

Those crates should depend on `opencvcore_ada` rather than defining competing root `OpenCV` packages.

Prefer hierarchical Ada package names over flattened names such as `OpenCV_Core`.

## Internal Binding Packages

Keep raw interoperability details under an internal package hierarchy.

Prefer private child packages such as:

- `OpenCV.Core.Internal`
- `OpenCV.Core.Internal.C_Types`
- `OpenCV.Core.Internal.C_API`
- `OpenCV.Core.Internal.Handles`

Nothing under `OpenCV.Core.Internal` is part of the supported public API.

Public package specifications must not expose:

- raw C pointers
- opaque shim handles
- `Interfaces.C` implementation types unless they are genuinely part of the public abstraction
- C++ ABI details
- shim-specific status codes

Where practical, declare internal binding packages as private child units.

Keep C++ shim source files physically separate from the public Ada API source files.

The agent must not bypass the internal layer by importing C shim functions directly into public API packages.

## Error and Exception Boundary

No C++ exception may cross the C ABI boundary into Ada.

Every exported C++ shim function that can fail must catch C++ exceptions and translate them into an explicit C-compatible error result.

At minimum, the shim should distinguish:

- success
- OpenCV exception
- standard C++ exception
- unknown exception

Preserve a useful diagnostic message from the caught exception.

The thin Ada interop layer should expose the raw status and diagnostic information.

The thick Ada API should translate shim failures into idiomatic Ada behavior, normally by raising well-defined Ada exceptions or by using an explicit Ada result abstraction where that is more appropriate.

Do not expose raw C++ exception types, `cv::Exception`, or shim-specific status codes in the public Ada API.

Never allow exceptions to propagate through `extern "C"` functions.
