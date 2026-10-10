"""Ensure recolorable PLAYER has exactly the same geometry, weights and clips."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
helper = Path(__file__).with_name('audit_meshy_export.py')
namespace = {'__file__': str(helper)}
exec(helper.read_text().split('exports = []')[0], namespace)
GLB = namespace['GLB']
assets = ROOT / 'apps/free-kick-3d/assets/footballer'
old = GLB(assets / 'meshy_player.glb')
new = GLB(assets / 'meshy_striker.glb')
assert old.rig() == new.rig(), 'Rig changed'
assert old.clips() == new.clips(), 'PLAYER arm animations changed'

def vertices(model):
    result = set()
    triangles = 0
    for mesh in model.data['meshes']:
        for primitive in mesh['primitives']:
            attrs = primitive['attributes']
            values = [model.values(attrs[name]) for name in
                ['POSITION', 'NORMAL', 'TEXCOORD_0', 'TEXCOORD_1', 'JOINTS_0', 'WEIGHTS_0']]
            result.update(zip(*values))
            triangles += model.data['accessors'][primitive['indices']]['count'] // 3
    return result, triangles

assert vertices(old) == vertices(new), 'Body geometry/normals/UVs/weights changed'
assert {m['name'] for m in new.data['materials']} == {'MeshyPlayer', 'Jersey'}
path = ROOT / 'docs/research/shared-player-2026-10-09/integration.json'
report = json.loads(path.read_text())
assert report['runtime_sha256'] == hashlib.sha256(new.raw).hexdigest()
report['source_blend_sha256'] = hashlib.sha256((ROOT / report['source_blend']).read_bytes()).hexdigest()
report['export_audit'] = {'body_geometry_uv_weights_exact': True, 'rig_exact': True,
    'all_player_clips_exact': True, 'triangles': vertices(new)[1], 'bytes': len(new.raw)}
path.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report['export_audit'], indent=2))
