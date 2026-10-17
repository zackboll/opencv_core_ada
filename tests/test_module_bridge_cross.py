"""Invocation regressions, not substitutes for real target/native builds."""
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ModuleBridgeCrossTests(unittest.TestCase):
    def fixture(self, cross, bad_archiver=False):
        temp = tempfile.TemporaryDirectory(prefix="core-probe-invocations.")
        self.addCleanup(temp.cleanup)
        root = Path(temp.name)
        for directory in ("scripts", "config", "tests/cpp", "cpp", "bin"):
            (root / directory).mkdir(parents=True)
        shutil.copy2(ROOT / "scripts/build_module_bridge_probe.sh", root / "scripts")
        for name in ("integer_borrow_lifetime_probe_shim.cpp", "umat_opencl_probe.cpp"):
            (root / "tests/cpp" / name).touch()
        log = root / "invocations"
        archiver = root / "bin/ar"
        archiver.write_text('#!/bin/sh\nprintf "ar" >> "$PROBE_LOG"\n'
                            'printf " <%s>" "$@" >> "$PROBE_LOG"\n'
                            'printf "\\n" >> "$PROBE_LOG"\n')
        archiver.chmod(0o755)
        driver = root / "bin/target-g++"
        answer = root / "missing-ar" if bad_archiver else archiver
        driver.write_text('#!/bin/sh\n'
                          'if [ "$1" = -print-prog-name=ar ]; then\n'
                          f'  printf "%s\\n" {shlex.quote(str(answer))}; exit 0\nfi\n'
                          'printf "cxx" >> "$PROBE_LOG"\n'
                          'printf " <%s>" "$@" >> "$PROBE_LOG"\n'
                          'printf "\\n" >> "$PROBE_LOG"\n')
        driver.chmod(0o755)
        sysroot = str(root / "target sysroot") if cross else ""
        (root / "config/opencv_core_install.gpr").write_text(
            'abstract project OpenCV_Core_Install is\n'
            '   Shim_Build : Shim_Build_Kind := "Static_PIC";\n'
            '   Cxx_Toolchain : Cxx_Toolchain_Kind := "GNU";\n'
            f'   Cxx_Driver := "{driver}";\n'
            f'   Cxx_Sysroot := "{sysroot}";\n'
            '   Include_Switch := "-Itarget-headers";\n'
            'end OpenCV_Core_Install;\n')
        env = dict(os.environ, PROBE_LOG=str(log),
                   PATH=str(root / "bin") + os.pathsep + os.environ["PATH"])
        result = subprocess.run(["sh", str(root / "scripts/build_module_bridge_probe.sh")],
                                env=env, text=True, capture_output=True)
        lines = log.read_text().splitlines() if log.exists() else []
        return result, lines, sysroot

    def test_cross_passes_sysroot_to_both_compiles_and_selects_archiver(self):
        result, lines, sysroot = self.fixture(True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(lines), 3)
        for line in lines[:2]:
            self.assertTrue(line.startswith("cxx "))
            self.assertIn(f"<--sysroot={sysroot}>", line)
            for flag in ("-Wall", "-Wextra", "-Wpedantic", "-Werror"):
                self.assertIn(f"<{flag}>", line)
        self.assertTrue(lines[2].startswith("ar <rcs>"))

    def test_native_commands_have_no_added_sysroot(self):
        result, lines, _ = self.fixture(False)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(lines), 3)
        self.assertNotIn("sysroot", "\n".join(lines))
        self.assertTrue(lines[2].startswith("ar <rcs>"))

    def test_cross_rejects_unresolved_archiver_before_compiling(self):
        result, lines, _ = self.fixture(True, bad_archiver=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not resolve its archiver", result.stderr)
        self.assertEqual(lines, [])


if __name__ == "__main__":
    unittest.main()