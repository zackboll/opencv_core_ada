"""Negative-first qualification of authoritative guide reconstruction."""
import shutil
import tempfile
import unittest
from pathlib import Path

import render_gnatdoc_guides as guides

ROOT = Path(__file__).resolve().parent.parent


class Guides(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.site = Path(self.tmp.name) / "site"
        shutil.copytree(ROOT / "_site", self.site)
        # Validate actual toolkit output before any legacy renderer can repair it.
        guides.validate(ROOT, self.site)
        self.page = self.site / "guides/ownership-and-views.html"

    def mutation(self, old, new):
        text = self.page.read_text()
        self.assertIn(old, text)
        self.page.write_text(text.replace(old, new, 1))
        with self.assertRaises(ValueError):
            guides.validate(ROOT, self.site)

    def test_missing(self):
        self.page.unlink()
        with self.assertRaises(ValueError):
            guides.validate(ROOT, self.site)

    def test_duplicate(self):
        shutil.copy(self.page, self.page.with_name("duplicate.html"))
        with self.assertRaises(ValueError):
            guides.validate(ROOT, self.site)

    def test_wrong_existing_guide(self):
        self.mutation('typed-access-guide.html#typed-access-matrix',
                      'core-operations-guide.html#public-api-overview')

    def test_wrong_fragment(self):
        self.mutation('#view-examples', '#contents')

    def test_wrong_existing_api(self):
        packages = guides.packages(ROOT, self.site)
        self.mutation('../api/' + packages['OpenCV.Core'],
                      '../api/' + packages['OpenCV.Core.Sparse'])

    def test_missing_source(self):
        self.mutation('blob/main/docs/ownership-and-views.md', 'blob/main/README.md')

    def test_code_mutation(self):
        self.mutation('<span class="ada-number">640</span>',
                      '<span class="ada-number">641</span>')

    def test_script(self):
        self.mutation('</main>', '<script>alert(1)</script></main>')

    def test_event(self):
        self.mutation('<main', '<main onclick="alert(1)"')

    def test_duplicate_heading(self):
        self.mutation('id="view-examples"', 'id="contents"')

    def test_css(self):
        (self.site / 'guides/gnatdoc-guides.css').write_text('body{}')
        with self.assertRaises(ValueError):
            guides.validate(ROOT, self.site)

    def test_table_tampering(self):
        self.page = self.site / 'guides/typed-access-guide.html'
        self.mutation('<table>', '<div>')

    def test_manifest_cannot_authorize_content(self):
        (self.site / 'guides/manifest.json').write_text('{"approved":true}')
        self.mutation('640', '641')

    def test_repeat(self):
        before = {p.name: p.read_bytes() for p in (self.site / 'guides').iterdir()}
        guides.generate(ROOT, self.site)
        self.assertEqual(before, {p.name: p.read_bytes() for p in
                                 (self.site / 'guides').iterdir()})

    def test_renderer_code_tables_and_angles(self):
        text = '# Test\n\n```ada\n   type T is private; -- <T>\n```\n\n| A | B |\n| --- | --- |\n| **bold** | `Vec<T>` |\n'
        rendered, headings = guides.markdown(text)
        self.assertIn('   type T is private; -- &lt;T&gt;\n', rendered)
        self.assertIn('<table>', rendered)
        self.assertIn('<strong>bold</strong>', rendered)
        self.assertIn('Vec&lt;T&gt;', rendered)
        self.assertEqual(headings, ['test'])

    def test_reject_raw_html(self):
        for source in ['# Test\n<script>alert(1)</script>',
                       '# Test\n<span onclick="x()">bad</span>']:
            with self.subTest(source=source), self.assertRaises(ValueError):
                guides.markdown(source)

    def test_reject_malformed_fence(self):
        with self.assertRaises(ValueError):
            guides.markdown('# Test\n```ada\nunclosed')

    def test_duplicate_heading_source_has_unique_ids(self):
        rendered, ids = guides.markdown('# Test\n## Same\n## Same\n')
        self.assertEqual(ids, ['test', 'same', 'same-1'])
        self.assertIn('id="same-1"', rendered)

    def test_reject_invalid_links(self):
        headings = guides.heading_inventory(ROOT)
        for link in ['../../outside.md', '../missing.md', 'javascript:alert(1)',
                     'http://example.com', 'data:text/html,bad',
                     '../tests/probes/../../README.md',
                     'typed-access-guide.md#not-a-heading']:
            with self.subTest(link=link), self.assertRaises(ValueError):
                guides.resolve_link(ROOT, 'ownership-and-views', link, headings)

    def test_final_site_validator_rejects_mutations(self):
        from validate_docs import validate
        text = self.page.read_text()
        packages = guides.packages(ROOT, self.site)
        mutations = [
            text.replace('typed-access-guide.html#typed-access-matrix',
                         'core-operations-guide.html#public-api-overview', 1),
            text.replace('../api/' + packages['OpenCV.Core'],
                         '../api/' + packages['OpenCV.Core.Sparse'], 1),
            text.replace('</main>', '<script>alert(1)</script></main>'),
        ]
        for content in mutations:
            with self.subTest(content=content[-100:]):
                self.page.write_text(content)
                with self.assertRaises(SystemExit) as caught:
                    validate(self.site)
                self.assertIn('guide integrity:', str(caught.exception))
        self.page.write_text(text)

    def test_source_fences_preserved(self):
        from markdown_it import MarkdownIt
        from html.parser import HTMLParser

        class Code(HTMLParser):
            def __init__(self, content):
                super().__init__(convert_charrefs=True)
                self.blocks, self.inside = [], False
                self.feed(content)

            def handle_starttag(self, tag, attrs):
                if tag == 'code' and any(k == 'class' and v.startswith('language-')
                                         for k, v in attrs):
                    self.inside = True
                    self.blocks.append('')

            def handle_endtag(self, tag):
                if tag == 'code':
                    self.inside = False

            def handle_data(self, text):
                if self.inside:
                    self.blocks[-1] += text

        for name in guides.GUIDES:
            source = (ROOT / f'docs/{name}.md').read_text()
            blocks = [t.content for t in MarkdownIt().parse(source) if t.type == 'fence']
            actual = Code((self.site / f'guides/{name}.html').read_text()).blocks
            self.assertEqual(blocks, actual, name)


if __name__ == '__main__':
    unittest.main()