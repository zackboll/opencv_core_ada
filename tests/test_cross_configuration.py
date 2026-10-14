"""Fail-closed cross preflight controls; no real SDK is modified."""
import os
from pathlib import Path
import subprocess
import shutil
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
        base, _, _, _, _ = self.fixture()
        outside = base / "outside-sysroot"
        outside.mkdir()
        pkg = Path(self.env["OPENCV_CROSS_PKG_CONFIG"])
        original = pkg.read_text()
        for flag in ["-I", "-L"]:
            with self.subTest(flag=flag):
                pkg.write_text(original.replace('--cflags) exit 0',
                                                f'--cflags) echo {flag}{outside}'))
                self.reject("host pkg-config dependency path")

    def test_missing_dependency_directories(self):
        base, _, _, _, _ = self.fixture()
        missing = base / "sysroot/absent"
        pkg = Path(self.env["OPENCV_CROSS_PKG_CONFIG"])
        original = pkg.read_text()
        for flag in ["-I", "-L"]:
            with self.subTest(flag=flag):
                pkg.write_text(original.replace('--cflags) exit 0',
                                                f'--cflags) echo {flag}{missing}'))
                self.reject("missing pkg-config dependency directory")

    def test_linux_target_names(self):
        self.fixture()
        original = "aarch64-linux-gnu"
        templates = {key: Path(self.env[key]).read_text() for key in
                     ["OPENCV_CROSS_ADA", "OPENCV_CROSS_CXX", "OPENCV_CROSS_GPR_CONFIG"]}
        for target in [original, "aarch64-unknown-linux-gnu", "aarch64-poky-linux",
                       "aarch64-oe-linux", "aarch64-poky-linux-gnu"]:
            with self.subTest(target=target):
                self.env["OPENCV_CROSS_TARGET"] = target
                for key in ["OPENCV_CROSS_ADA", "OPENCV_CROSS_CXX", "OPENCV_CROSS_GPR_CONFIG"]:
                    path = Path(self.env[key])
                    path.write_text(templates[key].replace(original, target))
                result = self.check()
                self.assertEqual(result.returncode, 0, result.stderr)
                # Wrapper must use the same naming contract before sysroot checks.
                env = self.env.copy()
                del env["ENV_PREFIX"]
                result = subprocess.run(["sh", str(ROOT / "scripts/cross_build_core.sh")],
                                        env=env, text=True, capture_output=True)
                self.assertIn("ENV_PREFIX is required", result.stderr)
                for key, diagnostic in [("OPENCV_CROSS_ADA", "Ada compiler target mismatch"),
                                        ("OPENCV_CROSS_CXX", "C++ compiler target mismatch"),
                                        ("OPENCV_CROSS_GPR_CONFIG", "GPR target mismatch")]:
                    path = Path(self.env[key])
                    contents = path.read_text()
                    path.write_text(contents.replace(target, "aarch64-other-linux"))
                    result = self.check()
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(diagnostic, result.stderr)
                    path.write_text(contents)

    def test_rejected_target_names(self):
        self.fixture()
        for target in ["x86_64-linux-gnu", "arm-linux-gnueabihf", "aarch64-none-elf",
                       "", "aarch64", "aarch64--linux", "aarch64-linux-",
                       "aarch64-linux/gnu", "aarch64-linux gnu", "aarch64evil-linux-gnu"]:
            with self.subTest(target=target):
                self.env["OPENCV_CROSS_TARGET"] = target
                self.reject("OPENCV_CROSS_TARGET" if not target else "AArch64 Linux")
                result = self.check()
                self.assertNotEqual(result.returncode, 0)

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

    def test_workspace_canonical_controls(self):
        base, _, _, _, _ = self.fixture()
        checkout = base / "checkout"
        shutil.copytree(ROOT / "scripts", checkout / "scripts")
        alias = base / "checkout-alias"
        alias.symlink_to(checkout, target_is_directory=True)
        sysroot = Path(self.env["ENV_PREFIX"])
        sdk_alias = base / "sdk-alias"
        sdk_alias.symlink_to(sysroot, target_is_directory=True)
        sibling = base / "sibling"
        sibling.mkdir()
        stale = base / "stale"
        stale.symlink_to(base / "absent")
        # A sentinel proves destination rejection occurs before Git/export.
        tools = base / "tools"
        tools.mkdir()
        git = tools / "git"
        git.write_text("#!/bin/sh\necho export-sentinel >&2\nexit 1\n")
        git.chmod(0o755)
        self.env["PATH"] = str(tools) + os.pathsep + self.env["PATH"]
        cases = [alias / "output", sibling / ".." / "checkout" / "output",
                 sysroot / "output", sdk_alias / "output", checkout, stale,
                 sibling]
        before = sorted(str(p.relative_to(base)) for p in base.rglob("*"))
        for destination in cases:
            with self.subTest(destination=destination):
                result = subprocess.run(
                    ["sh", str(checkout / "scripts/cross_build_core.sh"),
                     "--prepare", str(destination)], env=self.env,
                    text=True, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("export-sentinel", result.stderr)
                self.assertRegex(result.stderr, "workspace.*(outside|overlap|stale)")
        self.assertEqual(before, sorted(str(p.relative_to(base)) for p in base.rglob("*")))
        for destination in [base / "ordinary-new", sibling / ".." / "ordinary-new"]:
            result = subprocess.run(
                ["sh", str(checkout / "scripts/cross_build_core.sh"),
                 "--prepare", str(destination)], env=self.env,
                text=True, capture_output=True)
            self.assertIn("export-sentinel", result.stderr)
            self.assertFalse(destination.exists())

    def test_header_and_flag_symlink_controls(self):
        for kind in ["directory", "required", "nested", "broken", "local",
                     "local-directory", "cycle", "include-flag", "library-flag",
                     "local-include-flag", "local-library-flag"]:
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as temp:
                original = self.temp
                self.temp = type("Fixture", (), {"name": temp})()
                try:
                    base, include, _, _, _ = self.fixture()
                    host = base / "host"
                    host.mkdir()
                    (host / "core.hpp").touch()
                    if kind == "directory":
                        shutil.rmtree(include / "opencv2")
                        (include / "opencv2").symlink_to(host)
                    elif kind in ["required", "broken", "local"]:
                        header = include / "opencv2/core.hpp"
                        header.unlink()
                        target = host / "core.hpp"
                        if kind == "broken":
                            target = include / "absent.hpp"
                        if kind == "local":
                            target = include / "actual.hpp"
                            target.touch()
                        header.symlink_to(target)
                    elif kind == "nested":
                        (include / "opencv2/nested").mkdir()
                        (include / "opencv2/nested/detail.hpp").symlink_to(host / "core.hpp")
                    elif kind == "local-directory":
                        (include / "opencv2").rename(include / "actual")
                        (include / "opencv2").symlink_to(include / "actual")
                    elif kind == "cycle":
                        (include / "opencv2/loop").symlink_to(include / "opencv2")
                    else:
                        alias = include / "flags"
                        alias.symlink_to(include / "opencv2" if kind.startswith("local-") else host)
                        pkg = Path(self.env["OPENCV_CROSS_PKG_CONFIG"])
                        flag = "-I" if "include-flag" in kind else "-L"
                        pkg.write_text(pkg.read_text().replace('--cflags) exit 0',
                                                               f'--cflags) echo {flag}{alias}'))
                    before = sorted(str(p.relative_to(base)) for p in base.rglob("*"))
                    result = self.check()
                    if kind.startswith("local"):
                        self.assertEqual(result.returncode, 0, result.stderr)
                    else:
                        self.assertNotEqual(result.returncode, 0, "escaping headers/flags accepted")
                    self.assertEqual(before, sorted(str(p.relative_to(base)) for p in base.rglob("*")))
                finally:
                    self.temp = original


if __name__ == "__main__":
    unittest.main()