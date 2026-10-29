# CORE-DOC-VIS-001 — original Core landing presentation

## Scope and independently reviewed identities

Fetched `origin/main` before editing: `15d3ff37ed67283e906cc50da3f54c0608ac16f3`.
Branch: `corrective/core-doc-vis-001`. No runtime source, API prose, landing HTML,
original CSS, guide input, native acquisition record, toolkit release, or
navigation JavaScript changes.

The released v0.1.2 wheel remains checksum/provenance-qualified by the unchanged
installer. The custom theme uses the **existing original Core file**, not a CSS
copy or a toolkit default:

| Input | SHA-256 |
| --- | --- |
| `docs/assets/gnatdoc-theme.css` | `fa265d63e73436a6a449fd16011c3db68a5430e7fa6a98ea8eb0fd6821dca9b2` |
| `docs/gnatdoc-enhancer.toml` | `7ede7b535e69a2015fd0d64ccdb40b755f86d51c06bc53e7021d10525ebe1156` |
| unchanged `docs/index.html` | `3b859c15dfb85d4f5ab8a88b576f11671e790334c7c773d1c6eac72103abac8f` |

CSS and landing HTML were compared byte-for-byte with pre-migration Core
`33a2a4f3b83606a5c779b8a93abeb6c91fa49a21`. This is the original Core reference,
**not enhancer v0.1.1**. The independent publisher oracle pins the configuration
and CSS separately from generated metadata, requires exactly the documented
`theme_source` fields, and retains all native/semantic/file inventory checks.
The released toolkit continues to validate safe CSS and source/config identities.

## Visual qualification

Playwright **1.64.1**, Chromium **156.0.8078.4**, Linux. Viewports: **1280×900** and
**390×900**; light/dark; JavaScript on/off (eight cases). Screenshots are full-page,
with separate keyboard-focus captures. `landing-visual.json` records every measured
bounding box, computed typography, resource response, contrast ratio, layout delta,
browser version and pixel difference. All eight corrected captures match original
Core **exactly: zero changed pixels and identical measured layout**.

Before captures use a pristine native regeneration of starting main with the
released bundled theme. After captures use a separate pristine native regeneration
with the custom-theme configuration. Comparing those complete publications finds
**only** `api/gnatdoc-theme.css` and `api/presentation.json` changed.

| Viewport / scheme | Changed pixels before → after | Fraction of comparison canvas |
| --- | ---: | ---: |
| desktop / light | 1,104,303 | 60.8847% |
| desktop / dark | 1,104,125 | 60.8749% |
| mobile / light | 457,524 | 61.6468% |
| mobile / dark | 457,280 | 61.6139% |

JavaScript-on/off results are identical. Pixel comparison uses the union of the
two full-page canvases (desktop 1280×1417, mobile 390×1903), counting missing pixels
as transparent black. Diff images show changed pixels red and unchanged green.

Actual geometry changes:

* Desktop main: 1280px wide at x=0, no padding → **1024px at x=128**, **48px**
  left/right padding; content starts at x=176.
* Mobile main: 390px wide, no padding → **390px with 19.5px** left/right padding.
* API link: unpadded inline text, 221.77×19px → **288.97×51.98px inline-block**,
  colored background, 8px radius, weight 650. Keyboard Tab selects it first;
  a 3px visible outline passes 3:1 contrast and Enter opens the API browser.
* Lead: **19.2px**; original uppercase eyebrow, heading sizing, and wrapping footer
  restored. Full-page height becomes 1416.77px desktop / 1902.77px mobile.
* Text/eyebrow/button contrast: light **14.08 / 6.29 / 7.23:1**; dark
  **14.29 / 8.51 / 9.04:1**. All exceed 4.5:1.
* No page-level horizontal overflow, missing resources, failed requests, browser
  errors, CSS imports or CSS subresources. One local stylesheet responds HTTP 200.

Representative comparisons:

| Case | Before | After | Pixel diff |
| --- | --- | --- | --- |
| desktop light / JS | [before](screenshots/landing-1280-light-js-before.png) | [after](screenshots/landing-1280-light-js-after.png) | [diff](screenshots/landing-1280-light-js-diff.png) |
| mobile dark / no JS | [before](screenshots/landing-390-dark-nojs-before.png) | [after](screenshots/landing-390-dark-nojs-after.png) | [diff](screenshots/landing-390-dark-nojs-diff.png) |

The new browser gate is wired into the existing documentation PR workflow.
It renders the existing hash-approved original CSS as a separate reference and
compares actual output pixels and metrics. It also removes the landing-specific
rules in an isolated browser interception and requires that regression to fail
the layout qualification in every case. No publication files are mutated.

## Functional qualification and reproduction

All generations build the library first, then run GNATdoc 26.0.0 with the existing
public/leading scope under Alire 2.1.1, GNAT 16.1.0, GPRbuild 26.0.1. Zero warnings;
reviewed native acquisition hashes match. Preserved: **195 packages, 1,293 native
declarations, 216 bookmarks, 25 summaries, 102 summary links, 242 incoming
references, and five developer guides**; 2,758 native type links and exact
publication inventory remain independently verified.

* All **130** existing/new consumer Python tests pass, including publication,
  metadata, source/config/CSS mutations and native acquisition rejection.
* All **30** released custom-theme tests pass against the installed wheel,
  including unsafe CSS, encoding, path/symlink substitutions and forged hashes.
* Two fresh corrected native/output trees compare byte-identically. Re-enhancing
  the already enhanced output also compares byte-identically. Released `verify`
  and independent `validate_docs.py` / native verifier pass.
* Existing Chromium navigation, symbols, cross-origin history, migration and
  five-guide suites are run in addition to the eight-case landing gate.

The guide browser test now waits for native fragment arrival after navigation
and reload, matching the existing migration test. An initial mobile run exposed
its immediate post-reload visibility race. The wait does not scroll the target,
change guide bytes, or relax the in-viewport requirement.

Primary commands (from this worktree, with the qualified GNATdoc prefix):

```sh
DOC_BOOTSTRAP_PYTHON=python3.11 sh scripts/install_doc_enhancer.sh
sh scripts/generate_docs.sh
.doc-tools/enhancer/bin/python -m unittest discover -s scripts -p 'test_*.py' -v
.doc-tools/enhancer/bin/python scripts/validate_docs.py _site
.doc-tools/enhancer/bin/python scripts/verify_core_enhancer.py --native obj/docs/native
```

For the browser suite, use the existing workflow's Playwright install and HTTP
server setup. Run `test_gnatdoc_landing_browser.cjs` with `DOC_URL` set to the
homepage; optionally set `DOC_BEFORE_URL` to the independently regenerated starting
main site to collect before/after deltas. Other suites retain their original
commands. All evidence paths are build/test artifacts, not publication inventory.

An initial exploratory Python run overlapped site regeneration and failed while
copying transient output. It is not qualification evidence. The retained
`python-tests-stable.log` is the complete uncontended passing rerun.

Hosted CI status and exact final commit/tree are reported on the single open PR;
the PR workflow cannot deploy Pages. No merge, deployment, or release is authorized.