#!/usr/bin/env python3
"""Compare GNATdoc warnings by Ada declaration, not by source position.

A warning identity is the filename, the normalized declaration signature, and
the warning message. Source line and column numbers only locate that
declaration in the current sources. They are not part of the identity.

The same parameter name on two overloads therefore cannot cancel. Inserting an
overload, moving a declaration, or editing only its documentation comments does
not change the signature. A historical warning that disappears while the same
text appears on another declaration is both a removal and an addition, and the
addition fails the comparison.

Every current warning must map to exactly one declaration. Ambiguous or
unmapped locations fail closed. Warning-shaped diagnostics that do not match
the pinned GNATdoc 26.0.0 format also fail, including malformed baseline
entries. Ordinary non-warning log text is ignored.

The baseline is the normalized identity list produced by --write-baseline from
one complete GNATdoc log and the sources of that same revision. It is not a
raw copy of the log: a later comment edit would make those old line numbers
name a different declaration.
"""

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

WARNING_RE = re.compile(
    r"^(?P<file>[^:\s]+):(?P<line>\d+):(?P<column>\d+):\s+warning:\s+(?P<message>.+)$"
)
WARNING_HINT_RE = re.compile(r"(^|\s)warning:", re.IGNORECASE)
HEADER_RE = re.compile(
    r"(\s*)((?:overriding|not|abstract|private)\s+)*"
    r"(procedure|function|package|type|subtype)\b"
)
OBJECT_RE = re.compile(r"^(\s*)([A-Za-z][A-Za-z0-9_.]*)\s*:")
NAME_AFTER_KEYWORD_RE = re.compile(
    r"\s*([A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)*)"
)


class WarningComparisonError(Exception):
    """A diagnostic cannot be identified safely."""


def code_only(line):
    """Drop a trailing Ada comment. This binding does not use '--' in strings."""
    marker = line.find("--")
    return line if marker < 0 else line[:marker]


def name_at(line, column):
    """Return the identifier occupying a 1-based column, ignoring comments."""
    if line.lstrip().startswith("--"):
        return None
    if not (0 < column <= len(line)):
        return None
    if column > 1 and (line[column - 2].isalnum() or line[column - 2] == "_"):
        return None
    if not (line[column - 1].isalpha() or line[column - 1] == "_"):
        return None
    end = column - 1
    while end < len(line) and (line[end].isalnum() or line[end] in "._"):
        end += 1
    return line[column - 1:end]


def declaration_index(lines):
    """Index normalized declarations by the column and name GNATdoc reports.

    The signature keeps the declaration keyword, name, profile, and semicolon.
    Whitespace is collapsed and comments are removed. Two overloads stay
    distinct because their profiles differ.
    """
    declarations = []
    index = 0
    while index < len(lines):
        raw = lines[index]
        code = code_only(raw)
        header = HEADER_RE.match(code)
        object_header = None if header else OBJECT_RE.match(code)
        if header is None and object_header is None:
            index += 1
            continue
        if header is not None:
            name_match = NAME_AFTER_KEYWORD_RE.match(code[header.end():])
            if name_match is None:
                index += 1
                continue
            name = name_match.group(1)
            column = raw.find(name, header.end()) + 1
            kind = header.group(3)
        else:
            name = object_header.group(2)
            column = raw.find(name) + 1
            kind = "object"
        depth = 0
        parts = []
        end = index
        cursor = index
        while cursor < len(lines) and cursor - index < 80:
            piece = code_only(lines[cursor])
            parts.append(" ".join(piece.split()))
            depth += piece.count("(") - piece.count(")")
            package_ends = (
                kind == "package" and depth <= 0 and re.search(r"\bis\b|;", piece)
            )
            record_continues = (
                kind == "type" and depth <= 0 and re.search(r"\brecord\b", piece)
                and "end record" not in piece
            )
            other_ends = (
                kind != "package" and not record_continues and ";" in piece
                and depth <= 0
            )
            if package_ends or other_ends:
                end = cursor
                break
            cursor += 1
        else:
            end = cursor
        signature = re.sub(r"\s+", " ", " ".join(part for part in parts if part))
        signature = re.sub(r"\(\s+", "(", signature)
        signature = re.sub(r"\s+\)", ")", signature)
        signature = re.sub(r"\s*,\s*", ", ", signature)
        signature = re.sub(r"\s*:\s*", " : ", signature)
        signature = re.sub(r"\s*;", ";", signature)
        signature = re.sub(r"\s+", " ", signature).strip()
        declaration = {
            "start": index + 1,
            "end": end + 1,
            "column": column,
            "name": name,
            "signature": signature.strip(),
        }
        declarations.append(declaration)
        if kind == "type" and " record" in signature:
            for component_line in range(index, end + 1):
                component = OBJECT_RE.match(code_only(lines[component_line]))
                if component is None or component.group(2) == name:
                    continue
                component_name = component.group(2)
                component_column = lines[component_line].find(component_name) + 1
                declarations.append(
                    {
                        "start": component_line + 1,
                        "end": component_line + 1,
                        "column": component_column,
                        "name": component_name,
                        "signature": signature.strip(),
                    }
                )
        index = end + 1
    indexed = {}
    for declaration in declarations:
        key = (declaration["column"], declaration["name"], declaration["signature"])
        indexed.setdefault(key, []).append(declaration)
    for duplicates in indexed.values():
        if len(duplicates) > 1:
            for declaration in duplicates:
                declaration["ambiguous"] = True
    by_location = {}
    for declaration in declarations:
        by_location.setdefault(
            (declaration["column"], declaration["name"]), []
        ).append(declaration)
    return by_location

