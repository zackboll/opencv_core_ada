# AArch64 GNAT Pro / Yocto Core build and install

From a **clean checkout of the implementation candidate** or its unpacked
release/Alire source archive:

```sh
sh scripts/cross_install_core.sh \
  --target aarch64-linux-gnu \
  --toolchain-bin /usr/local/gnat/aarch64-linux-gnu/bin \
  --runtime /usr/local/gnat/aarch64-linux-gnu/lib/gcc/aarch64-linux-gnu/12.3.1/rts-native \
  --sysroot /usr/local/yocto/scarthgap/aarch64 \
  --prefix /usr/local/lib/aarch64-linux-gnu/ada \
  --profile release
```

These are the user's **GNAT Pro 25.0w / GCC 12.3.1** installation paths,
with OpenCV 4.9.0. They are example inputs, not implementation defaults. This
profile is distinct from the separately documented
[GNAT Pro 25.2 / GCC 13.3.1 qualification](adacore25-scarthgap-core-aunit.md).
No new target or compiler support claim is implied.

## Inputs and workflow

The host needs POSIX sh, GNU tar/coreutils (including `realpath` and
`sha256sum`), Git **only for Git sources**, pkg-config, readelf, GPRconfig,
GPRbuild and GPRinstall. Supply installed matching target GCC/GNAT and GNU C++
compilers, their runtime (`adalib` and `adainclude`), and a dedicated target
development sysroot with OpenCV headers, pkg-config metadata and libraries,
libc and libstdc++. No SDK or development tool is installed by this script.
The explicit runtime is required; there is no runtime autodetection.

Use `--source-root /absolute/source/root` to select another source tree;
otherwise the script's own tree is used, independent of the current directory.
Git sources must have accessible metadata at that root and a clean status.
They retain the existing exact-HEAD `git archive` semantics. A `.git`-free tree
uses explicit build inputs from that root, even if an unrelated repository
encloses it. Native/generated `config`, `obj`, `lib`, `bin`, Alire state and
Python caches are excluded from archive staging. Archive identity records the
source root, manifest SHA256 and staged snapshot SHA256, **not a fictitious
commit or an upstream archive provenance claim**. Use trusted, stable sources
and SDK inputs; this is not a sandbox against concurrent modification.

The entry point places the supplied toolchain directory first on PATH and
generates a configuration with:

```sh
gprconfig --batch --target="$target" \
  --config="Ada,,$runtime,$ada_compiler_directory,GNAT" \
  --config="C++,,,$cxx_compiler_directory,$cxx_executable_basename" \
  -o "$config_file"
```

The selected executables' actual directories and C++ basename are used;
the Ada selector remains `GNAT`. The user's generated `Canonical_Target =
aarch64-linux` is expected even though `Target = aarch64-linux-gnu`.
No compiler alias, source patch, generated-output editing or manual `.cgpr`
creation is needed. GPRconfig success alone is **not** accepted as validation:
the existing preflight checks target, selected compilers, runtime identity and
ELF architecture, target OpenCV metadata/headers/libraries and search-path
isolation. The matching-GNATLS fallback for unresolved `adalib` is unchanged.
The existing compiled/linked probe runs before the production build. All Ada
and C++ warnings and per-unit language-version policies remain unchanged.

`cross_build_core.sh` remains the single production build/recursive install
implementation. Its original `--prepare ABSOLUTE_WORKSPACE` and
`--build ABSOLUTE_WORKSPACE` CLI still works, with installation defaulting to
`WORKSPACE/install`. Optional `OPENCV_CROSS_SOURCE_ROOT` and
`OPENCV_CROSS_INSTALL_PREFIX` select source and installation locations there.
The new entry point defaults to `release`; the legacy wrapper still defaults
to `development`. Both accept `development`, `release`, `validation`.

Existing `OPENCV_CROSS_ADA`, `OPENCV_CROSS_CXX`, `OPENCV_CROSS_GPR_CONFIG`,
`OPENCV_CROSS_GPRBUILD`, `OPENCV_CROSS_GPRINSTALL`, `OPENCV_CROSS_READELF` and
`OPENCV_CROSS_PKG_CONFIG` overrides remain available. The bootstrap also accepts
`OPENCV_CROSS_GPRCONFIG`. An explicit configuration bypasses generation, not
validation. Compiler overrides are resolved to their actual executable paths.
Default pkg-config lookup uses existing target-local `usr/lib/pkgconfig`,
`usr/lib/TARGET/pkgconfig`, `usr/share/pkgconfig`, `lib/pkgconfig`; set
`PKG_CONFIG_LIBDIR` explicitly for other layouts. Host `PKG_CONFIG_PATH` and
compiler search-path contamination are rejected, not silently accepted.
Native project search paths are removed for cross tooling. None of this changes
native Alire configuration or native executable RPATH behavior.

## Installation, retained files and failures

Use a writable fresh temporary prefix for qualification or ordinary testing.
Only writing the requested destination needs destination permissions; building
does not need root. No automatic `sudo` is used. Source/sysroot overlap and
stale build workspaces are rejected. GPRinstall owns conflict handling for an
existing prefix; this is not an atomic prefix replacement or rollback tool.

Recursive GPRinstall installs Core, shim, project imports and metadata. The
workflow verifies these files and inspects the **ELF members** of both archives
with `readelf -h`, rejecting mixed architecture or ELF class:

```text
share/gpr/opencv_core.gpr
share/gpr/opencv_core_shim.gpr
lib/opencv_core/libopencv_core_ada.a
lib/opencv_core_shim/libopencv_core_shim.a
share/gprconfig/aarch64-linux-gnu.cgpr
share/gprconfig/aarch64-linux-gnu-source.txt
share/gprconfig/aarch64-linux-gnu-logs/
```

The durable `.cgpr` is copied only after successful install/artifact validation.
It legitimately references the installed target toolchain/runtime; installed
OpenCV project metadata references the selected SDK sysroot. Keep those inputs
available. The owned temporary build directory is removed on success, after
logs are copied into the prefix. On failure its location is printed and its
configuration/logs/partial build are retained; failing tool statuses propagate.
Only the `mktemp` directory owned by the successful run is removed. Failed
installation may leave a partial prefix, which must be inspected before reuse.

## Independent installed consumer (link only)

After installation, copy `tests/installed_mat_consumer.adb` and
`tests/gnat12/installed_ada.gpr` into a fresh external directory. From there:

```sh
prefix=/usr/local/lib/aarch64-linux-gnu/ada
sysroot=/usr/local/yocto/scarthgap/aarch64
unset ADA_PROJECT_PATH CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH
unset LIBRARY_PATH GCC_EXEC_PREFIX COMPILER_PATH
unset ADA_INCLUDE_PATH ADA_OBJECTS_PATH ADA_PRJ_INCLUDE_FILE ADA_PRJ_OBJECTS_FILE
GPR_PROJECT_PATH="$prefix/share/gpr" \
gprbuild --config="$prefix/share/gprconfig/aarch64-linux-gnu.cgpr" \
  -P installed_ada.gpr -p -v -R \
  -cargs:Ada "--sysroot=$sysroot" \
  -largs "--sysroot=$sysroot" -Wl,-t "-Wl,-rpath-link,$sysroot/usr/lib"
