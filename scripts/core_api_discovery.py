#!/usr/bin/env python3
"""Pinned full-header enumeration and conservative source declaration census.

The refresh-only CST parser visits *all* branches, not a selector name list.
Unparsed syntax, macro expansion and unreviewed reconciliation block discovery.
Offline checks use the independently committed Git tree manifest and review lock.
"""

from collections import Counter, defaultdict
import hashlib
import importlib.metadata
import json
from pathlib import Path
import re


PREFIX = "modules/core/include/opencv2/"
SCOPE_FILE = "docs/core-api-header-scope.json"
NATIVE_FILE = "docs/core-api-native-declarations.json"
REVIEW_FILE = "docs/core-api-discovery-review.json"
MANIFEST_FILE = "docs/core-api-header-manifest.json"
CATEGORIES = {"PORTABLE_PUBLIC", "TEMPLATE_INLINE", "BACKEND_PUBLIC",
              "PLATFORM_PUBLIC", "INTERNAL_IMPLEMENTATION", "HAL_IMPLEMENTATION",
              "LEGACY_COMPATIBILITY"}
EXCLUDED = {"INTERNAL_IMPLEMENTATION", "HAL_IMPLEMENTATION", "LEGACY_COMPATIBILITY"}
NATIVE_KINDS = {"declaration", "field_declaration", "function_definition",
                "class_specifier", "struct_specifier", "union_specifier",
                "enum_specifier", "enumerator", "type_definition",
                "alias_declaration", "preproc_def", "preproc_function_def",
                "using_declaration", "namespace_alias_definition",
                "static_assert_declaration", "concept_definition"}
CONTAINERS = {"translation_unit", "declaration_list", "field_declaration_list",
              "enumerator_list", "namespace_definition", "template_declaration",
              "linkage_specification", "export_declaration"}
TRIVIA = {"comment", "preproc_include", "preproc_call", "access_specifier",
          "empty_declaration"}
ANNOTATIONS = (
    "CV_EXPORTS_W_SIMPLE", "CV_EXPORTS_W_MAP", "CV_EXPORTS_W", "CV_EXPORTS",
    "CV_WRAP_PHANTOM", "CV_WRAP_MAPPABLE", "CV_WRAP", "CV_OUT", "CV_IN_OUT",
    "CV_PROP_RW", "CV_PROP", "CV_NODISCARD_STD", "CV_NODISCARD", "CV_NOEXCEPT",
    "CV_OVERRIDE", "CV_FINAL", "CV_INLINE", "CV_DEPRECATED", "CV_NORETURN",
)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
                                    separators=(",", ":")).encode()).hexdigest()


def write(root, name, data):
    # Large census: one independently diffable occurrence/uncertainty per line,
    # not several dozen indentation-only lines per record.
    if name in {NATIVE_FILE, "docs/core-api-compiler-evidence.json"}:
        pieces = []
        for key, value in data.items():
            if key == "versions":
                versions = []
                for version, entries in value.items():
                    fields = []
                    for field, content in entries.items():
                        if isinstance(content, list):
                            rendered = "[\n" + ",\n".join(json.dumps(item) for item in content) + "\n]"
                        else:
                            rendered = json.dumps(content)
                        fields.append(json.dumps(field) + ": " + rendered)
                    versions.append(json.dumps(version) + ": {\n" + ",\n".join(fields) + "\n}")
                rendered = "{\n" + ",\n".join(versions) + "\n}"
            else:
                rendered = json.dumps(value, indent=2)
            pieces.append(json.dumps(key) + ": " + rendered)
        output = "{\n" + ",\n".join(pieces) + "\n}\n"
    else:
        output = json.dumps(data, indent=2, ensure_ascii=True) + "\n"
    (root / name).write_text(output)


def normalize(text):
    """Token-oriented identity; independent of whitespace and comments."""
    text = re.sub(r"//[^\n]*|/\*[\s\S]*?\*/", " ", text)
    return " ".join(re.findall(
        r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_]\w*|'
        r'\d+(?:\.\d+)?|::|->|&&|<<|>>|<=|>=|==|!=|\.\.\.|[^\s]', text))


def blank(match):
    return re.sub(rb"[^\n]", b" ", match.group(0))


def prepare(data):
    """Remove ONLY named OpenCV binding/visibility annotations; keep offsets.

    Not a preprocessor. Every other macro remains in the CST or uncertainty
    ledger. Blanking annotations does not establish compiler-valid declarations.
    """
    edits = []
    patterns = [rb"\b(?:" + b"|".join(item.encode() for item in ANNOTATIONS) + rb")\b",
                rb"\b(?:CV_EXPORTS_AS|CV_EXPORTS_W_SIMPLE|CV_WRAP_AS|CV_WRAP_DEFAULT|"
                rb"CV_DEPRECATED_EXTERNAL|CV_DEPRECATED_INTERNAL)\s*\([^()]*\)"]
    result = data
    # Function-like annotations first, to avoid leaving their argument list.
    for pattern in reversed(patterns):
        for match in re.finditer(pattern, result):
            edits.append({"start_byte": match.start(), "end_byte": match.end(),
                          "annotation": match.group().decode()})
        result = re.sub(pattern, blank, result)
    return result, sorted(edits, key=lambda item: item["start_byte"])


def guard_lines(text):
    """Record source guards without evaluating target-specific conditions."""
    result, stack = {}, []
    for number, line in enumerate(text.splitlines(), 1):
        result[number] = [" / ".join(group) for group in stack]
        stripped = line.strip()
        if re.match(r"#\s*(if|ifdef|ifndef)\b", stripped):
            stack.append([stripped])
        elif re.match(r"#\s*(elif|else)\b", stripped) and stack:
            stack[-1].append(stripped)
        elif re.match(r"#\s*endif\b", stripped) and stack:
            stack.pop()
    return result


