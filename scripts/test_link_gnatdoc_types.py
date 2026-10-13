"""Realistic native-section fixtures, semantic negative controls and integrity."""

import contextlib
import html
import io
import tempfile
import unittest
from pathlib import Path

from link_gnatdoc_types import CrossReferenceError, process, SECTION, plain
from validate_docs import validate, overload_sections


class TypeLinks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.api = self.root / 'api'
        self.src = self.root / 'src'
        self.api.mkdir()
        self.src.mkdir()
        self.package('Demo', [
            'type Mat is tagged private;', 'type UMat is tagged private;',
            'type Index_Array is array (Positive range <>) of Integer;',
            'subtype UInt8_Value is Integer;', 'type Float16_Value is private;',
            'type Dimension_Array is array (Positive range <>) of Integer;'])

    def package(self, name, declarations, context='', formal='', instance=None):
        source = context + '\n' + formal + '\npackage ' + name + ' is\n'
        if instance:
            source += 'new ' + instance + ';\n'
        else:
            source += '\n'.join(declarations) + '\nend ' + name + ';\n'
        (self.src / (name.lower().replace('.', '-') + '.ads')).write_text(source)
        sections = ''
        for i, declaration in enumerate(declarations):
            name_tokens = declaration.split()
            label = name_tokens[1] if name_tokens[0] in {
                'type', 'subtype', 'function', 'procedure'} else name_tokens[0]
            rendered = declaration.rstrip(';') if name_tokens[0] in {
                'function', 'procedure'} else declaration
            sections += (f'<h4 id=native_{i}>{label}</h4>'
                         '<pre class=ada-code-snippet><code>' +
                         html.escape(rendered, quote=False) + '\n</code></pre>')
        filename = name.replace('.', '_') + '.html'
        (self.api / filename).write_text(
            '<!DOCTYPE html><h1>' + name + '</h1><p>Mat prose stays plain.</p>' + sections)
        return self.api / filename

    def run_links(self, check=False):
        with contextlib.redirect_stdout(io.StringIO()):
            return process(self.api, self.src, check=check)

    def test_parameters_returns_modes_and_families(self):
        page = self.package('Demo.Access', [
            'function Get (Image : Mat; Indices : Index_Array) return UInt8_Value;',
            'procedure Set (Left, Right : in out UMat; Value : Float16_Value; Shape : Dimension_Array);'])
        counts, _ = self.run_links()
        self.assertEqual(counts['linked'], 6)
        output = page.read_text()
        for identity in ('mat', 'umat', 'index_array', 'uint8_value',
                         'float16_value', 'dimension_array'):
            self.assertIn('data-type="demo.' + identity + '"', output)
        self.assertIn('<p>Mat prose stays plain.</p>', output)

    def test_local_arrays_nested_profiles_case_and_qualified(self):
        page = self.package('Demo.View', [
            'type Buffer_Array is array (Natural range <>) of UInt8_Value;',
            'type Callback is access function (Image : Mat) return UMat;',
            'procedure With_View (Data : aliased in out Buffer_Array; Process : not null access procedure (Image : in out mAt));',
            'function Read (Image : Demo.Mat) return Demo.UInt8_Value;'])
        self.run_links()
        output = page.read_text()
        self.assertIn('href="#native_0" data-type="demo.view.buffer_array"', output)
        self.assertIn('>mAt</a>', output)
        self.assertIn('>Demo.Mat</a>', output)
        self.assertIn('data-type="demo.uint8_value">UInt8_Value</a>', output)
        self.assertIn('data-type="demo.umat">UMat</a>', output)

    def test_subtypes_access_and_local_shadowing(self):
        page = self.package('Demo.Child', [
            'type Mat is private;', 'subtype Alias is Mat;',
            'type Pointer is access Mat;', 'function Read return Mat;'])
        self.run_links()
        self.assertEqual(page.read_text().count('data-type="demo.child.mat"'), 3)

    def test_unknown_names_namesakes_substrings_attributes_and_standard(self):
        page = self.package('Demo.Access', [
            'function Mat (Mat : Integer; Image : Unknown; Count : Natural) return UInt8_Value;',
            'procedure Set (Image : Mat_Type; X : Interfaces.Unsigned_16);',
            "subtype Bounds is Integer range 0 .. Index_Array'Length;"])
        counts, _ = self.run_links()
        self.assertEqual(counts['linked'], 1)
        self.assertNotIn('>Mat</a>', page.read_text())
        self.assertNotIn('>Index_Array</a>', page.read_text())

    def test_ambiguous_use_visibility(self):
        self.package('First', ['type Value is private;'])
        self.package('Second', ['type Value is private;'])
        page = self.package('Consumer', ['function Read return Value;'],
                            context='with First, Second; use First, Second;')
        counts, _ = self.run_links()
        self.assertEqual(counts['ambiguous'], 1)
        self.assertNotIn('type-reference', page.read_text())

    def test_unambiguous_import(self):
        self.package('Other', ['type Value is private;'])
        page = self.package('Consumer', ['function Read return Value;'],
                            context='with Other; use Other;')
        self.run_links()
        self.assertIn('data-type="other.value"', page.read_text())

    def test_generic_formals_and_instance_without_anchor(self):
        self.package('Demo.Generic', ['type Element is private;',
                     'type Vector is array (Positive range <>) of Element;'],
                     formal='generic\ntype Element is private;')
        # Rendered formal also occurs in source header; not a normal member.
        spec = self.src / 'demo-generic.ads'
        spec.write_text('generic\ntype Element is private;\npackage Demo.Generic is\n'
                        'type Vector is array (Positive range <>) of Element;\nend Demo.Generic;')
        self.package('Demo.Instance', [], context='with Demo.Generic;',
                     instance='Demo.Generic (Integer)')
        page = self.package('Demo.User', ['function Read return Demo.Instance.Vector;'],
                            context='with Demo.Instance;')
        self.run_links()
        self.assertNotIn('type-reference', page.read_text())
        generic = (self.api / 'Demo_Generic.html').read_text()
        self.assertNotIn('>Element</a>', generic)

    def test_non_type_shadow_blocks_parent(self):
        page = self.package('Demo.Child', [
            'Mat : Integer;', 'function Read return Mat;'])
        self.run_links()
        self.assertNotIn('type-reference', page.read_text())

    def test_idempotence_determinism_and_text_preservation(self):
        page = self.package('Demo.Access', ['function Read (Image : Mat) return UInt8_Value;'])
        original = page.read_text()
        self.run_links()
        first = {p.name: p.read_bytes() for p in self.api.iterdir()}
        self.run_links()
        self.run_links(check=True)
        self.assertEqual(first, {p.name: p.read_bytes() for p in self.api.iterdir()})
        self.assertEqual([plain(s[3]) for s in SECTION.finditer(page.read_text())],
                         [s[3] for s in SECTION.finditer(original)])
        # Recreate clean inputs in reverse creation order.
        manifest = self.api / 'type-crossrefs.json'
        manifest.unlink()
        files = [(p, p.read_text()) for p in self.api.glob('*.html')]
        for p, text in reversed(files):
            p.unlink()
            p.write_text(SECTION.sub(lambda m: m[0].replace(m[3], plain(m[3]), 1), text))
        self.run_links()
        self.assertEqual(first, {p.name: p.read_bytes() for p in self.api.iterdir()})

    def test_wrong_real_type_anchor_rejected(self):
        page = self.package('Demo.Access', ['function Read return Mat;'])
        self.run_links()
        page.write_text(page.read_text().replace('Demo.html#native_0', 'Demo.html#native_1'))
        with self.assertRaisesRegex(CrossReferenceError, 'identity/destination'):
            self.run_links(check=True)

    def test_missing_page_and_anchor_site_validator(self):
        page = self.package('Demo.Access', ['function Read return Mat;'])
        self.run_links()
        valid = page.read_text()
        for destination, diagnostic in [('absent.html#native_0', 'broken link'),
                                        ('Demo.html#absent', 'missing anchor')]:
            with self.subTest(destination=destination):
                page.write_text(valid.replace('Demo.html#native_0', destination))
                with contextlib.redirect_stdout(io.StringIO()):
                    with self.assertRaisesRegex(SystemExit, diagnostic):
                        validate(self.root)

    def test_invalid_structures_fail_before_writes(self):
        page = self.package('Demo.Access', ['function Read return Mat;'])
        good = page.read_text()
        for bad in (good.replace('<code>', '<code><span>'),
                    good.replace('native_0', ''),
                    good.replace('return Mat', 'return Mat ('),
                    good + good[good.index('<h4'):],
                    good.replace('return Mat', 'return <a href="#native_0">Mat</a>')):
            with self.subTest(bad=bad):
                page.write_text(bad)
                with self.assertRaises(CrossReferenceError):
                    self.run_links()
                self.assertFalse((self.api / 'type-crossrefs.json').exists())

    def test_internal_page_rejected(self):
        self.package('Demo.Internal', ['type Hidden is private;'])
        with self.assertRaisesRegex(CrossReferenceError, 'internal'):
            self.run_links()

    def test_generic_formal_shadows_parent_type(self):
        page = self.package('Demo.Generic', ['function Read return Mat;'],
                            formal='generic\ntype Mat is private;')
        self.run_links()
        self.assertNotIn('type-reference', page.read_text())

    def test_comments_literals_and_unimported_qualification(self):
        self.package('Other', ['type Value is private;'])
        page = self.package('Demo.Child', [
            'function Read (Text : String := "Mat") return Other.Value;',
            'procedure Set (Image : Mat -- UInt8_Value in a comment\n);'])
        self.run_links()
        self.assertEqual(page.read_text().count('type-reference'), 1)
        self.assertIn('-- UInt8_Value in a comment', page.read_text())

    def test_order_and_future_local_shadow(self):
        page = self.package('Demo.Child', ['function Before return Mat;',
                            'type Mat is private;', 'function After return Mat;'])
        self.run_links()
        self.assertIn('data-type="demo.mat"', page.read_text())
        self.assertIn('data-type="demo.child.mat"', page.read_text())

    def test_duplicate_type_identity_rejected(self):
        page = self.api / 'Demo.html'
        text = page.read_text()
        first = next(SECTION.finditer(text))[0]
        page.write_text(text + first.replace('native_0', 'another_native_anchor'))
        with self.assertRaisesRegex(CrossReferenceError, 'conflicting type identity'):
            self.run_links()

    def test_record_component_names_are_not_links(self):
        page = self.package('Demo.Child', [
            'type Pair is record\nMat : Integer;\nImage : UMat;\nend record;'])
        self.run_links()
        self.assertNotIn('>Mat</a>', page.read_text())
        self.assertIn('data-type="demo.umat"', page.read_text())

    def test_enumeration_literal_blocks_parent_namesake(self):
        page = self.package('Demo.Child', ['type Choice is (Mat, Other);',
                                          'function Read return Mat;'])
        self.run_links()
        self.assertNotIn('type-reference', page.read_text())

    def test_nested_or_duplicate_links_and_altered_text_rejected(self):
        page = self.package('Demo.Access', ['function Read return Mat;'])
        self.run_links()
        good = page.read_text()
        link = '<a class="type-reference"'
        for bad in (good.replace('>Mat</a>', '>Mat</a></a>'),
                    good.replace(link, '<a href="#native_0">' + link),
                    good.replace('return ', 'return  '),
                    good.replace('Demo.html#', '/Demo.html#')):
            page.write_text(bad)
            with self.assertRaises(CrossReferenceError):
                self.run_links(check=True)

    def test_overload_signatures_survive_links(self):
        page = self.package('Demo.Access', ['function Read (Image : Mat) return UInt8_Value;',
                                          'function Read (Image : UMat) return UInt8_Value;'])
        before, _ = overload_sections(page.read_text())
        self.run_links()
        after, errors = overload_sections(page.read_text())
        self.assertEqual(before, after)
        self.assertEqual(errors, [])


if __name__ == '__main__':
    unittest.main()