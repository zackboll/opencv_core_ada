# CORE-FIN-03 qualification record

This record describes the development feature, not implementation in main or a
release. Starting main: `8e39d9fca8563a48f55635f320b987b2cbde1962` (fetched and
verified; PR #95 merge). Work is isolated on
`feature/core-fin-03-native-runtime-identity`. Crate version remains `0.5.2`.
Exact tested/pushed/PR source and tree identities are recorded in the PR and
completion report after committing; this file does not embed a self-referential
commit hash. No release, tag, index submission, merge or auto-merge is authorized.

## Implementation and review

- Public API: `Native_Version_String return String` and
  `Native_Build_Information return String` in `OpenCV.Core`.
- Two `opencv_core_native_*` C functions, `uint64_t` capacities/counts,
  caller-owned buffer, query/copy protocol, counts excluding NUL.
- Native OpenCV functions are called for each query and copy. No shim cache,
  returned native pointer/reference, shared returned-data buffer, or ownership
  framework. Ada returns a checked ordinary String.
- [Full contract, example and pinned four-version findings](native-runtime-identity.md).
- Validation-boundary review: null/count alias/capacity combinations protect
  ABI outputs; capacity and length limits protect conversion, NUL reservation,
  `memcpy` and indexing; insufficient-capacity checks protect the caller buffer.
  No public semantic validation is duplicated in the C++ shim.
- Existing numerical norms/scalar behavior is unchanged. Additive implementation
  blocks preserve historical audit excerpt positions and bytes; no forensic
  ledger or planning-status rewrite was needed.

## Local evidence

Raw logs are retained under `/home/zboll/qualification/core-fin-03` on the
qualification host (not an installed-consumer dependency).

| Check | Result |
| --- | --- |
| Registered AUnit, OpenCV 4.1.0 | 2,054 successful; 0 assertions/errors |
| Registered AUnit, OpenCV 4.6.0 | 2,054 successful; 0 assertions/errors |
| Registered AUnit, OpenCV 4.10.0 | 2,054 successful; 0 assertions/errors |
| Registered AUnit, OpenCV 5.0.0 | 2,054 successful; 0 assertions/errors |
| Runtime identity independent native parity | Both complete public Strings, all four versions |
| Actual-shim native and ASan/UBSan probes | All four versions; Linux leak detection enabled |
| Ada count/overflow/failure controls | All four versions; both public functions |
| Existing scalar/numerical native and sanitizer probes | Passed on host OpenCV 4.10 |
| GNAT 12.2 Debian 12 production | 2,054 successful; existing layout O0/O2 and boundary controls passed |
| GNAT 12 runtime identity failure controls | Passed with Ada validity checks |
| GNAT 12 installed/relocated Ada and mixed consumers | Passed; prefix-only resolution and ELF controls |
| GNAT 16 installed/relocated Mat consumer | Passed; installed projects/libraries, source-path rejection |
| Offline audit and practical-scope validators | Passed; forensic incompleteness remains explicit |
| Audit/parser negative controls | 105 tests passed with pinned parser dependencies |
| Cross-configuration and probe/output controls | 56 + 3 + 7 tests passed; synthetic, not target execution |
| External shim installation regressions | 3 tests passed in Alire environment |
| GNAT 12 aggregate/language regressions | 8 tests passed in Debian 12 environment |
| Documentation warning/link/highlight unit controls | 26 + 21 + 21 tests passed |
| GNATdoc generation | Zero documentation warnings; generated contract includes both functions |
| Generated instance/navigation/guide regressions | 24 + 4 + 21 tests passed |
| Debian 12 checkout-free/Alire-free installed consumer | Passed ordinary/relocated prefixes; artifacts staged with status 0 |

GNATformat was run on modified/new Ada regions; unrelated formatter changes
were removed. `git diff --check` passed. GNATprove was not run: this addition
uses the trusted foreign boundary and ordinary String handling, not changed
SPARK arithmetic. Runtime checks and negative tests qualify count validation;
no formal proof of the native implementation is claimed.

GNATdoc generation, generated-page regression controls, and the separate
checkout-free Debian consumer campaign passed locally as recorded above.
Hosted qualification must be inspected for the
exact PR head; a merge-ref result cannot qualify a different source head.

## Diagnosed runs, not passes

- Initial foreground AUnit invocation exceeded the command tool's timeout and
  emitted host AMD OpenCL compiler diagnostics for a missing Clang 17 header.
  Completed local campaigns explicitly use `OPENCV_OPENCL_RUNTIME=disabled`;
  this is not local GPU/OpenCL qualification.
- Initial unformatted Ada comments exceeded the 79-column build policy; fixed
  and rebuilt with warnings fatal.
- Initial audit attempt detected shifted line evidence. Moving additive blocks
  to the ends of existing files preserved all historical evidence unchanged;
  validators and negative controls then passed.
- The new C control initially needed the same scalar forward declaration as
  existing C probes. Its files were isolated in their own source directory to
  avoid entering unrelated GPR probe source sets.
- An initial GNAT 12 snapshot taken during active builds failed representation
  checks; fresh stable-source campaigns passed. No production representation
  checks were disabled or altered.
- Concurrent host build jobs raced on generated archives and one transient
  source read. Generated outputs were cleaned and host qualification rerun
  serially. The failed concurrent runs are not successful qualification.
- Documentation tool-version pipelines exposed `grep -q` closing stdout early,
  causing Alire to report SIGPIPE (`-1`) for successful version tools. The
  documentation script now consumes complete output while retaining the exact
  version gates.
- Running tool-dependent regressions outside their environment failed to find
  `gprinstall`/`gnat1`. Re-running in Alire/Debian GNAT 12 environments passed.
- The generated-site regression correctly detected the two new public profiles:
  1,293 snippets rather than the old 1,291 baseline. The exact expected count was
  updated by two; existing reference/link counts and integrity checks remain.

## Boundaries and review disposition

Hosted CI adds probes only to existing compatibility/ARM64 jobs; source checkouts
use the actual PR head where qualification is required. Existing GNAT 12,
independent-consumer, cross, audit and documentation jobs are retained.
Windows/MSYS2 and MacPorts policy skips are not successes. Apple LeakSanitizer
remains unsupported; existing TBB lifetime handling is retained. No Scarthgap,
physical-target, or Windows qualification is inferred from Linux results.

FIN-03 remains `PLANNED_REQUIRED` in `docs/core-current-status.json` until merge.
A separate post-merge reconciliation must cite the merge and exact-head evidence.
The PR must remain non-draft, open, unmerged and without auto-merge for independent
review. Readiness is determined by the exact-head hosted checks, not this record
alone.