def classify(path):
    """Conservative scope: utility/detail is not a blanket private exclusion."""
    relative = path.removeprefix(PREFIX)
    if relative in {"core/core.hpp", "core/core_c.h", "core/types_c.h"}:
        return ("LEGACY_COMPATIBILITY", "Legacy C API or forwarding include; modern Core semantic families are inventoried from their defining C++ headers.")
    if ("/private/" in relative or ".private." in relative
            or relative in {"core/private.hpp", "core/private.cuda.hpp",
                            "core/detail/dispatch_helper.impl.hpp"}):
        return ("INTERNAL_IMPLEMENTATION", "Explicit private or dispatch implementation header; not an application-facing Core abstraction.")
    if (relative.startswith("core/hal/") and relative != "core/hal/interface.h"
            or relative in {"core/cv_cpu_dispatch.h", "core/cv_cpu_helper.h",
                            "core/neon_utils.hpp", "core/sse_utils.hpp",
                            "core/vsx_utils.hpp", "core/simd_intrinsics.hpp",
                            "core/llapi/llapi.h"}):
        return ("HAL_IMPLEMENTATION", "SIMD/HAL dispatch, architecture intrinsics or low-level plugin ABI; excluded from portable high-level binding target, not asserted absent from installed C++.")
    if (relative.startswith(("core/cuda/", "core/opencl/", "core/openvx/"))
            or relative in {"core/cuda.hpp", "core/cuda.inl.hpp", "core/cuda_types.hpp",
                            "core/cuda_stream_accessor.hpp", "core/ocl.hpp",
                            "core/ocl_genbase.hpp", "core/ovx.hpp", "core/bufferpool.hpp"}
            or relative.startswith("core/parallel/")):
        return ("BACKEND_PUBLIC", "Backend/device/parallel integration interface; census included separately from mandatory portable capability target.")
    if relative in {"core/directx.hpp", "core/opengl.hpp", "core/va_intel.hpp",
                    "core/eigen.hpp", "core/utils/fp_control_utils.hpp"}:
        return ("PLATFORM_PUBLIC", "External library, graphics/platform integration or architecture-sensitive control; declaration presence does not guarantee target availability.")
    if (".inl." in relative or relative in {"core/traits.hpp", "core/saturate.hpp",
                                            "core/fast_math.hpp", "core/cvstd_wrapper.hpp"}
            or relative.endswith(".impl.hpp")):
        return ("TEMPLATE_INLINE", "Template/inline or supporting implementation definitions; inspect public operations and reconcile redeclarations rather than count them as new semantic capabilities.")
    return ("PORTABLE_PUBLIC", "Public Core API/value/utility header retained for declaration census; individual nonpublic/implementation declarations are assessed separately.")


def family_for(path, qualified, kind, seeds):
    """Provisional reconciliation; no Ada implementation status inferred here."""
    owner, _, name = qualified.rpartition("::")
    overrides = {
        "transposeND": "core.layout.transpose-nd", "flipND": "core.layout.flip-nd",
        "broadcast": "core.layout.broadcast", "finiteMask": "core.numeric.finite-mask",
        "divSpectrums": "core.spectral.divide", "mulSpectrums": "core.spectral.multiply",
        "dft": "core.spectral.dft-dct", "idft": "core.spectral.dft-dct",
        "dct": "core.spectral.dft-dct", "idct": "core.spectral.dft-dct",
        "gemm": "core.linear.gemm", "batchDistance": "core.numeric.batch-distance",
        "norm": "core.numeric.general-norm", "getVersionString": "core.runtime.version-build",
        "getBuildInformation": "core.runtime.version-build",
        "getNumThreads": "core.runtime.threading", "setNumThreads": "core.runtime.threading",
        "useOptimized": "core.runtime.optimization", "setUseOptimized": "core.runtime.optimization",
        "getTickCount": "core.runtime.timing", "getTickFrequency": "core.runtime.timing",
    }
    if owner == "cv" and name in overrides:
        return overrides[name], "named-native-family"
    if "DualQuat" in owner or name == "DualQuat":
        return "core.types.dual-quaternion", "class-family"
    if "Quat" in owner or name == "Quat":
        return "core.types.quaternion", "class-family"
    # New IDs deliberately describe native discovery, not missing Ada APIs.
    groups = {
        "Mat": "dense-storage", "Mat_": "dense-storage", "MatExpr": "dense-expressions",
        "UMat": "umat-storage", "SparseMat": "sparse-storage", "SparseMat_": "sparse-storage",
        "FileStorage": "persistence-storage", "FileNode": "persistence-nodes",
        "FileNodeIterator": "persistence-nodes", "Algorithm": "algorithm-infrastructure",
        "PCA": "pca", "LDA": "lda", "SVD": "svd", "RNG": "random",
        "RNG_MT19937": "random", "AsyncArray": "async", "AsyncPromise": "async",
    }
    parts = qualified.split("::")
    for part in parts:
        if part in groups:
            return "core.native." + groups[part], "owner-family-provisional"
    stem = path.removeprefix(PREFIX).removesuffix(".hpp").removesuffix(".h")
    stem = re.sub(r"[^a-z0-9]+", "-", stem.lower()).strip("-")
    return "core.native.header-" + stem, "header-bucket-needs-semantic-review"


