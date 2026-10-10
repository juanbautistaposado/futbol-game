"""Build clothed CC0 MPFB athletes; no Blender installation/preferences changes.

blender -b --factory-startup --python tools/build_footballer_v3.py -- MPFB_REPO SYSTEM_ASSETS
Sources/versions and download instructions: source-assets/footballer/footballer_v3.md.
"""
import bpy, bmesh, sys, math, random
import numpy as np
from pathlib import Path
from mathutils import Vector

APP = Path(__file__).resolve().parents[1]
ROOT = APP.parents[1]
SOURCE = ROOT / 'source-assets/footballer'
OUT = APP / 'assets/footballer'
TEXTURES = OUT / 'textures'
TEXTURES.mkdir(parents=True, exist_ok=True)
args = sys.argv[sys.argv.index('--') + 1:]
sys.path.insert(0, str(Path(args[0]) / 'src'))
ASSETS = Path(args[1])
import mpfb
bpy.utils.extension_path_user = lambda *a, **kw: '/tmp/futbol-mpfb-state'
mpfb.get_preference = lambda name: '/tmp/futbol-mpfb-state' if name == 'mpfb_user_data' else None
mpfb.register()
from mpfb.services.humanservice import HumanService
from mpfb.services.targetservice import TargetService
from mpfb.services.exportservice import ExportService
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
macros = TargetService.get_default_macro_info_dict()
macros.update(gender=1., age=.5, muscle=.8, weight=.4, height=.6, proportions=.65)
human = HumanService.create_human(macro_detail_dict=macros)
rig = HumanService.add_builtin_rig(human, 'game_engine')
HumanService.set_character_skin(str(ASSETS/'skins/young_caucasian_male/young_caucasian_male.mhmat'), human, skin_type='GAMEENGINE')
parts = [human]
for folder, file, kind in [('eyes/low-poly','low-poly.mhclo','Eyes'), ('eyebrows/eyebrow001','eyebrow001.mhclo','Eyebrows'), ('hair/short04','short04.mhclo','Hair')]:
    parts.append(HumanService.add_mhclo_asset(str(ASSETS/folder/file), human, asset_type=kind, subdiv_levels=0, material_type='GAMEENGINE'))
TargetService.bake_targets(human)
ExportService.bake_modifiers_remove_helpers(human, bake_masks=True, remove_helpers=True)
# Normalize a real anatomical mesh to the existing gameplay scale.
height = max(v.co.z for v in human.data.vertices)
factor = 1.90 / height
for obj in parts:
    for vertex in obj.data.vertices: vertex.co *= factor
    obj.location *= factor
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for bone in rig.data.edit_bones:
    bone.head *= factor; bone.tail *= factor
bpy.ops.object.mode_set(mode='OBJECT')
rig.name = 'FootballerRig'
rename = {'pelvis':'Hips','spine_01':'Spine','spine_02':'SpineMid','spine_03':'Chest','neck_01':'Neck','head':'Head'}
# MakeHuman anatomical left is +X; current game uses Left = -X.
for source_side, side in [('l','R'),('r','L')]:
    for src, target in [('upperarm','UpperArm'),('lowerarm','Forearm'),('hand','Hand'),('thigh','Thigh'),('calf','Shin'),('foot','Foot')]: rename[f'{src}_{source_side}'] = f'{target}.{side}'
for old, new in rename.items():
    rig.data.bones[old].name = new
    for obj in parts:
        group = obj.vertex_groups.get(old)
        if group: group.name = new
# Refine the close-up facial surface without subdividing the whole athlete.
bm=bmesh.new();bm.from_mesh(human.data)
head_edges=[edge for edge in bm.edges if all(vertex.co.z>1.61 for vertex in edge.verts)]
bmesh.ops.subdivide_edges(bm,edges=head_edges,cuts=1,use_grid_fill=True,smooth=.15)
bm.to_mesh(human.data);bm.free()
# Refine the anatomical surface before clothing and removal of covered skin.
for mat in human.data.materials: mat.name = 'Skin'
for mat in parts[1].data.materials: mat.name = 'Eyes'
for mat in parts[2].data.materials:mat.name='Hair'
for mat in parts[3].data.materials:mat.name='HairStrands'

# Use neutral skin texture variation so runtime skin tints stay meaningful.
def save_image(name, pixels, noncolor=False):
    img = bpy.data.images.new(name, width=pixels.shape[1], height=pixels.shape[0], alpha=True)
    if noncolor: img.colorspace_settings.name='Non-Color'
    img.pixels.foreach_set(pixels.astype(np.float32).ravel())
    img.filepath_raw=str(TEXTURES/(name+'.png')); img.file_format='PNG'; img.save()
    return img
for mat in human.data.materials:
    for node in mat.node_tree.nodes:
        if node.type == 'TEX_IMAGE' and node.image:
            src=node.image; w,h=src.size
            pix=np.array(src.pixels[:],dtype=np.float32).reshape(h,w,4)
            # Preserve facial variation, freckles and lips while neutralizing base skin.
            lum=pix[:,:,:3].mean(axis=2)
            ratio=np.clip(pix[:,:,:3]/np.maximum(lum[:,:,None],.05),.65,1.35)
            neutral=np.ones_like(pix); neutral[:,:,:3]=np.clip((.62+.36*lum[:,:,None])*ratio,.12,1)
            # Limit runtime memory; original CC0 master is recorded separately.
            img=save_image('skin_detail',neutral)
            img.scale(1024,1024);img.save();node.image=img
    bsdf=mat.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Base Color'].default_value=(.57,.36,.245,1)
    bsdf.inputs['Roughness'].default_value=.75

# Skin and eyeballs are opaque. MPFB's alpha link otherwise makes glTF use
# transparent sorting, exposing inner mouth/eye surfaces and triangle edges.
for obj in [human, parts[1]]:
    for mat in obj.data.materials:
        bsdf=mat.node_tree.nodes.get('Principled BSDF')
        for link in list(bsdf.inputs['Alpha'].links):mat.node_tree.links.remove(link)
        bsdf.inputs['Alpha'].default_value=1.0

