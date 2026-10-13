"""Synthetic native GNATdoc fixtures and optional full-site qualification."""

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from enhance_gnatdoc_instances import (MEMBERS, VECTORS, MATRICES, ELEMENTS,
                                       PREFIX, native_instance, process, discover)
from link_gnatdoc_types import sources, CrossReferenceError
from compare_gnatdoc_warnings import WarningComparisonError


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

    def test_instance_type_signatures_link_to_own_summary(self):
        name = 'OpenCV.Core.Probe'
        declarations = [
            'function Get return Float32_Vec3.Vector;',
            'procedure Set (Value : OpenCV.Core.Float32_Vec3.Vector);',
            'function Convert return Float32_Matx3x3.Matrix;']
        (self.src / 'opencv-core-probe.ads').write_text(
            'with OpenCV.Core.Float32_Vec3;\nwith OpenCV.Core.Float32_Matx3x3;\n'
            'package ' + name + ' is\n' + '\n'.join(declarations) +
            '\nend ' + name + ';\n')
        path = self.api / 'probe.html'
        path.write_text(PREFIX + '<h1>' + name + '</h1>' + ''.join(
            f'<h4 id=probe-{i}>{d.split()[1]}</h4>'
            '<pre class=ada-code-snippet><code>' + d.rstrip(';') + '\n</code></pre>'
            for i, d in enumerate(declarations)))
        self.enhance()
        from link_gnatdoc_types import process as link_types
        link_types(self.api, self.src)
        text = path.read_text()
        for package, member in [('Float32_Vec3', 'vector'), ('Float32_Matx3x3', 'matrix')]:
            destination = self.page('OpenCV.Core.' + package).name + '#instance-members-summary'
            self.assertIn('href="' + destination + '" data-type="opencv.core.' +
                          package.lower() + '.' + member + '"', text)
        self.assertEqual(text.count('type-reference'), 3)

    def test_instance_visibility_and_case_controls(self):
        from link_gnatdoc_types import resolve, pages_and_targets, instance_targets
        self.enhance()
        source = self.src / 'opencv-core-probe.ads'
        contexts = [
            ('with OpenCV.Core.Float32_Vec3;', ''),
            ('', ''),
            ('with OpenCV.Core.Float32_Vec3;', 'Float32_Vec3 : Integer;'),
            ('with OpenCV.Core.Float32_Vec3;', 'OpenCV : Integer;'),
        ]
        for context, blocker in contexts:
            source.write_text(context + '\npackage OpenCV.Core.Probe is\n' + blocker +
                              '\nfunction Get return fLoAt32_vEc3.vEcToR;\n'
                              'end OpenCV.Core.Probe;')
            source_map = sources(self.src)
            from link_gnatdoc_types import Source
            consumer = Source(source)
            # Consumer HTML is irrelevant to resolution; destinations still
            # undergo the real complete summary qualification.
            source_map.pop(consumer.package)
            pages, targets = pages_and_targets(self.api, source_map)
            instance_targets(self.api, self.src, source_map, pages, targets)
            source_map[consumer.package] = consumer
            declaration = consumer.members['get'][0]
            for mark in ('float32_vec3.vector', 'opencv.core.float32_vec3.vector'):
                identity, _ = resolve(mark, consumer.package, declaration, source_map, targets)
                blocked = (blocker.startswith('OpenCV') and mark.startswith('opencv.')) or (
                    blocker.startswith('Float32') and not mark.startswith('opencv.'))
                self.assertEqual(identity is not None, bool(context) and not blocked)
            for mark in ('float32_vec3.matrix', 'float32_vec3.component_index',
                         'other.float32_vec3.vector', 'float32_vec3.vector.extra'):
                self.assertIsNone(resolve(mark, consumer.package, declaration, source_map, targets)[0])
        # Ancestor object names also hide the short selected package name.
        source.write_text('with OpenCV.Core.Float32_Vec3;\npackage OpenCV.Core.Probe is\n'
                          'function Get return Float32_Vec3.Vector;\nend OpenCV.Core.Probe;')
        source_map = sources(self.src)
        source_map['opencv.core'].members['float32_vec3'] = [{'start': 1}]
        declaration = source_map['opencv.core.probe'].members['get'][0]
        self.assertIsNone(resolve('float32_vec3.vector', 'opencv.core.probe', declaration,
                                  source_map, targets)[0])

    def test_linker_rejects_missing_summary_anchor_and_metadata(self):
        self.enhance()
        from link_gnatdoc_types import process as link_types
        original = self.instance.read_text()
        for mutated in (original.replace('id="instance-members-summary"', ''),
                        original.replace('id="instance-members-summary"', 'id="renamed"'),
                        native_instance(sources(self.src)['opencv.core.uint8_vec4'])):
            self.instance.write_text(mutated)
            with self.assertRaises(CrossReferenceError):
                link_types(self.api, self.src)
        self.instance.write_text(original)
        self.mutate(self.api / 'generic-instances.json', '"version": 1', '"version": 2')
        with self.assertRaises(CrossReferenceError):
            link_types(self.api, self.src)

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
            ('id="instance-members-summary"', 'id="renamed-summary"'),
            ('<h2>Instantiated Members</h2>', '<section class="generic-instance-summary"></section>'),
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

    def test_public_ancestor_shadowing_regression(self):
        self.mutate(self.src / 'opencv-core.ads', 'package OpenCV.Core is',
                    'package OpenCV.Core is\n   subtype UInt8_Value is Interfaces.Unsigned_16;')
        # Discovery alone must reject this, before HTML matching can mask the
        # resolver defect by noticing an unrelated missing native declaration.
        with self.assertRaisesRegex(CrossReferenceError, 'ancestor'):
            discover(sources(self.src))

    def test_ancestor_private_and_renamed_blockers(self):
        path = self.src / 'opencv-core.ads'
        original = path.read_text()
        mutations = [
            ('package OpenCV.Core is', 'package OpenCV.Core is\n   type uInT8_vAlUe is range 0 .. 255;'),
            ('private\n', 'private\n   subtype UInt8_Value is Interfaces.Unsigned_16;\n'),
            ('package OpenCV.Core is', 'package OpenCV.Core is\n   UInt8_Value : Integer renames Some_Value;'),
            ('private\n', 'private\n   package Hidden renames Interfaces;\n'),
            ('package OpenCV.Core is', 'package OpenCV.Core is\n   use Interfaces;'),
        ]
        for before, after in mutations:
            with self.subTest(mutation=after):
                self.assertIn(before, original)
                path.write_text(original.replace(before, after, 1))
                with self.assertRaises((CrossReferenceError, WarningComparisonError)):
                    discover(sources(self.src))
        path.write_text(original)

    def test_private_descendant_cannot_bypass_ancestor_blocker(self):
        self.mutate(self.src / 'opencv-core-uint8_vec4.ads',
                    'package OpenCV.Core.UInt8_Vec4 is', 'private package OpenCV.Core.UInt8_Vec4 is')
        self.mutate(self.src / 'opencv-core.ads', 'private\n',
                    'private\n   subtype UInt8_Value is Interfaces.Unsigned_16;\n')
        with self.assertRaisesRegex(CrossReferenceError, 'ancestor'):
            discover(sources(self.src))

    def test_every_intervening_parent_is_checked(self):
        (self.src / 'opencv-core-nested.ads').write_text(
            'package OpenCV.Core.Nested is\n'
            '   subtype UInt8_Value is Interfaces.Unsigned_16;\n'
            'end OpenCV.Core.Nested;\n')
        (self.src / 'opencv-core-nested-uint8_vec2.ads').write_text(
            'with OpenCV.Core.Vectors;\n'
            'package OpenCV.Core.Nested.UInt8_Vec2 is new OpenCV.Core.Vectors\n'
            '(Element_Type => UInt8_Value, Length => 2);\n')
        with self.assertRaisesRegex(CrossReferenceError, 'ancestor'):
            discover(sources(self.src))

    def test_existing_metadata_cannot_bless_ancestor_shadowing(self):
        self.enhance()
        self.mutate(self.src / 'opencv-core.ads', 'package OpenCV.Core is',
                    'package OpenCV.Core is\n   subtype Float32_Value is Interfaces.IEEE_Float_64;')
        with self.assertRaisesRegex(CrossReferenceError, 'ancestor'):
            self.check()

    def test_valid_actuals_case_insensitive(self):
        self.mutate(self.src / 'opencv-core-uint8_vec4.ads',
                    'Element_Type => UInt8_Value', 'element_type => uInT8_vAlUe')
        found = discover(sources(self.src))
        self.assertEqual(found['opencv.core.uint8_vec4'], (VECTORS, 'UInt8_Value', [4]))
        self.assertEqual(found['opencv.core.float32_vec3'], (VECTORS, 'Float32_Value', [3]))
        self.assertEqual(found['opencv.core.float16_vec4'], (VECTORS, 'Float16_Value', [4]))

    def test_rectangular_matrix_independent_facts_and_mutations(self):
        source = self.src / 'opencv-core-float32_matx2x4.ads'
        source.write_text('with OpenCV.Core.Fixed_Matrices;\n\n'
                          '--  Synthetic rectangular Ada matrix.\n'
                          'package OpenCV.Core.Float32_Matx2x4 is new\n'
                          'OpenCV.Core.Fixed_Matrices (Element_Type => Float32_Value,\n'
                          'Row_Count => 2, Column_Count => 4);\n')
        path = self.api / 'rectangular.html'
        # Independent pinned native fixture, not native_instance()/render().
        path.write_text(PREFIX + '<h1>OpenCV.Core.Float32_Matx2x4</h1>'
                        '<h2>Entities</h2><h2>Description</h2>'
                        '<p>Synthetic rectangular Ada matrix.')
        process(self.api, self.src, expected_count=8)
        original = path.read_text()
        template = self.page('OpenCV.Core.Fixed_Matrices').name
        root = self.page('OpenCV').name
        for expected in [
            f'href="{root}#fixture-Float32_Value">OpenCV.Float32_Value</a>',
            f'href="{template}#fixture-Row_Index">Row_Index</a></th><td>Natural range 0 .. 1',
            f'href="{template}#fixture-Column_Index">Column_Index</a></th><td>Natural range 0 .. 3',
            f'href="{template}#fixture-Matrix">Matrix</a></th><td>2 × 4 array of Float32_Value',
            '<th scope="row">Row_Count</th><td>2',
            '<th scope="row">Column_Count</th><td>4',
        ]:
            self.assertIn(expected, original)
        before = {p.name: p.read_bytes() for p in self.api.iterdir()}
        process(self.api, self.src, expected_count=8)
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.api.iterdir()})
        for before, after in [
            ('Natural range 0 .. 1', 'Natural range 0 .. 3'),
            ('Natural range 0 .. 3', 'Natural range 0 .. 1'),
            ('2 × 4 array', '4 × 2 array'),
            ('<th scope="row">Column_Count</th><td>4', '<th scope="row">Column_Count</th><td>2'),
            ('#fixture-Matrix', '#fixture-Row_Index'),
        ]:
            with self.subTest(mutation=after):
                path.write_text(original.replace(before, after, 1))
                with self.assertRaises(CrossReferenceError):
                    process(self.api, self.src, check=True, expected_count=8)
        path.write_text(original)

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
        self.assertEqual((counts['linked'], pages), (2698, 168))
        manifest = json.loads((api / 'type-crossrefs.json').read_text())
        self.assertEqual(sum(len(p['snippets']) for p in manifest['pages'].values()), 1268)
        from link_gnatdoc_types import LINK, SECTION
        from collections import Counter
        instances_linked = Counter()
        for path in api.glob('*.html'):
            for section in SECTION.finditer(path.read_text()):
                instances_linked.update(m[2] for m in LINK.finditer(section[3])
                                        if m[2].endswith(('.vector', '.matrix')))
        expected = {p + ('.vector' if v[0] == VECTORS else '.matrix'):
                    (10 if v[0] == VECTORS else 2) for p, v in instances.items()}
        self.assertEqual(dict(instances_linked), expected)

    @unittest.skipUnless((ROOT / '_site/api/generic-instances.json').exists(),
                         'full generated-site qualification runs after generation')
    def test_wrong_but_existing_instance_targets_and_missing_links(self):
        from validate_docs import validate
        from link_gnatdoc_types import pages_and_targets, LINK
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory) / 'site'
            shutil.copytree(ROOT / '_site', site)
            pages, _ = pages_and_targets(site / 'api', sources(ROOT / 'src'))
            path = pages['opencv.core.float16_vec2_access'][0]
            original = path.read_text()
            link = next(m for m in LINK.finditer(original)
                        if m[2] == 'opencv.core.float16_vec2.vector')
            for package in ('opencv.core.float32_vec2', 'opencv.core.float16_vec3'):
                wrong = pages[package][0].name + '#instance-members-summary'
                path.write_text(original.replace(link[1], wrong))
                with self.assertRaises(SystemExit):
                    validate(site)
            # Missing links are rejected, not just checked when present.
            path.write_text(LINK.sub(lambda m: m[3] if m[2].endswith('.vector') else m[0], original))
            with self.assertRaises(SystemExit):
                validate(site)

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