def _comment_gap(lines, start, stop):
    return all(
        not lines[cursor].strip() or lines[cursor].strip().startswith("--")
        for cursor in range(start, stop)
    )


def locate_declaration(lines, indexed, line_number, column):
    """Find the one declaration named at this column.

    GNATdoc 26.0.0 points at the declaration name. Scanning may continue
    through a directly preceding comment block, because an older log line can
    land there after comments are inserted. It stops at the first code line
    and never crosses another declaration. Zero or several matches fail.
    """
    delta = 0
    while line_number + delta <= len(lines) and delta <= 80:
        source_line = lines[line_number + delta - 1]
        name = name_at(source_line, column)
        if name is not None:
            hits = [
                declaration
                for declaration in indexed.get((column, name), [])
                if declaration["start"] <= line_number + delta <= declaration["end"]
            ]
            if len(hits) != 1 or hits[0].get("ambiguous"):
                raise WarningComparisonError(
                    f"ambiguous or unmapped declaration at column {column} "
                    f"name {name}"
                )
            if delta != 0 and not _comment_gap(
                lines, line_number - 1, line_number - 1 + delta
            ):
                raise WarningComparisonError(
                    f"warning column crossed unrelated code before {name}"
                )
            return hits[0]
        stripped = source_line.strip()
        if stripped and not stripped.startswith("--"):
            raise WarningComparisonError(
                f"column {column} is not a declaration name on line {line_number}"
            )
        delta += 1
    raise WarningComparisonError(
        f"no declaration name at column {column} near line {line_number}"
    )


def parse_warnings(text, label):
    """Return warning records. Unrecognized warning-shaped lines fail."""
    records = []
    for number, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        if not stripped:
            continue
        match = WARNING_RE.match(stripped)
        if match is None:
            if WARNING_HINT_RE.search(stripped):
                raise WarningComparisonError(
                    f"{label}:{number}: unrecognized warning diagnostic: {stripped}"
                )
            continue
        records.append(
            (
                match.group("file"),
                int(match.group("line")),
                int(match.group("column")),
                match.group("message").strip(),
            )
        )
    return records


def identities_from_log(text, source_root, label):
    """Map one GNATdoc log to stable declaration identities."""
    records = parse_warnings(text, label)
    sources = {}
    indexes = {}
    identities = []
    for filename, line_number, column, message in records:
        if filename not in sources:
            path = source_root / filename
            if not path.is_file():
                raise WarningComparisonError(
                    f"{label}: missing Ada source for warning: {path}"
                )
            sources[filename] = path.read_text(encoding="utf-8").splitlines()
            indexes[filename] = declaration_index(sources[filename])
        try:
            declaration = locate_declaration(
                sources[filename], indexes[filename], line_number, column
            )
        except WarningComparisonError as error:
            raise WarningComparisonError(
                f"{label}: {filename}:{line_number}:{column}: {error}"
            ) from error
        identities.append(f"{filename}: {declaration['signature']}: warning: {message}")
    return identities


def parse_baseline(text):
    """Return identities from a structured baseline. Malformed lines fail."""
    identities = []
    for number, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        if not stripped:
            continue
        marker = stripped.rfind(": warning: ")
        filename = stripped.split(": ", 1)[0]
        if WARNING_RE.match(stripped) or marker < 0 or not filename.endswith(".ads"):
            raise WarningComparisonError(
                f"baseline:{number}: malformed baseline identity: {stripped}"
            )
        identities.append(stripped)
    return identities


def compare_identities(baseline_identities, current_identities):
    """Return added and removed identities, preserving duplicate occurrences."""
    baseline = Counter(baseline_identities)
    current = Counter(current_identities)
    added = []
    removed = []
    for identity, count in sorted((current - baseline).items()):
        added.extend([identity] * count)
    for identity, count in sorted((baseline - current).items()):
        removed.extend([identity] * count)
    return added, removed


def compare(baseline_text, current_text, source_root):
    """Compare a structured baseline with a current GNATdoc log."""
    return compare_identities(
        parse_baseline(baseline_text),
        identities_from_log(current_text, source_root, "current"),
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("current", type=Path)
    parser.add_argument(
        "--sources",
        type=Path,
        default=None,
        help="Directory containing the Ada sources named by the log",
    )
    parser.add_argument(
        "--write-baseline",
        action="store_true",
        help="Write normalized identities for the current log",
    )
    args = parser.parse_args(argv)
    source_root = args.sources
    if source_root is None:
        source_root = Path(__file__).resolve().parent.parent / "src"
    try:
        if args.write_baseline:
            identities = identities_from_log(
                args.current.read_text(encoding="utf-8"), source_root, "current"
            )
            args.baseline.write_text("\n".join(identities) + "\n", encoding="utf-8")
            print(f"Wrote {len(identities)} declaration warning identities")
            return 0
        added, removed = compare(
            args.baseline.read_text(encoding="utf-8"),
            args.current.read_text(encoding="utf-8"),
            source_root,
        )
    except WarningComparisonError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    print(
        "GNATdoc warning delta: {added} added, {removed} removed".format(
            added=len(added), removed=len(removed)
        )
    )
    for item in added:
        print("added: " + item)
    for item in removed:
        print("removed: " + item)
    return 1 if added else 0


if __name__ == "__main__":
    sys.exit(main())

