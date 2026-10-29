"""Exercise the installer's provenance assertion against the published schema."""
import json
import shlex
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
            'release_version': '0.1.2',
            'expected_source_commit': 'd7636cc50154ebb5535c699d2bed6406ebc92e62',
            'expected_source_tree': 'ca7d4d70f2fc556eafe6b222facacadb16fa272a',
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


if __name__ == '__main__':
    unittest.main()