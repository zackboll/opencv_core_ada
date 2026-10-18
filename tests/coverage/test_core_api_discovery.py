"""Independent header authentication and fail-closed discovery regression tests."""

import copy
import hashlib
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import audit_core_api as api
import core_api_discovery as discovery


class GitTreeProofTests(unittest.TestCase):
    def test_known_git_empty_tree(self):
        self.assertEqual(discovery.git_tree_hash([]),
                         "4b825dc642cb6eb9a060e54bf8d69288fbee4904")

    def test_tree_payload_uses_git_not_json_hashing(self):
        blob = hashlib.sha1(b"blob 1\0x").hexdigest()
        payload = b"100644 a.h\0" + bytes.fromhex(blob)
        expected = hashlib.sha1(b"tree " + str(len(payload)).encode() + b"\0" + payload).hexdigest()
        self.assertEqual(discovery.git_tree_hash([["100644", blob, "a.h"]]), expected)

    def test_detail_directory_not_blanket_excluded(self):
        category, reason = discovery.classify(discovery.PREFIX + "core/detail/async_promise.hpp")
        self.assertNotIn(category, discovery.EXCLUDED)

    def test_hal_depth_types_not_blanket_excluded(self):
        category, reason = discovery.classify(discovery.PREFIX + "core/hal/interface.h")
        self.assertNotIn(category, discovery.EXCLUDED)

    def test_backend_not_counted_as_portable(self):
        category, reason = discovery.classify(discovery.PREFIX + "core/cuda.hpp")
        self.assertEqual(category, "BACKEND_PUBLIC")

    def test_private_headers_have_explicit_reason(self):
        category, reason = discovery.classify(discovery.PREFIX + "core/utils/trace.private.hpp")
        self.assertIn(category, discovery.EXCLUDED)
        self.assertTrue(reason)

    def test_dual_quaternion_not_mapped_to_quaternion(self):
        family, _ = discovery.family_for("header", "cv::DualQuat::normalize", "method", [])
        self.assertEqual(family, "core.types.dual-quaternion")

    def test_renamed_gemm_uses_existing_seed(self):
        family, _ = discovery.family_for("header", "cv::gemm", "function", [])
        self.assertEqual(family, "core.linear.gemm")

    def test_guards_preserve_inactive_branches(self):
        guards = discovery.guard_lines("#ifdef FLAG\nvoid a();\n#else\nvoid b();\n#endif")
        self.assertEqual(guards[2], ["#ifdef FLAG"])
        self.assertEqual(guards[4], ["#ifdef FLAG / #else"])

    def test_annotation_offsets_preserved(self):
        original = b"CV_EXPORTS_W void f(int n);\nCV_WRAP_AS(g) int h();"
        prepared, edits = discovery.prepare(original)
        self.assertEqual(len(prepared), len(original))
        self.assertEqual(prepared.count(b"\n"), original.count(b"\n"))
        self.assertTrue(edits)
        self.assertIn(b"void f(int n)", prepared)

    def test_compiler_anonymous_types_have_checkout_independent_paths(self):
        value = {"nested": ["enum at /different/checkout/header.hpp:12:2"]}
        self.assertEqual(discovery.portable_evidence_paths(value, Path("/different/checkout")),
                         {"nested": ["enum at ${PINNED_SOURCE}/header.hpp:12:2"]})


class SnapshotTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scope = api.load(ROOT / discovery.SCOPE_FILE)
        cls.native = api.load(ROOT / discovery.NATIVE_FILE)
        cls.manifest = api.load(ROOT / discovery.MANIFEST_FILE)
        cls.review = api.load(ROOT / discovery.REVIEW_FILE)

    def mutate(self, target, mutation, error, rehash=True):
        # Copy only mutated branch; all other snapshot evidence remains untouched.
        values = {"scope": self.scope, "native": self.native,
                  "manifest": self.manifest, "review": copy.deepcopy(self.review)}
        values[target] = copy.deepcopy(values[target])
        mutation(values[target])
        if rehash:
            if target == "manifest":
                values["scope"] = copy.deepcopy(values["scope"])
                values["scope"]["manifest_sha256"] = discovery.digest(values["manifest"])
            if target in {"scope", "manifest"}:
                values["native"] = copy.deepcopy(values["native"])
                values["native"]["header_scope_sha256"] = discovery.digest(values["scope"])
            values["review"]["header_scope_sha256"] = discovery.digest(values["scope"])
            values["review"]["native_declarations_sha256"] = discovery.digest(values["native"])
            values["review"]["manifest_sha256"] = discovery.digest(values["manifest"])
        with self.assertRaisesRegex(api.AuditError, error):
            discovery.validate(ROOT, api, **values)

    def test_actual_offline_snapshot(self):
        scope, native, blockers = discovery.validate(ROOT, api)
        self.assertTrue(blockers)
        self.assertFalse(native["upstream_discovery_complete"])
        self.assertFalse(native["ada_coverage_audit_complete"])

    def test_acceptance_rejects_unresolved_source(self):
        with self.assertRaisesRegex(api.AuditError, "UPSTREAM_DISCOVERY_BLOCKED"):
            discovery.validate(ROOT, api, complete=True)

    def test_missing_header_classification(self):
        self.mutate("scope", lambda value: value["versions"]["4.1.0"].pop(),
                    "missing header classification")

    def test_duplicate_header(self):
        self.mutate("scope", lambda value: value["versions"]["4.1.0"].append(
            copy.deepcopy(value["versions"]["4.1.0"][0])), "duplicate header scope")

    def test_lost_header_even_if_self_manifest_rehashed(self):
        self.mutate("manifest", lambda value: value["versions"]["4.1.0"]["entries"].pop(),
                    "authenticated Git subtree")

    def test_changed_tree_proof(self):
        self.mutate("manifest", lambda value: value["versions"]["4.1.0"]["tree_proof"][""]["entries"].pop(),
                    "changed Git tree proof")

    def test_changed_blob_mapping(self):
        self.mutate("scope", lambda value: value["versions"]["4.1.0"][0].update(blob="0" * 40),
                    "stale header blob")

    def test_duplicate_declaration_identity(self):
        self.mutate("native", lambda value: value["versions"]["4.1.0"]["declarations"].append(
            copy.deepcopy(value["versions"]["4.1.0"]["declarations"][0])), "duplicate native declaration")

    def test_lost_overload(self):
        self.mutate("native", lambda value: value["versions"]["4.1.0"]["declarations"].pop(),
                    "lost overload")

    def test_changed_signature(self):
        self.mutate("native", lambda value: value["versions"]["4.1.0"]["declarations"][0].update(
            signature="void changed();"), "changed native signature")

    def test_unaccounted_native_declaration(self):
        def change(value):
            item = next(item for item in value["versions"]["4.1.0"]["declarations"] if item["family"])
            item.update(family=None, exclusion_reason="")
        self.mutate("native", change, "unaccounted in-scope")

    def test_invalid_version(self):
        self.mutate("scope", lambda value: value["versions"].update({"6.0.0": []}),
                    "invalid discovery version")

    def test_exclusion_edit_requires_review(self):
        self.mutate("scope", lambda value: value["versions"]["4.1.0"][0].update(
            exclusion_reason="arbitrary changed exclusion"), "stale header classification", rehash=False)

    def test_false_native_complete(self):
        self.mutate("native", lambda value: value.update(upstream_discovery_complete=True),
                    "false UPSTREAM_DISCOVERY_COMPLETE")

    def test_native_cannot_certify_ada(self):
        self.mutate("native", lambda value: value.update(ada_coverage_audit_complete=True),
                    "cannot certify Ada coverage")

    def test_parser_cannot_grant_itself_independent_review(self):
        self.mutate("review", lambda value: value.update(
            compiler_or_independent_reconciliation=["parser said PASS"]),
            "missing affirmative independent")

    def test_missing_syntax_coverage_for_header(self):
        self.mutate("native", lambda value: value["versions"]["4.1.0"]["syntax_accounting"].pop(
            next(iter(value["versions"]["4.1.0"]["syntax_accounting"]))),
            "missing in-scope header syntax")

    def test_changed_parser_confidence(self):
        self.mutate("native", lambda value: value["versions"]["4.1.0"]["declarations"][0].update(
            confidence="CERTIFIED_BY_REGEX"), "unknown native parser confidence")


class OptionalParserFixtures(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        try:
            from tree_sitter import Language, Parser
            import tree_sitter_cpp
        except ImportError:
            raise unittest.SkipTest("refresh-only parser fixtures require pinned parser-requirements.txt")
        cls.parser = Parser(Language(tree_sitter_cpp.language()))

    def parse(self, code):
        return discovery.census(code.encode(), discovery.PREFIX + "demo.hpp", "5.0.0",
                                "0" * 40, self.parser, [])

    def test_methods_owners_overloads_access_and_inline(self):
        result = self.parse("namespace cv { class Demo { public: Demo(); void f(int); "
                            "void f(double); int g() const { return 1; } private: int hidden; }; }")
        functions = [item for item in result["declarations"] if item["qualified_name"] == "cv::Demo::f"]
        self.assertEqual(len(functions), 2)
        self.assertNotEqual(functions[0]["id"], functions[1]["id"])
        self.assertTrue(any(item["exclusion_reason"] for item in result["declarations"]
                            if item["name"] == "hidden"))

    def test_templates_and_conditional_overloads_both_retained(self):
        result = self.parse("namespace cv {\n#ifdef FLAG\ntemplate<class T> T f(T);\n"
                            "#else\nint f(int);\n#endif\n}")
        functions = [item for item in result["declarations"] if item["name"] == "f"]
        self.assertEqual(len(functions), 2)
        self.assertTrue(all(item["guards"] for item in functions))

    def test_bad_syntax_not_silently_complete(self):
        result = self.parse("namespace cv { class A { THIS_MACRO_GENERATES_METHODS(A) }; }")
        self.assertTrue(result["uncertainties"])

    def test_multiple_declarators_explicit_blocker(self):
        result = self.parse("namespace cv { int a, b; }")
        self.assertTrue(any("multiple declarators" in item["reason"]
                            for item in result["uncertainties"]))


if __name__ == "__main__":
    unittest.main()