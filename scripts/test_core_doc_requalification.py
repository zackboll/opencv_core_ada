"""CORE-DOC-VER-001R1 successor boundary: frozen history and fail-closed deltas."""
import copy
import json
import shutil
import tempfile
import unittest
from pathlib import Path

import core_doc_requalification as rq
from core_verified_examples import MAPPINGS, PREDECESSORS, successor_of_predecessor, digest
from link_gnatdoc_types import CrossReferenceError

ROOT = Path(__file__).resolve().parent.parent
FROZEN = {  # CORE-DOC-EXAMPLES-002R1 evidence must remain byte-identical.
    'docs/enhancer-qualification/gnatdoc-generic-qualification.json':
        '146a6f6375be14788996e04585ac141bfc308c5be87b040198f5d74c5c74bcfc',
    'docs/enhancer-qualification/gnatdoc-authored.json':
        '97a3351cbe0f852d5aeddea64fcffab9f66fdf56499b717caab82d06e9f67b65',
    'docs/enhancer-qualification/search-publication-inventory.json':
        '100af3824ee113bf1e58e166501d3fba2141bdb4386540cf1d768f2df3812851',
    'docs/enhancer-qualification/examples-publication-inventory.json':
        '2d2a628b00534d30bfc7eb6b5568cad8584a5ff7846cfbd3081b68e70a5f318e',
    'docs/enhancer-qualification/search-reconciliation.json':
        'a89090f9e2315ef15826659777ffa4bbd0877e0cd29219c338c31efdad7bf4b0',
    'docs/verified-examples/public-generic-qualification.json':
        '2623a2d5746241e567434fe0db4b86ea7b87ad518311cb24e45c71bd67e329be',
    'docs/verified-examples/debian.json':
        '2eeeb283aa0a54113dbeb423653549f13f6238f587c282ab391b9debfc6ba61a',
    'docs/verified-examples/ubuntu.json':
        '7ef2b7d4da95909a382661dc2a501556c416241a15f12070fe9b27e81ff23f2e',
}


