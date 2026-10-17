"""Tailor clothing and simplify rigid limb areas; preserve rig/clips and atlas UVs.

Blender authoring pass. Sources stay intact; creates cloth_v2 editable variants.
"""
import bpy
import bmesh
import json
import math
import sys
import hashlib
from pathlib import Path
from mathutils import Vector

sys.path.insert(0,str(Path(__file__).resolve().parent))
from pose_striker_arms import preserve_unedited_clip_channels
ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT/'source-assets/footballer'
ASSETS = ROOT/'apps/free-kick-3d/assets/footballer'
REPORT = ROOT/'docs/research/cloth-quality-2026-10-11'

def smooth(a,b,x):
    t=max(0.,min(1.,(x-a)/(b-a)))
    return t*t*(3-2*t)

def polish(role):
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE/f'meshy_{role}.blend'))
    body=bpy.data.objects['FootballerBody']
    rig=bpy.data.objects['FootballerRig']
    mesh=body.data
    rest=mesh.attributes['MeshyRestPosition']
    raw=[e.vector.copy() for e in rest.data]
    before=[v.co.copy() for v in mesh.vertices]
    uv=mesh.uv_layers['UVMap']
    material=mesh.materials[0]
    image=material.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].links[0].from_node.image
    pixels=list(image.pixels)
    width,height=image.size
    jersey_index=next(i for i,m in enumerate(mesh.materials) if m.name.split('.')[0]=='Jersey')
    regions=[]
    jersey_fixed=0
    for p in mesh.polygons:
        center=sum((raw[i] for i in p.vertices),Vector())/len(p.vertices)
        colors=[]
        for loop in p.loop_indices:
            coord=uv.data[loop].uv
            x,y=int(coord.x*width)%width,int(coord.y*height)%height
            colors.append(pixels[(y*width+x)*4:(y*width+x)*4+3])
        rgb=[sum(c[i] for c in colors)/len(colors) for i in range(3)]
        bright=max(rgb)
        neutral=bright>.24 and (bright-min(rgb))/bright<.32
        if p.material_index==jersey_index or (.98<center.z<1.595 and neutral):
            # Keep the navy neckline intact; white shirt boundaries no longer
            # depend on a harsh hue threshold that left ragged uncolored slivers.
            if p.material_index!=jersey_index:
                p.material_index=jersey_index
                jersey_fixed+=1
            regions.append('shirt')
        elif .665<center.z<1.045 and abs(center.x)<.28 and rgb[0]-rgb[1]<.07:
            regions.append('short')
        else:
            regions.append('protected')
    neighbors=[set() for _ in mesh.vertices]
    memberships=[set() for _ in mesh.vertices]
    for p,region in zip(mesh.polygons,regions):
        ids=list(p.vertices)
        for i,index in enumerate(ids):
            memberships[index].add(region)
            neighbors[index].update([ids[i-1],ids[(i+1)%len(ids)]])
    selected={i for i,r in enumerate(memberships) if len(r)==1 and 'protected' not in r}
    interior={i for i in selected if all(j in selected for j in neighbors[i])}
    # Fair small generated ridges without rounding the cuffs, neck or hems.
    for iteration in range(4):
        old=[v.co.copy() for v in mesh.vertices]
        for i in interior:
            p=raw[i]
            weight=.23 if 'shirt' in memberships[i] else .17
            average=sum((old[j] for j in neighbors[i]),Vector())/len(neighbors[i])
            target=old[i].lerp(average,weight)
            delta=target-before[i]
            if delta.length>.004:
                target=before[i]+delta.normalized()*.004
            mesh.vertices[i].co=target
    for i in interior:
        if 'shirt' in memberships[i]:
            p=raw[i]
            clearance=.0018*smooth(1.02,1.10,p.z)*(1-smooth(1.53,1.60,p.z))
            mesh.vertices[i].co+=mesh.vertices[i].normal*clearance
    # Gently bias the continuous waistband toward Hips and each leg to its thigh.
    # Reduce cross-leg influence that pulled the crotch apart during a kick.
    changed_weights=0
    hips=body.vertex_groups['Hips']
    left=body.vertex_groups['Thigh.L']
    right=body.vertex_groups['Thigh.R']
    for i in interior:
        if 'short' not in memberships[i]: continue
        p=raw[i]
        waist=smooth(.84,1.025,p.z)
        bridge=(1-smooth(.02,.085,abs(p.x)))*smooth(.79,.89,p.z)
        hip_weight=max(waist,.55*bridge)
        # Existing rig names use R on the positive-X anatomical chain.
        thigh=right if p.x>0 else left
        old_weights={g.group:g.weight for g in mesh.vertices[i].groups}
        desired={hips.index:hip_weight,thigh.index:1-hip_weight}
        # A modest correction preserves the original sculpted fold deformation.
        mixed={g:old_weights.get(g,0.)*.75+desired.get(g,0.)*.25
            for g in old_weights.keys()|desired.keys()}
        selected_weights=sorted(mixed.items(),key=lambda item:item[1],reverse=True)[:4]
        total=sum(weight for _,weight in selected_weights)
        for group_id in [g.group for g in mesh.vertices[i].groups]:
            body.vertex_groups[group_id].remove([i])
        for group_id,weight in selected_weights:
            body.vertex_groups[group_id].add([i],weight/total,'REPLACE')
        changed_weights+=1
    mesh.update()
    # Dissolve nearly planar cloth edges only. Remaining vertex weights and UV
    # corners survive; material boundaries, atlas seams and protected faces stay.
    bm=bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    candidates=[v for v in bm.verts if v.index in interior and 'shirt' in memberships[v.index]]
    rigid_bones={g.index for g in body.vertex_groups if g.name.split('.')[0] in ['UpperArm','Forearm','Thigh','Shin']}
    rigid={}
    for v in mesh.vertices:
        if memberships[v.index]!={'protected'}: continue
        if raw[v.index].z<.23 or raw[v.index].z>1.63: continue
        if before[v.index].z<.24: continue
        group=max(v.groups,key=lambda g:g.weight)
        if group.group in rigid_bones and group.weight>.999:
            rigid[v.index]=group.group
    rigid_verts=[v for v in bm.verts if v.index in rigid]
    rigid_edges=[e for e in bm.edges if all(v.index in rigid for v in e.verts)
        and rigid[e.verts[0].index]==rigid[e.verts[1].index]]
    # Keep the short's dense deformation topology: simplify jersey panels only.
    # Large n-gons across a bending hip can triangulate differently in animation.
    edges=[e for e in bm.edges if all(v.index in interior and 'shirt' in memberships[v.index] for v in e.verts)]
    before_triangles=len(mesh.polygons)
    bmesh.ops.dissolve_limit(bm,angle_limit=math.radians(6.5),
        use_dissolve_boundaries=False,verts=candidates,edges=edges,
        delimit={'UV','MATERIAL','NORMAL'})
    # Nearly planar limb areas attached to a single bone can also be simplified
    # without interpolating across a bending joint. Excludes head, hands/boots.
    bmesh.ops.dissolve_limit(bm,angle_limit=math.radians(6.5),
        use_dissolve_boundaries=False,verts=[v for v in rigid_verts if v.is_valid],
        edges=[e for e in rigid_edges if e.is_valid],delimit={'UV','MATERIAL','NORMAL'})
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons: p.use_smooth=True
    mesh.calc_loop_triangles()
    assert not mesh.validate(clean_customdata=False)
    for v in mesh.vertices:
        total=sum(g.weight for g in v.groups)
        assert abs(total-1)<1e-5, (v.index,total,[(g.group,g.weight) for g in v.groups])
    body['asset_revision']='cloth-quality-2026-10-11'
    editable=SOURCE/f'meshy_{role}_cloth_v2.blend'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.wm.save_as_mainfile(filepath=str(editable))
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active=rig
    target=ASSETS/f'meshy_{role}.glb'
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,
        export_animations=True,export_animation_mode='NLA_TRACKS',export_apply=False,
        export_yup=True,export_skins=True,export_all_influences=False)
    clip_source=ASSETS/('meshy_player.glb' if role=='striker' else 'goalkeeper_v4.glb')
    copied=preserve_unedited_clip_channels(clip_source,target,keep_authored_arms=False)
    report={'role':role,'source_blend':str(editable.relative_to(ROOT)),
        'baseline':f'source-assets/footballer/meshy_{role}.blend',
        'vertices':len(mesh.vertices),'triangles_before':before_triangles,
        'triangles_after':len(mesh.loop_triangles),'crotch_weight_vertices':changed_weights,
        'jersey_boundary_faces_fixed':jersey_fixed,'animation_channels_exact':copied,
        'runtime_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
        'license':'CC-BY-4.0','author':'Meshy AI; cloth adaptation by this project'}
    (REPORT/f'{role}.json').write_text(json.dumps(report,indent=2)+'\n')
    print('CLOTH_POLISH',json.dumps(report),flush=True)

args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['striker','keeper']
for role in args: polish(role)
