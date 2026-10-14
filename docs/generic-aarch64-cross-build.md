# Generic Linux AArch64 cross-build investigation

This work is **not Yocto Scarthgap qualification**. The proprietary container
remains inaccessible. The public Debian reference can compile and link a small
Ada probe, but GNAT 12 fails the production binding's existing representation
checks. No production cross-build, installed consumer, or target runtime PASS
is claimed.

## Explicit external inputs

The opt-in `scripts/cross_build_core.sh` accepts `--prepare` or `--build` and a
new absolute workspace outside the checkout. It exports a clean Git HEAD with
`git archive`; it never copies native config, objects, libraries, or Alire state.
Its generated files, probe objects, production objects/ALIs, libraries, and
`install` prefix are physically inside that workspace. Existing destinations
are rejected, not reused. Native builds do not require `ENV_PREFIX`.

Required environment inputs:

| Input | Contract |
| --- | --- |
| `OPENCV_CROSS_TARGET` | Actual matching Ada/C++ AArch64 Linux target triple |
| `OPENCV_CROSS_ADA` | Externally supplied GCC/GNAT executable |
| `OPENCV_CROSS_CXX` | Externally supplied GNU C++ executable |
| `ENV_PREFIX` | Dedicated target development sysroot, not `/` |
| `OPENCV_CROSS_RUNTIME` | Compiler runtime containing `adalib` and `adainclude` |
| `OPENCV_CROSS_GPR_CONFIG` | Explicit GPRconfig-generated configuration |
| `PKG_CONFIG_LIBDIR` | Target metadata directories contained in the sysroot |

`PKG_CONFIG_PATH` must be empty. `PKG_CONFIG_SYSROOT_DIR`, when supplied, must
match the resolved sysroot. `OPENCV_CROSS_PKG_CONFIG`,
`OPENCV_CROSS_READELF`, `OPENCV_CROSS_GPRBUILD`, and
`OPENCV_CROSS_GPRINSTALL` select external tools; none are installed by the
wrapper. `OPENCV_CROSS_PROFILE` defaults to `development`. Installation stays
under the workspace; a successful installation can subsequently be moved.

`OPENCV_CORE_CROSS=True` dispatches Alire's existing pre-build action to the
target validator instead of generating host settings. Default native behavior
is retained. The current cross wrapper deliberately uses direct GPRbuild, not
Alire. It does not advertise safe Alire system-dependency resolution.

## Public reference evidence

Reference: a separate x86_64 Debian 12 container derived from the existing
OpenCV 4.6 compatibility image. Public apt candidates were inspected and an
installation simulation run before installing packages. No proprietary SDK or
rootfs was used.

* `gnat-12-aarch64-linux-gnu`, `g++-12-aarch64-linux-gnu`, and
  `libgnat-12-arm64-cross`: `12.2.0-14cross1`.
* `libopencv-core-dev:arm64`: `4.6.0+dfsg-12`.
* Actual target: `aarch64-linux-gnu`.
* Ada compiler: `/usr/bin/aarch64-linux-gnu-gcc` (GCC 12.2.0).
* C++ compiler: `/usr/bin/aarch64-linux-gnu-g++` (GCC 12.2.0).
* Runtime: `/usr/lib/gcc-cross/aarch64-linux-gnu/12`.
* GPRbuild/GPRconfig: the image's existing Alire-provisioned `26.0.1` tools.
* OpenCV SONAME: `libopencv_core.so.406`.

GPRconfig's non-Pro G++ discovery recognizes unprefixed `g++`, not Debian's
prefixed executable. A disposable `/reference/tools/g++` symlink points to
the actual cross compiler. Debian's unversioned cross-GCC package entry point
is also needed for GNAT discovery. The generated configuration was inspected;
an incomplete configuration produced by failed discovery was not accepted.

The Core-only Debian package does not supply `opencv4.pc`. The reference uses
the explicitly documented Core-only metadata under `tests/fixtures`, after
independently inspecting the installed headers, ARM64 library, package version,
and SONAME. This is not a fake Alire dependency identity.

The dedicated `/reference/sysroot` contains copied public cross-development
headers/libraries and ARM64 OpenCV Core. The original package installation was
not modified to synthesize negative cases. This minimal fixture is not a
complete deployable root filesystem.

Successfully executed probe commands inside the reference container:

```sh
/root/.local/share/alire/toolchains/gprbuild_26.0.1_e3f27f25/bin/gprconfig \
  --batch --target=aarch64-linux-gnu \
  --config=Ada,,/usr/lib/gcc-cross/aarch64-linux-gnu/12 \
  --config=C++,,,/reference/tools -o /reference/target.cgpr
/root/.local/share/alire/toolchains/gprbuild_26.0.1_e3f27f25/bin/gprbuild \
  --config=/reference/target.cgpr -P /reference/probe/probe.gpr -p -f -v \
  -cargs:Ada --sysroot=/reference/sysroot -largs --sysroot=/reference/sysroot
readelf -h /reference/probe/bin/probe
readelf -d /reference/probe/bin/probe
```

The trace selects cross GCC, `aarch64-linux-gnu-gnatbind`, and the cross G++
linker. The probe is ELF64, little-endian AArch64; NEEDED includes
`libgnat-12.so` and `libc.so.6`. It was **not executed**.

The production build was attempted with that configuration and explicit
`--sysroot` compiler arguments. GPRbuild created objects under
`/reference/core/obj/{development,shim/development}` and libraries under
`/reference/core/lib`, not the native checkout. The shim object is AArch64
ELF64. Production Ada compilation fails first at
`opencv-internal-c_api.ads:565:26: error: C Vec3 size mismatch`, followed by
other vector representation assertions. GNAT 12 also reports existing
aggregate-obsolescence warnings. No assertion was removed and no warning was
suppressed. This is a production compiler/representation compatibility blocker,
not evidence of successful production cross-compilation.

## Alire limitation

Alire 2.1.1's `help toolchains` permits user-installed tools; `build --help`
permits forwarded GPRbuild arguments. The actual native `printenv` selects
GNAT native 16 and exports a native `LIBRARY_PATH`, which cross preflight
rejects. The community `opencv` external definition resolves Debian's
`libopencv-dev` without a target architecture/sysroot selector. It cannot serve
as evidence that ARM64 OpenCV is satisfied. No dependency was bypassed, no
replacement compiler was selected, and no Alire cross-build success is claimed.

## Verification and remaining work

Successfully executed synthetic tests:

```sh
python3 -m unittest discover -s tests -p test_cross_configuration.py -v
```

The fixtures use disposable fake tool outputs to test rejection logic; they
are not architecture evidence. Actual ELF evidence comes from the public
reference probe and shim object.

Native Debian 12/OpenCV 4.6 `alr -n build`, three external-shim GPRinstall
tests, and the installed Mat consumer passed. The installed Mat and mixed
Ada/C++ consumers also passed with `CORE_DEBIAN_QUALIFICATION=True`, including
installation, prefix removal/relocation, runtime execution, and native ELF
dependency checks. The public API, shim implementation/header, and manifest
version remain unchanged.

Production AArch64 archives, cross-GPRinstall, independent consumer linking,
mixed consumer linking, relocation, and target execution remain blocked by
the reference GNAT 12 failure. A compatible external compiler must qualify
those steps before stronger dispositions are used. Native macOS/Windows
execution and actual Yocto compiler/runtime/sysroot integration remain separate
qualification gates. The five-guide Pages inventory is unchanged.