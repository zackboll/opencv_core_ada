# CORE-CLOSE-001: Core API coverage evidence — INCOMPLETE

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
- `git diff --check`: successful; protected production/public manifests and
  existing test-registration paths have no baseline diff.

Hosted compatibility, native, cross-platform and documentation checks are
reported on the PR, not inferred from prior baseline success. The new hosted
audit workflow intentionally tests **evidence integrity and rejection of
incomplete acceptance**, and is labeled accordingly. Its green status cannot
override the explicit blocked audit disposition.