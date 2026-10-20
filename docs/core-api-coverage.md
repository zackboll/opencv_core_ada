# CORE-CLOSE-001: Core API coverage evidence — INCOMPLETE

## CORE-CROSS-UX-001-R1: repair inherited local evidence coordinates

PR #92 head `84ab4f2125dd5a18f9801babde8b79b30a4c8827` and its base
`5aef4d11722aa20b0c8229983afb6d257df5a74f` both failed the unchanged offline
validator with `stale source evidence: src/opencv-core.ads:4886`. The base had
merged scalar-mode additions ahead of the original audit's local anchors;
line 4886 now declares `Transform`, not the recorded `Norm`. This is an
inherited main/audit inconsistency, not a cross-tooling classification or
workflow checkout problem. The hosted job checked out the exact PR head.

Of 81 local evidence anchors, 51 moved: later declarations in
`src/opencv-core.ads` by 141 lines, implementation excerpts in
`src/opencv-core.adb` by 246, and `cpp/opencv_core_shim.cpp` by 160. Each
stored excerpt still matches exactly once in its original file. Only their
`start`/`end` coordinates in `core-api-coverage.json` are corrected. All stored
text, SHA256 values, identities, signatures, semantic records, upstream
provenance, review locks and unresolved classifications remain unchanged.
The raw upstream census is not regenerated. The earlier byte-for-byte retention
statements below describe the original audit continuation, before this repair.
The practical-scope checker's one protected coverage-JSON blob is relinked from
`10ee2d8f8a0cda9aa992357582b59ae6195bd21a` to
`e114c590c7088b77d55ed01555ccaab372345075` for these coordinate edits; its
other eight protected blobs remain unchanged. A focused positive/negative test
confirms that this replacement blob is still protected byte-for-byte.

The existing positive snapshot test checks all corrected anchors; additional
negative tests reject shifted coordinates and modified text even when the
stored hash is unchanged. Neither validator logic nor workflow behavior
(including `--allow-incomplete`) changes. `UPSTREAM_DISCOVERY_BLOCKED` and
`COVERAGE_AUDIT_BLOCKED` remain in force; this is evidence-integrity repair,
not exhaustive-coverage acceptance.

The cross-install implementation and all production Ada/C++/GPR/manifest
inputs remain unchanged from `84ab4f2`. The user's successful GNAT Pro 25.0w /
GCC 12.3.1 / AArch64 Scarthgap / OpenCV 4.9.0 bootstrap, build, recursive
install and independent installed-consumer link qualification therefore carries
forward. That qualification used `gprbuild -R`, produced no RPATH/RUNPATH,
and did **not** execute the target binary. It is user-supplied vendor evidence,
not a newly executed SDK test in the repair environment.

## CORE-CLOSE-001B: practical portable scope, separate from forensic acceptance

See the [portable capability matrix](core-portable-capabilities.md),
[implementation-ready finite backlog](core-finish-backlog.md), and
[artifact retention proposal](core-audit-artifact-policy.md). These separate
portable semantics, optional/version-specific capabilities and the native C++
implementation surface. The first three bounded implementation tasks can start
without waiting for the full raw census. They do not certify `BOUND_FULL`,
clear any blocker, or publish an exhaustive coverage percentage.

All nine forensic JSON files, including the complete header/Clang/census data,
original 26 records and unresolved review lists, are preserved byte-for-byte.
The new planning ledger/evidence/checker operates separately. Header-family
binding-target decisions in the matrix are not per-declaration review approvals.
Overall dispositions below remain accurate: `UPSTREAM_DISCOVERY_BLOCKED` and
`COVERAGE_AUDIT_BLOCKED`. Practical-scope acceptance is a distinct review gate.

## CORE-CLOSE-001A continuation — UPSTREAM_DISCOVERY_BLOCKED

This continuation enumerates **every tracked path** under the exact pinned
`modules/core/include/opencv2/` subtree, not merely the original 21 selected
headers. It does **not close native declaration discovery**: header dispositions,
conditional/macro declaration extraction and semantic reconciliation remain
unreviewed. No `BOUND_FULL` status or global `discovery_complete` promotion occurs.
The original 26 capability records and their evidence remain unchanged; only
their top-level reference/provenance fingerprints are relinked.

### Reproducible header enumeration and declaration counts

