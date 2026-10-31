"""Exercise the installer's provenance assertion against the published schema."""
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


class Provenance(unittest.TestCase):
    def setUp(self):
        line = next(line for line in (ROOT / 'scripts/install_doc_enhancer.sh').read_text().splitlines()
                    if line.startswith('"$python" -c ') and 'release_version' in line)
        self.assertion = shlex.split(line)[2]
        self.record = {
            'release_version': '0.1.3',
            'expected_source_commit': 'ce117aedc7eeb8c45aafc07dea9357166caadf0d',
            'expected_source_tree': 'e87c8500165c119753843f71e34868b7133523d1',
        }

    def check(self, expected):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'release-provenance.json'
            path.write_text(json.dumps(self.record))
            result = subprocess.run([sys.executable, '-c', self.assertion, str(path)],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode == 0, expected, result.stderr)

    def test_published_schema(self):
        self.check(True)

    def test_wrong_version_commit_or_tree(self):
        for key in self.record:
            with self.subTest(key=key):
                original = self.record[key]
                self.record[key] = 'unqualified'
                self.check(False)
                self.record[key] = original

    def test_missing_provenance_fields(self):
        original = dict(self.record)
        for key in original:
            with self.subTest(key=key):
                self.record = {name: value for name, value in original.items() if name != key}
                self.check(False)

    def test_unpublished_field_names_are_not_authority(self):
        self.record['source_commit'] = self.record.pop('expected_source_commit')
        self.record['source_tree'] = self.record.pop('expected_source_tree')
        self.check(False)


class Acquisition(unittest.TestCase):
    """Execute the real acquisition gate with isolated transport substitutions."""
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.assets = self.root / 'assets'
        self.assets.mkdir()
        for name in ['ada_gnatdoc_enhancer-0.1.3-py3-none-any.whl',
                     'SHA256SUMS', 'release-provenance.json']:
            shutil.copyfile(ROOT / '.doc-tools/enhancer-release' / name, self.assets / name)
        scripts = self.root / 'scripts'
        scripts.mkdir()
        script = (ROOT / 'scripts/install_doc_enhancer.sh').read_text()
        # No installation is needed to test transport/integrity rejection.
        (scripts / 'install_doc_enhancer.sh').write_text(script.split('"$python" -m venv')[0])
        bin_dir = self.root / 'bin'
        bin_dir.mkdir()
        curl = bin_dir / 'curl'
        curl.write_text('#!/bin/sh\nset -eu\ncp "$ASSET_FIXTURE/${5##*/}" "$4"\n')
        curl.chmod(0o755)
        self.env = {**os.environ, 'PATH': str(bin_dir) + os.pathsep + os.environ['PATH'],
                    'ASSET_FIXTURE': str(self.assets), 'DOC_BOOTSTRAP_PYTHON': sys.executable}

    def check(self, expected):
        result = subprocess.run(['sh', str(self.root / 'scripts/install_doc_enhancer.sh')],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, expected, result.stdout + result.stderr)

    def test_official_published_assets(self):
        self.check(True)

    def test_incorrect_assets_rejected(self):
        for path in self.assets.iterdir():
            with self.subTest(asset=path.name):
                original = path.read_bytes()
                path.write_bytes(original + b'forged')
                self.check(False)
                path.write_bytes(original)

    def test_missing_assets_rejected(self):
        for path in self.assets.iterdir():
            with self.subTest(asset=path.name):
                original = path.read_bytes()
                path.unlink()
                self.check(False)
                path.write_bytes(original)


if __name__ == '__main__':
    unittest.main()