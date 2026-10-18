#!/usr/bin/env python3
"""Offline, fail-closed Core coverage evidence checks (Python standard library).

Refresh reads local, official Git worktrees; it does not fetch or alter native
sources. This is a structured evidence collector, NOT an exhaustive C++ parser.
See docs/core-api-coverage.md for the deliberately separate acceptance gate.
"""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

from compare_gnatdoc_warnings import declaration_index, WarningComparisonError


ROOT = Path(__file__).resolve().parents[1]
VERSIONS = ("4.1.0", "4.6.0", "4.10.0", "5.0.0")
PINS = {
    "4.1.0": ("371bba8f54560b374fbcd47e7e02f015ac4969ad",
              "b1b20ff9642c0dff4e1788fc6b0148afa06d335f"),
    "4.6.0": ("b0dc474160e389b9c9045da5db49d03ae17c6a6b",
              "5f35a9f8f563ec920e2bc1a531f6158fd70f679c"),
    "4.10.0": ("71d3237a093b60a27601c20e9ee6c3e52154e8b1",
               "1f7a0c7fcc20571cab11da4c86ae1e796979df5b"),
    "5.0.0": ("40738fb16ceddb5fb3fea747585f7ce6abb0605b",
              "d24a3787c9a5a37a4167d1f506e447c7f385d88a"),
}
BASELINE = "64d8a60b59acfe4334045280e430c4774b5cad89"
STATUSES = {"BOUND_FULL", "BOUND_PARTIAL", "MISSING_PORTABLE",
            "VERSION_GATED", "INTENTIONALLY_EXCLUDED", "RESEARCH_REQUIRED"}
HEADERS = ["modules/core/include/opencv2/core.hpp"] + [
    "modules/core/include/opencv2/core/" + name for name in (
        "mat.hpp", "matx.hpp", "types.hpp", "base.hpp", "operations.hpp",
        "persistence.hpp", "utility.hpp", "affine.hpp", "quaternion.hpp",
        "dualquaternion.hpp", "async.hpp", "version.hpp", "optim.hpp",
        "ocl.hpp", "cuda.hpp", "hal/interface.h", "cvstd.hpp", "softfloat.hpp",
        "utils/logger.hpp", "utils/filesystem.hpp")]


class AuditError(ValueError):
    """Invalid evidence, ambiguous identity, or incomplete acceptance."""


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
                                    separators=(",", ":")).encode()).hexdigest()


def load(path):
    def pairs(entries):
        result = {}
        for key, value in entries:
            if key in result:
                raise AuditError(f"duplicate JSON key: {key}")
            result[key] = value
        return result
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"),
                          object_pairs_hook=pairs,
                          parse_constant=lambda value: fail(f"non-JSON {value}"))
    except (OSError, json.JSONDecodeError) as error:
        raise AuditError(f"{path}: {error}") from error


def fail(message):
    raise AuditError(message)


def schema_check(value, schema, whole=None, at="$"):
    """Validate the documented schema subset; reject unknown schema keywords."""
    whole = whole or schema
    supported = {"$schema", "$id", "$defs", "$ref", "title", "description",
                 "type", "properties", "required", "additionalProperties",
                 "items", "minItems", "minLength", "pattern", "enum"}
    if set(schema) - supported:
        fail(f"unsupported schema keywords at {at}: {set(schema) - supported}")
    if "$ref" in schema:
        prefix = "#/$defs/"
        if not schema["$ref"].startswith(prefix):
            fail("only local $defs schema references are supported")
        return schema_check(value, whole["$defs"][schema["$ref"][len(prefix):]],
                            whole, at)
    types = {"object": dict, "array": list, "string": str, "boolean": bool,
             "integer": int, "null": type(None)}
    if "type" in schema:
        kinds = schema["type"]
        kinds = kinds if isinstance(kinds, list) else [kinds]
        if any(kind not in types for kind in kinds):
            fail(f"unknown schema type at {at}")
        if not any(type(value) is types[kind] for kind in kinds):
            fail(f"{at}: expected {kinds}")
    if "enum" in schema and value not in schema["enum"]:
        fail(f"{at}: invalid enum {value!r}")
    if isinstance(value, dict):
        missing = set(schema.get("required", [])) - value.keys()
        if missing:
            fail(f"{at}: missing required {sorted(missing)}")
        properties = schema.get("properties", {})
        additional = schema.get("additionalProperties", True)
        for key, child in value.items():
            if key in properties:
                schema_check(child, properties[key], whole, at + "." + key)
            elif additional is False:
                fail(f"{at}: unknown field {key}")
            elif isinstance(additional, dict):
                schema_check(child, additional, whole, at + "." + key)
    if isinstance(value, list):
        if len(value) < schema.get("minItems", 0):
            fail(f"{at}: too few items")
        for index, child in enumerate(value):
            schema_check(child, schema.get("items", {}), whole, f"{at}[{index}]")
    if isinstance(value, str):
        if len(value) < schema.get("minLength", 0):
            fail(f"{at}: empty required text")
        if "pattern" in schema and not re.search(schema["pattern"], value):
            fail(f"{at}: pattern mismatch")


