# Public Ada API documentation

The specifications in `src/` are authoritative. The generated site is intended
for `https://zackboll.github.io/opencv_core_ada/`; its landing page is
`_site/index.html` and the native GNATdoc reference is `_site/api/index.html`.
Do not commit generated HTML.

## Reproduce on Linux

Required qualification versions:

| Tool | Release / executable version |
| --- | --- |
| Alire | 2.1.1 |
| GNAT Native | Alire `gnat_native=16.1.0`, executable GNAT 16.1.0 |
| GPRbuild | Alire `gprbuild=26.0.1`, executable 26.0.0 (2026-04-15) |
| GNATdoc | Alire `gnatdoc_bin=26.0.0`, executable 26.0.0 (20260415) |

Also install a supported native OpenCV development library, pkg-config,
a C++ compiler, POSIX shell and Python 3.9 or newer (standard library only).
The authoritative OpenCV compatibility policy is in the
[README](../README.md). Local qualification used OpenCV 4.10.0; documentation
CI uses Ubuntu 24.04's native OpenCV package. No documentation or testing
dependencies are added to the library manifest.

```sh
alr -n --force toolchain --select gnat_native=16.1.0 gprbuild=26.0.1
sh scripts/generate_docs.sh
```

Run from a checkout; the script itself locates the repository root. It installs
the pinned binary GNATdoc crate into `.doc-tools/gnatdoc-26.0.0` when absent.
Alire verifies the binary archive against the index's SHA-256. An existing
installation can be reused without reinstalling:

```sh
GNATDOC_PREFIX=/tmp/doc-001-gnatdoc-26 sh scripts/generate_docs.sh
```

The script builds `opencv_core.gpr` through Alire to resolve dependencies and
generate its normal supported configuration. It then invokes:

```sh
alr exec -- "$GNATDOC_PREFIX/bin/gnatdoc" -P docs_api.gpr \
  --backend html --generate public --style leading --warnings -O "$PWD/_site/api"
python3 scripts/validate_docs.py _site
```

`docs_api.gpr` uses production compiler switches, publishes only `src/`, and
excludes the configuration and `docs_internal.gpr` projects. Internal sources
remain available to Libadalang for resolution. These projects do not import
the production project: importing it while redeclaring its public sources
would violate GPR source ownership. The normal library projects, ABI, source
comments and dependencies are unchanged. Tests and applications are not
built for documentation generation.

Output is deleted before each generation. Full diagnostics are retained in
`obj/docs/gnatdoc.log`, not published. `--warnings` stays enabled. Generation
errors, partial-generation diagnostics, absent public package pages, and broken
local links fail the build.

Historical documentation warnings are measured, not suppressed. After a
successful GNATdoc run, `scripts/compare_gnatdoc_warnings.py` compares
`obj/docs/gnatdoc.log` with `docs/gnatdoc-warning-baseline.txt`. The baseline
stores one identity per warning:

```text
filename: enclosing scope: normalized declaration signature: warning: message
```

The signature is the complete Ada declaration with comments removed and
whitespace normalized. A semicolon inside a parameter list does not end it, so
a function identity keeps its return profile. The enclosing scope is the
package, nested package, generic formal, or record that contains the
declaration. Two identical profiles in different scopes, and two record
components with the same name, remain different warnings. Source line and
column numbers are used only to find that declaration in the current `src/`
tree. A pure line shift, comment edit, or reordering of the log matches. A warning that moves
from one declaration to another is an addition and fails the build, even when
the filename, column, and message text are unchanged.

Every warning must map to exactly one declaration. An unmapped location, two
declarations with the same normalized profile, or a warning-shaped diagnostic
that is not the pinned GNATdoc 26.0.0 `file:line:column: warning:` form fails
the comparison. Ordinary non-warning log text is ignored. Removed warnings are
printed and do not fail the build. Do not silence a warning with `@exclude`,
an empty comment, or a changed generator invocation.

