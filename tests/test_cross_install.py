"""Workflow controls with fake tools, NOT GNAT Pro/AArch64 build evidence.

Reuse the existing preflight fixture/negative suite rather than simulating a
second validator. The real wrapper, snapshot, bootstrap and install checks run.
"""
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest

import test_cross_configuration as preflight

ROOT = Path(__file__).resolve().parents[1]


class CrossInstallTests(unittest.TestCase):
    def setUp(self):
        self.fixture = preflight.CrossConfigurationTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.base, _, _, self.runtime, self.config = self.fixture.fixture()
        self.env = self.fixture.env
        for key in ("GPR_PROJECT_PATH", "ADA_PROJECT_PATH", "PKG_CONFIG_SYSROOT_DIR"):
            self.env.pop(key, None)
        self.tools = self.base / "tools"
        self.tools.mkdir()
        self.tmp = self.base / "temporary"
        self.tmp.mkdir()
        self.env["TMPDIR"] = str(self.tmp)
        self.source = self.base / "source"
        self.source.mkdir()
        # A real .git-free archive of the implementation inputs, not an old crate.
        archive = self.base / "candidate.tar"
        subprocess.run(["tar", "-cf", str(archive), "-C", str(ROOT),
                        "--exclude=__pycache__", "scripts", "src", "cpp",
                        "tests/fixtures/cross-reference", "alire.toml",
                        "opencv_core.gpr", "opencv_core_shim.gpr"], check=True)
        subprocess.run(["tar", "-xf", str(archive), "-C", str(self.source)], check=True)
        self.prefix = self.base / "prefix"
        self.args = ["sh", str(ROOT / "scripts/cross_install_core.sh"),
                     "--source-root", str(self.source),
                     "--target", "aarch64-linux-gnu", "--toolchain-bin", str(self.tools),
                     "--runtime", str(self.runtime), "--sysroot", self.env["ENV_PREFIX"],
                     "--prefix", str(self.prefix), "--profile", "release"]
        # Explicit compilers intentionally differ from the nominal directory.
        # GPRconfig must use their actual directory and C++ basename.
        self.env.pop("OPENCV_CROSS_GPR_CONFIG")
        self.env.pop("PKG_CONFIG_LIBDIR")
        self.exe("gprconfig", f'printf "%s\\n" "$@" > "{self.base}/selection"\n'
                 'while [ "$1" != -o ]; do shift; done\n'
                 f'cp "{self.config}" "$2"\n')
        self.exe("gprbuild", f'echo "{self.env["OPENCV_CROSS_ADA"]} {self.env["OPENCV_CROSS_CXX"]}"\n'
                 '[ -z "${GPR_PROJECT_PATH:-}${ADA_PROJECT_PATH:-}" ] || exit 93\n'
                 'case "$*" in *probe.gpr*)\n'
                 'mkdir -p tests/fixtures/cross-reference/bin\n'
                 'touch tests/fixtures/cross-reference/bin/probe ;;\n'
                 '*) test ! -e obj/native-stale; test ! -e config/native-stale; '
                 'test ! -e alire; test ! -e scripts/__pycache__; '
                 f'pwd > "{self.base}/production-work" ;; esac\n')
        self.exe("gprinstall", '[ "$2" = "-P" ] || exit 96\n'
                 'case "$*" in *" -r "*) ;; *) exit 97 ;; esac\n'
                 'for arg do case "$arg" in --prefix=*) prefix=${arg#--prefix=} ;; esac; done\n'
                 'mkdir -p "$prefix/share/gpr" "$prefix/lib/opencv_core" "$prefix/lib/opencv_core_shim"\n'
                 'cp opencv_core.gpr opencv_core_shim.gpr "$prefix/share/gpr/"\n'
                 'touch "$prefix/lib/opencv_core/libopencv_core_ada.a" '
                 '"$prefix/lib/opencv_core_shim/libopencv_core_shim.a"\n')

    def exe(self, name, body):
        path = self.tools / name
        path.write_text("#!/bin/sh\nset -eu\n" + body)
        path.chmod(0o755)
        self.env["OPENCV_CROSS_" + name.upper()] = str(path)
        return path

    def run_install(self):
        return subprocess.run(self.args, env=self.env, cwd=self.base,
                              text=True, capture_output=True)

    def success(self):
        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(list(self.tmp.iterdir()), [], "successful run left temporary build state")
        durable = self.prefix / "share/gprconfig/aarch64-linux-gnu.cgpr"
        self.assertEqual(durable.read_bytes(), self.config.read_bytes())
        self.assertIn(str(durable), result.stdout)
        self.assertIn("-R -cargs:Ada", result.stdout)
        self.assertFalse(Path((self.base / "production-work").read_text().strip()).exists())
        for name in ("opencv_core", "opencv_core_shim"):
            self.assertTrue((self.prefix / f"share/gpr/{name}.gpr").is_file())
        self.assertTrue((self.prefix / "lib/opencv_core/libopencv_core_ada.a").is_file())
        self.assertTrue((self.prefix / "lib/opencv_core_shim/libopencv_core_shim.a").is_file())
        self.assertTrue((self.prefix / "share/gprconfig/aarch64-linux-gnu-logs/build.log").is_file())
        return result

    def test_direct_bootstrap_archive_prefix_retention_and_isolation(self):
        # An enclosing repository must never be discovered/exported as source.
        subprocess.run(["git", "init", "-q", str(self.base)], check=True)
        for path in ("obj/native-stale", "config/native-stale", "alire/cache",
                     "scripts/__pycache__/stale.pyc"):
            item = self.source / path
            item.parent.mkdir(parents=True, exist_ok=True)
            item.touch()
        self.env.update(GPR_PROJECT_PATH="/native/projects", ADA_PROJECT_PATH="/native/ada")
        self.success()
        selection = (self.base / "selection").read_text().splitlines()
        self.assertIn(f"--config=Ada,,{self.runtime},{self.base},GNAT", selection)
        self.assertIn(f"--config=C++,,,{self.base},cxx", selection)
        identity = (self.prefix / "share/gprconfig/aarch64-linux-gnu-source.txt").read_text()
        self.assertIn("Manifest SHA256:", identity)
        self.assertIn("Snapshot SHA256:", identity)
        self.assertNotIn("Git commit:", identity)

    def init_git(self):
        subprocess.run(["git", "init", "-q", str(self.source)], check=True)
        subprocess.run(["git", "-C", str(self.source), "add", "."], check=True)
        subprocess.run(["git", "-C", str(self.source), "-c", "user.name=Test",
                        "-c", "user.email=test@example.invalid", "commit", "-qm", "candidate"], check=True)
        return subprocess.check_output(["git", "-C", str(self.source), "rev-parse", "HEAD"], text=True).strip()

    def test_git_exact_clean_snapshot(self):
        revision = self.init_git()
        self.success()
        self.assertEqual((self.prefix / "share/gprconfig/aarch64-linux-gnu-source.txt").read_text(),
                         f"Git commit: {revision}\n")
        self.assertEqual(subprocess.check_output(["git", "-C", str(self.source), "status", "--porcelain"]), b"")

    def test_dirty_git_is_rejected(self):
        self.init_git()
        (self.source / "untracked").touch()
        result = self.run_install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("source revision must be clean", result.stderr)
        self.assertFalse(self.prefix.exists())

    def test_prefix_overlap_and_incomplete_archive_rejected(self):
        for prefix in (self.source / "install", Path(self.env["ENV_PREFIX"]) / "install", self.base):
            with self.subTest(prefix=prefix):
                args = self.args.copy()
                args[args.index("--prefix") + 1] = str(prefix)
                result = subprocess.run(args, env=self.env, text=True, capture_output=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("installation prefix overlaps", result.stderr)
                self.assertFalse((self.base / "production-work").exists())
        (self.source / "alire.toml").unlink()
        result = self.run_install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("incomplete archive source: alire.toml", result.stderr)
        self.assertFalse(self.prefix.exists())

    def test_explicit_configuration_override(self):
        self.env["OPENCV_CROSS_GPR_CONFIG"] = str(self.config)
        self.exe("gprconfig", "exit 91\n")
        self.success()
        self.assertFalse((self.base / "selection").exists())

    def test_compiler_defaults_use_target_executables(self):
        ada = self.tools / "aarch64-linux-gnu-gcc"
        cxx = self.tools / "aarch64-linux-gnu-g++"
        original = self.env.pop("OPENCV_CROSS_ADA")
        ada.write_text(Path(original).read_text())
        ada.chmod(0o755)
        original_cxx = self.env.pop("OPENCV_CROSS_CXX")
        cxx.write_text(Path(original_cxx).read_text())
        cxx.chmod(0o755)
        self.config.write_text(self.config.read_text().replace(original, str(ada)).replace(original_cxx, str(cxx)))
        self.exe("gprbuild", f'echo "{ada} {cxx}"\nmkdir -p tests/fixtures/cross-reference/bin\n'
                 'touch tests/fixtures/cross-reference/bin/probe\n'
                 f'pwd > "{self.base}/production-work"\n')
        self.success()
        self.assertIn(f"--config=C++,,,{self.tools},aarch64-linux-gnu-g++",
                      (self.base / "selection").read_text())

    def test_incomplete_and_mismatched_generated_configurations(self):
        original = self.config.read_text()
        for wrong in ("", original.replace("aarch64-linux-gnu", "x86_64-linux-gnu"),
                      original.replace(self.env["OPENCV_CROSS_ADA"], "/wrong/gcc"),
                      original.replace(str(self.runtime), "/wrong/runtime"),
                      original.replace(self.env["OPENCV_CROSS_CXX"], "/wrong/g++"),
                      original.replace('Compiler\'Driver ("C++")', '"gcc"')):
            with self.subTest(output=wrong):
                self.config.write_text(wrong)
                result = self.run_install()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("GPR", result.stderr)
                self.assertFalse((self.base / "production-work").exists())
                self.assertFalse(self.prefix.exists())

    def test_failure_status_and_log_retention(self):
        for tool, status in (("gprconfig", 42), ("gprbuild", 43), ("gprinstall", 44)):
            with self.subTest(tool=tool), tempfile.TemporaryDirectory() as temp:
                broken = Path(temp) / tool
                broken.write_text(f"#!/bin/sh\necho diagnostic-{tool}\nexit {status}\n")
                broken.chmod(0o755)
                key = "OPENCV_CROSS_" + tool.upper()
                original = self.env[key]
                self.env[key] = str(broken)
                result = self.run_install()
                self.env[key] = original
                self.assertEqual(result.returncode, status, result.stderr)
                self.assertIn("workspace and logs retained:", result.stderr)
                self.assertIn(f"diagnostic-{tool}", result.stderr)
                self.assertTrue(list(self.tmp.rglob("*.log")))

    def test_installed_artifacts_and_every_member_checked(self):
        install = Path(self.env["OPENCV_CROSS_GPRINSTALL"])
        body = install.read_text()
        elf = Path(self.env["OPENCV_CROSS_READELF"])
        elf_body = elf.read_text()
        for kind in ("missing-project", "missing-archive", "mixed-machine", "mixed-class"):
            with self.subTest(kind=kind):
                install.write_text(body)
                elf.write_text(elf_body)
                if kind.startswith("missing"):
                    artifact = ("share/gpr/opencv_core_shim.gpr" if kind == "missing-project"
                                else "lib/opencv_core_shim/libopencv_core_shim.a")
                    install.write_text(body + f'rm "$prefix/{artifact}"\n')
                else:
                    field = "Machine: X86-64" if kind == "mixed-machine" else "Class: ELF32"
                    elf.write_text(elf_body + 'case "$*" in *libopencv_core_shim.a*) '
                                   f"printf '%s\\n' {shlex.quote(field)} ;; esac\n")
                result = self.run_install()
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((self.prefix / "share/gprconfig/aarch64-linux-gnu.cgpr").exists())
                shutil.rmtree(self.prefix)

    def test_legacy_cli_default_workspace_install(self):
        self.env.update(OPENCV_CROSS_GPR_CONFIG=str(self.config),
                        OPENCV_CROSS_SOURCE_ROOT=str(self.source),
                        PKG_CONFIG_LIBDIR=str(Path(self.env["ENV_PREFIX"]) / "usr/lib/pkgconfig"))
        work = self.base / "legacy-work"
        result = subprocess.run(["sh", str(ROOT / "scripts/cross_build_core.sh"),
                                 "--build", str(work)], env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((work / "install/share/gprconfig/aarch64-linux-gnu.cgpr").is_file())

    def test_qualification_consumer_after_cleanup_and_runpath_rejection(self):
        shutil.copy(ROOT / "tests/installed_mat_consumer.adb", self.source / "tests/")
        (self.source / "tests/gnat12").mkdir()
        shutil.copy(ROOT / "tests/gnat12/installed_ada.gpr", self.source / "tests/gnat12/")
        build = Path(self.env["OPENCV_CROSS_GPRBUILD"])
        build_body = build.read_text()
        # The consumer mock asserts the actual production workspace is gone and
        # the command preserves warning policy (the copied GPR) and uses -R.
        build.write_text(build_body.replace("set -eu\n", 'set -eu\n'
                         'if [ "${1:-}" = --help ]; then echo "  -R       Do not use run path option"; exit 0; fi\n'
                         'case "$*" in *installed_ada.gpr*)\n'
                         f'test ! -d "$(cat "{self.base}/production-work")"\n'
                         'case "$*" in *" -R "*) ;; *) exit 95 ;; esac\n'
                         f'echo "{self.env["OPENCV_CROSS_ADA"]} {self.env["OPENCV_CROSS_CXX"]}"\n'
                         f'echo "{self.prefix}/lib/opencv_core/libopencv_core_ada.a"\n'
                         f'echo "{self.prefix}/lib/opencv_core_shim/libopencv_core_shim.a"\n'
                         'mkdir -p bin; touch bin/installed_mat_consumer; exit 0 ;; esac\n'))
        elf = Path(self.env["OPENCV_CROSS_READELF"])
        elf_body = elf.read_text()
        extra = ('case "$*" in *installed_mat_consumer*)\n'
                 "echo 'Data: little endian'\n"
                 "echo 'Requesting program interpreter: /lib/ld-linux-aarch64.so.1'\n"
                 "echo '(NEEDED) libopencv_core.so.4.9.0'\n"
                 ';; esac\n')
        elf.write_text(elf_body + extra)
        args = ["sh", str(ROOT / "tests/qualify_cross_install.sh"), *self.args[2:]]
        result = subprocess.run(args, env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Target execution: NOT PERFORMED", result.stdout)
        shutil.rmtree(self.prefix)
        elf.write_text(elf_body + extra.replace(";; esac", "echo '(RUNPATH) /build-machine/lib'\n;; esac"))
        result = subprocess.run(args, env=self.env, text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("deployment run path", result.stderr)


if __name__ == "__main__":
    unittest.main()