| Reference | Tracked headers | Provisionally in scope | Provisionally excluded | Scope dispositions reviewed | CST declaration occurrences | Distinct source IDs | CST blockers | Clang active declarations | Unmatched Clang occurrences |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 4.1.0 | 113 | 88 | 25 | 0 | 9,023 | 8,143 | 644 | 5,910 | 2,262 |
| 4.6.0 | 141 | 104 | 37 | 0 | 9,783 | 8,871 | 697 | 6,541 | 2,468 |
| 4.10.0 | 149 | 105 | 44 | 0 | 9,861 | 8,964 | 676 | 6,630 | 2,513 |
| 5.0.0 | 145 | 106 | 39 | 0 | 10,261 | 9,320 | 698 | 6,984 | 2,297 |

All source-CST records have a **provisional** family or exclusion: respectively
8,734/289, 9,401/382, 9,493/368 and 9,875/386. Thus zero *emitted records* lack a
bucket, but this is emphatically **not zero genuinely unclassified native APIs**.
Unparsed regions, unmatched compiler declarations and unreviewed mappings block
that conclusion. The 129 provisional native buckets comprise 16 existing seed IDs
and **113 new discovery IDs**, not 129 independently reconciled semantic families.
The other ten seed records are preserved; the census does not remove them.
Exact new IDs are listed in the reference's `upstream_discovery` section.

Scope category counts (provisional; exclusions require explicit review):

| Reference | Portable public | Template/inline | Backend public | Platform/external | Internal excluded | HAL/low-level excluded | Legacy excluded |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 4.1.0 | 21 | 6 | 57 | 4 | 7 | 15 | 3 |
| 4.6.0 | 30 | 9 | 60 | 5 | 11 | 23 | 3 |
| 4.10.0 | 30 | 10 | 60 | 5 | 11 | 30 | 3 |
| 5.0.0 | 32 | 10 | 59 | 5 | 12 | 26 | 1 |

These are **source census counts**, never Ada coverage percentages. Public
constructors, methods, operators, templates, types, enums/enumerators, fields,
aliases, constants/macros and inline definitions are retained. Duplicate
signature IDs may occur at distinct declaration/definition locations; duplicate
*occurrence identities* are rejected. Signature identities are syntactic, not
canonical compiler overload identities: parameter names/defaults and annotations
can affect them. Clang USRs/type signatures provide a separate cross-check.

### Discovery artifacts and affirmative gates

- [Header manifest](core-api-header-manifest.json): full tracked path/blob list
  plus Git tree objects and ancestor sibling entries. Offline validation
  recomputes actual Git tree hashes, rooted at each pinned upstream tree SHA.
  Deleting a header and rehashing our JSON cannot make the authenticated subtree
  complete. No network or upstream checkout is required for this check.
- [Header scope](core-api-header-scope.json): every path has version, blob,
  SHA-256, category, rationale/exclusion reason, source excerpt, feature directive
  observations, source link, provisional families and explicit review state.
- [Native source census](core-api-native-declarations.json): all in-scope source
  files are traversed, including preprocessor branches. Records include owner,
  signature/overload identity, kind, source ranges/link, access, guards, mapping,
  confidence and review state. Syntax accounting records and exact blocking
  cases prevent a limited extraction from simply declaring itself complete.
- [Compiler evidence](core-api-compiler-evidence.json): independent libclang
  19.1.7 C++17 active-configuration census with **zero compiler errors** on each
  version. This uses pinned headers first and the installed Linux standard
  library/config header environment; it is not a clean target qualification.
  It records the exact arguments, diagnostics, include roots, USRs and
  source-candidate matches. It does not prove inactive branch completeness.
- [Review lock](core-api-discovery-review.json): fingerprints and separate
  reviewed-header, reviewed-exclusion and independent-reconciliation lists.
  Refresh never grants approval. These review lists remain empty.
- [Exact blocker report](core-api-discovery-blockers.json): per-version counts
  and every unresolved header path, including unmatched compiler counts and
  evidence required. Source-level uncertainties retain exact ranges and text in
  the native census, rather than a sampled list presented as exhaustive.

`UPSTREAM_DISCOVERY_COMPLETE` and `ADA_COVERAGE_AUDIT_COMPLETE` are **independent**
and both remain false. The legacy coverage JSON `discovery_complete=false`
continues to block overall Core coverage acceptance. The native gate requires
reviewed scope/exclusions, all syntax/macro/guard cases reconciled, every
applicable declaration mapped to a reviewed semantic family or explicit
exclusion, and affirmative independent reconciliation evidence. A parser's own
empty error list or emitted-record bucket count cannot satisfy it.