def census(data, path, version, blob, parser, seeds):
    transformed, annotations = prepare(data)
    tree = parser.parse(transformed)
    guards = guard_lines(data.decode())
    records, issues, accounting = [], [], []

    def text(node):
        return data[node.start_byte:node.end_byte].decode()

    def issue(node, reason):
        value = {"path": path, "version": version, "start": node.start_point.row + 1,
                 "end": node.end_point.row + 1, "start_byte": node.start_byte,
                 "end_byte": node.end_byte, "syntax_kind": node.type,
                 "reason": reason, "source": text(node)[:1600], "blocking": True}
        value["id"] = "uncertain." + digest(value)[:24]
        issues.append(value)
        return value["id"]

    def leaf_name(node):
        if node is None:
            return ""
        if node.type in {"identifier", "type_identifier", "field_identifier",
                         "qualified_identifier", "operator_name", "destructor_name",
                         "operator_cast"}:
            return normalize(text(node)).replace(" :: ", "::")
        declarator = node.child_by_field_name("declarator")
        if declarator:
            return leaf_name(declarator)
        # The C++ grammar's reference_declarator does not name its child field.
        if node.type in {"reference_declarator", "pointer_declarator",
                         "init_declarator", "function_declarator", "array_declarator"}:
            for child in node.named_children:
                result = leaf_name(child)
                if result:
                    return result
        return ""

    def record(node, owners, access, template, parent_kind):
        name_node = node.child_by_field_name("name")
        declarator = node.child_by_field_name("declarator")
        name = leaf_name(name_node) or leaf_name(declarator)
        if not name and node.type in {"field_declaration", "declaration"}:
            nested_type = node.child_by_field_name("type")
            if nested_type and nested_type.type in {"enum_specifier", "class_specifier",
                                                    "struct_specifier", "union_specifier"}:
                name = leaf_name(nested_type.child_by_field_name("name")) or "<anonymous-type-declaration>"
        if node.type in {"preproc_def", "preproc_function_def"}:
            name = text(name_node) if name_node else ""
        if node.type in {"using_declaration", "namespace_alias_definition"} and not name:
            name = normalize(text(node)).rstrip(" ;")
        if not name:
            # Anonymous types are retained by stable source signature, not lost.
            name = "<anonymous>" if node.type.endswith("specifier") else "<unresolved>"
        owner = "::".join(owners)
        qualified = owner + "::" + name if owner else name
        if "::" in name and not name.startswith("operator"):
            qualified = name if name.startswith("cv::") else (owner + "::" + name if owner else name)
        body = node.child_by_field_name("body")
        stop = body.start_byte if body else node.end_byte
        signature = normalize(data[node.start_byte:stop].decode())
        if template:
            signature = normalize(template) + " " + signature
        kind = node.type
        if node.type in {"declaration", "field_declaration", "function_definition"}:
            def has_function(inner):
                return inner.type in {"function_declarator", "operator_cast"} or any(
                    has_function(child) for child in inner.named_children
                    if child.type not in {"parameter_list", "compound_statement"})
            if declarator and has_function(declarator):
                if owners and name == owners[-1]:
                    kind = "constructor"
                elif name.startswith("~"):
                    kind = "destructor"
                elif name.startswith("operator"):
                    kind = "operator"
                else:
                    kind = "method" if parent_kind in {"class_specifier", "struct_specifier"} else "function"
            elif node.type != "function_definition":
                kind = "field_or_variable"
        if body and node.type in {"class_specifier", "struct_specifier", "union_specifier", "enum_specifier"}:
            kind += "_definition"
        identity = "native." + digest([qualified, kind.removesuffix("_definition")
                                       .replace("function_definition", "declaration"), signature])[:32]
        family, mapping = family_for(path, qualified, kind, seeds)
        private = access in {"private", "protected"}
        excluded_reason = ""
        if private:
            excluded_reason = f"C++ {access} member; not a public application declaration"
        elif kind in {"static_assert_declaration"}:
            excluded_reason = "Compile-time implementation assertion, not an application operation"
        elif name.startswith(("OPENCV_", "CV__")) and kind.startswith("preproc_"):
            excluded_reason = "Include/configuration/implementation macro; not separately mandatory Ada API"
        value = {"id": identity, "qualified_name": qualified, "owner": owner,
                 "name": name, "kind": kind, "signature": signature,
                 "overload_identity": digest([qualified, signature]),
                 "version": version, "availability": "DECLARED_UNDER_RECORDED_GUARDS",
                 "path": path, "blob": blob, "start": node.start_point.row + 1,
                 "end": node.end_point.row + 1, "start_byte": node.start_byte,
                 "end_byte": node.end_byte, "guards": guards.get(node.start_point.row + 1, []),
                 "access": access, "parent_syntax": parent_kind,
                 "family": None if excluded_reason else family,
                 "family_mapping": mapping, "exclusion_reason": excluded_reason,
                 "confidence": "CST_ONLY_NOT_COMPILER_VERIFIED",
                 "reviewed": False}
        # Identity is per signature; occurrence and source link are version-specific.
        if name == "<unresolved>":
            value["uncertainty"] = issue(node, "declaration identity not resolved")
        if node.has_error:
            value["confidence"] = "RECOVERY_TREE_REQUIRES_RECONCILIATION"
        declarators = [child for index, child in enumerate(node.children)
                       if node.field_name_for_child(index) == "declarator"]
        if len(declarators) > 1:
            value["uncertainty"] = issue(node, "multiple declarators in one source statement; split identities not yet reconciled")
        records.append(value)
        return name, identity

    def walk(node, owners=(), access="public", template="", parent_kind="translation_unit"):
        if node.type == "ERROR" or node.is_missing:
            identity = issue(node, "C++ grammar recovery or missing syntax; no completeness claim")
            accounting.append([node.start_byte, node.end_byte, node.type, "UNRESOLVED", identity])
            # Recovered declaration children still provide evidence, not closure.
            for child in node.named_children:
                walk(child, owners, access, template, node.type)
            return
        if node.type in TRIVIA:
            accounting.append([node.start_byte, node.end_byte, node.type, "TRIVIA_OR_DIRECTIVE", ""])
            return
        if node.type.startswith("preproc_") and node.type not in {"preproc_def", "preproc_function_def"}:
            for child in node.named_children:
                if child.type in {"identifier", "preproc_arg", "binary_expression",
                                  "unary_expression", "call_expression", "number_literal",
                                  "parenthesized_expression", "defined", "true", "false"}:
                    continue  # Condition is preserved in the separate guard ledger.
                walk(child, owners, access, template, node.type)
            return
        if node.type == "namespace_definition":
            name = node.child_by_field_name("name")
            body = node.child_by_field_name("body")
            if body:
                walk(body, owners + ((normalize(text(name)) if name else "<anonymous-namespace>"),),
                     access, template, node.type)
            return
        if node.type == "template_declaration":
            parameters = node.child_by_field_name("parameters")
            prefix = text(parameters) if parameters else "<unresolved-template>"
            for child in node.named_children:
                if child != parameters:
                    walk(child, owners, access, prefix, node.type)
            return
        if node.type in NATIVE_KINDS:
            name, identity = record(node, owners, access, template, parent_kind)
            accounting.append([node.start_byte, node.end_byte, node.type, "DECLARATION", identity])
            # Struct/class/enum nested inside typedef or declaration must be visited.
            for child in node.named_children:
                if child.type in {"class_specifier", "struct_specifier", "union_specifier", "enum_specifier"}:
                    walk(child, owners, access, template, node.type)
            body = node.child_by_field_name("body")
            if body and node.type in {"class_specifier", "struct_specifier", "union_specifier", "enum_specifier"}:
                current_access = "private" if node.type == "class_specifier" else "public"
                for child in body.named_children:
                    if child.type == "access_specifier":
                        current_access = text(child)
                    else:
                        walk(child, owners + (name,), current_access, "", node.type)
            # Bodies are implementation syntax, but grammar errors inside them still block.
            elif body:
                def errors(inner):
                    if inner.type == "ERROR" or inner.is_missing:
                        issue(inner, "inline body syntax recovery; public operation may be incomplete")
                    else:
                        for child in inner.named_children:
                            errors(child)
                errors(body)
            return
        if node.type in CONTAINERS:
            for child in node.named_children:
                walk(child, owners, access, template, node.type)
            return
        identity = issue(node, "unhandled declaration-scope CST node; manual disposition required")
        accounting.append([node.start_byte, node.end_byte, node.type, "UNRESOLVED", identity])

    walk(tree.root_node)
    return {"declarations": records, "uncertainties": issues,
            "accounting": accounting, "annotation_edits": annotations,
            "root_has_error": tree.root_node.has_error}


def diagnostics(root, api):
    native = api.load(root / NATIVE_FILE)
    for version, content in native["versions"].items():
        print("\n===", version, "===")
        counts = Counter(item["path"] for item in content["uncertainties"])
        for path, count in counts.most_common():
            print(count, path)
        print("Example blockers:")
        seen = set()
        for item in content["uncertainties"]:
            key = (item["path"], item["syntax_kind"])
            if key not in seen:
                seen.add(key)
                print(f"{item['path']}:{item['start']}: {item['reason']}: {item['source'][:100]!r}")


