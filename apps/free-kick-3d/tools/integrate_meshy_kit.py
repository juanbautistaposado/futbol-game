"""Fit Meshy clothing to the existing rig; preserve the anatomical body and clips.

blender -b --python apps/free-kick-3d/tools/integrate_meshy_kit.py -- footballer
Exports a v4 candidate under the trial integration directory, never over v3.
"""
import bpy, bmesh, math, json, hashlib, sys
import numpy as np
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[3]
SOURCE=ROOT/'source-assets/footballer'
TRIAL=SOURCE/'meshy-trial-2026-10-06'
OUT=TRIAL/'integration'
TEXTURES=ROOT/'apps/free-kick-3d/assets/footballer/textures/meshy'
REPORT=ROOT/'docs/research/meshy-trial-2026-10-06'
OUT.mkdir(exist_ok=True);TEXTURES.mkdir(parents=True,exist_ok=True)
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
role=args[0] if args else 'footballer'
assert role in ['footballer','goalkeeper']

def smooth(a,b,x):
 t=max(0.,min(1.,(x-a)/(b-a)));return t*t*(3-2*t)

def snapshot(body,rig):
 faces=[];bindings={'Jersey':[],'Shorts':[]}
 for p in body.data.polygons:
  name=body.data.materials[p.material_index].name
  if name in bindings:
   bindings[name].append([[sorted((body.vertex_groups[g.group].name,round(g.weight,7)) for g in body.data.vertices[body.data.loops[li].vertex_index].groups),list(body.data.uv_layers['UVMap'].data[li].uv),list(body.data.uv_layers['JerseyPrintUV'].data[li].uv)] for li in p.loop_indices])
   continue
  corners=[]
  for li in p.loop_indices:
   v=body.data.vertices[body.data.loops[li].vertex_index]
   weights=sorted((body.vertex_groups[g.group].name,round(g.weight,7)) for g in v.groups)
   corners.append([list(v.co),weights,list(body.data.uv_layers['UVMap'].data[li].uv),list(body.data.uv_layers['JerseyPrintUV'].data[li].uv)])
  faces.append([name,corners])
 digest=lambda x:hashlib.sha256(json.dumps(x,sort_keys=True).encode()).hexdigest()
 bones={b.name:[list(row) for row in b.matrix_local] for b in rig.data.bones}
 actions={}
 for action in bpy.data.actions:
  curves=[]
  for layer in action.layers:
   for strip in layer.strips:
    for bag in strip.channelbags:
     for curve in bag.fcurves:
      curves.append([curve.data_path,curve.array_index,[[list(k.co),k.interpolation] for k in curve.keyframe_points]])
  actions[action.name]=digest(curves)
 return {'protected_faces':digest(faces),'protected_face_count':len(faces),'garment_weights_and_uv':{name:digest(data) for name,data in bindings.items()},'bones':digest(bones),'actions':actions}

bpy.ops.wm.open_mainfile(filepath=str(SOURCE/f'{role}_v3.blend'))
body=bpy.data.objects['FootballerBody'];rig=bpy.data.objects['FootballerRig']
before=snapshot(body,rig)
source_coords=[v.co.copy() for v in body.data.vertices]
body.data.calc_loop_triangles()
skin_triangles=[tuple(t.vertices) for t in body.data.loop_triangles if body.data.materials[body.data.polygons[t.polygon_index].material_index].name=='Skin']
trees={'Skin':BVHTree.FromPolygons(source_coords,skin_triangles,all_triangles=True)}

