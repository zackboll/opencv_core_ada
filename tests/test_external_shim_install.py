"""GPRinstall regression using a tiny prebuilt library, not native Core coverage.

Run through `alr exec -- python3 -m unittest discover -s tests -p
test_external_shim_install.py -v`. Actual Core DLL/Mat coverage is separate.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ExternalInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="core-external-gprinstall.")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "config").mkdir()
        (self.root / "cpp").mkdir()
        (self.root / "lib").mkdir()
        (self.root / "config/opencv_core_config.gpr").write_text(
            'abstract project OpenCV_Core_Config is\n'
            '   Build_Profile := "development";\nend OpenCV_Core_Config;\n')
        config = (ROOT / "config/opencv_core_install.gpr").read_text()
        config = re.sub(r'Shim_Build : Shim_Build_Kind := "[^"]+";',
                        'Shim_Build : Shim_Build_Kind := "External_Relocatable";', config)
        (self.root / "config/opencv_core_install.gpr").write_text(config)
        self.project = self.root / "opencv_core_shim.gpr"
        self.original = (ROOT / "opencv_core_shim.gpr").read_text()
        self.project.write_text(self.original)

    def install(self):
        return subprocess.run(
            ["gprinstall", "-f", "-p", "-r", f"--prefix={self.root / 'prefix'}",
             "-P", str(self.project)], text=True, capture_output=True)

    def test_no_language_reproduces_predecessor_failure(self):
        old = self.original
        # Only mutate the external branch, not the Linux/macOS branches.
        old = re.sub(r'(when "External_Relocatable" =>\s*'
                     r'for Externally_Built use "True";).*?'
                     r'for Library_Kind use "relocatable";',
                     r'\1\n         for Languages use ();\n'
                     r'         for Source_Dirs use ();\n'
                     r'         for Library_Kind use "relocatable";', old,
                     count=1, flags=re.DOTALL)
        self.project.write_text(old)
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no language found, aborting", result.stdout + result.stderr)

    def test_language_only_does_not_install_library(self):
        self.project.write_text(re.sub(
            r'(for Externally_Built use "True";.*?)for Source_Dirs use \("cpp/"\);',
            r'\1for Source_Dirs use ();', self.original, count=1, flags=re.DOTALL))
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        installed = self.root / "prefix/share/gpr/opencv_core_shim.gpr"
        self.assertIn("abstract project", installed.read_text())
        self.assertFalse((self.root / "prefix/lib/opencv_core_shim").exists())

    def test_external_library_and_required_archive_install(self):
        source = self.root / "cpp/probe.cpp"
        source.write_text('extern "C" int core_install_probe() { return 37; }\n')
        windows = os.name == "nt"
        config = (ROOT / "config/opencv_core_install.gpr").read_text()
        driver = re.search(r'Cxx_Driver := "([^"]+)";', config)[1]
        if not windows:
            driver = "/usr/bin/g++"
        library = self.root / "lib" / ("libopencv_core_shim.dll" if windows
                                         else "libopencv_core_shim.so")
        archive = self.root / "lib/libopencv_core_shim.dll.a"
        command = [driver, "-shared", "-fPIC", str(source), "-o", str(library)]
        if windows:
            command.append(f"-Wl,--out-implib,{archive}")
        subprocess.run(command, check=True, capture_output=True)
        if not windows:
            # Linux archive fixture tests Required_Artifacts copying only;
            # it is deliberately not evidence for a Windows import library.
            subprocess.run(["ar", "rcs", str(archive)], check=True)
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        installed = self.root / "prefix/lib/opencv_core_shim"
        for artifact in (library, archive):
            self.assertEqual(artifact.read_bytes(), (installed / artifact.name).read_bytes())
        project = (self.root / "prefix/share/gpr/opencv_core_shim.gpr").read_text()
        self.assertIn("library project", project)
        self.assertIn('for Externally_Built use "True"', project)
        archive.unlink()
        shutil.rmtree(self.root / "prefix")
        result = self.install()
        self.assertNotEqual(result.returncode, 0, "missing required import archive accepted")


if __name__ == "__main__":
    unittest.main()