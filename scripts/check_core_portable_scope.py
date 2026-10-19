#!/usr/bin/env python3
"""Offline, standard-library-only practical roadmap integrity (not an API audit)."""

import argparse
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
LEDGER = "docs/core-portable-scope.json"
BASELINE = "26bf5e2e8151cb0545b928b72d3d87677543c1ae"
AUDIT = "a87e9ab241703ce4262dbcd637ab9192536aebe8"
PINS = {
    "4.1.0": "371bba8f54560b374fbcd47e7e02f015ac4969ad",
    "4.6.0": "b0dc474160e389b9c9045da5db49d03ae17c6a6b",
    "4.10.0": "71d3237a093b60a27601c20e9ee6c3e52154e8b1",
    "5.0.0": "40738fb16ceddb5fb3fea747585f7ce6abb0605b",
}
DOCUMENTS = [
    "docs/core-portable-capabilities.md", "docs/core-finish-backlog.md",
    "docs/core-audit-provenance.md", "docs/core-portable-scope-schema.md",
]
# Exact reviewed decision/category/status/task map: changing scope requires review.
REQUIRED = {
    "scalar-modes": ("PORTABLE", "REQUIRED", "IMPLEMENTED_IN_MAIN", "CORE-FIN-01"),
    "general-norms": ("PORTABLE", "REQUIRED", "PLANNED_REQUIRED", "CORE-FIN-02"),
    "runtime-identity": ("PORTABLE", "REQUIRED", "PLANNED_REQUIRED", "CORE-FIN-03"),
    "transpose-nd": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", "CORE-OPT-01"),
    "flip-broadcast-nd": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", "CORE-OPT-01"),
    "runtime-timing": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", "CORE-OPT-02"),
    "runtime-optimization": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", "CORE-OPT-02"),
    "umat-copy-set": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", "CORE-OPT-03"),
    "umat-reshape-transforms": ("OPTIONAL", "DEFERRED_RESEARCH", "RESEARCH_REQUIRED", ""),
    "spectral-division": ("OPTIONAL", "DEFERRED_RESEARCH", "RESEARCH_REQUIRED", ""),
    "finite-mask": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", "CORE-OPT-01"),
    "sparse-baseline": ("PORTABLE", "ALREADY_SUFFICIENT", "EXISTING_LIMITED", ""),
    "sparse-extra-arithmetic": ("OPTIONAL", "DEFERRED_RESEARCH", "RESEARCH_REQUIRED", ""),
    "sparse-minmax": ("NATIVE_SURFACE", "INTENTIONALLY_EXCLUDED", "INTENTIONALLY_EXCLUDED", ""),
    "persistence-baseline": ("PORTABLE", "ALREADY_SUFFICIENT", "EXISTING_LIMITED", ""),
    "persistence-append-base64": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", "CORE-OPT-04"),
    "persistence-gzip": ("OPTIONAL", "DEFERRED_RESEARCH", "RESEARCH_REQUIRED", ""),
    "escaping-file-nodes": ("OPTIONAL", "INTENTIONALLY_EXCLUDED", "INTENTIONALLY_EXCLUDED", ""),
    "quaternion-affine": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", ""),
    "async-promise": ("OPTIONAL", "DEFERRED_RESEARCH", "RESEARCH_REQUIRED", ""),
    "new-depths-shape": ("OPTIONAL", "OPTIONAL_LATER", "OPTIONAL", ""),
    "device-backends": ("OPTIONAL", "INTENTIONALLY_EXCLUDED", "INTENTIONALLY_EXCLUDED", ""),
    "cpp-machinery": ("NATIVE_SURFACE", "INTENTIONALLY_EXCLUDED", "INTENTIONALLY_EXCLUDED", ""),
    "renamed-numerics": ("PORTABLE", "ALREADY_SUFFICIENT", "EXISTING_LIMITED", ""),
}
TASK_STATES = {
    "CORE-FIN-01": "IMPLEMENTED_IN_MAIN", "CORE-FIN-02": "PLANNED_REQUIRED",
    "CORE-FIN-03": "PLANNED_REQUIRED",
    **{f"CORE-OPT-0{i}": "OPTIONAL" for i in range(1, 5)},
}
# (version, path, start, end, Git blob, SHA-256 of historical selected text).
OBSERVATIONS = {
    "norm-41": ("4.1.0", "modules/core/src/norm.cpp", 1014, 1111,
                "d3eec98e385dc809add29bf44ca22d2a61186b81",
                "093044d20943b219ecb21ac7fe2c405e2b216ad11619927c753674106be72994"),
    "norm-int32-safety-41": ("4.1.0", "modules/core/src/norm.cpp", 218, 279,
                            "d3eec98e385dc809add29bf44ca22d2a61186b81",
                            "679c7d71e1dacb5c31c552f9b23462dff0eb5161126304fdc4ce5704723ba96e"),
    "norm-46": ("4.6.0", "modules/core/src/norm.cpp", 1077, 1175,
                "4df25f495722987ba1b0952d0bfebcd31f90324b",
                "58c5e68f0609c8756ff9d0fa7574cd38ea077d360ddf9043de7ef186309af306"),
    "norm-410": ("4.10.0", "modules/core/src/norm.cpp", 1073, 1171,
                 "f2f84c35b84e0f4e6fc5e54303b538305983b432",
                 "58c5e68f0609c8756ff9d0fa7574cd38ea077d360ddf9043de7ef186309af306"),
    "norm-50": ("5.0.0", "modules/core/src/norm.dispatch.cpp", 521, 616,
                "930c3b758a99ac8dfd9471d353e3847a5216f2ec",
                "ef9d3f8d66e0f7742030b941e799aee9c4b0af30e50053f53970533dd58b22f5"),
    "runtime-41": ("4.1.0", "modules/core/src/system.cpp", 806, 820,
                   "1cc2dcdca19ca4f011d8a101ca841c8dc25241f1",
                   "9469d655988a24e46494c62f7c7aeed9da8f623f145d31a21754dc8227e2af6c"),
    "runtime-46": ("4.6.0", "modules/core/src/system.cpp", 998, 1012,
                   "d2231fe952eea71670538ac134313f1dea9c18ae",
                   "9469d655988a24e46494c62f7c7aeed9da8f623f145d31a21754dc8227e2af6c"),
    "runtime-410": ("4.10.0", "modules/core/src/system.cpp", 1031, 1045,
                    "c02944079e4c3b43ba2da9e3e6da6362449c225a",
                    "9469d655988a24e46494c62f7c7aeed9da8f623f145d31a21754dc8227e2af6c"),
    "runtime-50": ("5.0.0", "modules/core/src/system.cpp", 1099, 1113,
                   "a52946b46a4172b0da25f2130c72188f8ff4943b",
                   "9469d655988a24e46494c62f7c7aeed9da8f623f145d31a21754dc8227e2af6c"),
}
RAW_NAMES = {
    "core-api-native-declarations.json", "core-api-compiler-evidence.json",
    "core-api-header-scope.json", "core-api-header-manifest.json",
    "core-api-discovery-blockers.json", "core-api-discovery-review.json",
    "core-api-coverage.json", "core-api-reference.json", "core-api-upstream.json",
    "core-portable-evidence.json", "audit_core_api.py",
}


