# Task 052 — reusable unary math destination source findings

The starting-gate and preliminary observations below are retained. Final
production dispositions and qualification requirements are recorded at the end.

## Starting gate

- Fetched `origin`; actual `origin/main` matches the requested starting SHA:
  `663c3fff3e8b5681af3a9fe3284af753b32b60ad`.
- No open pull requests were returned by `gh pr list --state open`.
- Primary checkout was clean on `corrective/windows-external-shim-install`.
  Work is isolated at `/tmp/task052-core`, on
  `feature/052-unary-math-destination`, based on the exact main SHA above.
- Read the six repository rule files, library/test manifests, and GPR files.
- Full host baseline, including a second run using the concise counting runner:
  1901 registered, 1901 executed, 1901 passed, zero failed assertions, zero
  unexpected errors. Logs: `/tmp/task052-baseline.log` and
  `/tmp/task052-baseline-counted.log`.
- Host OpenCV is 4.10.0. The ordinary run emitted AMD OpenCL compilation
  diagnostics concerning a missing Clang OpenCL header; the suite passed.
  No GPU execution is claimed.
- Release refs recorded before work: `0.4.1` tag object
  `ee6c92eefd4543845a17f42b174335c13dcbcfe2`; remote release branch
  `15df9376f441c2fbe63a4416788bf49eb415673e`.

## Exact source identities

All four peeled remote tags were reconfirmed with `git ls-remote`. Local
checkouts also had these HEADs and clean tracked/untracked status:

| Tag | Peeled commit | Local source checkout |
| --- | --- | --- |
| 4.1.0 | `371bba8f54560b374fbcd47e7e02f015ac4969ad` | `/tmp/imgproc046-upstream-4.1.0` |
| 4.6.0 | `b0dc474160e389b9c9045da5db49d03ae17c6a6b` | `/tmp/task052-upstream-4.6.0` |
| 4.10.0 | `71d3237a093b60a27601c20e9ee6c3e52154e8b1` | `/tmp/imgproc046-upstream-4.10.0` |
| 5.0.0 | `40738fb16ceddb5fb3fea747585f7ce6abb0605b` | `/tmp/imgproc046-upstream-5.0.0` |

Paths below are relative to `modules/core/src`. The initial function locations
were followed by the four-version implementation review summarized below.

| Version | Exp / Log | Pow / Sqrt | Pow cases 0 / 1 / 2 |
| --- | --- | --- | --- |
| 4.1.0 | `mathfuncs.cpp:663 / 696` | `1209 / 1367` | `1228 / 1232 / 1235` |
| 4.6.0 | `mathfuncs.cpp:670 / 703` | `1216 / 1374` | `1235 / 1239 / 1242` |
| 4.10.0 | `mathfuncs.cpp:717 / 750` | `1263 / 1421` | `1282 / 1286 / 1289` |
| 5.0.0 | `mathfuncs.cpp:439 / 472` | `1006 / 1158` | `1021 / 1025 / 1028` |

In 4.10 the integer-specialized switch has an Intel-device exception at
1274–1277. In 5.0 the switch is unconditional for `is_ipower`. The three
specializations create/set one, copy, and multiply respectively. Sqrt delegates
to Pow(0.5). Do not replace all Pow paths with Multiply.

5.0 Exp and Log acquire a CPU source header before creating output
(`mathfuncs.cpp:449–451,482–484`); CPU paths use NAryMatIterator and float/double
HAL dispatch. Pow uses native integer rounding and half-power dispatch
(`1010–1012,1053–1060`). General fractional Pow has its own in-place buffer and
negative/zero handling (`1083–1148`), so an independently allocated result is
not an adequate universal same-alias oracle.

OpenCL Pow creates output before source acquisition
(`mathfuncs.cpp:925,981–983` on 5.0); 2-D OpenCL admission is at 1014/1034.
The final same-type UMat alias disposition is recorded in the OpenCL section.

HAL dispatch locations identified in `mathfuncs_core.dispatch.cpp`:
4.1 sqrt/exp/log at 91–153; 4.6 at 112–174; 4.10 at 109–171;
5.0 at 129–191. OpenCL operation definitions are in `opencl/arithm.cl`,
4.x at 317–339 and 5.0 at 321–346. SIMD/scalar review follows below; arbitrary
external HAL implementations remain a trusted native boundary.