# Neutralize the dark hair atlas for independent recoloring; preserve its alpha.
for mat in parts[3].data.materials:
    for node in mat.node_tree.nodes:
        if node.type=='TEX_IMAGE' and node.image:
            image=node.image;w,h=image.size
            pix=np.array(image.pixels[:],dtype=np.float32).reshape(h,w,4)
            lum=pix[:,:,:3].mean(axis=2)
            pix[:,:,:3]=(.45+.55*np.clip(lum/.14,0,1))[:,:,None]
            detail=save_image('hair_detail',pix);detail.scale(1024,1024);detail.save();node.image=detail

# Dedicated tileable cloth maps with low contrast and actual normal/roughness data.
N=512
y,x=np.mgrid[0:N,0:N];u=x/N;v=y/N
weave=np.sin(x*math.tau/4)*np.sin(y*math.tau/4)
fold=.5*np.sin(u*math.tau*3+np.sin(v*math.tau)*1.8)*np.sin(v*math.pi)**2
albedo=np.ones((N,N,4));albedo[:,:,:3]=(.91+.016*weave+.03*fold)[:,:,None]
cloth=save_image('kit_albedo',albedo)
rough=np.ones((N,N,4));rough[:,:,:3]=(.84+.025*weave)[:,:,None]
roughmap=save_image('kit_roughness',rough,True)
normal=np.ones((N,N,4));normal[:,:,0]=.5+.025*np.cos(x*math.tau/4);normal[:,:,1]=.5+.025*np.cos(y*math.tau/4);normal[:,:,2]=.998
normalmap=save_image('kit_normal',normal,True)

def material(name, color, cloth_maps=False, roughness=.75):
    m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=roughness
    if cloth_maps:
        for image,socket in [(cloth,'Base Color'),(roughmap,'Roughness')]:
            n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=image;m.node_tree.links.new(n.outputs['Color'],bs.inputs[socket])
        n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=normalmap
        nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.3
        m.node_tree.links.new(n.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],bs.inputs['Normal'])
    return m
jersey=material('Jersey',(.065,.25,.55),True)
shorts=material('Shorts',(.025,.055,.16),True)
socks=material('Socks',(.065,.25,.55),True)
trim=material('Trim',(.88,.9,.88),True)
boots=material('Boots',(.035,.045,.055),False,.4)
gloves=material('GoalkeeperGloves',(.78,.81,.76),False,.62)

human.data.update()
coords=[v.co.copy() for v in human.data.vertices]
weights=[{human.vertex_groups[g.group].name:g.weight for g in vertex.groups if human.vertex_groups[g.group].name in rig.data.bones} for vertex in human.data.vertices]

SHORT_HEM = .715
SLEEVE_LENGTH = .158

# Fit the neckline to the actual anatomical surface (the neck is forward of
# the torso center), and interpolate its original bone weights.
from mathutils.bvhtree import BVHTree
human.data.calc_loop_triangles()
source_triangles=[tuple(triangle.vertices) for triangle in human.data.loop_triangles]
body_tree=BVHTree.FromPolygons(coords,source_triangles,all_triangles=True)
def sampled_weights(point,triangle_index):
    indices=source_triangles[triangle_index]
    a,b,c=[coords[index] for index in indices]
    v0=b-a;v1=c-a;v2=point-a
    d00=v0.dot(v0);d01=v0.dot(v1);d11=v1.dot(v1);d20=v2.dot(v0);d21=v2.dot(v1)
    denom=d00*d11-d01*d01
    u=(d11*d20-d01*d21)/denom;v=(d00*d21-d01*d20)/denom
    bary=[max(0.,1-u-v),max(0.,u),max(0.,v)];total=sum(bary)
    result={}
    for index,factor in zip(indices,bary):
        for name,weight in weights[index].items():result[name]=result.get(name,0)+weight*factor/total
    return result

def neckline_point(angle,outer=False):
    direction=Vector((math.cos(angle),math.sin(angle),0))
    origin=Vector((0,-.035,1.645+.015*math.sin(angle)))
    hit,normal,index,distance=body_tree.ray_cast(origin,direction,.3)
    if hit is None:raise RuntimeError('Neckline ray missed anatomical skin')
    return hit+direction*(.020 if outer else .0015)+Vector((0,0,-.003 if outer else .001)),sampled_weights(hit,index)

def ordered_boundary(loop):
    start=max(loop,key=lambda vertex:vertex.co.x)
    neighbours=[edge.other_vert(start) for edge in start.link_edges if edge.is_boundary and edge.other_vert(start) in loop]
    current=max(neighbours,key=lambda vertex:vertex.co.y)
    ordered=[start];previous=start
    while current!=start:
        ordered.append(current)
        following=[edge.other_vert(current) for edge in current.link_edges if edge.is_boundary and edge.other_vert(current) in loop and edge.other_vert(current)!=previous]
        if not following:break
        previous,current=current,following[0]
    return ordered

