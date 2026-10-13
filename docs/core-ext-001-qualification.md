# CORE-EXT-001 local qualification record

Starting `origin/main`: `7bcdc3a1b130b8f51f2c97ac9f014578a281e64e`.
Branch: `feature/ext-001-external-gpr-consumer`.

## Environment

Local Podman image: `localhost/opencv-core-debian12-opencv-4.6`, image ID
`9216a90e0a3e` (existing repository Debian 12 container recipe).
Debian 12.15 x86_64; Alire 2.1.1; GNAT/GCC 16.1.0;
Alire gprbuild package 26.0.1, GPRbuild/GPRinstall 26.0.0 binary banners,
2026-04-15, GPRinstall engine 2. Application C++: Debian GCC 12.2.0.
OpenCV 4.6.0 (`libopencv-dev`, `libopencv-core406` 4.6.0+dfsg-12),
libstdc++6 12.2.0-14+deb12u1, libc6 2.36-9+deb12u14,
binutils 2.40-2. No independently installed GNAT 12 was qualified.

## Results

* Unmodified starting validator: recursive install and both consumers PASS.
* Extended default validator: PASS, exercised separately to preserve its existing
  single-environment entry point.
* Two-container qualification: PASS. Core built with Alire; GPRinstall invoked
  through the selected environment. Consumer container mounted only evidence
  and the selected toolchains, not the checkout; `/usr/local/bin/alr` removed.
* Direct `gprbuild -P consumer.gpr -v`: PASS, no Alire manifest. Public Mat
  creation/metadata, typed access, shallow assignment, independent Clone,
  Region mutation/lifetime, reassignment/cleanup scopes, invalid-Region
  `OpenCV_Error`, and default-empty LUT native failure translation passed.
* Mixed application: PASS, `/usr/bin/g++` compiled application-owned OpenCV
  code and the qualified GNAT toolchain compiled Ada. Existing application
  OpenCV linkage remained in its GPR. No native Mat pointers exchanged.
* Prefix relocation: PASS for freshly built standalone and mixed executables.
  `prefix-a` moved to `relocated-longer-prefix-b`; original prefix absent,
  checkout inaccessible. Installed source/object search paths and archive
  link traces resolved to the relocated install.
* ELF and `ldd -r`: PASS for both executables at both prefixes. Same
  `/usr/lib/x86_64-linux-gnu/libopencv_core.so.406` and `libstdc++.so.6`;
  no unresolved symbols or missing libraries. Default Ada runtime linked
  from GNAT 16.1.0's `adalib/libgnat.a`. Native dependencies include
  libgcc_s, libc, libm, zlib, GLX/GLdispatch, LAPACK/BLAS, TBB, X11/XCB,
  libgfortran, libquadmath, Xau/Xdmcp, libbsd, and libmd.
* Full AUnit suite: 2,025 successful tests; zero failed assertions or
  unexpected errors.
* Existing external-shim GPRinstall regressions: all three passed.
* GNATformat 26.0 formatted/checked both affected Ada consumer sources.
  Shell syntax checks and `git diff --check` passed.

Local detailed evidence is retained outside the repository at
`/tmp/core-ext-001-reviewed-evidence`, with the driver log at
`/tmp/core-ext-001-reviewed-qualification.log`. CI recreates qualification and
uploads logs/GPR metadata; local files are not a substitute for hosted checks.

## Review scope and limitations

No production Ada/C++ sources, public API, ABI, library GPRs, Alire manifests,
version, or GNATdoc baseline changed. No public semantic validation is
duplicated in the C++ shim by this change; the shim is unmodified.
Existing compatibility jobs are preserved, with one dedicated Debian 12
qualification job added. Hosted CI status and exact final source SHA are
reported in the PR/final handoff rather than hard-coded into this record.

This qualifies the default static-PIC install and rebuilding consumers after
relocation, not every library mode or relocating an already-linked executable.
Cleanup is behaviorally exercised, not leak-proven by memory analysis. Full
documentation generation, GNATprove, and coverage were not run: no production
Ada, SPARK code, or API documentation changed. Other platform compatibility
remains subject to existing hosted CI. Yocto, cross-compilation, different GNAT
major interoperability, and alternate OpenCV/C++ runtime ABIs remain
unqualified. Version remains 0.5.0-dev; no release tag or Alire index submission.