# CORE-FIN-01-R3: Scarthgap AArch64 target sanitizers

## Scope and disposition boundary

The remaining sanitizer execution blocker is resolved by **full-system**
AArch64 emulation with a real guest kernel, not by disabling LeakSanitizer.
The complete actual-shim ASan/UBSan/LSan run exits **0**, and independent
memory-error, leak and undefined-behavior controls demonstrate active detection.
This is emulated target qualification; **hardware remains NOT TESTED**.
Final `TARGET_ASAN_QUALIFIED` disposition also requires completed, applicable
hosted CI on the final documentation commit. Exact final commit/tree and CI
conclusions are reconciled in existing PR #90 after those checks finish.

Starting feature/PR head: `b3c07bf4296029f1a8346f95f9df893172cf7405`, Git tree
`c86c4e84d4c63df44356324a230cb4fddc59d439`. Refreshed main remains
`64d8a60b59acfe4334045280e430c4774b5cad89`. Version **0.5.1**, public Ada API,
C ABI, production Ada/C++, numerical/zero-denominator and destination/alias
contracts, and all **2,037** AUnit registrations are unchanged. Audit PR #89
is untouched. No merge, waiver, release, tag or Alire submission is authorized.

R1/R2 evidence is retained unchanged. This report supersedes their unresolved
target-ASan disposition, not their historical observations. It does not claim
that the previously failing user-mode runs passed retrospectively.

## Previously established failures and the new diagnostic

| Execution environment | Observation | Exit / classification |
| --- | --- | --- |
| QEMU user 6.2.0 | `asan_poisoning.cpp:38 AddrIsInMem(addr)` CHECK, empty stack, before application entry; allocation-only and actual-shim controls reproduce | 1; original environment failure |
| QEMU user 8.2.2 | Application and probe assertions execute, then LSan fails during thread/stack inspection: `LeakSanitizer has encountered a fatal error`, ptrace hint; allocation-only control reproduces | 1; partial execution, not qualified |
| QEMU user 8.2.2, fresh R3 shim, leaks enabled | `PASS scalar shim ABI safety 4.9.0`, then the same LSan fatal error | 1; complete requested gate fails here |
| QEMU user 8.2.2, fresh R3 shim, leaks disabled **only for diagnosis** | All assertions execute without ASan/UBSan report | 0; **TARGET_SCARTHGAP_ASAN_NONLEAK_DIAGNOSTIC_PASS**, not complete qualification |

Normal options for the leak-enabled user diagnostic and full-system campaign:

```sh
export ASAN_OPTIONS=detect_leaks=1:halt_on_error=1
export UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1
unset LSAN_OPTIONS LD_LIBRARY_PATH LD_PRELOAD
```

The second user-mode diagnostic changes only
`ASAN_OPTIONS=detect_leaks=0:halt_on_error=1`. Its success is never used as the
complete gate. Exact commands are retained in `core-fin-01-r3-user.sh` and
`logs/user-campaign.log`. Both user-mode binaries use the target interpreter
`/lib/ld-linux-aarch64.so.1`, resolved through `qemu -L "$SYSROOT"`; no host
target-library substitution occurs.

## Complete environment selection

**Native private AArch64:** no configured/authorized private native host was
identified. The repository runner inventory contains zero self-hosted runners;
the existing private workspace documents no connected target hardware. Public
hosted ARM64 runners were not used to upload or execute proprietary SDK inputs.
This is not a claim that no such host exists anywhere.

**Full-system:** local assets proved sufficient. The preserved workspace has
the pinned Yocto Linux source, cached BusyBox/build-tool archives and an
SDK-built QEMU system emulator. No downloads were needed. A disposable kernel
and initramfs were built under a fresh evidence directory, without writing to
the compiler installation or target sysroot. The sysroot alone was **not**
assumed bootable. A statically linked BusyBox supplies init/shell/mount/poweroff;
the test executables use the actual Scarthgap dynamic loader and libraries.

The concrete hypothesis was that a real guest kernel implements the process,
thread, `/proc` and ptrace facilities required by LSan, unlike the tested
user-mode emulation. Successful leak detection in the full-system guest
supports that hypothesis. No further emulator-version guessing or sanitizer
runtime replacement was needed. Dynamic ASan linkage was therefore not pursued.

| Component | Exact identity |
| --- | --- |
| System emulator | SDK `qemu-system-aarch64`, **8.2.1**, TCG, `virt`, Cortex-A57, 2 CPUs, 2 GiB RAM |
| Kernel | Yocto Linux **6.6.23**, pinned commit `2d01bc1d4eeade12518371139dd24a21438f523c` from the Scarthgap recipe |
| Guest helper | BusyBox **1.36.1**, locally cross-built static helper |
| Host execution | rootless Podman, UID/GID 1000, network **none** |
| Guest network | no NIC (`-nic none`); kernel `CONFIG_NET` disabled |
| Target compiler | supplied GNAT Pro **25.2**, GCC **13.3.1 20240927**, build **20250603**, target `aarch64-linux-gnu` |
| Ada runtime provenance | fresh compiler-generated `V "GNAT Lib v25"`, matching supplied runtime ALIs |
| Target userspace | preserved Scarthgap **5.0**, glibc/loader **2.39** |
| Native OpenCV | target **4.9.0**, `libopencv_core.so.409` |
| Sanitizer runtimes | supplied compiler's static `libasan.a` and `libubsan.a`, same as R2 |