def garment(name, select, mat, expansion=.01, smooth=6):
    obj=human.copy();obj.data=human.data.copy();bpy.context.collection.objects.link(obj)
    obj.name=name;obj.data.materials.clear();obj.data.materials.append(mat)
    # Select by complete face centers; generated clothes share body weights.
    bm=bmesh.new();bm.from_mesh(obj.data)
    remove=[f for f in bm.faces if not select(f.calc_center_median())]
    bmesh.ops.delete(bm,geom=remove,context='FACES')
    loose=[vert for vert in bm.verts if not vert.link_faces]
    bmesh.ops.delete(bm,geom=loose,context='VERTS')
    bm.normal_update()
    for vert in bm.verts: vert.co += vert.normal*expansion
    bm.to_mesh(obj.data);bm.free()
    bpy.context.view_layer.objects.active=obj
    # Smooth cloth so it bridges muscle/anatomical creases instead of tracing them.
    mod=obj.modifiers.new('Cloth drape','SMOOTH');mod.factor=1.;mod.iterations=smooth
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Align garment boundary loops: a deliberate neck opening and level hems.
    if name in ['Jersey','Shorts','Socks']:
        bm=bmesh.new();bm.from_mesh(obj.data)
        edges={edge for edge in bm.edges if edge.is_boundary}
        while edges:
            edge=edges.pop();loop=set(edge.verts);pending=list(edge.verts)
            while pending:
                vertex=pending.pop()
                for linked in vertex.link_edges:
                    if linked in edges:
                        edges.remove(linked)
                        for other in linked.verts:
                            if other not in loop:loop.add(other);pending.append(other)
            center=sum((vertex.co for vertex in loop),Vector())/len(loop)
            if name=='Jersey' and max(vertex.co.z for vertex in loop)>1.53 and min(vertex.co.x for vertex in loop)<0<max(vertex.co.x for vertex in loop):
                ordered=ordered_boundary(loop);deform=bm.verts.layers.deform.verify()
                for i,vertex in enumerate(ordered):
                    angle=math.atan2(vertex.co.y+.035,vertex.co.x)
                    vertex.co,groups=neckline_point(angle,outer=True)
                    vertex[deform].clear()
                    for group,weight in groups.items():vertex[deform][obj.vertex_groups[group].index]=weight
            elif name=='Jersey' and center.z<1.15:
                for vertex in loop:vertex.co.z=1.005
            elif name in ['Shorts','Socks']:
                for vertex in loop:vertex.co.z=center.z
                if name=='Socks' and center.z>.3:
                    deform=bm.verts.layers.deform.verify()
                    group=obj.vertex_groups['Shin.R' if center.x>0 else 'Shin.L'].index
                    for vertex in loop:
                        vertex[deform].clear();vertex[deform][group]=1.
            elif name=='Jersey':
                bone=rig.data.bones['UpperArm.R' if center.x>0 else 'UpperArm.L']
                axis=(bone.tail_local-bone.head_local).normalized()
                deform=bm.verts.layers.deform.verify()
                for vertex in loop:
                    vertex.co-=axis*((vertex.co-bone.head_local).dot(axis)-SLEEVE_LENGTH)
                    vertex[deform].clear();vertex[deform][obj.vertex_groups[bone.name].index]=1.
        bm.to_mesh(obj.data);bm.free()
    # Uniform projective UVs for readable cloth maps, not skin UVs.
    if name not in ['Beard']:
        while len(obj.data.uv_layers)>1:obj.data.uv_layers.remove(obj.data.uv_layers[-1])
        uv=obj.data.uv_layers[0]
        uv.name='UVMap'
        print_uv=obj.data.uv_layers.new(name='JerseyPrintUV')
        for p in obj.data.polygons:
            p.material_index=0;p.use_smooth=True
            for li in p.loop_indices:
                co=obj.data.vertices[obj.data.loops[li].vertex_index].co
                uv.data[li].uv=(co.x*2+0.5,co.z*.8)
                print_uv.data[li].uv=((.5-co.x/.5),(co.z-1.08)/.42) if name=='Jersey' and p.normal.y>.35 else (-2,-2)
    return obj
# Boundaries are explicit in normalized metres and independent of viewport.
def sleeve_axis(c):
    bone=rig.data.bones['UpperArm.R' if c.x>0 else 'UpperArm.L']
    return bone.head_local,(bone.tail_local-bone.head_local).normalized()
def jersey_region(c):
    if not 1.00<c.z<1.68:return False
    if abs(c.x)>.21:
        origin,axis=sleeve_axis(c)
        return (c-origin).dot(axis)<SLEEVE_LENGTH
    return not (c.z>1.53 and abs(c.x)<.105)
shirt=garment('Jersey',jersey_region,jersey,.040,24)
def smooth_transition(low,high,value):
    t=max(0.,min(1.,(value-low)/(high-low)))
    return t*t*(3-2*t)
# Shape one continuous garment, using the arm surface rather than a rigid
# cylinder added past an X threshold. The shoulder keeps its original blend.
for vertex in shirt.data.vertices:
    co=vertex.co.copy()
    if abs(co.x)<.225 and co.z<1.50:
        ease=max(0.,min(1.,(1.50-co.z)/.06))*(1-smooth_transition(.15,.225,abs(co.x)))
        co.x*=1.+.04*ease
    origin,axis=sleeve_axis(co)
    along=(co-origin).dot(axis)
    radial=co-(origin+axis*along)
    blend=smooth_transition(.025,.085,along)*smooth_transition(.155,.240,abs(co.x))
    if blend and 1.25<co.z<1.67 and radial.length:
        direction=radial.normalized()
        hit,normal,index,distance=body_tree.ray_cast(origin+axis*along,direction,.20)
        if hit is not None:
            target=hit+direction*.012
            co=co.lerp(target,blend)
        bone='UpperArm.R' if co.x>0 else 'UpperArm.L'
        weight_blend=blend*smooth_transition(.055,.145,along)
        groups={shirt.vertex_groups[g.group].name:g.weight*(1-weight_blend) for g in vertex.groups}
        groups[bone]=groups.get(bone,0)+weight_blend
        for group_index in [g.group for g in vertex.groups]:shirt.vertex_groups[group_index].remove([vertex.index])
        for name,weight in groups.items():
            if weight:shirt.vertex_groups[name].add([vertex.index],weight,'REPLACE')
    vertex.co=co
# Relax across the shoulder transition as a single surface. Pin collar/cuffs.
bm=bmesh.new();bm.from_mesh(shirt.data)
relax=[v for v in bm.verts if .145<abs(v.co.x)<.38 and 1.30<v.co.z<1.67 and not v.is_boundary]
for iteration in range(12):
    positions={v:sum((e.other_vert(v).co for e in v.link_edges),Vector())/len(v.link_edges) for v in relax}
    for v,position in positions.items():
        strength=.35*smooth_transition(.145,.19,abs(v.co.x))*(1-smooth_transition(.32,.38,abs(v.co.x)))
        v.co=v.co.lerp(position,strength)
