# CORE-DOC-EXAMPLES-002R1 — qualified consumer mappings

This is consumer adoption of the published enhancer v0.1.5, not enhancer
development. The final PR delivery record identifies the exact final commit/tree
and hosted CI result; local evidence is not hosted qualification.

## Authenticated inputs

* Core source commit: `dbdb410c0d86b640271733d7b999ede5a5f92267`
* Core source tree: `5bcbe86967fea4f718aab96a348fcaef5e8cfe8a`
* Enhancer annotated v0.1.5 tag object:
  `c6ca2b445b089e7f50abc1779d76dd4ff3f0f1eb`
* Published enhancer source: `0120bee2f2455e4c832d1d5ddae0a4cb03cb9477`
* Published enhancer tree: `01900ddb099c801eeb92fba718f4c528f87d865f`
* Wheel: `d712d330f213fc1909a66c47bc2c7e5e15d5ec687222bea3c4922f5243db4247`
* Sdist: `2bc2cc4160a182a2a9b1a4907f47198daabf88883888fa09d736913bd2931079`
* Provenance: `6c30b7a4ec987ab4f74a44d04586dcd57308dd592ac13f33c9444ef3acf0a8f3`
* SHA256SUMS: `93e061866d52e13b6266c6fa0efb3b9c2e3a1bd1b4c818981a11a802ded74756`

All 3,082 published source-file provenance entries were checked against an
immutable Git export. The generator is that export's unmodified
`scripts/generate_verified_examples.py`, SHA-256
`81ff58b5ba014a370dcf0fc6285dd946c4dd0350d59ad9ef5eff43ed4e9e516d`.

| Actual `config/opencv_core_config.gpr` SHA-256 | Mapping | Mapping SHA-256 |
| --- | --- | --- |
| `f405597289217976be3fd42d4b84da66179ebc412dad0f0a8c450861ee42a442` | `debian.json` | `2eeeb283aa0a54113dbeb423653549f13f6238f587c282ab391b9debfc6ba61a` |
| `bed2db88e56f69de7bd437319d8b1ed4086afe24629e423f9afd1fb113b8442b` | `ubuntu.json` | `7ef2b7d4da95909a382661dc2a501556c416241a15f12070fe9b27e81ff23f2e` |

The Debian mapping is unchanged GNATDOC-034/035 evidence. The Ubuntu map is a
fresh generation, not an edited Debian map. `qualification.json` records tool
identities, input comparisons, fresh compilation receipt hash, and semantic/native
equivalence. The disposable Ubuntu 24.04 container used native Ubuntu OpenCV
4.6.0 and its actual generated installation GPR. Debian used OpenCV 4.10.0.
All 27 mapping inputs were compared before generation: only the compiler GPR
distro string differs (`debian` versus `ubuntu`). The generated installation GPR
matches exactly. Actual compiler and runtime Ada dependency hashes also match.

Alire 2.1.1, GNAT 16.1.0, GPRbuild 26.0.0 (Alire release 26.0.1), GNATdoc
26.0.0 (20260415), and Libadalang 26 were authenticated. The analyzer reuses the
retained read-only GNATDOC-031/034 Libadalang 26 shared runtime, with binding bytes
checked against the hash-qualified official 26.0.0 source archive (106 relevant
source files identical). Its Python distribution calls itself `0.1`; that is not
the Libadalang source release number. The analyzer's GNAT 15 shared-library
runtime is separate from GNAT 16.1.0, which freshly compiled Core's example.
No Debian compiler configuration was substituted in Ubuntu.

## Semantic result

Each map accepts four calls and records the known line-9 end-name as unsupported.
Both maps agree on occurrence coordinates, complete profiles (including Create's
precondition), source file/hash, declaration line/column, canonical identity,
GNAT ALI evidence fingerprint and native GNATdoc fingerprint. Only compiler-project
and snapshot provenance legitimately differ.

All destinations are in native package page
`api/6913f2e7169ad4fb9224d4d93fd20e50615a317c7374a7e469bab89cdd6bb7e9.html`:

| Call | Declaration line/column | Native fragment |
| --- | --- | --- |
| `Create` | 1130:13 | `9453fef18922c567cef4a785986626da5ded5225eecc2276f7b7ab8de77d92c6` |
| `Image.Clone` | 1242:13 | `f0d347c5f5d28b39c4b977115b9879f00e12c48a5e95816c85142ade1ea40af1` |
| `Copy.Rows` | 3661:13 | `00f85810953412f15e0bdb21a86dff989020f06dbf58da2dc35eaf46a9a95eab` |
| `Copy.Columns` | 3669:13 | `a6e49bbc3415c1da655a5142bc8e9a9e3d651204a4bb49699636cd0d5941bd50` |

The independent Core oracle selects declarations by reviewed coordinates and
complete source/native profiles, never the first matching name. It reconstructs
the hrefs and original homepage markup. Output metadata cannot authorize links.