def git(root, *args):
    try:
        return subprocess.check_output(["git", "-C", str(root), *args],
                                       text=True, stderr=subprocess.PIPE).strip()
    except subprocess.CalledProcessError as error:
        raise AuditError(error.stderr.strip()) from error


def local_path(root, relative):
    path = (root / relative).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        fail(f"missing or unsafe local source mapping: {relative}")
    return path


def normalized(text):
    return " ".join(text.split())


def ada_index(path):
    try:
        grouped = declaration_index(path.read_text(encoding="utf-8").splitlines())
    except WarningComparisonError as error:
        raise AuditError(f"Ada declaration uncertainty in {path}: {error}") from error
    return [entry for entries in grouped.values() for entry in entries]


def evidence(path, start, end, root):
    lines = path.read_text(encoding="utf-8").splitlines()
    text = "\n".join(lines[start - 1:end])
    return {"path": str(path.relative_to(root)), "start": start, "end": end,
            "text": text, "sha256": hashlib.sha256(text.encode()).hexdigest()}


def check_evidence(entry, root):
    path = local_path(root, entry["path"])
    if not 1 <= entry["start"] <= entry["end"] <= len(path.read_text().splitlines()):
        fail(f"invalid source line range: {entry['path']}")
    actual = evidence(path, entry["start"], entry["end"], root)
    if actual != entry:
        fail(f"stale source evidence: {entry['path']}:{entry['start']}")


def cpp_code(text):
    """Preserve offsets while hiding comments and literal contents."""
    pattern = r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\''
    return re.sub(pattern, lambda m: re.sub(r"[^\n]", " ", m[0]), text)


def cpp_declarations(text, name):
    """Collect representative named declarations, retaining conditional guards.

    Overloads remain distinct by normalized declaration text. Templates, class
    bodies, macros, raw strings and namespace resolution require manual review;
    every result states that uncertainty instead of claiming an exhaustive AST.
    """
    code = cpp_code(text)
    lines = text.splitlines()
    result = []
    for match in re.finditer(r"\b" + re.escape(name) + r"\s*\(", code):
        line = code.count("\n", 0, match.start()) + 1
        begin = code.rfind("\n", 0, match.start()) + 1
        # Exclude qualified calls, prose stripped above, and examples in bodies.
        prefix = code[begin:match.start()]
        if "." in prefix or "->" in prefix or re.search(r"\breturn\b", prefix):
            continue
        pos, depth = code.index("(", match.start()) + 1, 1
        while pos < len(code) and depth:
            depth += (code[pos] == "(") - (code[pos] == ")")
            pos += 1
        end = pos
        while end < len(code) and code[end] not in ";{\n":
            end += 1
        # Multi-line const/noexcept suffixes are not resolved automatically.
        if end >= len(code) or code[end] != ";":
            continue
        finish = code.count("\n", 0, end) + 1
        guards = []
        for preceding in lines[:line - 1]:
            directive = preceding.strip()
            if re.match(r"#\s*(if|ifdef|ifndef)\b", directive):
                guards.append([directive])
            elif re.match(r"#\s*(else|elif)\b", directive) and guards:
                guards[-1].append(directive)
            elif re.match(r"#\s*endif\b", directive) and guards:
                guards.pop()
        result.append({"start": line, "end": finish,
                       "signature": normalized("\n".join(lines[line - 1:finish])),
                       "guards": [" / ".join(branch) for branch in guards],
                       "parse": "representative-only; manual scope/mode review required"})
    return result


