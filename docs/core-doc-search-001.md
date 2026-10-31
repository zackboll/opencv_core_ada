# CORE-DOC-SEARCH-001 — released offline search

## Consumer and dependency authority

Starting `main` was freshly fetched and exactly matched commit
`b6c8582bd5220ab6361357537f4b443477dee678`, tree
`629777ae4a1d56cfd73508145825922928dda608`.

Production documentation installs only the official **v0.1.3 wheel**, in
`.doc-tools/enhancer`; no editable install, enhancer checkout, Alire dependency,
remote search service, or browser runtime dependency is added.

| Release identity | Value |
| --- | --- |
| GitHub release | `429609001` |
| Annotated tag object | `b46644ffaafcdc74f20bb492fe65381425b9d74e` |
| Source commit | `ce117aedc7eeb8c45aafc07dea9357166caadf0d` |
| Source tree | `e87c8500165c119753843f71e34868b7133523d1` |
| Wheel SHA-256 | `f03f20ee4bcb6a918013bac7577300ab2bfb42714c22dc4677139e5359a7bac9` |
| Sdist SHA-256 | `7c7db837b665554b78a0fc78682d58229ce0b21c53a89d8b0eecef0fd7b2c8cf` |
| Provenance SHA-256 | `1f6f0c3dd34fe391977c1dc01d7d2b780cf40f314de4f76e7375aa86f202362d` |
| SHA256SUMS SHA-256 | `80dba07d94b8bc2dc25242e31460a2acc641a3b047459b79ec3aca6d9129d3e5` |
| Configuration SHA-256 | `0a6182e7b042b54bd787305d3fcfc4c9892109d7d3a043105c35340a59f616a0` |
| Unchanged original Core CSS SHA-256 | `fa265d63e73436a6a449fd16011c3db68a5430e7fa6a98ea8eb0fd6821dca9b2` |
| Unchanged landing HTML SHA-256 | `3b859c15dfb85d4f5ab8a88b576f11671e790334c7c773d1c6eac72103abac8f` |

The installer checks the pinned checksum inventory, wheel and provenance bytes,
then provenance version/commit/tree, installed CLI/distribution versions, and
wheel-origin non-editability. Acquisition tests run the actual transport/hash/
provenance gate with isolated substitutions for incorrect or missing assets.

## Search fixture reconciliation (not a relaxed count)

| Category | Released fixture | Existing Core additions | Fresh Core |
| --- | ---: | ---: | ---: |
| Packages | 195 | 0 | 195 |
| Types/subtypes | 215 | 1 | 216 |
| Operations | 1,047 | 24 | 1,071 |
| Developer guides | 5 | 0 | 5 |
| **Total** | **1,462** | **25** | **1,487** |

The fixture in the official v0.1.3 sdist retains an older Core snapshot.
Its `tests/real-fixtures/search-core/oracle.json` SHA-256 is
`0d9d04fceb9769e72fc156cbee69b4f75485e2d837415d67c07c53c61a83cbc9`.
The current hash-qualified Core source/native acquisition already contains
`Binary_Norm_Kind`, scalar arithmetic and comparison overloads, additional norm
operations, and native version/build-information operations. No Ada source or
native qualification baseline is changed by this PR.

`docs/enhancer-qualification/search-reconciliation.json` records the exact 25
additional source/native destinations and excerpts. Its checksum is pinned by
the Core-owned search verifier. It cannot independently authorize a record:
every record is reconstructed through the retained public-source parser and
native signature/anchor reconciliation, and every addition must match that
reconstruction. Subtracting the specifically identified additions must reproduce
the original category counts. Private completions, internal units, generic
formals and unrendered instantiated members are not search destinations.

## Independent publication security

The original source/native oracle and fail-closed mutations remain in place.
The extended oracle imports no enhancer code. It independently checks:

* Approved configuration and original CSS identities, including exact metadata.
* All 195 source/native package identities and 1,293 native declaration sections.
* Complete source-spelled search excerpts, source-order overload numbering,
  kinds, schema, deterministic ordering, unique destinations, and exact JSON bytes.
* Five reconstructed developer guides and their approved destinations/text.
* Exact shell allowlist markup and search digest, derived from reconstructed
  records, never from index-supplied URLs or self-declared hashes.
* Checksum-bound, reviewed search CSS and the composed navigation JavaScript.
  The latter is independently reproduced from the published wheel's shared
  search runtime and instance router (SHA-256
  `68b894257b698bb2e3a7a8bed828af17cd122dcc39b1fe9012e14966beaca88e`).
