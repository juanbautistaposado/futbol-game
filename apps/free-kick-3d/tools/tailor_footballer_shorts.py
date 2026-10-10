"""Lower the player's shorts on the existing mesh without changing its rig.

Run on the current jersey-tailored source, once per base regeneration.
Only Shorts positions and their hem-relative UV2 coordinates are changed.
"""
import bpy, hashlib, json, math, struct, sys
from pathlib import Path

APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
SOURCE = ROOT / 'source-assets/footballer'
OUT = APP / 'assets/footballer'
REVISION = 'football-shorts-low-crotch-2026-10-04'
HEM = .695

def smooth(a, b, x):
    t = max(0., min(1., (x-a)/(b-a)))
    return t*t*(3-2*t)

def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()

def locked_state(body, short_vertices, short_loops):
    mesh = body.data
    rig = bpy.data.objects['FootballerRig']
    curves = []
    for action in bpy.data.actions:
        for layer in action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    for curve in bag.fcurves:
                        curves.append([action.name, curve.data_path, curve.array_index,
                            [[list(k.co), list(k.handle_left), list(k.handle_right), k.interpolation]
                             for k in curve.keyframe_points]])
    return {
        'other_geometry': digest([[o.name, [[v.index, list(v.co)] for v in o.data.vertices
            if o != body or v.index not in short_vertices]] for o in bpy.data.objects if o.type == 'MESH']),
        'topology': digest([[list(p.vertices), p.material_index] for p in mesh.polygons]),
        'weights': digest([[[g.group, g.weight] for g in v.groups] for v in mesh.vertices]),
        'bones': digest([[b.name, b.parent.name if b.parent else None,
            [list(row) for row in b.matrix_local]] for b in rig.data.bones]),
        'animation_curves': digest(curves),
        'palette': digest([[m.name, list(m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value)]
            for m in mesh.materials if m.node_tree.nodes.get('Principled BSDF')]),
        'uv0': digest([list(v.uv) for v in mesh.uv_layers['UVMap'].data]),
        'protected_uv2': digest([[i, list(v.uv)] for i,v in enumerate(mesh.uv_layers['JerseyPrintUV'].data)
            if i not in short_loops]),
    }

def tailor(input_path, role='footballer'):
    if role not in ('footballer','goalkeeper'): raise ValueError('Unknown athlete role')
    bpy.ops.wm.open_mainfile(filepath=str(input_path))
    body = bpy.data.objects['FootballerBody']; mesh = body.data
    if body.get('short_tailoring_revision'):
        raise RuntimeError('Shorts already tailored; use a fresh base or the pre-pass backup')
    faces = [p for p in mesh.polygons if mesh.materials[p.material_index].name == 'Shorts']
    vertices = {i for p in faces for i in p.vertices}
    loops = {i for p in faces for i in p.loop_indices}
    before = locked_state(body, vertices, loops)
    old_positions = {i:mesh.vertices[i].co.copy() for i in vertices}
    for i in vertices:
        old = old_positions[i]; co = mesh.vertices[i].co
        # Lengthen below the pelvis, keeping the shared waistband fixed.
        co.z -= .020 * (1-smooth(.79, 1.0, old.z))
        # Lower the crotch bridge, blending out before the flat leg openings.
        crotch = (1-smooth(.020, .065, abs(old.x)))
        crotch *= smooth(.715, .745, old.z) * (1-smooth(.79, .90, old.z))
        co.z -= .018*crotch
        # A small amount of ease keeps the lower outer side from tapering inward.
        side = smooth(.15, .20, abs(old.x))*(1-smooth(.80, .94, old.z))
        co.x += math.copysign(.002*side, old.x)
    for li in loops:
        co = mesh.vertices[mesh.loops[li].vertex_index].co
        mesh.uv_layers['JerseyPrintUV'].data[li].uv.y = co.z-HEM
    mesh.update()
    assert before == locked_state(body, vertices, loops), 'Protected source data changed'
    assert not mesh.validate(verbose=True, clean_customdata=False), 'Unexpected mesh repair'
    body['short_tailoring_revision'] = REVISION
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/f'{role}_v3.blend'))
    rig = bpy.data.objects['FootballerRig']
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [rig, body, bpy.data.objects['Beard']]: obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{role}_v3.glb'), export_format='GLB',
        export_vertex_color='ACTIVE', export_all_vertex_colors=False, use_selection=True,
        export_animations=True, export_animation_mode='NLA_TRACKS', export_apply=False,
        export_yup=True, export_skins=True, export_all_influences=False)
    raw = (OUT/f'{role}_v3.glb').read_bytes()
    size = struct.unpack_from('<I',raw,12)[0]; glb = json.loads(raw[20:20+size])
    path = SOURCE/'athlete_v3_manifest.json'; data = json.loads(path.read_text())
    for item in data['exports']:
        if item['path'].endswith(f'/{role}_v3.glb'):
            item.update(sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw),
                triangles=sum(glb['accessors'][p['indices']]['count']//3 for m in glb['meshes'] for p in m['primitives']),
                surfaces=sum(len(m['primitives']) for m in glb['meshes']), embedded_images=len(glb['images']),
                bones=len(glb['skins'][0]['joints']), animations=sorted(a['name'] for a in glb['animations']))
    data['shorts_revision'] = REVISION
    data['art_target'].update(short_hem_z_m=HEM, crotch_z_m=.720)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')
    report = {key+'_unchanged': True for key in before}
    report.update(role=role,short_vertices=len(vertices), max_displacement_m=max((mesh.vertices[i].co-old_positions[i]).length for i in vertices),
        hem_z_m=min(mesh.vertices[i].co.z for i in vertices), bones=len(rig.data.bones),
        animations=sorted(a['name'] for a in glb['animations']), revision=REVISION)
    directory = ROOT/'docs/research/short-quality-2026-10-04'; directory.mkdir(parents=True, exist_ok=True)
    (directory/('auditoria.json' if role=='footballer' else 'goalkeeper-auditoria.json')).write_text(json.dumps(report, indent=2)+'\n')
    print('SHORTS_TAILORED', json.dumps(report), flush=True)

if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    input_path = Path(args[0]) if args else SOURCE/'footballer_v3.blend'
    role = args[1] if len(args)>1 else ('goalkeeper' if input_path.name.startswith('goalkeeper') else 'footballer')
    tailor(input_path, role)