The guest kernel was built from `defconfig`, disabling unneeded network,
module, graphics/audio and virtualization features and enabling procfs,
sysfs, devtmpfs, initramfs, tmpfs and multiple users. Cross-memory access,
48-bit virtual addressing and normal process tracing remain available.
The empty system certificate trust-store feature was disabled because this
offline test kernel uses neither signed modules nor executable verification;
no sanitizer assertion or check is affected. Complete `.config` is retained.

Host-tool assembly initially encountered missing m4/ed/OpenSSL headers; logs
are preserved, not called successful attempts. Cached SDK m4/flex, locally
built Bison 3.8.2 and GNU bc's bootstrap calculator resolved build prerequisites.
The final kernel build completed successfully. Stock BusyBox/kernel-helper
build warnings are retained separately and are **not** Core build/sanitizer
warnings. Core and all throwaway control compilations use `-Werror` and have
no compiler warnings. No broad warning suppression was introduced into Core.

## Fresh production-source build and exact dependency closure

The actual probe is freshly built from a clean clone of PR #90, not an old
0.5.1 target binary. It directly includes `cpp/opencv_core_shim.cpp`, invokes
real C ABI functions and target OpenCV, and retains every focused assertion.
The initial successful source SHA is the starting head above. The final-head
documentation commit changes no production or probe input; final-head rebuild
and execution identities are recorded separately in PR #90.

Common compiler command (the supplied absolute driver is explicit):

```sh
"$TARGET_CXX" --sysroot="$SYSROOT" -std=c++17 -O1 -g \
  -Wall -Wextra -Wpedantic -Werror \
  -fsanitize=address,undefined -static-libasan -static-libubsan \
  -fno-omit-frame-pointer -I"$SYSROOT/usr/include/opencv4" \
  "$CORE_ROOT/tests/probes/scalar_modes_shim_probe.cpp" \
  -L"$SYSROOT/usr/lib" -lopencv_core -o "$EVIDENCE/bin/shim"
```

Controls use the same driver/sysroot/options without OpenCV when not needed.
All are ELF64 little-endian **AArch64 EXEC**, interpreter
`/lib/ld-linux-aarch64.so.1`. The shim imports OpenCV .409, libstdc++, libm,
librt, libpthread, libgcc_s and libc. The interpreter and recursively required
libraries are copied **byte-for-byte** into the disposable guest, not rebuilt
or installed back into the sysroot. The explicit dependency resolver checks
ELF architecture, target-root search paths and symbol-version satisfaction.
It verifies **62** version requirements for the actual-shim closure; standalone
controls each verify 32. The target OpenCV's documented `/usr/lib` RPATH is
target-root, never host `/usr/lib`. The executable has no RPATH/RUNPATH.

In-guest `ld.so --list` confirms every dependency under guest `/lib`.
In-guest SHA-256 output matches the copied payload and original target-library
hashes. Sanitizer code is statically linked from the supplied archives; no host
ASan/UBSan DSO is loaded. Symbols include `__asan_init`,
`__ubsan_handle_add_overflow` and `__lsan_do_leak_check`. Runtime behavior is
verified by fault controls, not merely by the presence of symbols.
Target OpenCV itself is not claimed to be sanitizer-compiled.

Selected SHA-256 provenance:

| Input | SHA-256 |
| --- | --- |
| Supplied C++ driver | `eafef42da4df0326dd4ba58f662e5c664624a6b099bcc1370ecee2234e425ea0` |
| Supplied libasan.a | `04fe4d60ba250c62146ce9e0ea0b71c0318ab559b5627bda6ffc33ed91775cfa` |
| Supplied libubsan.a | `eb31b81d0e42bd82c6c2071c52ab76629ce452f7d089db61a95b2b9a7b07cb96` |
| Target libc.so.6 | `89532c6455d2c3b894a61adbbadd46eb4601401784c57b9c9cf03392b5a58cde` |
| Target loader | `3862b9deb0aa7d59bbf13971da6e5d626ac031ec73c33db53f17257dada95a8a` |
| Target OpenCV 4.9.0 | `7601b57881fb39e36bde08f09d439a888d6b11e94cb726a9cd5c30158d58aee0` |
| System QEMU 8.2.1 | `bf4b11d3264f6c0c47691a4506bef9c53587a6f317fe886022d698171c2dc641` |
| Guest Linux Image | `aef66f599173196c0ad6f8efc7aef757992313ec7a7c5b2d5268d92c6a8def33` |
| Guest kernel config | `85abbd001c6e85fb42449443da40444ad669c097c42855b70eaa50facdbdf91f` |
| Fresh actual-shim executable | `e1f4069ef31ff08aceb93746dbc1a4e2b665b3ab90f776b99eed0e68344b3c35` |
| Confirmation initramfs | `cf9406969acdf9aab7b588178ebf7a5d79802c8814f4f7e129f5ab56ed78aada` |
| Confirmation serial log | `868613f0f6fcbc41c40efa0e830b7631075c36f15f49a5e5898c84c9e8d7c633` |