bm.to_mesh(shirt.data);bm.free()
# Tailored shorts: one waistband, a sewn crotch and two leg openings.
# The previous body-surface crop traced anatomy and produced an irregular cut.
def tailored_shorts():
    vertices=[];faces=[];assignments=[]
    def add(co, weights):
        vertices.append(tuple(co));assignments.append(weights);return len(vertices)-1
    def bridge(a,b):
        for i in range(len(a)):faces.append((a[i],a[(i+1)%len(a)],b[(i+1)%len(b)],b[i]))
    rings=[]
    for z,rx,ry in [(1.075,.168,.098),(1.052,.174,.105),(1.018,.182,.117),(.995,.193,.121),(.935,.225,.139)]:
        ring=[add((rx*math.cos(-math.pi/2+i*math.tau/32),-.014+ry*math.sin(-math.pi/2+i*math.tau/32),z),{'Hips':1.}) for i in range(32)]
        if rings:bridge(rings[-1],ring)
        rings.append(ring)
    crotch=[add((0,y,.758),{'Hips':.4,'Thigh.L':.3,'Thigh.R':.3}) for y in [.040,-.014,-.068]]
    for side,indices in [(1,list(range(17))),(-1,list(range(16,32))+[0])]:
        branch=[rings[-1][i] for i in indices]+(crotch if side>0 else list(reversed(crotch)))
        thigh='Thigh.R' if side>0 else 'Thigh.L'
        cx=side*.121
        angles=[math.atan2(vertices[i][1]+.014,vertices[i][0]-cx) for i in branch]
        previous=branch
        for z,inner_drop,rx,ry,pelvis in [(.842,.088,.116,.123,.20),(.780,.044,.115,.121,.04),(.730,.004,.115,.120,0.),(.722,0.,.115,.120,0.),(SHORT_HEM,0.,.115,.120,0.)]:
            # Keep inner seams descending from the shared low crotch. Flat
            # upper leg rings above it would fold the seam back upwards.
            ring=[add((cx+rx*math.cos(angle),-.014+ry*math.sin(angle),z-inner_drop*max(0.,-side*math.cos(angle))),{'Hips':pelvis,thigh:1-pelvis}) for angle in angles]
            bridge(previous,ring);previous=ring
    mesh=bpy.data.meshes.new('Tailored shorts');mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new('Shorts',mesh);bpy.context.collection.objects.link(obj);obj.parent=rig
    mesh.materials.append(shorts)
    for name in ['Hips','Thigh.L','Thigh.R']:obj.vertex_groups.new(name=name)
    for i,groups in enumerate(assignments):
        for name,weight in groups.items():
            if weight:obj.vertex_groups[name].add([i],weight,'REPLACE')
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Tailored smoothing','SUBSURF');mod.levels=2
    bpy.ops.object.modifier_apply(modifier=mod.name)
    # Low-amplitude cloth folds fade out at the supported waistband and hem.
    for vertex in mesh.vertices:
        co=vertex.co;cx=.121 if co.x>0 else -.121
        radial=Vector((co.x-cx,co.y+.014,0))
        if radial.length and SHORT_HEM+.015<co.z<.975:
            angle=math.atan2(radial.y,radial.x)
            fold=.0030*math.cos(angle*5+.4)*math.sin((co.z-SHORT_HEM-.015)/(.960-SHORT_HEM)*math.pi)**2
            co+=radial.normalized()*fold
    bm=bmesh.new();bm.from_mesh(mesh)
    for vertex in bm.verts:
        if vertex.is_boundary and vertex.co.z<.80:vertex.co.z=SHORT_HEM
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
    uv=mesh.uv_layers.new(name='UVMap');blank=mesh.uv_layers.new(name='JerseyPrintUV')
    for face in mesh.polygons:
        face.use_smooth=True
        for li in face.loop_indices:
            co=mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv=(co.x*2+.5,co.z*.8)
            angle=math.atan2(co.y+.014,abs(co.x)-.121)
            blank.data[li].uv=(angle/math.tau+.5,co.z-SHORT_HEM)
    mod=obj.modifiers.new('Shorts skinning','ARMATURE');mod.object=rig
    return obj
short=tailored_shorts()
sock=garment('Socks',lambda c: .095<c.z<.55 and abs(c.x)<.30,socks,.004,3)
# Smoothing the knee cuff must not pull the cloth inside exposed skin.
for vertex in sock.data.vertices:
    if vertex.co.z>.50:
        hit,normal,index,distance=body_tree.find_nearest(vertex.co)
        if (vertex.co-hit).dot(normal)<.008:vertex.co=hit+normal*.008
        for group_index in [g.group for g in vertex.groups]:sock.vertex_groups[group_index].remove([vertex.index])
        sock.vertex_groups['Shin.R' if vertex.co.x>0 else 'Shin.L'].add([vertex.index],1.,'REPLACE')
