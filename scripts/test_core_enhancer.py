"""Consumer authority tests: metadata cannot bless altered native/source output."""
import contextlib
import io
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from verify_core_enhancer import validate, validate_native
from link_gnatdoc_types import sources, pages_and_targets, LINK

ROOT = Path(__file__).resolve().parent.parent


class Publication(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.site = Path(self.temp.name) / 'site'
        shutil.copytree(ROOT / '_site', self.site)
        self.pages, _ = pages_and_targets(self.site / 'api', sources(ROOT / 'src'))

    def check(self):
        with contextlib.redirect_stdout(io.StringIO()):
            validate(self.site)

    def test_complete_publication_is_read_only(self):
        before = {p.relative_to(self.site): p.read_bytes() for p in self.site.rglob('*') if p.is_file()}
        self.check()
        self.assertEqual(before, {p.relative_to(self.site): p.read_bytes() for p in self.site.rglob('*') if p.is_file()})

    def test_original_native_metadata_cannot_authorize_changes(self):
        path = self.site / 'api/presentation.json'
        data = json.loads(path.read_text())
        original = dict(data['original_api_html'])
        for name, text in original.items():
            if '<h4' in text:
                data['original_api_html'][name] = text.replace('<h4', '<h3', 1)
                break
        path.write_text(json.dumps(data))
        with self.assertRaises(ValueError):
            self.check()

    def test_counts_cannot_be_forged(self):
        path = self.site / 'api/presentation.json'
        data = json.loads(path.read_text())
        data['counts']['linked_types'] += 1
        path.write_text(json.dumps(data))
        with self.assertRaises(ValueError):
            self.check()

    def test_size_link_wrong_existing_destination_is_rejected(self):
        path = self.pages['opencv.core'][0]
        text = path.read_text()
        size = next(m for m in LINK.finditer(text) if m[2] == 'opencv.size')
        wrong = next(m for m in LINK.finditer(text) if m[2] == 'opencv.point')
        path.write_text(text.replace(size[1], wrong[1]))
        with self.assertRaises(ValueError):
            self.check()

    def test_unlisted_file_and_symlink_rejected(self):
        path = self.site / 'unapproved.txt'
        path.write_text('not authorized')
        with self.assertRaises(ValueError):
            self.check()
        path.unlink()
        path.symlink_to(self.site / 'index.html')
        with self.assertRaises(ValueError):
            self.check()

    def test_native_source_requalification_is_not_automatic(self):
        native = Path(self.temp.name) / 'native'
        shutil.copytree(ROOT / 'obj/docs/native', native)
        validate_native(native)
        path = next((native / 'api').glob('*.html'))
        path.write_text(path.read_text() + '\n')
        with self.assertRaises(ValueError):
            validate_native(native)


if __name__ == '__main__':
    unittest.main()