def compiler_census(source, includes, library):
    """Independent active-configuration AST. Never resolves inactive branches."""
    from clang import cindex
    if not cindex.Config.loaded:
        cindex.Config.set_library_file(str(library))
    index = cindex.Index.create()
    args = ["-x", "c++", "-std=c++17", "-I" + str(source / "modules/core/include"),
            "-I/usr/include/opencv4", "-I/usr/include/c++/14",
            "-I/usr/include/x86_64-linux-gnu/c++/14",
            "-I/usr/lib/llvm-19/lib/clang/19/include"]
    document = "\n".join("#include <" + item + ">" for item in includes) + "\n"
    translation = index.parse("core-audit-census.cpp", args=args,
                              unsaved_files=[("core-audit-census.cpp", document)],
                              options=cindex.TranslationUnit.PARSE_DETAILED_PROCESSING_RECORD)
    diagnostics = [{"severity": item.severity, "message": item.spelling,
                    "location": str(item.location)} for item in translation.diagnostics]
    kinds = {"FUNCTION_DECL", "FUNCTION_TEMPLATE", "CXX_METHOD", "CONSTRUCTOR",
             "DESTRUCTOR", "CONVERSION_FUNCTION", "CLASS_DECL", "STRUCT_DECL",
             "UNION_DECL", "CLASS_TEMPLATE", "CLASS_TEMPLATE_PARTIAL_SPECIALIZATION",
             "ENUM_DECL", "ENUM_CONSTANT_DECL", "TYPEDEF_DECL", "TYPE_ALIAS_DECL",
             "VAR_DECL", "FIELD_DECL", "MACRO_DEFINITION"}
    entries = []

    def walk(cursor):
        location = cursor.location
        local = None
        if location.file:
            try:
                local = Path(location.file.name).resolve().relative_to(source.resolve()).as_posix()
            except ValueError:
                pass
        if local and local.startswith(PREFIX) and cursor.kind.name in kinds:
            owners, parent = [], cursor.semantic_parent
            while parent and parent.kind.name != "TRANSLATION_UNIT":
                if parent.spelling:
                    owners.append(parent.spelling)
                parent = parent.semantic_parent
            owner = "::".join(reversed(owners))
            tokens = []
            # Compiler type signature distinguishes overloads without inline body tokens.
            for token in cursor.get_tokens():
                if token.spelling == "{":
                    break
                tokens.append(token.spelling)
            qualified = owner + "::" + cursor.spelling if owner else cursor.spelling
            entries.append({"usr": cursor.get_usr(), "qualified_name": qualified,
                            "owner": owner, "kind": cursor.kind.name,
                            "type": cursor.type.spelling,
                            "signature": " ".join(tokens), "access": cursor.access_specifier.name,
                            "path": local, "line": location.line,
                            "start_byte": cursor.extent.start.offset,
                            "end_byte": cursor.extent.end.offset,
                            "is_definition": cursor.is_definition()})
        # Do not crawl standard library declarations or function-local implementation.
        if cursor.kind.name in {"FUNCTION_DECL", "CXX_METHOD", "CONSTRUCTOR",
                                "DESTRUCTOR", "CONVERSION_FUNCTION"}:
            return
        if local or cursor.kind.name == "TRANSLATION_UNIT":
            for child in cursor.get_children():
                walk(child)
    walk(translation.cursor)
    return {"compiler": "libclang 19.1.7", "configuration": "Linux x86_64, C++17; active branches only",
            "include_headers": includes, "arguments": args,
            "diagnostics": diagnostics, "declarations": entries,
            "all_conditional_branches_reconciled": False}


def portable_evidence_paths(value, source):
    """Compiler anonymous-type spellings include absolute source paths."""
    if isinstance(value, str):
        return value.replace(str(source), "${PINNED_SOURCE}")
    if isinstance(value, list):
        return [portable_evidence_paths(item, source) for item in value]
    if isinstance(value, dict):
        return {key: portable_evidence_paths(item, source) for key, item in value.items()}
    return value


def refresh_compiler(root, parent, library, api):
    result = {"schema_version": 1, "versions": {},
              "status": "INDEPENDENT_ACTIVE_CONFIGURATION_ONLY_NOT_DISCOVERY_CLOSURE"}
    for version in api.VERSIONS:
        source = parent / ("upstream-" + version)
        if api.git(source, "rev-parse", "HEAD") != api.PINS[version][0]:
            api.fail(f"incorrect compiler source: {version}")
        includes = ["opencv2/core.hpp", "opencv2/core/affine.hpp", "opencv2/core/optim.hpp",
                    "opencv2/core/softfloat.hpp", "opencv2/core/ocl.hpp", "opencv2/core/cuda.hpp",
                    "opencv2/core/opengl.hpp", "opencv2/core/utils/filesystem.hpp",
                    "opencv2/core/utils/logger.hpp", "opencv2/core/utils/trace.hpp"]
        for extra in ("quaternion.hpp", "dualquaternion.hpp", "async.hpp", "detail/async_promise.hpp",
                      "utils/tls.hpp", "utils/allocator_stats.hpp", "utils/fp_control_utils.hpp",
                      "parallel/parallel_backend.hpp"):
            if (source / PREFIX / "core" / extra).exists():
                includes.append("opencv2/core/" + extra)
        value = compiler_census(source, includes, library)
        # Absolute execution paths belong to local logs, not source identity.
        value = portable_evidence_paths(value, source)
        result["versions"][version] = value
        print(version, "compiler declarations:", len(value["declarations"]),
              "errors:", sum(item["severity"] >= 3 for item in value["diagnostics"]))
    write(root, "docs/core-api-compiler-evidence.json", result)


def declaration_identity(item):
    kind = item["kind"].removesuffix("_definition").replace("function_definition", "declaration")
    return "native." + digest([item["qualified_name"], kind, item["signature"]])[:32]


def reconcile_compiler(root, api):
    native = api.load(root / NATIVE_FILE)
    compiler = api.load(root / "docs/core-api-compiler-evidence.json")
    for version, content in compiler["versions"].items():
        source = native["versions"][version]
        by_path = defaultdict(list)
        for item in source["declarations"]:
            by_path[item["path"]].append(item)
        comparisons = []
        for item in content["declarations"]:
            candidates = [record["id"] for record in by_path[item["path"]]
                          if record["start"] <= item["line"] <= record["end"]
                          and (record["qualified_name"] == item["qualified_name"]
                               or record["name"] == item["qualified_name"].split("::")[-1])]
            comparisons.append({"compiler_usr": item["usr"], "path": item["path"],
                                "line": item["line"], "name": item["qualified_name"],
                                "source_candidate_ids": sorted(set(candidates)),
                                "disposition": "CANDIDATES_NOT_REVIEWED" if candidates else "UNMATCHED_COMPILER_DECLARATION"})
        content["source_reconciliation"] = comparisons
        content["source_reconciliation_reviewed"] = False
        print(version, "unmatched compiler declaration occurrences:",
              sum(not item["source_candidate_ids"] for item in comparisons))
    write(root, "docs/core-api-compiler-evidence.json", compiler)