The current baseline contains 4,395 identities. It was 4,484 raw warnings on
main `53c14c469b22ba1c608836d9a16c0947e2c80323`, 4,460 after documenting the
six polar record-destination overloads, and 4,395 after documenting the shared
`OpenCV` value types and the `Fixed_Matrices` and `Vectors` generic foundations
(65 warnings removed, none added). Regenerate it only from a complete pinned
GNATdoc 26.0.0 log and the sources of that same revision:

```sh
python3 scripts/compare_gnatdoc_warnings.py --write-baseline \
    docs/gnatdoc-warning-baseline.txt obj/docs/gnatdoc.log
```

Do not replace the baseline with a raw copy of the log. Old line numbers do
not remain attached to the same declaration after later comment edits.

### Remaining warning backlog

Counts below are the 4,395 baseline warnings, grouped by GNATdoc category:

| Category | Warnings |
| --- | ---: |
| Undocumented parameter | 2,988 |
| Undocumented entity | 887 |
| Undocumented return | 356 |
| Undocumented component | 75 |
| Undocumented enumeration literal | 89 |

By public package family:

| Family | Warnings |
| --- | ---: |
| `OpenCV.Core` typed `*_mat_view` packages | 1,245 |
| `OpenCV.Core` (`opencv-core.ads`) | 1,237 |
| `OpenCV.Core` typed `*_access` packages | 890 |
| `OpenCV.Core` typed `*_row_access` packages | 554 |
| `OpenCV.Core` typed `*_buffer_access` packages | 208 |
| `OpenCV.Core.Sparse` | 101 |
| `OpenCV.Core.Persistence` | 100 |
| Fixed-size value instances | 25 |
| `OpenCV.Core.Module_Interop` | 15 |
| `OpenCV.Core.Sparse` typed children | 8 |
| Typed conversions | 7 |
| `OpenCV.Core.Transfers` | 5 |

Recommended cleanup order, one family per review:

1. `OpenCV`, `OpenCV.Core.Fixed_Matrices` and `OpenCV.Core.Vectors` (done).
2. `OpenCV.Core` operations in `opencv-core.ads`, where prose often exists but
   parameters and returns still lack `@param` and `@return`.
3. `Persistence`, `Sparse`, `Transfers`, and `Module_Interop`.
4. One typed-access generic pattern (`Get`/`Set`, row, buffer, then mat view),
   applied consistently to its instances rather than documented one depth at a
   time with copied text.


## Coverage and qualified limitations

The initial build documents all 195 public specification packages, including
`OpenCV`, `OpenCV.Core`, `Transfers`, `Persistence`, `Sparse`, typed scalar/vector
access, row/buffer access and scoped views, and the fixed-matrix/vector generic
foundations and instances. `Mat`, `UMat`, `Sparse_Mat`, arithmetic and matrix
operations are present. Public module-interoperability packages in `src/` are
intentionally included; unsupported `OpenCV.Internal` units and generated
configuration are excluded. Private completions, bodies and C/C++ files are
not published.

GNATdoc 26 parses this repository's Ada 2022 declarations, controlled public
views, overload signatures, discriminated records and generic formal parts.
GNATdoc 26.0.0 attaches documentation for enumeration literals through
`@enum` (`@value` is not recognized) and for generic formals through `@formal`
in the generic unit's leading comment block. Inline comments between generic
formals render, but do not satisfy the generic-formal warning. Overloads have
distinct native anchors. Generic instantiations link to their
generic template rather than duplicating every instantiated declaration.
The native index provides a flat, fully qualified compilation-unit list and
tagged-type links, not a collapsible hierarchy. Package filenames are native
hashes; do not depend on handwritten package filenames. Package coverage is
checked against actual specifications, not a fixed count.

Existing comments mix leading and trailing styles. Generation uses **leading**
because most long public policy comments precede declarations. Some historical
trailing comments therefore do not attach to the intended entity. No comments
are deleted or mass-migrated. The current run has 4,395 undocumented-entity
warnings. This is not evidence that declarations are missing: validation checks
the pages and representative declarations separately. No unsupported public
declaration was identified in the inspected representative pages; this is not
a claim that every comment or cross-reference is semantically perfect.