class ScopeError(ValueError):
    """Malformed or contradictory planning data."""


def require(condition, message):
    if not condition:
        raise ScopeError(message)


def fields(value, names, label):
    require(type(value) is dict and set(value) == set(names.split()),
            f"{label}: missing/unknown fields")


def text(value, label):
    require(type(value) is str and bool(value.strip()), f"{label}: expected nonempty string")


def strings(value, label, nonempty=False):
    require(type(value) is list, f"{label}: expected list")
    for item in value:
        text(item, label)
    require(len(value) == len(set(value)), f"{label}: duplicates")
    require(not nonempty or bool(value), f"{label}: empty")


def records(value, label):
    require(type(value) is list and bool(value), f"{label}: expected nonempty array")
    result = {}
    for item in value:
        require(type(item) is dict, f"{label}: expected object")
        text(item.get("id"), label)
        require(item["id"] not in result, f"{label}: duplicate ID {item['id']}")
        result[item["id"]] = item
    return result


def local_path(root, name):
    text(name, "local path")
    require(not Path(name).is_absolute() and "\\" not in name,
            f"nonportable path: {name}")
    path = (root / name).resolve()
    require(path.is_relative_to(root.resolve()), f"path escapes checkout: {name}")
    require(path.is_file(), f"missing local file: {name}")
    require(path.name not in RAW_NAMES and not path.name.startswith("core-api-"),
            f"raw research dependency: {name}")
    return path


def public_ada(path):
    # Sufficient for these declaration specs, not an Ada parser or coverage index.
    source = re.sub(r"--[^\n]*", "", path.read_text(encoding="utf-8"))
    return re.split(r"(?im)^\s*private\s*$", source, maxsplit=1)[0]


