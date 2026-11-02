#!/usr/bin/env python3
"""Create browser expectations from pristine native output and original sources."""
import json
from pathlib import Path

from link_gnatdoc_types import sources, pages_and_targets
from enhance_gnatdoc_instances import discover, VECTORS, title
from verify_core_enhancer import validate_native
from render_gnatdoc_guides import expected, GUIDES
from verify_core_examples import landing_example
from core_verified_examples import compiler_destinations
from html.parser import HTMLParser

ROOT = Path(__file__).resolve().parent.parent
native = ROOT / 'obj/docs/native'
validate_native(native)
source = sources(ROOT / 'src')
pages, targets = pages_and_targets(native / 'api', source)
symbols = []
for identity, (filename, anchor) in sorted(targets.items()):
    owner, _, simple = identity.rpartition('.')
    declarations = [d for d in source[owner].declarations if d['scope'].lower() == identity]
    symbols.append({'name': title(source[owner]) + '.' + declarations[0]['name'],
                    'page': filename, 'anchor': anchor})
instances = discover(source)
data = {
    'packages': [{'name': title(source[key]), 'page': value[0].name}
                 for key, value in sorted(pages.items())],
    'symbols': symbols,
    'declarations': [{'package': title(source[key]), 'page': value[0].name,
                       'anchor': section[1], 'name': section[2]}
                      for key, value in sorted(pages.items()) for section in value[2]
                      if section[2] in ('Native_Version_String', 'Native_Build_Information', 'Create')
                      and key == 'opencv.core'],
    'instances': [{'name': title(source[key]), 'page': pages[key][0].name,
                   'member': 'Vector' if item[0] == VECTORS else 'Matrix',
                   'template': '#'.join(targets[item[0] + ('.vector' if item[0] == VECTORS else '.matrix')])}
                  for key, item in sorted(instances.items())],
    'size_references': [{'page': pages['opencv.core'][0].name, 'anchor': section[1],
                         'destination': '#'.join(targets['opencv.size'])}
                        for section in pages['opencv.core'][2]
                        if section[2] in ('Create', 'Dimensions', 'Region_Location')
                        and 'Size' in section[3]],
}
assert len(data['size_references']) == 3
(ROOT / 'obj/docs/browser-oracle.json').write_text(json.dumps(data, indent=2) + '\n')
print(f'Independent browser oracle: {len(pages)} packages; {len(symbols)} symbols; {len(instances)} summaries')


class Examples(HTMLParser):
    def __init__(self, page):
        super().__init__(convert_charrefs=True)
        self.blocks, self.active, self.link = [], False, None
        self.feed(page)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'pre' and attrs.get('class') == 'ada-example':
            self.active = True
            self.blocks.append({'text': '', 'links': [], 'tokens': {}})
        if not self.active:
            return
        if tag == 'a':
            self.link = {'href': attrs['href'], 'text': ''}
            self.blocks[-1]['links'].append(self.link)
        if tag == 'span' and attrs.get('class', '').removeprefix('ada-') in (
                'keyword', 'number', 'string', 'character', 'attribute', 'comment', 'operator'):
            tokens = self.blocks[-1]['tokens']
            kind = attrs['class'].removeprefix('ada-')
            tokens[kind] = tokens.get(kind, 0) + 1

    def handle_endtag(self, tag):
        if tag == 'pre':
            self.active = False
        if tag == 'a':
            self.link = None

    def handle_data(self, text):
        if self.active:
            self.blocks[-1]['text'] += text
            if self.link is not None:
                self.link['text'] += text


guide_pages = expected(ROOT, native)
example_pages = {'index.html': landing_example(ROOT, native).decode(),
                 **{f'guides/{slug}.html': guide_pages[slug + '.html'].decode() for slug in GUIDES}}
examples = {name: Examples(page).blocks for name, page in example_pages.items()}
(ROOT / 'obj/docs/browser-compiler-oracle.json').write_text(
    json.dumps(compiler_destinations(ROOT, native), indent=2) + '\n')
(ROOT / 'obj/docs/browser-examples-oracle.json').write_text(json.dumps(examples, indent=2) + '\n')
print(f'Independent examples oracle: {sum(map(len, examples.values()))} Ada blocks; '
      f'{sum(len(b["links"]) for bs in examples.values() for b in bs)} verified links')