# Model shoe shells with a continuous convex toe box, not individual toes.
boot_parts=[]
for side in [-1,1]:
    obj=garment('Boots',lambda c:c.z<.145 and side*c.x>0,boots,.008,1)
    bm=bmesh.new();bm.from_mesh(obj.data)
    result=bmesh.ops.convex_hull(bm,input=list(bm.verts),use_existing_faces=False)
    bmesh.ops.delete(bm,geom=[g for g in result.get('geom_interior',[]) if isinstance(g,bmesh.types.BMVert)],context='VERTS')
    # Remove original interior faces; hull is the only external shoe surface.
    keep=set(g for g in result['geom'] if isinstance(g,bmesh.types.BMFace))
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f not in keep],context='FACES')
    for vert in bm.verts: vert.co.z=max(vert.co.z,.005)
    bm.to_mesh(obj.data);bm.free()
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Rounded boot upper','BEVEL');mod.width=.009;mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name)
    for vtx in obj.data.vertices:
        for g in list(vtx.groups):obj.vertex_groups[g.group].remove([vtx.index])
    vg=obj.vertex_groups.get('Foot.R' if side>0 else 'Foot.L') or obj.vertex_groups.new(name='Foot.R' if side>0 else 'Foot.L')
    vg.add(list(range(len(obj.data.vertices))),1,'REPLACE')
    obj.data.materials.append(trim)
    for face in obj.data.polygons:
        if face.center.z<.026:face.material_index=1
    from mathutils.bvhtree import BVHTree
    hull=bmesh.new();hull.from_mesh(obj.data);tree=BVHTree.FromBMesh(hull)
    center_x=sum(v.co.x for v in obj.data.vertices)/len(obj.data.vertices)
    for lace_y in [-.065,-.092,-.119]:
        points=[]
        for lace_x in [center_x-.024,center_x+.024]:
            hit=tree.ray_cast(Vector((lace_x,lace_y,.4)),Vector((0,0,-1)))[0]
            if hit is not None:points.append(hit+Vector((0,0,.0015)))
        if len(points)!=2:continue
        curve=bpy.data.curves.new('Boot lace','CURVE');curve.dimensions='3D';curve.bevel_depth=.0017;curve.bevel_resolution=1
        spline=curve.splines.new('POLY');spline.points.add(1)
        for point,co in zip(spline.points,points):point.co=(*co,1)
        lace=bpy.data.objects.new('Lace',curve);bpy.context.collection.objects.link(lace);curve.materials.append(trim)
        bpy.ops.object.select_all(action='DESELECT');lace.select_set(True);bpy.context.view_layer.objects.active=lace;bpy.ops.object.convert(target='MESH')
        vg=lace.vertex_groups.new(name='Foot.R' if side>0 else 'Foot.L');vg.add(list(range(len(lace.data.vertices))),1,'REPLACE')
        lace.parent=rig;modifier=lace.modifiers.new('Deform lace','ARMATURE');modifier.object=rig
        boot_parts.append(lace)
    hull.free()
    boot_parts.append(obj)
bpy.ops.object.select_all(action='DESELECT')
for obj in boot_parts:obj.select_set(True)
bpy.context.view_layer.objects.active=boot_parts[0];bpy.ops.object.join();boot=boot_parts[0]
# Smooth the collar/shoulder transition with overlapping, gradual weights.
# A rectangular relax mask would leave another crease at its own border.
bm=bmesh.new();bm.from_mesh(shirt.data)
relax=[v for v in bm.verts if 1.30<v.co.z<1.70 and abs(v.co.x)<.40 and not v.is_boundary]
for iteration in range(24):
    positions={v:sum((e.other_vert(v).co for e in v.link_edges),Vector())/len(v.link_edges) for v in relax}
    for v,position in positions.items():
        neck=smooth_transition(1.45,1.53,v.co.z)*(1-smooth_transition(.20,.28,abs(v.co.x)))
        shoulder=smooth_transition(.13,.19,abs(v.co.x))*(1-smooth_transition(.32,.40,abs(v.co.x)))
        shoulder*=smooth_transition(1.30,1.40,v.co.z)*(1-smooth_transition(1.62,1.70,v.co.z))
        v.co=v.co.lerp(position,.40*max(neck,shoulder))
bm.to_mesh(shirt.data);bm.free()

# Fit shoulder fabric before adding thickness, and refresh weights after moving it.
# This avoids skin triangles protruding through the smoothed clavicle region.
for vertex in shirt.data.vertices:
    if vertex.co.z>1.47:
        hit,normal,index,distance=body_tree.find_nearest(vertex.co)
        margin=.012*smooth_transition(1.47,1.55,vertex.co.z)
        if (vertex.co-hit).dot(normal)<margin:
            vertex.co=hit+normal*margin
        for group_index in [g.group for g in vertex.groups]:shirt.vertex_groups[group_index].remove([vertex.index])
        for name,weight in sampled_weights(hit,index).items():shirt.vertex_groups[name].add([vertex.index],weight,'REPLACE')

# A smooth, broad cloth surface replaces inherited sternum/nipple spikes.
# Fit only the frontal torso, preserving X/Z, neckline, sleeves and skin weights.
front=[v for v in shirt.data.vertices if abs(v.co.x)<.205 and 1.15<v.co.z<1.52 and v.co.y<-.035]
def chest_basis(co):
    z=co.z-1.34;x=co.x
    return [1.,x*x,z,z*z,z*z*z,x*x*z]
A=np.array([chest_basis(v.co) for v in front]);values=np.array([v.co.y for v in front])
keep=np.ones(len(front),dtype=bool)
for iteration in range(3):
    coefficients=np.linalg.lstsq(A[keep],values[keep],rcond=None)[0]
    residual=np.abs(values-A@coefficients)
    keep=residual<max(.006,float(np.median(residual))*3.)
for vertex in front:
    co=vertex.co
    weight=(1-smooth_transition(.150,.205,abs(co.x)))*smooth_transition(1.15,1.23,co.z)*(1-smooth_transition(1.46,1.52,co.z))
    target=float(np.array(chest_basis(co))@coefficients)
    co.y=co.y*(1-weight)+target*weight
shirt.data.update()

# Anchor the tucked hem to the pelvis. Inherited thigh weights lifted it away
# from the shorts during high kicks and exposed the removed torso interior.
for vertex in shirt.data.vertices:
    if vertex.co.z<1.15:
        blend=max(0.,min(1.,(1.15-vertex.co.z)/.07))
        previous={shirt.vertex_groups[g.group].name:g.weight for g in vertex.groups}
        for group_index in [g.group for g in vertex.groups]:shirt.vertex_groups[group_index].remove([vertex.index])
        result={name:weight*(1-blend) for name,weight in previous.items()}
        result['Hips']=result.get('Hips',0)+blend
        for name,weight in result.items():
            if weight:shirt.vertex_groups[name].add([vertex.index],weight,'REPLACE')

# Keep the actual shirt opening as the outer binding edge. Sampling a separate
# circle left triangular gaps between this edge and the fitted collar.
bm=bmesh.new();bm.from_mesh(shirt.data)
neck_vertices={vertex for edge in bm.edges if edge.is_boundary for vertex in edge.verts if vertex.co.z>1.53 and abs(vertex.co.x)<.23}
neck_loop=ordered_boundary(neck_vertices)
deform=bm.verts.layers.deform.active
neck_edge=[(vertex.co.copy(),{shirt.vertex_groups[index].name:weight for index,weight in vertex[deform].items()}) for vertex in neck_loop]
bm.free()
if len(neck_edge)<12:raise RuntimeError('Incomplete jersey neckline')