def refresh(root, upstream_parent):
    reference = load(root / "docs/core-api-reference.json")
    provenance = {"official_remote": "https://github.com/opencv/opencv.git",
                  "versions": {}}
    for version in VERSIONS:
        source = upstream_parent / ("upstream-" + version)
        remote = git(source, "remote", "get-url", "origin")
        if remote != provenance["official_remote"]:
            fail(f"not the official upstream remote: {remote}")
        commit = git(source, "rev-parse", version + "^{commit}")
        tree = git(source, "rev-parse", version + "^{tree}")
        if (commit, tree) != PINS[version] or git(source, "rev-parse", "HEAD") != commit:
            fail(f"incorrect upstream identity for {version}")
        if git(source, "status", "--porcelain", "--", "modules/core"):
            fail(f"dirty upstream Core source for {version}")
        headers = {}
        for path in HEADERS:
            record = git(source, "ls-tree", commit, "--", path)
            if not record:
                headers[path] = None
                continue
            blob = record.split()[2]
            data = (source / path).read_bytes()
            actual_blob = hashlib.sha1(b"blob " + str(len(data)).encode()
                                       + b"\0" + data).hexdigest()
            if blob != actual_blob:
                fail(f"upstream blob mismatch: {version}:{path}")
            headers[path] = {"blob": blob, "sha256": hashlib.sha256(data).hexdigest(),
                             "url": f"https://github.com/opencv/opencv/blob/{commit}/{path}"}
        provenance["versions"][version] = {
            "tag_object": git(source, "rev-parse", "refs/tags/" + version),
            "commit": commit, "tree": tree, "headers": headers}

    records = []
    for family in reference["capabilities"]:
        record = dict(family)
        record["upstream"] = {}
        for version in VERSIONS:
            source = upstream_parent / ("upstream-" + version)
            locations = []
            for path, names in family["native_selectors"].items():
                file = source / path
                if not file.exists():
                    continue
                for name in names:
                    for declaration in cpp_declarations(file.read_text(), name):
                        declaration.update({"path": path, "name": name,
                                            "url": provenance["versions"][version]
                                            ["headers"][path]["url"]
                                            + f"#L{declaration['start']}"})
                        locations.append(declaration)
            record["upstream"][version] = {
                "availability": family["availability"][version],
                "declarations": locations}
        record["ada"] = []
        for selector in family["ada_selectors"]:
            path = local_path(root, selector["path"])
            found = [item for item in ada_index(path)
                     if item["name"].lower() == selector["name"].lower()
                     and selector.get("profile", "").lower()
                     in item["signature"].lower()]
            if not found:
                fail(f"removed Ada declaration: {selector}")
            for item in found:
                if item.get("ambiguous"):
                    fail(f"ambiguous Ada identity: {selector}")
                record["ada"].append({"identity": item["scope"] + "." + item["name"],
                                      "signature": item["signature"],
                                      "source": evidence(path, item["start"],
                                                         item["end"], root)})
        record["implementation"] = []
        for selector in family["implementation_selectors"]:
            path = local_path(root, selector["path"])
            matches = [i + 1 for i, line in enumerate(path.read_text().splitlines())
                       if re.search(selector["pattern"], line)]
            if not matches:
                fail(f"missing implementation mapping: {selector}")
            for start in matches:
                record["implementation"].append(evidence(
                    path, start, start + selector.get("lines", 3) - 1, root))
        record["tests"] = []
        for selector in family["test_selectors"]:
            path = local_path(root, selector["path"])
            matches = [i + 1 for i, line in enumerate(path.read_text().splitlines())
                       if re.search(selector["pattern"], line)]
            if not matches:
                fail(f"missing test mapping: {selector}")
            record["tests"].append(evidence(path, matches[0], matches[0] + 2, root))
        records.append(record)
    provenance["declaration_manifest_sha256"] = digest(
        {record["id"]: record["upstream"] for record in records})
    snapshot = {"schema_version": 1, "baseline": BASELINE,
                "reference_sha256": digest(reference),
                "provenance_sha256": digest(provenance),
                "discovery_complete": False,
                "unreviewed_scope": reference["unreviewed_scope"],
                "capabilities": records}
    for name, value in (("core-api-upstream.json", provenance),
                        ("core-api-coverage.json", snapshot)):
        (root / "docs" / name).write_text(json.dumps(value, indent=2) + "\n")