### Known unresolved declarations and exact evidence needed

Representative blockers (the linked JSON is the complete location list):

- `core/mat.hpp`: `CV_ENUM_FLAGS(AccessFlag)`, `_InputArray::KindFlag` flag
  operators and `CV__DEBUG_NS_BEGIN/END` expansion; reconcile generated
  operators/debug owners and every Mat/UMat/SparseMat overload against compiler
  USRs and inactive configurations.
- `core/affine.hpp`: conditional `DataType<Affine3<...>>` members and templated
  conversion operator `Affine3<T>::operator Affine3<Y>()`; resolve source identity
  and guarded signatures, not merely class name.
- `core/saturate.hpp`: explicit conversion specializations; `core/mat.inl.hpp`,
  `matx.inl.hpp`, `types.hpp`, `operations.hpp`, `softfloat.hpp`, `traits.hpp`:
  overload/template/inline cases and multiple declarators must be reconciled.
- `core/cvdef.h` and `cvstd_wrapper.hpp`: compiler-feature branches, annotation
  macro definitions and wrapper templates; account for generated syntax without
  stripping API-generating macros as though they were visibility annotations.
- `core/cuda/color.hpp`, `functional.hpp`, `saturate_cast.hpp`, `vec_math.hpp`,
  `vec_traits.hpp`, `datamov_utils.hpp`: device compiler/macros generate APIs;
  either independently enumerate them or explicitly review a justified scope
  exclusion. Backend status alone is not permission to drop them silently.
- OpenCL runtime/autogenerated headers: clAMD/clBLAS/clFFT declarations and SVM
  extension branches need backend/exclusion review and guard-aware identity.
- `core/utils/logger.hpp`, `utils/tls.hpp`, `parallel/parallel_backend.hpp`,
  `async.hpp`, `detail/async_promise.hpp`: friend declarations and utility methods
  still require scope/semantic review. In particular **AsyncPromise is a public
  documented API despite the `detail/` path**; no blanket detail exclusion.

Known candidate availability remains pinned-source qualified: transposeND is
absent in 4.1; flipND/broadcast absent in 4.1/4.6; finiteMask/divSpectrums occur
only in 5.0 among references; Quat/DualQuat/Async headers absent in 4.1; MatShape
and new 5.0 depth macros occur in their exact source files. Native census
`version_differences`, `header_differences` and `declaration_availability` record
source-ID additions/removals/changed overload sets between reference tags.
These are **observed reference differences**, not exact release-introduction
dates, canonical ABI diffs or proof all depth/channel combinations work.

### Reproduction and validation

Normal offline integrity validation remains standard-library-only:

```sh
python3 scripts/audit_core_api.py --allow-incomplete
python3 scripts/audit_core_api.py --check-discovery  # expected BLOCKED / exit 1
python3 scripts/audit_core_api.py --allow-incomplete --discovery-diagnostics
python3 -m unittest discover -s tests/coverage -v
```

Optional full source refresh uses the pinned parser requirements under tests,
not production dependencies. From a local environment with those requirements:

```sh
python3 scripts/audit_core_api.py --refresh-discovery /absolute/upstream-parent --allow-incomplete
python3 scripts/audit_core_api.py --refresh-compiler /absolute/upstream-parent --libclang /absolute/libclang-19.so.1 --allow-incomplete
python3 scripts/audit_core_api.py --reconcile-compiler --lock-discovery-snapshot --integrate-discovery-metadata --write-discovery-report --allow-incomplete
python3 scripts/audit_core_api.py --verify-discovery-checkout /absolute/upstream-parent --allow-incomplete
```

Refresh intentionally leaves a stale review lock until explicitly updated; an
integrity-lock update is **not** reviewer approval. Compiler refresh currently
records this Linux development environment; portable compiler-argument discovery
and cross-target/inactive-branch verification remain work. The source parser is
tree-sitter 0.25.2 / tree-sitter-cpp 0.23.4, not the original seed-name regex.
Its annotation blanking preserves byte offsets, but macro spelling inside
definitions and multiple-declarator/operator/template canonicalization remain
limitations. The compiler-to-source matching is a candidate finder, not a proof.