def declaration(root, link):
    name, separator, fragment = link.partition("#")
    require(separator and re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", fragment),
            f"invalid Ada declaration link: {link}")
    require(name.startswith("src/") and "/internal/" not in name and name.endswith(".ads"),
            f"not a public Ada spec: {link}")
    source = public_ada(local_path(root, name))
    require(re.search(r"\b(?:type|subtype|function|procedure|package)\s+"
                      + re.escape(fragment) + r"\b", source, re.I),
            f"missing public Ada declaration: {link}")


def headings(source):
    # Roadmap uses simple ATX headings without inline markup; GitHub slug rules.
    result, counts = set(), {}
    for heading in re.findall(r"(?m)^#{1,6}\s+(.+?)\s*#*\s*$", source):
        slug = re.sub(r"[^\w\- ]", "", heading.lower()).replace(" ", "-")
        number = counts.get(slug, 0)
        counts[slug] = number + 1
        result.add(f"{slug}-{number}" if number else slug)
    return result


def check_link(root, link, parent="."):
    text(link, "link")
    parsed = urlsplit(link)
    if parsed.scheme or parsed.netloc:
        require(parsed.scheme == "https" and parsed.netloc == "github.com"
                and not parsed.query, f"unsupported external link: {link}")
        parts = parsed.path.strip("/").split("/")
        require(len(parts) >= 4, f"invalid GitHub link: {link}")
        repo = "/".join(parts[:2])
        if parts[2] in {"blob", "tree"}:
            allowed = set(PINS.values()) if repo == "opencv/opencv" else {AUDIT}
            require(repo in {"opencv/opencv", "zackboll/opencv_core_ada"}
                    and parts[3] in allowed and len(parts) >= (5 if parts[2] == "blob" else 4),
                    f"unpinned source link: {link}")
        else:
            require(repo == "zackboll/opencv_core_ada" and len(parts) == 4
                    and parts[2] == "pull" and parts[3] in {"89", "90"},
                    f"unexpected provenance link: {link}")
        return
    require(not parsed.query, f"local query unsupported: {link}")
    path = local_path(root, str(Path(parent) / unquote(parsed.path)))
    if parsed.fragment:
        fragment = unquote(parsed.fragment)
        if path.suffix == ".ads":
            declaration(root, f"{path.relative_to(root.resolve()).as_posix()}#{fragment}")
        else:
            require(path.suffix == ".md" and fragment in headings(path.read_text(encoding="utf-8")),
                    f"missing documentation fragment: {link}")


def check_documents(root, plan):
    docs = {}
    for name in plan["documents"]:
        source = local_path(root, name).read_text(encoding="utf-8")
        docs[name] = source
        # All Markdown links here are inline; reject unchecked reference-style links.
        require(not re.search(r"(?m)^\s*\[[^]]+\]:", source),
                f"unsupported reference-style link in {name}")
        for link in re.findall(r"\[[^]\n]*\]\(([^)\s]+)\)", source):
            check_link(root, link, str(Path(name).parent))
        for link in re.findall(r"<((?:https?://)[^>]+)>", source):
            check_link(root, link)
    matrix = docs[DOCUMENTS[0]]
    for item in plan["capabilities"]:
        row = next((line for line in matrix.splitlines()
                    if line.startswith(f"| `{item['id']}` |")), "")
        require(f"{item['decision']} / {item['implementation_status']}" in row,
                f"readable capability decision/status missing: {item['id']}")
    backlog = docs[DOCUMENTS[1]]
    for task in plan["tasks"]:
        require(task["id"] in backlog, f"task missing from readable backlog: {task['id']}")
    require("UPSTREAM_DISCOVERY_BLOCKED" in docs[DOCUMENTS[2]]
            and "COVERAGE_AUDIT_BLOCKED" in docs[DOCUMENTS[2]], "audit limits missing")


