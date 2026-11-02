"""Consumer authority tests: metadata cannot bless altered native/source output."""
import contextlib
import io
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from verify_core_enhancer import (validate, validate_native, validate_theme_identity,
                                  THEME_SOURCE, CONFIG_SOURCE, digest)
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

    def test_custom_theme_metadata_is_exact_not_authority(self):
        path = self.site / 'api/presentation.json'
        original = json.loads(path.read_text())
        for key in original['theme_source']:
            with self.subTest(key=key):
                data = json.loads(json.dumps(original))
                data['theme_source'][key] = 'unapproved'
                path.write_text(json.dumps(data))
                with self.assertRaises(ValueError):
                    self.check()
        for replacement in [None, {}, {**original['theme_source'], 'extra': True}]:
            data = json.loads(json.dumps(original))
            data['theme_source'] = replacement
            path.write_text(json.dumps(data))
            with self.assertRaises(ValueError):
                self.check()
        del data['theme_source']
        path.write_text(json.dumps(data))
        with self.assertRaises(ValueError):
            self.check()

    def test_rehashed_published_css_is_not_approved(self):
        css = self.site / 'api/gnatdoc-theme.css'
        css.write_bytes(css.read_bytes() + b'\n.landing { max-width: none; }\n')
        path = self.site / 'api/presentation.json'
        data = json.loads(path.read_text())
        data['output_sha256']['api/gnatdoc-theme.css'] = digest(css.read_bytes())
        path.write_text(json.dumps(data))
        with self.assertRaises(ValueError):
            self.check()

    def test_rehashed_source_or_configuration_is_not_approved(self):
        root = Path(self.temp.name) / 'inputs'
        from core_verified_examples import selected_mapping
        (mapping_name, _), mapping = selected_mapping(ROOT)
        for name in [mapping_name, *mapping['inputs']]:
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        for name in [THEME_SOURCE, CONFIG_SOURCE]:
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, target)
        identity = json.loads((self.site / 'api/presentation.json').read_text())['theme_source']
        validate_theme_identity(identity, root)
        for name, key in [(THEME_SOURCE, 'sha256'), (CONFIG_SOURCE, 'config_sha256')]:
            with self.subTest(name=name):
                path = root / name
                original = path.read_bytes()
                path.write_bytes(original + b'\n')
                forged = {**identity, key: digest(path.read_bytes())}
                with self.assertRaises(ValueError):
                    validate_theme_identity(forged, root)
                path.write_bytes(original)

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

    def forge_search(self, mutate):
        """Rehash cache AND shell AND manifest; none can bless forged content."""
        path = self.site / 'api/gnatdoc-search-index.json'
        old = digest(path.read_bytes())
        data = json.loads(path.read_text())
        mutate(data)
        path.write_text(json.dumps(data, sort_keys=True, indent=2, ensure_ascii=False) + '\n')
        shell = self.site / 'api/index.html'
        shell.write_text(shell.read_text().replace(old, digest(path.read_bytes())))
        manifest = self.site / 'api/presentation.json'
        presentation = json.loads(manifest.read_text())
        for name in ['api/index.html', 'api/gnatdoc-search-index.json']:
            presentation['output_sha256'][name] = digest((self.site / name).read_bytes())
        manifest.write_text(json.dumps(presentation))
        with self.assertRaises(ValueError):
            self.check()

    def test_modified_search_text_rehashed(self):
        self.forge_search(lambda d: d['records'][0].update(text='forged description'))

    def test_missing_search_record_rehashed(self):
        self.forge_search(lambda d: d['records'].pop())

    def test_duplicate_search_record_rehashed(self):
        self.forge_search(lambda d: d['records'].append(dict(d['records'][0])))

    def test_forged_search_name_rehashed(self):
        self.forge_search(lambda d: d['records'][0].update(name='OpenCV.Core.Private_Handle'))

    def test_internal_search_record_rehashed(self):
        self.forge_search(lambda d: d['records'][0].update(name='OpenCV.Internal.Native.Handle'))

    def test_private_completion_rehashed(self):
        self.forge_search(lambda d: next(r for r in d['records'] if r['name'] == 'OpenCV.Core.Mat').update(
            text='type Mat is record Handle : System.Address; end record;'))

    def test_reordered_search_records_rehashed(self):
        self.forge_search(lambda d: d['records'].reverse())

    def test_wrong_existing_search_destination_rehashed(self):
        self.forge_search(lambda d: d['records'][0].update(href=d['records'][1]['href']))

    def test_cross_origin_search_destination_rehashed(self):
        self.forge_search(lambda d: d['records'][0].update(href='https://example.com/'))

    def test_unauthorized_guide_rehashed(self):
        self.forge_search(lambda d: next(r for r in d['records'] if r['kind'] == 'guide').update(
            href='../guides/not-approved.html'))

    def test_wrong_search_kind_rehashed(self):
        self.forge_search(lambda d: d['records'][0].update(kind='operation'))

    def test_wrong_search_schema_rehashed(self):
        self.forge_search(lambda d: d.update(schema_version=2))

    def test_forged_overload_label_rehashed(self):
        self.forge_search(lambda d: next(r for r in d['records'] if 'overload' in r['label']).update(
            label='OpenCV.Core.Create (overload 99/99)'))

    def test_search_assets_missing_or_rehashed(self):
        for name in ['gnatdoc-search-index.json', 'gnatdoc-search.css', 'gnatdoc-navigation.js']:
            with self.subTest(name=name):
                path = self.site / 'api' / name
                original = path.read_bytes()
                path.unlink()
                with self.assertRaises((ValueError, FileNotFoundError)):
                    self.check()
                path.write_bytes(original + b'\n')
                manifest = self.site / 'api/presentation.json'
                data = json.loads(manifest.read_text())
                data['output_sha256']['api/' + name] = digest(path.read_bytes())
                manifest.write_text(json.dumps(data))
                with self.assertRaises(ValueError):
                    self.check()
                path.write_bytes(original)


if __name__ == '__main__':
    unittest.main()