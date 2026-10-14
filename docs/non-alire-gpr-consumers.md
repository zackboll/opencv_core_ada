# Alire-built Core in an existing GPR application

[README](../README.md) · [Interoperability](interop-and-compatibility.md)

Core can be built with Alire, installed with GPRinstall, and used by an
application that has **no Alire manifest, pin, action, or build invocation**.
The installed GPR project, not repository-relative source directories, is the
integration boundary. This guide qualifies native Debian 12 x86_64 with distro
OpenCV 4.6; it does not establish cross-compilation or Yocto support.

The commands and evidence below describe the original GNAT 16 qualification.
Independent GNAT 12 native and generic AArch64 qualification is recorded in
[GNAT 12 completion](gnat12-completion.md). Always rebuild Core and consumers
with the same compiler/runtime; that later evidence does not make GNAT 16
installed ALIs compatible with GNAT 12.

## Build and install Core

Install Debian's `build-essential`, `libopencv-dev`, `pkg-config`, and Alire.
In the Core checkout:

```sh
alr -n --force toolchain --select gnat_native=16.1.0 gprbuild=26.0.1
alr -n build
alr -n exec -- gprinstall -f -p -r --prefix=/opt/core-0.5-dev -P opencv_core.gpr
alr -n exec -- sh -c 'printf "%s\n" "$PATH"' > /tmp/core-toolchain-path
```

The last command records the compiler/tool binaries for later **direct** use;
provisioning compilers with Alire is not the same as building an application
with Alire. Do not carry checkout directories into the application's PATH.
Keep the selected compiler installation available after installing Core.

The default Linux install contains:

| Path relative to prefix | Purpose |
| --- | --- |
| `share/gpr/opencv_core.gpr` | Externally-built Ada library project; imports `opencv_core_shim` |
| `share/gpr/opencv_core_shim.gpr` | Externally-built C++ library project and native link options |
| `include/opencv_core/` | Ada specs and generic bodies required by clients |
| `lib/opencv_core/` | Compatible ALIs and `libopencv_core_ada.a` |
| `lib/opencv_core_shim/` | `libopencv_core_shim.a` |
| `include/opencv_core_module_bridge.hpp` | Internal cross-module bridge, not application pointer access |

Both libraries are static-PIC by default. The generated projects use relative
source/library paths, so the installation prefix can move. The shim project
records `-L/usr/lib/x86_64-linux-gnu -lopencv_core -lstdc++` on this platform.
These system dependency paths are not relocatable target-sysroot metadata.
Do not copy only the archives: specs, generic bodies, ALIs, and both projects
are part of the installed integration contract.

## Existing application's GPR

Add one import to the application's existing project; retain its own source
layout, compiler settings, C++ sources, and existing native dependencies:

```gpr
with "opencv_core";
project Consumer is
   for Source_Dirs use ("src");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Create_Missing_Dirs use "True";
   for Main use ("main.adb");
end Consumer;
```

Outside the Core checkout, using the qualified compiler binaries on PATH:

```sh
export PATH="$(cat /tmp/core-toolchain-path)"
export GPR_PROJECT_PATH=/opt/core-0.5-dev/share/gpr
gprbuild -P consumer.gpr
./bin/main
```

The consumer does not need Alire installed. Its sources use `OpenCV`,
`OpenCV.Core`, and public typed-access child packages. Do not add Core's
implementation sources to the application's source directories or import the
shim C ABI directly.

For a mixed Ada/C++ application, its existing C++ code may continue to include
`opencv2/core.hpp` and link `-lopencv_core -lstdc++`. Importing Core does not
require a second OpenCV installation. The Debian-specific executable example
is [`tests/installed_mixed_consumer.gpr`](../tests/installed_mixed_consumer.gpr),
with application-owned C++ code and a small private C interface. It passes no
OpenCV native pointers between Ada and C++. Its `/usr/bin/g++` and include
directory are intentionally specific to Debian, not a portable toolchain
replacement for an existing application.

## Toolchain contract

Use the **same qualified GNAT compiler and runtime** to build Core and the
initial consumer. ALIs, object files, binder behavior, compiler switches, and
Ada runtime must agree. Different GNAT major versions are not silently binary
compatible; Debian GNAT 12 interoperability is not qualified by this test.
Rebuild Core for the application's compiler rather than rewriting the
application's toolchain to consume incompatible binaries. A different GPRbuild
or GPRinstall version also requires qualification of generated metadata and
link behavior; package version and binary banner need not be identical.