def scalar_profiles(root):
    source = re.sub(r"\s+", "", public_ada(local_path(root, "src/opencv-core.ads"))).lower()
    profiles = []
    for name in ("Add", "Subtract", "Multiply", "Divide"):
        profiles.extend([
            f"function {name} (Self : Mat; Value : Scalar) return Mat;",
            f"procedure {name} (Self : Mat; Value : Scalar; Destination : in out Mat);",
        ])
    for name in ("Subtract_From", "Divide_Into"):
        profiles.extend([
            f"function {name} (Value : Scalar; Self : Mat) return Mat;",
            f"procedure {name} (Value : Scalar; Self : Mat; Destination : in out Mat);",
        ])
    profiles.extend([
        "function Compare (Self : Mat; Value : Float64_Value; Kind : Comparison_Kind) return Mat;",
        "procedure Compare (Self : Mat; Value : Float64_Value; Kind : Comparison_Kind; Destination : in out Mat);",
    ])
    for profile in profiles:
        require(source.count(re.sub(r"\s+", "", profile).lower()) == 1,
                f"missing/duplicate FIN-01 scalar profile: {profile}")


def check_dependencies(tasks):
    visiting, done = set(), set()

    def visit(key):
        require(key not in visiting, f"cyclic task dependency: {key}")
        if key in done:
            return
        visiting.add(key)
        for dependency in tasks[key]["depends_on"]:
            require(dependency in tasks and dependency != key, f"invalid dependency: {dependency}")
            require(not key.startswith("CORE-FIN") or dependency.startswith("CORE-FIN"),
                    "required task depends on optional work")
            visit(dependency)
        visiting.remove(key)
        done.add(key)

    for key in tasks:
        visit(key)
    require(all(not tasks[key]["depends_on"] for key in tasks if key.startswith("CORE-FIN")),
            "required implementation tasks must remain independent")


def reject_completion(value):
    if type(value) is dict:
        for key, item in value.items():
            require(key not in {"upstream_discovery_complete", "ada_coverage_audit_complete"},
                    "unsupported exhaustive-completion field")
            reject_completion(item)
    elif type(value) is list:
        for item in value:
            reject_completion(item)
    elif type(value) is str:
        require(not re.search(r"\b(?:BOUND_FULL|UPSTREAM_DISCOVERY_COMPLETE|ADA_COVERAGE_AUDIT_COMPLETE)\b", value),
                "false exhaustive/full-coverage claim")