def validate(root, inventory=None, provenance=None, reference=None, complete=True):
    snapshot = inventory if inventory is not None else load(root / "docs/core-api-coverage.json")
    upstream = provenance if provenance is not None else load(root / "docs/core-api-upstream.json")
    reference = reference if reference is not None else load(root / "docs/core-api-reference.json")
    schema_check(snapshot, load(root / "docs/core-api-coverage.schema.json"))
    if snapshot["baseline"] != BASELINE:
        fail("unexpected audit baseline")
    if snapshot["reference_sha256"] != digest(reference):
        fail("reference fingerprint changed: review added/changed/removed capabilities")
    if snapshot["unreviewed_scope"] != reference["unreviewed_scope"]:
        fail("unresolved required scope was removed without reference review")
    if snapshot["provenance_sha256"] != digest(upstream):
        fail("upstream inventory fingerprint changed")
    if upstream.get("declaration_manifest_sha256") != digest(
            {record["id"]: record["upstream"] for record in snapshot["capabilities"]}):
        fail("upstream declaration inventory fingerprint changed")
    if upstream.get("official_remote") != "https://github.com/opencv/opencv.git":
        fail("missing official upstream provenance")
    if set(upstream["versions"]) != set(VERSIONS):
        fail("invalid upstream version labels")
    for version, pin in PINS.items():
        actual = upstream["versions"][version]
        if (actual["commit"], actual["tree"]) != pin:
            fail(f"changed upstream pin: {version}")
        if set(actual["headers"]) != set(HEADERS):
            fail(f"missing upstream header provenance: {version}")
        for path, header in actual["headers"].items():
            if header is not None and (not re.fullmatch(r"[a-f0-9]{40}", header["blob"])
                                       or not re.fullmatch(r"[a-f0-9]{64}", header["sha256"])):
                fail(f"invalid header fingerprint: {version}:{path}")
    ids = [record["id"] for record in snapshot["capabilities"]]
    if len(ids) != len(set(ids)):
        fail("duplicate stable capability IDs")
    expected = {record["id"]: record for record in reference["capabilities"]}
    if set(ids) != set(expected):
        fail("unreviewed/uncategorized reference entries")
    c_header = cpp_code(local_path(root, "cpp/opencv_core_shim.h").read_text())
    c_body = cpp_code(local_path(root, "cpp/opencv_core_shim.cpp").read_text())
    imports = local_path(root, "src/internal/opencv-internal-c_api.ads").read_text()
    for record in snapshot["capabilities"]:
        name, status = record["id"], record["classification"]
        for key, value in expected[name].items():
            if record.get(key) != value:
                fail(f"invalid status transition or stale reviewed data: {name}:{key}")
        if status not in STATUSES:
            fail(f"unknown classification: {name}")
        if set(record["availability"]) != set(VERSIONS) or set(record["upstream"]) != set(VERSIONS):
            fail(f"invalid version assignments: {name}")
        for version, item in record["upstream"].items():
            if item["availability"] != record["availability"][version]:
                fail(f"contradictory version assignments: {name}")
            if item["availability"] == "ABSENT" and item["declarations"]:
                fail(f"declaration contradicts absence: {name}:{version}")
            if item["availability"] == "PRESENT" and not item["declarations"]:
                fail(f"missing required upstream declaration provenance: {name}:{version}")
            for declaration in item["declarations"]:
                header = upstream["versions"][version]["headers"][declaration["path"]]
                if header is None or declaration["url"] != header["url"] + f"#L{declaration['start']}":
                    fail(f"invalid pinned upstream source link: {name}")
        for declaration in record["ada"]:
            check_evidence(declaration["source"], root)
            found = [item for item in ada_index(root / declaration["source"]["path"])
                     if item["scope"] + "." + item["name"] == declaration["identity"]
                     and item["signature"] == declaration["signature"]]
            if len(found) != 1 or found[0].get("ambiguous"):
                fail(f"removed or ambiguous Ada declaration: {name}")
        for entry in record["implementation"] + record["tests"]:
            check_evidence(entry, root)
        for symbol in record["c_abi"]:
            # Check a declaration, a definition, and the actual thin import.
            pattern = r"\b" + re.escape(symbol) + r"\s*\([^;{}]*\)\s*"
            if not re.search(pattern + ";", c_header) or not re.search(pattern + r"\{", c_body):
                fail(f"missing C ABI declaration/definition: {name}:{symbol}")
            if not re.search(r'External_Name\s*=>\s*"' + re.escape(symbol) + '"', imports):
                fail(f"missing thin Ada import: {name}:{symbol}")
        if status.startswith("BOUND_") and (not record["ada"] or not record["implementation"]):
            fail(f"bound capability lacks positive implementation evidence: {name}")
        for selector in record["ada_selectors"]:
            if not any(item["source"]["path"] == selector["path"]
                       and item["identity"].lower().endswith("." + selector["name"].lower())
                       and selector.get("profile", "").lower() in item["signature"].lower()
                       for item in record["ada"]):
                fail(f"missing selected Ada source mapping: {name}:{selector['name']}")
        if record["test_selectors"] and not record["tests"]:
            fail(f"missing selected test mappings: {name}")
        if status == "BOUND_FULL":
            if (not record["tests"] or not record["review_complete"]
                    or record["qualification_gaps"] or not record["mode_matrix"]
                    or any(mode["state"] != "VERIFIED" for mode in record["mode_matrix"])):
                fail(f"false full-coverage classification: {name}")
        if status == "MISSING_PORTABLE" and (record["ada"] or any(
                value != "PRESENT" for value in record["availability"].values())):
            fail(f"contradictory missing portable classification: {name}")
        if status == "VERSION_GATED" and len(set(record["availability"].values())) == 1:
            fail(f"version-gated family has no demonstrated version difference: {name}")
        if status == "INTENTIONALLY_EXCLUDED" and not record["exclusion_reason"]:
            fail(f"missing deliberate exclusion rationale: {name}")
    if complete:
        blockers = list(snapshot["unreviewed_scope"])
        blockers += [record["id"] for record in snapshot["capabilities"]
                     if not record["review_complete"]
                     or record["classification"] == "RESEARCH_REQUIRED"]
        if not snapshot["discovery_complete"] or blockers:
            fail("COVERAGE_AUDIT_BLOCKED: unresolved required entries:\n- "
                 + "\n- ".join(blockers))
    return snapshot


