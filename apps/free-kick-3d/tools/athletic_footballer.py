"""Athletic silhouette pass on the existing player, with exact rig/UV preservation."""
import bpy, importlib.util, json, math, sys, hashlib, struct
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
SOURCE = ROOT/'source-assets/footballer'
OUT = APP/'assets/footballer'
REVISION = 'athletic-footballer-balanced-legs-2026-10-04'
REVIEW = ROOT/'docs/research/athletic-character-2026-10-04/revision-proporciones'
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('athletic_helpers',APP/'tools/tailor_footballer_shorts.py')
helpers = importlib.util.module_from_spec(spec); spec.loader.exec_module(helpers)
smooth = helpers.smooth

def tailor(input_path, role='footballer'):
    if role not in ('footballer','goalkeeper'): raise ValueError('Unknown athlete role')
    bpy.ops.wm.open_mainfile(filepath=str(input_path))
    body = bpy.data.objects['FootballerBody']; mesh = body.data
    rig = bpy.data.objects['FootballerRig']
    if body.get('athletic_revision'):
        raise RuntimeError('Athletic pass already applied; use the previous source or regenerate')
    materials = {}
    for p in mesh.polygons:
        name = mesh.materials[p.material_index].name
        for i in p.vertices: materials.setdefault(i,set()).add(name)
    original = {v.index:v.co.copy() for v in mesh.vertices}
    frames = {}
    for name in ['UpperArm','Forearm','Thigh','Shin']:
        for side in ['L','R']:
            bone = rig.data.bones[name+'.'+side]
            axis = bone.tail_local-bone.head_local
            frames[name+'.'+side] = (bone.head_local.copy(),axis.normalized(),axis.length)
    updates = {}
    for v in mesh.vertices:
        names = materials[v.index]; co = original[v.index]
        if not names <= {'Skin','Jersey','Shorts','Socks','Trim'}: continue
        # Trim also contains boot details; only the upper sock binding is eligible.
        if 'Trim' in names and co.z<.48: continue
        if co.z<.15 or co.z>1.585: continue
        # Protect the complete neck/collar transition, including its lower front.
        if abs(co.x)<.145 and co.z>1.53: continue
        weights = {body.vertex_groups[g.group].name:g.weight for g in v.groups}
        # Hands/fingers must keep their original geometry and gameplay reach.
        if any(w>.05 and (name.startswith('Hand.') or name.startswith(('thumb_','index_','middle_','ring_','pinky_')))
               for name,w in weights.items()): continue
        delta = Vector()
        # Contain the chest instead of inflating it; build strength in the legs.
        torso = smooth(1.015,1.40,co.z)*(1-smooth(1.50,1.585,co.z))
        torso *= 1-smooth(.195,.335,abs(co.x))
        delta.x += co.x*.04*torso
        delta.y -= (co.y+.020)*.025*torso
        for name,weight in weights.items():
            if name not in frames: continue
            head,axis,length = frames[name]
            t = (co-head).dot(axis)/length
            radial = co-head-axis*(co-head).dot(axis)
            if name.startswith('UpperArm'):
                amplitude = .22*math.exp(-((t-.55)/.45)**2)
                envelope = smooth(-.20,-.03,t)*(1-smooth(.78,1.04,t))
            elif name.startswith('Forearm'):
                amplitude = .14*math.exp(-((t-.35)/.34)**2)
                envelope = smooth(.02,.16,t)*(1-smooth(.65,.96,t))
            elif name.startswith('Thigh'):
                # Put most volume in the exposed thigh; do not balloon the shorts.
                peak = .08 if names == {'Shorts'} else .30
                amplitude = peak*math.exp(-((t-.58)/.46)**2)
                envelope = smooth(-.04,.15,t)*(1-smooth(.75,1.0,t))
            else:
                amplitude = .25*math.exp(-((t-.40)/.33)**2)
                envelope = smooth(.05,.22,t)*(1-smooth(.68,.92,t))
                envelope *= smooth(.15,.23,co.z)
            change = radial*(amplitude*envelope*weight)
            # Preserve a clear shared crotch and the flat lower short hems.
            if name.startswith('Thigh') and co.x*change.x<0:
                change.x *= smooth(.015,.065,abs(co.x))
            if names == {'Shorts'}: change.z = 0
            delta += change
        if names == {'Shorts'}:
            # Keep the small centre bridge and waistband, avoiding inward collapse.
            delta *= smooth(.015,.055,abs(co.x))*(1-smooth(.995,1.055,co.z))
            delta.z = 0
        if delta.length>1e-8: updates[v.index] = co+delta
    before = helpers.locked_state(body,set(updates),set())
    height_before = max(v.co.z for v in mesh.vertices)
    for i,co in updates.items(): mesh.vertices[i].co = co
    mesh.update()
    # Fit the low short opening to the enlarged exposed thigh. Cast horizontally
    # from each leg axis; unlike nearest-surface projection, this preserves hem Z
    # and cannot jump to a cut skin edge above the opening.
    mesh.calc_loop_triangles()
    skin_triangles = [tuple(t.vertices) for t in mesh.loop_triangles
        if mesh.materials[mesh.polygons[t.polygon_index].material_index].name == 'Skin']
    skin_tree = BVHTree.FromPolygons([v.co.copy() for v in mesh.vertices],skin_triangles,all_triangles=True)
    clearance_vertices = 0
    for i in updates:
        if materials[i] != {'Shorts'}: continue
        co = mesh.vertices[i].co
        if not .69<co.z<.84 or abs(co.x)<.045: continue
        head,axis,length = frames['Thigh.R' if co.x>0 else 'Thigh.L']
        center = head+axis*((co.z-head.z)/axis.z)
        radial = co-center; radial.z = 0
        if radial.length<.01: continue
        direction = radial.normalized()
        # Sample the neighbouring heights as well: a cloth face above the cut
        # skin boundary still needs to cover skin between its corner vertices.
        distances = []
        for z in [co.z,co.z-.015,co.z+.015,min(co.z,.729)]:
            origin = head+axis*((z-head.z)/axis.z)
            hit,normal,index,distance = skin_tree.ray_cast(origin,direction,.18)
            if hit is not None: distances.append(distance)
        distance = max(distances) if distances else 0
        if distances and distance+.011>radial.length:
            mesh.vertices[i].co = center+direction*(distance+.011)
            clearance_vertices += 1
    mesh.update()
    assert before == helpers.locked_state(body,set(updates),set()), 'Protected asset data changed'
    assert height_before == max(v.co.z for v in mesh.vertices), 'Overall height changed'
    assert not mesh.validate(verbose=True,clean_customdata=False), 'Unexpected mesh repair'
    body['athletic_revision'] = REVISION
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
    data['athletic_revision'] = REVISION
    data.setdefault('athletic_roles', {})[role] = REVISION
    data['athletic_authorship'] = {'source':'apps/free-kick-3d/tools/athletic_footballer.py',
        'research':'docs/research/athletic-character-2026-10-04/', 'external_models_imported':False,
        'target':'silueta atlética inspirada en referencias oficiales de Football Strike'}
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
    def sections(positions):
        result = {}
        for label,lo,hi in [('waist',1.07,1.11),('chest',1.38,1.43)]:
            points = [positions[i] for i,n in materials.items() if 'Jersey' in n and lo<original[i].z<hi and abs(original[i].x)<.25]
            result[label+'_width_m'] = max(v.x for v in points)-min(v.x for v in points)
        return result
    report = {key+'_unchanged':True for key in before}
    report.update(role=role,height_unchanged=True,bones=len(rig.data.bones),animations=sorted(a['name'] for a in glb['animations']),
        affected_vertices=len(updates),max_displacement_m=max((mesh.vertices[i].co-original[i]).length for i in updates),
        short_clearance_vertices=clearance_vertices,
        before=sections(original),after=sections({v.index:v.co.copy() for v in mesh.vertices}),
        peak_radius_changes={'upperarm':.22,'forearm':.14,'thigh':.30,'calf':.25,'shorts':.08})
    directory = REVIEW; directory.mkdir(parents=True,exist_ok=True)
    (directory/('auditoria-conservacion.json' if role=='footballer' else 'goalkeeper-auditoria-conservacion.json')).write_text(json.dumps(report,indent=2)+'\n')
    print('ATHLETIC_FOOTBALLER',json.dumps(report),flush=True)

if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    input_path = Path(args[0]) if args else SOURCE/'footballer_v3.blend'
    role = args[1] if len(args)>1 else ('goalkeeper' if input_path.name.startswith('goalkeeper') else 'footballer')
    tailor(input_path, role)
