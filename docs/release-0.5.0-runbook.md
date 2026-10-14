# Final 0.5.0 publication runbook (later task only)

**STOP: these commands are instructions, not publication authorization.**
First require PR #81 successful and merged, and independent authorization for
source publication, tagging and index submission. Do not push the preparatory
branch as the release. Use the local preparation SHA from the external evidence.

## 1. Verify integration and replay only the qualified delta

Set `REPO`, `FINAL_WORKTREE`, `PREP_SHA`, and `APPROVED_MERGED_MAIN_SHA` to
absolute checkout paths / independently verified full commits. Use a new
worktree; never reset a research or PR #81 worktree.

```sh
set -eu
: "${REPO:?absolute existing repository}" "${FINAL_WORKTREE:?new absolute worktree}"
: "${PREP_SHA:?local qualified preparation commit}" "${APPROVED_MERGED_MAIN_SHA:?verified main SHA}"
test "$(gh pr view 81 --repo zackboll/opencv_core_ada --json state --jq .state)" = MERGED
git -C "$REPO" fetch origin main
test "$(git -C "$REPO" rev-parse origin/main)" = "$APPROVED_MERGED_MAIN_SHA"
git -C "$REPO" diff --stat 242299eee7bc1bf98d52b3a1e619dc3552491a94 origin/main
git -C "$REPO" worktree add -b release/0.5.0-final "$FINAL_WORKTREE" origin/main
git -C "$FINAL_WORKTREE" cherry-pick --no-commit "$PREP_SHA"
git -C "$FINAL_WORKTREE" diff --cached --check
git -C "$FINAL_WORKTREE" diff --cached --stat
```

Review all differences from the qualified #81 source, particularly production
and test trees. Do not assume a squash/rebase merge retains #81's SHA. Resolve
conflicts by review, not blindly taking the preparation tree. Refresh wording
that refers to pending #81 integration; do not claim Alire acceptance early.

## 2. Requalify final merged source before committing/pushing

Use a disposable Debian 12 copy with actual dependency resolution, explicit
GNAT 12.2.0 compiler/runtime selection and no inherited object/config state.
Run these in that copy, not through an unrelated host compiler:

```sh
alr -n --force toolchain --select --local gnat_external=12.2.0 gprbuild=18.0.0
alr -n update
alr -n exec -- gnatls -v
alr -n build
OPENCV_CORE_CI=1 alr -n test
ADAFLAGS='-gnatwa -gnatwe' alr -n build --release
alr -n -C tests --force toolchain --select --local gnat_external=12.2.0 gprbuild=18.0.0
alr -n -C tests update
ADAFLAGS='-gnatwa -gnatwe' alr -n -C tests build --profiles=opencv_core=release
OPENCV_CORE_CI=1 alr -n -C tests run
: "${CONSUMER_WORK:?fresh absolute consumer evidence directory}"
CONSUMER_WORK="$CONSUMER_WORK" alr -n exec -- sh tests/gnat12/run_installed_consumers.sh
```

Require 2,025 tests, zero failures/errors, installed/relocated Ada and mixed
execution, `ldd -r` success and GNAT 12 ALI/runtime evidence. Use a fresh
deployment for normal root actions: an explicitly persisted Core development
override intentionally produces eight IEEE errors. Also rerun affected
multi-version/cross or platform checks if merged-source changes warrant them.
Inspect the source archive, license, scripts, links, metadata and dependency
equality; exclude generated config/objects, local evidence, private files and
credentials. Record all logs and the exact tested source identity.

## 3. Commit, verify and publish the exact source commit (authorized later)

```sh
cd "$FINAL_WORKTREE"
git diff --cached --check
git commit -m "Prepare OpenCV Core 0.5.0 release"
RELEASE_SHA=$(git rev-parse HEAD)
test -z "$(git status --porcelain)"
test "$(git show "$RELEASE_SHA:alire.toml" | grep '^version = ')" = 'version = "0.5.0"'
git archive --prefix=opencv_core-0.5.0/ "$RELEASE_SHA" > "${SOURCE_ARCHIVE:?absolute archive filename}"
sha256sum "$SOURCE_ARCHIVE"
```

Requalify the exact committed archive as above and record the tested SHA.
Only after independent release approval, push the final release branch (not
directly over main), confirm remote equality, and tag that same commit:

```sh
git push origin HEAD:refs/heads/release/0.5.0-final
test "$(git ls-remote origin refs/heads/release/0.5.0-final | cut -f1)" = "$RELEASE_SHA"
test -z "$(git ls-remote origin 'refs/tags/0.5.0*')"
git tag -a 0.5.0 "$RELEASE_SHA" -m "OpenCV Core 0.5.0"
test "$(git rev-parse '0.5.0^{commit}')" = "$RELEASE_SHA"
git push origin refs/tags/0.5.0
test "$(git ls-remote origin 'refs/tags/0.5.0^{}' | cut -f1)" = "$RELEASE_SHA"
```

Do not enable auto-merge. Any intervening corrective commit invalidates the
source identity: revalidate and confirm remote equality again before tagging.
Do not move an existing tag. A GitHub release, if desired later, is a separate
authorized operation, not performed by this runbook's preparation task.

## 4. Generate and inspect the real index entry

Alire's temporary deployment needs free disk space. For example, supply an
existing disk-backed `PUBLISH_TMPDIR`; do not delete prior evidence to free it.
Use the final public immutable SHA, without `--skip-build` or automatic submit:

```sh
: "${PUBLISH_TMPDIR:?existing absolute disk-backed temporary directory}"
test -d "$PUBLISH_TMPDIR"
TMPDIR="$PUBLISH_TMPDIR" alr -n publish --skip-submit \
  https://github.com/zackboll/opencv_core_ada.git "$RELEASE_SHA"
GENERATED="$FINAL_WORKTREE/alire/releases/opencv_core-0.5.0.toml"
test -f "$GENERATED"
grep -A4 '^\[origin\]' "$GENERATED"
test "$(grep '^commit = ' "$GENERATED")" = "commit = \"$RELEASE_SHA\""
test "$(grep '^version = ' "$GENERATED")" = 'version = "0.5.0"'
```

Inspect generated metadata/actions/system and Windows dependencies against the
source and external draft. Require the public HTTPS Git origin and final SHA;
do not submit the unresolved draft or the PR/preparation commit. Inspect all
publisher warnings and require its normal build check to pass. Record the
generated entry hash. `--skip-submit` does not require automated PR credentials.

## 5. Submit only the generated manifest for independent index review

Recheck newest stable branch and installed Alire behavior. The observed target
is **stable-1.4.0**, not main/master/devel. Use an existing authorized maintainer
fork and absolute `INDEX_WORKTREE`; credential provisioning is out of scope.

```sh
: "${INDEX_WORKTREE:?absolute maintainer fork checkout}"
: "${MAINTAINER_FORK_OWNER:?authorized maintainer fork owner}"
test "$MAINTAINER_FORK_OWNER" = zackboll
git -C "$INDEX_WORKTREE" fetch upstream stable-1.4.0
git -C "$INDEX_WORKTREE" switch -c release/opencv-core-0.5.0 upstream/stable-1.4.0
cp "$GENERATED" "$INDEX_WORKTREE/index/op/opencv_core/opencv_core-0.5.0.toml"
git -C "$INDEX_WORKTREE" diff --check
: "${INDEX_CHECK_SETTINGS:?new absolute isolated Alire settings directory}"
alr -n -s "$INDEX_CHECK_SETTINGS" settings --global --set index.auto_community false
alr -n -s "$INDEX_CHECK_SETTINGS" index --add "$INDEX_WORKTREE/index" --name candidate
alr -n -s "$INDEX_CHECK_SETTINGS" index --check
git -C "$INDEX_WORKTREE" add index/op/opencv_core/opencv_core-0.5.0.toml
git -C "$INDEX_WORKTREE" commit -m "Add opencv_core 0.5.0"
INDEX_SHA=$(git -C "$INDEX_WORKTREE" rev-parse HEAD)
git -C "$INDEX_WORKTREE" push origin HEAD
test "$(git -C "$INDEX_WORKTREE" ls-remote origin refs/heads/release/opencv-core-0.5.0 | cut -f1)" = "$INDEX_SHA"
gh pr create --repo alire-project/alire-index --base stable-1.4.0 \
  --head "$MAINTAINER_FORK_OWNER:release/opencv-core-0.5.0" \
  --title "Add opencv_core 0.5.0" \
  --body "OpenCV Core 0.5.0; origin commit $RELEASE_SHA. Leave open for independent review."
```

The isolated settings check above targets the actual candidate index; a
configured unrelated community index is not validation of the fork. Inspect
only the intended added manifest, confirm PR
head equals `INDEX_SHA`, and leave it **open and unmerged**, with auto-merge
disabled. Record tested source SHA, pushed source SHA, peeled tag SHA, index
commit and index PR head. Only after index acceptance update "latest indexed"
documentation; an open PR or source tag is not Alire publication.