def summary(snapshot):
    records = snapshot["capabilities"]
    print("Evidence snapshot only; not an exhaustive Core coverage percentage.")
    for domain in sorted({item["domain"] for item in records}):
        group = [item for item in records if item["domain"] == domain]
        counts = Counter(item["classification"] for item in group)
        print(f"{domain}: n={len(group)}; " + "; ".join(
            f"{status}={counts[status]} ({100 * counts[status] / len(group):.1f}%)"
            for status in sorted(STATUSES)))
    print(f"Discovered seed families: {len(records)}; "
          f"discovery complete: {snapshot['discovery_complete']}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--allow-incomplete", action="store_true",
                        help="check evidence integrity only; NEVER claims audit acceptance")
    parser.add_argument("--refresh", type=Path, metavar="UPSTREAM_PARENT",
                        help="explicitly regenerate evidence from pinned official worktrees")
    parser.add_argument("--compare", type=Path, metavar="OLD_INVENTORY",
                        help="print semantic added/changed/removed IDs")
    parser.add_argument("--refresh-discovery", type=Path, metavar="UPSTREAM_PARENT",
                        help="enumerate all pinned header paths and parse all in-scope source branches")
    parser.add_argument("--check-discovery", action="store_true",
                        help="require independent native discovery closure, not Ada coverage closure")
    parser.add_argument("--discovery-diagnostics", action="store_true",
                        help="list exact unresolved native source paths and representative syntax")
    parser.add_argument("--lock-discovery-snapshot", action="store_true",
                        help="explicitly update discovery integrity lock, without granting review/closure")
    parser.add_argument("--refresh-compiler", type=Path, metavar="UPSTREAM_PARENT",
                        help="record independent active-configuration libclang census")
    parser.add_argument("--libclang", type=Path,
                        help="explicit libclang 19 library path for optional compiler refresh")
    parser.add_argument("--reconcile-compiler", action="store_true",
                        help="compare independent compiler declarations with source census candidates")
    parser.add_argument("--integrate-discovery-metadata", action="store_true",
                        help="link census fingerprints and provisional IDs without changing seed records")
    parser.add_argument("--write-discovery-report", action="store_true",
                        help="record all unresolved header paths and version-specific counts")
    parser.add_argument("--verify-discovery-checkout", type=Path, metavar="UPSTREAM_PARENT",
                        help="independently reproduce complete header paths/tree/blob proofs")
    args = parser.parse_args()
    try:
        if args.refresh:
            refresh(args.root, args.refresh)
        if args.refresh_discovery:
            import core_api_discovery
            core_api_discovery.refresh(args.root, args.refresh_discovery,
                                       sys.modules[__name__])
        if args.refresh_compiler:
            import core_api_discovery
            if not args.libclang:
                fail("--refresh-compiler requires explicit --libclang path")
            core_api_discovery.refresh_compiler(args.root, args.refresh_compiler,
                                                args.libclang, sys.modules[__name__])
        if args.reconcile_compiler:
            import core_api_discovery
            core_api_discovery.reconcile_compiler(args.root, sys.modules[__name__])
        if args.lock_discovery_snapshot:
            import core_api_discovery
            core_api_discovery.lock_snapshot(args.root, sys.modules[__name__])
        if args.integrate_discovery_metadata:
            import core_api_discovery
            core_api_discovery.integrate_metadata(args.root, sys.modules[__name__])
        if args.write_discovery_report:
            import core_api_discovery
            core_api_discovery.report(args.root, sys.modules[__name__])
        if args.verify_discovery_checkout:
            import core_api_discovery
            core_api_discovery.verify_checkout(args.root, args.verify_discovery_checkout,
                                               sys.modules[__name__])
        if (args.root / "docs/core-api-header-scope.json").exists():
            import core_api_discovery
            scope, native, blockers = core_api_discovery.validate(
                args.root, sys.modules[__name__], complete=args.check_discovery)
            core_api_discovery.validate_links(args.root, sys.modules[__name__])
            core_api_discovery.summary(scope, native)
            if args.discovery_diagnostics:
                core_api_discovery.diagnostics(args.root, sys.modules[__name__])
        elif args.check_discovery:
            fail("UPSTREAM_DISCOVERY_BLOCKED: header/declaration census missing")
        if args.check_discovery:
            return 0
        snapshot = validate(args.root, complete=not args.allow_incomplete)
        if args.compare:
            old = {item["id"]: item for item in load(args.compare)["capabilities"]}
            new = {item["id"]: item for item in snapshot["capabilities"]}
            print("added:", sorted(new.keys() - old.keys()))
            print("removed:", sorted(old.keys() - new.keys()))
            print("changed:", sorted(key for key in old.keys() & new.keys()
                                     if digest(old[key]) != digest(new[key])))
        summary(snapshot)
    except (AuditError, KeyError, TypeError, IndexError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())