"""Fail-closed evidence and negative acceptance tests; no native dependencies."""

import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
SPEC = importlib.util.spec_from_file_location(
    "audit_core_api", ROOT / "scripts/audit_core_api.py")
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)


class InventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.snapshot = audit.load(ROOT / "docs/core-api-coverage.json")
        cls.reference = audit.load(ROOT / "docs/core-api-reference.json")
        cls.provenance = audit.load(ROOT / "docs/core-api-upstream.json")

    def setUp(self):
        self.data = copy.deepcopy(self.snapshot)
        self.ref = copy.deepcopy(self.reference)
        self.upstream = copy.deepcopy(self.provenance)

    def validate(self, complete=False):
        return audit.validate(ROOT, self.data, self.upstream, self.ref, complete)

    def reconcile_reference(self):
        """Tests may simulate a reviewed transition without bypassing semantics."""
        generated = {"ada", "upstream", "implementation", "tests"}
        self.ref["capabilities"] = [
            {key: value for key, value in item.items() if key not in generated}
            for item in self.data["capabilities"]]
        self.data["reference_sha256"] = audit.digest(self.ref)

    def reconcile_declaration_manifest(self):
        self.upstream["declaration_manifest_sha256"] = audit.digest(
            {item["id"]: item["upstream"] for item in self.data["capabilities"]})
        self.data["provenance_sha256"] = audit.digest(self.upstream)

    def bound(self):
        return next(item for item in self.data["capabilities"]
                    if item["classification"] == "BOUND_PARTIAL")

    def test_actual_snapshot_evidence(self):
        self.assertEqual(self.validate(), self.data)

    def test_actual_snapshot_blocks_completion(self):
        with self.assertRaisesRegex(audit.AuditError, "COVERAGE_AUDIT_BLOCKED"):
            self.validate(complete=True)

    def test_duplicate_ids(self):
        self.data["capabilities"].append(copy.deepcopy(self.data["capabilities"][0]))
        with self.assertRaisesRegex(audit.AuditError, "duplicate stable"):
            self.validate()

    def test_missing_provenance(self):
        del self.data["provenance_sha256"]
        with self.assertRaisesRegex(audit.AuditError, "missing required"):
            self.validate()

    def test_invalid_version_assignment(self):
        self.data["capabilities"][0]["availability"]["4.2.0"] = "PRESENT"
        with self.assertRaisesRegex(audit.AuditError, "unknown field"):
            self.validate()

    def test_incomplete_versions(self):
        del self.data["capabilities"][0]["availability"]["4.1.0"]
        with self.assertRaisesRegex(audit.AuditError, "missing required"):
            self.validate()

    def test_unknown_classification(self):
        self.data["capabilities"][0]["classification"] = "PASS"
        with self.assertRaisesRegex(audit.AuditError, "invalid enum"):
            self.validate()

    def test_removed_ada_declaration_identity(self):
        self.bound()["ada"][0]["identity"] += "_Removed"
        with self.assertRaisesRegex(audit.AuditError, "removed or ambiguous Ada"):
            self.validate()

    def test_removed_ada_overload_signature(self):
        self.bound()["ada"][0]["signature"] += "_Removed"
        with self.assertRaisesRegex(audit.AuditError, "removed or ambiguous Ada"):
            self.validate()

    def test_missing_local_source(self):
        self.bound()["implementation"][0]["path"] = "src/no-such-file.adb"
        with self.assertRaisesRegex(audit.AuditError, "missing or unsafe local"):
            self.validate()

    def test_path_escape(self):
        self.bound()["implementation"][0]["path"] = "../outside-audit-root.ads"
        with self.assertRaisesRegex(audit.AuditError, "missing or unsafe local"):
            self.validate()
        with self.assertRaisesRegex(audit.AuditError, "missing or unsafe local"):
            audit.local_path(ROOT, "../../../../../../etc/passwd")

    def test_missing_bound_mapping(self):
        self.bound()["implementation"] = []
        with self.assertRaisesRegex(audit.AuditError, "lacks positive implementation"):
            self.validate()

    def test_removed_unreviewed_scope(self):
        self.data["unreviewed_scope"] = []
        with self.assertRaisesRegex(audit.AuditError, "unresolved required scope"):
            self.validate()

    def test_missing_ada_selector_evidence(self):
        self.bound()["ada"] = self.bound()["ada"][:1]
        with self.assertRaisesRegex(audit.AuditError, "missing selected Ada"):
            self.validate()

    def test_missing_c_abi_mapping(self):
        self.bound()["c_abi"] = ["opencv_core_no_such_function"]
        self.reconcile_reference()
        with self.assertRaisesRegex(audit.AuditError, "missing C ABI"):
            self.validate()

    def test_invalid_status_transition(self):
        self.bound()["classification"] = "MISSING_PORTABLE"
        with self.assertRaisesRegex(audit.AuditError, "invalid status transition"):
            self.validate()

    def test_unresolved_required_entry(self):
        self.data["capabilities"] = self.data["capabilities"][:-1]
        self.reconcile_declaration_manifest()
        with self.assertRaisesRegex(audit.AuditError, "uncategorized"):
            self.validate()

    def test_changed_upstream_fingerprint(self):
        self.upstream["versions"]["4.1.0"]["tree"] = "0" * 40
        with self.assertRaisesRegex(audit.AuditError, "upstream inventory fingerprint"):
            self.validate()

    def test_changed_declaration_fingerprint(self):
        self.data["capabilities"][0]["upstream"]["4.6.0"]["declarations"][0][
            "signature"] += " changed"
        with self.assertRaisesRegex(audit.AuditError, "upstream declaration inventory"):
            self.validate()

    def test_rehashed_wrong_upstream_pin(self):
        self.upstream["versions"]["4.1.0"]["tree"] = "0" * 40
        self.data["provenance_sha256"] = audit.digest(self.upstream)
        with self.assertRaisesRegex(audit.AuditError, "changed upstream pin"):
            self.validate()

    def test_missing_header_provenance(self):
        del self.upstream["versions"]["4.1.0"]["headers"][audit.HEADERS[0]]
        self.data["provenance_sha256"] = audit.digest(self.upstream)
        with self.assertRaisesRegex(audit.AuditError, "missing upstream header"):
            self.validate()

    def test_changed_reference_fingerprint(self):
        self.ref["capabilities"].pop()
        with self.assertRaisesRegex(audit.AuditError, "reference fingerprint"):
            self.validate()

    def test_false_full_coverage(self):
        self.bound()["classification"] = "BOUND_FULL"
        self.reconcile_reference()
        with self.assertRaisesRegex(audit.AuditError, "false full-coverage"):
            self.validate()

    def test_full_cannot_have_missing_modes(self):
        item = self.bound()
        item.update(classification="BOUND_FULL", review_complete=True,
                    qualification_gaps=[])
        item["mode_matrix"] = [{"name": "relative", "state": "MISSING",
                                "evidence": "not implemented"}]
        self.reconcile_reference()
        with self.assertRaisesRegex(audit.AuditError, "false full-coverage"):
            self.validate()

    def test_false_missing_when_bound(self):
        self.bound()["classification"] = "MISSING_PORTABLE"
        self.reconcile_reference()
        with self.assertRaisesRegex(audit.AuditError, "contradictory missing"):
            self.validate()

    def test_missing_upstream_declaration(self):
        item = self.data["capabilities"][0]
        item["upstream"]["4.6.0"]["declarations"] = []
        self.reconcile_declaration_manifest()
        with self.assertRaisesRegex(audit.AuditError, "missing required upstream"):
            self.validate()

    def test_absent_version_with_declaration(self):
        item = self.data["capabilities"][0]
        item["upstream"]["4.1.0"]["declarations"] = copy.deepcopy(
            item["upstream"]["4.6.0"]["declarations"])
        self.reconcile_declaration_manifest()
        with self.assertRaisesRegex(audit.AuditError, "contradicts absence"):
            self.validate()

    def test_changed_local_fingerprint(self):
        self.bound()["implementation"][0]["sha256"] = "0" * 64
        with self.assertRaisesRegex(audit.AuditError, "stale source evidence"):
            self.validate()

    def test_shifted_local_coordinates_with_unchanged_text_and_hash(self):
        # Reproduce the stale Norm anchor after the scalar-mode merge. A valid
        # identity/text/hash does not authenticate a different source location.
        entry = self.bound()["ada"][0]["source"]
        entry["start"] -= 1
        entry["end"] -= 1
        with self.assertRaisesRegex(audit.AuditError, "stale source evidence"):
            self.validate()

    def test_changed_local_text_with_unchanged_coordinates_and_hash(self):
        self.bound()["ada"][0]["source"]["text"] += " -- stale"
        with self.assertRaisesRegex(audit.AuditError, "stale source evidence"):
            self.validate()

    def test_malformed_or_incomplete_json(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bad.json"
            for text in ('{', '{"a": 1, "a": 2}', '{"x": NaN}'):
                path.write_text(text)
                with self.subTest(text=text), self.assertRaises(audit.AuditError):
                    audit.load(path)
        with self.assertRaisesRegex(audit.AuditError, "missing required"):
            audit.validate(ROOT, {}, self.upstream, self.ref, False)

    def test_unknown_schema_keyword_not_silently_ignored(self):
        with self.assertRaisesRegex(audit.AuditError, "unsupported schema"):
            audit.schema_check({}, {"oneOf": []})

    def test_schema_is_json_serializable(self):
        self.assertEqual(json.loads(json.dumps(self.data)), self.data)


class ParserBoundaryTests(unittest.TestCase):
    def test_cpp_overloads_and_guard(self):
        source = """namespace cv {
#ifndef DEMO_HPP
#define DEMO_HPP
#ifdef HAVE_FEATURE
CV_EXPORTS void operation(int n);
CV_EXPORTS void operation(double n, int flag = 0);
#else
CV_EXPORTS void other();
#endif
#endif
}
"""
        entries = audit.cpp_declarations(source, "operation")
        self.assertEqual(len(entries), 2)
        self.assertNotEqual(entries[0]["signature"], entries[1]["signature"])
        self.assertEqual(entries[0]["guards"], ["#ifndef DEMO_HPP", "#ifdef HAVE_FEATURE"])
        self.assertIn("manual scope", entries[0]["parse"])

    def test_comments_and_strings_do_not_create_declarations(self):
        source = '// operation(int n);\nconst char *s = "operation(int n);";\n'
        self.assertEqual(audit.cpp_declarations(source, "operation"), [])

    def test_template_remains_explicitly_uncertain(self):
        entries = audit.cpp_declarations(
            "namespace cv {\ntemplate<class T> T operation(T n);\n}", "operation")
        self.assertEqual(len(entries), 1)
        self.assertIn("representative-only", entries[0]["parse"])

    def test_macro_indirection_does_not_claim_exhaustive_parse(self):
        self.assertEqual(audit.cpp_declarations("DECLARE_API(operation)", "operation"), [])

    def test_ada_overloads_have_distinct_profiles(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "demo.ads"
            path.write_text("package Demo is\n"
                            "   function F (X : Integer) return Integer;\n"
                            "   function F (X : Float) return Float;\n"
                            "end Demo;\n")
            entries = [item for item in audit.ada_index(path) if item["name"] == "F"]
            self.assertEqual(len(entries), 2)
            self.assertNotEqual(entries[0]["signature"], entries[1]["signature"])


if __name__ == "__main__":
    unittest.main()