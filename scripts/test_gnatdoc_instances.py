"""Synthetic native GNATdoc fixtures and optional full-site qualification."""

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from enhance_gnatdoc_instances import (MEMBERS, VECTORS, MATRICES, ELEMENTS,
                                       PREFIX, native_instance, process)
from link_gnatdoc_types import sources, CrossReferenceError


ROOT = Path(__file__).resolve().parent.parent


class InstanceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.src = self.root / 'src'
        self.api = self.root / 'api'
        self.src.mkdir()
        self.api.mkdir()
        names = ['opencv', 'opencv.core', VECTORS, MATRICES,
                 'opencv.core.float32_matx3x3_conversions',
                 'opencv.core.uint8_vec2', 'opencv.core.uint8_vec3',
                 'opencv.core.uint8_vec4', 'opencv.core.float16_vec4',
                 'opencv.core.float32_vec3', 'opencv.core.float64_vec2',
                 'opencv.core.float32_matx3x3']
        for name in names:
            file = name.replace('.', '-') + '.ads'
            shutil.copyfile(ROOT / 'src' / file, self.src / file)
        source_map = sources(self.src)
        # Realistic pinned serialization; filenames and anchors deliberately
        # differ from production hashes to establish identity-based discovery.
        for i, (name, source) in enumerate(source_map.items()):
            if source.instance:
                text = native_instance(source)
            else:
                from enhance_gnatdoc_instances import title
                text = PREFIX + '<h1>' + title(source) + '</h1><h2>Entities</h2><h2>Description</h2><p>Template introduction.'
                declarations = MEMBERS.get(name, {})
                declarations = dict(declarations)
                declarations.update({element: declaration for element, (owner, declaration)
                                     in ELEMENTS.items() if owner == name})
                for member, declaration in declarations.items():
                    text += (f'<h4 id=fixture-{member}>{member}</h4>'
                             f'<pre class=ada-code-snippet><code>{declaration}\n</code></pre><p>Member documentation.')
            (self.api / f'fixture-{i}.html').write_text(text)
        self.instance = self.page('OpenCV.Core.UInt8_Vec4')

    def page(self, name):
        return next(p for p in self.api.glob('*.html') if '<h1>' + name + '</h1>' in p.read_text())

    def enhance(self):
        return process(self.api, self.src, expected_count=7)

    def check(self):
        return process(self.api, self.src, check=True, expected_count=7)

    def mutate(self, path, before, after):
        text = path.read_text()
        self.assertIn(before, text)
        path.write_text(text.replace(before, after, 1))

    def test_positive_members_links_semantics_and_idempotence(self):
        instances, links = self.enhance()
        self.assertEqual(len(instances), 7)
        self.assertEqual(links, 30)
        for name, (_, element, dimensions) in instances.items():
            page = next(p for p in self.api.glob('*.html')
                        if '<h1>' + name + '</h1>' in p.read_text().lower())
            text = page.read_text()
            self.assertIn('ordinary Ada array', text)
            self.assertIn('Ada value semantics', text)
            self.assertIn(element, text)
            self.assertIn(f'Natural range 0 .. {dimensions[0] - 1}', text)
            self.assertIn('generic template declarations', text)
        vector = self.instance.read_text()
        self.assertIn('href="' + self.page('OpenCV.Core.Vectors').name + '"', vector)
        self.assertIn('#fixture-Vector', vector)
        self.assertIn('#fixture-Component_Index', vector)
        self.assertIn('#fixture-UInt8_Value', vector)
        self.assertIn('exact IEEE-754 binary16 encodings', self.page('OpenCV.Core.Float16_Vec4').read_text())
        self.assertIn('does not imply shared native storage', self.page('OpenCV.Core.Float32_Matx3x3').read_text())
        before = {p.name: p.read_bytes() for p in self.api.iterdir()}
        self.enhance()
        self.check()
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.api.iterdir()})
        # Rebuild from identical native/source inputs, not the previous metadata.
        for entry in json.loads((self.api / 'generic-instances.json').read_text())['pages'].values():
            (self.api / entry['file']).write_text(entry['original'])
        (self.api / 'generic-instances.json').unlink()
        self.enhance()
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.api.iterdir()})

    def test_summary_mutations_fail(self):
        self.enhance()
        pristine = self.instance.read_text()
        mutations = [
            ('Array of 4', 'Array of 3'),
            ('Natural range 0 .. 3', 'Natural range 0 .. 2'),
            ('4 UInt8_Value', '4 Float32_Value'),
            ('#fixture-Vector', '#fixture-Component_Index'),
            ('ordinary Ada array', 'native shared array'),
            ('<section class="generic-instance-summary">', '<section class="generic-instance-summary"><section class="generic-instance-summary"></section>'),
            ('One complete CV_8UC4', 'One incomplete CV_8UC4'),
            ('<h2>Description</h2>', '<h4 id=unapproved>Vector</h4><h2>Description</h2>'),
            ('href="', 'href="missing.html#'),
        ]
        for before, after in mutations:
            with self.subTest(mutation=before):
                self.instance.write_text(pristine)
                self.mutate(self.instance, before, after)
                with self.assertRaises(CrossReferenceError):
                    self.check()

    def test_wrong_existing_matrix_destination_fails(self):
        self.enhance()
        self.mutate(self.instance, self.page('OpenCV.Core.Vectors').name + '#fixture-Vector',
                    self.page('OpenCV.Core.Fixed_Matrices').name + '#fixture-Matrix')
        with self.assertRaises(CrossReferenceError):
            self.check()

    def test_tampered_metadata_even_with_native_tampering_fails(self):
        self.enhance()
        metadata = self.api / 'generic-instances.json'
        self.mutate(metadata, 'One complete CV_8UC4', 'One incomplete CV_8UC4')
        self.mutate(self.instance, 'One complete CV_8UC4', 'One incomplete CV_8UC4')
        with self.assertRaises(CrossReferenceError):
            self.check()

    def test_missing_template_page(self):
        self.page('OpenCV.Core.Vectors').unlink()
        with self.assertRaises(CrossReferenceError):
            self.enhance()

    def test_missing_member_anchor(self):
        self.mutate(self.page('OpenCV.Core.Vectors'), '<h4 id=fixture-Vector>', '<h4>')
        with self.assertRaises(CrossReferenceError):
            self.enhance()

    def test_source_mutations_fail_closed(self):
        file = self.src / 'opencv-core-uint8_vec4.ads'
        pristine = file.read_text()
        mutations = [('Length => 4', '4'), ('Length => 4', 'Length => 0'),
                     ('Length => 4', 'Length => 3, Length => 4'),
                     ('UInt8_Value', 'Unknown_Value'),
                     ('UInt8_Value', 'OpenCV.UInt8_Value'),
                     ('OpenCV.Core.Vectors', 'OpenCV.Core.Unknown')]
        for before, after in mutations:
            with self.subTest(mutation=after):
                file.write_text(pristine.replace(before, after))
                with self.assertRaises(CrossReferenceError):
                    self.enhance()
                self.assertFalse((self.api / 'generic-instances.json').exists())
        file.write_text(pristine)

    def test_inconsistent_template_fails(self):
        self.mutate(self.src / 'opencv-core-vectors.ads', 'Length - 1;', 'Length - 2;')
        with self.assertRaises(CrossReferenceError):
            self.enhance()

    def test_ambiguous_actual_visibility(self):
        self.mutate(self.src / 'opencv-core-uint8_vec4.ads',
                    'with OpenCV.Core.Vectors;',
                    'with OpenCV.Core.Vectors; use OpenCV.Core.Vectors;')
        with self.assertRaises(CrossReferenceError):
            self.enhance()

    def test_metadata_only_tampering(self):
        self.enhance()
        self.mutate(self.api / 'generic-instances.json', '"version": 1', '"version": 2')
        with self.assertRaises(CrossReferenceError):
            self.check()

    def test_unsupported_insertion_point(self):
        self.mutate(self.instance, '<h2>Description</h2>', '<h2>Changed</h2>')
        with self.assertRaises(CrossReferenceError):
            self.enhance()