Remaining Ada implementation/mode/test audit work is unchanged in
`unreviewed_scope`. Header-path authentication is complete; **reviewed header
scope, declaration closure and semantic reconciliation are not**.

Continuation verification: **71 audit tests passed** with the pinned refresh
parser environment (36 original plus 35 new discovery/fixture tests). Standard-
library-only runs explicitly skip the four optional parser fixture methods;
hosted audit CI installs the pinned requirements and exercises them separately.
The offline manifest/tree/blob check was independently reproduced against all
four clean source worktrees. The native discovery gate correctly exits 1.
Public documentation generation validated **195 packages / 202 HTML pages**;
all **117 existing documentation-tool tests passed**. `git diff --check` and
protected production-tree comparisons passed. Applicable hosted results are
reported on PR #89 for the pushed continuation HEAD, not inferred from the
previous successful HEAD. No proprietary Scarthgap campaign was rerun.

**Disposition: COVERAGE_AUDIT_BLOCKED. This is an initial evidence snapshot,
not the exhaustive coverage audit requested by CORE-CLOSE-001.**

No production functionality is added. No capability is certified `BOUND_FULL`.
The absence of full classifications means qualification has not been completed;
it does **not** mean the existing binding has no completely implemented families.
Independent review must not interpret successful evidence-integrity CI as audit
acceptance or as a release gate being satisfied.

## Verified baseline and scope

Repository: <https://github.com/zackboll/opencv_core_ada>.
The only configured binding remote is `origin`, with fetch and push URL
`git@github.com:zackboll/opencv_core_ada.git`. `git fetch --all --prune --no-tags`
completed. GitHub repository identity and default branch `main` were queried;
the open PR list was empty when work began.

Fetched `origin/main` exactly matches expected
`64d8a60b59acfe4334045280e430c4774b5cad89`; no advanced baseline to investigate.
The separate `audit/core-close-001` branch/worktree starts at that commit, whose
crate version is **0.5.1**. The pre-existing Core checkout was on an unrelated
corrective branch (0.5.0) and was not used as the audit baseline. The original
Geometry workspace was not modified.

Protected baseline tree identities:

| Path | Git tree SHA |
| --- | --- |
| `src/` | `1391492417e408bd0b5bdc0327a1d659d229feed` |
| `cpp/` | `7b6e6b34cf23e0c635a3e821e5e428bbb78aa7d8` |

Production manifests/actions/dependencies, GPR files, release version and
existing AUnit registrations are unchanged. Release tags, publication and prior
qualification artifacts are untouched. Proprietary Scarthgap qualification is
not rerun for these audit-only changes.

## Authoritative upstream identities

Source was fetched from **`https://github.com/opencv/opencv.git`** into a separate
bare repository, then inspected in sparse, detached Core source worktrees.
Tags were resolved with `^{commit}` and `^{tree}`. Header bytes were checked
against their Git blob identities. Historical absence is retained as `null`,
not filled from a newer release.

| Release | Actual commit | Git tree |
| --- | --- | --- |
| 4.1.0 | `371bba8f54560b374fbcd47e7e02f015ac4969ad` | `b1b20ff9642c0dff4e1788fc6b0148afa06d335f` |
| 4.6.0 | `b0dc474160e389b9c9045da5db49d03ae17c6a6b` | `5f35a9f8f563ec920e2bc1a531f6158fd70f679c` |
| 4.10.0 | `71d3237a093b60a27601c20e9ee6c3e52154e8b1` | `1f7a0c7fcc20571cab11da4c86ae1e796979df5b` |
| 5.0.0 | `40738fb16ceddb5fb3fea747585f7ce6abb0605b` | `d24a3787c9a5a37a4167d1f506e447c7f385d88a` |

[Upstream metadata](core-api-upstream.json) records annotated tag object IDs,
21 selected header paths per release, Git blob hashes, SHA-256 hashes and
commit-pinned links. This verifies source identity, not exhaustive semantic
inspection of all those headers. The 13 named primary targets are included,
along with `optim.hpp`, `ocl.hpp`, `cuda.hpp`, `hal/interface.h`, `cvstd.hpp`,
`softfloat.hpp`, logging and filesystem headers. Internal headers are not treated
as automatically mandatory public binding targets.

Independent identity checks, using a local official-source Git checkout:

