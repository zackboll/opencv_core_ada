"""Compiler regression for actual positional/named typed-vector returns.

Run with ADA_COMPILER=gcc-12 (or the cross compiler/GNAT 16 gcc).
No production compatibility claim: only this translation unit is compiled.
"""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src/internal/opencv-core-internal-typed_access.adb"


class AggregateTests(unittest.TestCase):
    def compile(self, path, directory):
        return subprocess.run(
            [os.environ.get("ADA_COMPILER", "gcc-12"), "-c", "-gnat2022",
             "-gnatwa", "-gnatwe", "-Werror", "-fPIC",
             f"-I{ROOT / 'src'}", f"-I{ROOT / 'src/internal'}", str(path)],
            cwd=directory, text=True, capture_output=True)

    def test_production_context_has_no_obsolete_aggregates(self):
        with tempfile.TemporaryDirectory() as directory:
            result = self.compile(SOURCE, directory)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_record_aggregates_and_calls_remain_parenthesized(self):
        source = SOURCE.read_text()
        self.assertIn("V : aliased OpenCV.Internal.C_API.UInt8_Vec2 := (others => 0);",
                      source)
        self.assertIn("(OpenCV.Internal.C_API.C_UInt8 (Value (0)),\n"
                      "         OpenCV.Internal.C_API.C_UInt8 (Value (1)));", source)
        self.assertIn('Raise_On_Error (S, "UInt8 Vec2 read");', source)

    def test_original_positional_and_named_forms_are_rejected(self):
        forms = (
            ("[UInt8_Value (V.Component_0), UInt8_Value (V.Component_1)]",
             "(UInt8_Value (V.Component_0), UInt8_Value (V.Component_1))"),
            ("[0 => Float64_Value (V.Component_0),\n"
             "         1 => Float64_Value (V.Component_1),\n"
             "         2 => Float64_Value (V.Component_2)]",
             "(0 => Float64_Value (V.Component_0),\n"
             "         1 => Float64_Value (V.Component_1),\n"
             "         2 => Float64_Value (V.Component_2))"),
        )
        original = SOURCE.read_text()
        for corrected, obsolete in forms:
            with self.subTest(form=obsolete), tempfile.TemporaryDirectory() as directory:
                self.assertIn(corrected, original)
                path = Path(directory) / SOURCE.name
                path.write_text(original.replace(corrected, obsolete, 1))
                result = self.compile(path, directory)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("array aggregate using ()", result.stderr)
                self.assertIn("-gnatwj", result.stderr)


if __name__ == "__main__":
    unittest.main()