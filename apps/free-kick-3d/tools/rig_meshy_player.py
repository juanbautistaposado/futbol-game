"""Bind the complete Meshy candidate to the game's unchanged 53-bone rig.

The Meshy face, hair, body, boots, UV0 and PBR atlas remain the new character.
Rest-pose limbs align to the existing skeleton; hands have a mild finger curl
and Idle/Kick contain authored football arm rotations.
blender -b --python apps/free-kick-3d/tools/rig_meshy_player.py
"""
import bpy
import bmesh
import hashlib
import json
import sys
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
sys.path.insert(0, str(Path(__file__).resolve().parent))
from pose_striker_arms import author_striker_arms, relax_hand, preserve_unedited_clip_channels

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'source-assets/footballer'
RAW = SOURCE / 'meshy-trial-2026-10-06/meshy-lite-raw.glb'
TARGET = ROOT / 'apps/free-kick-3d/assets/footballer/meshy_player.glb'
REPORT = ROOT / 'docs/research/meshy-trial-2026-10-06/full-player-rig.json'


def smooth(a, b, value):
    t = max(0., min(1., (value - a) / (b - a)))
    return t * t * (3 - 2 * t)


def blend_weights(point, tree, triangles, coords, weights):
    hit, normal, index, distance = tree.find_nearest(point)
    indices = triangles[index]
    a, b, c = [coords[i] for i in indices]
    v0, v1, v2 = b - a, c - a, hit - a
    d00, d01, d11 = v0.dot(v0), v0.dot(v1), v1.dot(v1)
    d20, d21 = v2.dot(v0), v2.dot(v1)
    denominator = d00 * d11 - d01 * d01
    if abs(denominator) < 1e-15:
        factors = [1., 0., 0.]
    else:
        u = (d11 * d20 - d01 * d21) / denominator
        v = (d00 * d21 - d01 * d20) / denominator
        factors = [max(0., 1 - u - v), max(0., u), max(0., v)]
    result = {}
    for index, factor in zip(indices, factors):
        for name, weight in weights[index].items():
            result[name] = result.get(name, 0.) + factor * weight
    selected = sorted(result.items(), key=lambda item: item[1], reverse=True)[:4]
    total = sum(weight for _, weight in selected)
    assert total > 0
    return {name: weight / total for name, weight in selected if weight > 1e-7}


bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'footballer_v3.blend'))
rig = bpy.data.objects['FootballerRig']
old_body = bpy.data.objects['FootballerBody']
coords = [v.co.copy() for v in old_body.data.vertices]
weights = [{old_body.vertex_groups[g.group].name: g.weight for g in v.groups if old_body.vertex_groups[g.group].name in rig.data.bones} for v in old_body.data.vertices]
old_body.data.calc_loop_triangles()
triangles = [tuple(t.vertices) for t in old_body.data.loop_triangles]
tree = BVHTree.FromPolygons(coords, triangles, all_triangles=True)
old_objects = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(RAW))
body = next(o for o in bpy.data.objects if o not in old_objects and o.type == 'MESH')
bpy.context.view_layer.objects.active = body
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
minimum = min(v.co.z for v in body.data.vertices)
height = max(v.co.z for v in body.data.vertices) - minimum
for vertex in body.data.vertices:
    vertex.co.z -= minimum
    vertex.co *= 1.898873 / height
original_coords = [v.co.copy() for v in body.data.vertices]
rest_positions = body.data.attributes.new('MeshyRestPosition', 'FLOAT_VECTOR', 'POINT')
for entry, point in zip(rest_positions.data, original_coords):
    entry.vector = point


def segment_map(point, start, end, bone, scale_length=True):
    source_axis = end - start
    target_axis = bone.tail_local - bone.head_local
    rotation = source_axis.rotation_difference(target_axis)
    factor = target_axis.length / source_axis.length if scale_length else 1.
    return bone.head_local + (rotation @ (point - start)) * factor