old_materials={m.name:m for m in body.data.materials}
old_objects=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=str(TRIAL/'meshy-lite-raw.glb'))
raw=next(o for o in bpy.data.objects if o not in old_objects and o.type=='MESH')
bpy.context.view_layer.objects.active=raw
bpy.ops.object.select_all(action='DESELECT');raw.select_set(True)
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
minimum=min(v.co.z for v in raw.data.vertices);height=max(v.co.z for v in raw.data.vertices)-minimum
for v in raw.data.vertices:v.co.z-=minimum;v.co*=1.898873/height
base=next(n.image for n in raw.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE' and n.image.colorspace_settings.name=='sRGB')
w,h=base.size;pixels=np.array(base.pixels[:],dtype=np.float32).reshape(h,w,4)
raw.data.uv_layers[0].name='UVMap'
uv=raw.data.uv_layers[0]

def color_of(p):
 c=np.zeros(3)
 for li in p.loop_indices:
  xy=uv.data[li].uv
  c+=pixels[int(xy.y*(h-1))%h,int(xy.x*(w-1))%w,:3]
 return c/len(p.loop_indices)

labels=[]
for p in raw.data.polygons:
 co=sum((raw.data.vertices[i].co for i in p.vertices),Vector())/len(p.vertices)
 r,g,b=color_of(p);skin=r>g*1.17 and b<g*.97
 name=None
 if not skin and .955<co.z<1.65:
  if (r+g+b)/3>.19 or co.z>1.10:name='Jersey'
 if not skin and .67<co.z<1.085 and name is None:name='Shorts'
 labels.append(name)

def make_image(name,array,noncolor=False,persist=True):
 image=bpy.data.images.new(name,width=array.shape[1],height=array.shape[0],alpha=True)
 if noncolor:image.colorspace_settings.name='Non-Color'
 image.pixels.foreach_set(array.astype(np.float32).ravel())
 image.scale(1024,1024)
 if persist:
  image.filepath_raw=str(TEXTURES/(name+'.png'));image.file_format='PNG';image.save()
 return image

lum=pixels[:,:,:3].mean(axis=2)
light=np.ones_like(pixels)
values=.68+.30*np.sqrt(np.clip(lum,0,1))
light[:,:,:3]=values[:,:,None]
lightmap=make_image('meshy_jersey_neutral',light,persist=False)
dark=np.ones_like(pixels);dark[:,:,:3]=np.clip(.65+.23*np.sqrt(np.clip(lum/.018,0,2)),.65,.96)[:,:,None]
darkmap=make_image('meshy_shorts_neutral',dark,persist=False)
rough=np.ones_like(pixels);rough[:,:,:3]=.88
roughmap=make_image('meshy_cloth_roughness',rough,True)
raw_bs=raw.data.materials[0].node_tree.nodes.get('Principled BSDF')
normal_node=raw_bs.inputs['Normal'].links[0].from_node
normal_source=normal_node.inputs['Color'].links[0].from_node.image
normal_pixels=np.array(normal_source.pixels[:],dtype=np.float32).reshape(h,w,4)
normalmap=make_image('meshy_cloth_normal',normal_pixels,True,persist=False)

for region,albedo in [('Jersey',lightmap),('Shorts',darkmap)]:
 material=old_materials[region];nodes=material.node_tree.nodes;links=material.node_tree.links
 bs=nodes.get('Principled BSDF')
 for socket,image in [('Base Color',albedo),('Roughness',roughmap)]:
  for link in list(bs.inputs[socket].links):links.remove(link)
  node=nodes.new('ShaderNodeTexImage');node.image=image;links.new(node.outputs['Color'],bs.inputs[socket])
 for link in list(bs.inputs['Normal'].links):links.remove(link)
 node=nodes.new('ShaderNodeTexImage');node.image=normalmap
 normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.35
 links.new(node.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bs.inputs['Normal'])

garments=[];measurements={}
for region in ['Jersey','Shorts']:
 obj=raw.copy();obj.data=raw.data.copy();bpy.context.collection.objects.link(obj);obj.name='Meshy'+region
 bm=bmesh.new();bm.from_mesh(obj.data)
 bmesh.ops.delete(bm,geom=[f for f in bm.faces if labels[f.index]!=region],context='FACES')
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
 bm.to_mesh(obj.data);bm.free()
 obj.data.materials.clear();obj.data.materials.append(old_materials[region])
 for p in obj.data.polygons:p.material_index=0;p.use_smooth=True
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 mod=obj.modifiers.new('Meshy clothing simplification','DECIMATE');mod.ratio=.65
 bpy.ops.object.modifier_apply(modifier=mod.name)
 bm=bmesh.new();bm.from_mesh(obj.data)
 boundary={v for e in bm.edges if e.is_boundary for v in e.verts}
 for v in bm.verts:
  co=v.co.copy()
  if region=='Jersey':
   # Bring the neckline to the original neck, then fit sleeves to upper-arm axes.
   co.z+=.015+.015*smooth(1.40,1.60,co.z)
   co.y-=.020*(1-smooth(1.46,1.60,co.z))
   sign=1 if co.x>0 else -1;side='R' if sign>0 else 'L'
   origin=Vector((sign*.198,-.02,1.520));axis=Vector((sign*.13,0,-.29))
   bone=rig.data.bones['UpperArm.'+side];target=bone.tail_local-bone.head_local
   mapped=bone.head_local+axis.rotation_difference(target)@(co-origin)*(target.length/axis.length)
   influence=smooth(.14,.245,abs(co.x))
   co=co.lerp(mapped,influence)
  else:
   co.y-=.025
   # Lower the inner crotch while fading to zero at the continuous waistband.
   co.z-=.105*(1-smooth(.91,1.04,co.z))*(1-smooth(.025,.115,abs(co.x)))*smooth(.695,.815,co.z)
   if v in boundary and co.z<.85:
    co.z=.695+.014*(1-smooth(.015,.060,abs(co.x)))
  v.co=co
 bm.normal_update();bm.to_mesh(obj.data);bm.free()
 # Match the existing muscle envelope where skin is exposed at cuffs/hem.
 for vertex in obj.data.vertices:
  co=vertex.co
  side='R' if co.x>0 else 'L'
  bone=rig.data.bones[('UpperArm.' if region=='Jersey' else 'Thigh.')+side]
  axis=bone.tail_local-bone.head_local
  t=(co-bone.head_local).dot(axis)/axis.length_squared
  relevant=(region=='Jersey' and abs(co.x)>.255 and .40<t<.9) or (region=='Shorts' and .685<co.z<.77 and abs(co.x)>.045)
  if not relevant:continue
  center=bone.head_local+axis*t
  radial=co-center
  if region=='Shorts':
   center=bone.head_local+axis*((co.z-bone.head_local.z)/axis.z);radial=co-center;radial.z=0
  if radial.length<.01:continue
  direction=radial.normalized();samples=[]
  for delta in [-.025,0,.025]:
   origin=center+axis.normalized()*delta
   hit,n,index,distance=trees['Skin'].ray_cast(origin,direction,.25)
   if hit is not None:samples.append(distance)
  if samples and max(samples)+.009>radial.length:
   vertex.co=center+direction*(max(samples)+.009)
 # Retopologize onto the clean existing garment. Meshy's automatic segmentation
 # has ragged boundaries; keep the continuous collar/cuffs/waist/hem and the
 # proven four-bone deformation layout instead of shipping those cut edges.
 obj.data.calc_loop_triangles()
 source_triangles=list(obj.data.loop_triangles)
 source_positions=[v.co.copy() for v in obj.data.vertices]
 source_uv=obj.data.uv_layers['UVMap']
 cloth_tree=BVHTree.FromPolygons(source_positions,[tuple(t.vertices) for t in source_triangles],all_triangles=True)
 clean=body.copy();clean.data=body.data.copy();bpy.context.collection.objects.link(clean)
 clean.name='RetopologizedMeshy'+region
 bm=bmesh.new();bm.from_mesh(clean.data)
 bmesh.ops.delete(bm,geom=[f for f in bm.faces if clean.data.materials[f.material_index].name!=region],context='FACES')
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
 rim={v for e in bm.edges if e.is_boundary for v in e.verts}
 fixed=set(rim)
 for v in list(rim):fixed.update(e.other_vert(v) for e in v.link_edges)
 for v in bm.verts:
  if region=='Jersey' and (v.co.z<1.018 or (v.co.z>1.59 and abs(v.co.x)<.14) or (v.co.z>1.28 and abs(v.co.x)>.14)):fixed.add(v)
  if region=='Shorts' and (v.co.z<.725 or v.co.z>1.06):fixed.add(v)
 bm.normal_update()
 for v in bm.verts:
  original=v.co.copy()
  hit,n,index,distance=cloth_tree.find_nearest(original)
  if hit is None or distance>.10 or v in fixed:continue
  # Keep a smooth silhouette and a restrained amount of the generated folds.
  delta=hit-original
  limit=.035 if region=='Jersey' else .018
  if region=='Jersey':
   limit*=.45+.55*smooth(1.04,1.18,original.z)
   limit*=1-smooth(.085,.14,abs(original.x))*smooth(1.25,1.28,original.z)
  if delta.length>limit:delta*=limit/delta.length
  inward=delta.dot(v.normal)
  skin_hit,skin_normal,skin_index,skin_distance=trees['Skin'].find_nearest(original)
  if inward<0 and skin_distance<.035:delta-=v.normal*inward
  v.co+=delta*.80
 for iteration in range(4):
  bmesh.ops.smooth_vert(bm,verts=[v for v in bm.verts if v not in fixed],factor=.25,use_axis_x=True,use_axis_y=True,use_axis_z=True)
 bm.normal_update();bm.to_mesh(clean.data);bm.free()
 # Bake each texel by surface position onto the existing continuous UV atlas.
 # Interpolating Meshy's unrelated UV islands across a retopology face would
 # create black seams. UV2 and the original skin weights remain unchanged.
 size=1024;atlas=np.ones((size,size,4),dtype=np.float32);atlas[:,:,:3]=.85
 old_uv=clean.data.uv_layers['UVMap'];clean.data.calc_loop_triangles()
 for triangle in clean.data.loop_triangles:
  triangle_uv=np.array([list(old_uv.data[li].uv) for li in triangle.loops])*(size-1)
  for tile_shift in [-1,0,1]:
   a,b,c=triangle_uv+np.array([tile_shift*(size-1),0])
   denominator=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
   if abs(denominator)<1e-9:continue
   lo=np.maximum(np.floor(np.minimum(np.minimum(a,b),c)).astype(int),0)
   hi=np.minimum(np.ceil(np.maximum(np.maximum(a,b),c)).astype(int),size-1)
   if np.any(hi<lo):continue
   yy,xx=np.mgrid[lo[1]:hi[1]+1,lo[0]:hi[0]+1]
   f0=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/denominator
   f1=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/denominator
   f2=1-f0-f1
   mask=(f0>=-1e-6)&(f1>=-1e-6)&(f2>=-1e-6)
   positions=np.array([list(clean.data.vertices[i].co) for i in triangle.vertices])
   for x,y,q0,q1,q2 in zip(xx[mask],yy[mask],f0[mask],f1[mask],f2[mask]):
    co=Vector(positions[0]*q0+positions[1]*q1+positions[2]*q2)
    hit,n,index,distance=cloth_tree.find_nearest(co)
    source_triangle=source_triangles[index]
    a,b,c=[source_positions[i] for i in source_triangle.vertices]
    v0=b-a;v1=c-a;v2=hit-a
    d00=v0.dot(v0);d01=v0.dot(v1);d11=v1.dot(v1);d20=v2.dot(v0);d21=v2.dot(v1)
    denominator=d00*d11-d01*d01
    if abs(denominator)<1e-15:factors=[1.,0.,0.]
    else:
     u=(d11*d20-d01*d21)/denominator;v=(d00*d21-d01*d20)/denominator
     factors=[1-u-v,u,v]
    sampled_uv=sum((source_uv.data[loop].uv*factor for loop,factor in zip(source_triangle.loops,factors)),Vector((0.,0.)))
    rgb=(light if region=='Jersey' else dark)[int(sampled_uv.y*(h-1))%h,int(sampled_uv.x*(w-1))%w,:3]
    # The shared Meshy atlas contains black shorts beside the shirt. Keep those
    # samples neutral; author the thin collar from its fitted surface position.
    atlas[y,x,:3]=rgb
 if region=='Jersey':
  # The existing collar owns the top strip of the atlas; sleeves use .72-.90.
  atlas[int(size*.95):,:,:3]=.50
  atlas[:int(size*.08),:,:3]=.90
  atlas[int(size*.885):int(size*.905),:,:3]*=.82
 baked=make_image(role+'_meshy_'+region.lower()+'_neutral',atlas)
 material=old_materials[region];nodes=material.node_tree.nodes
 bs=nodes.get('Principled BSDF')
 bs.inputs['Base Color'].links[0].from_node.image=baked
 # Derive a restrained tangent-space cloth relief in this atlas, without using
 # Meshy's normals in an incompatible UV tangent basis.
 heightmap=np.clip(atlas[:,:,:3].mean(axis=2),.70,1.)
 for iteration in range(3):
  heightmap=(heightmap+np.roll(heightmap,1,0)+np.roll(heightmap,-1,0)+np.roll(heightmap,1,1)+np.roll(heightmap,-1,1))/5
 gy,gx=np.gradient(heightmap)
 normal_atlas=np.ones_like(atlas);normal_atlas[:,:,0]=.5-np.clip(gx*8,-.22,.22);normal_atlas[:,:,1]=.5-np.clip(gy*8,-.22,.22);normal_atlas[:,:,2]=1
 baked_normal=make_image(role+'_meshy_'+region.lower()+'_normal',normal_atlas,True)
 bs.inputs['Normal'].links[0].from_node.inputs['Color'].links[0].from_node.image=baked_normal
 clean.data.update()
 bpy.data.objects.remove(obj,do_unlink=True);obj=clean
 measurements[region]={'vertices':len(obj.data.vertices),'polygons':len(obj.data.polygons),'min_z':min(v.co.z for v in obj.data.vertices),'max_z':max(v.co.z for v in obj.data.vertices)}
 garments.append(obj)

# Keep every original body/face/hair/sock/boot/glove face and its existing weights.
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if body.data.materials[f.material_index].name in ['Jersey','Shorts']],context='FACES')
bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
bm.to_mesh(body.data);bm.free()
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
for obj in garments:obj.select_set(True)
bpy.context.view_layer.objects.active=body;bpy.ops.object.join()
bpy.data.objects.remove(raw,do_unlink=True)
after=snapshot(body,rig)
assert before==after,'Protected body geometry, weights, UVs, bones or animations changed'
assert not body.data.validate(verbose=True,clean_customdata=False)
body['mesh_revision']='meshy-kit-v4-2026-10-06'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.make_paths_relative()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/f'{role}_v4.blend'))
bpy.ops.object.select_all(action='DESELECT')
for obj in [rig,body,bpy.data.objects['Beard']]:obj.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT/f'{role}_v4.glb'),export_format='GLB',
 export_vertex_color='ACTIVE',export_all_vertex_colors=False,use_selection=True,
 export_animations=True,export_animation_mode='NLA_TRACKS',export_apply=False,
 export_yup=True,export_skins=True,export_all_influences=False)
report={'role':role,'source':'Meshy 6 Lite cloth shape/textures retopologized onto the existing clean kit; preserved v3 anatomy and garment weights','protected_state_unchanged':before==after,'before':before,'after':after,'garments':measurements,'candidate':str(OUT/f'{role}_v4.glb')}
(REPORT/f'integration-{role}.json').write_text(json.dumps(report,indent=2)+'\n')
print('MESHY_INTEGRATION',json.dumps(report),flush=True)
