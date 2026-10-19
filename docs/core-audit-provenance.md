# Core audit provenance and non-completion disposition

This PR integrates the practical completion roadmap, not the unfinished exhaustive audit.

## Origin and independent review

Original [audit PR #89](https://github.com/zackboll/opencv_core_ada/pull/89)
remains **OPEN, UNMERGED**, at source review commit
`a87e9ab241703ce4262dbcd637ab9192536aebe8`. This successor is independently
introduced from main `26bf5e2e8151cb0545b928b72d3d87677543c1ae`, not a merge,
cherry-pick, rebase or copy of the audit history. Local Git objects are not proof
of imported ancestry: inspect objects reachable from the successor HEAD.

Selected source documents at that exact commit:

- [Practical capabilities](https://github.com/zackboll/opencv_core_ada/blob/a87e9ab241703ce4262dbcd637ab9192536aebe8/docs/core-portable-capabilities.md)
- [Finite backlog](https://github.com/zackboll/opencv_core_ada/blob/a87e9ab241703ce4262dbcd637ab9192536aebe8/docs/core-finish-backlog.md)
- [Artifact policy](https://github.com/zackboll/opencv_core_ada/blob/a87e9ab241703ce4262dbcd637ab9192536aebe8/docs/core-audit-artifact-policy.md)
- [Practical scope](https://github.com/zackboll/opencv_core_ada/blob/a87e9ab241703ce4262dbcd637ab9192536aebe8/docs/core-portable-scope.json)
- [Supporting source evidence](https://github.com/zackboll/opencv_core_ada/blob/a87e9ab241703ce4262dbcd637ab9192536aebe8/docs/core-portable-evidence.json)
- [Old dependent checker](https://github.com/zackboll/opencv_core_ada/blob/a87e9ab241703ce4262dbcd637ab9192536aebe8/scripts/check_core_portable_scope.py)

Each of the 24 decision IDs was reviewed against main. All inclusion decisions
and optional/excluded boundaries are retained. `REQUIRED_FOR_0_6` is normalized
to `REQUIRED` without declaring a release. Scalar-modes changes from missing to
IMPLEMENTED_IN_MAIN based on merged [PR #90](https://github.com/zackboll/opencv_core_ada/pull/90).
Confirmed missing optional subsets are recorded as OPTIONAL with their missing
scope explicit, not promoted to required. Research becomes RESEARCH_REQUIRED;
excluded becomes INTENTIONALLY_EXCLUDED. Existing limited families stay limited.
Old dependency/preservation checks are replaced, not imported. No raw source
excerpts, parser dependencies or forensic workflow are needed by the new checker.

## Four pinned upstream sources

These identify the reference releases, not every intermediate release/platform:

| OpenCV | Commit | Repository tree |
| --- | --- | --- |
| 4.1.0 | [371bba8f54560b374fbcd47e7e02f015ac4969ad](https://github.com/opencv/opencv/tree/371bba8f54560b374fbcd47e7e02f015ac4969ad) | `b1b20ff9642c0dff4e1788fc6b0148afa06d335f` |
| 4.6.0 | [b0dc474160e389b9c9045da5db49d03ae17c6a6b](https://github.com/opencv/opencv/tree/b0dc474160e389b9c9045da5db49d03ae17c6a6b) | `5f35a9f8f563ec920e2bc1a531f6158fd70f679c` |
| 4.10.0 | [71d3237a093b60a27601c20e9ee6c3e52154e8b1](https://github.com/opencv/opencv/tree/71d3237a093b60a27601c20e9ee6c3e52154e8b1) | `1f7a0c7fcc20571cab11da4c86ae1e796979df5b` |
| 5.0.0 | [40738fb16ceddb5fb3fea747585f7ce6abb0605b](https://github.com/opencv/opencv/tree/40738fb16ceddb5fb3fea747585f7ce6abb0605b) | `d24a3787c9a5a37a4167d1f506e447c7f385d88a` |

Compact FIN-02/03 source observations in the [ledger](core-portable-scope.json)
retain pinned blob URLs, line intervals, Git blob IDs and SHA-256 of the **old
selected excerpt text**, not whole-file hashes. No excerpt is copied. Offline
validation checks identities and consistency, not remote source bytes. Feature
authors must inspect the actual pinned declarations/implementations, including
dispatch and omitted paths, before implementation.

## Header discovery and declaration census: still blocked

The audit authenticated complete pinned header-path/tree/blob manifests, but
**path enumeration is not semantic discovery or binding coverage**. Counts below
are historical audit observations, not a denominator for Ada completeness:

| Reference | Header paths | Reviewed header dispositions | CST occurrences | CST blockers | Compiler occurrences | Unmatched compiler occurrences |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 4.1.0 | 113 | 0 | 9023 | 644 | 5910 | 2262 |
| 4.6.0 | 141 | 0 | 9783 | 697 | 6541 | 2468 |
| 4.10.0 | 149 | 0 | 9861 | 676 | 6630 | 2513 |
| 5.0.0 | 145 | 0 | 10261 | 698 | 6984 | 2297 |

Original audit disposition remains **UPSTREAM_DISCOVERY_BLOCKED** and
**COVERAGE_AUDIT_BLOCKED**. Review lists for headers, exclusions and independent
compiler reconciliation were empty. Zero compiler errors in the captured Linux
configuration are not universal discovery success. Major gaps include macro,
conditional, overload/template and inline reconciliation; provisional family
assignments/exclusions; platform/backend/header dispositions; and per-mode
Ada/shim/test/ownership/negative-path qualification. The original 26 semantic
inventory records are not the 24 practical decisions and are not reduced to a
new exhaustive inventory here. No completeness percentage is claimed.

## Raw historical locations and retention

All paths below are in `docs/` at the original audit commit above, accessible
with `git show a87e9ab241703ce4262dbcd637ab9192536aebe8:docs/<filename>` or
the [pinned historical docs tree](https://github.com/zackboll/opencv_core_ada/tree/a87e9ab241703ce4262dbcd637ab9192536aebe8/docs).
They are **references only**, not successor checkout dependencies.

| Historical filename | Bytes | Git blob |
| --- | ---: | --- |
| core-api-native-declarations.json | 49,034,268 | `7a0f5c82a7f531c440e9ca3093924538bef4792c` |
| core-api-compiler-evidence.json | 18,662,035 | `49a81301c0b4391a95ff9b1c52f7d44ad861b15f` |
| core-api-header-scope.json | 2,985,613 | `1fc4cdf21e06b8e9c186e96a47b97f6497aacb74` |
| core-api-discovery-blockers.json | 274,552 | `47116f1da39c5ea14b8163c4042c80c1ee441a69` |
| core-api-header-manifest.json | 213,283 | `eeb25bcc0ddb690b9cba1b0dffee4ba87c6528a5` |
| core-api-coverage.json | 247,126 | `10ee2d8f8a0cda9aa992357582b59ae6195bd21a` |
| core-api-reference.json | 51,199 | `1e001ddc4c0689c6c1945d2bee8a0ea96784a36b` |
| core-api-upstream.json | 31,302 | `3f403310b9f3be3cfc626eb7d3cabb8ac82d89d9` |
| core-api-discovery-review.json | 636 | `dc208b0ae3965d95203cd6ad0a1973fe209fff98` |

The first three total **70,681,916 bytes**, uncompressed blob payload, not pack
size or clone-transfer savings. They and the AST/parser/blocker ledgers are not
introduced into successor Git history. Deleting them in a later commit would
not remove earlier reachable blobs; this is why an independent main-based
successor is used.

**PR #89's branch is not a guaranteed permanent archival service.** Before any
future removal of that branch or historical references, separately authorize
durable archival: exact bytes, SHA-256 and Git blob/commit manifest, capture
commands, compiler/libclang 19.1.7/configuration and pinned CST-tool versions,
limitations, retention/retrieval policy and a verified retrieved copy. Source
path proofs are reproducible; active compiler evidence is environment-dependent
and must not be represented as universally deterministic. Expiring hosted CI
artifacts are not durable storage. No external archival/upload, deletion,
rewrite, closure or change to PR #89 is performed or authorized by this task.
Private SDK/compiler files must never be included. A future archival decision
requires separate authorization.

The practical plan can be accepted independently while the exhaustive audit
remains blocked. See the [backlog](core-finish-backlog.md) for the two remaining
required tasks and the [scope](core-portable-capabilities.md) for explicit limits.