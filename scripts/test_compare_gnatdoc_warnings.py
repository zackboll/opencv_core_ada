#!/usr/bin/env python3
"""Unit tests for the GNATdoc warning baseline comparison."""

import unittest

from compare_gnatdoc_warnings import compare


BASELINE = """\
opencv-core.ads:10:14: warning: entity `Polar_To_Cart` is not documented
opencv-core.ads:10:14: warning: parameter `Angle` is not documented
opencv-core.ads:22:14: warning: entity `Polar_To_Cart` is not documented
opencv-core.ads:22:14: warning: parameter `Destination` is not documented
opencv.ads:4:9: warning: entity `Point` is not documented
noise: this is not a warning
"""


class CompareWarningsTest(unittest.TestCase):
    def test_duplicate_overloads_remain_distinct(self):
        added, removed = compare(BASELINE, BASELINE)
        self.assertEqual((added, removed), ([], []))
        current = BASELINE.replace(
            "opencv-core.ads:22:14: warning: entity `Polar_To_Cart` is not documented\n",
            "",
            1,
        )
        added, removed = compare(BASELINE, current)
        self.assertEqual(added, [])
        self.assertEqual(
            removed,
            [
                "opencv-core.ads:22:14: warning: entity `Polar_To_Cart` is not documented"
            ],
        )

    def test_reordered_diagnostics_match(self):
        current = "\n".join(reversed(BASELINE.splitlines())) + "\n"
        self.assertEqual(compare(BASELINE, current), ([], []))

    def test_shifted_line_numbers_match(self):
        current = BASELINE.replace(":10:", ":110:").replace(":22:", ":140:")
        current = current.replace("opencv.ads:4:", "opencv.ads:80:")
        self.assertEqual(compare(BASELINE, current), ([], []))

    def test_new_warning_is_reported_without_hiding_history(self):
        current = BASELINE + (
            "opencv-core.ads:30:14: warning: parameter `Units` is not documented\n"
        )
        added, removed = compare(BASELINE, current)
        self.assertEqual(removed, [])
        self.assertEqual(
            added,
            ["opencv-core.ads:30:14: warning: parameter `Units` is not documented"],
        )

    def test_duplicate_occurrence_is_an_addition(self):
        current = BASELINE + (
            "opencv.ads:40:9: warning: entity `Point` is not documented\n"
        )
        added, removed = compare(BASELINE, current)
        self.assertEqual(
            added, ["opencv.ads:40:9: warning: entity `Point` is not documented"]
        )
        self.assertEqual(removed, [])

    def test_eliminated_warning_is_reported_and_not_added(self):
        lines = [
            line
            for line in BASELINE.splitlines()
            if "parameter `Destination`" not in line
        ]
        added, removed = compare(BASELINE, "\n".join(lines) + "\n")
        self.assertEqual(added, [])
        self.assertEqual(
            removed,
            [
                "opencv-core.ads:22:14: warning: parameter `Destination` is not documented"
            ],
        )

    def test_same_column_different_lines_do_not_collapse(self):
        """Two overloads at column 14 stay two baseline occurrences."""
        baseline = """\
opencv-core.ads:10:14: warning: entity `Polar_To_Cart` is not documented
opencv-core.ads:22:14: warning: entity `Polar_To_Cart` is not documented
"""
        current = baseline + (
            "opencv-core.ads:30:14: warning: entity `Polar_To_Cart` is not documented\n"
        )
        added, removed = compare(baseline, current)
        self.assertEqual(removed, [])
        self.assertEqual(
            added,
            ["opencv-core.ads:30:14: warning: entity `Polar_To_Cart` is not documented"],
        )


if __name__ == "__main__":
    unittest.main()