## Existing production helpers and empty asymmetry

Starting shim `cpp/opencv_core_shim.cpp:5034–5079` contains Mat template
helpers and UMat-specific empty bypasses. The Mat allocation-returning Pow
export additionally short-circuits empties at 5243–5251 using `make_empty_like`.
The Mat template helper itself has no empty bypass.

The preliminary probe confirms that calling that template directly is not
equivalent to the allocation-returning wrapper for typed empty Power=1:
on host 4.10, native copy releases a fresh output to default-empty, while
the allocation-returning wrapper preserves the typed source representation.
Reused release may preserve old destination rank/type. This is a reason to
factor the existing empty policy into shared helper handling, not a reason to
normalize all unary empties. That factoring is now implemented below.

Probe empty-mode has intentionally broad research exception logging and also
includes raw-only rejected Ada combinations. It is not an AUnit contract test.
The output must be interpreted together with unchanged Ada `Validate_Pow`.
The corrected actual-helper empty probes subsequently passed on all versions.

## Preliminary Pow(2) old destination observations

4.10 `arithm.cpp:1034–1092,1123` and 5.0
`arithm.cpp:1250–1309,1342` expose the same old-destination selector described
in `multiply_destination_source_findings.md`. Native Pow(2) delegates to
Multiply and therefore reaches that selector. The existing `dense_multiply`
protection was at starting shim 5625–5635. The final Pow protection is below.

The direct-native preliminary probe uses UInt8 -> old UInt16 and Int8 -> old
Int16, Mat and UMat, with a retained old Region alias and parent. Independent
and reused results, unchanged old storage, and new storage independence passed
on the host and all four local compatibility images. This does **not** disprove
the source-level hazard: an extended HAL implementation may exercise different
write widths. Final call-boundary interception below establishes the protected
layout; source-level reasoning establishes why it is necessary.

Host ASAN Mat old-depth native cases passed. The first UMat run reported
LeakSanitizer leaks in AMD HSA/COMGR runtime initialization. Re-running with
`OPENCV_OPENCL_RUNTIME=disabled` passed both UMat cases. The installed OpenCV
library was not rebuilt with ASAN, so these outcomes are not comprehensive
instrumentation of native writes and must not be described as such.

## Initial alias probes

Actual-helper versus separately constructed direct-native same-alias oracle
passed locally on 4.1/4.6/4.10/5.0 for Mat and UMat with OpenCL disabled:

- Float32/Float64, C1/C3, whole 2×257 and N-D (2,3,5);
- Sqrt, Exp, Log;
- Pow 0,1,2,3,-1,-2,0.5,-0.5,1.3;
- exact native object and distinct shallow header aliases.

Inputs in the initial alias probe were constant 1.75. The resumed probe uses
varied positive values for exact aliases, and the public tests add varied
C1/C3 data, reciprocal writes, Region geometry/guards and independent mismatches.

## Reproduction

Compile the probe alone; it includes the actual production shim implementation:

```sh
g++ -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  $(pkg-config --cflags opencv4) \
  tests/probes/unary_math_destination_probe.cpp \
  $(pkg-config --libs-only-L opencv4) -lopencv_core -o /tmp/task052-probe
/tmp/task052-probe mat alias helper
/tmp/task052-probe umat alias helper
/tmp/task052-probe mat old native
/tmp/task052-probe umat old native
```

For 5.0 use `opencv5`. Isolate native research modes from AUnit because upstream
assertions or crashes must not take down the normal suite. Logs for the four
image runs: `/tmp/task052-research-{4.1,4.6,4.10,5.0}.log`.

## Final production dispositions (supersede preliminary pending conclusions)

Eight public procedures and eight exports use the caller's actual native output.
The allocation-returning Ada functions and their signatures are unchanged.
Thick validation is reused; no destination compatibility precondition is added.
No production UMat mapping, getMat, transfer or host staging was introduced.

### Pow(2) write-width correction

The hazard is established by source, not by whether one backend implements the
extended HAL. In 4.10 `arithm.cpp:1123` and 5.0:1342 the old output depth chooses
the extended function. Output creation at 4.10:617 / 5.0:648 then creates source
type storage before the extended call at 4.10:625 / 5.0:656. The wrappers cast
output to ushort/short at 4.10:1040/1056 and 5.0:1256/1272. A successful HAL
implementation can therefore write past byte storage. Returning NOT_IMPLEMENTED
only happens to avoid the defect in some builds. 4.1/4.6 have no getMulExtFunc;
their multiply calls arithm_op with getMulTab and no old-depth extended selector.