* Exact publication file inventory, original native bytes, unchanged homepage,
  2,758 native type links, 25 generic summaries, 102 summary links and 242
  incoming references.

Negative tests modify/miss/duplicate/forge records, descriptions, kinds,
overload labels, schemas and destination identities. They rehash the cache,
shell digest and presentation manifest together and still require rejection.
Missing or rehashed assets and extra publication files remain rejected.

Only two publication files are added: `api/gnatdoc-search-index.json` and
`api/gnatdoc-search.css`. Only three pre-existing files change:
`api/gnatdoc-navigation.js`, `api/index.html`, and `api/presentation.json`.
The exact **209-file** name/hash inventory is retained in
`docs/enhancer-qualification/search-publication-inventory.json` (SHA-256
`100af3824ee113bf1e58e166501d3fba2141bdb4386540cf1d768f2df3812851`)
and in the exact-head CI diagnostics. It is evidence, not verifier authority.
Search results are intentional UI changes; the Core
homepage, original CSS, package content and guides are not redesigned.

## Reproduction and browser evidence

From the repository root:

```sh
sh scripts/install_doc_enhancer.sh
sh scripts/generate_docs.sh
.doc-tools/enhancer/bin/python -m unittest discover -s scripts -p 'test_*.py' -v
.doc-tools/enhancer/bin/python scripts/verify_core_enhancer.py --native obj/docs/native
.doc-tools/enhancer/bin/python scripts/validate_docs.py _site
```

The existing workflow installs Playwright 1.64.1/Chromium separately and serves
`_site` over localhost HTTP. It now also runs
`scripts/test_gnatdoc_search_browser.cjs`. The suite checks actual Create/Clone
operations, distinct Create overloads, Mat and qualified Mat symbols, Sparse,
ownership guide destinations, exact ranking/kinds/descriptions, unknown and
malicious input, clear/empty behavior, accessible focus and keyboard controls,
iframe scrolling, canonical URLs, reload, fresh tabs, Back/Forward, and missing,
corrupt, duplicate, cross-origin, unauthorized and wrong-kind cache fallback.
Cross-origin shell authority and tampered result hrefs are rejected too.
Both 1280×900 and 390×900, light/dark and JavaScript-disabled native access are
covered. No external request, runtime exception or page-level horizontal
overflow is accepted.

Observed match counts: Create **70** (first: `OpenCV.Core.Create (overload 1/3)`),
Clone **101** (first: `OpenCV.Core.Clone (overload 1/2)`), Mat **1,224** (first:
`OpenCV.Core.Mat`), qualified Mat **9** (same exact type first), Sparse **162**
(exact package first), ownership **68** (`Ownership and views` first). Matches
include signature/description text; the UI caps displayed results at 50 and
explicitly requests refinement. Every Core Create overload is opened and its
distinct native fragment/visible declaration verified.

The mandatory landing suite compares pixel and geometry/typography metrics in
all eight viewport/scheme/JavaScript cases. Local qualification additionally
uses the downloaded successful `main` publication artifact from run
`40973337638` as `DOC_BEFORE_URL`, served on a second localhost port. That
artifact was byte-identical to a pristine local v0.1.2 regeneration. All eight
comparisons require zero changed pixels and exact original layout, padding,
typography and blue-button preservation. The missing-theme-rule mutation must
still fail the visual gate.

Screenshots and structured `search-browser.json` / `landing-visual.json` are
written under `obj/docs/browser-screenshots` and uploaded by exact-head CI.
Selected local evidence is retained in `docs/search-qualification/`:

* [Mobile dark Create search](search-qualification/screenshots/search-390-dark-Create.png).
* [Desktop ownership search](search-qualification/screenshots/search-1280-light-ownership.png).
* [Unchanged desktop homepage](search-qualification/screenshots/landing-1280-light-js-after.png).
* [Unchanged mobile dark homepage, no JS](search-qualification/screenshots/landing-390-dark-nojs-after.png).

Existing navigation, symbol, cross-origin, migration and five-guide suites
remain mandatory, as do pristine GNATdoc generation, deterministic fresh
regeneration, enhancer idempotence, and independent publication verification.

## Delivery boundary

PR builds remain non-deployable. Only successful trusted main-branch builds
can upload/deploy Pages; the existing **30-day Pages artifact retention** is
unchanged. This task neither merges nor deploys. Exact tested/pushed/PR head,
tree, hosted check results and any pending qualification are reported on the
single open PR; readiness is not inferred from a different head's CI result.