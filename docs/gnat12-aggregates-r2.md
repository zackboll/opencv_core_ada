# CORE-EXT-003-R2: narrow Ada 2022 aggregate cleanup

Dispositions: **AGGREGATE_COMPATIBILITY_QUALIFIED** for the identified
typed-access context; **GNAT12_ALIGNMENT_PENDING**. This is not complete
GNAT 12 production support, cross-build qualification, or Yocto qualification.

Baseline: `9380a832aaafd92ca4aacadb253d55dd33b5680c`, merged PR #76.
Version remains `0.5.0-dev`. Existing R1 research in the separate
`core-ext-003` worktree and `/tmp/core-ext-003-evidence/r1` was not changed.
R2 evidence is retained under `/tmp/core-ext-003-r2-evidence` and the
`core-ext-003-r2` Debian 12 container's `/qualification` directory.

## Scope and source classification

The only production Ada source changed is
`src/internal/opencv-core-internal-typed_access.adb`: 48 vector-return array
aggregates (32 positional, 16 named), in the 2-D and N-D getters of the eight
depth families at widths 2/3/4. Each public vector is an array instantiated
from `OpenCV.Core.Vectors`, not a C record. Only the outer aggregate delimiters
change; scalar conversions, function calls, named indices, order and values
are unchanged. No affected aggregate is multidimensional, nested or qualified.

Examples:

```ada
--  Before / after, positional:
return (UInt8_Value (V.Component_0), UInt8_Value (V.Component_1));
return [UInt8_Value (V.Component_0), UInt8_Value (V.Component_1)];
--  Before / after, named:
return (0 => Float64_Value (V.Component_0),
        1 => Float64_Value (V.Component_1),
        2 => Float64_Value (V.Component_2));
return [0 => Float64_Value (V.Component_0),
        1 => Float64_Value (V.Component_1),
        2 => Float64_Value (V.Component_2)];
```

The C record initializers in the setters and their calls remain parenthesized.
No public Ada declaration, C header, C++ implementation or Compile_Time_Error
check changes. `opencv_core.gpr` explicitly selects `-gnat2022` **only for this
body**, retaining generated compiler switches and `-Werror`. Native Alire
configuration previously did not select Ada 2022. Selecting it project-wide
exposes unrelated obsolete aggregates, so no global change is made here.

Original warning sites, unchanged line numbers:

```text
27 71 115 159 268 318 368 418 468 518 567 613 660 708 755 803
848 894 2373 2429 2485 2542 2598 2658 2716 2764 2844 2888
2966 3014 3095 3145 3226 3270 3347 3395 3475 3525 3616 3659
3703 3749 3795 3845 4000 4043 4119 4169
```

There are **48 distinct sites and 48 occurrences per baseline compilation**,
not repeated diagnostics from fewer sites. Both native and cross GNAT 12
reproductions emitted 48 warnings followed by 21 secondary C_API diagnostics.
Exact warning form:

```text
opencv-core-internal-typed_access.adb:27:14: warning: array aggregate using () is an obsolescent syntax, use [] instead [-gnatwj]
```

## GNAT 12 evidence

Public Debian 12 native GCC/GNAT 12.2.0 package `12.2.0-14+deb12u1`, target
`x86_64-linux-gnu`, runtime `/usr/lib/gcc/x86_64-linux-gnu/12`.
Cross GCC/GNAT 12.2.0 package `12.2.0-14cross1`, target `aarch64-linux-gnu`,
runtime `/usr/lib/gcc-cross/aarch64-linux-gnu/12`.
GPRbuild used for build exploration reports 26.0.0 (2026-04-15).
OpenCV Core native/target packages: `4.6.0+dfsg-12`.

The complete corrected typed-access translation unit compiles natively and
cross with `-gnat2022 -gnatwa -gnatwe -Werror`, zero warnings and zero C_API
size-mismatch diagnostics. Cross command (run in an empty output directory):

```sh
aarch64-linux-gnu-gcc -c -gnatA \
  --RTS=/usr/lib/gcc-cross/aarch64-linux-gnu/12 \
  -gnat2022 -gnatwa -gnatwe -Werror \
  --sysroot=/evidence/unchanged-cross/sysroot -fPIC -gnatR3 \
  -I/r2/src -I/r2/src/internal \
  /r2/src/internal/opencv-core-internal-typed_access.adb
```