# Small fabric rims close cuffs and neckline without oversized primitive bands.
for obj in [shirt,short,sock]:
    obj.data.materials.append(trim)
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('Fabric thickness and hems','SOLIDIFY');mod.thickness=.001 if obj==shirt else .0025;mod.offset=1. if obj==shirt else -1.;mod.material_offset_rim=0 if obj in [short,shirt] else 1
    bpy.ops.object.modifier_apply(modifier=mod.name)
    if obj==shirt:
        for face in obj.data.polygons:
            if face.material_index==1 and face.center.z>1.53:face.material_index=0
# Tapered athletic haircut: natural temple line, short sides and swept top.
def hairline(c):
    front=max(0.,min(1.,(-c.y+.01)/.07))
    temple=max(0.,min(1.,(abs(c.x)-.055)/.035))
    return 1.755+front*(.069-.045*temple)+.003*math.cos(c.x*70)
haircap=garment('Tapered haircut',lambda c:c.z>hairline(c),material('HairScalp',(.045,.032,.025)),.0003,0)
bm=bmesh.new();bm.from_mesh(haircap.data)
for vertex in bm.verts:
    if any(edge.is_boundary for edge in vertex.link_edges):vertex.co.z=hairline(vertex.co)
bm.to_mesh(haircap.data);bm.free()
for vertex in haircap.data.vertices:
    c=vertex.co
    top=max(0.,min(1.,(c.z-1.82)/.06))
    front=max(0.,min(1.,(-c.y+.025)/.09))
    # Root layer stays below the actual textured hair mesh.
    c.z+=.0001*top
# Use the primary color channel shared by the joined body, not COLOR_1.
color_name=human.data.color_attributes[0].name if human.data.color_attributes else 'Color'
for attribute in list(haircap.data.color_attributes):haircap.data.color_attributes.remove(attribute)
fade=haircap.data.color_attributes.new(name=color_name,type='FLOAT_COLOR',domain='CORNER')
haircap.data.color_attributes.active_color=fade
for li,loop in enumerate(haircap.data.loops):
    co=haircap.data.vertices[loop.vertex_index].co
    depth=co.z-hairline(co)
    coverage=max(0.,min(1.,depth/.025))
    # Side hair blends into the skin; the top remains full coverage.
    if co.y<-.045 and abs(co.x)<.070:
        coverage=.78+.22*coverage
    else:coverage=.03+.97*coverage
    fade.data[li].color=(coverage,coverage,coverage,1)

# Remove the anatomical skin covered by kit (including internal genital surfaces).
bm=bmesh.new();bm.from_mesh(human.data)
covered=[]
for face in bm.faces:
    c=face.calc_center_median()
    torso=1.015<c.z<1.585 and abs(c.x)<.21
    sleeve=False
    if abs(c.x)>.21 and 1.1<c.z<1.68:
        origin,axis=sleeve_axis(c)
        sleeve=(c-origin).dot(axis)<.145
    if (SHORT_HEM+.020<c.z<1.075 and abs(c.x)<.30) or torso or sleeve or (.105<c.z<.545 and abs(c.x)<.30) or c.z<.145: covered.append(face)
bmesh.ops.delete(bm,geom=covered,context='FACES')
bmesh.ops.delete(bm,geom=[vert for vert in bm.verts if not vert.link_faces],context='VERTS')
# Extend exposed skin to the straight garment openings. Face-center masking
# alone leaves stepped edges and gaps around knees and the neckline.
edges={edge for edge in bm.edges if edge.is_boundary}
while edges:
    edge=edges.pop();loop=set(edge.verts);pending=list(edge.verts)
    while pending:
        vertex=pending.pop()
        for linked in vertex.link_edges:
            if linked in edges:
                edges.remove(linked)
                for other in linked.verts:
                    if other not in loop:loop.add(other);pending.append(other)
    center=sum((vertex.co for vertex in loop),Vector())/len(loop)
    if SHORT_HEM-.01<center.z<.86:
        deform=bm.verts.layers.deform.verify()
        group=human.vertex_groups['Thigh.R' if center.x>0 else 'Thigh.L'].index
        for vertex in loop:
            vertex.co.z=SHORT_HEM+.014;vertex[deform].clear();vertex[deform][group]=1.
    elif .48<center.z<.60:
        deform=bm.verts.layers.deform.verify()
        group=human.vertex_groups['Shin.R' if center.x>0 else 'Shin.L'].index
        for vertex in loop:
            vertex.co.z=.536;vertex[deform].clear();vertex[deform][group]=1.
    elif 1.20<center.z<1.50 and abs(center.x)>.21:
        sleeve=shirt
        bone=rig.data.bones['UpperArm.R' if center.x>0 else 'UpperArm.L']
        axis=(bone.tail_local-bone.head_local).normalized()
        cuff=bone.head_local+axis*.16
        deform=bm.verts.layers.deform.verify()
        for vertex in loop:
            vertex.co-=axis*((vertex.co-cuff).dot(axis)+.008)
            vertex[deform].clear();vertex[deform][human.vertex_groups[bone.name].index]=1.
bm.to_mesh(human.data);bm.free()
# A narrow ribbed binding follows the same surface and weights as the skin.
vertices=[];faces=[];collar_weights=[]
# Subdivide each garment edge without changing its outline. Intermediate rib
# vertices follow skin relief instead of cutting through the clavicles.
dense_edge=[]
def mix_weights(a,b,t):
    return {name:a.get(name,0)*(1-t)+b.get(name,0)*t for name in a.keys()|b.keys()}
for i,(edge,groups) in enumerate(neck_edge):
    following,next_groups=neck_edge[(i+1)%len(neck_edge)]
    for step in range(4):
        point=edge.lerp(following,step/4)
        dense_edge.append((point,math.atan2(point.y+.035,point.x),mix_weights(groups,next_groups,step/4)))
