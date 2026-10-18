# CORE-FIN-01-R2 sanitizer qualification boundary

## Scope and immutable baseline

PR #90, branch `feature/core-fin-01-scalar-modes`; no replacement PR, merge,
release, tag or publication. Version remains 0.5.1. Starting feature commit
`82c7d33e32574fdd8e77d9fa2abd8d0802dd778f`, tree
`229f86ae14c017f84f793192ef63fde7596fed7b`; refreshed main
`64d8a60b59acfe4334045280e430c4774b5cad89`. Audit PR #89 remains untouched.

R2 changes only this evidence report and the existing Ubuntu ARM64 CI job.
Production Ada, production C++ shim, ABI, public API, native probes, assertions,
2,025 original plus twelve scalar AUnit registrations and documentation of
numerical/zero-denominator policy are unchanged. Baseline production and target
qualification therefore remain evidence for these identical source inputs;
final-head hosted checks still have to complete on the new Git commit.

## Native ARM64 actual-shim instrumentation

The existing `ubuntu-24.04-arm` job now runs
`sh -x scripts/run_scalar_modes_probes.sh` using `/usr/bin/g++` and the system
ARM64 OpenCV development library. The script is unchanged. It compiles
`tests/probes/scalar_modes_shim_probe.cpp`, which directly includes
`cpp/opencv_core_shim.cpp`, with:

```text
-std=c++17 -O1 -g -Wall -Wextra -Wpedantic -Werror
-fsanitize=address,undefined -fno-omit-frame-pointer
```

The focused assertions invoke actual shim entry points and actual OpenCV calls,
including failure containment, integer zero/preflight safety, strided final
pixel/channel checks, default output, null/selector/output initialization,
unsafe scalar conversion, temporary-output and legacy Float16 protection.
This is not a mock shim or a claim that system OpenCV is sanitizer-compiled.

The job requires host `uname -m = aarch64`, AArch64 ELF, imported ASan/UBSan
instrumentation symbols, resolved sanitizer libraries, and native dynamic-loader
initialization of both runtimes. It records exact commit/tree, compiler/package
versions, OpenCV, ELF/dependencies, runtime options, full compiler/link commands
and complete probe output. Evidence is retained even on failure via the
`native-arm64-scalar-sanitizers-<run-id>` artifact.

Runtime policy is explicit and fatal, with no sanitizer-error suppression:

```text
ASAN_OPTIONS=detect_leaks=1:halt_on_error=1
UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1
```

The ordinary execution must pass before a second native loader-traced run.
No emulator is invoked. Leak detection is not disabled. The new job result and
final commit/tree must be read from the final PR head and recorded in PR #90;
adding this step by itself is **not** evidence of a native ARM64 sanitizer pass.

## Independent Scarthgap failure reproduction

Preserved rootless qualification container, UID/GID 1000, network `none`.
No compiler installation, sysroot, SDK library or host-global emulator changed.
Fresh R2 allocation-only and actual-shim programs use the same compile/link
options, sanitizer archives, Scarthgap sysroot, dependency search paths and
QEMU. The shim source is identical to the R1 qualified source. An application
entry marker in the allocation program and application constructor marker in
the shim wrapper establish whether application logic was reached.

| Input | Measured identity |
| --- | --- |
| Target compiler | GNAT Pro 25.2 C++, GCC 13.3.1 20240927, build 20250603 |
| Compiler target | aarch64-linux-gnu |
| libasan | supplied compiler `aarch64-linux-gnu/lib64/libasan.a`, shared counterpart libasan.so.8.0.0 |
| libubsan | same supplied family, libubsan.a / libubsan.so.1.0.0 |
| glibc and target loader | GNU libc 2.39, ld-linux-aarch64.so.1 |
| Sysroot | preserved Scarthgap 5.0 qemuarm64 eSDK-derived sysroot |
| OpenCV | preserved target 4.9.0, libopencv_core.so.409 |
| Original emulator | qemu-aarch64 6.2.0, Ubuntu package 1:6.2+dfsg-2ubuntu6.31 |
| Both ELF types | ELF64 little-endian AArch64, EXEC, target interpreter |
| Sanitizer linkage | static libasan and libubsan, not host sanitizer DSOs |

Exact common compiler options:

```text
--sysroot=<preserved-qemuarm64-sysroot> -std=c++17 -O1 -g
-Wall -Wextra -Wpedantic -Werror -fsanitize=address,undefined
-static-libasan -static-libubsan -fno-omit-frame-pointer
-I<sysroot>/usr/include/opencv4 -L<sysroot>/usr/lib -lopencv_core
```

The allocation source has only stdio, new[], a volatile integer access and
delete[]; it does not include or call OpenCV or the shim. Matching link options
retain the same OpenCV dependency for this additional control. The original R1
allocation-only program without that dependency also fails identically.
Both R2 binaries resolve the same dependency list under `qemu -L <sysroot>`:
libopencv_core.so.409, libstdc++.so.6, libm.so.6, librt.so.1, libpthread.so.0,
libgcc_s.so.1, libc.so.6 and the target loader. Neither has RPATH/RUNPATH;
LD_LIBRARY_PATH and LD_PRELOAD are unset. The loader resolution was captured
independently using its `--list` option.

Both reproduce with ASAN_OPTIONS/UBSAN_OPTIONS **unset** (defaults), exit **1**:

```text
AddressSanitizer: CHECK failed: asan_poisoning.cpp:38
"((AddrIsInMem(addr))) != (0)" (0x0, 0x0)
    <empty stack>
```

No application marker or probe success appears. Historical
`ASAN_OPTIONS=detect_leaks=0:verbosity=1` also reproduces exit 1 for both; it
shows interceptor/shadow initialization before the CHECK. It is a diagnostic
comparison, **not** a successful run or a qualification setting. This supports
a QEMU/runtime environment incompatibility independently of Core. It does
**not** prove that Core has no memory-safety defects.

Selected measured SHA-256 identities (no proprietary binaries published):

| Input | SHA-256 |
| --- | --- |
| C++ compiler | eafef42da4df0326dd4ba58f662e5c664624a6b099bcc1370ecee2234e425ea0 |
| libasan.a | 04fe4d60ba250c62146ce9e0ea0b71c0318ab559b5627bda6ffc33ed91775cfa |
| libubsan.a | eb31b81d0e42bd82c6c2071c52ab76629ce452f7d089db61a95b2b9a7b07cb96 |

## Bounded alternative: isolated QEMU 8.2.2

Public Ubuntu 24.04 qemu-user-static package 1:8.2.2+ds-0ubuntu1.18 was
installed only in a disposable tools container. Its statically linked host
emulator was copied into the evidence directory; no host-global emulator was
installed or replaced, and the protected container stayed offline. Emulator
SHA-256: `e4f8d99e9ff69c3cefffab71cee358ce2af1ecba1282d04c3eeb44ef76f5a71e`.

With the same binaries/sysroot and sanitizer options **unset**, QEMU 8.2.2
passes startup and reaches the allocation and actual-shim application markers
and their success messages. The original R1 actual-shim binary likewise prints
`PASS scalar shim ABI safety 4.9.0`. All then exit **1** with:

```text
LeakSanitizer has encountered a fatal error.
HINT: LeakSanitizer does not work under ptrace (strace, gdb, etc)
```

This narrows the old startup failure to the emulation/runtime environment, but
does not establish an end-to-end target ASan pass: LeakSanitizer cannot complete
under this tested user emulator. No assertion was disabled; no leak-disable
retry is promoted to qualification. Further emulator-internal investigation is
out of scope for this bounded campaign.

## Qualification boundary and independent decision

Keep these statements separate:

* **NATIVE_X86_64_ASAN_PASS**: R1 actual shim and instrumented OpenCV versions
  4.1.0/4.6.0/4.10.0/5.0.0 passed; production/probe sources unchanged. R2 local
  OpenCV 4.10 ASan/UBSan run also passes with leak detection enabled.
* **NATIVE_ARM64_ASAN_PASS**: requires the newly added hosted final-head step;
  do not infer it from prior AUnit or QEMU execution.
* **TARGET_SCARTHGAP_UBSAN_PASS**: R1 actual-shim UBSan exit 0; unchanged inputs.
* **TARGET_SCARTHGAP_ASAN_PASS**: **not established**.
* **TARGET_SCARTHGAP_ASAN_ENVIRONMENT_BLOCKED**:
  **TARGET_SCARTHGAP_ASAN_NOT_EXECUTABLE** as a complete leak-enabled sanitizer
  qualification in the preserved/tested environment. Neither PASS nor
  SKIPPED_BY_POLICY; QEMU 8's partial execution is reported separately above.

R1 changed-source GNAT Pro 25.2/Scarthgap qualification remains: complete AUnit
2037/2037 and instrumented suite 2037/2037, ABI/provenance/target dependency
checks, O0/O2 safety controls and independent installed/relocated Ada and mixed
consumers, all exit 0. Actual hardware remains **NOT TESTED**.

Validation limitation is unchanged: immutable main has eight independently
reproduced nonfinite Constraint_Error failures; corrected feature has exactly
the same eight, zero additional failures (2037 executed, 2029 successful).
This is **not** a 100% validation-profile pass. See the R1 qualification report
for each registered name and Ada source line. Windows/MSYS2 and MacPorts
workflow policy skips remain skips, not passes.

**Explicit independent release-gate acceptance is requested** for the residual
Scarthgap target ASan limitation. Native ARM64 sanitizer coverage does not
automatically replace a mandatory target gate. No waiver is approved here.
Any review-ready disposition is for independent review only, not release
acceptance or permission to merge.

## Preserved reproduction evidence

Private protected workspace, not uploaded wholesale:

* `evidence/core-fin-01-r2-reproduce.sh`: exact matched compile/run commands.
* `evidence/core-fin-01-r2-allocation.cpp` and `core-fin-01-r2-shim.cpp`.
* `evidence/core-fin-01-r2-reproduction/campaign.log`: versions, runtime hashes,
  compiler/link commands, complete diagnostics and individual exit records.
* Same directory: each ELF report, loader resolution and default/verbose log.
* `logs/core-fin-01-r2-qemu8-{allocation,shim,original-shim}.log`.
* Original `logs/core-fin-01-r1-*` evidence is retained unchanged.

Final hosted run/job URLs, exact commit/tree and measured native ARM64 package
versions are recorded in PR #90 after the final-head jobs finish. This report
does not self-certify results from jobs that have not executed.