"""Rehashed example mutations cannot acquire authority from presentation.json."""
import contextlib
import io
import json
import shutil
import tempfile
import unittest
import zipfile
from pathlib import Path

from verify_core_enhancer import validate, digest
from verify_core_examples import CSS_SHA, STYLESHEET, landing_example, native_destinations

ROOT = Path(__file__).resolve().parent.parent


class Examples(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.site = Path(self.temp.name) / 'site'
        shutil.copytree(ROOT / '_site', self.site)

    def check(self):
        with contextlib.redirect_stdout(io.StringIO()):
            validate(self.site)

    def mutation(self, name, mutate):
        path = self.site / name
        original = path.read_text()
        changed = mutate(original)
        self.assertNotEqual(changed, original, 'mutation must exercise actual published markup')
        path.write_text(changed)
        metadata = self.site / 'api/presentation.json'
        data = json.loads(metadata.read_text())
        data['output_sha256'][name] = digest(path.read_bytes())
        metadata.write_text(json.dumps(data))
        with self.assertRaises((ValueError, OSError)):
            self.check()

    def test_complete_independent_reconstruction(self):
        self.check()

    def test_stylesheet_is_official_wheel_bytes(self):
        wheel = ROOT / '.doc-tools/enhancer-release/ada_gnatdoc_enhancer-0.1.4-py3-none-any.whl'
        self.assertEqual(digest(wheel.read_bytes()),
                         '057b7945a71d3afb10cbabec32111b4ac2d94a116c6b8553f70c71229a68ffc7')
        with zipfile.ZipFile(wheel) as archive:
            css = archive.read('ada_gnatdoc_enhancer/' + STYLESHEET)
        self.assertEqual(digest(css), CSS_SHA)
        self.assertEqual(css, (self.site / STYLESHEET).read_bytes())

    def test_rehashed_wrong_valid_link(self):
        destinations = native_destinations(ROOT, self.site)
        mat = destinations['opencv.core.mat'][0]
        umat = destinations['opencv.core.umat'][0]
        self.mutation('index.html', lambda text: text.replace(mat, umat))

    def test_guide_rehashed_wrong_valid_link(self):
        destinations = native_destinations(ROOT, self.site)
        self.mutation('guides/ownership-and-views.html', lambda text: text.replace(
            destinations['opencv.core.mat'][0], destinations['opencv.core.umat'][0]))

    def test_overloaded_create_link_rejected(self):
        href = native_destinations(ROOT, self.site)['opencv.core.mat'][0]
        self.mutation('index.html', lambda text: text.replace('Create ',
            f'<a class="ada-api-reference" href="api/{href}">Create</a> ', 1))

    def test_object_prefixed_clone_link_rejected(self):
        href = native_destinations(ROOT, self.site)['opencv.core.mat'][0]
        self.mutation('index.html', lambda text: text.replace('Clone',
            f'<a class="ada-api-reference" href="api/{href}">Clone</a>', 1))

    def test_local_variable_link_rejected(self):
        href = native_destinations(ROOT, self.site)['opencv.core.mat'][0]
        self.mutation('index.html', lambda text: text.replace('Image ',
            f'<a class="ada-api-reference" href="api/{href}">Image</a> ', 1))

    def test_comment_link_rejected(self):
        href = native_destinations(ROOT, self.site)['opencv.core.mat'][0]
        self.mutation('guides/ownership-and-views.html', lambda text: text.replace(
            '<span class="ada-comment">-- Data',
            f'<span class="ada-comment">-- <a class="ada-api-reference" href="../api/{href}">Data</a>', 1))

    def test_string_link_rejected(self):
        href = native_destinations(ROOT, self.site)['opencv.core.mat'][0]
        self.mutation('guides/sparse-and-persistence-guide.html', lambda text: text.replace(
            '<span class="ada-string">"Camera"</span>',
            f'<span class="ada-string">"<a class="ada-api-reference" href="../api/{href}">Camera</a>"</span>', 1))

    def test_formal_link_rejected(self):
        href = native_destinations(ROOT, self.site)['opencv.core.mat'][0]
        self.mutation('guides/ownership-and-views.html', lambda text: text.replace(
            'Process <span class="ada-operator">(</span>Image',
            f'Process <span class="ada-operator">(</span><a class="ada-api-reference" href="../api/{href}">Image</a>', 1))

    def test_guide_prose_rehashed(self):
        self.mutation('guides/ownership-and-views.html', lambda text: text.replace(
            '<h1 id="ownership-and-views">Ownership and views</h1>',
            '<h1 id="ownership-and-views">Altered ownership and views</h1>', 1))

    def test_nonada_fence_rehashed(self):
        self.mutation('guides/interop-and-compatibility.html', lambda text: text.replace(
            '<pre><code class="language-sh">',
            '<pre class="ada-example" tabindex="0"><code class="language-sh">', 1))

    def test_rehashed_token_class(self):
        self.mutation('index.html', lambda text: text.replace('ada-keyword', 'ada-number', 1))

    def test_rehashed_code_character(self):
        self.mutation('index.html', lambda text: text.replace('>2</span>', '>9</span>', 1))

    def test_rehashed_extra_markup(self):
        self.mutation('index.html', lambda text: text.replace('</pre>', '<b></b></pre>', 1))

    def test_shell_highlighting_rejected(self):
        self.mutation('index.html', lambda text: text.replace('<pre>alr', '<pre class="ada-example">alr', 1))

    def test_rehashed_unauthorized_css(self):
        self.mutation(STYLESHEET, lambda text: text + '\nbody { color: red; }\n')

    def test_missing_stylesheet(self):
        (self.site / STYLESHEET).unlink()
        with self.assertRaises((ValueError, OSError)):
            self.check()

    def test_stylesheet_symlink_substitution(self):
        path = self.site / STYLESHEET
        copy = Path(self.temp.name) / 'css'
        copy.write_bytes(path.read_bytes())
        path.unlink()
        path.symlink_to(copy)
        with self.assertRaises(ValueError):
            self.check()

    def test_extra_asset(self):
        (self.site / 'assets/extra.css').write_text('')
        with self.assertRaises(ValueError):
            self.check()

    def test_wrong_enhancer_version(self):
        self.mutation('api/presentation.json', lambda text: text.replace('0.1.4', '0.1.3'))

    def test_ambiguous_or_changed_home_source_rejected(self):
        root = Path(self.temp.name) / 'inputs'
        (root / 'docs').mkdir(parents=True)
        example = (ROOT / 'docs/example.adb').read_bytes()
        (root / 'docs/example.adb').write_bytes(example)
        home = (ROOT / 'docs/index.html').read_text()
        for text in (home + '<pre>' + example.decode().rstrip('\n') + '</pre>',
                     home.replace('Image.Clone', 'Image.Copy')):
            (root / 'docs/index.html').write_text(text)
            with self.assertRaises(ValueError):
                landing_example(root, self.site)


if __name__ == '__main__':
    unittest.main()
