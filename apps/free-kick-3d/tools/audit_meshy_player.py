"""Audit the complete selectable PLAYER without rewriting the v4 kit manifest."""
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
helper = Path(__file__).with_name('audit_meshy_export.py')
namespace = {'__file__': str(helper)}
exec(helper.read_text().split('exports = []')[0], namespace)
GLB = namespace['GLB']
assets = ROOT / 'apps/free-kick-3d/assets/footballer'
old = GLB(assets / 'footballer_v3.glb')
new = GLB(assets / 'meshy_player.glb')
assert old.rig() == new.rig(), 'Original inverse bind matrices must remain exact'
old_clips, new_clips = old.clips(), new.clips()
assert old_clips.keys() == new_clips.keys()
authored_bones = {kind + '.' + side for side in ['R', 'L'] for kind in ['UpperArm', 'Forearm', 'Hand']}
changed_channels = {}
for clip, channels in old_clips.items():
    assert channels.keys() == new_clips[clip].keys()
    changed_channels[clip] = []
    for key, values in channels.items():
        bone, channel = key.split('/')
        if clip in ['Idle', 'Kick'] and bone in authored_bones and channel == 'rotation':
            assert values != new_clips[clip][key], f'{clip}/{key}: arm gesture must change'
            changed_channels[clip].append(key)
        else:
            assert values == new_clips[clip][key], f'{clip}/{key}: non-arm channel changed'
assert len(new.data['meshes']) == 1
assert len(new.data['meshes'][0]['primitives']) == 1
primitive = new.data['meshes'][0]['primitives'][0]
attributes = primitive['attributes']
assert 'TEXCOORD_0' in attributes and 'TEXCOORD_1' in attributes
positions = new.values(attributes['POSITION'])
weights = new.values(attributes['WEIGHTS_0'])
joints = new.values(attributes['JOINTS_0'])
assert all(math.isfinite(v) for p in positions for v in p)
assert all(0 <= j < 53 for row in joints for j in row)
maximum_error = max(abs(sum(row) - 1) for row in weights)
assert maximum_error < 1e-5
report_path = ROOT / 'docs/research/meshy-trial-2026-10-06/full-player-rig.json'
report = json.loads(report_path.read_text())
assert report['runtime_sha256'] == hashlib.sha256(new.raw).hexdigest()
assert report['source_sha256'] == hashlib.sha256((ROOT / report['source']).read_bytes()).hexdigest()
report['source_blend_sha256'] = hashlib.sha256((ROOT / report['source_blend']).read_bytes()).hexdigest()
report['export_audit'] = {
    'original_rig_exact': True,
    'original_non_arm_channels_exact': True,
    'changed_channels': changed_channels,
    'exported_vertices': len(positions),
    'triangles': new.data['accessors'][primitive['indices']]['count'] // 3,
    'animations': sorted(new.clips()),
    'maximum_weight_sum_error': maximum_error,
    'uv0_and_print_uv2_present': True,
    'bytes': len(new.raw),
}
report_path.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report['export_audit'], indent=2))
