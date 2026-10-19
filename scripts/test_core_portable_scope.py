"""Disposable, offline positive and negative practical-roadmap fixtures."""

import copy
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import check_core_portable_scope as scope


class PortableScope(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "fresh-checkout"
        self.root.mkdir()
        # Only main files and the new lightweight files; no audit checkout,
        # dependencies, source worktrees, .git objects or developer-local paths.
        for directory in ("src", "docs", "scripts"):
            shutil.copytree(scope.ROOT / directory, self.root / directory)
        shutil.copy(scope.ROOT / "alire.toml", self.root)
        self.plan = scope.load(self.root / scope.LEDGER)

    def rejected(self):
        with self.assertRaises(scope.ScopeError):
            scope.validate(self.root, self.plan)

    def test_fresh_offline_checkout(self):
        self.assertFalse((self.root / ".git").exists())
        self.assertEqual(len(scope.validate(self.root)["capabilities"]), 24)
        run = subprocess.run(
            [sys.executable, str(self.root / "scripts/check_core_portable_scope.py"),
             "--root", str(self.root)], cwd=self.tmp.name, capture_output=True, text=True,
            env={"PATH": str(Path(sys.executable).parent), "PYTHONNOUSERSITE": "1"},
            check=False,
        )
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertIn("14 scalar profiles", run.stdout)

    def test_schema_and_identity_failures(self):
        for field, bad in (
            ("schema_version", 2), ("schema_version", True),
            ("baseline", "0" * 40), ("audit_commit", "0" * 40),
            ("crate_version", "0.6.0"), ("upstream", {}),
            ("supported_versions", ["4.9.0"]), ("documents", []),
            ("discovery_status", "UPSTREAM_DISCOVERY_COMPLETE"),
            ("coverage_status", "ADA_COVERAGE_AUDIT_COMPLETE"),
        ):
            with self.subTest(field=field, bad=bad):
                plan = copy.deepcopy(self.plan)
                plan[field] = bad
                with self.assertRaises(scope.ScopeError):
                    scope.validate(self.root, plan)

    def test_missing_unknown_and_bad_field_types(self):
        for field in self.plan:
            with self.subTest(missing=field):
                plan = copy.deepcopy(self.plan)
                del plan[field]
                with self.assertRaises(scope.ScopeError):
                    scope.validate(self.root, plan)
        self.plan["raw_evidence"] = "docs/core-api-native-declarations.json"
        self.rejected()
        del self.plan["raw_evidence"]
        for field in ("capabilities", "tasks", "observations"):
            for bad in (None, {}, "not an array", [], [None]):
                with self.subTest(field=field, bad=bad):
                    plan = copy.deepcopy(self.plan)
                    plan[field] = bad
                    with self.assertRaises(scope.ScopeError):
                        scope.validate(self.root, plan)

    def test_every_stable_id_required_and_unique(self):
        for field in ("capabilities", "tasks", "observations"):
            for index in range(len(self.plan[field])):
                with self.subTest(field=field, missing=index):
                    plan = copy.deepcopy(self.plan)
                    del plan[field][index]
                    with self.assertRaises(scope.ScopeError):
                        scope.validate(self.root, plan)
            plan = copy.deepcopy(self.plan)
            plan[field].append(copy.deepcopy(plan[field][0]))
            with self.assertRaises(scope.ScopeError):
                scope.validate(self.root, plan)
            plan[field][-1]["id"] = "unknown-new-id"
            with self.assertRaises(scope.ScopeError):
                scope.validate(self.root, plan)

    def test_decisions_statuses_categories_and_tasks_locked(self):
        for index in range(24):
            for field, bad in (
                ("decision", "REQUIRED_FOR_0_6"), ("category", "UNREVIEWED"),
                ("implementation_status", "BOUND_FULL"), ("tasks", ["unknown-task"]),
                ("versions", ["4.9.0"]), ("description", ""),
                ("restrictions", []), ("consumer_value", None), ("provenance", []),
            ):
                with self.subTest(index=index, field=field):
                    plan = copy.deepcopy(self.plan)
                    plan["capabilities"][index][field] = bad
                    with self.assertRaises(scope.ScopeError):
                        scope.validate(self.root, plan)

    def test_required_status_reconciliation(self):
        for index, bad in ((0, "PLANNED_REQUIRED"), (1, "IMPLEMENTED_IN_MAIN"),
                           (2, "IMPLEMENTED_IN_MAIN")):
            for field in ("capabilities", "tasks"):
                with self.subTest(index=index, field=field):
                    plan = copy.deepcopy(self.plan)
                    plan[field][index]["implementation_status"] = bad
                    with self.assertRaises(scope.ScopeError):
                        scope.validate(self.root, plan)

    def test_dependency_errors(self):
        for dependencies in (["unknown"], ["CORE-FIN-02"], ["CORE-OPT-01"],
                             ["CORE-FIN-01", "CORE-FIN-01"], ["CORE-FIN-01"]):
            with self.subTest(dependencies=dependencies):
                plan = copy.deepcopy(self.plan)
                plan["tasks"][1]["depends_on"] = dependencies
                with self.assertRaises(scope.ScopeError):
                    scope.validate(self.root, plan)
        self.plan["tasks"][3]["depends_on"] = ["CORE-OPT-02"]
        self.plan["tasks"][4]["depends_on"] = ["CORE-OPT-01"]
        self.rejected()

    def test_false_full_claim_in_free_text(self):
        self.plan["capabilities"][-1]["description"] = "BOUND_FULL"
        self.rejected()

    def test_no_additional_completion_fields(self):
        self.plan["upstream_discovery_complete"] = True
        self.rejected()

    def test_pinned_source_changes(self):
        for field, bad in (
            ("blob", "0" * 40), ("excerpt_sha256", "0" * 64),
            ("start", True), ("end", -1), ("path", "modules/core/src/other.cpp"),
            ("version", "4.9.0"), ("url", "https://github.com/opencv/opencv/blob/4.x/modules/core/src/norm.cpp"),
        ):
            with self.subTest(field=field):
                plan = copy.deepcopy(self.plan)
                plan["observations"][0][field] = bad
                with self.assertRaises(scope.ScopeError):
                    scope.validate(self.root, plan)
        self.plan["tasks"][1]["observations"].remove("norm-46")
        self.rejected()

    def test_local_declaration_missing_and_comments_not_evidence(self):
        path = self.root / "src/opencv-core.ads"
        source = path.read_text()
        source = source.replace("function Covariance", "function Removed_Covariance")
        path.write_text(source + "\n-- function Covariance\n")
        self.rejected()

    def test_scalar_overload_profile_not_just_name(self):
        path = self.root / "src/opencv-core.ads"
        source = path.read_text()
        old = "procedure Add (Self : Mat; Value : Scalar; Destination : in out Mat);"
        self.assertIn(old, source)
        path.write_text(source.replace(old, "-- " + old, 1))
        self.rejected()

    def test_private_declarations_not_public_evidence(self):
        self.plan["capabilities"][-1]["ada"] = ["src/opencv-core.ads#Finalize"]
        self.rejected()

    def test_implemented_entries_need_local_evidence(self):
        self.plan["capabilities"][-1]["ada"] = []
        self.rejected()

    def test_credited_family_cannot_be_replaced_by_unrelated_declaration(self):
        self.plan["capabilities"][-1]["ada"] = ["src/opencv-core.ads#Add"]
        self.rejected()

    def test_task_malformed_or_missing_contract_reference(self):
        for bad in (None, "", "docs/core-portable-capabilities.md", "docs/core-finish-backlog.md#missing"):
            with self.subTest(bad=bad):
                plan = copy.deepcopy(self.plan)
                plan["tasks"][1]["document"] = bad
                with self.assertRaises(scope.ScopeError):
                    scope.validate(self.root, plan)

    def test_missing_local_and_bad_fragment(self):
        for link in ("docs/missing.md", "docs/core-finish-backlog.md#not-a-heading",
                     "src/opencv-core.ads#Not_A_Declaration", "../outside.md",
                     "/etc/passwd", "file:///etc/passwd", "https://example.org/anything",
                     "https://github.com/zackboll/opencv_core_ada/blob/main/README.md"):
            with self.subTest(link=link):
                plan = copy.deepcopy(self.plan)
                plan["capabilities"][0]["provenance"] = [link]
                with self.assertRaises(scope.ScopeError):
                    scope.validate(self.root, plan)

    def test_symlink_escape(self):
        (self.root / "docs/outside.md").symlink_to(Path(self.tmp.name))
        self.plan["capabilities"][0]["provenance"] = ["docs/outside.md/not-there"]
        self.rejected()

    def test_raw_dependency_even_if_present(self):
        path = self.root / "docs/core-api-reference.json"
        path.write_text("{}")
        self.plan["capabilities"][0]["provenance"] = ["docs/core-api-reference.json"]
        self.rejected()

    def test_unreferenced_raw_artifact_contamination(self):
        (self.root / "scripts/audit_core_api.py").write_text("# unwanted dependency\n")
        self.rejected()

    def test_readable_status_contradiction(self):
        path = self.root / scope.DOCUMENTS[0]
        path.write_text(path.read_text().replace("REQUIRED / IMPLEMENTED_IN_MAIN",
                                                "REQUIRED / PLANNED_REQUIRED"))
        self.rejected()

    def test_markdown_link_is_checked(self):
        path = self.root / scope.DOCUMENTS[2]
        path.write_text(path.read_text() + "\n[broken](does-not-exist.md)\n")
        self.rejected()

    def test_json_duplicate_keys_nonfinite_and_malformed(self):
        path = self.root / scope.LEDGER
        for source in ('{"schema_version":1,"schema_version":1}',
                       '{"value":NaN}', '{"value":Infinity}', '{broken'):
            with self.subTest(source=source):
                path.write_text(source)
                with self.assertRaises(ValueError):
                    scope.validate(self.root)

    def test_cli_failure_is_nonzero(self):
        self.plan["capabilities"].pop()
        (self.root / scope.LEDGER).write_text(json.dumps(self.plan))
        run = subprocess.run([sys.executable, str(self.root / "scripts/check_core_portable_scope.py")],
                             capture_output=True, text=True, check=False)
        self.assertEqual(run.returncode, 1)
        self.assertIn("missing/unknown practical capability", run.stderr)


if __name__ == "__main__":
    unittest.main()