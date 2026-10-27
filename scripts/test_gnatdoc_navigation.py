"""Negative-first navigation qualification against the real final validator."""
import contextlib
import io
from pathlib import Path
import re
import shutil
import tempfile
import unittest

from enhance_gnatdoc_navigation import enhance, check_navigation
from validate_docs import validate
from verify_core_enhancer import is_enhancer, validate as check_core

ROOT = Path(__file__).resolve().parent.parent


class NavigationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.site = Path(self.temp.name) / 'site'
        shutil.copytree(ROOT / '_site', self.site)
        self.api = self.site / 'api'
        self.shared = is_enhancer(self.api)
        if not self.shared:
            enhance(self.api)

    def test_complete_inventory_and_idempotence(self):
        inventory = check_core(self.site) if self.shared else check_navigation(self.api)
        self.assertEqual(len(inventory), 195)
        self.assertIn('OpenCV.Core', inventory)
        before = {p.name: p.read_bytes() for p in self.api.iterdir() if p.is_file()}
        if self.shared:
            check_core(self.site)
        else:
            enhance(self.api)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.api.iterdir() if p.is_file()})
        with contextlib.redirect_stdout(io.StringIO()):
            validate(self.site)

    def test_final_validator_rejects_mutations(self):
        path = self.api / 'index.html'
        original = path.read_text()
        links = re.findall(r'<li><a href=([^ >]+) target=document-content>([^<]+)</a>', original)
        first, second = links[:2]
        mutations = {
            'duplicate identity': original.replace('>OpenCV.Core</a>', '>OpenCV</a>', 1),
            'missing package': original.replace(f'<li><a href={first[0]} target=document-content>{first[1]}</a>', '', 1),
            'wrong existing target': original.replace(first[0], second[0], 1),
            'swapped destinations': original.replace(first[0], 'SWAP', 1).replace(second[0], first[0], 1).replace('SWAP', second[0], 1),
            'altered target': original.replace('target=document-content', 'target=other', 1),
            'missing script': original.replace('<script src="gnatdoc-navigation.js" defer></script>', ''),
            'duplicate script': original + '<script src="gnatdoc-navigation.js" defer></script>',
            'unsupported shell': original.replace('name=document-content', 'name=other'),
            'missing tagged link': original.replace(f'<li><a href={links[-1][0]} target=document-content>{links[-1][1]}</a>', ''),
            'inline script': original + '<script>alert(1)</script>',
            'event handler': original.replace('<body class=main>', '<body class=main onload="alert(1)">'),
            'duplicate control': original + '<div id="package-search"></div>',
            'external': original.replace(first[0], 'https://example.com/', 1),
            'traversal': original.replace(first[0], '../index.html', 1),
        }
        for label, text in mutations.items():
            with self.subTest(label=label):
                path.write_text(text)
                with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit):
                    validate(self.site)
        path.write_text(original)

    def test_tampered_asset(self):
        with (self.api / 'gnatdoc-navigation.js').open('a') as stream:
            stream.write('\n// tampered\n')
        with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit):
            validate(self.site)

    def test_symbol_destinations_are_independently_reconstructed(self):
        path = self.api / 'index.html'
        original = path.read_text()
        symbols = re.findall(r'<a href="([^"]+)" data-symbol="([^"]+)"></a>', original)
        self.assertGreater(len(symbols), 50)
        for name in ('OpenCV.Rect', 'OpenCV.Size', 'OpenCV.Angle_Unit',
                     'OpenCV.Core.Mat', 'OpenCV.Float64_Value'):
            self.assertEqual(sum(n == name for _, n in symbols), 1)
        first, second = symbols[:2]
        for text in (
                original.replace('data-symbol="OpenCV.Rect"', 'data-symbol="OpenCV.Size"'),
                original.replace(f'<a href="{first[0]}" data-symbol="{first[1]}"></a>', ''),
                original.replace(f'href="{first[0]}"', f'href="{second[0]}"', 1),
                original.replace('data-symbol="OpenCV.Rect"', 'data-symbol="OpenCV.Absent"')):
            path.write_text(text)
            with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(SystemExit):
                validate(self.site)
        path.write_text(original)


if __name__ == '__main__':
    unittest.main()