The native qualification uses:

* Alire 2.1.1, `gnat_native=16.1.0`, target `x86_64-pc-linux-gnu`.
* Alire `gprbuild=26.0.1`; GPRbuild/GPRinstall banners report 26.0.0
  (2026-04-15, GPRinstall engine 2).
* Debian 12 OpenCV 4.6.0, package `libopencv-core406` / `libopencv-dev`
  `4.6.0+dfsg-12`, SONAME `libopencv_core.so.406`.
* Application C++ compiler Debian GCC 12.2.0, `libstdc++.so.6` package
  `12.2.0-14+deb12u1`; glibc package `2.36-9+deb12u14` in the local image.
  Core's shim is compiled with the selected GNAT toolchain's g++ 16.1.0;
  the exercised symbols resolve successfully against Debian's libstdc++ 6.
* GNAT's default Ada runtime is linked statically (`libgnat.a`); OpenCV,
  libstdc++, libgcc_s, glibc, and OpenCV's transitive dependencies remain
  dynamic. A static binding does **not** mean a fully static executable.

Package revisions can change when the container is rebuilt. Qualification
records actual versions, compiler paths, runtime location, ELF NEEDED entries,
and `ldd -r` resolution rather than assuming the image tag pins all packages.
The Core shim and application's C++ translation units must use compatible
OpenCV headers/libraries and the same C++ ABI/runtime family. This exercise
does not qualify mixing libc++ with libstdc++, alternate OpenCV builds, or all
possible compiler/runtime combinations.

## Reproducible Debian 12 qualification

From the repository root, with Docker (or `CONTAINER_ENGINE=podman`):

```sh
docker build -t opencv-core-ci-4.6 containers/debian12-opencv-4.6
CORE_CONSUMER_EVIDENCE=/tmp/core-consumer-evidence \
  sh scripts/qualify_debian12_consumer.sh
```

The driver extends the existing installed-Mat validator rather than replacing
it. The first container uses Alire to build Core and recursively install it.
The second container mounts only qualification artifacts and the selected
toolchain: the checkout is absent and `alr` is removed. Fresh standalone and
mixed-language consumers build with direct GPRbuild, run against the original
prefix, then rebuild and run after that prefix is moved and removed.

The public Mat test checks creation, metadata, typed Get/Set, shallow assignment,
Clone independence, shared Regions, retained storage after header finalization,
reassignment, repeated cleanup scopes, Ada validation errors, and native
OpenCV failure translation. This is behavioral cleanup evidence, not a memory
leak proof or a Valgrind run.

Logs verify installed specs/ALIs and both archives, reject checkout/original
prefix references in relocated resolution/link traces, and check ELF/runtime
dependencies with `readelf -d` and `ldd -r`. Both application paths must resolve
`libopencv_core.so.406` and `libstdc++.so.6` without missing libraries or
unresolved symbols. The dedicated compatibility CI job preserves logs and
installed GPR metadata as artifacts; existing compatibility jobs remain intact.

## Debugging and relocation

* Project not found: check `GPR_PROJECT_PATH` points to **prefix/share/gpr**.
* Missing Ada units/ALIs: check recursive installation and run
  `gprls -v -U -P consumer.gpr`; do not fix it by adding checkout sources.
* ALI/compiler mismatch: verify `command -v gcc gnat gprbuild` and version
  banners, then rebuild/install Core with the application's qualified compiler.
* Missing shim symbols: inspect `gprbuild -P consumer.gpr -v`; both archives
  must come from the installed prefix, in dependency order.
* Missing OpenCV/C++ symbols: check installed shim `Linker_Options`,
  `pkg-config --modversion opencv4`, `readelf -d bin/main`, and `ldd -r bin/main`.
  Avoid injecting a second incompatible OpenCV/runtime through search paths.
* After moving the prefix: update `GPR_PROJECT_PATH`, remove consumer objects,
  and rebuild. This qualifies rebuilding against a relocated install, not
  moving an already-linked executable without considering its RPATH.

Future Yocto Scarthgap AArch64 integration will reuse this installed-GPR model,
but must independently qualify the existing consumer cross-toolchain,
`ENV_PREFIX`, target Ada runtime, OpenCV headers/libraries in the target
sysroot, and C++ runtime. The native generated `/usr/lib/x86_64-linux-gnu`
options must not be reused as a target configuration. No Yocto support or
cross-compilation readiness is claimed here.