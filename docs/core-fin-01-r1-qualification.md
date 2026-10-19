# CORE-FIN-01-R1 corrective qualification

This is an evidence log, not a release or acceptance declaration. PR #90 stays
open; audit PR #89 is unchanged. Version remains 0.5.1.

## Initial identities and real ARM64 reproduction

Starting main: `64d8a60b59acfe4334045280e430c4774b5cad89`.
Starting feature/PR head: `7f3e72be3941a80e713a1ade06e00cf7c195d13c`.
The initial compatibility run 39146655268 failed on Ubuntu 24.04 ARM64:
2037 executed, 2036 successful, one assertion, no unexpected errors.

Diagnostic commit `bde17d1248238431e8701a769aae845a40cba4ef` was tested on
actual hosted Ubuntu ARM64, run 39151158278, job 117744911508. It independently
calls native OpenCV with the same 2x257 shape, depth, channels and coefficients,
without calling the binding's arithmetic helpers. First mismatch:

```text
OpenCV=4.6.0 arch=aarch64 depth=0 C2 op=5 channel=1 row=0 col=0
actual=1 actual_float64_bits=3ff0000000000000 expected=0
mathematical=0.5 destination=1 native=1
```

This is an incorrect test oracle, not a binding defect: one-element Convert_To
is not interchangeable with arithmetic working-buffer conversion. OpenCV 4.6
`modules/core/src/convert.simd.hpp` uses vector conversion when enough elements
are present, and `saturate_cast` for the scalar tail. At pinned commit
`b0dc474160e389b9c9045da5db49d03ae17c6a6b`,
`modules/core/include/opencv2/core/hal/intrin_neon.hpp:1976-1985` implements
double `v_round` using `vcvtaq_s64_f64` (ties away), whereas
`core/fast_math.hpp:200-218` implements scalar cvRound using lrint (rounding
environment, normally ties even). A one-pixel 0.5 oracle returns 0 while the
native vector path returns 1. No architecture special case or tolerance increase
is needed: compare with independent native arithmetic, including the final
logical pixel, and retain mathematical checks for integral intermediates.

## Integer division policy and ABI review

All integer result depths reject active zero scalar denominators for Divide
and any logical Mat zero denominator for Divide_Into, before output mutation.
Ada owns the public policy. It examines each channel using native comparisons
and an infinity norm, avoiding signed element-count products and honoring ROI
strides. No constant numerator matrix is constructed.

All four pinned sources select CV_64F working depth for scalar multiply/divide
(`arithm.cpp`, scalar muldiv branch). The floating division path can produce
Inf/NaN and then narrow it to integer output. The raw shim therefore repeats
the zero protection for ABI safety, before destination creation/writes. Its
zero mask uses same-row-count reshape (preserving strides), a checked row
flattening bound, and infinity norm rather than overflowing countNonZero.

Retained duplicate conditions and concrete ABI reasons:

* Float16: legacy null arithmetic/comparison dispatch entries.
* columns*channels bound: native signed row-flattening multiplication overflow.
* coefficient finite/int32 bound: legacy cvRound / unsafe integer conversions.
* integer zero denominator: nonfinite working result narrowed to integer.
* temporary output: native header rebind severs callback-scoped capability.

Each has an ABI-safety comment. General empty/rank/channel/alias public policy
is not duplicated for convenience in C++.

## Exact validation baseline isolation

Clean detached worktrees were built at each immutable starting commit using
`alr -n build --profiles=*=validation`, then `alr exec -- ./bin/tests`.
The dependency-sharing setting was disabled locally in each test workspace;
this isolates AUnit build outputs as well as Core and test outputs.
The earlier shared-dependency attempts collided and are not test evidence.

Both builds use GNATLS/GNAT 16.1.0, target x86_64-pc-linux-gnu, its matching
adainclude/adalib runtime, OpenCV 4.10.0. Core and tests use Alire validation:
`-O3 -ffunction-sections -fdata-sections -g -gnatwa -gnatw.X -gnato -gnatVa
-gnatwe -gnata` plus generated style checks and `-gnatW8`; project `-Werror`.

Main: **2025 run, 2017 successful, 0 assertions, 8 unexpected exceptions**.
Original feature: **2037 run, 2028 successful, 0 assertions, 9 unexpected**.
All below are CONSTRAINT_ERROR, `invalid data`; same lines in both builds:

| Registered name | Ada source and line |
| --- | --- |
| Magnitude Phase special classifications | opencv-core-float64_access.adb:96 |
| Polar special classifications | opencv-core-float64_access.adb:96 |
| Mat Float16 Minimum and Maximum special C3 | opencv-core-internal-typed_access.adb:1121 |
| N-D extrema native floating specials | opencv-core-float32_access.adb:137 |
| Sparse non-finite extrema | opencv-core-sparse-typed_impl.adb:30 |
| Sparse one-sided extrema boundaries | opencv-core-sparse-typed_impl.adb:30 |
| UMat Float16 min max special values | opencv-core-internal-typed_access.adb:1121 |
| UMat sqrt special values | opencv-core-float32_access.adb:96 |

Feature-only: Scalar IEEE values, CONSTRAINT_ERROR, invalid data at
opencv-core-internal-typed_access.adb:1148. Suppressing validity checks in the
caller does not suppress checks inside a separately compiled typed getter.
The corrective test transports native IEEE object representations as unsigned
integers through test-only module callbacks, classifies exponent/fraction bits,
and does not catch unexpected exceptions. Both Float32 and Float64 remain
covered. Existing typed-access implementations and all original tests remain
unchanged. No global validity/assertion switch is disabled.

Corrected-source validation rerun (same command, compiler/runtime, OpenCV and
isolated outputs): **2037 run, 2029 successful, 0 assertions, 8 unexpected
exceptions**. The eight names, exceptions and source lines exactly match main;
all twelve scalar registrations pass. Thus this run establishes **zero added
unexpected validation failures**, not an entirely passing validation profile.
Log: `/home/zboll/work/core-fin-01-r1-validation-v3.log`.

Private local logs (not SDK contents):
`/home/zboll/work/core-fin-01-r1-main-validation-isolated.log`,
`/home/zboll/work/core-fin-01-r1-feature-validation-isolated.log`,
`/home/zboll/work/core-fin-01-r1-arm64-diagnostic.log`.

## Remaining gates

The corrected source must still complete validation, final native/version and
actual-shim sanitizer checks, documentation, installed/relocated consumers,
changed-source GNAT Pro 25.2/Scarthgap/QEMU, and final-head hosted CI. Prior
0.5.1 target binaries are not evidence for this change. Hardware is NOT TESTED.
Windows/MSYS2 and MacPorts policy skips are not passes.