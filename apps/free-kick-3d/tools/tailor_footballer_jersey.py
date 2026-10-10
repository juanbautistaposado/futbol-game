"""Tailor only the player's jersey on the existing skinned mesh.

Run after build_footballer_v3.py, or pass an unmodified v3 .blend as input:
blender -b --factory-startup --python tools/tailor_footballer_jersey.py -- BASE_BLEND
Keeps all non-jersey geometry, weights, bones, actions and print UVs intact.
"""
import bpy, bmesh, math, sys, json, hashlib, struct
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
SOURCE = ROOT / 'source-assets/footballer'
OUT = APP / 'assets/footballer'
REVISION = 'football-jersey-shoulder-drape-pass2-2026-10-04'

# Localised flank tension and short vertical folds at the free hem.
# Shared by geometry and atlas: no mirrored diagonals meeting in a central V.
FOLDS = [
    ((-.185,1.39),(-.112,1.335),.0028,.013),
    ((.182,1.355),(.118,1.32),.0024,.014),
    ((-.125,1.03),(-.111,1.15),.0042,.018),
    ((.132,1.025),(.118,1.12),.0038,.019),
    ((.026,1.022),(.037,1.09),.0024,.020),
]

def smooth(a, b, x):
    t = max(0., min(1., (x-a)/(b-a)))
    return t*t*(3-2*t)

def jersey_components(mesh):
    faces = [p for p in mesh.polygons if mesh.materials[p.material_index].name == 'Jersey']
    remaining = {i for p in faces for i in p.vertices}
    neighbours = {i:set() for i in remaining}
    for p in faces:
        for i in p.vertices: neighbours[i].update(p.vertices)
    result = []
    while remaining:
        pending = [remaining.pop()]; component = set(pending)
        while pending:
            for i in neighbours[pending.pop()]:
                if i in remaining:
                    remaining.remove(i); component.add(i); pending.append(i)
        result.append(component)
    assert len(result) == 2, 'Expected continuous shirt and collar binding'
    return sorted(result, key=lambda c:min(mesh.vertices[i].co.z for i in c))

def make_atlas():
    # Three charts: cylindrical torso, arm-local sleeves, and collar binding.
    # Colour variations describe sewn panels, not baked directional lighting.
    n = 512
    yy, xx = np.mgrid[0:n, 0:n]; u = (xx+.5)/n; v = (yy+.5)/n
    weave = np.sin(xx*math.tau/4)*np.sin(yy*math.tau/4)
    shade = np.full((n,n), .93) + .006*weave
    rough = np.full((n,n), .74) + .015*weave
    relief = .000025*weave
    torso = (v>=.04)&(v<=.68)
    t = np.clip((v-.04)/.64, 0, 1)
    # Mesh side gussets taper towards the underarm; curved seams follow the cut.
    side_distance = np.minimum(np.abs(u-.25),np.abs(u-.75))
    panel_width = .060-.025*t
    panel = np.clip((panel_width-side_distance)/.008, 0, 1)*torso
    panel *= np.clip((.74-t)/.10,0,1)
    shade *= 1-.12*panel
    rough += .055*panel
    # Raglan-style shoulder construction, gentle tonal difference, no hard mesh join.
    front_distance = np.abs(u-.5)
    back_distance = np.minimum(u,1-u)
    center_distance = np.minimum(front_distance,back_distance)
    seam_t = .985-1.48*center_distance
    shoulder = np.clip((t-seam_t)/.012,0,1)*torso*(t>.68)
    shade *= 1-.015*shoulder
    seam = np.exp(-((t-seam_t)/.0035)**2)*torso*(t>.68)
    shade *= 1-.035*seam
    relief += .00012*seam
    side_seam = np.exp(-((side_distance-panel_width)/.0018)**2)*torso
    shade *= 1-.09*side_seam
    relief += .0002*side_seam
    hem = np.exp(-((t-.024)/.0025)**2)*torso
    shade *= 1-.12*hem
    relief += .0002*hem
    sleeve = (v>=.72)&(v<=.90)
    sleeve_t = np.clip((v-.72)/.18,0,1)
    cuff = sleeve*(sleeve_t>.91)
    shade *= 1-.22*cuff
    rough += .05*cuff
    relief += .00010*np.sin(xx*math.tau/6)*cuff
    collar = v>=.94
    shade *= 1-.32*collar
    rough += .07*collar
    relief += .00012*np.sin(xx*math.tau/5)*collar
    # Fold normals share the same local flank/hem strokes as the geometry.
    theta=(u-.5)*math.tau; cloth_x=.225*np.sin(theta); cloth_z=.986+t*.685
    for start,end,amplitude,width in FOLDS:
        dx=end[0]-start[0]; dz=end[1]-start[1]
        along=((cloth_x-start[0])*dx+(cloth_z-start[1])*dz)/(dx*dx+dz*dz)
        distance=((cloth_x-start[0]-along*dx)**2+(cloth_z-start[1]-along*dz)**2)**.5
        fold=amplitude*np.sin(np.clip(along,0,1)*math.pi)**.7*np.exp(-(distance/width)**2)
        relief+=fold*torso*np.clip(np.cos(theta)*6,0,1)
    # Normal map from shallow physical stitch/weave and fold relief.
    dy, dx = np.gradient(relief)
    normals = np.stack((-dx*n/.8, -dy*n/.8, np.ones_like(dx)),axis=2)
    normals /= np.linalg.norm(normals,axis=2,keepdims=True)
    def save(name, rgb, noncolor=False):
        pixels = np.ones((n,n,4),dtype=np.float32); pixels[:,:,:3] = rgb
        img = bpy.data.images.new(name,width=n,height=n,alpha=True)
        if noncolor: img.colorspace_settings.name='Non-Color'
        img.pixels.foreach_set(pixels.ravel())
        img.filepath_raw=str(OUT/'textures'/(name+'.png')); img.file_format='PNG';img.save();img.pack()
        return img
    return [save('jersey_albedo',np.repeat(shade[:,:,None],3,axis=2)),
            save('jersey_normal',normals*.5+.5,True),
            save('jersey_roughness',np.repeat(rough[:,:,None],3,axis=2),True)]

