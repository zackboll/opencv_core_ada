# Core audit artifact retention proposal — CORE-CLOSE-001B

## Current retention disposition — CORE-CLOSE-001D

PR #89 **merged** as `5aef4d11722aa20b0c8229983afb6d257df5a74f`.
Its raw evidence is already part of main's Git history. All sections below are
the **historical pre-merge archival proposal**, not instructions to leave #89
open or to remove its evidence. No archival migration, deletion, regeneration,
history rewrite or change to PR #89 is authorized here. The existing forensic
validator, nine blob locks and negative tests remain mandatory. The separate
[current-status reconciliation](core-roadmap-reconciliation.md) replaces stale
implementation claims without changing historical findings. See the retained
**Git history** discussion below; a **successor PR** cannot remove history
already merged into main.

## Historical proposal (superseded where it assumes an unmerged audit)

**No deletion, compression, overwrite, history rewrite or migration is authorized
by this document.** All existing evidence remains unchanged on PR #89, with
byte-preservation checks. Independent approval is required before a retention or
successor-PR action. No successor PR is created by this task.

## Measured committed sizes

Measured with `git ls-tree -r -l bd60e969e2a2471c1bb4b90d3006e53f3f6e09eb docs`.
Bytes below are exact **uncompressed blob payload sizes**, not Git pack/clone
transfer estimates. Git compression/delta/storage varies; no fabricated pack
savings are claimed.

| Artifact | Bytes | Retention recommendation |
| --- | ---: | --- |
| `docs/core-api-native-declarations.json` | 49,034,268 | Immutable external research snapshot plus hash/pinned reproduction recipe preferred over permanent main history |
| `docs/core-api-compiler-evidence.json` | 18,662,035 | External qualification data: environment/compiler-dependent active-config ledger; retain exact hash/toolchain/arguments and limitations |
| `docs/core-api-header-scope.json` | 2,985,613 | Raw snapshot retained; practical header-family dispositions can be concise permanent documentation, not silent replacement of raw review state |
| `docs/core-api-discovery-blockers.json` | 274,552 | Keep exact raw report with snapshot; concise blocking categories plus durable location index could live on main |
| `docs/core-api-header-manifest.json` | 213,283 | Worth permanently versioning: complete pinned path/blob census and independently recomputable Git tree proofs, low churn |
| `docs/core-api-coverage.json` | 247,126 | Keep source-backed semantic evidence/qualification distinctions; prefer focused records over repeated raw bodies in future design |
| `docs/core-api-reference.json` | 51,199 | Keep stable semantic IDs, decisions and explicit uncertainty; provisional header buckets must not become mandatory API count |
| `docs/core-api-upstream.json` | 31,302 | Keep exact commits/trees/tags/blobs/source links and provenance |
| `docs/core-api-discovery-review.json` | 636 | Keep approvals/locks with the snapshot; empty review lists must not be transformed into approvals during reduction |

The first three artifacts total **70,681,916 bytes** (~70.7 decimal MB). This
does not measure total PR size or unique Git pack size. The native census alone
is ~49.0 decimal MB. Repeated regeneration can add large distinct Git blobs
even when the human-relevant changes are small.

## What should be permanent on main (after approval)

1. Practical portable capability decisions, explicit exclusions/optional scope,
   finite backlog, source links, safety/ownership/version contracts and freeze
   policy; stable semantic IDs, not one record per C++ syntax occurrence.
2. Pinned source identities and complete lightweight header/blob/tree proof.
3. Focused source excerpts for disputed or high-value semantics (e.g. norm
   mask/epsilon semantics), validator/negative tests, exact regeneration tool
   versions and hashes. Keep qualification truth separate from planning readiness.
4. A durable index for any externally retained raw artifact: SHA-256, Git blob,
   originating audit commit, capture command/environment, compression format,
   integrity verification and explicit `UPSTREAM_DISCOVERY_BLOCKED` state.
5. Preserve prior release/qualification artifacts unchanged; never replace
   authoritative evidence with a generated PASS or a summary that hides blockers.

## What is reproducible / what is not yet proven deterministic

- Complete header paths/tree/blob identities reproduce from the exact official
  Git commits and are authenticated offline by the committed Git tree proof.
- Source-CST census generation has pinned tree-sitter packages and byte-offset
  annotation handling; its uncertainties are part of the result. Reproduction
  of an extraction is **not** proof its declarations are complete or classified.
- Compiler census depends on libclang 19.1.7, Linux standard-library/configuration
  environment and active feature guards. Pinned upstream sources alone do not
  reproduce every target's ABI/declarations. Preserve exact environment and
  diagnostics; do not advertise universal byte-identical regeneration.
- New focused practical implementation excerpts come from full pinned Git
  blobs and have checked byte ranges and SHA-256; ordinary offline verification
  needs no OpenCV source download.
- Arbitrary upstream tags/URLs can move or disappear; commits/blob identities
  and retained hashes are essential. A transient hosted CI artifact expiration
  policy is **not** durable preservation. Select archival storage and verify a
  retrieved copy before any raw-file removal decision.

## Reviewable retention procedure

1. Keep PR #89 and every current raw artifact intact while reviewing this
   proposal; do not regenerate existing ledgers merely to shrink them.
2. If external archival is approved, export exact raw bytes with a manifest of
   hashes/commits/tool versions and a retrieval/retention policy. Verify retrieval
   and compare original hashes before proposing a concise main representation.
   Do not publish an unverified archive or transfer private qualification data.
3. Independently review the concise semantic report and its cross-links to raw
   blockers. Preserve unresolved evidence, distinguish optional from excluded
   portable scope, and never imply per-declaration closure from the reduction.
4. Update validation in a separately reviewed migration: forensic snapshot
   checks still run where raw files are retained; lightweight main CI must check
   approved metadata and planning integrity without weakening historical gates.
5. New production feature PRs should contain their relevant source evidence and
   tests, not recapture the entire native C++ AST. No mandatory toolchain/parser
   dependency enters the production Alire crate.

## Git history: why later deletion is not enough

**Removing a large file in a later commit does not remove its Git history from
a subsequently merged PR** when merge strategy retains those commits. A merge
of this branch can retain the 49 MB and 18 MB blobs even if its final tree later
deletes them. A squash is a different history policy, but must not be assumed;
the current task neither rewrites nor selects a merge strategy. Force-pushing
or rebasing published audit history is prohibited here.

**Recommendation for independent approval:** keep PR #89 as the immutable,
open research-review record and prepare a **lightweight successor PR** from
current main containing the approved practical scope/backlog, compact provenance
and scoped validators, with durable references to the archived/raw PR evidence.
Do not merge/cherry-pick the raw-data commits into that successor. Its final
diff/history and archival retrieval must be independently checked. This route
protects main's long-term Git size without pretending the old evidence was
never published. Whether to close #89 as superseded is a later user decision;
this task leaves it open, unmerged and auto-merge disabled.

The first three feature PRs can already start independently on main using the
bounded backlog. They do not need a successor PR or full census closure first.