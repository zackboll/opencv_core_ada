# Task 053 — Magnitude and Phase reusable destinations

## Starting gate and scope

Fetched origin/main is `136c87ceb69c4ce5ba61ca93249c972fa4fb9de0`, exactly
the requested PR #55 merge. No open PRs were returned. The primary checkout
was clean on a corrective branch and was left untouched. Work is isolated at
`/home/zboll/git/opencv/core-task053`, branch
`feature/053-magnitude-phase-destination`. Read all six repository rules,
library/test manifests and projects. Full host baseline: 1975 executed/passed,
zero assertions/errors (`/tmp/task053-baseline.log`). Host OpenCV: 4.10.0.

Exactly four public procedures and four narrow destination exports are added.
Allocation functions, angle mapping, validators and production helpers are
unchanged. No release/version, dependency, CI or two-output API changes.

## Exact upstream identities

Reconfirmed peeled tags with git ls-remote and local source HEADs:

| Version | Commit | Source checkout |
| --- | --- | --- |
| 4.1.0 | `371bba8f54560b374fbcd47e7e02f015ac4969ad` | `/tmp/imgproc046-upstream-4.1.0` |
| 4.6.0 | `b0dc474160e389b9c9045da5db49d03ae17c6a6b` | `/tmp/task052-upstream-4.6.0` |
| 4.10.0 | `71d3237a093b60a27601c20e9ee6c3e52154e8b1` | `/tmp/imgproc046-upstream-4.10.0` |
| 5.0.0 | `40738fb16ceddb5fb3fea747585f7ce6abb0605b` | `/tmp/imgproc046-upstream-5.0.0` |

Reviewed files below are relative to modules/core/src. The installed core.hpp
declarations also confirm source-typed output, radians default, and Phase's
approximately 0.3-degree accuracy contract.

| Version | mathfuncs.cpp: ocl_math_op / Magnitude / Phase |
| --- | --- |
| 4.1.0 | 61 / 146 / 182 |
| 4.6.0 | 62 / 147 / 183 |
| 4.10.0 | 62 / 147 / 183 |
| 5.0.0 | 64 / 149 / 185 |

All versions select CPU HAL using source depth, acquire X and Y Mat headers
before output creation, create source-typed output, then use NAryMatIterator
and magnitude32f/64f or fastAtan32f/64f. Reviewed mathfuncs_core.dispatch.cpp
and mathfuncs_core.simd.hpp: native HAL/CPU dispatch, vector sqrt/multiply and
scalar tails, fast-angle polynomial, and Float64 angle's float-buffer path.
The native SIMD tail checks avoid reprocessing in-place source data and can
select scalar tails for aliases. Same-alias native oracles are used rather
than requiring fresh-output bit identity.

Reviewed matrix_wrap.cpp output creation dispatch and matrix.cpp/umatrix.cpp
create/release implementations. Compatible nonempty shape/type returns early,
including Region headers; incompatible output releases/rebinds only its own
header. Retained shallow headers keep old allocations alive. Native 5.0 release
clears rank/shape (matrix.cpp:1010, umatrix.cpp:384), unlike 4.x release's
retained rank with zero sizes. Typed creation after release can reconstruct
rank, so release behavior alone does not determine each operation's result.
No binding postcondition is added to force equal empty metadata.

## Old destination and OpenCL audit

ocl_math_op obtains both UMat source headers before destination creation
(4.1:80–82, 4.6/4.10:81–83, 5.0:83–85). Exact source aliases have the same
source/output layout and do not require depth-changing rebinding. Compatible
Regions preserve layout; incompatible output creation detaches old aliases.

Magnitude predicts vector width before output creation. Reviewed ocl.cpp
PROCESS_SRC/checkOptimalVectorWidth (4.1:6242–6319, 4.6:7202–7279,
4.10:7220 onward, 5.0:7203 onward). It considers each nonempty operand's
offset/step/channel-width divisibility, returns width one for incompatible
types under OCL_VECTOR_OWN, and otherwise takes the minimum valid width.
The output kernel type and depth remain source-derived, not old-output-derived.
Old shape/channel/depth does not become a numerical write-width selection.
Phase fixes kercn=1. No Multiply/Subtract-style old-depth hazard was found.
**Both production helpers remain unchanged; no preallocation or alias copies.**