## Actual complete execution and positive detection controls

Two independent full-system boots completed, QEMU exit **0** and normal guest
poweroff. The second includes an extra UBSan fault control and payload hashes.
All tests run with **leaks enabled**, the exact normal options above, no
LSan options/suppressions and no LD_PRELOAD/library override.

| Program | Required/observed behavior | Observed exit |
| --- | --- | --- |
| Clean allocation | new[8], volatile access at index 7, delete[]; application marker; no finding | **0** |
| Deliberate memory error | separate disposable new[8], non-inlined write at index 8; `AddressSanitizer: heap-buffer-overflow` | **1**, expected |
| Deliberate leak | separate disposable malloc(12345), touched and deliberately lost; `LeakSanitizer: detected memory leaks`, exactly 12,345 bytes | **1**, expected |
| Deliberate undefined behavior | separate disposable volatile INT_MAX + argc; UBSan signed-integer-overflow diagnostic and stack | **1**, expected |
| Actual Core shim | `PASS scalar shim ABI safety 4.9.0`; every assertion retained; no ASan/UBSan/LSan warning or finding | **0** |

Expected reports are confined to the disposable fault controls. The clean and
actual-shim sections are checked separately for unexpected diagnostics. LSan
shutdown completes normally for both. Positive ASan and LSan controls also
run with fatal options, proving real detection rather than ignored reports.
The additional UBSan control proves its instrumentation can execute and stop.
No unsafe test code was added to the library or AUnit suite.

Exact boot command (all inputs are explicit, no host-global emulator change):

```sh
timeout 240 "$QEMU_SYSTEM_AARCH64" \
  -machine virt -cpu cortex-a57 -accel tcg -m 2048 -smp 2 \
  -nographic -monitor none -nic none \
  -kernel "$EVIDENCE/Image" -initrd "$EVIDENCE/initramfs-confirm.cpio.gz" \
  -append 'console=ttyAMA0 rdinit=/init panic=-1'
```

The guest init mounts proc/sys/dev and records kernel, options, payload hashes
and loader resolution. It executes each `/tests/<name>` directly, records
`TEST_EXIT <name> <status>`, and powers off. The verifier checks every status,
expected control report, absence of unexpected clean/shim reports, payload
hashes and guest/QEMU completion. Independent verification summary:

```text
clean=0 memory_error=1 leak=1 undefined=1 actual_shim=0 qemu_exit=0
leak_detection=true hardware=NOT TESTED
TARGET_SCARTHGAP_ASAN_UBSAN_LSAN_PASS
```

This establishes the focused actual-shim gate in the assembled Scarthgap
target environment. It does not prove all Core paths memory-safe, instrument
every OpenCV library, or establish hardware qualification.

## Evidence retention and final review

Private evidence root:
`/home/zboll/work/opencv-geometry-scarthgap/evidence/core-fin-01-r3/`.
The corresponding `logs/core-fin-01-r3-*` coordinator logs and all R1/R2 data
remain preserved. Important files under the new evidence root:

* `logs/user-campaign.log`, `user-shim-leaks-{1,0}.exit` and matching logs.
* `logs/guest-build.log`, `logs/kernel-*.log`, `kernel.config`, kernel release.
* `logs/target-closure.json`, `logs/shim-compiler-abi.json`, ELF/symbol reports.
* `logs/full-system-console.log`, `full-system-qemu.exit` (first boot).
* `logs/full-system-confirm-console.log`, `full-system-confirm-qemu.exit`.
* `logs/guest-payload-hashes.txt`, `logs/verified-summary.json`.
* Exact orchestration/control sources are sibling `core-fin-01-r3-*.sh`,
  `.cpp` and `.py` files; complete compiler/link/boot commands are traced.

No SDK, compiler archive, runtime binary, guest image or proprietary sysroot
contents are uploaded. This public report publishes commands, identities and
results only. The guest is disposable; the protected toolchain and sysroot
remain unchanged. Native x86_64/ARM64 sanitizer qualification and existing
2037/2037 functional/target qualification remain separate evidence.

The eight independently established nonfinite validation-profile exceptions
remain a baseline issue, with **zero additional feature failures**; there is
no claim of a fully passing validation profile. Windows/MSYS2 and MacPorts
policy skips remain skips. R3 requires no residual target-sanitizer waiver:
the complete focused gate now executes successfully, subject to final-head CI
and identity reconciliation. Stop at independent review; do not merge PR #90.