```sh
git rev-parse '4.1.0^{commit}' '4.1.0^{tree}'
git ls-tree -r 4.1.0 -- modules/core/include/opencv2
```

Repeat for each exact reference release. These commands do not require trusting
current online documentation. Every representative declaration in the snapshot
links to its pinned commit and line location.

## What the committed inventory establishes

[Coverage JSON](core-api-coverage.json) currently records **26 discovery-seed
families**, all with an explicit preliminary classification. The seed is
**not the discovered closure of portable Core**. An explicit `unreviewed_scope`
list keeps the entire remaining audit visible. Domain A has no seed record yet.

Confirmed distinctions from inspected sources:

| Capability | 4.1.0 | 4.6.0 | 4.10.0 | 5.0.0 | Current finding |
| --- | --- | --- | --- | --- | --- |
| `transposeND` | absent | present | present | present | No established Ada equivalent; ordinary Transpose is 2-D |
| `flipND`, `broadcast` | absent | absent | present | present | Missing Ada modes; older-version fallback unproven |
| Core `divSpectrums` | absent | absent | absent | present | Not the real elementwise Divide operation |
| `finiteMask` | absent | absent | absent | present | Check_Range and scalar Is_Finite are not equivalent |
| Quat / DualQuat headers | absent | present | present | present | Value-type/numerical API research needed |
| AsyncArray header | absent | present | present | present | Presence does not prove portable execution backend |
| Requested version/build/thread/optimization/tick APIs | present | present | present | present | No public Ada equivalents found in inspected spec search |
| General pairwise/relative/squared/Hamming norms | present | present | present | present | General Norm only exposes unary/masked L1/L2/Infinity |
| Batch squared-L2/Hamming/Hamming2 | present | present | present | present | Already represented by K_Nearest_Neighbors; not a missing family |
| Packed CCS transforms/multiplication | present | present | present | present | Already bound with row-wise forms; conversion/division/destinations are separate questions |
| UMat masked Set_To, masked/output Copy_To | present | present | present | present | Existing UMat set is unmasked; copy returns a new result |
| UMat reshape | present | present | present | present | Mat-only Ada profiles; exact overload/version safety review remains open |
| FileStorage append/Base64 flags | present | present | present | present | Not exposed by current storage modes |
| gzip | documented | documented | documented | documented | Build guards and Ada extension validation unresolved |

The JSON contains positive public declaration identities, implementation
fragments, C ABI links where mapped and actual test-source references for bound
records. Test-source presence is recorded independently from implementation.
One test reference does not certify every mode or error branch.

Renamed operations were searched: `gemm` is represented by Matrix_Multiply and
Matrix_Multiply_Add, `batchDistance` by K_Nearest_Neighbors. Existing source also
contains Transposed_Product, Min_Max_Indices, Singular_Value_Decomposition and
Covariance; their complete inventories and qualification remain open. Do not
mark these native families absent based on spelling.

OpenCV 5 additionally defines `CV_16BF`, `CV_Bool`, `CV_64U`, `CV_64S`, and
`CV_32U`, changes `CV_CN_MAX` to 128 and defines a MatShape value with
`MAX_DIMS=10`. The current public channel type permits up to 512, so the
all-version/native conversion policy must be examined, not inferred from Ada
type range alone. These are **source observations still awaiting semantic
inventory records**, not assertions that all corresponding operations are safe.
See the pinned `hal/interface.h` and `mat.hpp` links in the metadata.

## Coverage metrics and honest denominators

The following denominator is **only the 26 preliminary seed records**. It is
not a portable Core completeness metric. Classification percentages total
100% of the seed; discovery coverage is unknown and acceptance is blocked.

| Domain | Seed denominator | Full | Partial | Missing portable | Version-gated | Excluded | Research |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| A — fundamental types/memory | 0 | — | — | — | — | — | — |
| B — dense operations | 5 | 0 | 2 (40%) | 0 | 3 (60%) | 0 | 0 |
| C — linear algebra | 1 | 0 | 1 (100%) | 0 | 0 | 0 | 0 |
| D — spectral | 3 | 0 | 2 (66.7%) | 0 | 1 (33.3%) | 0 | 0 |
| E — statistical/numerical | 3 | 0 | 2 (66.7%) | 0 | 1 (33.3%) | 0 | 0 |
| F — sparse | 1 | 0 | 0 | 0 | 0 | 1 (100%) | 0 |
| G — persistence | 3 | 0 | 1 (33.3%) | 0 | 0 | 1 (33.3%) | 1 (33.3%) |
| H — runtime | 4 | 0 | 0 | 4 (100%) | 0 | 0 | 0 |
| I — additional types | 2 | 0 | 0 | 0 | 2 (100%) | 0 | 0 |
| J — accelerators/async | 4 | 0 | 2 (50%) | 0 | 0 | 0 | 2 (50%) |
| **All seeds** | **26** | **0 (0%)** | **10 (38.5%)** | **4 (15.4%)** | **7 (26.9%)** | **2 (7.7%)** | **3 (11.5%)** |