def invariant_snapshot(body, protected):
    mesh=body.data
    state={
        'protected_positions':[[i,list(mesh.vertices[i].co)] for i in sorted(protected)],
        'weights':[[[body.vertex_groups[g.group].name,g.weight] for g in v.groups] for v in mesh.vertices],
        'dorsal_uv': [list(loop.uv) for loop in mesh.uv_layers['JerseyPrintUV'].data],
        'palette': {m.name:list(m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value) for m in mesh.materials if m.node_tree.nodes.get('Principled BSDF')},
    }
    return hashlib.sha256(json.dumps(state,sort_keys=True).encode()).hexdigest()

def update_manifest(role='footballer'):
    path=SOURCE/'athlete_v3_manifest.json'
    data=json.loads(path.read_text())
    raw=(OUT/f'{role}_v3.glb').read_bytes()
    size=struct.unpack_from('<I',raw,12)[0];glb=json.loads(raw[20:20+size])
    for item in data['exports']:
        if item['path'].endswith(f'/{role}_v3.glb'):
            item.update(sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),
                triangles=sum(glb['accessors'][p['indices']]['count']//3 for m in glb['meshes'] for p in m['primitives']),
                surfaces=sum(len(m['primitives']) for m in glb['meshes']),embedded_images=len(glb['images']),
                bones=len(glb['skins'][0]['joints']),animations=sorted(a['name'] for a in glb['animations']))
    data['revision']=REVISION;data['revision_date']='2026-10-04'
    data['art_target']['jersey_texture_size']=512
    data['art_target']['style']='fútbol estilizado: camiseta deportiva con caída libre, cuello fino y paneles tonales'
    data['jersey_authorship']={'author':'geometría y atlas originales del proyecto','external_models_imported':False,
        'research':'docs/research/jersey-quality-2026-10-04/','source':'apps/free-kick-3d/tools/tailor_footballer_jersey.py'}
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def tailor(input_path, role='footballer'):
    if role not in ('footballer','goalkeeper'): raise ValueError('Unknown athlete role')
    bpy.ops.wm.open_mainfile(filepath=str(input_path))
    body = bpy.data.objects['FootballerBody']; mesh = body.data
    if body.get('jersey_tailoring_revision'):
        raise RuntimeError('Use an unmodified base blend; tailoring is not cumulative')
    shirt, collar = jersey_components(mesh)
    protected=set(range(len(mesh.vertices)))-(shirt|collar)
    invariant=invariant_snapshot(body,protected)
    original = {i:mesh.vertices[i].co.copy() for i in shirt|collar}
    rig = bpy.data.objects['FootballerRig']
    mesh.calc_loop_triangles()
    skin_triangles=[tuple(t.vertices) for t in mesh.loop_triangles if mesh.materials[mesh.polygons[t.polygon_index].material_index].name=='Skin']
    skin_tree=BVHTree.FromPolygons([v.co.copy() for v in mesh.vertices],skin_triangles,all_triangles=True)
    def arm_frame(co):
        bone = rig.data.bones['UpperArm.R' if co.x>0 else 'UpperArm.L']
        axis = (bone.tail_local-bone.head_local).normalized()
        origin = bone.head_local
        along = (co-origin).dot(axis)
        radial = co-origin-axis*along
        return origin,axis,along,radial
    for i in shirt:
        c = mesh.vertices[i].co; old = original[i]
        # Hang from the chest: abdomen is an envelope rather than a muscle tracing.
        torso_weight = (1-smooth(.18,.24,abs(old.x)))*(1-smooth(1.48,1.56,old.z))
        abdomen = 1-smooth(1.30,1.48,old.z)
        c.x += math.copysign(.013*abdomen*torso_weight,old.x)*smooth(.02,.14,abs(old.x))
        depth_direction = -1 if old.y<-.020 else 1
        c.y += depth_direction*(.011+.006*abdomen)*torso_weight
        # A free, softly uneven hem covers the waistband, pinned to existing Hips weights.
        hem_weight = 1-smooth(1.035,1.17,old.z)
        c.z -= hem_weight*(.017+.002*math.sin(old.x*27+.4))
        # Bridge the side pectorals with one broad cloth panel; avoid anatomical lobes.
        if old.y<-.035 and abs(old.x)<.215 and 1.05<old.z<1.52:
            plane = float(np.interp(old.z,[1.05,1.18,1.32,1.46,1.52],[-.183,-.181,-.177,-.168,-.151]))
            plane += .055*(abs(old.x)/.23)**2
            blend = (1-smooth(.16,.215,abs(old.x)))*smooth(1.05,1.15,old.z)*(1-smooth(1.45,1.52,old.z))
            c.y = c.y*(1-blend)+plane*blend
        # Local flank tension and hem drape leave the middle of the torso clean.
        if old.y<-.03 and 1.035<old.z<1.47:
            envelope = smooth(1.035,1.09,old.z)*(1-smooth(1.40,1.47,old.z))
            folds = 0.
            # Short independent folds; the chest centre stays smooth.
            for start,end,amplitude,width in FOLDS:
                a=np.array(start); direction=np.array(end)-a; delta=np.array((old.x,old.z))-a
                along=float(delta@direction/(direction@direction))
                if 0<along<1:
                    d=float(np.linalg.norm(delta-direction*along))
                    folds += amplitude*math.sin(along*math.pi)**.7*math.exp(-(d/width)**2)
            c.y -= folds*envelope
        if old.y>.02 and 1.04<old.z<1.46:
            # Back folds are broader and weaker so name/number remain readable.
            envelope = smooth(1.04,1.10,old.z)*(1-smooth(1.40,1.46,old.z))
            c.y += .002*math.exp(-((abs(old.x)-.12)/.025)**2)*math.sin((old.z-1.03)*23)*envelope*(1-smooth(1.16,1.24,old.z))
        origin,axis,along,radial = arm_frame(old)
        # Flatten the inflated shoulder cap while preserving its continuous surface.
        shoulder = smooth(.165,.215,abs(old.x))*(1-smooth(.30,.35,abs(old.x)))
        shoulder *= smooth(1.465,1.535,old.z)*(1-smooth(1.625,1.67,old.z))
        c.y += (.010 if old.y<-.025 else -.008)*shoulder
        c.z -= .012*shoulder
        c.x -= math.copysign(.004*shoulder,old.x)
        # A straight, slightly oval sleeve hangs below the arm instead of flaring.
        sleeve = smooth(.175,.225,abs(old.x))*smooth(.005,.065,along)
        if radial.length and sleeve:
            across=Vector((0,1,0)); up=axis.cross(across).normalized()
            r=c-origin-axis*(c-origin).dot(axis)
            elliptical=math.sqrt((r.dot(across)/.057)**2+(r.dot(up)/.060)**2)
            tube_blend=smooth(.015,.090,along)*sleeve
            if elliptical>0:
                target=origin+axis*(c-origin).dot(axis)+r/elliptical
                target.z-=.003*sleeve
                c=c.lerp(target,tube_blend)
        # Slight drape below the armpit softens the arm-to-torso saddle.
        axilla=smooth(.155,.205,abs(old.x))*(1-smooth(.235,.285,abs(old.x)))
        axilla*=smooth(1.335,1.395,old.z)*(1-smooth(1.445,1.50,old.z))
        c.z-=.005*axilla
        # Open the front neckline slightly; the existing skin continues beneath it.
        if old.z>1.56 and abs(old.x)<.15:
            angle = math.atan2(old.y+.035,old.x)
            front = max(0.,-math.sin(angle))
            neck = smooth(1.56,1.63,old.z)*(1-smooth(.095,.15,abs(old.x)))
            c.z -= .017*front*neck
            c.y -= .004*front*neck
    # The surviving skin at the clavicle must stay under the reshaped fabric.
    # Enforce local clearance only where skin actually remains; do not alter skin.
    for i in shirt:
        c=mesh.vertices[i].co
        if original[i].z>1.47 and .13<abs(original[i].x)<.34:
            hit,normal,index,distance=skin_tree.find_nearest(c)
            if hit is not None and distance<.025 and (c-hit).dot(normal)<.003:
                c[:]=hit+normal*.003
    for i in collar:
        c = mesh.vertices[i].co; old = original[i]
        angle = math.atan2(old.y+.035,old.x)
        front = max(0.,-math.sin(angle))
        c.z -= .017*front
        c.y -= .004*front
    mesh.update()
    # Re-map only UV0; UV2's existing dorsal coordinates and all weights stay exact.
    uv = mesh.uv_layers['UVMap']
    for p in mesh.polygons:
        if mesh.materials[p.material_index].name!='Jersey':continue
        is_collar = p.vertices[0] in collar
        center = sum((original[i] for i in p.vertices),Vector())/len(p.vertices)
        is_sleeve = abs(center.x)>.225 and arm_frame(center)[2]>.035
        values=[]
        for i in p.vertices:
            c=mesh.vertices[i].co
            if is_collar:
                angle=math.atan2(c.y+.035,c.x)
                values.append(((angle/math.tau+.5)%1,.965+(c.z-1.64)*.25))
            elif is_sleeve:
                origin,axis,along,radial=arm_frame(c)
                across=Vector((0,1,0));up=axis.cross(across).normalized()
                angle=math.atan2(radial.dot(up),radial.dot(across))
                values.append(((angle/math.tau+.5)%1,.72+.18*max(0.,min(1.,along/.158))))
            else:
                angle=math.atan2(c.x,-(c.y+.02))
                values.append(((angle/math.tau+.5)%1,.04+.64*max(0.,min(1.,(c.z-.986)/.685))))
        # Unwrap the cylinder seam per face instead of stretching across the atlas.
        if max(a[0] for a in values)-min(a[0] for a in values)>.5:
            values=[(u+1 if u<.5 else u,v) for u,v in values]
        for li,value in zip(p.loop_indices,values):uv.data[li].uv=value
    albedo,normal,roughness = make_atlas()
    mat=bpy.data.materials['Jersey']; nodes=mat.node_tree.nodes
    # Preserve the palette and switch only this material's texture nodes.
    for node in nodes:
        if node.type!='TEX_IMAGE':continue
        if node.image.name.startswith('kit_albedo'):node.image=albedo
        elif node.image.name.startswith('kit_normal'):node.image=normal
        elif node.image.name.startswith('kit_roughness'):node.image=roughness
    for node in nodes:
        if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.85
    body['jersey_tailoring_revision']=REVISION
    if mesh.validate(verbose=True,clean_customdata=False):raise RuntimeError('Unexpected mesh repair')
    # Recalculate only jersey normals. Other source surfaces remain untouched.
    bm=bmesh.new();bm.from_mesh(mesh)
    jersey_index=list(mesh.materials).index(mat)
    bmesh.ops.recalc_face_normals(bm,faces=[f for f in bm.faces if f.material_index==jersey_index])
    bm.to_mesh(mesh);bm.free()
    assert invariant==invariant_snapshot(body,protected), 'A protected region, weight, palette or print UV changed'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/f'{role}_v3.blend'))
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [rig,body,bpy.data.objects['Beard']]:obj.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/f'{role}_v3.glb'),export_format='GLB',export_vertex_color='ACTIVE',export_all_vertex_colors=False,use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_apply=False,export_yup=True,export_skins=True,export_all_influences=False)
    update_manifest(role)
    print('JERSEY_TAILORED',len(shirt),len(collar),REVISION,flush=True)

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    input_path = Path(args[0]) if args else SOURCE/'footballer_v3.blend'
    role = args[1] if len(args)>1 else ('goalkeeper' if input_path.name.startswith('goalkeeper') else 'footballer')
    tailor(input_path, role)
