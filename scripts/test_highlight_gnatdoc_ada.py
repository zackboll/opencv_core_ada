"""Lexical cases plus coordinated final-HTML semantic mutation tests."""

import contextlib
import io
import unittest

from highlight_gnatdoc_ada import highlight, strip_highlighting
from install_gnatdoc_theme import install, check_theme, NATIVE
from link_gnatdoc_types import CrossReferenceError, LINK, SECTION, plain, process
import test_link_gnatdoc_types as fixtures


class Tokens(unittest.TestCase):
    def assert_token(self, text, category, value):
        output = highlight(text)
        self.assertIn(f'<span class="ada-{category}">{value}</span>', output)
        self.assertEqual(strip_highlighting(output), text)

    def test_mixed_case_and_identifier_boundaries(self):
        self.assert_token('FuNcTiOn functional return_value RETURN', 'keyword', 'FuNcTiOn')
        self.assertNotIn('>functional</span>', highlight('functional'))
        self.assertNotIn('>return_value</span>', highlight('return_value'))

    def test_profiles_modes_and_nested_access(self):
        text = ('procedure Set (A, B : aliased in out Mat; '
                'Process : not null access function (X : in Mat) return Mat)')
        for word in ('procedure', 'aliased', 'in', 'out', 'not', 'null', 'access', 'function', 'return'):
            self.assert_token(text, 'keyword', word)

    def test_multiline_arrays_records_and_generics(self):
        text = 'generic\ntype T is private;\ntype A is array (1 .. 4) of T;\ntype R is record\nX : T;\nend record;'
        for word in ('generic', 'type', 'private', 'array', 'of', 'record', 'end'):
            self.assert_token(text, 'keyword', word)

    def test_strings_doubled_quotes_not_recursive(self):
        self.assert_token('"return ""function"""', 'string', '"return ""function"""')
        self.assertNotIn('ada-keyword', highlight('"return"'))

    def test_characters_and_attributes(self):
        self.assert_token("'A'", 'character', "'A'")
        self.assert_token("'''", 'character', "'''")
        for attr in ("'First", "'Length", "'Image"):
            self.assert_token('A' + attr, 'attribute', attr)

    def test_numbers_based_decimal_exponents_underscores(self):
        for number in ('0', '1.0', '16#FF#', '2#1_0.01#E+2', '1_000', '1.25e-10', '12E3'):
            self.assert_token(number, 'number', number)
        self.assertEqual(highlight('1..2').count('ada-number'), 2)

    def test_comments_not_recursive(self):
        self.assert_token('-- return "type" 16#FF#', 'comment', '-- return "type" 16#FF#')
        self.assertNotIn('ada-keyword', highlight('-- return'))

    def test_escaped_operators(self):
        for operator in (':=', '=&gt;', '..', '**', '/=', '&lt;&gt;', '&amp;'):
            self.assert_token(operator, 'operator', operator)

    def test_atomic_links(self):
        link = '<a class="type-reference" href="page.html#anchor" data-type="demo.mat">mAt</a>'
        self.assertIn(link, highlight('function F return ' + link))
        self.assertEqual([m[0] for m in LINK.finditer(highlight(link))], [link])


