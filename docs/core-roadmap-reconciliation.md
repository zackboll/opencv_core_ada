# Current Core roadmap reconciliation — CORE-CLOSE-001D

## Current implementation, not forensic completion

Reconciled against main `1d5d8e57feb02d91f596725a4988a274bfd2398c`, tree
`51ad49a7a8518364670a5bf44f4c248cb8a7b010`. **Current crate version:** `0.5.2`.
This is not a new release or a whole-Core qualification. The existing 0.5.2
source tag points to the earlier release merge `aa8a378ab614e9a5fc4f43765cd3ff1bbcf6a44d`;
FIN-02 subsequently landed on main without changing the manifest version.

| Task | Current status | Merged evidence / remaining scope |
| --- | --- | --- |
| CORE-FIN-01 | IMPLEMENTED_IN_MAIN | [PR #90](https://github.com/zackboll/opencv_core_ada/pull/90), fourteen bounded Mat/scalar overloads |
| CORE-FIN-02 | IMPLEMENTED_IN_MAIN | [PR #94](https://github.com/zackboll/opencv_core_ada/pull/94), eight numerical/binary norm profiles |
| CORE-FIN-03 | PLANNED_REQUIRED | Copied native version/build strings; no global setters |
| CORE-OPT-01 | OPTIONAL | Consumer-selected tensor operation or finite mask; native version gates |
| CORE-OPT-02 | OPTIONAL | Timing or explicitly reviewed global controls |
| CORE-OPT-03 | OPTIONAL | Selected UMat destination parity; no GPU execution promise |
| CORE-OPT-04 | OPTIONAL | File append, then Base64 separately; no escaping nodes or gzip qualification |

The [current-status overlay](core-current-status.json) is the machine-readable
counterpart of this table. It does not replace the [24-decision planning ledger](core-portable-scope.json),
its [pinned practical evidence](core-portable-evidence.json), or the original 26
forensic records. Historical `MISSING_CONFIRMED` means missing at the planning
baseline, not missing today. `ready` in that ledger means implementation-ready
scope at that baseline, not present-day unfinished work. Inclusion/exclusion
decisions and the finite optional queue are unchanged. Only FIN-03 remains
required implementation work; audit closure is not its prerequisite.

## Reconciliation ledger

| Concern | Authoritative material already on main | Useful PR #91 intent retained | Duplicate or obsolete component omitted |
| --- | --- | --- | --- |
| 24 practical capability decisions | [Scope JSON](core-portable-scope.json), [human matrix](core-portable-capabilities.md), [source excerpts](core-portable-evidence.json) | Stable IDs, bounded required/optional/research/excluded decisions | Replacement scope schema, renamed decisions and duplicated source observation inventory |
| Original 26 forensic records | [Reference](core-api-reference.json), [coverage](core-api-coverage.json), [report](core-api-coverage.md) | Explicit non-completion and source provenance | Rejecting raw evidence from a checkout that now legitimately contains it |
| Finite backlog | [Existing backlog](core-finish-backlog.md) | Independent required tasks, bounded OPT-01..04 | Parallel backlog; FIN-02-pending constraint |
| Current implementation | Small overlay above, linked merged feature evidence | Separate implementation state from scope decision and historical audit findings | 0.5.1 version lock; FIN-01-only latest qualification |
| Integrity / negative tests | [Existing checker](../scripts/check_core_portable_scope.py), [tests](../tests/coverage/test_core_portable_scope.py) | Strict overlay schema, negative status/completion/version/identity tests, public declaration profiles and Markdown fragments | Second validator and test suite with the same responsibilities; Git-history-dependent standalone workflow |
| Audit locks / provenance | [Artifact policy](core-audit-artifact-policy.md), existing forensic checker and exact blob locks | Durable historical references and honest incompleteness | Open/unmerged-#89 assumption, proposed exclusion of already-merged raw history |
| Documentation / CI | README, existing Core API audit evidence workflow and documentation workflow | Roadmap entry point; source-head checkout for GNAT 12 aggregate controls | Parallel scope workflow; production matrix rewrites (compatibility can dispatch the unchanged workflow at the exact branch head) |

Reviewed predecessor: [PR #91](https://github.com/zackboll/opencv_core_ada/pull/91),
head `94cb2ca74ad150e533019b9a02d8c8921dd8ede7`, based on
`26bf5e2e8151cb0545b928b72d3d87677543c1ae`. No commits were cherry-picked.
Its assumptions predate the merges of #89, #92, #93 and #94. This reconciliation
supersedes its proposal, not its review disposition: PR #91 is left untouched.

## Qualification and provenance boundaries

Merged FIN-02 qualification records **2,052 successful registered tests on each
of OpenCV 4.1, 4.6, 4.10 and 5.0**, zero assertions/unexpected errors. The
[final exact-source report](https://github.com/zackboll/opencv_core_ada/pull/94#issuecomment-6329500097)
and [successful compatibility run](https://github.com/zackboll/opencv_core_ada/actions/runs/39544146897)
identify source `3b71f0edf96b0adad421caa92173a55bd9f10961`, tree
`51ad49a7a8518364670a5bf44f4c248cb8a7b010`.
The [feature record](core-fin-02-qualification.md) and
[corrective investigation](core-fin-02-r1-qualification.md) retain earlier,
explicitly superseded checkpoints. They are not current pending-gate claims.

The earlier [FIN-01 campaign](core-fin-01-r1-qualification.md) with 2,037 tests
remains historical evidence at its own source. Neither campaign establishes
exhaustive OpenCV API coverage. Preserve the eight pre-existing validation-profile
exceptions documented with FIN-01. Windows/MSYS2 and MacPorts remain policy
skips. FIN-02 Scarthgap GNAT Pro 25.2/OpenCV 4.9 and physical target execution
remain **NOT TESTED**; do not carry FIN-01 target results forward to FIN-02.
Apple LeakSanitizer is unsupported; the qualified macOS ASan/UBSan link setup
and recorded failing default-link controls remain explicit in the R1 record.

[PR #89](https://github.com/zackboll/opencv_core_ada/pull/89) merged as
`5aef4d11722aa20b0c8229983afb6d257df5a74f` from source
`a87e9ab241703ce4262dbcd637ab9192536aebe8`. All nine forensic JSON files are
preserved byte-for-byte relative to this reconciliation's starting main.
FIN-02 had already reanchored 35 unchanged Ada excerpts in coverage JSON;
the existing lock `f2d257c522b554e7fb50b15ac8235e64eac98ea7` protects that
merged coordinate-only update. Native identities, hashes, classifications,
empty review approvals and unresolved blockers are not rewritten here.
**UPSTREAM_DISCOVERY_BLOCKED** and **COVERAGE_AUDIT_BLOCKED** remain unchanged.
No large snapshot, archive migration, release, API or ABI change is introduced.

## Overlay validation contract

Schema version 1 has exactly the root/task/qualification fields shown in the
overlay. Unknown/missing fields, duplicate JSON keys, nonfinite values, wrong
types, unknown/duplicate tasks and contradictory status or source identities
fail closed. The reviewed merged states, 0.5.2 manifest, four reference versions,
qualification source/tree/count and public scalar/norm profiles are checked.
Future implementation/status changes require a reviewed overlay/checker/doc/test
update, not an invented `IMPLEMENTED_IN_MAIN` or forensic completion flag.

The single existing practical checker validates the overlay as well as its
original planning/evidence/hash checks. It runs offline with Python's standard
library and no Git history, network, parser or native toolchain requirement;
the already-merged audit files remain intentional dependencies. It checks local
Markdown targets/fragments and Ada declaration references, not external URL
availability. It does not execute production code or certify behavior from a
declaration's presence. Existing forensic and parser CI gates run alongside it.

From the checkout root:

```sh
python3 scripts/audit_core_api.py --allow-incomplete
python3 scripts/check_core_portable_scope.py
python3 -m unittest discover -s tests/coverage -v
git diff --check
```

Parser fixtures additionally require the existing pinned
`tests/coverage/parser-requirements.txt`; a skip is not a parser pass. Hosted
production CI must qualify the replacement's exact final head independently of
these historical feature reports and local documentation/integrity checks.