Requested final metrics **cannot yet be computed** for portable semantic
families, portable mode variants, dense Mat, UMat, SparseMat, persistence,
runtime, Core data types and version-specific additions. Their denominators
need reviewed discovery closure and non-overlapping modes. It would be false
to extrapolate from these seeds. GPU/interop-only APIs must remain a separate
optional denominator and must not lower mandatory portable coverage.

## Schema and reproducibility

The explicit [JSON Schema](core-api-coverage.schema.json) is Draft 2020-12,
versioned by `schema_version`. The standard-library validator implements and
tests the exact subset used by this schema; unsupported schema keywords fail.
It does not silently accept unimplemented JSON Schema features.

Top-level fields identify the binding baseline, semantic-reference fingerprint,
upstream metadata fingerprint, discovery state, unresolved scope and records.
Each record has:

- stable semantic `id` (primary key), `domain`, `native_family`;
- `native_selectors`, four-release `availability`, `upstream` declarations,
  representative signature text, pinned links and observed guard stacks;
- `ada` qualified declaration identity and complete normalized profile,
  including result type; exact text ranges and SHA-256 evidence;
- `implementation` source fragments, explicit `c_abi` mappings and `tests`;
- `variants`, `mode_matrix`, `ownership`, `concerns`, `qualification_gaps`;
- `classification`, `review_complete`, `exclusion_reason`, `priority`,
  `downstream`, `complexity`, `maintenance`.

`PRESENT` describes the native **family** declaration, not that every mode is
valid. In particular the sparse-normalize record does not claim MINMAX support.
`RESEARCH_REQUIRED` is allowed both as a disposition and as an availability
answer when the evidence cannot yet establish availability.

The checked-in [reference](core-api-reference.json) is the manually authored
seed/disposition source. Status or scope changes require an explicit reference
review and evidence regeneration; merely editing the generated JSON fails.

From the audit repository root:

```sh
# Default acceptance gate: currently exits 1 and lists unresolved requirements.
python3 scripts/audit_core_api.py

# Evidence integrity only; success NEVER implies completed audit.
python3 scripts/audit_core_api.py --allow-incomplete
python3 -m unittest discover -s tests/coverage -v

# Optional explicit local refresh. Parent contains upstream-4.1.0, etc.
python3 scripts/audit_core_api.py --refresh /absolute/upstream-parent --allow-incomplete

# Compare a saved prior snapshot without collapsing overloads into bare names.
python3 scripts/audit_core_api.py --allow-incomplete --compare /absolute/old.json
```

Refresh validates official remote URL, exact commit/tree pins, clean Core source
and header Git blobs. It never fetches, downloads, or changes production code.
Normal validation and CI are offline: they need only the committed inventory,
metadata and repository files. SHA-256 checks protect snapshot consistency,
not malicious co-editing of an entire evidence set; independent source review
is still necessary.

### Parsing limitations — material blockers

Ada declaration indexing reuses the repository's declaration-aware GNATdoc
checker, distinguishing complete profiles and package scopes. It is not a full
Ada semantic analyzer. Ambiguous identities fail.

C++ collection removes comments/literals and balances parameter parentheses,
preserves overload signature text and lexical guard stacks. It does **not**
resolve class/namespace scopes, templates, macro-generated APIs, conditional
branch satisfiability, raw strings or all inline definitions. Every collected
declaration explicitly reports representative-only/manual-review uncertainty.
For example, `mat.hpp` setTo/copyTo/reshape extraction includes multiple
classes; it is not automatically UMat-specific evidence. Empty extraction
cannot establish absence. Historical absence findings above were separately
checked in the exact release source.