class Pipeline(unittest.TestCase):
    def setUp(self):
        self.fixture = fixtures.TypeLinks()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)
        self.api, self.src = self.fixture.api, self.fixture.src
        self.page = self.fixture.package('Demo.Access', [
            'function Read (A, B : in out Mat) return UInt8_Value;',
            'type Pair is record\nImage : Mat;\nend record;'])
        for path in self.api.glob('*.html'):
            path.write_text(path.read_text().replace('<!DOCTYPE html>', '<!DOCTYPE html>' + NATIVE))
        (self.api / 'gnatdoc.css').write_text('/* native fixture */')
        (self.api / 'index.html').write_text('<!DOCTYPE html>' + NATIVE +
            '<body class=main><a href=Demo.Access.html target=document-content>Demo.Access</a>'
            '<iframe name=document-content></iframe>')
        self.original = {p.name: p.read_text() for p in self.api.glob('*.html')}
        with contextlib.redirect_stdout(io.StringIO()):
            install(self.api)
            process(self.api, self.src)
        self.linked = self.page.read_text()
        self.run_process(highlight=True)

    def run_process(self, **kwargs):
        with contextlib.redirect_stdout(io.StringIO()):
            return process(self.api, self.src, **kwargs)

    def test_final_text_links_order_and_overload_integrity(self):
        self.run_process(check=True)
        original = list(SECTION.finditer(self.original[self.page.name]))
        final = list(SECTION.finditer(self.page.read_text()))
        self.assertEqual([plain(strip_highlighting(m[3])) for m in final], [m[3] for m in original])
        self.assertEqual([m[0] for m in LINK.finditer(self.page.read_text())],
                         [m[0] for m in LINK.finditer(self.linked)])

    def test_idempotence_and_determinism(self):
        before = {p.name: p.read_bytes() for p in self.api.iterdir()}
        with contextlib.redirect_stdout(io.StringIO()):
            install(self.api)
        self.run_process(highlight=True)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.api.iterdir()})
        # Rebuild from the same native input, not from the enhanced output.
        for path in self.api.iterdir():
            if path.name in self.original:
                path.write_text(self.original[path.name])
            elif path.name != 'gnatdoc.css':
                path.unlink()
        with contextlib.redirect_stdout(io.StringIO()):
            install(self.api)
            process(self.api, self.src)
        self.run_process(highlight=True)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.api.iterdir()})

    def test_wrong_but_existing_type_destination(self):
        good = self.page.read_text()
        links = list(LINK.finditer(good))
        wrong = next(m for m in links if m[2] == 'demo.uint8_value')
        self.page.write_text(good.replace(links[0][0], links[0][0].replace(links[0][1], wrong[1])))
        with self.assertRaisesRegex(CrossReferenceError, 'identity/destination/markup'):
            self.run_process(check=True)

    def test_missing_anchor(self):
        self.page.write_text(self.page.read_text().replace('id=native_0', 'id=removed'))
        with self.assertRaises(CrossReferenceError):
            self.run_process(check=True)

    def test_unknown_nested_or_corrupted_markup(self):
        good = self.page.read_text()
        for bad in (good.replace('ada-keyword', 'ada-unknown'),
                    good.replace('<span class="ada-keyword">', '<span class="ada-keyword" title="x">'),
                    good.replace('>function</span>', '><b>function</b></span>'),
                    good.replace('>Mat</a>', '>Mat</a></a>')):
            with self.subTest(bad=bad[:60]):
                self.page.write_text(bad)
                with self.assertRaises(CrossReferenceError):
                    self.run_process(check=True)

    def test_valid_html_changed_token_and_whitespace(self):
        good = self.page.read_text()
        for bad in (good.replace('>function</span>', '>FUNCTION</span>'),
                    good.replace('Read ', 'Read  ')):
            self.page.write_text(bad)
            with self.assertRaisesRegex(CrossReferenceError, 'declaration text changed'):
                self.run_process(check=True)

    def test_valid_but_wrong_syntax_category(self):
        self.page.write_text(self.page.read_text().replace('ada-keyword', 'ada-number', 1))
        with self.assertRaisesRegex(CrossReferenceError, 'markup mismatch'):
            self.run_process(check=True)

    def test_unapproved_non_snippet_changes(self):
        self.page.write_text(self.page.read_text().replace('Mat prose', 'Changed prose'))
        with self.assertRaises(CrossReferenceError):
            self.run_process(check=True)
        with self.assertRaises(CrossReferenceError):
            check_theme(self.api)

    def test_missing_and_corrupted_theme_assets(self):
        asset = self.api / 'gnatdoc-theme.css'
        asset.write_text('corrupted')
        with self.assertRaisesRegex(CrossReferenceError, 'asset differs'):
            check_theme(self.api)
        asset.unlink()
        with self.assertRaisesRegex(CrossReferenceError, 'missing theme asset'):
            check_theme(self.api)

    def test_broken_stylesheet_link_and_index_navigation(self):
        index = self.api / 'index.html'
        good = index.read_text()
        self.assertIn('target=document-content', good)
        self.assertIn('<iframe name=document-content>', good)
        for bad in (good.replace('gnatdoc-theme.css', 'missing.css'),
                    good.replace('Demo.Access.html', 'Demo.html')):
            index.write_text(bad)
            with self.assertRaises(CrossReferenceError):
                check_theme(self.api)

    def test_native_css_unchanged(self):
        (self.api / 'gnatdoc.css').write_text('changed')
        with self.assertRaisesRegex(CrossReferenceError, 'native GNATdoc stylesheet'):
            check_theme(self.api)

    def test_failed_insertion_is_atomic(self):
        for path in self.api.iterdir():
            if path.name in self.original:
                path.write_text(self.original[path.name])
            elif path.name != 'gnatdoc.css':
                path.unlink()
        self.page.write_text(self.page.read_text().replace(NATIVE, ''))
        before = {p.name: p.read_bytes() for p in self.api.iterdir()}
        with self.assertRaisesRegex(CrossReferenceError, 'insertion point'):
            install(self.api)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.api.iterdir()})


if __name__ == '__main__':
    unittest.main()