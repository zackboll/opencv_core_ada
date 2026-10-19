"""Fail-closed verifier controls, separate from real compiler qualification."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "verify_outputs", ROOT / "tests/adacore25/verify_outputs.py")
VERIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFY)


class OutputVerificationTests(unittest.TestCase):
    def test_mixed_or_wrong_architectures_are_rejected(self):
        good = "Class: ELF64\nData: 2's complement, little endian\nMachine: AArch64\n"
        for text in (good.replace("AArch64", "X86-64"),
                     good + good.replace("AArch64", "X86-64"),
                     good.replace("little endian", "big endian"), ""):
            with self.subTest(text=text), patch.object(VERIFY, "run", return_value=text):
                with self.assertRaises(ValueError):
                    VERIFY.elf(Path("object.o"))
        with patch.object(VERIFY, "run", return_value=good):
            VERIFY.elf(Path("object.o"))

    def test_ali_identity_is_complete_not_gcc_major(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "probe.ali"
            path.write_text('V "GNAT Lib v25"\n')
            self.assertEqual(VERIFY.signature(path), 'V "GNAT Lib v25"')
            path.write_text('V "GNAT Lib v25" trailing\n')
            with self.assertRaises(ValueError):
                VERIFY.signature(path)

    def test_symlink_escape_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "sysroot"
            root.mkdir()
            outside = Path(temp) / "host.so"
            outside.touch()
            (root / "lib.so").symlink_to(outside)
            with self.assertRaises(ValueError):
                VERIFY.contained(root / "lib.so", root)

    def test_driver_sysroot_and_host_search_trace_controls(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            ada, cxx, log = root / "gcc", root / "g++", root / "build.log"
            ada.touch()
            cxx.touch()
            good = f"{ada} -c --sysroot={root} source.adb\n"
            log.write_text(good)
            self.assertEqual(VERIFY.check_trace(log, ada, cxx, root), 1)
            for text in ("gcc -c source.adb\n", good.replace(" --sysroot=" + str(root), ""),
                         good.replace(" -c", " -I/usr/include -c"),
                         good.replace(" -c", " -L/usr/lib/x86_64-linux-gnu -c")):
                log.write_text(text)
                with self.subTest(text=text), self.assertRaises(ValueError):
                    VERIFY.check_trace(log, ada, cxx, root)

    def test_version_requirements_and_definitions_are_distinct(self):
        output = ("Version definition section\n Name: PROVIDED\n"
                  "Version needs section\n File: libc.so.6\n Name: GLIBC_2.34\n")
        with patch.object(VERIFY, "run", return_value=output):
            self.assertEqual(VERIFY.versions("library", True), {"PROVIDED"})
            self.assertEqual(VERIFY.versions("program"), {"libc.so.6": {"GLIBC_2.34"}})

    def test_complete_unfiltered_execution_is_required(self):
        good = ("Registered tests: 2037\n"
                + "".join(f"RUN {index}/2037: test\n" for index in range(1, 2038))
                + "Total Tests Run:   2037\nSuccessful Tests:  2037\n"
                  "Failed Assertions: 0\nUnexpected Errors: 0\n")
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp) / "run.log"
            path.write_text(good)
            self.assertEqual(VERIFY.check_summary(path)["executed"], 2037)
            for text in (good.replace("RUN 1/2037: test\n", ""),
                         good.replace("RUN 1/2037", "RUN 2/2037"),
                         good.replace("Unexpected Errors: 0", "Unexpected Errors: 1"),
                         good + "Registered tests: 2037\n", good + "FAIL test\n"):
                path.write_text(text)
                with self.subTest(text=text[:40]), self.assertRaises(ValueError):
                    VERIFY.check_summary(path)

    def test_library_run_paths_are_target_root_only(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp) / "sysroot"
            (root / "usr/lib").mkdir(parents=True)
            library = root / "usr/lib/opencv.so"
            dynamic = "(RPATH) Library rpath: [/usr/lib]"
            searches, directories = VERIFY.qualified_run_directories(library, root, dynamic)
            self.assertEqual(searches, ["/usr/lib"])
            self.assertEqual(directories, [root / "usr/lib"])
            for item, text in ((Path(temp) / "test", dynamic),
                               (library, dynamic.replace("/usr/lib", "$ORIGIN")),
                               (library, dynamic.replace("/usr/lib", "/host/lib")),
                               (library, dynamic.replace("/usr/lib", "/usr/lib:"))):
                with self.subTest(text=text), self.assertRaises(ValueError):
                    VERIFY.qualified_run_directories(item, root, text)


if __name__ == "__main__":
    unittest.main()