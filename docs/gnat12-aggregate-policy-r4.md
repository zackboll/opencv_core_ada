# CORE-EXT-003-R4: retain the qualified per-unit language policy

This change does not qualify full GNAT 12 production or AArch64 builds and
does not modify the independent alignment candidate. Version remains 0.5.0-dev.
Starting source is `f4bd2167ecc0a74162a00c6597772a2a67ea84b0`, merged PR #77.
All predecessor worktrees and their uncommitted research are preserved.

## Narrow correction

Native builds already leave the default language mode unchanged and select
Ada 2022 only for `opencv-core-internal-typed_access.adb`. The cross wrapper
instead forced Ada 2022 globally. This exposed otherwise valid Ada 2012 array
aggregates as obsolete and promoted those warnings to errors.

`scripts/cross_build_core.sh` now retains `-gnatwa -gnatwe` without imposing
a global language mode. `opencv_core.gpr` still supplies `-Werror` and the
typed-access body's local `-gnat2022`. This is NOT a global Ada 2012 override,
warning suppression, assertion removal, or aggregate rewrite.

Corrected Ada source sites: **zero**. Changed generated-policy sites: **one**.
Every production Ada declaration, expression, record aggregate, representation
clause, ABI check, and ownership path is unchanged. No optimized Ada expression
comparison is necessary because no Ada expression changed. No Ada source
formatting is required. Shell syntax and diff checks apply.

## Toolchain and commands

Public Debian 12 environment `localhost/core-ext-003-r2-env:latest`, isolated
container `core-ext-003-r4`. Evidence: `/tmp/core-ext-003-r4-evidence` mounted
as `/evidence`. Compiler identities:

* Native: gcc-12 12.2.0, Debian `12.2.0-14+deb12u1`, x86_64-linux-gnu;
  runtime `/usr/lib/gcc/x86_64-linux-gnu/12`.
* Cross: aarch64-linux-gnu-gcc/g++ 12.2.0, GNAT package `12.2.0-14cross1`;
  runtime `/usr/lib/gcc-cross/aarch64-linux-gnu/12`.
* Comparison: GNAT-FSF-builds 16.1.0, Alire toolchain directory
  `/root/.local/share/alire/toolchains/gnat_native_16.1.0_9f74f58a/bin`.
* Alire-selected GPRbuild 26.0.0 (2026-04-15), distribution directory
  `gprbuild_26.0.1_e3f27f25`. The unrelated system GPRbuild 18 is not used
  as qualification tooling.
* OpenCV native/target 4.6.0+dfsg-12; target SONAME libopencv_core.so.406.

Unchanged scalar sparse generic body independently compiles with default and
`-gnat2012` under `-gnatwa -gnatwe -Werror`, but fails at line 28 under
`-gnat2022`. Keep-going whole-project native and cross Ada compiler exploration:

```sh
alr exec -- gprbuild -k -P opencv_core.gpr --subdirs=r4-native-default \
  --compiler-subst=Ada,gcc-12 -cargs:Ada -gnatwa -gnatwe -Werror
alr exec -- gprbuild -k -P opencv_core.gpr --subdirs=r4-native-2022 \
  --compiler-subst=Ada,gcc-12 -cargs:Ada -gnat2022 -gnatwa -gnatwe -Werror
```

Cross exploration substitutes aarch64-linux-gnu-gcc and uses separate output
directories. It is not claimed as a complete cross build. Both default runs
have **zero aggregate diagnostics**; both explicit Ada 2022 runs have exactly
the same **67 aggregate diagnostics**, retained in native-aggregate-sites.txt
and cross-aggregate-sites.txt. No nonfatal-warning run or suppression is used.

The actual target-configured production attempt uses the merged preflight,
validated `/reference/r2-head/sysroot`, target-only pkg-config metadata and
`/reference/r2-head/target.cgpr`. The preflight passes compiler/runtime identity,
sysroot containment and target runtime/OpenCV ELF validation. Build command:

```sh
gprbuild --config=/reference/r2-head/target.cgpr -k -P opencv_core.gpr -p -v \
  -cargs:Ada --sysroot=/reference/r2-head/sysroot \
  -cargs:C++ --sysroot=/reference/r2-head/sysroot
```

The disposable target configuration matches the corrected wrapper policy.
The verbose log confirms the actual cross GCC and matching --RTS. Target shim
and scalar sparse iterator objects are AArch64 ELF64. This build has zero
aggregate diagnostics but fails other compile-time checks; no AArch64 binary
is executed and no complete target library qualification is claimed.

## Complete captured Ada 2022 warning inventory

