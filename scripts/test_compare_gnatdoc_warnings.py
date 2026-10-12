#!/usr/bin/env python3
"""Regression tests for declaration-aware GNATdoc warning comparison."""

import tempfile
import textwrap
import unittest
from pathlib import Path

from compare_gnatdoc_warnings import (
    WarningComparisonError,
    compare,
    identities_from_log,
    parse_baseline,
    parse_warnings,
)


SPEC = textwrap.dedent(
    """\
    package Demo is

       type Point is record
          X : Integer;
          Y : Integer;
       end record;

       procedure Procedure_A (Image : Matrix);
       procedure Procedure_B (Image : Matrix);

       function Polar_To_Cart (Angle : Mat) return Coordinates;
       procedure Polar_To_Cart
         (Angle : Mat; Destination : in out Coordinates);

       procedure Later (Image : Matrix);

    end Demo;
    """
)


def write_sources(root, text=SPEC, name="demo.ads"):
    (root / name).write_text(text, encoding="utf-8")


class CompareWarningsTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        write_sources(self.root)
        self.baseline = "\n".join(
            identities_from_log(self._log(), self.root, "baseline")
        ) + "\n"

    def tearDown(self):
        self.temporary.cleanup()

    def _lines(self):
        return [
            "demo.ads:3:9: warning: entity `Point` is not documented",
            "demo.ads:4:7: warning: component `X` is not documented",
            "demo.ads:8:14: warning: parameter `Image` is not documented",
            "demo.ads:9:14: warning: parameter `Image` is not documented",
            "demo.ads:11:13: warning: entity `Polar_To_Cart` is not documented",
            "demo.ads:12:14: warning: entity `Polar_To_Cart` is not documented",
            "demo.ads:15:14: warning: entity `Later` is not documented",
        ]

    def _log(self, replacements=None, extra="", preamble="info: parsed demo.ads\n"):
        rebuilt = []
        for line in self._lines():
            if replacements and line in replacements:
                if replacements[line] is not None:
                    rebuilt.append(replacements[line])
            else:
                rebuilt.append(line)
        return preamble + "\n".join(rebuilt) + "\n" + extra

    def test_identical_warnings_pass(self):
        self.assertEqual(compare(self.baseline, self._log(), self.root), ([], []))

    def test_pure_line_shift_passes(self):
        write_sources(self.root, "\n\n" + SPEC)
        moved = {
            "demo.ads:3:9: warning: entity `Point` is not documented":
                "demo.ads:5:9: warning: entity `Point` is not documented",
            "demo.ads:4:7: warning: component `X` is not documented":
                "demo.ads:6:7: warning: component `X` is not documented",
            "demo.ads:8:14: warning: parameter `Image` is not documented":
                "demo.ads:10:14: warning: parameter `Image` is not documented",
            "demo.ads:9:14: warning: parameter `Image` is not documented":
                "demo.ads:11:14: warning: parameter `Image` is not documented",
            "demo.ads:11:13: warning: entity `Polar_To_Cart` is not documented":
                "demo.ads:13:13: warning: entity `Polar_To_Cart` is not documented",
            "demo.ads:12:14: warning: entity `Polar_To_Cart` is not documented":
                "demo.ads:14:14: warning: entity `Polar_To_Cart` is not documented",
            "demo.ads:15:14: warning: entity `Later` is not documented":
                "demo.ads:17:14: warning: entity `Later` is not documented",
        }
        self.assertEqual(compare(self.baseline, self._log(moved), self.root), ([], []))

    def test_reordered_diagnostics_pass(self):
        body = [line for line in self._log().splitlines() if "warning:" in line]
        current = "\n".join(reversed(body)) + "\n"
        self.assertEqual(compare(self.baseline, current, self.root), ([], []))

    def test_new_warning_fails(self):
        current = self._log(
            extra="demo.ads:15:14: warning: parameter `Image` is not documented\n"
        )
        added, removed = compare(self.baseline, current, self.root)
        self.assertEqual(removed, [])
        self.assertEqual(len(added), 1)
        self.assertIn("procedure Later (Image : Matrix);", added[0])

    def test_removed_warning_is_reported_and_succeeds(self):
        current = self._log(
            {"demo.ads:15:14: warning: entity `Later` is not documented": None}
        )
        added, removed = compare(self.baseline, current, self.root)
        self.assertEqual(added, [])
        self.assertEqual(len(removed), 1)
        self.assertIn("procedure Later", removed[0])

    def test_additional_duplicate_occurrence_fails(self):
        current = self._log(
            extra="demo.ads:9:14: warning: parameter `Image` is not documented\n"
        )
        added, removed = compare(self.baseline, current, self.root)
        self.assertEqual(removed, [])
        self.assertEqual(
            added,
            [
                "demo.ads: Demo.Procedure_B: procedure Procedure_B (Image : Matrix);: "
                "warning: parameter `Image` is not documented"
            ],
        )

    def test_overloads_stay_distinct(self):
        identities = identities_from_log(self._log(), self.root, "current")
        image = [item for item in identities if "parameter `Image`" in item]
        polar = [item for item in identities if "entity `Polar_To_Cart`" in item]
        self.assertEqual(len(set(image)), 2)
        self.assertEqual(len(set(polar)), 2)

    def test_same_text_on_another_declaration_fails(self):
        """Historical false negative: same file, column, and message."""
        current_source = textwrap.dedent(
            """\
            package Demo is

               type Point is record
                  X : Integer;
                  Y : Integer;
               end record;

               --  Procedure_A Image is now documented.
               procedure Procedure_A (Image : Matrix);
               procedure Procedure_B (Image : Matrix);

               function Polar_To_Cart (Angle : Mat) return Coordinates;
               procedure Polar_To_Cart
                 (Angle : Mat; Destination : in out Coordinates);

               procedure Replacement (Image : Matrix);

            end Demo;
            """
        )
        write_sources(self.root, current_source)
        current = self._log(
            {
                "demo.ads:8:14: warning: parameter `Image` is not documented": None,
                "demo.ads:9:14: warning: parameter `Image` is not documented":
                    "demo.ads:10:14: warning: parameter `Image` is not documented",
                "demo.ads:11:13: warning: entity `Polar_To_Cart` is not documented":
                    "demo.ads:12:13: warning: entity `Polar_To_Cart` is not documented",
                "demo.ads:12:14: warning: entity `Polar_To_Cart` is not documented":
                    "demo.ads:13:14: warning: entity `Polar_To_Cart` is not documented",
                "demo.ads:15:14: warning: entity `Later` is not documented":
                    "demo.ads:16:14: warning: parameter `Image` is not documented",
            }
        )
        added, removed = compare(self.baseline, current, self.root)
        self.assertTrue(any("Procedure_A" in item for item in removed))
        self.assertTrue(any("Replacement" in item for item in added))
        self.assertFalse(any("Procedure_B" in item for item in added + removed))

    def test_inserted_overload_does_not_shift_matches(self):
        current_source = textwrap.dedent(
            """\
            package Demo is

               type Point is record
                  X : Integer;
                  Y : Integer;
               end record;

               procedure Procedure_A (Image : Matrix);
               procedure Inserted (Other : Matrix);
               procedure Procedure_B (Image : Matrix);

               function Polar_To_Cart (Angle : Mat) return Coordinates;
               procedure Polar_To_Cart
                 (Angle : Mat; Destination : in out Coordinates);

               procedure Later (Image : Matrix);

            end Demo;
            """
        )
        write_sources(self.root, current_source)
        current = self._log(
            {
                "demo.ads:9:14: warning: parameter `Image` is not documented":
                    "demo.ads:10:14: warning: parameter `Image` is not documented",
                "demo.ads:11:13: warning: entity `Polar_To_Cart` is not documented":
                    "demo.ads:12:13: warning: entity `Polar_To_Cart` is not documented",
                "demo.ads:12:14: warning: entity `Polar_To_Cart` is not documented":
                    "demo.ads:13:14: warning: entity `Polar_To_Cart` is not documented",
                "demo.ads:15:14: warning: entity `Later` is not documented":
                    "demo.ads:16:14: warning: entity `Later` is not documented",
            }
        )
        self.assertEqual(compare(self.baseline, current, self.root), ([], []))

    def test_documentation_and_movement_do_not_false_positive(self):
        current_source = textwrap.dedent(
            """\
            package Demo is
               --  Moved and documented around, signatures unchanged.

               type Point is record
                  X : Integer;  --  horizontal
                  Y : Integer;
               end record;

               procedure Later (Image : Matrix);

               procedure Procedure_B (Image : Matrix);
               procedure Procedure_A (Image : Matrix);

               procedure Polar_To_Cart
                 (Angle : Mat; Destination : in out Coordinates);
               function Polar_To_Cart (Angle : Mat) return Coordinates;

            end Demo;
            """
        )
        write_sources(self.root, current_source)
        current = "\n".join(
            [
                "demo.ads:9:14: warning: entity `Later` is not documented",
                "demo.ads:11:14: warning: parameter `Image` is not documented",
                "demo.ads:12:14: warning: parameter `Image` is not documented",
                "demo.ads:14:14: warning: entity `Polar_To_Cart` is not documented",
                "demo.ads:16:13: warning: entity `Polar_To_Cart` is not documented",
                "demo.ads:4:9: warning: entity `Point` is not documented",
                "demo.ads:5:7: warning: component `X` is not documented",
            ]
        ) + "\n"
        self.assertEqual(compare(self.baseline, current, self.root), ([], []))

    def test_different_categories_do_not_cancel(self):
        current = self._log(
            {
                "demo.ads:15:14: warning: entity `Later` is not documented":
                    "demo.ads:15:14: warning: parameter `Image` is not documented"
            }
        )
        added, removed = compare(self.baseline, current, self.root)
        self.assertEqual(len(added), 1)
        self.assertEqual(len(removed), 1)
        self.assertIn("parameter `Image`", added[0])
        self.assertIn("entity `Later`", removed[0])

    def test_unrecognized_warning_format_fails(self):
        with self.assertRaises(WarningComparisonError) as caught:
            parse_warnings(
                "demo.ads: warning: parameter `Image` is not documented\n",
                "current",
            )
        self.assertIn("unrecognized warning diagnostic", str(caught.exception))

    def test_malformed_baseline_fails(self):
        with self.assertRaises(WarningComparisonError) as caught:
            parse_baseline(
                "demo.ads:8:14: warning: parameter `Image` is not documented\n"
            )
        self.assertIn("malformed baseline identity", str(caught.exception))

    def test_non_warning_output_is_ignored(self):
        current = self._log(
            preamble="GNATdoc 26.0.0\nDocumentation coverage: public\n"
        )
        self.assertEqual(compare(self.baseline, current, self.root), ([], []))

    def test_ambiguous_declaration_identity_fails_closed(self):
        write_sources(
            self.root,
            textwrap.dedent(
                """\
                package Demo is
                   procedure Get (Image : Matrix);
                   procedure Get ( Image : Matrix);
                end Demo;
                """
            ),
        )
        with self.assertRaises(WarningComparisonError) as caught:
            identities_from_log(
                "demo.ads:3:14: warning: parameter `Image` is not documented\n",
                self.root,
                "current",
            )
        self.assertIn("ambiguous or unmapped", str(caught.exception))

    def test_nested_package_signatures_stay_distinct(self):
        source = textwrap.dedent(
            """\
            package Demo is
               package Inner is
                  procedure Read (Image : Mat);
               end Inner;

               procedure Read (Image : Mat);
            end Demo;
            """
        )
        write_sources(self.root, source)
        log = (
            "demo.ads:3:17: warning: parameter `Image` is not documented\n"
            "demo.ads:6:14: warning: parameter `Image` is not documented\n"
        )
        identities = identities_from_log(log, self.root, "current")
        self.assertEqual(len(set(identities)), 2)
        self.assertTrue(any(": Demo.Inner.Read:" in item for item in identities))
        self.assertTrue(any(": Demo.Read:" in item for item in identities))
        self.assertFalse(any("Demo.Demo" in item for item in identities))

    def test_warning_moved_between_scopes_fails(self):
        source = textwrap.dedent(
            """\
            package Demo is
               package Inner is
                  procedure Read (Image : Mat);
               end Inner;

               procedure Read (Image : Mat);
            end Demo;
            """
        )
        write_sources(self.root, source)
        baseline_log = "demo.ads:3:17: warning: parameter `Image` is not documented\n"
        current_log = "demo.ads:6:14: warning: parameter `Image` is not documented\n"
        baseline = "\n".join(
            identities_from_log(baseline_log, self.root, "baseline")
        ) + "\n"
        added, removed = compare(baseline, current_log, self.root)
        self.assertEqual(len(added), 1)
        self.assertEqual(len(removed), 1)
        self.assertIn("Demo.Read", added[0])
        self.assertIn("Demo.Inner.Read", removed[0])

    def test_indentation_does_not_merge_scopes(self):
        source = textwrap.dedent(
            """\
            package Demo is
            package Inner is
            procedure Read (Image : Mat);
            end Inner;
            procedure Read (Image : Mat);
            end Demo;
            """
        )
        write_sources(self.root, source)
        identities = identities_from_log(
            "demo.ads:3:11: warning: parameter `Image` is not documented\n"
            "demo.ads:5:11: warning: parameter `Image` is not documented\n",
            self.root,
            "current",
        )
        self.assertEqual(len(set(identities)), 2)

    def test_record_components_with_the_same_name_stay_distinct(self):
        source = textwrap.dedent(
            """\
            package Demo is
               type Left is record
                  Image : Integer;
               end record;
               type Right is record
                  Image : Integer;
               end record;
            end Demo;
            """
        )
        write_sources(self.root, source)
        identities = identities_from_log(
            "demo.ads:2:9: warning: component `Image` is not documented\n"
            "demo.ads:5:9: warning: component `Image` is not documented\n",
            self.root,
            "current",
        )
        self.assertIn("Demo.Left.Image", identities[0])
        self.assertIn("Demo.Right.Image", identities[1])

    def test_multiline_function_keeps_return_profile(self):
        source = textwrap.dedent(
            """\
            package Demo is
               function Get
                 (Image : Mat; Row, Column : Integer)
                  return OpenCV.Core.Float16_Vec3.Vector;
            end Demo;
            """
        )
        write_sources(self.root, source)
        identities = identities_from_log(
            "demo.ads:2:13: warning: entity `Get` is not documented\n",
            self.root,
            "current",
        )
        self.assertIn("return OpenCV.Core.Float16_Vec3.Vector;", identities[0])
        self.assertIn("(Image : Mat; Row, Column : Integer)", identities[0])

    def test_multiline_procedure_keeps_complete_profile(self):
        source = textwrap.dedent(
            """\
            package Demo is
               procedure Set
                 (Image : in out Mat;
                  Value : Vector);
            end Demo;
            """
        )
        write_sources(self.root, source)
        identities = identities_from_log(
            "demo.ads:2:14: warning: parameter `Value` is not documented\n",
            self.root,
            "current",
        )
        self.assertIn("Value : Vector", identities[0])
        self.assertIn("in out Mat", identities[0])

    def test_qualified_return_overloads_stay_distinct(self):
        source = textwrap.dedent(
            """\
            package Demo is
               function Get (Image : Mat) return OpenCV.Core.Float16_Vec3.Vector;
               function Get (Image : Mat) return OpenCV.Core.Float32_Vec3.Vector;
            end Demo;
            """
        )
        write_sources(self.root, source)
        identities = identities_from_log(
            "demo.ads:2:13: warning: entity `Get` is not documented\n"
            "demo.ads:3:13: warning: entity `Get` is not documented\n",
            self.root,
            "current",
        )
        self.assertIn("Float16_Vec3.Vector", identities[0])
        self.assertIn("Float32_Vec3.Vector", identities[1])
        self.assertNotEqual(identities[0], identities[1])

    def test_comments_and_movement_do_not_change_scoped_identity(self):
        source = textwrap.dedent(
            """\
            package Demo is
               --  moved below a comment
               function Get
                 (Image : Mat; Row, Column : Integer)
                  return OpenCV.Core.Float16_Vec3.Vector;
            end Demo;
            """
        )
        write_sources(self.root, source)
        moved = identities_from_log(
            "demo.ads:3:13: warning: entity `Get` is not documented\n",
            self.root,
            "current",
        )
        original = textwrap.dedent(
            """\
            package Demo is
               function Get
                 (Image : Mat; Row, Column : Integer)
                  return OpenCV.Core.Float16_Vec3.Vector;
            end Demo;
            """
        )
        write_sources(self.root, original)
        baseline = identities_from_log(
            "demo.ads:2:13: warning: entity `Get` is not documented\n",
            self.root,
            "baseline",
        )
        self.assertEqual(moved, baseline)

    def test_string_literals_do_not_corrupt_declaration_scanning(self):
        source = textwrap.dedent(
            """\
            package Demo is
               Label : constant String := "a; b -- still a string";
               procedure Read (Image : Mat);
            end Demo;
            """
        )
        write_sources(self.root, source)
        identities = identities_from_log(
            "demo.ads:3:14: warning: parameter `Image` is not documented\n",
            self.root,
            "current",
        )
        self.assertIn("Demo.Read", identities[0])
        self.assertIn("procedure Read (Image : Mat);", identities[0])

    def test_generic_and_discriminant_keep_scope(self):
        source = textwrap.dedent(
            """\
            generic
               type Element_Type is private;
            package Demo is
               type Result (Valid : Boolean := False) is record
                  Image : Element_Type;
               end record;
            end Demo;
            """
        )
        write_sources(self.root, source)
        identities = identities_from_log(
            "demo.ads:3:9: warning: generic formal `Element_Type` is not documented\n"
            "demo.ads:4:9: warning: component `Valid` is not documented\n"
            "demo.ads:4:9: warning: component `Image` is not documented\n",
            self.root,
            "current",
        )
        self.assertIn("generic Element_Type", identities[0])
        self.assertIn("Demo.Result.Valid", identities[1])
        self.assertIn("Demo.Result.Image", identities[2])

    def test_unsupported_unclosed_scope_fails_closed(self):
        write_sources(
            self.root,
            "package Demo is\n   procedure Read (Image : Mat);\n",
        )
        with self.assertRaises(WarningComparisonError) as caught:
            identities_from_log(
                "demo.ads:2:14: warning: parameter `Image` is not documented\n",
                self.root,
                "current",
            )
        self.assertIn("unclosed Ada scope", str(caught.exception))




if __name__ == "__main__":
    unittest.main()




