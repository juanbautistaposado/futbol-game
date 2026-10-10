"""Validate the exported kit against v3's rig and clips; write its manifest."""
import hashlib
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'apps/free-kick-3d/assets/footballer'
SOURCE = ROOT / 'source-assets/footballer'
REPORT = ROOT / 'docs/research/meshy-trial-2026-10-06'


class GLB:
    def __init__(self, path):
        self.path = path
        self.raw = path.read_bytes()
        length = struct.unpack_from('<I', self.raw, 12)[0]
        self.data = json.loads(self.raw[20:20 + length])
        self.buffer = self.raw[28 + length:]

    def values(self, index):
        accessor = self.data['accessors'][index]
        view = self.data['bufferViews'][accessor['bufferView']]
        code = {5120: 'b', 5121: 'B', 5122: 'h', 5123: 'H', 5125: 'I', 5126: 'f'}[accessor['componentType']]
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[accessor['type']]
        fmt = '<' + code * width
        stride = view.get('byteStride', struct.calcsize(fmt))
        start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        return [struct.unpack_from(fmt, self.buffer, start + i * stride) for i in range(accessor['count'])]

    def rig(self):
        skin = self.data['skins'][0]
        matrices = self.values(skin['inverseBindMatrices'])
        return {self.data['nodes'][node]['name']: matrix for node, matrix in zip(skin['joints'], matrices)}

    def clips(self):
        clips = {}
        for animation in self.data['animations']:
            channels = {}
            for channel in animation['channels']:
                sampler = animation['samplers'][channel['sampler']]
                node = self.data['nodes'][channel['target']['node']]['name']
                key = node + '/' + channel['target']['path']
                channels[key] = [sampler.get('interpolation', 'LINEAR'), self.values(sampler['input']), self.values(sampler['output'])]
            clips[animation['name']] = channels
        return clips

    def protected_surfaces(self):
        surfaces = {}
        for mesh in self.data['meshes']:
            for primitive in mesh['primitives']:
                name = self.data['materials'][primitive['material']]['name']
                if name in ['Jersey', 'Shorts']:
                    continue
                surfaces[name] = {key: self.values(index) for key, index in primitive['attributes'].items() if key in ['POSITION', 'JOINTS_0', 'WEIGHTS_0', 'TEXCOORD_0', 'TEXCOORD_1', 'COLOR_0']}
        return surfaces


exports = []
for role in ['footballer', 'goalkeeper']:
    old = GLB(ASSETS / f'{role}_v3.glb')
    new = GLB(ASSETS / f'{role}_v4.glb')
    assert old.rig() == new.rig(), f'{role}: inverse bind matrices changed'
    assert old.clips() == new.clips(), f'{role}: animations changed during export'
    assert old.protected_surfaces() == new.protected_surfaces(), f'{role}: protected exported surface data changed'
    triangles = vertices = 0
    maximum_weight_error = 0
    for mesh in new.data['meshes']:
        for primitive in mesh['primitives']:
            triangles += new.data['accessors'][primitive['indices']]['count'] // 3
            positions = new.values(primitive['attributes']['POSITION'])
            vertices += len(positions)
            assert all(math.isfinite(v) for p in positions for v in p)
            weights = new.values(primitive['attributes']['WEIGHTS_0'])
            joints = new.values(primitive['attributes']['JOINTS_0'])
            maximum_weight_error = max(maximum_weight_error, max(abs(sum(w) - 1) for w in weights))
            assert all(0 <= j < 53 for values in joints for j in values)
    assert maximum_weight_error < 1e-5, f'{role}: unnormalized export weights'
    protected = json.loads((REPORT / f'integration-{role}.json').read_text())
    assert protected['before'] == protected['after']
    exports.append({
        'path': str(new.path.relative_to(ROOT)),
        'sha256': hashlib.sha256(new.raw).hexdigest(), 'bytes': len(new.raw),
        'triangles': triangles, 'exported_vertices': vertices,
        'bones': len(new.rig()), 'animations': sorted(new.clips()),
        'original_rig_and_clips_exact': True, 'protected_body_weights_uv_exact': True,
        'maximum_weight_sum_error': maximum_weight_error,
        'source_blend': f'source-assets/footballer/{role}_v4.blend',
        'source_sha256': hashlib.sha256((SOURCE / f'{role}_v4.blend').read_bytes()).hexdigest(),
    })
manifest = {
    'version': 4, 'date': '2026-10-06', 'revision': 'meshy-retopologized-kit',
    'builder': 'apps/free-kick-3d/tools/integrate_meshy_kit.py',
    'base': 'athlete_v3_manifest.json', 'height_m': 1.898873,
    'scope': 'Meshy cloth shape and texture adaptation; original anatomy, clean garment topology, weights, UV0/UV2, rig and clips retained',
    'license': {'body': 'CC0-1.0', 'meshy_clothing_derivative': 'CC-BY-4.0', 'attribution': 'Meshy AI (Meshy 6 Lite); adapted by this project', 'visible_credits': 'Configurar → Créditos'},
    'provenance': 'meshy-trial-2026-10-06/manifest.json', 'exports': exports,
}
(SOURCE / 'athlete_v4_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps(manifest, indent=2))