count=len(dense_edge)
rows=[(t,False) for t in [0,.25,.5,.75,1]]+[(t,True) for t in [1,.75,.5,.25,0]]
for t,lower in rows:
    for edge,angle,edge_groups in dense_edge:
        inner,inner_groups=neckline_point(angle)
        co=inner.lerp(edge,t)
        hit,normal,index,distance=body_tree.find_nearest(co)
        if t<1 and (co-hit).dot(normal)<.006:co=hit+normal*.006
        groups=mix_weights(inner_groups,edge_groups,t)
        if lower:co.z-=.0025
        vertices.append(tuple(co));collar_weights.append(groups)
for row in range(len(rows)):
    for i in range(count):faces.append((row*count+i,row*count+(i+1)%count,((row+1)%len(rows))*count+(i+1)%count,((row+1)%len(rows))*count+i))
mesh=bpy.data.meshes.new('Anatomically fitted collar');mesh.from_pydata(vertices,[],faces);mesh.update()
bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
collar=bpy.data.objects.new('Collar binding',mesh);bpy.context.collection.objects.link(collar);collar.parent=rig;mesh.materials.append(jersey)
for name in sorted({name for groups in collar_weights for name in groups}):collar.vertex_groups.new(name=name)
for i,groups in enumerate(collar_weights):
    for name,weight in groups.items():collar.vertex_groups[name].add([i],weight,'REPLACE')
uv=mesh.uv_layers.new(name='UVMap');blank=mesh.uv_layers.new(name='JerseyPrintUV')
for face in mesh.polygons:
    face.use_smooth=True
    for li in face.loop_indices:
        co=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(co.x*2+.5,co.z*.8);blank.data[li].uv=(-2,-2)
mod=collar.modifiers.new('Collar skinning','ARMATURE');mod.object=rig
# Close-trimmed beard made of actual short bristles; no dark translucent face shell.
human.data.calc_loop_triangles()
candidates=[]
for triangle in human.data.loop_triangles:
    co=sum((human.data.vertices[i].co for i in triangle.vertices),Vector())/3
    # Jaw/chin, tapered cheeks and a narrow moustache; keep lips clear.
    jaw=1.633<co.z<1.686 and co.y<-.035
    cheek=1.674<co.z<1.730 and .038<abs(co.x)<.093 and co.y<-.025
    moustache=1.707<co.z<1.721 and abs(co.x)<.043 and co.y<-.070
    if jaw or cheek or moustache:candidates.append(triangle)
vertices=[];faces=[];bristle_weights=[]
rng=random.Random(3108)
areas=[triangle.area for triangle in candidates]
for triangle in rng.choices(candidates,weights=areas,k=6000):
    a,b=rng.random(),rng.random()
    if a+b>1:a,b=1-a,1-b
    bary=[1-a-b,a,b]
    points=[human.data.vertices[i] for i in triangle.vertices]
    co=sum((point.co*weight for point,weight in zip(points,bary)),Vector())
    normal=triangle.normal.normalized()
    # Fade the cheek line by thinning strands near its upper edge.
    if co.z>1.693 and abs(co.x)>.043 and rng.random()<max(0.,(co.z-1.69)/.04):continue
    tangent=normal.cross(Vector((0,0,1))).normalized()
    if tangent.length<.1:tangent=Vector((1,0,0))
    radius=rng.uniform(.00015,.00024)
    length=rng.uniform(.0010,.0027)
    base=co+normal*.00025;tip=base+normal*length+Vector((0,0,-length*.25))
    start=len(vertices)
    vertices.extend([tuple(base+tangent*radius),tuple(base-tangent*radius),tuple(tip)])
    faces.append((start,start+1,start+2))
    groups={}
    for point,weight in zip(points,bary):
        for group in point.groups:
            name=human.vertex_groups[group.group].name
            if name in rig.data.bones:groups[name]=groups.get(name,0)+weight*group.weight
    bristle_weights.extend([groups]*3)
mesh=bpy.data.meshes.new('Trimmed beard bristles');mesh.from_pydata(vertices,[],faces);mesh.update()
beard=bpy.data.objects.new('Beard',mesh);bpy.context.collection.objects.link(beard);beard.parent=rig
mesh.materials.append(material('Beard',(.07,.045,.025),False,.92))
for name in sorted({name for groups in bristle_weights for name in groups}):beard.vertex_groups.new(name=name)
for i,groups in enumerate(bristle_weights):
    for name,weight in groups.items():beard.vertex_groups[name].add([i],weight,'REPLACE')
mod=beard.modifiers.new('Beard skinning','ARMATURE');mod.object=rig
mesh.uv_layers.new(name='UVMap')

# Normalize names and combine visible surfaces while keeping optional beard separate.
all_parts=[human,*parts[1:],shirt,collar,short,sock,boot,haircap]
for obj in all_parts:
    first=obj.data.uv_layers[0];first.name='UVMap'
    for layer in list(obj.data.uv_layers)[1:]:
        if layer.name!='JerseyPrintUV':obj.data.uv_layers.remove(layer)
    if obj.data.uv_layers.get('JerseyPrintUV') is None:
        layer=obj.data.uv_layers.new(name='JerseyPrintUV')
        for loop in layer.data:loop.uv=(-2,-2)
    for modifier in list(obj.modifiers):
        if modifier.type!='ARMATURE': obj.modifiers.remove(modifier)
    for p in obj.data.polygons:p.use_smooth=True
bpy.ops.object.select_all(action='DESELECT')
for obj in all_parts:obj.select_set(True)
bpy.context.view_layer.objects.active=human;bpy.ops.object.join()
human.name='FootballerBody'

# Retarget source clips with basis correction, preserving timing and anatomical rig.
with bpy.data.libraries.load(str(SOURCE/'goalkeeper_v2.blend'),link=False) as (src,dst):
    dst.objects=[name for name in src.objects if name=='FootballerRig']
    dst.actions=[name for name in src.actions if name.split('.')[0] in ['Idle','Kick','Celebrate','Catch','SaveLeft','SaveRight','SaveLowLeft','SaveLowRight']]
