# CORE-DOC-MIG-001 — released documentation toolkit adoption

This is documentation tooling only, not CORE-CLOSE-001E, a release, an index
change, or completion of the exhaustive Core API audit. Crate version **0.5.2**,
the FIN-03 overlay, production sources/projects, ABI, test registrations,
forensic evidence and practical capability decisions are unchanged.

## CORE-DOC-MIG-001R2 — published enhancer v0.1.2 adoption

This follow-up updates the **existing PR #97**, not a replacement PR. The
current installer acquires the official released v0.1.2 wheel only after
verifying independently pinned SHA-256 values for the wheel, checksum manifest
and release provenance. The release provenance must identify source commit
`d7636cc50154ebb5535c699d2bed6406ebc92e62` and tree
`ca7d4d70f2fc556eafe6b222facacadb16fa272a`.

| v0.1.2 release asset | Pinned SHA-256 |
| --- | --- |
| `ada_gnatdoc_enhancer-0.1.2-py3-none-any.whl` | `cb227554bc0c8f1906ba15875306b5fefac103a50d84a876d0fdbd2754e1657e` |
| `SHA256SUMS` | `0d7e16b2e932de982d929049db8bd6039ad39fd9f2a9dd791dc3751a127775b4` |
| `release-provenance.json` | `adc77b4d906f379d71a4d1db2443a529d4fe68e56e2a3c007c591a79f1c16b00` |

The packaged theme stylesheet and instance-navigation JavaScript are
**byte-identical** between toolkit v0.1.1 and v0.1.2 (verified against both
release-tag source blobs). Core has neither custom theme nor external bookmark
opt-ins; its existing approved asset fingerprints remain applicable. The
v0.1.2 default-router restoration feature is not silently reclassified as a
change to Core's instance-navigation contract. The presentation manifest's
enhancer version is expected to change to 0.1.2.

Capture screenshots for desktop/mobile, light/dark, JavaScript on/off in the
existing CI browser evidence directory. Compare relevant snapshots and native
API destinations against the earlier v0.1.1 review baseline. Existing legacy
and v0.1.1 coverage figures below are **historical baseline observations**,
not proof of final v0.1.2 qualification. Complete exact-new-head CI, independent
Core publication-oracle checks, deterministic generation, browser assertions
and visual review before approving a merge. No Pages deployment from this PR.

## Historical CORE-DOC-MIG-001 — original v0.1.1 qualification baseline

## Acquisition and trust

Base: `33a2a4f3b83606a5c779b8a93abeb6c91fa49a21`, tree
`454fb0fa3a128e638a1d7d85f345c7904f296877` (freshly fetched `origin/main`).
No open overlapping PR existed at acquisition. Work is isolated on
`docs/core-gnatdoc-enhancer-migration`; no existing worktree was modified.
The final branch commit/tree are recorded by Git and CI's
`obj/docs/git-identities.txt`, rather than a circular self-commit identity here.

