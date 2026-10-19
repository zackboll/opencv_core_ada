# Practical scope schema, version 1

[core-portable-scope.json](core-portable-scope.json) is a standalone UTF-8 JSON
object. The normative executable schema and cross-record constraints are in
[check_core_portable_scope.py](../scripts/check_core_portable_scope.py), using
Python standard library only. Unknown keys, duplicate JSON keys, nonfinite JSON
numbers, invalid types, missing fields and contradictions fail closed. This is
not an upstream API census or an implementation certification.

## Root fields

- `schema_version`: integer 1 (not boolean).
- `baseline`, `audit_commit`: exact reviewed Git commits.
- `crate_version`: 0.5.1, not a proposed release.
- `discovery_status`: UPSTREAM_DISCOVERY_BLOCKED.
- `coverage_status`: COVERAGE_AUDIT_BLOCKED.
- `supported_versions`: ordered four reference releases, not every supported
  build/platform: 4.1.0, 4.6.0, 4.10.0, 5.0.0.
- `upstream`: release-to-full-commit map.
- `documents`: the four roadmap/schema Markdown files, all local links checked.
- `observations`: compact selected source identities for remaining work.
- `tasks`: finite task records with ID, implementation status, dependency IDs,
  supported `versions`, source observation IDs and backlog `document` link.
- `capabilities`: exactly the 24 preserved practical decision IDs.

## Capability records

Every record has `id` (stable, unique), `description` (semantic capability),
`category` (PORTABLE, OPTIONAL or NATIVE_SURFACE), `decision`,
`implementation_status`, nonempty `versions` subset, `ada` declaration links
(empty only when none is credited), `consumer_value`, `restrictions`,
`provenance` (local documents or pinned source-review links), and `tasks` IDs.
`ada` links are checkout-relative `path.ads#Declaration_Name`; they resolve only
to declarations in the public portion of that spec, after Ada comments are
removed. Scalar profiles additionally check all fourteen exact overloads.
Presence is not full native-family/mode/test coverage.

Decisions are REQUIRED, ALREADY_SUFFICIENT, OPTIONAL_LATER, DEFERRED_RESEARCH and
INTENTIONALLY_EXCLUDED. Implementation states are IMPLEMENTED_IN_MAIN,
PLANNED_REQUIRED, OPTIONAL, RESEARCH_REQUIRED, INTENTIONALLY_EXCLUDED and
EXISTING_LIMITED. The two fields are deliberately separate: scalar-modes remains
REQUIRED while its status is implemented; optional missing subsets remain
OPTIONAL, never a hidden required blocker. This version locks each reviewed
decision/status/category/task mapping; a future change requires explicit review
of the ledger, readable docs, executable schema and negative tests together.

Tasks have only IMPLEMENTED_IN_MAIN, PLANNED_REQUIRED or OPTIONAL states.
FIN-01 is implemented, FIN-02/03 remain pending and independent, and OPT-01..04
are optional. Dependencies must exist, be unique, non-self and acyclic; required
tasks cannot depend on optional work. FIN-02/03 each retain four-version source
observations. Exact bounded contracts and review prerequisites live in the
linked [backlog](core-finish-backlog.md), not copied native source text.

## Source observations and links

Each observation has unique `id`, `version`, relative upstream `path`, positive
inclusive `start`/`end` lines, full Git `blob`, 64-hex `excerpt_sha256`, and `url`
matching the pinned release commit/path/start line. Hashes identify the selected
text in the original audit evidence, **not whole-file content**. Exact reviewed
identities are locked by the checker; without downloading text it cannot verify
upstream bytes. No network/source checkout is needed or implied.

Local document links must remain inside the checkout, exist, and resolve heading
or Ada-declaration fragments. HTTPS upstream blob/tree links must use known full
commit pins; source-review links use the exact audit commit. Ordinary PR links
are issue provenance, not unpinned source evidence. Network availability is not
tested by the offline checker. No local raw research artifact may be linked or
required, even if a developer happens to have it untracked.

Run from any working directory:

```sh
python3 scripts/check_core_portable_scope.py
python3 -m unittest discover -s scripts -p 'test_core_portable_scope.py' -v
```

Paths above are repository-relative commands. The checker also accepts `--root`
for a separate fresh checkout. Tests build disposable fixtures from only files
referenced by this lightweight schema, never the original audit checkout. They
exercise malformed inputs, false completion, identity/decision/status changes,
dependency cycles, declarations/links/pins and raw-artifact contamination.