def git_tree_hash(entries):
    """Actual Git tree object hash, not a hash of our own discovery output."""
    payload = b""
    for mode, object_id, name in entries:
        payload += mode.lstrip("0").encode() + b" " + name.encode() + b"\0" + bytes.fromhex(object_id)
    return hashlib.sha1(b"tree " + str(len(payload)).encode() + b"\0" + payload).hexdigest()


def tree_proof(source, commit, api):
    """Full descendant trees and ancestor siblings authenticate the path census."""
    root = PREFIX.rstrip("/")
    paths = ["", "modules", "modules/core", "modules/core/include", root]
    paths += [line.split("\t", 1)[1] for line in api.git(
        source, "ls-tree", "-r", "-t", commit, "--", root).splitlines()
              if line.startswith("040000") and line.split("\t", 1)[1] != root]
    proof = {}
    for path in sorted(set(paths)):
        treeish = commit + (":" + path if path else "^{tree}")
        entries = []
        for line in api.git(source, "ls-tree", treeish).splitlines():
            metadata, name = line.split("\t", 1)
            mode, kind, object_id = metadata.split()
            entries.append([mode, object_id, name])
        proof[path] = {"sha": api.git(source, "rev-parse", treeish), "entries": entries}
    return proof


def check_tree_proof(listing, pin, api):
    proof = listing["tree_proof"]
    for path, tree in proof.items():
        if git_tree_hash(tree["entries"]) != tree["sha"]:
            api.fail(f"incomplete or changed Git tree proof: {path}")
        if path:
            parent, _, name = path.rpartition("/")
            if ["040000", tree["sha"], name] not in proof[parent]["entries"]:
                api.fail(f"disconnected Git tree proof: {path}")
    if proof[""]["sha"] != pin[1]:
        api.fail("discovery Git tree proof not rooted at pinned upstream tree")
    expected = []

    def descend(path):
        for mode, object_id, name in proof[path]["entries"]:
            child = path + "/" + name
            if mode == "040000":
                if child not in proof:
                    api.fail(f"missing descendant Git tree proof: {child}")
                descend(child)
            else:
                expected.append([mode, object_id, child])
    descend(PREFIX.rstrip("/"))
    if sorted(expected) != sorted(listing["entries"]):
        api.fail("pinned public header list does not cover authenticated Git subtree")


def refresh(root, parent, api):
    from tree_sitter import Language, Parser
    import tree_sitter_cpp
    versions = {"tree-sitter": "0.25.2", "tree-sitter-cpp": "0.23.4"}
    for package, version in versions.items():
        if importlib.metadata.version(package) != version:
            api.fail(f"census refresh requires {package}=={version}")
    parser = Parser(Language(tree_sitter_cpp.language()))
    seeds = api.load(root / "docs/core-api-reference.json")["capabilities"]
    seed_ids = {item["id"] for item in seeds}
    scope = {"schema_version": 1, "versions": {}}
    manifest = {"schema_version": 1, "prefix": PREFIX, "versions": {}}
    native = {"schema_version": 1, "parser": versions,
              "upstream_discovery_complete": False, "ada_coverage_audit_complete": False,
              "versions": {}, "families": {}, "version_differences": {}}
    for version, pin in api.PINS.items():
        source = parent / ("upstream-" + version)
        if api.git(source, "remote", "get-url", "origin") != "https://github.com/opencv/opencv.git":
            api.fail("not official upstream")
        if (api.git(source, "rev-parse", "HEAD"), api.git(source, "rev-parse", "HEAD^{tree}")) != pin:
            api.fail(f"wrong pinned source identity: {version}")
        if api.git(source, "status", "--porcelain", "--", "modules/core/include/opencv2"):
            api.fail(f"dirty pinned headers: {version}")
        listing = api.git(source, "ls-tree", "-r", pin[0], "--", PREFIX)
        header_records, declarations, uncertainties, syntax = [], [], [], {}
        manifest["versions"][version] = {"commit": pin[0], "tree": pin[1], "entries": [],
                                          "tree_proof": tree_proof(source, pin[0], api)}
        for line in listing.splitlines():
            metadata, path = line.split("\t", 1)
            mode, kind, blob = metadata.split()
            if kind != "blob" or not path.endswith((".h", ".hpp", ".hxx", ".inl")):
                api.fail(f"unhandled tracked entry under declared header scope: {line}")
            data = (source / path).read_bytes()
            if hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest() != blob:
                api.fail(f"header blob mismatch: {version}:{path}")
            manifest["versions"][version]["entries"].append([mode, blob, path])
            category, reason = classify(path)
            text = data.decode()
            directives = [{"line": i + 1, "text": value.strip()} for i, value in enumerate(text.splitlines())
                          if re.match(r"\s*#\s*(if|ifdef|ifndef|elif|else|endif)\b", value)]
            parsed = census(data, path, version, blob, parser, seeds) if category not in EXCLUDED else None
            if parsed:
                for declaration in parsed.pop("declarations"):
                    declaration["source"] = (f"https://github.com/opencv/opencv/blob/{pin[0]}/"
                                             f"{path}#L{declaration['start']}")
                    declarations.append(declaration)
                uncertainties += parsed.pop("uncertainties")
                syntax[path] = parsed
            families = sorted({item["family"] for item in declarations
                               if item["path"] == path and item["family"]})
            header_records.append({"version": version, "path": path, "blob": blob,
                                   "sha256": hashlib.sha256(data).hexdigest(), "category": category,
                                   "in_scope": category not in EXCLUDED,
                                   "scope_reason": reason,
                                   "exclusion_reason": reason if category in EXCLUDED else "",
                                   "scope_review": "PROVISIONAL_REQUIRES_EXPLICIT_REVIEW",
                                   "families": families, "guards": directives,
                                   "source": f"https://github.com/opencv/opencv/blob/{pin[0]}/{path}",
                                   "evidence_excerpt": "\n".join(text.splitlines()[:65])})
        scope["versions"][version] = header_records
        native["versions"][version] = {"declarations": declarations,
                                       "uncertainties": uncertainties,
                                       "syntax_accounting": syntax}
        print(f"{version}: headers={len(header_records)} in_scope="
              f"{sum(item['in_scope'] for item in header_records)} "
              f"declaration_occurrences={len(declarations)} blocking_cases={len(uncertainties)}")
        for item in declarations:
            if item["family"]:
                native["families"].setdefault(item["family"], {
                    "existing_seed": item["family"] in seed_ids,
                    "classification": "RESEARCH_REQUIRED",
                    "reconciliation_reviewed": False,
                    "note": "Discovery mapping only; no Ada implementation completeness or absence inferred"})
    # Availability by exact declaration identity, and changed signatures by qualified name.
    names = defaultdict(lambda: defaultdict(set))
    for version, value in native["versions"].items():
        for item in value["declarations"]:
            names[item["qualified_name"]][version].add(item["id"])
    previous = None
    for version in api.VERSIONS:
        current = {item["id"] for item in native["versions"][version]["declarations"]}
        if previous:
            before = {item["id"] for item in native["versions"][previous]["declarations"]}
            native["version_differences"][previous + ".." + version] = {
                "added_declaration_ids": sorted(current - before),
                "removed_declaration_ids": sorted(before - current),
                "changed_overload_sets": sorted(name for name, sets in names.items()
                                                if sets.get(version) and sets.get(previous)
                                                and sets[version] != sets[previous]),
                "meaning": "Observed reference-tag changes, not exact first introduction dates or callability"}
        previous = version
    availability = defaultdict(set)
    for version, content in native["versions"].items():
        for declaration in content["declarations"]:
            availability[declaration["id"]].add(version)
    native["declaration_availability"] = {identity: sorted(versions) for identity, versions in sorted(availability.items())}
    scope["manifest_sha256"] = digest(manifest)
    native["header_scope_sha256"] = digest(scope)
    native["header_differences"] = {}
    previous = None
    for version in api.VERSIONS:
        now = {item[2]: item[1] for item in manifest["versions"][version]["entries"]}
        if previous:
            before = {item[2]: item[1] for item in manifest["versions"][previous]["entries"]}
            native["header_differences"][previous + ".." + version] = {
                "added": sorted(now.keys() - before.keys()),
                "removed": sorted(before.keys() - now.keys()),
                "changed_blobs": sorted(path for path in now.keys() & before.keys() if now[path] != before[path])}
        previous = version
    review = {"schema_version": 1, "header_scope_sha256": digest(scope),
              "native_declarations_sha256": digest(native), "manifest_sha256": digest(manifest),
              "reviewed_exclusions": [], "reviewed_headers": [],
              "compiler_or_independent_reconciliation": [],
              "disposition": "UPSTREAM_DISCOVERY_BLOCKED",
              "note": "Refresh never grants review or closure. Review changes separately."}
    write(root, MANIFEST_FILE, manifest)
    write(root, SCOPE_FILE, scope)
    write(root, NATIVE_FILE, native)
    # A refresh cannot overwrite review approvals silently.
    if not (root / REVIEW_FILE).exists():
        write(root, REVIEW_FILE, review)