Every entry below is an ARRAY aggregate, not a record aggregate. The diagnostic
is `array aggregate using () is an obsolescent syntax, use [] instead [-gnatwj]`.
It becomes fatal with the retained warning policy only when Ada 2022 is forced.
All filenames have prefix `opencv-core-` unless explicitly stated otherwise.

| Unit family | Width 2 / 3 / 4 line numbers |
| --- | --- |
| float16_vecN_row_access.adb | 92 / 105 / 92 |
| float32_vecN_row_access.adb | 57 / 88 / 60 |
| float64_vecN_row_access.adb | 57 / 67 / 60 |
| int16_vecN_row_access.adb | 60 / 60 / 60 |
| int32_vecN_row_access.adb | 57 / 57 / 57 |
| int8_vecN_row_access.adb | 89 / 89 / 89 |
| uint16_vecN_row_access.adb | 60 / 60 / 59 |
| uint8_vecN_row_access.adb | 60 / 87 / 59 |
| sparse-float16_vecN_access.adb | 13 / 14 / 15 |
| sparse-float32_vecN_access.adb | 13 / 14 / 15 |
| sparse-float64_vecN_access.adb | 13 / 14 / 15 |
| sparse-int16_vecN_access.adb | 12 / 14 / 15 |
| sparse-int32_vecN_access.adb | 12 / 14 / 15 |
| sparse-int8_vecN_access.adb | 12 / 14 / 15 |
| sparse-uint16_vecN_access.adb | 12 / 14 / 15 |
| sparse-uint8_vecN_access.adb | 12 / 14 / 15 |

Remaining 19 sites:

* internal sparse-typed_iteration_impl.adb:28 and
  sparse-typed_vector_iteration_impl.adb:28: C_Int32_Array `(others => 0)`.
* sparse.adb:24,243,244,326; sparse.ads:179,180: array initialization/returns,
  including Index_Array defaults inside a record (the defaults are arrays).
* `opencv-core.adb`:2382,2518,3336,5414,5419,9478,9479,9613,9632;
  `opencv-core.ads`:411,412: array initialization/returns/defaults.

Representative original named vector syntax is
`(0 => UInt8_Value (V.Component_0), 1 => UInt8_Value (V.Component_1))`;
ordinary neighboring C record conversions and `(others => 0)` record zero
initializers remain unchanged. The PR #77 tests retain positional/named return
mutation controls. No new nested-array rewrite is proposed.

## Tests and remaining failures

`tests/test_gnat12_language_policy.py` compiles real production contexts in
fresh temporary directories. It verifies original others arrays and named
sparse vector returns fail under forced Ada 2022 and pass under the default
policy. It also preserves neighboring record forms and the local typed-access
Ada 2022 policy. Together with PR #77 tests: seven tests pass on native GNAT 12,
cross GNAT 12 and native GNAT 16. Synthetic cross configuration: 31 tests pass.
The added hosted workflow executes these real Debian 12 compilers; it is
explicitly labeled source-unit coverage, not production build qualification.

Remaining native and target failures include unknown-condition checks in
vector buffer/row access and Mat views, notably Float16 and the shared generic
alignment check. C_API size diagnostics also appear on early failed-unit
paths. Those secondary diagnostics are not independent measured ABI failures.
They are retained, not removed. Complete remaining diagnostics are in
native-default.log and target-build.log. No aggregate failure remains in
these keep-going attempts with the selected per-unit policy.

## Regression disposition

**AGGREGATE_COMPATIBILITY_COMPLETE** for the retained per-unit language policy.
This does not promise warning-free global Ada 2022 compilation; callers that
override the policy globally still expose the documented 67 sites.

GNAT 16 production builds and all 2,025 AUnit tests pass on each OpenCV
4.1/4.6/4.10/5.0 configuration, with zero failed assertions/unexpected errors.
Sparse iterator and typed-vector tests are included in those complete suites.
All three GPRinstall regressions pass. Debian 12 installed Ada and mixed
Ada/C++ consumers pass before and after prefix relocation, including ELF
dependency checks. Evidence logs: aunit41.log, aunit46.log, aunit410.log,
aunit50.log, install.log, consumers.log. Seven source-unit compiler tests pass
on each of native GNAT 12, cross GNAT 12, and GNAT 16 (final-compiler-tests.log).
The final main reconciliation finds no advancement beyond the starting SHA.
No macOS/Windows local execution is claimed; existing workflows are unchanged.

No GNAT12_NATIVE_QUALIFIED, GNAT12_AARCH64_CROSS_BUILD_QUALIFIED,
or GNAT12_ALIGNMENT_QUALIFIED claim follows from this narrow task.

No public semantic validation is duplicated in the C++ shim; it is untouched.