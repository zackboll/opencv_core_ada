# CORE-FIN-02 qualification record

The [R1 corrective report](core-fin-02-r1-qualification.md) supersedes initial
qualification claims where the three exact-head hosted failures differ:
stale local audit coordinates, IPP zero-mask relative NaN, and macOS sanitizer
teardown. Earlier local passes do not waive those gates.

Starting main: `aa8a378ab614e9a5fc4f43765cd3ff1bbcf6a44d`, version 0.5.2.
Fresh worktree: `/home/zboll/git/opencv/core-fin-02-numerical-norms`.
Branch: `feature/core-fin-02-numerical-norms`. PR #91 was not modified.

The public API, exclusions, count policy and complete validation-boundary
review are in [numerical norms](numerical-norms.md). Immutable native source
references are in [source findings](../tests/probes/numerical_norms_source_findings.md).
No release, version or tag change is part of this feature.

## Local campaigns

* Baseline: `alr build`, `alr -C tests run`: **2037/2037**.
* New suite: **15 registrations**, final expected total **2052**. Existing
  registrations remain intact. Native references use the supported borrowed
  module bridge and call OpenCV directly; mathematical expectations do not
  use the new implementation as their own oracle.
* Actual-shim probe: `sh scripts/run_numerical_norms_probes.sh`, compiled
  separately against actual OpenCV 4.1.0, 4.6.0, 4.10.0 and 5.0.0 installs.
  Native parity and raw negatives include null handles/outputs, selectors,
  native exceptions, output initialization, count/channel/stride bounds,
  nonfinite inputs, N-D and unaligned/noncontiguous binary ROIs.
* The same actual production shim runs with ASan/UBSan. Linux leak detection
  is enabled; Apple LeakSanitizer is unsupported and explicitly not claimed.
  Linked system OpenCV is **not** claimed to be sanitizer-instrumented.
* Compiled Ada example:
  `alr -C tests exec -- gprbuild -P probes/numerical_norms_example.gpr -p`,
  then `tests/probes/bin-numerical-example/numerical_norms_example`.
* Independent native GNAT 12.2.0/Debian 12/OpenCV 4.6.0 campaign uses
  `tests/gnat12/run_production.sh`, including the full ordinary AUnit suite,
  boundary controls, recursive installation and relocated GPR consumers.
  The installed Ada consumer now directly exercises the new API as well.
* GNATdoc: qualified 26.0.0 generator, leading public documentation, zero new
  warnings; 195 public packages, 202 HTML pages, 1291 highlighted declarations,
  2755 resolved type links. New declarations account for +9 snippets/+13 links.
* Documentation regression suite: **117 passed** using the existing isolated
  Markdown environment. Desktop/mobile, light/dark, JavaScript-disabled and
  direct-symbol/history browser checks passed against the generated site.
* Cross-configuration controls: **56 passed**, module-bridge cross controls:
  **3 passed**, GNAT Pro evidence-verifier controls: **7 passed**. These are
  synthetic controls, **not** cross-target execution.

Final exact tested/pushed/PR source identities and hosted run conclusions are
recorded in the PR body after commit. This document does not promote a test on
an earlier source revision to final-head evidence.

## Diagnosed development failures (not hidden qualification passes)

1. A synthetic OpenCV 5 header originally changed `cols` without updating
   `size[1]`. GDB showed the inconsistent fixture bypassing the intended count
   preflight; it was corrected. No workaround for a supposed valid-input
   OpenCV Hamming defect was retained.
2. A borrowed-view fixture attempted a prohibited shallow copy. It now tests
   exact-input aliases directly within the borrow callback; ordinary shallow
   copies are covered separately.
3. Root documentation builds select `-gnatVa` for Core. Native IEEE result
   conversions and deliberate invalid enum tests need local validity-check
   suppression so the new documented result/selector contract is enforced.
   Existing unrelated strict-validity failures remain outside this feature;
   ordinary tests use the existing release dependency profile.
4. Documentation tests initially ran with system Python lacking `markdown_it`.
   They were rerun in the existing documentation-only environment. Two exact
   generated-site fixture counts were updated for the new public declarations;
   structural validation was not weakened.
5. Shared `/tmp` exhaustion interrupted one final rerun (`No space left on
   device` during staging; GPR temporary configuration creation failed). This
   was an environment failure before feature compilation. Reruns use private
   disk-backed temporary/evidence directories under
   `/home/zboll/qualification/core-fin-02`.

## Explicit platform limitations

Hosted Linux x86_64, Ubuntu ARM64, macOS ARM64, GNAT 12 production, cross
controls, documentation/browser, installed Debian consumer and compatibility
jobs must be evaluated at the exact pushed head. Windows/MSYS2 and MacPorts
policy skips remain skips, not passes.

The previously preserved Scarthgap qualification container was inspected
read-only. Its mounted workspace has no available proprietary compiler/SDK
inputs; `/opt/gnat` is absent. GNAT Pro 25.2/OpenCV 4.9.0 source/ABI/target
qualification is therefore **NOT TESTED in this environment**, not a cross-build
or QEMU pass. No private SDK/compiler/sysroot was modified. Physical hardware
testing is **NOT TESTED**. No QEMU sanitizer result is claimed.

Broader stale planning statuses in the JSON ledger remain a separate task.
FIN-01 is identified as merged in the readable planning documents; FIN-02 is
not marked fully qualified there before the remaining review gates complete.