def lock_snapshot(root, api):
    """Explicit integrity update, never silently asserts review or completion."""
    review = api.load(root / REVIEW_FILE)
    review["header_scope_sha256"] = digest(api.load(root / SCOPE_FILE))
    review["native_declarations_sha256"] = digest(api.load(root / NATIVE_FILE))
    review["manifest_sha256"] = digest(api.load(root / MANIFEST_FILE))
    compiler = root / "docs/core-api-compiler-evidence.json"
    if compiler.exists():
        review["compiler_evidence_sha256"] = digest(api.load(compiler))
    review["disposition"] = "UPSTREAM_DISCOVERY_BLOCKED"
    write(root, REVIEW_FILE, review)


def validate_links(root, api):
    upstream = api.load(root / "docs/core-api-upstream.json")
    scope = api.load(root / SCOPE_FILE)
    native = api.load(root / NATIVE_FILE)
    manifest = api.load(root / MANIFEST_FILE)
    reference = api.load(root / "docs/core-api-reference.json")
    expected = {"header_scope_sha256": digest(scope), "native_declarations_sha256": digest(native),
                "manifest_sha256": digest(manifest), "review_sha256": digest(api.load(root / REVIEW_FILE)),
                "compiler_evidence_sha256": digest(api.load(root / "docs/core-api-compiler-evidence.json"))}
    if upstream.get("discovery_snapshot") != expected:
        api.fail("stale linked upstream discovery fingerprints")
    link = reference.get("upstream_discovery", {})
    if (link.get("header_scope") != SCOPE_FILE or link.get("native_declarations") != NATIVE_FILE
            or link.get("new_native_family_ids") != sorted(key for key, item in native["families"].items()
                                                          if not item["existing_seed"])):
        api.fail("stale linked native family reconciliation")


def integrate_metadata(root, api):
    """Link discovery ledgers without changing any of the 26 seed records."""
    scope = api.load(root / SCOPE_FILE)
    native = api.load(root / NATIVE_FILE)
    manifest = api.load(root / MANIFEST_FILE)
    reference = api.load(root / "docs/core-api-reference.json")
    starting_reference = json.loads(api.git(root, "show",
        "887f378bdac2ff90a5163bd87cbe8569443dd872:docs/core-api-reference.json"))
    if reference["capabilities"] != starting_reference["capabilities"]:
        api.fail("original 26 seed capability records were altered")
    reference["upstream_discovery"] = {
        "header_scope": SCOPE_FILE, "native_declarations": NATIVE_FILE,
        "manifest": MANIFEST_FILE, "review": REVIEW_FILE,
        "native_complete": False, "ada_complete": False,
        "new_native_family_ids": sorted(key for key, item in native["families"].items()
                                        if not item["existing_seed"]),
        "meaning": "Provisional native owner/header buckets; not completed semantic reconciliation or Ada missing-feature classifications"}
    provenance = api.load(root / "docs/core-api-upstream.json")
    provenance["discovery_snapshot"] = {
        "header_scope_sha256": digest(scope), "native_declarations_sha256": digest(native),
        "manifest_sha256": digest(manifest), "review_sha256": digest(api.load(root / REVIEW_FILE)),
        "compiler_evidence_sha256": digest(api.load(root / "docs/core-api-compiler-evidence.json"))}
    coverage = api.load(root / "docs/core-api-coverage.json")
    starting_coverage = json.loads(api.git(root, "show",
        "887f378bdac2ff90a5163bd87cbe8569443dd872:docs/core-api-coverage.json"))
    if coverage["capabilities"] != starting_coverage["capabilities"]:
        api.fail("original 26 generated evidence records were altered")
    coverage["reference_sha256"] = digest(reference)
    coverage["provenance_sha256"] = digest(provenance)
    # No global discovery_complete or review_complete promotion.
    write(root, "docs/core-api-reference.json", reference)
    write(root, "docs/core-api-upstream.json", provenance)
    write(root, "docs/core-api-coverage.json", coverage)