Reviewed opencl/arithm.cl: OP_MAG uses hypot (4.x:300, 5.0:304); Phase uses
atan2(Y,X), adds a full turn for negative angles and optionally degrees
(4.x:303–315, 5.0:307–319). CPU sqrt-of-squares and OpenCL hypot can have
different overflow/special-value behavior; no universal hypot policy is added.

UMat remains native in production: no transfers, getMat, access mapping or
host staging added. Probe observation maps are test-only. The local compatibility
images were built without OpenCL; requested=1 reports enabled=0. Host request
reports enabled=1, but AMD kernel compilation fails due to missing
`/usr/lib/llvm-17/lib/clang/17/include/opencl-c-base.h`, followed by successful
CPU fallback. Actual GPU execution has not been demonstrated.

## Numeric and ownership qualification

Public tests check Float32/Float64 C1/C3, width 257, whole and interior Region
reuse, every Parent guard, original geometry, and reciprocal alias writes.
Independent shape/depth/channel mismatch cases preserve old Parent/Alias and
detach new output. Exact X/Y and distinct shallow X/Y destinations, plus X=Y
independent/exact/shallow output cases, preserve ordinary finite behavior.
The actual-helper probe constructs separate direct-native same-alias oracles
and checks retained old-source mathematical expectations, not bit identity.

Finite Magnitude tests include 3/4, 5/12, negative coordinates, zero, noninteger,
small and large finite inputs. Phase tests include all axes/quadrants, zero,
explicit radians/degrees and omitted radians default. Wraparound distance uses
the documented 0.3-degree tolerance without a strict half-open range claim.

Special-value probe inputs are signed zeros, +/-Infinity, NaN, and Inf/Inf.
Function/helper reused/direct-native classifications agree on the tested CPU
builds. Host Magnitude yields zero, infinity, or NaN as appropriate; Phase
Inf/Inf and NaN cases yield NaN, single-infinity cases can yield finite angles.
The probe prints std::fpclassify codes (host: NaN=0, Inf=1, zero=2, normal=4).
No NaN payload, signed-zero bit, universal overflow, or backend policy is imposed.

Both public functions and procedures reject genuine (2,3,5) N-D and invalid
source layout/type before mutation. Default-empty procedure inputs reject and
preserve Destination/Alias. Matching typed float empties are accepted: Mat
uses native creation; UMat uses unchanged empty_float_pair reconstruction.
Direct metadata tests deliberately do not transfer empty UMat to Mat, because
that transfer may discard metadata. Observed helper and Mat-native 0x0 outputs
on all four builds have rank two and source type, fresh and reused.

Temporary external and selected Mat sources remain legal. Public and raw
temporary outputs reject before native execution; tests preserve rank, shape,
format, values, selected Parent, and padded external backing. Raw tests also
exercise each export's null arguments, valid Phase flags 0/1, invalid 2/255,
Region Parent preservation and native exception-to-status translation.
No arbitrary post-native failure-atomicity guarantee is introduced.

## Validation-boundary review

No source float, shape, channel or 2-D public policy is duplicated in the new
exports. Null guards protect handle dereferences; Phase guards validate the
explicit 0/1 ABI boolean representation. The sole retained duplicated public
restriction is temporary Mat output rejection: native output creation can
release/rebind callback-scoped external/selected headers and sever their
capability. Both Mat exports carry the concrete ABI safety comment. Existing
empty_float_pair memory-safety guards remain unchanged.

## Reproduction and final review gate

Compile the standalone probe with C++17 -Wall -Wextra -Wpedantic -Werror and
pkg-config flags for the selected installed OpenCV. It includes actual
cpp/opencv_core_shim.cpp, not copied helper logic. Normal mode disables OpenCL;
--opencl requests it and records actual activation; --raw-empty isolates native
UMat empty research from AUnit. No historical builds are added to hosted CI.

Host development suite has 2009 registered/executed/passed, zero assertions
or errors. Exact committed-head five-environment results, strict shared-link,
format/diff checks and hosted CI snapshot are recorded in the final review
handoff rather than inferred from earlier development runs. No SPARK-compatible
computation changed; GNATprove is not applicable to this foreign-call slice.