# CORE-DOC-SEARCH-001 local evidence

See `../core-doc-search-001.md` for release identities, search-fixture
reconciliation, security authority, reproduction commands and publication
inventory. The PR records exact commit/tree and hosted CI separately so evidence
does not claim to contain its own Git identity.

Environment: Linux, Python 3.13.5, Alire 2.1.1, GNAT 16.1.0,
GPRbuild Alire release 26.0.1, GNATdoc 26.0.0 (20260415),
Playwright 1.64.1, Chromium 156.0.8078.4. Production documentation uses the
checksum-verified official v0.1.3 wheel; Markdown dependencies stay isolated.

* `python-tests.log`: complete stable consumer Python documentation run.
* `generation.log`: initial pristine v0.1.3 generation and independent checks.
* `determinism.log`: second pristine native/site generation, recursive
  byte comparisons, enhancer idempotence, released verification and independent
  source/native/publication verification.
* `navigation-browser.log`: retained navigation suite, four viewport/theme
  combinations plus JavaScript-disabled native navigation.
* `existing-browsers.log`: symbol, cross-origin history, independent browser
  oracle, eight migration combinations and eight guide combinations.
* `search-browser.json`: four functional viewport/theme combinations, seven
  fault-injection scenarios, and four JavaScript-disabled native fallbacks.
* `landing-visual.json`: eight pixel-exact original/v0.1.2 comparisons with
  computed layout, typography, contrast, focus and missing-rule rejection.
* `screenshots/`: representative search UI and unchanged homepages. All captures
  are also generated in `obj/docs/browser-screenshots` for hosted CI artifacts.

The v0.1.2 baseline was downloaded from the successful main publication build
40973337638, exact source b6c8582bd5220ab6361357537f4b443477dee678, and matched a
pristine local regeneration byte-for-byte. Eight before/after homepage captures
had **zero changed pixels** and identical geometry/style metrics. Search UI
changes are intentional and are not subject to that pixel-parity requirement.

An exploratory final Python run accidentally overlapped site regeneration and
copied transient/missing `_site` files. That failed run is not qualification
evidence. The retained Python log is the subsequent complete stable rerun;
regeneration and generated-site tests must be serialized. CI already runs those
steps serially. No assertion was weakened for this execution-order error.

The exact 209-file output hash inventory is
`../enhancer-qualification/search-publication-inventory.json`. It is evidence,
not a replacement for independent reconstruction. No native API HTML, guide,
landing HTML, original theme, Ada/C++ source or ABI is changed. PR builds cannot
deploy Pages, Pages artifact retention remains 30 days, and no merge or
auto-merge is authorized.