def report(root, api):
    """Explicit complete list of unresolved paths; no sampled completeness claim."""
    scope = api.load(root / SCOPE_FILE)
    native = api.load(root / NATIVE_FILE)
    compiler = api.load(root / "docs/core-api-compiler-evidence.json")
    report = {"schema_version": 1, "disposition": "UPSTREAM_DISCOVERY_BLOCKED", "versions": {}}
    for version, headers in scope["versions"].items():
        content = native["versions"][version]
        parse_counts = Counter(item["path"] for item in content["uncertainties"])
        unmatched = Counter(item["path"] for item in compiler["versions"][version]["source_reconciliation"]
                            if item["disposition"] == "UNMATCHED_COMPILER_DECLARATION")
        declarations = content["declarations"]
        counts = Counter(item["category"] for item in headers)
        report["versions"][version] = {
            "headers": len(headers), "in_scope": sum(item["in_scope"] for item in headers),
            "excluded": sum(not item["in_scope"] for item in headers),
            "scope_categories": dict(sorted(counts.items())),
            "header_dispositions_reviewed": sum(item["scope_review"] == "REVIEWED" for item in headers),
            "native_occurrences": len(declarations), "distinct_native_ids": len({item["id"] for item in declarations}),
            "provisionally_assigned_to_family": sum(bool(item["family"]) for item in declarations),
            "provisionally_excluded_declarations": sum(bool(item["exclusion_reason"]) for item in declarations),
            "records_without_any_mapping": sum(not item["family"] and not item["exclusion_reason"] for item in declarations),
            "cst_blocking_cases": len(content["uncertainties"]),
            "compiler_occurrences": len(compiler["versions"][version]["declarations"]),
            "compiler_errors": sum(item["severity"] >= 3 for item in compiler["versions"][version]["diagnostics"]),
            "unmatched_compiler_occurrences": sum(unmatched.values()),
            "unresolved_headers": [{"path": item["path"], "category": item["category"],
                                    "scope_review_required": item["scope_review"] != "REVIEWED",
                                    "exclusion_review_required": not item["in_scope"],
                                    "cst_cases": parse_counts[item["path"]],
                                    "unmatched_compiler_occurrences": unmatched[item["path"]],
                                    "evidence_required": "Review scope/exclusion and semantic reconciliation; reconcile recorded CST/macro/conditional/overload cases against independent compiler or manual source evidence"}
                                   for item in headers]}
    write(root, "docs/core-api-discovery-blockers.json", report)
    return report


def verify_checkout(root, parent, api):
    """Reproduce path/tree/blob identities independently of classification/parser."""
    manifest = api.load(root / MANIFEST_FILE)
    scope = api.load(root / SCOPE_FILE)
    for version, pin in api.PINS.items():
        source = parent / ("upstream-" + version)
        if api.git(source, "remote", "get-url", "origin") != "https://github.com/opencv/opencv.git":
            api.fail("not official upstream checkout")
        if (api.git(source, "rev-parse", "HEAD"), api.git(source, "rev-parse", "HEAD^{tree}")) != pin:
            api.fail(f"wrong pinned checkout: {version}")
        if api.git(source, "status", "--porcelain", "--", PREFIX):
            api.fail(f"dirty upstream checkout: {version}")
        listing = []
        for line in api.git(source, "ls-tree", "-r", pin[0], "--", PREFIX).splitlines():
            metadata, path = line.split("\t", 1)
            mode, kind, blob = metadata.split()
            listing.append([mode, blob, path])
        if listing != manifest["versions"][version]["entries"]:
            api.fail(f"changed upstream public header census: {version}")
        if tree_proof(source, pin[0], api) != manifest["versions"][version]["tree_proof"]:
            api.fail(f"changed upstream tree proof: {version}")
        for header in scope["versions"][version]:
            data = (source / header["path"]).read_bytes()
            blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
            if blob != header["blob"] or hashlib.sha256(data).hexdigest() != header["sha256"]:
                api.fail(f"changed header source bytes: {version}:{header['path']}")
        print(f"{version}: reproduced {len(listing)} pinned header/tree/blob identities")


