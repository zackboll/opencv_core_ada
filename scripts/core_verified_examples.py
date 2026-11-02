"""Core-owned immutable compiler-map selection; no compiler imports at publication."""
import hashlib
import json

from link_gnatdoc_types import require, sources, pages_and_targets, words, plain
from highlight_gnatdoc_ada import strip_highlighting

CONFIGURATION = 'config/opencv_core_config.gpr'
PUBLIC = 'public'
MAPPINGS = {
    'f405597289217976be3fd42d4b84da66179ebc412dad0f0a8c450861ee42a442': (
        'docs/verified-examples/debian.json',
        '2eeeb283aa0a54113dbeb423653549f13f6238f587c282ab391b9debfc6ba61a'),
    'bed2db88e56f69de7bd437319d8b1ed4086afe24629e423f9afd1fb113b8442b': (
        'docs/verified-examples/ubuntu.json',
        '7ef2b7d4da95909a382661dc2a501556c416241a15f12070fe9b27e81ff23f2e'),
}
# Reviewed coordinates, never selected by name/order or a URL in metadata.
CALLS = ((1130, 5, 28, 87, 93, 'Create'),
         (1242, 6, 34, 168, 173, 'Clone'),
         (3661, 8, 24, 204, 208, 'Rows'),
         (3669, 8, 47, 227, 234, 'Columns'))


def digest(payload):
    return hashlib.sha256(payload).hexdigest()


def regular(root, name):
    root = root.resolve()
    path = root / name
    require(path.resolve().is_relative_to(root) and path.is_file() and
            not any(p.is_symlink() for p in (path, *path.parents)), 'unsafe compiler input: ' + name)
    return path


def selected_mapping(root):
    key = digest(regular(root, CONFIGURATION).read_bytes())
    require(key in MAPPINGS, 'unqualified compiler configuration SHA-256: ' + key)
    name, pin = MAPPINGS[key]
    payload = regular(root, name).read_bytes()
    require(digest(payload) == pin, 'unreviewed compiler mapping')
    data = json.loads(payload)
    require(data['inputs'][CONFIGURATION] == key, 'incorrect mapping selection')
    for name, expected in data['inputs'].items():
        require(digest(regular(root, name).read_bytes()) == expected, 'stale/missing compiler input: ' + name)
    return MAPPINGS[key], data


def staged_config(root):
    """The only platform variation is the reviewed mapping path and exact pin."""
    (name, pin), _ = selected_mapping(root)
    text = (root / 'docs/gnatdoc-enhancer.toml').read_text()
    default_name, default_pin = next(iter(MAPPINGS.values()))
    require(text.count(default_name) == text.count(default_pin) == 1, 'unreviewed mapping configuration')
    return text.replace(default_name, name).replace(default_pin, pin).encode()


def compiler_destinations(root, site):
    """Reconstruct exact declarations and native profiles independently of enhancer."""
    _, mapping = selected_mapping(root)
    require(len(mapping['mappings']) == 4, 'incomplete compiler call inventory')
    source = sources(root / 'src')
    pages, _ = pages_and_targets(site / 'api', source)
    path, _, sections = pages['opencv.core']
    example = regular(root, 'docs/example.adb').read_text()
    spec = regular(root, 'src/opencv-core.ads')
    lines = spec.read_text().splitlines()
    results = []
    for record, (line, call_line, column, start, end, token) in zip(mapping['mappings'], CALLS):
        expected = {'file': 'src/opencv-core.ads', 'line': line, 'column': 13,
                    'sha256': digest(spec.read_bytes())}
        require(record['selected'] == {**expected, 'kind': 'SubpDecl'} and
                record['compiler_selected'] == expected, 'compiler declaration substitution')
        require(record['occurrence'] == {'line': call_line, 'column': column, 'start': start,
                                        'end': end, 'text': token} and example[start:end] == token,
                'modified compiler call coordinates')
        require(record['source'] == {'file': 'docs/example.adb', 'sha256': digest(example.encode())},
                'stale compiler example')
        candidates = []
        for section in sections:
            raw = plain(strip_highlighting(section[3]))
            declaration = source['opencv.core'].match(raw)
            if declaration['start'] == line:
                require(declaration['name'] == token and lines[line - 1][12:12 + len(token)] == token,
                        'canonical defining token changed')
                complete = '\n'.join(lines[declaration['start'] - 1:declaration['end']]).strip()
                require(words(complete) == words(record['profile']), 'complete compiler profile changed')
                require(record['identity'] == declaration['scope'].lower(), 'canonical identity changed')
                candidates.append((section, raw))
        require(len(candidates) == 1, 'nonunique source/native compiler destination')
        section, raw = candidates[0]
        results.append({'start': start, 'end': end, 'text': token, 'profile': raw,
                        'href': path.name + '#' + section[1], 'line': line})
    return results