#!/usr/bin/env python3
"""Practical planning checks, independent of forensic discovery acceptance.

Normal checks are offline/stdlib-only. Explicit capture reads pinned local
sources and writes only the new practical evidence ledger, never old artifacts.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlsplit

import audit_core_api as audit


ROOT = Path(__file__).resolve().parents[1]
PLAN = "docs/core-portable-scope.json"
EVIDENCE = "docs/core-portable-evidence.json"
BASELINE = "bd60e969e2a2471c1bb4b90d3006e53f3f6e09eb"
DECISIONS = {"REQUIRED_FOR_0_6", "OPTIONAL_LATER", "DEFERRED_RESEARCH",
             "INTENTIONALLY_EXCLUDED", "ALREADY_SUFFICIENT"}
STATUSES = {"MISSING_CONFIRMED", "EXISTING_LIMITED", "OPTIONAL", "RESEARCH", "EXCLUDED"}
DOCUMENTS = ("docs/core-portable-capabilities.md", "docs/core-finish-backlog.md",
             "docs/core-audit-artifact-policy.md")
REQUIRED_CANDIDATES = {
    "scalar-modes", "general-norms", "runtime-identity", "transpose-nd",
    "flip-broadcast-nd", "runtime-timing", "runtime-optimization", "umat-copy-set",
    "umat-reshape-transforms", "spectral-division", "finite-mask", "sparse-baseline",
    "sparse-extra-arithmetic", "sparse-minmax", "persistence-baseline",
    "persistence-append-base64", "persistence-gzip", "escaping-file-nodes",
    "quaternion-affine", "async-promise", "new-depths-shape", "device-backends",
    "cpp-machinery", "renamed-numerics"}
PROTECTED = {
    "docs/core-api-compiler-evidence.json": "49a81301c0b4391a95ff9b1c52f7d44ad861b15f",
    "docs/core-api-coverage.json": "10ee2d8f8a0cda9aa992357582b59ae6195bd21a",
    "docs/core-api-discovery-blockers.json": "47116f1da39c5ea14b8163c4042c80c1ee441a69",
    "docs/core-api-discovery-review.json": "dc208b0ae3965d95203cd6ad0a1973fe209fff98",
    "docs/core-api-header-manifest.json": "eeb25bcc0ddb690b9cba1b0dffee4ba87c6528a5",
    "docs/core-api-header-scope.json": "1fc4cdf21e06b8e9c186e96a47b97f6497aacb74",
    "docs/core-api-native-declarations.json": "7a0f5c82a7f531c440e9ca3093924538bef4792c",
    "docs/core-api-reference.json": "1e001ddc4c0689c6c1945d2bee8a0ea96784a36b",
    "docs/core-api-upstream.json": "3f403310b9f3be3cfc626eb7d3cabb8ac82d89d9",
}


def blob(data):
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def require(condition, message):
    if not condition:
        raise audit.AuditError(message)


def check_preservation(root, protected=None):
    for path, expected_blob in (PROTECTED if protected is None else protected).items():
        require(blob(audit.local_path(root, path).read_bytes()) == expected_blob,
                f"forensic evidence changed during practical planning: {path}")


def check_document_links(root, name, text):
    """These simple Markdown documents use inline links, not embedded HTML."""
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", text):
        url = urlsplit(target)
        if url.scheme:
            if url.netloc == "github.com" and url.path.startswith("/opencv/opencv/"):
                parts = url.path.split("/")
                require(len(parts) >= 6 and parts[3] in {"blob", "tree"} and
                        parts[4] in {pin[0] for pin in audit.PINS.values()},
                        "unpinned practical Markdown upstream link")
        elif url.path:
            path = (root / name).parent / unquote(url.path)
            require(path.resolve().is_relative_to(root.resolve()) and path.exists(),
                    f"broken practical Markdown local link: {name}:{target}")


def capture(root, parent):
    plan = audit.load(root / PLAN)
    records = []
    for selector in plan["native_evidence_selectors"]:
        version = selector["version"]
        source = parent / ("upstream-" + version)
        commit, tree = audit.PINS[version]
        require(audit.git(source, "remote", "get-url", "origin") ==
                "https://github.com/opencv/opencv.git", "unofficial practical evidence remote")
        require((audit.git(source, "rev-parse", "HEAD"), audit.git(source, "rev-parse", "HEAD^{tree}"))
                == (commit, tree), "wrong practical evidence checkout")
        require(not audit.git(source, "status", "--porcelain", "--", selector["path"]),
                "dirty practical evidence source")
        data = (source / selector["path"]).read_bytes()
        object_id = audit.git(source, "rev-parse", commit + ":" + selector["path"])
        require(blob(data) == object_id, "practical evidence blob mismatch")
        lines = data.decode().splitlines()
        text = "\n".join(lines[selector["start"] - 1:selector["end"]])
        records.append(dict(selector, commit=commit, tree=tree, blob=object_id,
                            sha256=hashlib.sha256(text.encode()).hexdigest(), text=text,
                            url=f"https://github.com/opencv/opencv/blob/{commit}/{selector['path']}#L{selector['start']}"))
    evidence = {"schema_version": 1, "plan_sha256": audit.digest(plan), "sources": records}
    (root / EVIDENCE).write_text(json.dumps(evidence, indent=2) + "\n")


def validate(root, plan=None, evidence=None, documents=True, preservation=True):
    plan = audit.load(root / PLAN) if plan is None else plan
    evidence = audit.load(root / EVIDENCE) if evidence is None else evidence
    require(plan.get("schema_version") == 1 and plan.get("baseline") == BASELINE,
            "invalid practical scope schema/baseline")
    require(plan.get("upstream_discovery_complete") is False and
            plan.get("ada_coverage_audit_complete") is False, "practical plan falsely certifies forensic closure")
    require(set(plan.get("objectives", {})) == {"PORTABLE", "OPTIONAL", "NATIVE_SURFACE"},
            "missing separate practical objectives")
    require(evidence.get("schema_version") == 1 and evidence.get("plan_sha256") == audit.digest(plan),
            "stale practical plan/evidence fingerprint")
    candidates = plan.get("candidates", [])
    ids = [item["id"] for item in candidates]
    require(len(ids) == len(set(ids)), "duplicate practical capability ID")
    require(set(ids) == REQUIRED_CANDIDATES, "missing or unreviewed practical candidate")
    tasks = plan.get("tasks", [])
    task_ids = [item["id"] for item in tasks]
    require(len(task_ids) == len(set(task_ids)), "duplicate practical task ID")
    require(plan.get("first_tasks") == ["CORE-FIN-01", "CORE-FIN-02", "CORE-FIN-03"] and
            task_ids[:3] == plan["first_tasks"], "first three are not the ready implementation tasks")
    inventory = audit.load(root / "docs/core-api-reference.json")
    seed_ids = {item["id"] for item in inventory["capabilities"]}
    for item in candidates:
        require(item["decision"] in DECISIONS and item["status"] in STATUSES,
                "invalid practical decision/status")
        require(item["objective"] in plan["objectives"] and bool(item.get("reason", "").strip()),
                "missing practical decision rationale")
        require(set(item["tasks"]) <= set(task_ids), "unknown practical backlog dependency")
        require(set(item["inventory_ids"]) <= seed_ids, "unknown existing semantic inventory reference")
        if item["decision"] == "REQUIRED_FOR_0_6":
            require(item["objective"] == "PORTABLE" and bool(item["tasks"]),
                    "mandatory feature lacks portable bounded implementation task")
        if item["status"] == "RESEARCH":
            require(item["decision"] == "DEFERRED_RESEARCH", "research silently promoted to implemented/missing")
    sources = evidence.get("sources", [])
    source_ids = [item["id"] for item in sources]
    require(len(source_ids) == len(set(source_ids)), "duplicate practical source identity")
    selectors = {item["id"]: item for item in plan["native_evidence_selectors"]}
    require(set(source_ids) == set(selectors), "missing required practical source evidence")
    for item in sources:
        require(all(item.get(key) == value for key, value in selectors[item["id"]].items()),
                "stale practical source selector")
        require(item["version"] in audit.PINS and (item["commit"], item["tree"]) == audit.PINS[item["version"]],
                "wrong pinned practical source version")
        require(item["sha256"] == hashlib.sha256(item["text"].encode()).hexdigest() and bool(item["text"]),
                "changed practical source excerpt fingerprint")
        require(item["url"] == f"https://github.com/opencv/opencv/blob/{item['commit']}/{item['path']}#L{item['start']}",
                "unpinned practical source link")
        require(re.fullmatch(r"[a-f0-9]{40}", item["blob"]) is not None, "missing practical source blob")
    by_source = {item["id"]: item for item in sources}
    for index, task in enumerate(tasks):
        for field in ("scope", "api", "exclusions", "tests", "complexity"):
            require(bool(task.get(field, "").strip()), "incomplete practical implementation task")
        require(set(task["versions"]) <= set(audit.VERSIONS) and bool(task["versions"]), "invalid task version strategy")
        require(set(task["depends_on"]) <= set(task_ids) and task["id"] not in task["depends_on"],
                "unknown/cyclic task prerequisite")
        require(set(task["source_evidence"]) <= set(source_ids), "missing task source mapping")
        if index < 3:
            require(task["kind"] == "IMPLEMENTATION" and task["ready"] is True and not task["depends_on"],
                    "first task blocked on unrelated audit/research")
            require(set(task["versions"]) == set(audit.VERSIONS) and bool(task["source_evidence"]),
                    "ready task lacks four-version support evidence")
            require({by_source[key]["version"] for key in task["source_evidence"]} == set(audit.VERSIONS),
                    "ready task lacks pinned implementation evidence on each version")
    for selector in plan["local_evidence"]:
        path = audit.local_path(root, selector["path"])
        found = [item for item in audit.ada_index(path) if item["name"].lower() == selector["name"].lower()
                 and selector.get("profile", "").lower() in item["signature"].lower()]
        require(bool(found), "removed/changed credited Ada declaration")
    if documents:
        text = {}
        for name in DOCUMENTS:
            text[name] = audit.local_path(root, name).read_text()
            check_document_links(root, name, text[name])
        require(all(item["id"] in text[DOCUMENTS[0]] for item in candidates), "candidate missing from readable matrix")
        require(all(item["id"] in text[DOCUMENTS[1]] for item in tasks), "task missing from readable backlog")
        require("Git history" in text[DOCUMENTS[2]] and "successor PR" in text[DOCUMENTS[2]],
                "missing artifact retention/history decision")
    if preservation:
        check_preservation(root)
    return plan


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--capture", type=Path, metavar="PINNED_UPSTREAM_PARENT")
    args = parser.parse_args()
    try:
        if args.capture:
            capture(args.root, args.capture)
        plan = validate(args.root)
        print(f"Practical scope: {len(plan['candidates'])} explicit decisions; first tasks: "
              + ", ".join(plan["first_tasks"]))
        print("Planning integrity verified; no exhaustive coverage or native discovery certification.")
    except (audit.AuditError, KeyError, TypeError, OSError, subprocess.CalledProcessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())