#!/usr/bin/env python3
"""Compare GNATdoc warnings with a version-controlled baseline.

Each diagnostic keeps its filename, source line, column, warning category,
and declaration or parameter identity. Duplicate occurrences stay duplicated.
Comparison treats a pure source-line shift as the same warning: identities
are matched by filename, column, and message, while unchanged regions keep
their original line numbers. Historical warnings remain allowed. A new
occurrence fails the comparison. Eliminated warnings are reported and do not
fail it.
"""

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

WARNING_RE = re.compile(
    r"^(?P<file>[^:\s]+):(?P<line>\d+):(?P<column>\d+):\s+warning:\s+(?P<message>.*)$"
)


def parse(text):
    """Return warning records, ignoring non-warning log lines."""
    records = []
    for raw in text.splitlines():
        match = WARNING_RE.match(raw.strip())
        if match is None:
            continue
        records.append(
            (
                match.group("file"),
                int(match.group("line")),
                int(match.group("column")),
                match.group("message"),
            )
        )
    return records


def identity(record):
    """Format one warning without discarding duplicate occurrences."""
    filename, line, column, message = record
    return f"{filename}:{line}:{column}: warning: {message}"


def stable_key(record):
    """Key that is unchanged when only the source line number moves."""
    filename, _line, column, message = record
    return (filename, column, message)


def compare(baseline_text, current_text):
    """Return sorted added and removed warning identities.

    Within one file, column, and message, occurrences are paired in source
    order. Pairs may have different line numbers. Unpaired baseline records
    were eliminated; unpaired current records are new.
    """
    baseline_groups = defaultdict(list)
    current_groups = defaultdict(list)
    for record in parse(baseline_text):
        baseline_groups[stable_key(record)].append(record)
    for record in parse(current_text):
        current_groups[stable_key(record)].append(record)

    added = []
    removed = []
    for key in sorted(set(baseline_groups) | set(current_groups)):
        old = baseline_groups.get(key, [])
        new = current_groups.get(key, [])
        extra = len(new) - len(old)
        if extra > 0:
            added.extend(identity(record) for record in new[len(old):])
        elif extra < 0:
            removed.extend(identity(record) for record in old[len(new):])
    return added, removed


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("current", type=Path)
    args = parser.parse_args(argv)
    added, removed = compare(
        args.baseline.read_text(encoding="utf-8"),
        args.current.read_text(encoding="utf-8"),
    )
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
