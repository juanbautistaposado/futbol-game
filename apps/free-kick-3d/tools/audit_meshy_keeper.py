"""Verify same PLAYER base, unchanged goalkeeper rig/clips, valid weights."""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
cloth_report = ROOT / 'docs/research/cloth-quality-2026-10-11/keeper.json'
if cloth_report.exists() and json.loads(cloth_report.read_text())['runtime_sha256'] == hashlib.sha256((ROOT / 'apps/free-kick-3d/assets/footballer/meshy_keeper.glb').read_bytes()).hexdigest():
    from audit_player_cloth import audit
    audit('keeper')
    raise SystemExit(0)
helper = Path(__file__).with_name('audit_meshy_export.py')
namespace = {'__file__': str(helper)}
exec(helper.read_text().split('exports = []')[0], namespace)
GLB = namespace['GLB']
assets = ROOT / 'apps/free-kick-3d/assets/footballer'
old = GLB(assets / 'goalkeeper_v4.glb')
player = GLB(assets / 'meshy_player.glb')
new = GLB(assets / 'meshy_keeper.glb')
assert old.rig() == player.rig() == new.rig(), 'Rig/bind matrices changed'
assert old.clips() == new.clips(), 'Goalkeeper clips changed'
assert len(new.data['meshes']) == 1
primitives = new.data['meshes'][0]['primitives']
assert {new.data['materials'][p['material']]['name'] for p in primitives} == {
    'MeshyPlayer', 'Jersey', 'GoalkeeperGloves'}
triangles = sum(new.data['accessors'][p['indices']]['count'] // 3 for p in primitives)
assert triangles == player.data['accessors'][player.data['meshes'][0]['primitives'][0]['indices']]['count'] // 3
maximum_error = 0
for primitive in primitives:
    attrs = primitive['attributes']
    assert 'TEXCOORD_0' in attrs and 'TEXCOORD_1' in attrs
    assert all(math.isfinite(v) for p in new.values(attrs['POSITION']) for v in p)
    assert all(0 <= j < 53 for row in new.values(attrs['JOINTS_0']) for j in row)
    maximum_error = max(maximum_error, max(abs(sum(row) - 1) for row in new.values(attrs['WEIGHTS_0'])))
assert maximum_error < 1e-5
report_path = ROOT / 'docs/research/meshy-keeper-2026-10-09/integration.json'
report = json.loads(report_path.read_text())
assert report['runtime_sha256'] == hashlib.sha256(new.raw).hexdigest()
report['source_blend_sha256'] = hashlib.sha256((ROOT / report['source_blend']).read_bytes()).hexdigest()
report['export_audit'] = {'rig_exact': True, 'goalkeeper_clips_exact': True,
    'animations': sorted(new.clips()), 'triangles': triangles,
    'maximum_weight_sum_error': maximum_error, 'bytes': len(new.raw)}
report_path.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report['export_audit'], indent=2))