GNATdoc `--version` prints to stderr and exits 1 in this exact release; version
checking handles that quirk explicitly. Generator execution must still succeed.
Local URL validation checks file references and HTML anchors, including native
CSS, and rejects filesystem/root-absolute local links so repository-relative
hosting works. External website availability is not tested. No custom JavaScript,
analytics or second documentation generator is used.

## Comment convention for future PRs

Use adjacent **leading** `--` comments for new public declarations. Do not
insert a blank line between a documentation block and its declaration. Use
GNATdoc's `@param`, `@return` and `@exception` annotations where appropriate;
names must match the actual Ada declaration. For example:

```ada
--  Return an independent copy of the source matrix.
--  @param Self Source matrix, borrowed for this call.
--  @return A matrix with independent pixel storage.
--  @exception OpenCV_Error Native allocation or OpenCV failure.
function Clone (Self : Mat) return Mat;
```

For every new API, describe package purpose, parameter units/ranges, result
meaning, exceptions and rejection conditions. State ownership and lifetimes,
including `Mat`/`UMat`/`Sparse_Mat` assignment aliasing versus explicit deep copy,
view/callback lifetime restrictions, overlap restrictions and native-library
safety limitations. Document relevant OpenCV version constraints and examples
when helpful. Do not imply that native failures provide rollback unless the
API promises it. Preserve existing comments; migrate only focused comments
when reviewing the affected API. A new public declaration must not add a
GNATdoc warning: the documentation workflow fails when the warning baseline
grows. Generate documentation and inspect rendering in the PR artifact. The
specification remains the source of truth, not a second handwritten API manual.

## CI and Pages review gate

`documentation.yml` runs for PRs targeting main, pushes to main, and manual
dispatch. PR jobs have only `contents: read`, generate and validate the site,
and upload a review artifact plus diagnostics. They never configure or deploy
Pages and do not receive Pages/OIDC write permissions.

Only trusted `refs/heads/main` runs upload a Pages artifact. A separate job,
dependent on successful generation, uses `actions/deploy-pages` with
`pages: write`, `id-token: write`, and the `github-pages` environment. Main runs
share a cancel-in-progress concurrency group so superseded publication runs
are cancelled. Manual runs on other branches can validate but cannot publish.
No PAT or `gh-pages` branch is needed.

Repository owner prerequisite: **Settings → Pages → Build and deployment →
Source: GitHub Actions**. Configure the `github-pages` environment's deployment
branch policy to allow **main only**. These settings are intentionally left to
the owner. The Pages API returned 404 during qualification; no existing Pages
configuration or public deployment was assumed. After merge, verify the successful
deployment and the live URL, including navigation and CSS under
`/opencv_core_ada/`. Feature-branch qualification is not public deployment evidence.

## Local qualification record

Starting main: `e0d505103fd69a16b863f409c7c451ac5bce993c` (PR #57 merge).
The existing compatibility workflow succeeded on that exact SHA.

Commands run in the isolated DOC-001 worktree:

```sh
alr -n build
alr -n test
GNATDOC_PREFIX=/tmp/doc-001-gnatdoc-26 sh scripts/generate_docs.sh
python3 scripts/validate_docs.py _site
sh -n scripts/generate_docs.sh
alr exec -- gnatformat --check -P docs/example.gpr docs/example.adb
alr exec -- gprbuild -P docs/example.gpr
obj/docs-example/example
git diff --check
```

The existing build succeeded; AUnit reported 2024 successful tests, zero failed
assertions and zero unexpected errors. Generation produced 195 public package
pages, a native API index and CSS (197 HTML pages including the landing page).
All local links/anchors/assets resolved. No production source, test source,
production project, dependency or release metadata was changed.
The landing-page example was compiled with assertions and warnings-as-errors
and executed successfully. ShellCheck 0.11.0 and actionlint 1.7.12 validated
the script and new workflow; GNATformat 26.0.0 formatted the example.
A copied-site negative test with `api/gnatdoc.css` removed was correctly
rejected with missing-asset and broken-link errors. Generated HTML was scanned
for local filesystem paths and common credential markers; none were found.