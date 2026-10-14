"""Real source-unit compiler controls, not complete GNAT 12 build coverage.

ADA_COMPILER selects native Debian gcc-12 or its AArch64 counterpart.
All compiler outputs are disposable; production source is never rewritten.
"""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LanguagePolicyTests(unittest.TestCase):
    def compile(self, unit, mode=None):
        with tempfile.TemporaryDirectory(prefix="core-language-policy.") as output:
            command = [os.environ.get("ADA_COMPILER", "gcc-12"), "-c",
                       "-gnatwa", "-gnatwe", "-Werror", "-fPIC",
                       f"-I{ROOT / 'src'}", f"-I{ROOT / 'src/internal'}"]
            if mode:
                command.append(mode)
            command.append(str(ROOT / unit))
            return subprocess.run(command, cwd=output, text=True,
                                  capture_output=True)

    def test_actual_generic_others_arrays(self):
        for unit in ("opencv-core-sparse-typed_iteration_impl.adb",
                     "opencv-core-sparse-typed_vector_iteration_impl.adb"):
            for mode in (None, "-gnat2012"):
                with self.subTest(unit=unit, mode=mode):
                    result = self.compile("src/internal/" + unit, mode)
                    self.assertEqual(result.returncode, 0,
                                     result.stdout + result.stderr)
            with self.subTest(unit=unit, mode="-gnat2022"):
                result = self.compile("src/internal/" + unit, "-gnat2022")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("array aggregate using ()", result.stderr)
                self.assertIn(":28:60:", result.stderr)

    def test_actual_sparse_vector_named_array_and_record_preservation(self):
        unit = "src/opencv-core-sparse-uint8_vec2_access.adb"
        result = self.compile(unit)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        result = self.compile(unit, "-gnat2022")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("array aggregate using ()", result.stderr)
        source = (ROOT / unit).read_text()
        self.assertIn("is (0 => UInt8_Value (V.Component_0),", source)
        self.assertIn("is (Component_0 => C.C_UInt8 (V (0)),", source)
        self.assertIn("Zero : constant C.UInt8_Vec2 := (others => 0);", source)

    def test_typed_access_retains_local_ada2022(self):
        result = self.compile("src/internal/opencv-core-internal-typed_access.adb",
                              "-gnat2022")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        project = (ROOT / "opencv_core.gpr").read_text()
        self.assertIn('Switches ("opencv-core-internal-typed_access.adb")', project)
        self.assertIn('("-gnat2022", "-Werror")', project)

    def test_cross_wrapper_does_not_override_per_unit_language(self):
        source = (ROOT / "scripts/cross_build_core.sh").read_text()
        self.assertIn('Ada_Compiler_Switches := ("-gnatwa", "-gnatwe")', source)
        self.assertNotIn('Ada_Compiler_Switches := ("-gnat2022"', source)


if __name__ == "__main__":
    unittest.main()