Consequently the tool does not claim an exhaustive parse or detect arbitrary
new upstream APIs outside its seed selectors. A future refresh prints meaningful
added/removed semantic IDs and changed record evidence, but new declaration
discovery still requires parser improvements/manual review. This limitation
blocks the requested audit acceptance.

## Intentional exclusions proposed for independent review

1. **Sparse MINMAX normalization:** native docs prohibit shifting the implicit
   zero level. Keep explicit sparse-to-dense conversion as the alternative.
2. **Escaping FileNode/iterator wrappers:** retain owning File_Storage navigation
   and copied values rather than add a lifetime-coupled native iterator API.
   Safe semantic iteration is not excluded; existing indexed/map navigation
   must be audited before deciding whether a callback convenience is needed.

CUDA, OpenCL device handles, OpenGL/DirectX/VA interop, allocator hooks and
Algorithm infrastructure have **not** been categorically excluded yet. They
need explicit backend/lifetime/consumer disposition, not a blanket assertion.

## Exact remaining blockers

The authoritative machine-readable list is `unreviewed_scope` in the reference
and coverage JSON. In addition every current record has `review_complete=false`.
Required missing source evidence includes:

- all typed access and fixed helper specs/bodies, including sparse layouts;
- complete Mat/UMat/SparseMat lifecycle, strides, views, external buffers and
  MatShape/channel/depth conversion semantics;
- full arithmetic/comparison/mask/channel/border/statistical mode matrices;
- solve/invert flags, least squares, eigensystems, SVD, PCA/LDA, covariance,
  polynomial and optimization API dispositions and test registrations;
- native DFT/DCT/CCS conversion/division, destination/in-place alias safety;
- RNG variants, kmeans, PSNR, non-finite values and all error-path tests;
- complete FileNode/FileStorage methods, Base64/append enum evidence, gzip
  feature guards, raw formats and lifetime semantics;
- runtime CPU/parallel/error/global-state APIs and callback safety;
- Affine3/Quat/DualQuat/Algorithm/Ptr/softfloat/new-depth semantic records;
- UMat direct mapping, mixed operands, OpenCL controls, async/backend ownership,
  CUDA/Core-adjacent disposition and fallback behavior;
- closure over additional applicable public headers, including definitions
  missed by the representative extractor.

No production defect or feature completion is asserted by this snapshot.
See the [provisional completion roadmap](core-completion-roadmap.md) for finite
review slices, conditional implementation priorities and proposed freeze gates.

## Local regression evidence

Executed in the isolated audit worktree with the configured Alire environment,
GNAT 16.1.0, GPRbuild selected crate 26.0.1 and native OpenCV 4.10.0 on Linux:

- `alr -n build`: successful, existing warnings-as-errors unchanged.
- `alr -n -C tests run`: **2,025 successful tests**, zero failed assertions and
  zero unexpected errors. This is the actual executed AUnit inventory.
- `sh tests/layout/run_controls.sh`: successful, O0/O2 scalar/vector layout and
  Float16 representation/borrowing controls. Generated untracked build output
  was removed; existing sources and qualification artifacts were not changed.
- `python3 -m unittest discover -s tests/coverage -v`: **36 tests passed**,
  including negative evidence/schema/identity/mapping/classification checks,
  representative C++ overload/template/guard fixtures and actual snapshot checks.
- `python3 scripts/audit_core_api.py --allow-incomplete`: successful evidence
  integrity. Default invocation correctly exits 1 with COVERAGE_AUDIT_BLOCKED.
- Explicit official-source refresh succeeded and verified all four pins and
  selected header blob identities. Comparing the snapshot to itself reports
  no added, removed or changed semantic IDs.
- Existing `scripts/generate_docs.sh`, using pinned GNATdoc 26.0.0 and the
  repository's pinned documentation renderer: successful; **195 public packages,
  202 HTML pages** validated, all local links/anchors/assets resolve. Existing
  warning baseline remains unchanged.
- Existing documentation-tool test discovery (`test_*.py` under the scripts
  directory): **117 tests passed**, using the qualified renderer environment.
- `git diff --check`: successful; protected production/public manifests and
  existing test-registration paths have no baseline diff.

Hosted compatibility, native, cross-platform and documentation checks are
reported on the PR, not inferred from prior baseline success. The new hosted
audit workflow intentionally tests **evidence integrity and rejection of
incomplete acceptance**, and is labeled accordingly. Its green status cannot
override the explicit blocked audit disposition.