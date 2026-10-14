"""Fail-closed cross preflight controls; no real SDK is modified."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CrossConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="core-cross-negative.")
        self.addCleanup(self.temp.cleanup)
        self.workspace = Path(self.temp.name) / "build"
        self.env = os.environ.copy()
        for key in list(self.env):
            if key.startswith("OPENCV_CROSS_") or key == "ENV_PREFIX":
                del self.env[key]

    def reject(self, message):
        result = subprocess.run(
            ["sh", str(ROOT / "scripts/cross_build_core.sh"),
             "--prepare", str(self.workspace)], env=self.env,
            text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(message, result.stdout + result.stderr)
        self.assertFalse(self.workspace.exists(), "failed preflight exported sources")

    def test_missing_target(self):
        self.reject("OPENCV_CROSS_TARGET")

    def test_unsupported_target(self):
        self.env["OPENCV_CROSS_TARGET"] = "x86_64-linux-gnu"
        self.reject("AArch64 Linux")

    def test_missing_sysroot(self):
        self.env["OPENCV_CROSS_TARGET"] = "aarch64-linux-gnu"
        self.reject("ENV_PREFIX")

    def test_invalid_sysroot(self):
        self.env.update(OPENCV_CROSS_TARGET="aarch64-linux-gnu",
                        ENV_PREFIX=str(Path(self.temp.name) / "absent"))
        self.reject("sysroot")

    def test_missing_ada_compiler(self):
        self.env.update(OPENCV_CROSS_TARGET="aarch64-linux-gnu",
                        ENV_PREFIX=self.temp.name)
        self.reject("OPENCV_CROSS_ADA")

    def test_host_ada_compiler(self):
        self.env.update(OPENCV_CROSS_TARGET="aarch64-linux-gnu",
                        ENV_PREFIX=self.temp.name, OPENCV_CROSS_ADA="/usr/bin/gcc")
        self.reject("Ada compiler target")

    def fixture(self):
        base = Path(self.temp.name)
        sysroot = base / "sysroot"
        include = sysroot / "usr/include/opencv4"
        library = sysroot / "usr/lib"
        metadata = library / "pkgconfig"
        (include / "opencv2").mkdir(parents=True)
        metadata.mkdir(parents=True)
        (include / "opencv2/core.hpp").touch()
        (library / "libopencv_core.so").touch()
        (library / "libc.so.6").touch()
        (library / "libstdc++.so.6").touch()
        runtime = base / "runtime"
        (runtime / "adalib").mkdir(parents=True)
        (runtime / "adainclude").mkdir()
        (runtime / "adalib/libgnat.a").touch()
        def executable(name, body):
            path = base / name
            path.write_text("#!/bin/sh\n" + body)
            path.chmod(0o755)
            return str(path)
        ada = executable("ada", f'case "$1" in -print-file-name=adalib) echo "{runtime}/adalib" ;; *) echo aarch64-linux-gnu ;; esac\n')
        cxx = executable("cxx", "printf '%s\\n' aarch64-linux-gnu\n")
        elf = executable("readelf", "printf '%s\\n' 'Class: ELF64' 'Machine: AArch64'\n")
        pkg = executable("pkg-config", "case \"$1\" in\n"
                         "--exists) exit 0 ;;\n"
                         "--modversion) printf '%s\\n' 4.6.0 ;;\n"
                         "--variable=includedir) printf '%s\\n' /usr/include/opencv4 ;;\n"
                         "--variable=libdir) printf '%s\\n' /usr/lib ;;\n"
                         "--cflags) exit 0 ;;\nesac\n")
        config = base / "target.cgpr"
        config.write_text(f'for Target use "aarch64-linux-gnu";\n'
                          f'"{ada}"\n"{cxx}"\n"{runtime}/"\n'
                          'for Driver use Compiler\'Driver ("C++");\n')
        self.env.update(OPENCV_CROSS_TARGET="aarch64-linux-gnu",
                        ENV_PREFIX=str(sysroot), OPENCV_CROSS_ADA=ada,
                        OPENCV_CROSS_CXX=cxx, OPENCV_CROSS_RUNTIME=str(runtime),
                        OPENCV_CROSS_READELF=elf, OPENCV_CROSS_PKG_CONFIG=pkg,
                        OPENCV_CROSS_GPR_CONFIG=str(config),
                        PKG_CONFIG_LIBDIR=str(metadata), PKG_CONFIG_PATH="")
        return base, include, library, runtime, config

    def check(self):
        return subprocess.run(["sh", str(ROOT / "scripts/configure_cross_opencv.sh"),
                               "--check"], env=self.env, text=True, capture_output=True)

    def test_fixture_preflight_and_repetition(self):
        self.fixture()
        first, second = self.check(), self.check()
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(first.stdout, second.stdout)

    def test_target_mismatch(self):
        self.fixture()
        Path(self.env["OPENCV_CROSS_CXX"]).write_text("#!/bin/sh\necho x86_64-linux-gnu\n")
        self.reject("C++ compiler target mismatch")

    def test_missing_headers(self):
        _, include, _, _, _ = self.fixture()
        (include / "opencv2/core.hpp").unlink()
        self.reject("missing target OpenCV headers")

    def test_missing_libraries(self):
        _, _, library, _, _ = self.fixture()
        (library / "libopencv_core.so").unlink()
        self.reject("missing target library")

    def test_host_pkg_config(self):
        self.fixture()
        self.env["PKG_CONFIG_LIBDIR"] = "/usr/lib"
        self.reject("host pkg-config contamination")

    def test_host_pkg_config_path(self):
        self.fixture()
        self.env["PKG_CONFIG_PATH"] = "/usr/lib/pkgconfig"
        self.reject("PKG_CONFIG_PATH must be empty")

    def test_wrong_library_architecture(self):
        self.fixture()
        Path(self.env["OPENCV_CROSS_READELF"]).write_text("#!/bin/sh\necho 'Machine: X86-64'\n")
        self.reject("not AArch64 ELF")

    def test_wrong_runtime(self):
        _, _, _, runtime, _ = self.fixture()
        (runtime / "adalib/libgnat.a").unlink()
        self.reject("missing target library")

    def test_missing_sysroot_libc(self):
        _, _, library, _, _ = self.fixture()
        (library / "libc.so.6").unlink()
        self.reject("missing target runtime library: libc.so.6")

    def test_stale_gpr_target(self):
        _, _, _, _, config = self.fixture()
        config.write_text('for Target use "x86_64-linux-gnu";\n')
        self.reject("GPR target mismatch")

    def test_missing_cxx_compiler(self):
        self.fixture()
        del self.env["OPENCV_CROSS_CXX"]
        self.reject("OPENCV_CROSS_CXX")

    def test_wrong_gpr_runtime(self):
        _, _, _, runtime, config = self.fixture()
        config.write_text(config.read_text().replace(str(runtime), "/host/runtime"))
        self.reject("GPR Ada runtime mismatch")

    def test_wrong_gpr_cxx(self):
        _, _, _, _, config = self.fixture()
        config.write_text(config.read_text().replace(self.env["OPENCV_CROSS_CXX"], "/usr/bin/g++"))
        self.reject("GPR C++ compiler mismatch")

    def test_wrong_gpr_linker(self):
        _, _, _, _, config = self.fixture()
        config.write_text(config.read_text().replace('for Driver use Compiler\'Driver ("C++");',
                                                   'for Driver use "/usr/bin/g++";'))
        self.reject("GPR linker")

    def test_compiler_runtime_mismatch(self):
        self.fixture()
        Path(self.env["OPENCV_CROSS_ADA"]).write_text(
            '#!/bin/sh\ncase "$1" in -print-file-name=adalib) echo /usr/lib ;; *) echo aarch64-linux-gnu ;; esac\n')
        self.reject("Ada runtime differs")

    def test_host_dependency_flags(self):
        self.fixture()
        pkg = Path(self.env["OPENCV_CROSS_PKG_CONFIG"])
        pkg.write_text(pkg.read_text().replace('--cflags) exit 0',
                                              '--cflags) echo -I/usr/include/opencv4'))
        self.reject("host pkg-config dependency path")

    def test_generated_configuration_is_idempotent(self):
        self.fixture()
        outputs = []
        for _ in range(2):
            result = subprocess.run(["sh", str(ROOT / "scripts/configure_cross_opencv.sh")],
                                    env=self.env, cwd=self.temp.name,
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            outputs.append((Path(self.temp.name) / "config/opencv_core_install.gpr").read_bytes())
        self.assertEqual(*outputs)

    def test_prebuild_action_keeps_cross_mode(self):
        self.fixture()
        self.env["OPENCV_CORE_CROSS"] = "True"
        self.env["PKG_CONFIG_LIBDIR"] = "/usr/lib"
        result = subprocess.run(["sh", str(ROOT / "scripts/configure_opencv.sh")],
                                env=self.env, cwd=ROOT, text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("host pkg-config contamination", result.stderr)

    def test_unsupported_opencv(self):
        self.fixture()
        pkg = Path(self.env["OPENCV_CROSS_PKG_CONFIG"])
        pkg.write_text(pkg.read_text().replace("4.6.0", "3.4.0"))
        self.reject("unsupported OpenCV version")

    def test_stale_workspace(self):
        self.fixture()
        self.workspace.mkdir()
        result = subprocess.run(["sh", str(ROOT / "scripts/cross_build_core.sh"),
                                 "--prepare", str(self.workspace)], env=self.env,
                                text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("stale artifacts", result.stderr)


if __name__ == "__main__":
    unittest.main()