`prepare_pow_output` is shared by Mat/UMat dense_pow. On 4.10/5.0 only, it uses
the exact native classification `cvRound(power)` and
`fabs(ipower-power) < DBL_EPSILON`, requires effective integer 2 and nonempty
source, and precreates source layout only for 8U->old16U / 8S->old16S. It then
calls **cv::pow**, not dense_multiply. Adjacent representable values around 2
are farther than the strict epsilon test; they are not reclassified by us.

The 4.10 Intel exception may choose OpenCL rather than the multiply shortcut;
precreation is still safe: output must have source shape/type anyway, and the
affected differently typed output cannot be an exact/same-layout source alias.
No source acquisition, exponent calculation or native dispatch was replaced.
Compatible outputs and all other powers avoid precreation entirely.

The probe exercises whole and interior old-word destinations, retains old
aliases and parents, compares every result against independent native Pow,
checks shape/type and old storage, and verifies independent subsequent writes.
Optional `UNARY_MATH_AUDIT_POW_LAYOUT` plus linker wrapping of cv::pow checks
the actual helper's native call layout. It does not emulate a HAL or claim
instrumentation inside an uninstrumented shared OpenCV library.

### Empty Pow compatibility

Mat dense_pow now handles empty input with the same representation policy as
the allocation-returning wrapper. The wrapper's existing short-circuit remains
unchanged, preserving its raw ABI behavior. A typed source makes typed 0x0 output
at every accepted power, including 1; a default source releases output. UMat's
existing helper bypass is unchanged. Old destination aliases remain alive.
This avoids known OpenCV 5 ARM64 zero-element HAL calls. There is no change to
normal nonempty execution except the narrow old-depth correction.

On local release builds, default-source release leaves fresh output rank/type
0/0. Reused old 16SC2 output keeps rank/type 2/11 on 4.x; 5.0 keeps type 11 but
resets rank to 0. Typed-empty Mat/UMat outputs keep rank 2 and source type.
UMat metadata is checked directly: test-only To_Mat uses native copyTo, which
can discard empty source metadata and is not an authoritative UMat observer.
Sqrt/Exp/Log retain their separate native Mat behavior and existing UMat
empty_float_math safety bypass. No generalized empty normalization was added.

### Creation, ownership and N-D

Reviewed Mat create at 4.1 `matrix.cpp:318–375`, 4.6/4.10:659–718,
5.0:1085–1144 and UMat create at 4.1 `umatrix.cpp:403–461`,
4.6/4.10:653–717, 5.0:601–671. Compatible storage returns before release,
including Regions with their existing step/offset. Mismatch releases only the
destination header; other headers retain reference-counted storage. Dimensions
are copied before release when their pointer belongs to the output header.
5.0 changes default 0-D creation to scalar storage, another reason not to enter
native empty Pow. No binding-level temporary output or copy-back is used.

Reviewed OutputArray create/createSameSize/release at 4.1
`matrix_wrap.cpp:1189–1342,1651–1673`, 4.6/4.10:1160–1339,1659–1681,
5.0:1466–1663,1954–1958,2042–2058. createSameSize obtains all dimensions;
plain Mat/UMat output dispatch calls the corresponding native create/release.
Release is 4.1 `mat.inl.hpp:848–866,3774–3781`, 4.6/4.10
`matrix.cpp:547–565,umatrix.cpp:378–385`, 5.0:1010–1021/384–391.
4.x zeroes extents while retaining rank/type in release builds; 5.0 clears rank
while retaining type. Shallow storage ownership is not changed by this binding.

All unary CPU paths use NAryMatIterator with channel-unrolled lengths. On 4.x
output creation explicitly passes dims/size; 5.0 uses MatShape. Genuine (2,3,5)
execution and direct metadata are tested, rather than treating Rows/Columns as
N-D metadata. Native internal CPU fallback is not binding host staging.

### Aliases, SIMD/tails and approximations

Source acquisition precedes CPU output creation for Exp/Log/general Pow in all
four versions. Compatible exact and shallow aliases keep output storage.
Pow(0) createSameSize/setTo, Pow(1) copyTo and Pow(2) multiply are separately
exercised; their compatible Region storage stays attached. General fractional
CPU Pow uses native buffers when source/output data pointers agree. No hidden
binding copy was added. Arbitrary partial Region overlap remains unsupported.