readelf -h -l -d bin/installed_mat_consumer
```

The installed GPRbuild 26.0.0 help was checked: **`-R` means “Do not use run
path option”**. Check `gprbuild --help` on the SDK host too. This prevents
GPRbuild's automatic executable RPATH/RUNPATH; inspect the dynamic section for
any independently injected path. `-rpath-link` is a **link-time** dependency
search path, not an executable deployment run path. The original consumer's
warnings-as-errors policy is preserved. `-Wl,-t` makes the actual installed
archive paths visible in the verbose link log. No target execution is implied.

## One-command vendor qualification

From clean candidate sources, with a **nonexistent** test prefix and no
`OPENCV_CROSS_GPR_CONFIG` override, run:

```sh
sh tests/qualify_cross_install.sh \
  --target aarch64-linux-gnu \
  --toolchain-bin /usr/local/gnat/aarch64-linux-gnu/bin \
  --runtime /usr/local/gnat/aarch64-linux-gnu/lib/gcc/aarch64-linux-gnu/12.3.1/rts-native \
  --sysroot /usr/local/yocto/scarthgap/aarch64 \
  --prefix /tmp/opencv-core-gnat25-qualification \
  --profile release
```

This invokes the new production flow, then builds a fresh external consumer
**after the build workspace has been removed**, using only the installed GPR
path and durable configuration. It checks selected compiler traces, both
installed archive paths, ELF64/little-endian/AArch64, interpreter, OpenCV dynamic
dependency and absence of RPATH/RUNPATH. It retains verbose build/readelf logs
in a printed consumer evidence directory. It never runs the target executable.

### Evidence boundary

At baseline `5aef4d11722aa20b0c8229983afb6d257df5a74f`, the user reported
successful unmodified preflight, production build/recursive install using the
original configuration, and two independent AArch64 consumer cross-links. A
direct GPRconfig selection also passed preflight and linked a consumer, but the
libraries used there were built with the original configuration. Neither
consumer was run. Historical logs remain in the user's container under
`/tmp/opencv-core-debug.nJZ23C/`; they are not newly executed evidence here.

The GNAT Pro 25.0w / GCC 12.3.1 SDK and Scarthgap sysroot are unavailable in the
implementation environment. **Clean production build using automatic
configuration and the complete vendor qualification above remain pending.**
Synthetic Git/archive/bootstrap/failure controls are workflow tests, not vendor
architecture evidence. Native regression tests likewise do not qualify this
proprietary profile. Release/version selection, published-archive verification
and the alire-index PR follow implementation merge and vendor qualification;
an older indexed crate must not be assumed to contain these scripts.

Implementation validation on Linux with Alire GNAT 16.1.0, GPRbuild 26.0.0,
system GNU C++ and native OpenCV 4.10.0:

- 56 cross-configuration/workflow controls, including a `.git`-free archive of
  the implementation inputs and clean exact-commit Git sources;
- 3 module-bridge cross controls, 7 GNAT Pro evidence-parser controls;
- 8 aggregate/language-policy source-unit tests using **GNAT 16**, not GNAT 12;
- native `alr -n build` and `alr -n test`: **2,037 successful AUnit tests**;
- 3 external-shim GPRinstall controls;
- native prefix-only Mat installation/relocation and independent Ada/mixed
  consumers, including execution and ELF dependency checks;
- shell syntax and `git diff --check`.

The host's `gcc-12` lacks `gnat1`, so an initial direct GNAT 12 source-control
attempt was unavailable; GNAT 12 remains covered by its configured CI jobs.
The Debian-12-specific consumer check expects OpenCV `.406` and is not a valid
qualification on this `.410` host; the version-independent Ada/mixed consumer
script passed here. `/tmp` inode exhaustion was avoided by selecting a fresh
`TMPDIR` on the larger filesystem, without deleting unrelated state.