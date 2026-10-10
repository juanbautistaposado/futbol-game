"""Same PLAYER geometry/animations with jersey colors for every identity."""
import bpy
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from split_meshy_jersey import split_jersey
from pose_striker_arms import preserve_unedited_clip_channels

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'source-assets/footballer'
ASSETS = ROOT / 'apps/free-kick-3d/assets/footballer'
TARGET = ASSETS / 'meshy_striker.glb'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'meshy_player.blend'))
rig = bpy.data.objects['FootballerRig']
body = bpy.data.objects['FootballerBody']
jersey_polygons = split_jersey(body)
body['asset_revision'] = 'shared-meshy-striker-2026-10-09'
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'meshy_striker.blend'))
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(TARGET), export_format='GLB', use_selection=True,
    export_animations=True, export_animation_mode='NLA_TRACKS', export_apply=False,
    export_yup=True, export_skins=True, export_all_influences=False)
copied = preserve_unedited_clip_channels(ASSETS / 'meshy_player.glb', TARGET, keep_authored_arms=False)
report = {'date': '2026-10-09', 'runtime': str(TARGET.relative_to(ROOT)),
    'source_blend': 'source-assets/footballer/meshy_striker.blend',
    'base': 'source-assets/footballer/meshy_player.blend', 'bones': len(rig.data.bones),
    'jersey_polygons': jersey_polygons, 'animation_channels_preserved': copied,
    'license': 'CC-BY-4.0', 'author': 'Meshy AI', 'extra_meshy_credits': 0,
    'runtime_sha256': hashlib.sha256(TARGET.read_bytes()).hexdigest()}
directory = ROOT / 'docs/research/shared-player-2026-10-09'
directory.mkdir(parents=True, exist_ok=True)
(directory / 'integration.json').write_text(json.dumps(report, indent=2) + '\n')
print('MESHY_SHARED_STRIKER', json.dumps(report), flush=True)