def validate(root=ROOT, plan=None):
    root = Path(root).resolve()
    if plan is None:
        plan = load(local_path(root, LEDGER))
    fields(plan, "schema_version baseline audit_commit crate_version discovery_status coverage_status "
           "supported_versions upstream documents observations tasks capabilities", "ledger")
    reject_completion(plan)
    require(type(plan["schema_version"]) is int and plan["schema_version"] == 1,
            "unsupported schema version")
    require(plan["baseline"] == BASELINE and plan["audit_commit"] == AUDIT, "wrong provenance commit")
    require(plan["crate_version"] == "0.5.1", "unapproved crate version")
    require(plan["discovery_status"] == "UPSTREAM_DISCOVERY_BLOCKED"
            and plan["coverage_status"] == "COVERAGE_AUDIT_BLOCKED", "false audit closure")
    strings(plan["supported_versions"], "supported versions", True)
    require(plan["supported_versions"] == list(PINS) and plan["upstream"] == PINS, "wrong native pins/versions")
    strings(plan["documents"], "documents", True)
    require(plan["documents"] == DOCUMENTS, "unexpected/missing roadmap documents")
    observations = records(plan["observations"], "observations")
    require(set(observations) == set(OBSERVATIONS), "missing/unknown source observation")
    for key, item in observations.items():
        fields(item, "id version path start end blob excerpt_sha256 url", key)
        require(all(type(item[name]) is int and item[name] > 0 for name in ("start", "end")),
                f"invalid source line interval: {key}")
        expected = tuple(item[name] for name in ("version", "path", "start", "end", "blob", "excerpt_sha256"))
        require(expected == OBSERVATIONS[key], f"changed source identity: {key}")
        url = f"https://github.com/opencv/opencv/blob/{PINS[item['version']]}/{item['path']}#L{item['start']}"
        require(item["url"] == url, f"unpinned observation URL: {key}")
        check_link(root, item["url"])
    tasks = records(plan["tasks"], "tasks")
    require(set(tasks) == set(TASK_STATES), "missing/unknown task")
    for key, task in tasks.items():
        fields(task, "id implementation_status depends_on versions observations document", key)
        require(task["implementation_status"] == TASK_STATES[key], f"wrong task status: {key}")
        for field in ("depends_on", "versions", "observations"):
            strings(task[field], f"{key} {field}", field == "versions")
        require(set(task["versions"]) <= set(PINS), f"unsupported task version: {key}")
        expected_versions = list(PINS)[1:] if key == "CORE-OPT-01" else list(PINS)
        require(task["versions"] == expected_versions, f"changed task versions: {key}")
        expected_sources = {name for name in OBSERVATIONS
                            if (key == "CORE-FIN-02" and name.startswith("norm-"))
                            or (key == "CORE-FIN-03" and name.startswith("runtime-"))}
        require(set(task["observations"]) == expected_sources, f"missing/wrong task sources: {key}")
        if expected_sources:
            require({observations[name]["version"] for name in expected_sources} == set(PINS),
                    f"incomplete four-version source requirements: {key}")
        text(task["document"], f"{key} document")
        require(task["document"].startswith("docs/core-finish-backlog.md#"), f"wrong task document: {key}")
        check_link(root, task["document"])
    check_dependencies(tasks)
    capabilities = records(plan["capabilities"], "capabilities")
    require(set(capabilities) == set(REQUIRED), "missing/unknown practical capability")
    for key, item in capabilities.items():
        fields(item, "id description category decision implementation_status versions ada consumer_value "
               "restrictions provenance tasks", key)
        for field in ("description", "category", "decision", "implementation_status", "consumer_value", "restrictions"):
            text(item[field], f"{key} {field}")
        for field in ("versions", "ada", "provenance", "tasks"):
            strings(item[field], f"{key} {field}", field in {"versions", "provenance"})
        expected = REQUIRED[key]
        require(tuple(item[field] for field in ("category", "decision", "implementation_status")) == expected[:3]
                and item["tasks"] == ([expected[3]] if expected[3] else []),
                f"changed reviewed decision/status/task mapping: {key}")
        expected_versions = {
            "transpose-nd": list(PINS)[1:], "flip-broadcast-nd": list(PINS)[2:],
            "spectral-division": ["5.0.0"], "finite-mask": ["5.0.0"],
            "async-promise": list(PINS)[1:], "new-depths-shape": ["5.0.0"],
        }.get(key, list(PINS))
        require(item["versions"] == expected_versions, f"changed capability versions: {key}")
        if item["implementation_status"] in {"IMPLEMENTED_IN_MAIN", "EXISTING_LIMITED"}:
            require(bool(item["ada"]), f"implemented capability lacks Ada evidence: {key}")
        credited = {
            "scalar-modes": {"Add", "Subtract", "Multiply", "Divide", "Subtract_From", "Divide_Into", "Compare"},
            "general-norms": {"Norm", "Norm_Kind", "K_Nearest_Neighbors"},
            "sparse-baseline": {"From_Dense", "Norm", "Normalize"},
            "persistence-baseline": {"Open", "Create_Memory", "Map_Key", "Storage_Mode"},
            "renamed-numerics": {"Matrix_Multiply", "Matrix_Multiply_Add", "Transposed_Product",
                                 "Singular_Value_Decomposition", "Principal_Component_Analysis",
                                 "Covariance", "Min_Max_Indices", "Multiply_Packed_Spectra", "K_Nearest_Neighbors"},
        }.get(key, set())
        require(credited <= {link.partition("#")[2] for link in item["ada"]},
                f"missing credited Ada family evidence: {key}")
        for link in item["ada"]:
            declaration(root, link)
        for link in item["provenance"]:
            check_link(root, link)
    scalar_profiles(root)
    check_documents(root, plan)
    manifest = local_path(root, "alire.toml").read_text(encoding="utf-8")
    require(re.search(r'(?m)^version\s*=\s*"0\.5\.1"\s*$', manifest), "crate version changed")
    # Reject tracked or untracked raw snapshots without traversing .git objects.
    for directory in (root / "docs", root / "scripts"):
        for path in directory.rglob("*"):
            require(path.name not in RAW_NAMES and not path.name.startswith("core-api-"),
                    f"raw research artifact present: {path.relative_to(root)}")
    return plan


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, f"duplicate JSON key: {key}")
        result[key] = value
    return result


def invalid_constant(value):
    raise ScopeError(f"nonfinite JSON constant: {value}")


def load(path):
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object,
                      parse_constant=invalid_constant)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        plan = validate(args.root)
    except (ValueError, TypeError, KeyError, OSError, RecursionError) as error:
        print(f"Practical scope FAILED: {error}", file=sys.stderr)
        return 1
    print(f"Practical scope PASS: {len(plan['capabilities'])} decisions, 7 tasks, "
          "14 scalar profiles; local documentation links and four pinned references checked.")
    print("FIN-01 implemented; FIN-02/03 pending. Planning integrity only; exhaustive audit remains blocked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())