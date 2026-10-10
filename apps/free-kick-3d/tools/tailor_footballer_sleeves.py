"""Smooth the existing shoulder/sleeve transition without changing topology or weights."""
import bpy, importlib.util, json, math, sys, hashlib, struct
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
SOURCE = ROOT/'source-assets/footballer'
OUT = APP/'assets/footballer'
REVISION = 'football-sleeves-continuous-shoulder-2026-10-04'
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('short_helpers', APP/'tools/tailor_footballer_shorts.py')
helpers = importlib.util.module_from_spec(spec); spec.loader.exec_module(helpers)
smooth = helpers.smooth

def tailor(input_path, role='footballer'):
    if role not in ('footballer','goalkeeper'): raise ValueError('Unknown athlete role')
    bpy.ops.wm.open_mainfile(filepath=str(input_path))
    body = bpy.data.objects['FootballerBody']; mesh = body.data
    if body.get('sleeve_tailoring_revision'):
        raise RuntimeError('Sleeves already adjusted; use a fresh base or the pre-pass backup')
    rig = bpy.data.objects['FootballerRig']
    shirt_faces = [p for p in mesh.polygons if mesh.materials[p.material_index].name == 'Jersey']
    shirt = {i for p in shirt_faces for i in p.vertices}
    original = {i:mesh.vertices[i].co.copy() for i in shirt}
    masks = {}
    for i,co in original.items():
        bone = rig.data.bones['UpperArm.R' if co.x>0 else 'UpperArm.L']
        axis = (bone.tail_local-bone.head_local).normalized()
        along = (co-bone.head_local).dot(axis)
        # Follow the arm axis instead of a horizontal height cut, which would
        # leave a hard corner on top of the cap and pinch the sleeve opening.
        weight = smooth(.120,.195,abs(co.x))
        weight *= 1-smooth(.060,.135,along)
        if weight>0: masks[i] = weight
    movable = set(masks)
    before = helpers.locked_state(body, movable, set())
    neighbours = {i:set() for i in movable}
    edge_use = {}
    for p in shirt_faces:
        for a,b in p.edge_keys:
            edge_use[a,b] = edge_use.get((a,b),0)+1
            if a in neighbours: neighbours[a].add(b)
            if b in neighbours: neighbours[b].add(a)
    boundary = {i for edge,count in edge_use.items() if count == 1 for i in edge}
    # Alternate smoothing and expansion (Taubin) to avoid shrinking the cap.
    # Local proportional influence keeps collar and sleeve openings pinned.
    # This is one connected shirt, so no weld or separate sleeve object is needed.
    for iteration in range(16):
        updates = {}
        for i,weight in masks.items():
            if i in boundary or not neighbours[i]: continue
            center = sum((mesh.vertices[j].co for j in neighbours[i]),Vector())/len(neighbours[i])
            coefficient = .50 if iteration % 2 == 0 else -.53
            target = mesh.vertices[i].co.lerp(center,coefficient*weight)
            displacement = target-original[i]
            if displacement.length>.010:
                target = original[i]+displacement.normalized()*.010
            updates[i] = target
        for i,co in updates.items(): mesh.vertices[i].co = co
    mesh.calc_loop_triangles()
    triangles = [tuple(t.vertices) for t in mesh.loop_triangles
        if mesh.materials[mesh.polygons[t.polygon_index].material_index].name == 'Skin']
    skin = BVHTree.FromPolygons([v.co.copy() for v in mesh.vertices],triangles,all_triangles=True)
    for i in movable:
        if i in boundary or original[i].z<1.47: continue
        co = mesh.vertices[i].co
        hit,normal,index,distance = skin.find_nearest(co)
        if hit is not None and distance<.025 and (co-hit).dot(normal)<.003:
            # Keep the already fitted original where smoothing would lose
            # clearance; projecting to a nearby cut skin edge can inflate it.
            co[:] = original[i]
    mesh.update()
    assert before == helpers.locked_state(body,movable,set()), 'Protected data changed'
    assert not mesh.validate(verbose=True,clean_customdata=False), 'Unexpected mesh repair'
    body['sleeve_tailoring_revision'] = REVISION
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/f'{role}_v3.blend'))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [rig,body,bpy.data.objects['Beard']]: obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{role}_v3.glb'),export_format='GLB',
        export_vertex_color='ACTIVE',export_all_vertex_colors=False,use_selection=True,
        export_animations=True,export_animation_mode='NLA_TRACKS',export_apply=False,
        export_yup=True,export_skins=True,export_all_influences=False)
    raw = (OUT/f'{role}_v3.glb').read_bytes()
    size = struct.unpack_from('<I',raw,12)[0]; glb = json.loads(raw[20:20+size])
    path = SOURCE/'athlete_v3_manifest.json'; data = json.loads(path.read_text())
    for item in data['exports']:
        if item['path'].endswith(f'/{role}_v3.glb'):
            item.update(sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),
                triangles=sum(glb['accessors'][p['indices']]['count']//3 for m in glb['meshes'] for p in m['primitives']),
                surfaces=sum(len(m['primitives']) for m in glb['meshes']),embedded_images=len(glb['images']),
                bones=len(glb['skins'][0]['joints']),animations=sorted(a['name'] for a in glb['animations']))
    data['sleeves_revision'] = REVISION
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    report = {key+'_unchanged':True for key in before}
    report.update(role=role,affected_vertices=len(movable),max_displacement_m=max((mesh.vertices[i].co-original[i]).length for i in movable),
        boundary_vertices_pinned=len(boundary & movable),bones=len(rig.data.bones),animations=sorted(a['name'] for a in glb['animations']))
    directory = ROOT/'docs/research/sleeves-quality-2026-10-04'; directory.mkdir(parents=True,exist_ok=True)
    (directory/('auditoria.json' if role=='footballer' else 'goalkeeper-auditoria.json')).write_text(json.dumps(report,indent=2)+'\n')
    print('SLEEVES_TAILORED',json.dumps(report),flush=True)

if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    input_path = Path(args[0]) if args else SOURCE/'footballer_v3.blend'
    role = args[1] if len(args)>1 else ('goalkeeper' if input_path.name.startswith('goalkeeper') else 'footballer')
    tailor(input_path, role)