Native equivalent uses `gcc-12`, omits the cross runtime/sysroot, and retains
the language and fatal-warning switches. Before commands use unchanged
`/evidence/baseline/src` instead of `/r2/src`. Separate directories prevent
native/cross/GNAT16 ALI reuse.

The unchanged full C_API body plus actual-type R1 layout tables and authoritative
C-header oracle were recompiled for AArch64. The independent comparator passes
all 26 records: size, Object_Size, object size, alignment, field positions and
array stride. All eight comparator mutations remain rejected. No target binary
was run on the host. R1 research probes were read-only inputs, not copied into
this narrow PR.

### Remaining blockers: do not overstate the result

Whole-library direct native/cross GPRbuild with Ada 2022 and fatal warnings
now gets beyond the corrected typed-access body and fails at:

```text
opencv-core-sparse-typed_vector_iteration_impl.adb:28:60:
warning: array aggregate using () is an obsolescent syntax, use [] instead [-gnatwj]
```

That separate earlier error can again trigger the same 21 secondary C_API
messages. Therefore this cleanup resolves the **identified typed-access
diagnostic family**, not all possible secondary C_API messages throughout the
library. Other Ada 2022 aggregates in sparse, row-access and Core units remain
separate work; a project-wide cleanup was not retained.

Independent native/cross compilation of the actual Float64 Vec4 view still
fails with warnings-as-errors retained:

```text
opencv-core-float64_vec4_mat_view.adb:11:56: error: condition is not known at compile time
opencv-core-float64_vec4_mat_view.adb:17:04: error: instantiation error at opencv-core-internal-typed_external_mat_view.adb:28
opencv-core-float64_vec4_mat_view.adb:17:04: error: condition is not known at compile time
```

This is the established GNAT 12 alignment-evaluation limitation, not a corrected
ABI condition. Its assertions are unchanged. No full GNAT 12 build passes.

## Negative-first compiler regression

`tests/test_gnat12_aggregates.py` compiles the full actual production body in
fresh temporary directories. Before the source correction the positive test
failed. After correction it passes. Separate mutations restore one actual
positional return and one actual named return to their original syntax;
both fail with the `-gnatwj` diagnostic. The fixture is disposable and production
source never changes. A preservation test checks representative record
initializers and function calls remain parenthesized.

All three tests pass under each of native GNAT 12, cross GNAT 12, and native
GNAT 16:

```sh
ADA_COMPILER=gcc-12 python3 -m unittest discover -s tests -p test_gnat12_aggregates.py -v
ADA_COMPILER=aarch64-linux-gnu-gcc python3 -m unittest discover -s tests -p test_gnat12_aggregates.py -v
ADA_COMPILER=/path/to/gnat16/bin/gcc python3 -m unittest discover -s tests -p test_gnat12_aggregates.py -v
```

## GNAT 16 regression evidence

Compiler: `gcc (GNAT-FSF-builds) 16.1.0`.

* Complete production native build passes.
* Full AUnit: **2,025 / 2,025** on each Linux OpenCV 4.1, 4.6, 4.10 and 5.0
  compatibility image, with zero failed assertions/unexpected errors.
* GPRinstall regression: 3 / 3 passes.
* Debian 12 installed Ada and mixed Ada/C++ consumers pass before and after
  moving the installation prefix; ELF dependency and resolution checks pass.
* GNAT 16 `-gnat2022 -O2 -S` output for the complete typed-access body is
  **byte-identical** before/after the 48 delimiter rewrites.
* GNATformat and diff checks pass for the changed Ada body.

An initial run in the reused exploratory build directory produced eight
floating-special validity-check errors after mixed build-profile activity.
A forced rebuild passed all 2,025 tests, and a fresh source/output checkout
independently passed the full suite. The stale exploratory result is not used
as regression evidence. macOS/Windows execution is delegated to existing CI;
no local execution claim is made. Existing CI remains intact; no GNAT 12
production badge or successful placeholder job is introduced.

No public semantic validation is duplicated in the C++ shim by this change;
the shim is untouched. No manifest dependency/version or five-guide inventory
change. Stop at independent review; no merge/tag/release.