class Requalification(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for name in ('docs/enhancer-qualification', 'docs/verified-examples'):
            shutil.copytree(ROOT / name, self.root / name)

    def rewrite(self, pair, mutate):
        """Mutate a successor and re-pin it, as an attacker able to rehash would."""
        name = pair[1][0]
        data = json.loads((self.root / name).read_bytes())
        mutate(data)
        payload = (json.dumps(data, indent=2, sort_keys=True) + '\n').encode()
        (self.root / name).write_bytes(payload)
        return (pair[0], (name, digest(payload)))

    def test_historical_evidence_frozen(self):
        for name, sha in FROZEN.items():
            self.assertEqual(digest((ROOT / name).read_bytes()), sha, name)

    def test_successors_bounded_by_reviewed_delta(self):
        delta = rq.requalification()
        self.assertEqual(set(delta['sources']), {'src/opencv-core.ads', 'src/opencv-core-persistence.ads'})
        self.assertEqual(len(delta['native']), 2)
        self.assertEqual(len(delta['publication']), 4)
        generic = rq.generic()
        for name, change in delta['sources'].items():
            self.assertEqual(generic['source_sha256'][name], change['after'])
            self.assertEqual(digest((ROOT / name).read_bytes()), change['after'])
        self.assertEqual(rq.authored()['native_sha256'], generic['native_sha256'])
        public = rq.public_generic()
        self.assertEqual(public['native_sha256'], generic['native_sha256'])
        self.assertEqual(public['source_sha256'],
                         {n.replace('src/', 'public/', 1): v for n, v in generic['source_sha256'].items()})

    def test_rehashed_extra_native_change_rejected(self):
        def mutate(data):
            name = sorted(n for n in data['native_sha256'] if n not in rq.requalification()['native'])[0]
            data['native_sha256'][name] = '0' * 64
        pair = self.rewrite(rq.GENERIC, mutate)
        with self.assertRaisesRegex(CrossReferenceError, 'successor entry changed'):
            rq.successor(self.root, pair, {'source_sha256', 'native_sha256'})

    def test_rehashed_extra_source_change_rejected(self):
        pair = self.rewrite(rq.GENERIC, lambda d: d['source_sha256'].update({'src/opencv.ads': '0' * 64}))
        with self.assertRaisesRegex(CrossReferenceError, 'successor entry changed'):
            rq.successor(self.root, pair, {'source_sha256', 'native_sha256'})

    def test_rehashed_instance_change_rejected(self):
        pair = self.rewrite(rq.GENERIC, lambda d: d['instances'].popitem())
        with self.assertRaisesRegex(CrossReferenceError, 'outside boundary'):
            rq.successor(self.root, pair, {'source_sha256', 'native_sha256'})

    def test_rehashed_wrong_requalified_value_rejected(self):
        name = sorted(rq.requalification()['native'])[0]
        pair = self.rewrite(rq.AUTHORED, lambda d: d['native_sha256'].update({name: '1' * 64}))
        with self.assertRaisesRegex(CrossReferenceError, 'differs from reviewed delta'):
            rq.successor(self.root, pair, {'native_sha256'})

    def test_modified_frozen_predecessor_rejected(self):
        path = self.root / rq.GENERIC[0][0]
        path.write_bytes(path.read_bytes() + b'\n')
        with self.assertRaisesRegex(CrossReferenceError, 'unreviewed qualification record'):
            rq.generic(self.root)

    def test_unreviewed_requalification_record_rejected(self):
        path = self.root / rq.RECORD
        data = json.loads(path.read_bytes())
        data['publication']['api/gnatdoc.css'] = {'before': '0' * 64, 'after': '1' * 64}
        path.write_text(json.dumps(data, indent=2, sort_keys=True) + '\n')
        with self.assertRaisesRegex(CrossReferenceError, 'unreviewed qualification record'):
            rq.requalification(self.root)

    def test_publication_comparison_fails_closed(self):
        baseline = json.loads((ROOT / 'docs/enhancer-qualification/examples-publication-inventory.json').read_bytes())
        changes = rq.publication()
        current = dict(baseline, **{n: c['after'] for n, c in changes.items()})
        exempt = {'index.html', 'api/presentation.json'}
        rq.unchanged_or_requalified(baseline, current, exempt)
        other = sorted(n for n in baseline if n not in changes and n not in exempt)[0]
        for mutated, message in [
                (dict(current, **{other: '0' * 64}), 'previously qualified publication bytes changed'),
                (dict(current, **{sorted(changes)[0]: '0' * 64}), 'requalified publication bytes differ'),
                (dict(current, **{sorted(changes)[0]: baseline[sorted(changes)[0]]}),
                 'requalified publication bytes differ')]:
            with self.assertRaisesRegex(CrossReferenceError, message):
                rq.unchanged_or_requalified(baseline, mutated, exempt)
        wrong = dict(baseline, **{sorted(changes)[0]: '2' * 64})
        with self.assertRaisesRegex(CrossReferenceError, 'wrong frozen hash'):
            rq.unchanged_or_requalified(wrong, current, exempt)

    def test_prose_only_rejects_structure_and_foreign_text(self):
        source = '--  Old description.\nprocedure P;\n--  New description.\n'
        before = '<h4 id=a>P</h4><pre>procedure P;</pre><p>Old description.<h5>x</h5>'
        after = '<h4 id=a>P</h4><pre>procedure P;</pre><p>New description.<h5>x</h5>'
        self.assertEqual(rq.prose_only(before, after, source.replace('Old', 'Other'), 1), 1)
        with self.assertRaisesRegex(CrossReferenceError, 'outside comment-derived'):
            rq.prose_only(before, after.replace('id=a', 'id=b'), source, 1)
        with self.assertRaisesRegex(CrossReferenceError, 'not the edited source comment'):
            rq.prose_only(before, after.replace('New', 'Forged'), source, 1)
        with self.assertRaisesRegex(CrossReferenceError, 'delta count'):
            rq.prose_only(before, after, source.replace('Old', 'Other'), 2)

    def test_successor_maps_bounded_by_frozen_predecessors(self):
        self.assertEqual(MAPPINGS.keys(), PREDECESSORS.keys())
        for key, (name, pin) in MAPPINGS.items():
            payload = (ROOT / name).read_bytes()
            self.assertEqual(digest(payload), pin)
            data = json.loads(payload)
            successor_of_predecessor(ROOT, key, data)
            old = json.loads((ROOT / PREDECESSORS[key][0]).read_bytes())
            for left, right in zip(old['mappings'], data['mappings']):
                for field in ('identity', 'profile', 'occurrence', 'source', 'classification'):
                    self.assertEqual(left[field], right[field])
                self.assertEqual({k: v for k, v in left['selected'].items() if k != 'sha256'},
                                 {k: v for k, v in right['selected'].items() if k != 'sha256'})
            self.assertEqual(old['skipped'], data['skipped'])
            for field in ('compiler', 'ali', 'libadalang'):
                self.assertEqual(old['provenance'][field], data['provenance'][field])

    def test_successor_map_semantic_drift_rejected(self):
        key = next(iter(MAPPINGS))
        data = json.loads((ROOT / MAPPINGS[key][0]).read_bytes())
        for mutate in (lambda d: d['mappings'][1].update(profile='function Clone (Self : UMat) return UMat;'),
                       lambda d: d['mappings'][2]['selected'].update(line=3662),
                       lambda d: d['mappings'][3]['compiler_selected'].update(line=3670),
                       lambda d: d['skipped'].clear(),
                       lambda d: d['provenance'].update(libadalang='0' * 64),
                       lambda d: d['inputs'].update({'docs/example.gpr': '0' * 64}),
                       lambda d: d.update(native_sha256='0' * 64)):
            forged = copy.deepcopy(data)
            mutate(forged)
            with self.assertRaisesRegex(CrossReferenceError, 'outside the requalified'):
                successor_of_predecessor(ROOT, key, forged)
        forged = copy.deepcopy(data)
        forged['mappings'][0]['selected']['sha256'] = '0' * 64
        with self.assertRaisesRegex(CrossReferenceError, 'source identity changed'):
            successor_of_predecessor(ROOT, key, forged)


if __name__ == '__main__':
    unittest.main()
