"""Check runtime character exports: rig, clips, UVs and normalized skinning."""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'apps/free-kick-3d/assets/footballer'
REPORT = ROOT / 'docs/research/player-realism-2026-10-14'
helper = Path(__file__).with_name('audit_meshy_export.py')
namespace = {'__file__': str(helper)}
exec(helper.read_text().split('exports = []')[0], namespace)
GLB = namespace['GLB']


def boot_normals(model):
    result = {}
    for primitive in model.data['meshes'][0]['primitives']:
        attrs = primitive['attributes']
        rows = [model.values(attrs[key]) for key in ('POSITION', 'TEXCOORD_0', 'NORMAL')]
        for position, uv, normal in zip(*rows):
            if position[1] < .20:
                result[tuple(round(v, 5) for v in position + uv)] = normal
    return result


def audit(role):
    new = GLB(ASSETS / f'meshy_{role}.glb')
    baseline = GLB(ASSETS / ('meshy_player.glb' if role == 'striker' else 'goalkeeper_v4.glb'))
    assert new.rig() == baseline.rig(), 'Bind pose or skeleton changed'
    assert new.clips() == baseline.clips(), 'Animation channels changed'
    assert len(new.rig()) == 53
    # Open scan components must retain their authored winding. A global
    # "recalculate outside" can flip whole limbs even with valid weights.
    old_normals = boot_normals(GLB(ASSETS / 'meshy_player.glb'))
    new_normals = boot_normals(new)
    common = old_normals.keys() & new_normals.keys()
    reversed_normals = sum(sum(a * b for a, b in zip(old_normals[k], new_normals[k])) < -.5 for k in common)
    assert len(common) > 1000 and reversed_normals / len(common) < .005, 'Surface winding inverted'
    triangles = 0
    materials = {}
    maximum_weight_error = 0.
    for mesh in new.data['meshes']:
        for primitive in mesh['primitives']:
            attrs = primitive['attributes']
            assert all(name in attrs for name in ('POSITION', 'NORMAL', 'TEXCOORD_0', 'TEXCOORD_1', 'JOINTS_0', 'WEIGHTS_0'))
            name = new.data['materials'][primitive['material']]['name']
            count = new.data['accessors'][primitive['indices']]['count'] // 3
            materials[name] = materials.get(name, 0) + count
            triangles += count
            positions = new.values(attrs['POSITION'])
            assert all(math.isfinite(v) for p in positions for v in p)
            assert all(0 <= j < 53 for row in new.values(attrs['JOINTS_0']) for j in row)
            weights = new.values(attrs['WEIGHTS_0'])
            assert all(w >= 0 for row in weights for w in row)
            maximum_weight_error = max(maximum_weight_error, max(abs(sum(row) - 1) for row in weights))
            if name in ('HairGroom', 'BeardGroom', 'BrowGroom', 'EyeSurface'):
                assert min(p[1] for p in positions) > 1.62, 'Facial geometry escaped the head'
                assert all(uv == (-2., 3.) for uv in new.values(attrs['TEXCOORD_1'])), 'Details must never receive the jersey print'
    expected = {'MeshyPlayer', 'Jersey', 'TailoredShorts', 'CollarKnit', 'EyeSurface', 'HairGroom', 'BeardGroom', 'BrowGroom'}
    if role == 'keeper':
        expected.add('GoalkeeperGloves')
    assert set(materials) == expected
    assert 180000 < triangles < 260000
    assert maximum_weight_error < 1e-5
    report_path = REPORT / f'{role}.json'
    report = json.loads(report_path.read_text())
    assert report['sha256'] == hashlib.sha256(new.raw).hexdigest()
    report['export_audit'] = {'rig_and_clips_exact': True, 'bones': len(new.rig()),
                            'clips': sorted(new.clips()), 'triangles': triangles,
                            'materials': materials, 'maximum_weight_error': maximum_weight_error,
                            'winding_reference_vertices': len(common), 'reversed_reference_normals': reversed_normals,
                            'bytes': len(new.raw)}
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(role, json.dumps(report['export_audit']))


if __name__ == '__main__':
    for role in ('striker', 'keeper'):
        audit(role)