Official release: [ada-gnatdoc-enhancer v0.1.1](https://github.com/zackboll/ada-gnatdoc-enhancer/releases/tag/v0.1.1).
The annotated tag resolves to commit
`dd100f026e13cdd9e97b283d50130241d71bdb9d`, tree
`2873e5f7e0c200ec24a6706610d3bc0527303a7d`.

| Release input | SHA-256 |
| --- | --- |
| `ada_gnatdoc_enhancer-0.1.1-py3-none-any.whl` | `8b896683a65623a7e7d626701a4cd68c8b89cb65792f9ffd5525bfa8cfa257ab` |
| `SHA256SUMS` | `7b508545299c7c84ac5a95ec5a164b4e43cad8620574e02b0c78055c5460179b` |
| `release-provenance.json` | `fd29acd9660b4eea07b88dba493091894badc5b442eaeef2c8ad90741c6c0baa` |

The installer downloads official assets, checks the independently pinned
inventory and wheel hashes, checks inventory consistency and provenance, and
only then installs the wheel non-editably into `.doc-tools/enhancer`. CLI and
distribution versions must both be `0.1.1`; supported Python is 3.11–3.13.
Local qualification uses Python 3.11.17 and CI explicitly selects 3.11.
The only extra dependencies are the unchanged documentation-only
`markdown-it-py==3.0.0` and `mdurl==0.1.2`. No enhancer checkout, source import,
editable install, Alire dependency, or production dependency is used.

## Current-source parity

The unchanged legacy generator was run first. An additional pristine native
generation used exactly its Alire 2.1.1, GNAT 16.1.0, GPRbuild Alire 26.0.1
(banner 26.0.0), GNATdoc 26.0.0 (20260415), public scope and leading comments.
Its diagnostic log matched the legacy generation. Local OpenCV is 4.10.0.
Both enhancers consumed equivalent current-source native bytes, not historical
0.5.0 or pre-FIN-03 qualification output.

| Independently observed property | Legacy | Migrated |
| --- | ---: | ---: |
| Public packages | 195 | 195 |
| Native declaration sections/signatures/anchors | 1,293 | 1,293, unchanged |
| Public type/subtype bookmark destinations | 216 | 216, unchanged |
| Enhanced HTML pages (landing/API/guides) | 202 | 202 |
| Published files | 209 | 207 |
| Type references | 2,755 | 2,758 |
| Vector/Matrix summaries | 24/1 | 24/1 |
| Actual summary links | 102 | 102, same destinations |
| Incoming summary references | 242 | 242, same destinations |
| Fabricated native instance members | 0 | 0 |
| Developer guides | 5 | 5, byte-identical |
| Documentation warnings | 0 | 0 |

The two removed output files are legacy `api/generic-instances.json` and
`api/type-crossrefs.json`. Toolkit `api/presentation.json` replaces the legacy
presentation record; exact inventory checks reject additional files.
The pristine API has 197 files (196 HTML pages plus original CSS).

All legacy link destinations survive after resolving same-page `#fragment`
versus explicit `page.html#fragment` equivalence. The **only three additional
type-link occurrences** are the source-visible parent type `OpenCV.Size` in:

* `Create (Dimensions : Size; Element_Type : Mat_Type) return Mat`;
* `Dimensions (Self : Mat) return Size`;
* `Region_Location.Whole_Size : Size`.

All point to the actual root package's native `Size` declaration, not a guessed
fragment. Current FIN-02/03 inputs do not increase these three occurrences.
`Binary_Norm_Kind` accounts for the current 216 versus historical 215 bookmarks.

## Consumer policy and deliberate differences

[`gnatdoc-enhancer.toml`](gnatdoc-enhancer.toml) explicitly lists all 195 units,
uses verified default `OpenCV.Core`, enables package and native symbol bookmarks,
source-qualified type links, highlighting, responsive light/dark presentation,
reviewed summaries and separately qualified incoming instance references.
External dependency navigation and `external_type_target = "_top"` are absent.
The HTTPS allowlist serves authored links only.

Reviewed current acquisition inputs, generated using the retained independent
Core source/template oracle, are pinned both in TOML and the consumer verifier:

* Generic record: `146a6f6375be14788996e04585ac141bfc308c5be87b040198f5d74c5c74bcfc`.
* Authored manifest: `97a3351cbe0f852d5aeddea64fcffab9f66fdf56499b717caab82d06e9f67b65`.

These bind every public specification and pristine native file, all actual
generic arguments, landing/guide/CSS inputs and referenced source documents.
Generation never refreshes these hashes. `qualify_gnatdoc_enhancer.py` is an
explicit acquisition aid requiring separate review, not a production step.

v0.1.1 scans source directories recursively, while `docs_api.gpr` excludes the
separate `src/internal` project. `stage_gnatdoc_sources.py` therefore makes an
exact public-only input copy at `obj/docs/enhancer-input/src`, preserving original
relative paths and bytes. Original source-backed inventory and hash checks run
before enhancement. This uses the toolkit's supported isolated-source staging
contract, not parser patching or an internal-source publication waiver.

Reviewed presentation changes are:

* Explicit API document language, UTF-8 charset, head and source-qualified titles.
* Consolidated toolkit CSS: different palette, spacing, typography and sidebar
  width; native CSS stays byte-identical. Focus and mobile overflow remain tested.
* Search label/status become “Search documentation”/“No matching documentation.”
* Same-page type links use explicit observed filenames; destinations are unchanged.
* Summary prose adds the qualified instance identity and distinguishes Ada array
  assignment from Mat storage ownership. Matrix multiplication uses an HTML
  character reference. All original arguments, ranges, ownership/Float16 prose,
  introductions and actual member/template/conversion destinations survive.
* Incoming instance links retain the explanatory summary fragment in browser
  history. They never acquire native declaration or public-symbol authority.
* Hidden source-derived symbol metadata moves within the navigation shell and
  uses source declaration order. Native package/tagged links remain unchanged.

## Production and independent gates

Run from the repository root:

```sh
sh scripts/install_doc_enhancer.sh
sh scripts/generate_docs.sh
.doc-tools/enhancer/bin/python -m unittest discover -s scripts -p 'test_*.py' -v
```

Generation preserves toolchain/build/diagnostic/warning gates, generates only
pristine `obj/docs/native/api`, validates source/native inventory, stages a fresh
`_site`, then runs installed `inventory`, dry-run `enhance`, `enhance`, `verify`,
and the independent Core publication validator. It never treats an enhanced site
as fresh native input. Browser suites run afterward as mandatory CI gates.

Duplicate **production execution** of `enhance_gnatdoc_instances.py`,
`install_gnatdoc_theme.py`, `link_gnatdoc_types.py`, `highlight_gnatdoc_ada.py`,
`enhance_gnatdoc_navigation.py`, and `render_gnatdoc_guides.py` is removed.
These files and all their security/integrity tests are **retained** as independent
oracles and synthetic regressions; they are not a second production pipeline.
`validate_docs.py` keeps its public package/content/overload/local-link checks.
`verify_core_enhancer.py` independently reconstructs every declaration, exact
non-snippet native content, links/highlighting, 25 summaries, navigation metadata,
guide bytes and the 207-file publication. It checks reviewed original hashes,
not self-authorizing output metadata. Reviewed toolkit CSS/router hashes are
additional consumer presentation permissions. New mutation tests reject forged
native metadata/counts, wrong-but-existing Size destinations, unlisted files,
symlinks and changed pristine native bytes. Existing mutation tests still run.

The original 117 documentation Python tests passed on legacy and migrated
output; the expanded suite passes 123 tests. Two fresh native/enhanced production
generations compare byte-for-byte; enhancer rerun is byte-idempotent. Warning
delta is zero additions and zero removals. Workflow syntax is actionlint-clean.

Chromium qualification uses independent original-source/pristine-native oracles:
all 195 package destinations, all 25 summary member destinations, all 216 native
symbol bookmarks, the three Size links, real overload/FIN-03 declaration anchors,
search/clear, active package, keyboard focus, invalid/conflicting/unknown query
rejection and clean canonical URLs. It covers 1280px/390px, light/dark and
JavaScript enabled/disabled (query routing itself requires JavaScript).
The retained symbol/navigation/cross-origin suites additionally test native
declaration scrolling, reload, fresh tabs, Back/Forward and stale-offset/BFCache
history restoration. The guide suite visits all five guides, fragments,
cross-links, native API entry points, direct heading bookmarks, reload/new tabs,
Back/Forward, focus and overflow in all eight width/theme/JavaScript combinations.

Detailed local acquisitions, site inventories, independent link reconciliation,
logs, screenshots and browser reports live at
`/home/zboll/qualification/core-doc-mig-001/`. CI retains pristine output,
diagnostics, exact source identities, independent browser oracle/report,
screenshots and release provenance alongside the review site artifact. It checks
exact PR head, deterministic fresh generation, idempotence and unchanged tracked
source. Only main can deploy Pages; PRs publish review artifacts, not Pages.

## Review boundary

Stop at one open, non-draft PR, without approval, merge or auto-merge. Hosted
results belong to the exact PR source head, not a different merge-ref build.
Linux Chromium testing is not cross-browser, screen-reader or complete
accessibility certification. No Pages deployment is attempted from this branch;
deployment is deliberately left to the reviewed main-only workflow. This
migration does not extend Core capability/audit claims or authorize releases.