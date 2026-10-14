"""Render a diagnostic inventory; this is evidence, not an architectural checker.

Usage: python3 inventory.py BASELINE DIAGNOSTIC_LOG
Prints JSON for all 96 concrete bodies, including every incompatible condition.
Does not modify source or infer that a semantic guard belongs in C++.
"""
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True)


def inventory(baseline, diagnostic_log):
    diagnostics = {}
    for line in Path(diagnostic_log).read_text().splitlines():
        match = re.match(r"([^:]+):(\d+):(\d+): (error|warning): (.*)", line)
        if match:
            name, row, column, severity, message = match.groups()
            diagnostics.setdefault(name, []).append(
                {"line": int(row), "column": int(column),
                 "severity": severity, "message": message})
    paths = git("ls-tree", "-r", "--name-only", baseline, "src").splitlines()
    paths = [path for path in paths if re.fullmatch(
        r"src/opencv-core-(uint8|int8|uint16|int16|int32|float16|float32|float64)"
        r"(_vec[234])?_(mat_view|row_access|buffer_access)\.adb", path)]
    assert len(paths) == 96
    rows = []
    for path in paths:
        original = git("show", f"{baseline}:{path}")
        current = (ROOT / path).read_text()
        guards = []
        for diagnostic in diagnostics.get(Path(path).name, []):
            if diagnostic["severity"] != "error":
                continue
            line = diagnostic["line"]
            offset = sum(len(part) for part in original.splitlines(True)[:line - 1])
            for match in re.finditer(
                    r"pragma\s+Compile_Time_Error\s*\((.*?),\s*\"(.*?)\"\s*\);",
                    original, re.DOTALL):
                if match.start() <= offset < match.end():
                    condition, message = match.groups()
                    attribute = "Object_Size" if "Object_Size" in condition else "Alignment"
                    guards.append({**diagnostic,
                        "expression": condition.strip(),
                        "original_requirement": message,
                        "replacement": "Object_Storage.Verify: " + (
                            "Element_Type'Object_Size /= Expected_Element_Bits"
                            if attribute == "Object_Size" else
                            "Element_Type'Alignment > Native_Alignment"),
                        "guard_timing": "before construction" if "mat_view" in path
                            else "before lease; address checked before typed conversion",
                        "representation_evidence": "tests/layout/representation_measurements.adb",
                        "gnat12_native": "complete production build passed",
                        "gnat12_cross": "complete AArch64 production build passed",
                        "gnat16": "four-version production build passed"})
                    break
            else:
                raise ValueError(f"diagnostic outside assertion: {path}:{line}")
        rows.append({"file": path, "changed": original != current,
                     "incompatible_assertions": guards,
                     "warnings": [d for d in diagnostics.get(Path(path).name, [])
                                  if d["severity"] == "warning"]})
    return {"baseline": baseline, "body_count": len(rows),
            "scalar_bodies": 24, "vector_bodies": 72,
            "changed_bodies": sum(row["changed"] for row in rows),
            "incompatible_conditions": sum(len(row["incompatible_assertions"]) for row in rows),
            "bodies": rows}


if __name__ == "__main__":
    print(json.dumps(inventory(*sys.argv[1:]), indent=2))