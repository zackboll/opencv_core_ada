# CORE-MAC-CI-001: native macOS GNAT linker SDK selection

## Regression and investigation

The [main failure](https://github.com/zackboll/opencv_core_ada/actions/runs/38833155825/job/116756220151)
tested `a3a3535e3ba42ecf9d026a8e0c8a8d657bb58b0d` on
`macos-26-arm64` image `20261013.0424.1` (macOS 26.6.2, build 25G83).
GNAT-FSF 16.1.0 failed linking AUnit, before executing tests: its linker
rejected `arm64e.x1` in
`/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/libSystem.tbd`.
The root Ada archive and Apple clang++ shim build had already succeeded.

The [successful PR #83 job](https://github.com/zackboll/opencv_core_ada/actions/runs/38832266266/job/116753465204)
used image `20260907.0351.1` and passed all 2,025 tests. Both jobs selected
Apple clang++ from Xcode 26.6. The image manifests identify the independent
Command Line Tools upgrade from `26.6.0.0.1781586589` to
`27.0.0.0.1788430756`. The MacPorts job in the failing main run landed on
the September image, so its success was not evidence against the regression.
This is independent of cross-runtime detection.

`configure_opencv.sh` already records the SDK selected by
`xcrun --sdk macosx --show-sdk-path` as `Cxx_Sysroot` and uses Apple clang++
for the shim. Previously neither the Core Ada project's consumer linker
options nor its relocatable library options selected that SDK. The test
project consequently inherited GNAT's compiled-in Command Line Tools SDK.

## Correction and repeatable diagnostics

For `Apple_Clang` configuration only, Core now supplies
`--sysroot=<Cxx_Sysroot>` in both places:

* `Linker.Linker_Options`, propagated to AUnit and installed/relocated consumers;
* `Library_Options` for the relocatable Ada library build.

The shim compiler and its SDK options are unchanged. GNU configurations,
including AArch64 Linux cross-builds, and the Windows link strategy are
unchanged. No SDK files, stubs, or error suppression are involved.

The native macOS job runs `scripts/probe_macos_native_link.sh` inside Alire.
Its tiny source lives in the test crate and has no OpenCV dependency. It
records the source SHA, image, `xcode-select -p`, selected SDK, CLT SDK
symlink and package version, GNAT g++ identity, actual linker path/version,
and GCC's expanded commands. Default and `SDKROOT`-only links are diagnostic
comparisons whose failures are printed; explicit-syslibroot linking and
execution are mandatory. A green default link on a September runner does
not establish that `SDKROOT` overrides the GCC specs.

The initial diagnostic commit `fd798504bb203db60e23d786fa84d17d6e38419b`
landed on the September image. Its observed configuration was:

* developer directory: `/Applications/Xcode_26.6.app/Contents/Developer`;
* SDK: `/Applications/Xcode_26.6.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26.5.sdk`;
* CLT SDK symlink: `MacOSX.sdk -> MacOSX26.5.sdk`;
* linker: GNAT toolchain `libexec/gcc/aarch64-apple-darwin24.6.0/16.1.0/ld`,
  `ld-classic`, `ld64-957.1`.

The expanded explicit link contains a trailing Xcode `-syslibroot` after
the GCC-generated CLT `-syslibroot`. All three probes passed on that older
image; qualification of the October image requires separate evidence.

The subsequent [October-image probe](https://github.com/zackboll/opencv_core_ada/actions/runs/38838788006/job/116773808100)
on `22c82932ddbff7d60b262260a56bb2aee3f80c70` reproduced the native failure
without OpenCV. The developer directory, Xcode SDK and bundled linker were
unchanged, but the CLT symlink targeted `MacOSX27.0.sdk` and the package
version was `27.0.0.0.1788430756`. Default linking failed, `SDKROOT`-only
linking passed, and appending linker-only `-syslibroot` still failed.
Consequently the initial linker-only production candidate is insufficient.
GCC's configured specs explicitly recognize `--sysroot=...` as an override
for the compiled-in default. The follow-up mandatory probe passed before
changing production configuration to that driver option.