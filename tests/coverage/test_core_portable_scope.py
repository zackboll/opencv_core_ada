"""Practical planning integrity is separate from native/Ada acceptance."""

import copy
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import audit_core_api as audit
import check_core_portable_scope as scope


class PracticalScopeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original_plan = audit.load(ROOT / scope.PLAN)
        cls.original_evidence = audit.load(ROOT / scope.EVIDENCE)

    def setUp(self):
        self.plan = copy.deepcopy(self.original_plan)
        self.evidence = copy.deepcopy(self.original_evidence)

    def check(self):
        return scope.validate(ROOT, self.plan, self.evidence)

    def rehash(self):
        self.evidence["plan_sha256"] = audit.digest(self.plan)

    def test_actual_practical_scope_and_preserved_forensic_snapshot(self):
        self.assertEqual(self.check(), self.plan)

    def test_missing_candidate(self):
        self.plan["candidates"].pop()
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "missing or unreviewed practical candidate"):
            self.check()

    def test_duplicate_id(self):
        self.plan["candidates"].append(copy.deepcopy(self.plan["candidates"][0]))
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "duplicate practical capability"):
            self.check()

    def test_unknown_decision(self):
        self.plan["candidates"][0]["decision"] = "ALL_CPP_SYMBOLS_REQUIRED"
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "invalid practical decision"):
            self.check()

    def test_full_status_cannot_be_invented(self):
        self.plan["candidates"][0]["status"] = "BOUND_FULL"
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "invalid practical decision/status"):
            self.check()

    def test_scope_cannot_clear_native_blockers(self):
        self.plan["upstream_discovery_complete"] = True
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "falsely certifies"):
            self.check()

    def test_missing_rationale(self):
        self.plan["candidates"][0]["reason"] = ""
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "missing practical decision rationale"):
            self.check()

    def test_unpinned_documentation_source_link(self):
        with self.assertRaisesRegex(audit.AuditError, "unpinned practical Markdown"):
            scope.check_document_links(ROOT, scope.DOCUMENTS[0],
                "[source](https://github.com/opencv/opencv/blob/main/modules/core/src/arithm.cpp)")

    def test_broken_documentation_local_link(self):
        with self.assertRaisesRegex(audit.AuditError, "broken practical Markdown"):
            scope.check_document_links(ROOT, scope.DOCUMENTS[0], "[source](no-such-source.ads)")

    def test_optional_feature_not_automatically_required(self):
        self.plan["candidates"][3]["decision"] = "REQUIRED_FOR_0_6"
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "mandatory feature lacks portable"):
            self.check()

    def test_first_three_cannot_be_audit_only(self):
        self.plan["tasks"][0]["kind"] = "AUDIT"
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "first task blocked"):
            self.check()

    def test_first_three_need_no_global_census_prerequisite(self):
        self.plan["tasks"][0]["depends_on"] = ["AUD-07"]
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "unknown/cyclic task prerequisite"):
            self.check()

    def test_first_three_no_cross_task_prerequisite(self):
        self.plan["tasks"][1]["depends_on"] = ["CORE-FIN-01"]
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "first task blocked"):
            self.check()

    def test_ready_task_has_four_version_implementation_evidence(self):
        self.plan["tasks"][1]["source_evidence"] = ["norm-41"]
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "on each version"):
            self.check()

    def test_unknown_version(self):
        self.plan["tasks"][0]["versions"].append("6.0.0")
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "invalid task version"):
            self.check()

    def test_stale_source_excerpt(self):
        self.evidence["sources"][0]["text"] += " altered"
        with self.assertRaisesRegex(audit.AuditError, "source excerpt fingerprint"):
            self.check()

    def test_missing_provenance(self):
        self.evidence["sources"].pop()
        with self.assertRaisesRegex(audit.AuditError, "missing required practical source"):
            self.check()

    def test_wrong_source_commit(self):
        self.evidence["sources"][0]["commit"] = "0" * 40
        with self.assertRaisesRegex(audit.AuditError, "wrong pinned practical source"):
            self.check()

    def test_removed_credited_ada_declaration(self):
        self.plan["local_evidence"][0]["name"] = "Removed_Operation"
        self.rehash()
        with self.assertRaisesRegex(audit.AuditError, "credited Ada declaration"):
            self.check()

    def test_altered_forensic_blob_cannot_be_approved_by_plan(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / next(iter(scope.PROTECTED))
            path.parent.mkdir(parents=True)
            path.write_text("not the historical forensic snapshot")
            with self.assertRaisesRegex(audit.AuditError, "forensic evidence changed"):
                scope.check_preservation(root, {str(path.relative_to(root)):
                                                scope.PROTECTED[str(path.relative_to(root))]})

    def test_reanchored_coverage_blob_remains_exactly_protected(self):
        name = "docs/core-api-coverage.json"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / name
            path.parent.mkdir(parents=True)
            data = (ROOT / name).read_bytes()
            path.write_bytes(data)
            protected = {name: scope.PROTECTED[name]}
            scope.check_preservation(root, protected)
            # Even harmless JSON whitespace must fail the explicit blob lock.
            path.write_bytes(data + b"\n")
            with self.assertRaisesRegex(audit.AuditError, "forensic evidence changed"):
                scope.check_preservation(root, protected)


class CurrentStatusTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.current = audit.load(ROOT / scope.CURRENT)

    def rejected(self, value):
        with self.assertRaises(audit.AuditError):
            scope.validate_current(ROOT, value, documents=False)

    def test_current_overlay_and_all_links(self):
        self.assertEqual(scope.validate_current(ROOT), self.current)

    def test_every_field_has_closed_types_keys_and_values(self):
        # Exercise nested schemas, including bool-as-integer and numeric strings.
        def mutations(value):
            for bad in (None, True, 1, 1.0, "unknown", [], {}):
                if type(value) is not type(bad) or value != bad:
                    yield bad
            if isinstance(value, dict):
                yield dict(value, unreviewed_completion=True)
                for key in value:
                    yield {name: item for name, item in value.items() if name != key}
                    for bad in mutations(value[key]):
                        yield dict(value, **{key: bad})
            elif isinstance(value, list):
                yield value + value[:1]
                for index in range(len(value)):
                    yield value[:index] + value[index + 1:]
                    for bad in mutations(value[index]):
                        yield value[:index] + [bad] + value[index + 1:]
        for index, value in enumerate(mutations(self.current)):
            with self.subTest(mutation=index):
                self.rejected(value)

    def test_no_stale_or_unqualified_task_promotion(self):
        for index, bad in ((0, "PLANNED_REQUIRED"), (1, "PLANNED_REQUIRED"),
                           (2, "IMPLEMENTED_IN_MAIN"), (3, "PLANNED_REQUIRED"),
                           (4, "IMPLEMENTED_IN_MAIN"), (5, "IMPLEMENTED_IN_MAIN"),
                           (6, "IMPLEMENTED_IN_MAIN")):
            with self.subTest(task=index, status=bad):
                value = copy.deepcopy(self.current)
                value["tasks"][index]["status"] = bad
                self.rejected(value)

    def test_historical_qualification_cannot_be_latest(self):
        for key, bad in (("successful_registered_tests", 2037), ("task", "CORE-FIN-01"),
                         ("source", self.current["tasks"][0]["source"]),
                         ("tree", "0" * 40), ("reference_versions", ["4.9.0"])):
            with self.subTest(field=key):
                value = copy.deepcopy(self.current)
                value["latest_feature_qualification"][key] = bad
                self.rejected(value)

    def fixture(self, root):
        # No Git metadata or large forensic snapshots needed for overlay checks;
        # the full CLI separately retains and checks those existing dependencies.
        shutil.copytree(ROOT / "src", root / "src")
        (root / "docs").mkdir()
        for name in (*scope.PLANNING_BLOBS, "alire.toml"):
            shutil.copy(ROOT / name, root / name)

    def test_manifest_and_public_profiles_are_not_just_status_claims(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture(root)
            scope.validate_current(root, self.current, documents=False)
            manifest = root / "alire.toml"
            original = manifest.read_text()
            manifest.write_text(original.replace('version = "0.5.2"', 'version = "0.5.1"'))
            with self.assertRaisesRegex(audit.AuditError, "crate version mismatch"):
                scope.validate_current(root, self.current, documents=False)
            manifest.write_text(original)
            path = root / "src/opencv-core.ads"
            original = path.read_text()
            for name in ("Add", "Compare", "Difference_Norm", "Squared_L2_Norm",
                         "Squared_L2_Difference_Norm", "Hamming_Norm", "Hamming_Pairwise_Norm"):
                with self.subTest(declaration=name):
                    path.write_text(original.replace(f"function {name}", f"function Removed_{name}"))
                    with self.assertRaisesRegex(audit.AuditError, "implemented public Ada profile"):
                        scope.validate_current(root, self.current, documents=False)
            path.write_text(original)
            with (root / scope.PLAN).open("a") as stream:
                stream.write("\n")
            with self.assertRaisesRegex(audit.AuditError, "forensic evidence changed"):
                scope.validate_current(root, self.current, documents=False)

    def test_readable_status_cannot_contradict_overlay(self):
        from unittest.mock import patch
        original_read = Path.read_text
        for document in (scope.CURRENT_DOCUMENT, scope.DOCUMENTS[1]):
            for task in ("CORE-FIN-01", "CORE-FIN-02", "CORE-FIN-03", "CORE-OPT-01"):
                with self.subTest(document=document, task=task):
                    def changed(path, *args, **kwargs):
                        text = original_read(path, *args, **kwargs)
                        if path == ROOT / document:
                            text = text.replace(f"| {task} | {scope.TASK_STATES[task]} |",
                                                f"| {task} | UNQUALIFIED |")
                        return text
                    with patch.object(Path, "read_text", changed):
                        with self.assertRaisesRegex(audit.AuditError, "readable current task status"):
                            scope.validate_current(ROOT)

    def test_markdown_and_ada_fragments(self):
        name = scope.CURRENT_DOCUMENT
        for target in ("core-finish-backlog.md#not-a-heading",
                       "../src/opencv-core.ads#Not_A_Declaration",
                       "../src/opencv-core.ads#Finalize", "../../outside.md"):
            with self.subTest(target=target), self.assertRaises(audit.AuditError):
                scope.check_document_links(ROOT, name, f"[bad]({target})")
        scope.check_document_links(ROOT, name, "[norm](../src/opencv-core.ads#Difference_Norm)")

    def test_readable_version_and_capability_regressions(self):
        from unittest.mock import patch
        original_read = Path.read_text
        cases = [(name, "Current crate version:** `0.5.2`", "Current crate version:** `0.5.1`")
                 for name in (scope.CURRENT_DOCUMENT, scope.DOCUMENTS[0], scope.DOCUMENTS[1],
                              "docs/core-completion-roadmap.md", "README.md")]
        cases.append((scope.DOCUMENTS[0], "**IMPLEMENTED_IN_MAIN**", "**PLANNED_REQUIRED**"))
        for document, before, after in cases:
            with self.subTest(document=document, mutation=after):
                self.assertIn(before, original_read(ROOT / document))
                def changed(path, *args, **kwargs):
                    text = original_read(path, *args, **kwargs)
                    return text.replace(before, after) if path == ROOT / document else text
                with patch.object(Path, "read_text", changed):
                    with self.assertRaises(audit.AuditError):
                        scope.validate_current(ROOT)

    def test_json_and_cli_fail_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            path = root / scope.CURRENT
            for source in ('{"schema_version":1,"schema_version":1}',
                           '{"value":NaN}', '{"value":Infinity}', '{broken',
                           json.dumps(dict(self.current, crate_version="0.5.1"))):
                with self.subTest(source=source[:60]):
                    path.write_text(source)
                    with self.assertRaises(ValueError):
                        scope.validate_current(root)
            run = subprocess.run([sys.executable, str(ROOT / "scripts/check_core_portable_scope.py"),
                                  "--root", str(root)], capture_output=True, text=True, check=False)
            self.assertEqual(run.returncode, 1)
            self.assertNotIn("Traceback", run.stderr)

    def test_cli_from_unrelated_directory_without_git_or_network(self):
        with tempfile.TemporaryDirectory() as directory:
            run = subprocess.run([sys.executable, str(ROOT / "scripts/check_core_portable_scope.py")],
                                 cwd=directory, env={"PATH": directory, "PYTHONNOUSERSITE": "1"},
                                 capture_output=True, text=True, check=False)
            self.assertEqual(run.returncode, 0, run.stderr)
            self.assertIn("24 explicit decisions", run.stdout)
            self.assertIn("FIN-01/02 IMPLEMENTED_IN_MAIN", run.stdout)


if __name__ == "__main__":
    unittest.main()