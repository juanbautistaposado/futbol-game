import bpy, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'source-assets/footballer/footballer_v3.blend'))
body=bpy.data.objects['FootballerBody']; rig=bpy.data.objects['FootballerRig']
regions={}
for p in body.data.polygons:
 name=body.data.materials[p.material_index].name
 region=regions.setdefault(name,{'faces':0,'vertices':set()})
 region['faces']+=1;region['vertices'].update(p.vertices)
for name,region in regions.items():
 points=[body.data.vertices[i].co for i in region.pop('vertices')]
 region['min']=[min(p[j] for p in points) for j in range(3)]
 region['max']=[max(p[j] for p in points) for j in range(3)]
data={'body_matrix':[list(row) for row in body.matrix_world],'regions':regions,'bones':{b.name:{'head':list(b.head_local),'tail':list(b.tail_local)} for b in rig.data.bones if b.name in ['Hips','Spine','SpineMid','Chest','Neck','Head'] or b.name.startswith(('UpperArm.','Forearm.','Hand.','Thigh.','Shin.','Foot.'))},'objects':[{ 'name':o.name,'type':o.type,'parent':o.parent.name if o.parent else None} for o in bpy.data.objects]}
out=ROOT/'docs/research/meshy-trial-2026-10-06/integration-source.json'
out.write_text(json.dumps(data,indent=2)+'\n')
print('SOURCE_INSPECTION',json.dumps(data),flush=True)