Reviewed square-root/inverse-square-root SIMD and scalar tails in
`mathfuncs_core.simd.hpp`: 4.1/4.6:260–371, 4.10:336–447,
5.0:481–592. The vector loop avoids reprocessing a tail in place and uses
std::sqrt scalar tails. Exp/Log use lookup/polynomial approximations, vector
loads followed by stores and scalar tails: 4.1/4.6:436–830,
4.10:512–906, 5.0:657–1051. Dispatch goes through the HAL and CPU dispatch
locations listed earlier; an external HAL may differ in precision or edge
values. No bit-identity contract across architectures is introduced.

Pow integer SIMD/general kernels are in mathfuncs.cpp between the Log and
ocl_pow sections (4.1:727–1138, 4.6:734–1145, 4.10:781–1192,
5.0:504–914). Scalar kernels use native saturate_cast for narrow integer
depths. Multiply kernels in `arithm.simd.hpp` at 4.1/4.6:179–192,1414–1550,
4.10:179–192,1424–1562 and 5.0:513–710 preserve native saturation/conversion
and tails. Int32 overflow is not a saturating promise; boundary observation
uses typed Int32 access and does not round extrema through floating conversion.

Finite tests use independent mathematical expectations with tolerances plus
same-build function/procedure parity. Sqrt is native Pow(0.5), not a separate
binding algorithm. Exp/Log special inputs remain observational/backend-specific;
negative fractional bases keep native behavior, not a mathematically preferred
replacement. No portable NaN payload, signed-zero or under/overflow promise.

### OpenCL

Reviewed ocl_math_op and ocl_pow in mathfuncs.cpp and unary definitions in
`opencl/arithm.cl:317–339` (4.x), 321–346 (5.0). Pow's early createSameSize
is source-typed, so supported exact/same-layout aliases cannot rebind. CPU
fallback obtains a source Mat header before output creation; no demonstrated
unsafe identity-specific rebind exists for these same-type operations. No
general UMatData/refcount/overlap detector or unnecessary identity guard is added.

OpenCL admission is output UMat and source dims<=2; double support and kernel
availability can force CPU fallback. Float OpenCL Exp/Sqrt can use native_exp /
native_sqrt; Log uses log(fabs(value)), and Pow uses pow/pown. Backend-specific
edge-value behavior is therefore not generalized. Requested-enabled probe mode
records actual useOpenCL; request alone is never claimed as GPU execution.

### Validation-boundary review

The only newly duplicated public restriction is temporary Mat destination
rejection. Its ABI safety reason is native output creation may release/rebind
callback-scoped external or selected storage, severing the logical capability.
Ada and raw C tests reject this before execution. Null checks protect handles;
no public depth, shape, channel, dimensionality or power-policy validation was
duplicated. Pow empty and old-width conditions are memory-safety compatibility
selectors, with concrete ABI safety comments. Existing UMat empty safety guards
remain unchanged. No SPARK-compatible computation was changed.

### Qualification

The suite adds 74 registrations (1975 total) for whole/Region reuse, guards,
reciprocal writes, independent mismatches, source aliases, N-D, finite numbers,
integer saturation/typed Int32 extrema, empties, validation, temporary sources
and outputs, raw null/status translation and exception-safe OpenCL disable.
Final exact-head full-suite/probe results and hosted snapshot belong in the
review handoff; they must not be inferred from earlier development runs.
No dependencies, CI, release metadata, tags or release branches are changed.

All four corrected helper/native old-depth, alias and empty probes passed in
the local compatibility images. The wrapped Pow layout assertions passed on
4.10/5.0; 4.1/4.6 compile cleanly with no guard needed. Requested-enabled alias
probes on all images reported actual OpenCL=0, so no GPU execution is claimed.
Host ASAN corrected whole/Region Mat and UMat old-depth probes passed with
OpenCL runtime loading disabled. As above, native shared OpenCV was not rebuilt
with ASAN: source reasoning, not comprehensive ASAN instrumentation, justifies
the correction. Shared shim C++17 strict warnings and --no-undefined linked
successfully on host; its dynamic symbol table contains exactly the eight new
named exports. GNATformat changed ranges and new units were checked separately.