## Staging and publication

`scripts/core_verified_examples.py` recognizes only the two actual generated GPR
digests and binds each to one exact mapping/pin. Unknown digests fail closed.
Staging selects the immutable map in `[guides.verified_examples]`; it never modifies
the map or generated GPR. The default authored configuration pins Debian; only the
disposable staged configuration changes to the reviewed Ubuntu map and pin.

Within `obj/docs/enhancer-input`, only `public/` is recursively inventoried: 195
byte-identical public specifications. The 27 compiler inputs retain their original
relative paths, including the two `src/internal/*.ads` files and project files,
outside `public/`. They never become packages or public assets. The separate
`public-generic-qualification.json` changes only the historical qualification's
source path prefix, from `src/` to `public/`; original qualification records remain
unchanged. `api/presentation.json` reflects those exact public source paths.

The source-text manifest, original homepage/example/project, five Markdown guides
and 38 guide Ada fences remain unchanged. There are still two lexical Mat links,
1,293 native sections, 2,758 signature type links, 25 summaries and 1,487 search
records. The site still contains 210 files, without compiler evidence assets.

Authenticated v0.1.4 baseline: exact-main run `41245425725`, artifact
`13059214885`, archive SHA-256
`247967ff696da66ea9d791b4584c4901adabe19c7e691d65a07234911d699334`.
All 210 baseline member hashes match the existing reviewed inventory. Exactly
`index.html` and `api/presentation.json` differ; 208 resources are byte-identical.
Removing just the four authenticated call wrappers restores the prior homepage
bytes. Metadata differs only in version, public source path prefix, staged config
identity and homepage output hash. Debian and Ubuntu sites differ only in the
staged configuration hash in metadata; all rendered files match.

The older authenticated 209-file comparison is also retained: seven historical
authorized changes, one example CSS addition and 202 unchanged resources.
Prior v0.1.4 qualification records and screenshots are not overwritten.

## Qualification and reproduction

The local workspace `/home/zboll/qualifications/core-doc-examples-002r1` retains
full compiler receipts/ALIs, native outputs, source exports, archives, package
inventory, exploratory failures and final logs. Production CI consumes committed
maps without Libadalang or mapping generation. The Ubuntu runner is unchanged.
Pages deployment is restricted to main **push** events, never PRs or manual runs.

Normal consumer build, after installing native prerequisites and selecting tools:

```sh
sh scripts/install_doc_enhancer.sh
sh scripts/generate_docs.sh
.doc-tools/enhancer/bin/python -m unittest discover -s scripts -p 'test_*.py' -v
sh scripts/acquire_core_doc_baseline.sh
.doc-tools/enhancer/bin/python scripts/acquire_core_doc_v014.py
.doc-tools/enhancer/bin/python scripts/compare_core_doc_examples.py
.doc-tools/enhancer/bin/python scripts/gnatdoc_browser_oracle.py
```

The workflow retains all existing Chromium suites and screenshot/security checks.
Examples cover all eight width/theme/JavaScript combinations, 312 native clipboard
copies and 216 keyboard API arrivals, plus 32 mouse activations of the new calls.
Each new arrival checks its actual complete native profile and rejects UMat Clone;
rendered text, highlighting, focus and nonoverlapping/nonnested links are checked.
The original strict homepage pixel test passes in all eight combinations.

The complete local Core documentation Python suite passes **196 tests on Debian
and 196 on Ubuntu**, with zero failures/skips. Navigation, symbols, search,
cross-origin, guides and exhaustive migration browser suites all pass. Fresh
native/site generation repeats byte-identically on each platform; reapplying and
verifying the installed enhancer is byte-idempotent on Debian. Shell syntax,
actionlint, dependency integrity and protected-input checks pass. The separate
`adoption-qualification/` directory retains final logs and machine-readable
comparisons without replacing previous evidence.

Negative tests cover unknown/substituted configurations, map symlinks, stale GPRs,
source hashes and mappings, missing internal inputs, incomplete compiler closure,
modified call coordinates, Mat/UMat substitution, wrong existing native anchors,
and self-rehashed publication metadata. New qualification does not broaden the
historical output allowlist or authorize extra guide links.

Early diagnostic runs are not passes: the first Python run overlapped transient
regeneration; the theme fixture initially lacked newly required compiler inputs;
the old Create mutation initially targeted markup replaced by the new authorized
link. These were corrected and rerun against stable output. An idempotence command
initially supplied a relative site path (resolved under source-root by the CLI);
the corrected absolute-path check is the qualification result. An initial native
run lacked its object directory; the clean rerun has zero warnings and identical
native bytes. The optional research parser run reports 17 passes and one accurately
skipped full private integration; the fresh real Ubuntu generator tests pass all
four controls normally and optimized without skips.