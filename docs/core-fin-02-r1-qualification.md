# CORE-FIN-02-R1 corrective qualification

Starting main: `aa8a378ab614e9a5fc4f43765cd3ff1bbcf6a44d`.
Starting feature: `5873650bac8b20186df61c956306c8de3a6e9a03`, tree
`0efbcee5ad13449bfce979eba52b5da30acbc247`. PR #94 is updated in place.
Version 0.5.2, all eight profiles, existing Norm/enumerations, exclusions and
production count/stride guards are unchanged. PR #91 is untouched.

## A — local audit provenance

The failed exact-head audit run 39539104441 first rejected
`src/opencv-core.ads:5027`. Every stored local excerpt was compared to current
source. All 35 shifted declarations have exactly one unchanged-text match,
and their identities/signatures are verified by the Ada declaration index.
Only their start/end ranges in `core-api-coverage.json` change. Text and SHA-256,
stable IDs, classifications, upstream declarations, provenance/reference JSON,
compiler snapshots, and unresolved limitations are preserved.

The practical-scope validator retains an exact blob lock, updated to the newly
authenticated coordinate-only coverage ledger. Its validation logic is not
relaxed; whitespace/content mutation negatives still apply. Added regression
coverage requires unique original text, exact signature, and matching ranges.
Historical discovery/coverage incompleteness remains explicit; no completion
flag or BOUND_FULL classification is promoted.

## B — native zero-mask relative results

Hosted OpenCV 5 job 119022163204 (run 39538998823) failed at the Ada test call
site, `numerical_norm_tests.adb:276 invalid data`, 2052 run / 2051 successful.
The former local OpenCV 5 build had IPP disabled, unlike the default hosted
source build. A fresh default-options Core build from pinned 5.0 source was
configured with IPP 2026.0.0, and the independent
`tests/probes/numerical_norms_native_mask.cpp` calls `cv::norm` directly, without
the shim or Ada API. It exercises all six depths, C1..C4, L1/L2/INF, zero and
partial masks, both operand orders, optimized IPP, IPP-disabled, and generic
dispatch. Each result is recorded as FINITE/POSITIVE_INFINITY/NEGATIVE_INFINITY/
NAN, with exceptions and abnormal exits treated as failures.

Observed pinned OpenCV 5 / IPP 2026.0:

* Zero mask: C1 UInt8/UInt16/Float32 returns **NAN** for all three relative
  norms, in both orders (18 cases). Other supported depths/channels return
  finite zero in this build.
* IPP disabled or optimizations disabled: all zero-mask cases return zero.
* Partial mask: every result is finite, forward 2 and reverse 2/3 for the
  constant operands 3 and 1. No native exception or abnormal exit occurred.

Pinned source `40738fb16ceddb5fb3fea747585f7ce6abb0605b`:
`modules/core/src/norm.dispatch.cpp:538–553` invokes HAL before generic relative
division; `hal/ipp/src/norm_ipp.cpp:132–170` selects masked ippiNormRel C1
functions for UInt8/UInt16/Float32 and publishes their successful result,
without applying the generic DBL_EPSILON denominator. The generic fallback
uses Right norm + DBL_EPSILON. This is a numerical/backend distinction, not
unsafe memory access or a wrong selector mapping.

Correction: preserve native results; compare the all-zero relative case against
the independent native oracle using IEEE-safe classification, with local
Validity_Check suppression at that test scope. No production algorithm or
forced-zero branch is introduced. The existing public implementation already
preserves native IEEE outputs. Public mask documentation no longer promises
zero for relative empty selection. The raw actual-shim probe now covers this
case too; AUnit registration total remains **2052**.

Local IPP-enabled full run after the mask fix has **no new norm failure** but
one unrelated existing UMat Float16 extrema assertion in this locally built
configuration. This is not claimed as a full qualification pass; the exact
hosted configuration must run the complete 2052 tests. IPP-disabled local
passes are not substituted for that gate.

## C — macOS sanitizer teardown investigation (pending controls)

Hosted macos-26-arm64 image 20261013.0424.1, Apple clang
21.0.0 (clang-2100.1.1.101), Homebrew OpenCV 5.0.0, TBB 2023.1.0:
unsanitized actual-shim probe passed. ASan/UBSan probe exited **134** during
normal process teardown, with ASan SEGV:

```
#0 <unknown module>
#1 tbb::detail::r1::__TBB_InitOnce::~__TBB_InitOnce()+0x38
   libtbb.12.19.dylib:arm64+0x9824
#2 __cxa_finalize_ranges
#3 exit
```

A printed assertion-completion message before that abnormal exit is **not** a
sanitizer pass. The stack alone does not establish environment-only causation.
oneTBB v2023.1.0 commit `3046c8b0c29df995980003ea24f4d78c80ec0c8d`,
`src/tbb/main.h` destructor and `src/tbb/governor.cpp` release_resources include
TLS teardown and dynamic-unlink callbacks; allocator lifetime is a hypothesis,
not a finding yet.

`scripts/qualify_macos_norm_sanitizers.sh` records exact compiler/resource SDK,
runtime/dependency identities and dylib hashes, command lines, dSYM-backed
symbolized logs, return statuses and loader traces. Controls: clean ASan/UBSan
process; same-library direct native norm; unchanged starting-main shim using
existing Norm; full feature shim; positive UAF/signed-overflow detection. All
successful controls return normally with full teardown. A separate explicitly
needed allocator dependency tests the unload-lifetime hypothesis; it does not
waive a failing default configuration. No ASan/UBSan disabling, _Exit, teardown
skip, or sanitizer-error suppression is used. LeakSanitizer remains unsupported
by Apple's runtime, as previously documented.

Final corrected SHA/tree, exact-head hosted conclusions and control artifacts
are recorded in PR #94 after the corrective commit. Until the full macOS
instrumented process exits normally, the gate is **MACOS_SANITIZER_BLOCKED**.
Scarthgap and physical target execution remain NOT TESTED.