old=dst.objects[0]
bpy.context.collection.objects.link(old)
old.name='AnimationSource'
old_actions=[track.strips[0].action for track in old.animation_data.nla_tracks if track.strips]
if old.animation_data.action not in old_actions:old_actions.append(old.animation_data.action)
# The keeper save actions also exist in the file but are not all in NLA.
old_actions=[a for a in bpy.data.actions if a.name.split('.')[0] in ['Idle','Kick','Celebrate','Catch','SaveLeft','SaveRight','SaveLowLeft','SaveLowRight']]
rig.animation_data_create();scene=bpy.context.scene;scene.render.fps=30
clips=[]
ik_targets={}
for side in ['L','R']:
    target=bpy.data.objects.new('HandContact.'+side,None);bpy.context.collection.objects.link(target)
    constraint=rig.pose.bones['Forearm.'+side].constraints.new('IK')
    constraint.target=target;constraint.chain_count=2;constraint.use_tail=True
    ik_targets[side]=target
for action in old_actions:
    name=action.name.split('.')[0];start,end=(round(t) for t in action.frame_range)
    old.animation_data.action=action
    for target in ik_targets.values():target.animation_data_clear()
    new=bpy.data.actions.new(name+'_v3');rig.animation_data.action=new
    for frame in range(start,end+1):
        scene.frame_set(frame)
        for pb in rig.pose.bones:
            pb.rotation_mode='QUATERNION'
            if pb.name in old.pose.bones:
                source=old.pose.bones[pb.name]
                correction=pb.bone.matrix_local.to_quaternion().inverted()@source.bone.matrix_local.to_quaternion()
                pb.rotation_quaternion=correction@source.rotation_euler.to_quaternion()@correction.inverted()
            else:pb.rotation_quaternion=(1,0,0,0)
            pb.keyframe_insert('rotation_quaternion',frame=frame,group=pb.name)
        for side,target in ik_targets.items():
            target.location=old.pose.bones['Hand.'+side].matrix.translation
            target.keyframe_insert('location',frame=frame)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    bpy.ops.nla.bake(frame_start=start,frame_end=end,only_selected=False,visual_keying=True,clear_constraints=False,use_current_action=True,bake_types={'POSE'})
    clips.append((name,new))
for pb in rig.pose.bones:
    for constraint in list(pb.constraints):pb.constraints.remove(constraint)
for target in ik_targets.values():bpy.data.objects.remove(target,do_unlink=True)
rig.animation_data.action=None
for name,action in clips:
    action.name=name+'_v3'
    track=rig.animation_data.nla_tracks.new();track.name=name;track.strips.new(name,1,action);track.mute=True
bpy.data.objects.remove(old,do_unlink=True)
# Remove unused old actions so export never contains duplicate clip names.
for action in old_actions:
    action.use_fake_user=False
    if action.users==0:bpy.data.actions.remove(action)
rig.animation_data.action=dict(clips)['Idle'];scene.frame_set(1)
# Pack and preserve all licensed source images in the editable source.
for image in bpy.data.images:
    if image.source=='FILE' and image.has_data:image.pack()

for role in ['footballer','goalkeeper']:
    glove_obj=None
    if role=='goalkeeper':
        # Anatomical fingers and thumb are real mesh, enlarged slightly for gloves.
        # Read from the uncut anatomical source saved before kit filtering.
        glove_obj=garment('Gloves',lambda c:abs(c.x)>.49 and c.z<1.22 and c.z>.86,gloves,.006,2)
        bpy.ops.object.select_all(action='DESELECT');human.select_set(True);glove_obj.select_set(True)
        bpy.context.view_layer.objects.active=human;bpy.ops.object.join()
    # Ship only rig groups. MPFB helper masks can contain negative weights after
    # subdivision; they are not deformation influences and must not remain in
    # the editable delivery. Match the four-influence GLB/runtime contract.
    for group in list(human.vertex_groups):
        if group.name not in rig.data.bones:human.vertex_groups.remove(group)
    for vertex in human.data.vertices:
        influences=sorted([(g.group,max(0.,g.weight)) for g in vertex.groups],key=lambda item:item[1],reverse=True)[:4]
        total=sum(weight for group,weight in influences)
        for group_index in [g.group for g in vertex.groups]:human.vertex_groups[group_index].remove([vertex.index])
        if total:
            for group,weight in influences:
                if weight:human.vertex_groups[group].add([vertex.index],weight/total,'REPLACE')
    if human.data.validate(verbose=True,clean_customdata=False):
        raise RuntimeError('Unexpected mesh repair after cleaning rig weights')
    if human.data.color_attributes:
        human.data.color_attributes.active_color_index=0
        human.data.color_attributes.render_color_index=0
    if human.data.color_attributes:
        color=human.data.color_attributes[0]
        for polygon in human.data.polygons:
            if human.data.materials[polygon.material_index].name!='HairScalp':
                for li in polygon.loop_indices:color.data[li].color=(1,1,1,1)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(role+'_v3.blend')))
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);human.select_set(True);beard.select_set(True)
    bpy.context.view_layer.objects.active=rig
    bpy.ops.export_scene.gltf(filepath=str(OUT/(role+'_v3.glb')),export_format='GLB',export_vertex_color='ACTIVE',export_all_vertex_colors=False,use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_apply=False,export_yup=True,export_skins=True,export_all_influences=False)
    print('V3_EXPORT',role,len(human.data.vertices),len(human.data.polygons),len(rig.data.bones),flush=True)

# Apply the same source refinements to both shared models and all their profiles.
import importlib.util
sys.dont_write_bytecode = True
for role in ['footballer', 'goalkeeper']:
    for module_name in ['tailor_footballer_jersey', 'tailor_footballer_shorts',
                        'tailor_footballer_sleeves', 'athletic_footballer']:
        spec = importlib.util.spec_from_file_location(module_name, APP/'tools'/(module_name+'.py'))
        tailoring = importlib.util.module_from_spec(spec); spec.loader.exec_module(tailoring)
        tailoring.tailor(SOURCE/(role+'_v3.blend'), role)