def validate(root, api, complete=False, scope=None, native=None, manifest=None, review=None):
    scope = scope if scope is not None else api.load(root / SCOPE_FILE)
    native = native if native is not None else api.load(root / NATIVE_FILE)
    manifest = manifest if manifest is not None else api.load(root / MANIFEST_FILE)
    review = review if review is not None else api.load(root / REVIEW_FILE)
    for value in (scope, native, manifest, review):
        if value.get("schema_version") != 1:
            api.fail("invalid discovery schema_version")
    if scope.get("manifest_sha256") != digest(manifest):
        api.fail("stale pinned header manifest fingerprint")
    if native.get("header_scope_sha256") != digest(scope):
        api.fail("stale header classification fingerprint")
    if (review.get("header_scope_sha256") != digest(scope)
            or review.get("native_declarations_sha256") != digest(native)
            or review.get("manifest_sha256") != digest(manifest)):
        api.fail("discovery review lock changed; review exclusions/declarations explicitly")
    compiler_path = root / "docs/core-api-compiler-evidence.json"
    if compiler_path.exists():
        compiler = api.load(compiler_path)
        if review.get("compiler_evidence_sha256") != digest(compiler):
            api.fail("changed compiler evidence fingerprint")
        for version, content in compiler["versions"].items():
            if version not in api.VERSIONS:
                api.fail("invalid compiler evidence version")
            if any(item["severity"] >= 3 for item in content["diagnostics"]):
                api.fail("compiler evidence contains errors; cannot be positive declaration evidence")
    if any(set(value.get("versions", {})) != set(api.VERSIONS) for value in (scope, native, manifest)):
        api.fail("invalid discovery version labels")
    if native.get("ada_coverage_audit_complete") is not False:
        api.fail("native discovery cannot certify Ada coverage")
    blockers = []
    for version, pin in api.PINS.items():
        listing = manifest["versions"][version]
        if (listing["commit"], listing["tree"]) != pin:
            api.fail("wrong discovery upstream commit/tree")
        check_tree_proof(listing, pin, api)
        entries = listing["entries"]
        if len({item[2] for item in entries}) != len(entries):
            api.fail("duplicate header in pinned tree manifest")
        headers = scope["versions"][version]
        paths = [item["path"] for item in headers]
        if len(paths) != len(set(paths)):
            api.fail("duplicate header scope record")
        if set(paths) != {item[2] for item in entries}:
            api.fail("missing header classification / unaccounted pinned header")
        blobs = {item[2]: item[1] for item in entries}
        by_path = {item["path"]: item for item in headers}
        for item in headers:
            if item["category"] not in CATEGORIES or item["version"] != version:
                api.fail("invalid header classification/version")
            if item["blob"] != blobs[item["path"]]:
                api.fail("stale header blob mapping")
            if item["source"] != f"https://github.com/opencv/opencv/blob/{pin[0]}/{item['path']}":
                api.fail("invalid pinned header source reference")
            if not re.fullmatch(r"[a-f0-9]{64}", item["sha256"]):
                api.fail("invalid source byte fingerprint")
            if item["in_scope"] != (item["category"] not in EXCLUDED):
                api.fail("contradictory header scope")
            if not item["scope_reason"] or (not item["in_scope"] and not item["exclusion_reason"]):
                api.fail("missing header exclusion reason")
            if item["scope_review"] != "REVIEWED":
                blockers.append(f"{version}:{item['path']}: scope disposition not reviewed")
        value = native["versions"][version]
        expected_paths = {item["path"] for item in headers if item["in_scope"]}
        if set(value["syntax_accounting"]) != expected_paths:
            api.fail("missing in-scope header syntax accounting")
        occurrences = set()
        identities = {}
        for item in value["declarations"]:
            occurrence = (item["id"], item["path"], item["start_byte"], item["end_byte"])
            if occurrence in occurrences:
                api.fail("duplicate native declaration occurrence identity")
            occurrences.add(occurrence)
            if item["id"] != declaration_identity(item) or item["overload_identity"] != digest(
                    [item["qualified_name"], item["signature"]]):
                api.fail("changed native signature/overload identity")
            identity = (item["qualified_name"], item["signature"], item["overload_identity"])
            if item["id"] in identities and identities[item["id"]] != identity:
                api.fail("duplicate native identity with contradictory overload")
            identities[item["id"]] = identity
            if (item["version"] != version or item["path"] not in expected_paths
                    or item["blob"] != blobs[item["path"]]):
                api.fail("stale native declaration/header mapping")
            if item["source"] != (f"https://github.com/opencv/opencv/blob/{pin[0]}/"
                                  f"{item['path']}#L{item['start']}"):
                api.fail("invalid pinned declaration source reference")
            if (type(item["start"]) is not int or type(item["end"]) is not int
                    or not 1 <= item["start"] <= item["end"]
                    or not 0 <= item["start_byte"] < item["end_byte"]):
                api.fail("invalid native declaration source range")
            if item["confidence"] not in {"CST_ONLY_NOT_COMPILER_VERIFIED", "RECOVERY_TREE_REQUIRES_RECONCILIATION"}:
                api.fail("unknown native parser confidence")
            if item["access"] not in {"public", "protected", "private"}:
                api.fail("invalid native public/private assessment")
            if not item["family"] and not item["exclusion_reason"]:
                api.fail("unaccounted in-scope native declaration")
            if item["family"] and item["family"] not in native["families"]:
                api.fail("unknown semantic family mapping")
            if bool(item["family"]) == bool(item["exclusion_reason"]):
                api.fail("contradictory native family/exclusion mapping")
            if not item["reviewed"]:
                blockers.append(f"{version}:{item['path']}:{item['start']}:{item['qualified_name']}: declaration/family review")
        for path, ledger in value["syntax_accounting"].items():
            for start, end, kind, disposition, identity in ledger["accounting"]:
                if disposition == "DECLARATION" and (identity, path, start, end) not in occurrences:
                    api.fail("lost overload / missing syntax-ledger declaration")
                if disposition == "UNRESOLVED":
                    blockers.append(f"{version}:{path}:{start}: unresolved syntax {kind}")
                if disposition not in {"DECLARATION", "UNRESOLVED", "TRIVIA_OR_DIRECTIVE"}:
                    api.fail("unknown syntax accounting disposition")
            if ledger["root_has_error"]:
                blockers.append(f"{version}:{path}: CST grammar recovery")
        for item in value["uncertainties"]:
            if item["blocking"]:
                blockers.append(f"{version}:{item['path']}:{item['start']}: {item['reason']}")
        excluded_now = sorted(item["path"] for item in headers if not item["in_scope"])
        reviewed_exclusions = review["reviewed_exclusions"]
        expected_exclusions = sorted(item["path"] for item in reviewed_exclusions if item["version"] == version)
        if any(item["scope_review"] == "REVIEWED" and not item["in_scope"] for item in headers):
            if excluded_now != expected_exclusions:
                api.fail("changed reviewed header exclusion list")
    for family, disposition in native["families"].items():
        if not disposition["reconciliation_reviewed"]:
            blockers.append(f"{family}: semantic reconciliation not reviewed")
    availability = defaultdict(set)
    for version, content in native["versions"].items():
        for item in content["declarations"]:
            availability[item["id"]].add(version)
    if native.get("declaration_availability") != {identity: sorted(versions) for identity, versions in availability.items()}:
        api.fail("lost overload or stale version-specific declaration availability")
    # Affirmative independent review is mandatory, never inferred from own parser output.
    if not review["compiler_or_independent_reconciliation"]:
        blockers.append("all in-scope headers: compiler-backed/independent declaration reconciliation absent")
    else:
        reviews = review["compiler_or_independent_reconciliation"]
        expected = {(version, item["path"], item["blob"])
                    for version, headers in scope["versions"].items()
                    for item in headers if item["in_scope"]}
        assessed = set()
        for entry in reviews:
            if not isinstance(entry, dict) or not all(entry.get(key) for key in (
                    "version", "path", "blob", "evidence", "method", "conditional_branch_evidence")):
                api.fail("missing affirmative independent header/conditional reconciliation evidence")
            key = entry["version"], entry["path"], entry["blob"]
            if key in assessed:
                api.fail("duplicate independent header review")
            assessed.add(key)
        if assessed != expected:
            blockers.append("independent reconciliation does not cover every in-scope pinned header")
    expected_reviewed = {(version, item["path"], item["blob"])
                         for version, headers in scope["versions"].items() for item in headers}
    reviewed = {(item["version"], item["path"], item["blob"]) for item in review["reviewed_headers"]}
    if reviewed != expected_reviewed:
        blockers.append("explicit reviewed-header list does not cover authenticated header scope")
    if native["upstream_discovery_complete"] and blockers:
        api.fail("false UPSTREAM_DISCOVERY_COMPLETE: unresolved source/review evidence")
    if complete and (blockers or not native["upstream_discovery_complete"]):
        api.fail("UPSTREAM_DISCOVERY_BLOCKED\n" + "\n".join(blockers[:30])
                 + f"\nTotal blocking observations: {len(blockers)}; full locations in discovery JSON")
    return scope, native, blockers


def summary(scope, native):
    for version, headers in scope["versions"].items():
        entries = native["versions"][version]
        declarations = entries["declarations"]
        categories = Counter(item["category"] for item in headers)
        print(f"{version}: headers={len(headers)}, in_scope={sum(item['in_scope'] for item in headers)}, "
              f"excluded={sum(not item['in_scope'] for item in headers)}, reviewed="
              f"{sum(item['scope_review']=='REVIEWED' for item in headers)}")
        print("  scope categories:", dict(sorted(categories.items())))
        print(f"  native occurrence records={len(declarations)}, distinct native IDs="
              f"{len({item['id'] for item in declarations})}, mapped="
              f"{sum(bool(item['family']) for item in declarations)}, excluded="
              f"{sum(bool(item['exclusion_reason']) for item in declarations)}, "
              f"unaccounted={sum(not item['family'] and not item['exclusion_reason'] for item in declarations)}, "
              f"uncertainties={len(entries['uncertainties'])}")
    print("UPSTREAM_DISCOVERY_COMPLETE:", native["upstream_discovery_complete"])
    print("ADA_COVERAGE_AUDIT_COMPLETE:", native["ada_coverage_audit_complete"])
    print("Provisional native family IDs:", len(native["families"]),
          "new IDs:", sum(not item["existing_seed"] for item in native["families"].values()))