class GeneratedSiteTests(unittest.TestCase):
    @unittest.skipUnless((ROOT / '_site/api/generic-instances.json').exists(),
                         'full generated-site qualification runs after generation')
    def test_full_site_all_depths_and_exact_baseline(self):
        api = ROOT / '_site/api'
        before = {p.name: p.read_bytes() for p in api.iterdir() if p.is_file()}
        instances, links = process(api, ROOT / 'src', check=True, expected_count=25)
        self.assertEqual(links, 102)
        self.assertEqual({i[1] for i in instances.values()}, set(ELEMENTS))
        process(api, ROOT / 'src', expected_count=25)
        self.assertEqual(before, {p.name: p.read_bytes() for p in api.iterdir() if p.is_file()})
        from link_gnatdoc_types import process as check_types
        counts, pages = check_types(api, ROOT / 'src', check=True)
        self.assertEqual((counts['linked'], pages), (2456, 168))
        manifest = json.loads((api / 'type-crossrefs.json').read_text())
        self.assertEqual(sum(len(p['snippets']) for p in manifest['pages'].values()), 1268)

    @unittest.skipUnless((ROOT / '_site/api/generic-instances.json').exists(),
                         'full generated-site qualification runs after generation')
    def test_final_validator_rejects_valid_html_wrong_facts_and_targets(self):
        from validate_docs import validate
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory) / 'site'
            shutil.copytree(ROOT / '_site', site)
            manifest = json.loads((site / 'api/generic-instances.json').read_text())
            path = site / 'api' / manifest['pages']['opencv.core.uint8_vec4']['file']
            original = path.read_text()
            source_map = sources(ROOT / 'src')
            from link_gnatdoc_types import pages_and_targets
            _, targets = pages_and_targets(site / 'api', source_map)
            vector = '#'.join(targets[VECTORS + '.vector'])
            matrix = '#'.join(targets[MATRICES + '.matrix'])
            for before, after in [('Array of 4', 'Array of 3'), (vector, matrix)]:
                with self.subTest(mutation=after):
                    self.assertIn(before, original)
                    path.write_text(original.replace(before, after))
                    with self.assertRaises(SystemExit):
                        validate(site)


if __name__ == '__main__':
    unittest.main()