assignments = []
for vertex, original in zip(body.data.vertices, original_coords):
    point = relax_hand(original, smooth)
    sign = 1 if point.x > 0 else -1
    side = 'R' if sign > 0 else 'L'
    shoulder = Vector((sign * .198, .025, 1.520))
    elbow = Vector((sign * .305, .058, 1.225))
    wrist = Vector((sign * .398, .025, .995))
    # The Meshy arms are lower and less spread. Rotate upper arm and forearm
    # independently; blend at the elbow and at the cloth-to-shoulder transition.
    # Move the entire arm circumference; partial rotations across the forearm
    # would stretch its inner triangles into a broad membrane. Classify by
    # geometry, including dark nail/knuckle texels and every UV seam duplicate.
    arm = smooth(.17, .245, abs(point.x)) * smooth(1.24, 1.34, point.z)
    if point.z > .65:
        arm = max(arm, smooth(.26, .28, abs(point.x)) * (1 - smooth(1.13, 1.20, point.z)))
        inner_arm = max(.195, .245 - max(0., point.z - 1.10) * .32)
        arm = max(arm, smooth(inner_arm, inner_arm + .01, abs(point.x)) * smooth(1.05, 1.10, point.z) * (1 - smooth(1.32, 1.42, point.z)))
    if arm > 0:
        upper = segment_map(point, shoulder, elbow, rig.data.bones['UpperArm.' + side])
        forearm = segment_map(point, elbow, wrist, rig.data.bones['Forearm.' + side])
        upper_fraction = smooth(1.18, 1.29, point.z)
        point = point.lerp(forearm.lerp(upper, upper_fraction), arm)
    # Keep the athlete's leg volumes; align their modest backward lean to the
    # existing thigh/shin chain, including the boot position used for contact.
    leg = (1 - smooth(.94, 1.035, original.z)) * smooth(.025, .075, abs(original.x))
    if leg > 0 and arm < .1:
        hip = Vector((sign * .116, .025, 1.025))
        knee = Vector((sign * .160, .060, .545))
        ankle = Vector((sign * .208, .050, .080))
        thigh = segment_map(original, hip, knee, rig.data.bones['Thigh.' + side])
        shin = segment_map(original, knee, ankle, rig.data.bones['Shin.' + side])
        mapped = shin.lerp(thigh, smooth(.48, .61, original.z))
        point = point.lerp(mapped, leg)
    vertex.co = point
    if original.z > 1.69:
        assignment = {'Head': 1.}
    elif original.z < .11:
        assignment = {'Foot.' + side: 1.}
    else:
        assignment = blend_weights(point, tree, triangles, coords, weights)
        if arm > 0:
            hand = 1 - smooth(.99, 1.055, original.z)
            upper = smooth(1.18, 1.29, original.z)
            chain = {'Hand.' + side: hand, 'Forearm.' + side: (1 - hand) * (1 - upper), 'UpperArm.' + side: (1 - hand) * upper}
            mixed = {name: weight * (1 - arm) for name, weight in assignment.items()}
            for name, weight in chain.items():
                mixed[name] = mixed.get(name, 0.) + weight * arm
            selected = sorted(mixed.items(), key=lambda item: item[1], reverse=True)[:4]
            total = sum(weight for _, weight in selected)
            assignment = {name: weight / total for name, weight in selected if weight > 1e-7}
    assignments.append(assignment)

for bone in rig.data.bones:
    body.vertex_groups.new(name=bone.name)
for index, assignment in enumerate(assignments):
    for name, weight in assignment.items():
        body.vertex_groups[name].add([index], weight, 'REPLACE')
assert max(abs(sum(a.values()) - 1) for a in assignments) < 1e-5

# Weld only coincident positions; keep the generated UVs on face corners.
bm = bmesh.new()
bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1e-6)
bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
bm.to_mesh(body.data)
bm.free()
body.data.normals_split_custom_set([(0., 0., 0.)] * len(body.data.loops))
for polygon in body.data.polygons:
    polygon.use_smooth = True
body.data.uv_layers[0].name = 'UVMap'
print_uv = body.data.uv_layers.new(name='JerseyPrintUV')
for polygon in body.data.polygons:
    center = sum((body.data.vertices[i].co for i in polygon.vertices), Vector()) / len(polygon.vertices)
    printable = center.y > .035 and polygon.normal.y > .35 and abs(center.x) < .19 and 1.045 < center.z < 1.51
    for loop in polygon.loop_indices:
        point = body.data.vertices[body.data.loops[loop].vertex_index].co
        print_uv.data[loop].uv = (.5 - point.x / .42, (point.z - 1.045) / .465) if printable else (-2, -2)
body.data.uv_layers['UVMap'].active_render = True
body.data.materials[0].name = 'MeshyPlayer'
body.data.materials[0].diffuse_color = (1., 1., 1., 1.)
body.parent = rig
modifier = body.modifiers.new('Footballer skinning', 'ARMATURE')
modifier.object = rig
for obj in [old_body, bpy.data.objects.get('Beard')]:
    if obj is not None:
        bpy.data.objects.remove(obj, do_unlink=True)
body.name = 'FootballerBody'
assert not body.data.validate(verbose=True, clean_customdata=False)
body['asset_revision'] = 'football-arm-gesture-2026-10-08'
body['license'] = 'CC-BY-4.0; generated with Meshy AI, rig adaptation by this project'
arm_animation_changes = author_striker_arms(rig)
bpy.context.preferences.filepaths.save_version = 0
# Pack the original Meshy atlas so the editable source is portable.
for material in body.data.materials:
    for node in material.node_tree.nodes:
        if node.type == 'TEX_IMAGE' and node.image:
            node.image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / 'meshy_player.blend'))
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(TARGET), export_format='GLB', use_selection=True,
    export_animations=True, export_animation_mode='NLA_TRACKS', export_apply=False,
    export_yup=True, export_skins=True, export_all_influences=False)
preserved_channels = preserve_unedited_clip_channels(TARGET.with_name('footballer_v3.glb'), TARGET)
report = {
    'source': str(RAW.relative_to(ROOT)), 'source_sha256': hashlib.sha256(RAW.read_bytes()).hexdigest(),
    'runtime': str(TARGET.relative_to(ROOT)), 'runtime_sha256': hashlib.sha256(TARGET.read_bytes()).hexdigest(),
    'source_blend': 'source-assets/footballer/meshy_player.blend',
    'scope': 'Complete Meshy geometry and original PBR maps; relaxed finger rest shape and football arm rotation tracks in Idle/Kick',
    'vertices': len(body.data.vertices), 'polygons': len(body.data.polygons), 'bones': len(rig.data.bones),
    'maximum_weight_sum_error': max(abs(sum(a.values()) - 1) for a in assignments),
    'license': 'CC-BY-4.0', 'author': 'Meshy AI', 'rig_changes': False,
    'arm_animation_changes': arm_animation_changes,
    'revision': 'football-arm-gesture-2026-10-08',
    'original_channels_preserved_exact': preserved_channels,
}
REPORT.write_text(json.dumps(report, indent=2) + '\n')
print('MESHY_FULL_PLAYER', json.dumps(report), flush=True)
