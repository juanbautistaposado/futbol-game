"""Reuse PLAYER geometry/weights with goalkeeper clips, jersey and gloves.

blender -b --python apps/free-kick-3d/tools/build_meshy_keeper.py
"""
import bpy
import hashlib
import json
import sys
from pathlib import Path
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pose_striker_arms import preserve_unedited_clip_channels

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'source-assets/footballer'
ASSETS = ROOT / 'apps/free-kick-3d/assets/footballer'
TARGET = ASSETS / 'meshy_keeper.glb'
REPORT = ROOT / 'docs/research/meshy-keeper-2026-10-09'
REPORT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'meshy_player.blend'))
rig = bpy.data.objects['FootballerRig']
body = bpy.data.objects['FootballerBody']
mesh = body.data
original = mesh.materials[0]
for name in ['Jersey', 'GoalkeeperGloves']:
    existing = bpy.data.materials.get(name)
    if existing is not None:
        existing.name = 'Legacy' + name
jersey = original.copy()
jersey.name = 'Jersey'
mesh.materials.append(jersey)
gloves = bpy.data.materials.new('GoalkeeperGloves')
gloves.use_nodes = True
bsdf = gloves.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value = (.72, .76, .68, 1)
bsdf.inputs['Roughness'].default_value = .75
mesh.materials.append(gloves)
for mat in [original, jersey]:
    bsdf = mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Roughness'].default_value = .7
    for node in mat.node_tree.nodes:
        if node.type == 'NORMAL_MAP':
            node.inputs['Strength'].default_value = .45

# Original coordinates distinguish the hand, sleeve and torso even after the
# A-pose was aligned to the existing skeleton. UV0 remains the original atlas.
rest = mesh.attributes['MeshyRestPosition']
image = next(n.image for n in original.node_tree.nodes
             if n.type == 'TEX_IMAGE' and 'base' in n.label.lower()) if any(
                 n.type == 'TEX_IMAGE' and 'base' in n.label.lower()
                 for n in original.node_tree.nodes) else None
if image is None:
    bsdf = original.node_tree.nodes.get('Principled BSDF')
    image = bsdf.inputs['Base Color'].links[0].from_node.image
pixels = list(image.pixels)
width, height = image.size
uv = mesh.uv_layers['UVMap']
counts = {'jersey': 0, 'gloves': 0, 'base': 0}
for polygon in mesh.polygons:
    point = sum((rest.data[i].vector for i in polygon.vertices), Vector()) / len(polygon.vertices)
    if abs(point.x) > .35 and .75 < point.z < .995:
        polygon.material_index = 2
        counts['gloves'] += 1
    elif 1.025 < point.z < 1.615:
        # Cloth is neutral white; skin is warm, and the navy collar stays navy.
        colors = []
        for loop in polygon.loop_indices:
            coord = uv.data[loop].uv
            x, y = int(coord.x * width) % width, int(coord.y * height) % height
            colors.append(pixels[(y * width + x) * 4:(y * width + x) * 4 + 3])
        rgb = [sum(c[i] for c in colors) / len(colors) for i in range(3)]
        white = max(rgb) > .28 and (max(rgb) - min(rgb)) / max(rgb) < .24
        polygon.material_index = 1 if white else 0
        counts['jersey' if white else 'base'] += 1
    else:
        counts['base'] += 1

# Slightly thicken the existing hand surface into a glove. No extra skin or
# attachment: the same hand weights keep the glove and catch position together.
for vertex, entry in zip(mesh.vertices, rest.data):
    if abs(entry.vector.x) > .35 and .75 < entry.vector.z < .995:
        fade = min(1., max(0., (.995 - entry.vector.z) / .025))
        vertex.co += vertex.normal * (.0035 * fade)
mesh.update()
body['asset_revision'] = 'meshy-goalkeeper-2026-10-09'

# Restore the goalkeeper's own readiness/at-save gestures in the editable file.
with bpy.data.libraries.load(str(SOURCE / 'goalkeeper_v4.blend'), link=False) as (src, dst):
    dst.actions = [name for name in src.actions if name.split('.')[0].split('_')[0] in
                   ['Idle', 'Kick', 'Celebrate', 'Catch', 'SaveLeft', 'SaveRight', 'SaveLowLeft', 'SaveLowRight']]
actions = {action.name.split('.')[0].split('_')[0]: action for action in dst.actions}
for track in rig.animation_data.nla_tracks:
    for strip in track.strips:
        name = track.name
        strip.action = actions[name]
rig.animation_data.action = actions['Idle']
bpy.context.scene.frame_set(1)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'meshy_keeper.blend'))
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(TARGET), export_format='GLB', use_selection=True,
    export_animations=True, export_animation_mode='NLA_TRACKS', export_apply=False,
    export_yup=True, export_skins=True, export_all_influences=False)
copied = preserve_unedited_clip_channels(ASSETS / 'goalkeeper_v4.glb', TARGET, keep_authored_arms=False)
report = {'date': '2026-10-09', 'runtime': str(TARGET.relative_to(ROOT)),
    'source_blend': 'source-assets/footballer/meshy_keeper.blend',
    'base': 'source-assets/footballer/meshy_player.blend', 'bones': len(rig.data.bones),
    'vertices': len(mesh.vertices), 'polygons': len(mesh.polygons), 'material_polygons': counts,
    'goalkeeper_channels_preserved': copied, 'license': 'CC-BY-4.0', 'author': 'Meshy AI',
    'extra_meshy_credits': 0, 'runtime_sha256': hashlib.sha256(TARGET.read_bytes()).hexdigest()}
(REPORT / 'integration.json').write_text(json.dumps(report, indent=2) + '\n')
print('MESHY_KEEPER', json.dumps(report), flush=True)
