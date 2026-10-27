#!/usr/bin/env python3
"""Create browser expectations from pristine native output and original sources."""
import json
from pathlib import Path

from link_gnatdoc_types import sources, pages_and_targets
from enhance_gnatdoc_instances import discover, VECTORS, title
from verify_core_enhancer import validate_native

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