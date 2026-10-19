"""Practical planning integrity is separate from native/Ada acceptance."""

import copy
from pathlib import Path
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


if __name__ == "__main__":
    unittest.main()