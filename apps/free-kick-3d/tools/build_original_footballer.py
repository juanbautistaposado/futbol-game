"""Create an original rigged footballer and GLB; run with Blender 5.2 in background."""
import bpy
import math
import sys
from mathutils import Vector
from pathlib import Path

# The candidate uses separate files so the accepted original remains playable.
GOALKEEPER_V2 = '--goalkeeper-v2' in sys.argv

# Rebuilding the editable sources should not leave stale .blend1 files in the
# asset directory.
bpy.context.preferences.filepaths.save_version = 0

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'footballer'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE_OUT = ROOT.parents[1] / 'source-assets' / 'footballer'
SOURCE_OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for datablocks in (bpy.data.materials, bpy.data.actions):
    for item in list(datablocks):
        if item.users == 0:
            datablocks.remove(item)


def mat(name, color, roughness=0.78):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    return m

skin = mat('Skin', (0.57, 0.36, 0.245), .88)
shirt = mat('Jersey', (0.065, .25, .55), .89)
shorts = mat('Shorts', (.025, .055, .16), .87)
sock = mat('Socks', (.07, .23, .48), .86)
hair = mat('Hair', (.045, .032, .028), .95)
white = mat('Trim', (.87, .89, .85), .8)
boot = mat('Boots', (.025, .035, .045), .62)
eye = mat('Eyes', (.035, .028, .025), .45)
lip = mat('Lips', (.35, .17, .14), .9)
eye_white = mat('EyeWhite', (.86, .82, .72), .66) if GOALKEEPER_V2 else None
skin_shade = mat('SkinShade', (.42, .25, .17), .9) if GOALKEEPER_V2 else None
shirt_accent = mat('JerseyAccent', (.19, .39, .66), .87) if GOALKEEPER_V2 else None
objects = []


def mesh(name, verts, faces, material, bone):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(material)
    for p in data.polygons:
        p.use_smooth = True
    vg = obj.vertex_groups.new(name=bone)
    vg.add(list(range(len(verts))), 1, 'REPLACE')
    objects.append(obj)
    return obj


def rings(name, rows, material, bone, sides=20, cy=0):
    # rows: z, x-center, x-radius, depth-radius, front/back offset.
    verts = []
    for z, cx, rx, ry, dy in rows:
        for i in range(sides):
            a = math.tau*i/sides
            verts.append((cx + rx*math.cos(a), cy + dy + ry*math.sin(a), z))
    faces = []
    for r in range(len(rows)-1):
        for i in range(sides):
            j = (i+1)%sides
            faces.append((r*sides+i, r*sides+j, (r+1)*sides+j, (r+1)*sides+i))
    faces.append(tuple(reversed(tuple(range(sides)))))
    faces.append(tuple((len(rows)-1)*sides+i for i in range(sides)))
    obj = mesh(name, verts, faces, material, bone)
    uv = obj.data.uv_layers.new(name='FabricUV')
    for poly in obj.data.polygons:
        for li in poly.loop_indices:
            vi = obj.data.loops[li].vertex_index
            uv.data[li].uv = (float(vi % sides) / sides, float(vi // sides) / max(len(rows)-1, 1))
    return obj


def ellipsoid(name, pos, size, material, bone, segments=16, rings_count=10):
    verts=[]
    for j in range(rings_count+1):
        v=math.pi*j/rings_count
        for i in range(segments):
            u=math.tau*i/segments
            verts.append((pos[0]+size[0]*math.sin(v)*math.cos(u),
                          pos[1]+size[1]*math.sin(v)*math.sin(u),
                          pos[2]+size[2]*math.cos(v)))
    faces=[]
    for j in range(rings_count):
        for i in range(segments):
            k=(i+1)%segments
            faces.append((j*segments+i,j*segments+k,(j+1)*segments+k,(j+1)*segments+i))
    obj = mesh(name,verts,faces,material,bone)
    uv = obj.data.uv_layers.new(name='SurfaceUV')
    for poly in obj.data.polygons:
        for li in poly.loop_indices:
            vi = obj.data.loops[li].vertex_index
            uv.data[li].uv = (float(vi % segments) / segments, float(vi // segments) / rings_count)
    return obj

# Single armature shared by all visual pieces. Blender Z becomes Godot Y in GLB.
arm_data=bpy.data.armatures.new('FootballerSkeleton')
rig=bpy.data.objects.new('FootballerRig',arm_data)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')

def bone(name,head,tail,parent=None):
    b=arm_data.edit_bones.new(name)
    b.head=head
    b.tail=tail
    if parent:
        b.parent=arm_data.edit_bones[parent]
    return b
bone('Root',(0,0,0),(0,0,.91))
bone('Hips',(0,0,.91),(0,0,1.04),'Root')
bone('Spine',(0,0,1.04),(0,0,1.31),'Hips')
bone('Chest',(0,0,1.31),(0,0,1.49),'Spine')
bone('Neck',(0,0,1.49),(0,0,1.62),'Chest')
bone('Head',(0,0,1.62),(0,0,1.89),'Neck')
for side,sfx in ((-1,'L'),(1,'R')):
    x=side*.12
    bone('Thigh.'+sfx,(x,0,.91),(side*.135,0,.51),'Hips')
    bone('Shin.'+sfx,(side*.135,0,.51),(side*.14,0,.13),'Thigh.'+sfx)
    bone('Foot.'+sfx,(side*.14,0,.13),(side*.14,-.19,.08),'Shin.'+sfx)
    bone('UpperArm.'+sfx,(side*.255,0,1.435),(side*.37,0,1.155),'Chest')
    bone('Forearm.'+sfx,(side*.37,0,1.155),(side*.42,-.015,.91),'UpperArm.'+sfx)
    bone('Hand.'+sfx,(side*.42,-.015,.91),(side*.43,-.03,.79),'Forearm.'+sfx)
bpy.ops.object.mode_set(mode='OBJECT')
rig.select_set(False)

# Fitted jersey: broad shoulders, athletic chest, tapered waist and collar.
rings('Tailored jersey',[(.995,0,.205,.115,0),(1.07,0,.213,.126,0),(1.17,0,.205,.125,0),(1.30,0,.235,.147,0),(1.40,0,.271,.16,0),(1.48,0,.24,.145,0),(1.53,0,.095,.085,0)],shirt,'Spine',28)
rings('Collar edge',[(1.515,0,.105,.087,0),(1.54,0,.104,.086,0)],white,'Chest',24)
rings('Jersey lower piping',[(1.002,0,.208,.12,0),(1.018,0,.209,.12,0)],white,'Spine',24)
if GOALKEEPER_V2:
    # Original club-style details. The accent uses its own material slot so
    # Godot can derive it from any user-selected shirt color.
    for side,sfx in ((-1,'L'),(1,'R')):
        ellipsoid('Front shirt stripe '+sfx,(side*.116,-.113,1.274),(.010,.005,.145),shirt_accent,'Spine',10,6)
    ellipsoid('Club crest border',(-.115,-.143,1.421),(.025,.005,.027),white,'Chest',16,8)
    ellipsoid('Club crest center',(-.115,-.150,1.421),(.017,.004,.019),shirt_accent,'Chest',16,8)
# Raised seam and jersey panels, slim so fabric remains sporty rather than toy-like.
for side,sfx in ((-1,'L'),(1,'R')):
    ellipsoid('Shoulder seam '+sfx,(side*.204,0,1.431),(.053,.095,.018),white,'Chest',12,6)
    if GOALKEEPER_V2:
        # The sleeve now grows out of the shoulder, with a narrow fabric panel
        # that remains readable when the arm reaches across the goal.
        ellipsoid('Shoulder cap '+sfx,(side*.268,0,1.425),(.068,.087,.054),shirt,'UpperArm.'+sfx,16,9)
        ellipsoid('Jersey side seam '+sfx,(side*.211,-.012,1.193),(.012,.021,.163),white,'Spine',10,6)
    # Shorts follow thighs; overlap at waist conceals the hip hinge.
    rings('Short leg '+sfx,[(.70,side*.132,.112,.116,0),(.76,side*.13,.121,.126,0),(.86,side*.124,.128,.129,0),(.98,side*.12,.119,.121,0)],shorts,'Thigh.'+sfx,18)
    rings('Short hem '+sfx,[(.70,side*.132,.113,.117,0),(.72,side*.132,.114,.118,0)],white,'Thigh.'+sfx,18)
    ellipsoid('Short side piping '+sfx,(side*.241,0,.795),(.009,.018,.082),white,'Thigh.'+sfx,10,5)
    if GOALKEEPER_V2:
        # Continuous weighted surface avoids the spherical placeholder knee.
        leg_rows=[(.44,side*.137,.071,.077,0),(.49,side*.137,.084,.089,0),(.54,side*.136,.094,.097,0),(.62,side*.133,.109,.106,0),(.74,side*.128,.108,.103,0)]
        leg_skin=rings('Continuous leg '+sfx,leg_rows,skin,'Thigh.'+sfx,18)
        upper_leg=leg_skin.vertex_groups['Thigh.'+sfx]
        lower_leg=leg_skin.vertex_groups.new(name='Shin.'+sfx)
        upper_leg.remove(list(range(len(leg_skin.data.vertices))))
        for row,(z,*_) in enumerate(leg_rows):
            indices=list(range(row*18,(row+1)*18))
            upper_weight=max(0.0,min(1.0,(z-.45)/.13))
            if upper_weight>.001: upper_leg.add(indices,upper_weight,'REPLACE')
            if upper_weight<.999: lower_leg.add(indices,1.0-upper_weight,'REPLACE')
    else:
        rings('Thigh skin '+sfx,[(.48,side*.135,.085,.09,0),(.55,side*.136,.096,.099,0),(.63,side*.132,.113,.108,0),(.74,side*.128,.108,.103,0)],skin,'Thigh.'+sfx,18)
        ellipsoid('Knee '+sfx,(side*.138,-.018,.50),(.09,.092,.102),skin,'Shin.'+sfx,14,8)
    rings('Football sock '+sfx,[(.13,side*.14,.048,.051,0),(.20,side*.14,.066,.07,0),(.33,side*.139,.072,.078,0),(.44,side*.137,.069,.071,0),(.48,side*.136,.075,.076,0)],sock,'Shin.'+sfx,18)
    for z in (.44,.465):
        rings('Sock stripe '+sfx,[(z,side*.136,.076,.078,0),(z+.009,side*.136,.076,.078,0)],white,'Shin.'+sfx,18)
    ellipsoid('Football boot '+sfx,(side*.14,-.105,.075),(.09,.18,.078),boot,'Foot.'+sfx,18,8)
    ellipsoid('Boot sole '+sfx,(side*.14,-.12,.035),(.093,.19,.024),white,'Foot.'+sfx,16,6)
    for j in range(3):
        ellipsoid('Lace '+sfx,(side*.14,-.11-j*.033,.132),(.039,.007,.006),white,'Foot.'+sfx,8,4)
    # Tapered sleeve, shoulder, rounded upper/lower arm, hand.
    rings('Sleeve '+sfx,[(1.20,side*.33,.094,.10,0),(1.29,side*.318,.102,.111,0),(1.40,side*.29,.112,.117,0),(1.48,side*.252,.096,.101,0)],shirt,'UpperArm.'+sfx,16)
    rings('Sleeve cuff '+sfx,[(1.20,side*.33,.096,.102,0),(1.215,side*.329,.096,.102,0)],white,'UpperArm.'+sfx,16)
    arm_rows=[(.865,side*.420,.041,.043,-.014),(.91,side*.411,.049,.053,-.012),(.98,side*.397,.058,.062,-.008),(1.06,side*.380,.067,.068,-.005),(1.13,side*.356,.071,.073,0),(1.20,side*.332,.076,.078,0),(1.25,side*.314,.071,.074,0)]
    arm_skin=rings('Continuous arm '+sfx,arm_rows,skin,'UpperArm.'+sfx,18)
    upper=arm_skin.vertex_groups['UpperArm.'+sfx]
    lower=arm_skin.vertex_groups.new(name='Forearm.'+sfx)
    upper.remove(list(range(len(arm_skin.data.vertices))))
    for row,(z,*_) in enumerate(arm_rows):
        indices=list(range(row*18,(row+1)*18))
        upper_weight=max(0.0,min(1.0,(z-1.015)/.12))
        if upper_weight>.001: upper.add(indices,upper_weight,'REPLACE')
        if upper_weight<.999: lower.add(indices,1.0-upper_weight,'REPLACE')
    ellipsoid('Hand '+sfx,(side*.426,-.027,.80),(.047,.038,.085),skin,'Hand.'+sfx,12,7)
    ellipsoid('Thumb '+sfx,(side*.39,-.05,.81),(.021,.028,.047),skin,'Hand.'+sfx,10,5)

rings('Shorts waistband',[(.92,0,.205,.12,0),(1.0,0,.21,.122,0),(1.02,0,.206,.121,0)],shorts,'Hips',26)
rings('Waist piping',[(1.018,0,.207,.123,0),(1.031,0,.205,.122,0)],white,'Hips',24)
rings('Neck',[(1.50,0,.071,.068,0),(1.60,0,.069,.067,0)],skin,'Neck',18)
# More human facial proportions: shaped jaw/chin/cheeks instead of a simple ball.
rings('Face',[(1.62,0,.053,.061,-.013),(1.67,0,.073,.071,-.011),(1.73,0,.09,.078,0),(1.81,0,.102,.085,.003),(1.88,0,.10,.083,.008),(1.93,0,.073,.073,.013),(1.96,0,.022,.029,.015)],skin,'Head',28)
# Hair cap with close-cropped sides and slightly fuller crown.
rings('Short dark hair',[(1.847,0,.102,.086,.012),(1.90,0,.102,.087,.012),(1.96,0,.078,.078,.016),(1.985,0,.02,.024,.018)],hair,'Head',24)
for side,sfx in ((-1,'L'),(1,'R')):
    ellipsoid('Ear '+sfx,(side*.101,.002,1.793),(.018,.02,.035),skin,'Head',10,6)
    ellipsoid('Brow '+sfx,(side*.04,-.083,1.831),(.032,.006,.006) if GOALKEEPER_V2 else (.026,.005,.004),hair,'Head',10,5)
    if GOALKEEPER_V2:
        ellipsoid('Eye white '+sfx,(side*.041,-.086,1.810),(.016,.007,.010),eye_white,'Head',12,7)
        ellipsoid('Iris '+sfx,(side*.041,-.092,1.809),(.0065,.004,.008),eye,'Head',12,7)
        ellipsoid('Upper eyelid '+sfx,(side*.041,-.090,1.820),(.019,.006,.005),skin,'Head',12,5)
        ellipsoid('Lower eyelid '+sfx,(side*.041,-.088,1.799),(.017,.005,.003),skin_shade,'Head',12,5)
        ellipsoid('Inner ear '+sfx,(side*.113,-.016,1.788),(.007,.007,.016),skin_shade,'Head',10,5)
        ellipsoid('Nostril '+sfx,(side*.011,-.094,1.758),(.006,.004,.003),skin_shade,'Head',10,5)
    else:
        ellipsoid('Eye '+sfx,(side*.041,-.084,1.810),(.009,.004,.006),eye,'Head',10,5)
ellipsoid('Nose bridge',(0,-.079,1.79),(.015,.009,.037),skin,'Head',12,7)
ellipsoid('Nose tip',(0,-.086,1.768),(.021,.012,.015),skin,'Head',12,6)
ellipsoid('Lower lip',(0,-.076,1.691),(.036,.008,.007),lip,'Head',12,5)
if GOALKEEPER_V2:
    ellipsoid('Mouth line',(0,-.083,1.704),(.031,.004,.003),skin_shade,'Head',14,5)
    ellipsoid('Chin contour',(0,-.065,1.657),(.042,.008,.012),skin,'Head',14,6)

def enlarge_head(parts):
    if not GOALKEEPER_V2:
        return
    for obj in parts:
        if obj.vertex_groups.get('Head') is None:
            continue
        for vertex in obj.data.vertices:
            vertex.co.x *= 1.34
            vertex.co.y *= 1.23
            vertex.co.z = 1.57 + (vertex.co.z - 1.62) * 1.14
    # The larger face remains attached to the same Head bone and keeps the rig.

enlarge_head(objects)

# Join mesh parts: vertex group names survive join, materials become surfaces.
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.object.join()
body=objects[0]
body.name='FootballerBody'
body.parent=rig
mod=body.modifiers.new('Skin footballer','ARMATURE')
mod.object=rig
for mat_slot in body.material_slots:
    mat_slot.link='DATA'

# Optional short beard is a separate skinned mesh so the existing beard toggle
# works for both presets and independently customized players.
beard_start = len(objects)
if GOALKEEPER_V2:
    ellipsoid('Beard chin',(0,-.081,1.665),(.064,.008,.021),hair,'Head',18,7)
    for side,sfx in ((-1,'L'),(1,'R')):
        ellipsoid('Moustache '+sfx,(side*.023,-.089,1.731),(.023,.006,.007),hair,'Head',12,5)
else:
    ellipsoid('Beard chin',(0,-.079,1.669),(.063,.016,.034),hair,'Head',18,7)
    for side,sfx in ((-1,'L'),(1,'R')):
        ellipsoid('Beard cheek '+sfx,(side*.073,-.052,1.709),(.019,.014,.048),hair,'Head',12,6)
beard_parts=objects[beard_start:]
enlarge_head(beard_parts)
bpy.ops.object.select_all(action='DESELECT')
for obj in beard_parts: obj.select_set(True)
bpy.context.view_layer.objects.active=beard_parts[0]
bpy.ops.object.join()
beard=beard_parts[0]
beard.name='Beard'
beard.parent=rig
beard_mod=beard.modifiers.new('Skin beard','ARMATURE')
beard_mod.object=rig

# Simple original clips on the shared rig. Each pose is keyed for animation export.
scene=bpy.context.scene
scene.render.fps=30
rig.animation_data_create()

def clip(name, poses, length):
    act=bpy.data.actions.new(name)
    rig.animation_data.action=act
    # Record every pose bone to produce a predictable rest/idle transition.
    for frame, rotations in poses:
        scene.frame_set(frame)
        for p in rig.pose.bones:
            p.rotation_mode='XYZ'
            p.rotation_euler=rotations.get(p.name,(0,0,0))
            p.keyframe_insert('rotation_euler',frame=frame,group=p.name)
    act.use_fake_user=True
    rig.animation_data.action=None
    return act

idle=clip('Idle',[(1,{'UpperArm.L':(.08,0,-.08),'UpperArm.R':(.08,0,.08),'Thigh.L':(.015,0,0),'Thigh.R':(-.015,0,0)}),(16,{'UpperArm.L':(.10,0,-.09),'UpperArm.R':(.10,0,.09),'Chest':(.012,0,0)}),(31,{'UpperArm.L':(.08,0,-.08),'UpperArm.R':(.08,0,.08),'Thigh.L':(.015,0,0),'Thigh.R':(-.015,0,0)})],31)
kick=clip('Kick',[(1,{}),(7,{'Thigh.R':(.7,0,0),'Shin.R':(-.8,0,0),'Thigh.L':(.16,0,0),'UpperArm.L':(.25,0,-.32),'UpperArm.R':(-.2,0,.4),'Chest':(-.10,0,0)}),(11,{'Thigh.R':(.2,0,0),'Shin.R':(-.55,0,0),'Thigh.L':(.12,0,0),'Chest':(.10,0,-.08)}),(15,{'Thigh.R':(-.76,0,0),'Shin.R':(-.05,0,0),'Thigh.L':(.08,0,0),'Chest':(.22,0,-.13),'UpperArm.R':(.20,0,.32)}),(21,{'Thigh.R':(-1.0,0,0),'Shin.R':(-.1,0,0),'Chest':(.19,0,-.19),'UpperArm.L':(-.15,0,-.35)}),(29,{})],29)
celebrate=clip('Celebrate',[(1,{}),(8,{'UpperArm.L':(0,0,2.2),'UpperArm.R':(0,0,-2.2),'Forearm.L':(.15,0,0),'Forearm.R':(.15,0,0),'Chest':(.10,0,0)}),(16,{'UpperArm.L':(0,0,2.3),'UpperArm.R':(0,0,-2.3),'Chest':(-.03,0,.04)}),(24,{'UpperArm.L':(0,0,2.2),'UpperArm.R':(0,0,-2.2),'Chest':(.10,0,0)})],24)
# NLA strips ensure all three actions are exported independently.
for act in (idle,kick,celebrate):
    track=rig.animation_data.nla_tracks.new()
    track.name=act.name
    track.strips.new(act.name,1,act)
    track.mute=True
rig.animation_data.action=idle
scene.frame_set(1)
scene.frame_end=31

# Export the same body as a field player before adding goalkeeper gloves.
# The v2 build therefore produces two role-specific GLBs with matching faces,
# uniforms and rig, while the original exports remain untouched.
field_name = 'footballer_v2' if GOALKEEPER_V2 else 'footballer_original'
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_OUT/(field_name+'.blend')))
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
body.select_set(True)
beard.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT/(field_name+'.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_apply=False,export_yup=True)
print('FIELD_PLAYER', field_name, len(body.data.vertices), len(body.data.polygons), len(body.material_slots), len(arm_data.bones), [(a.name,a.frame_range[:]) for a in bpy.data.actions])

# A second original variant shares the deformation rig and gains real glove
# geometry plus goalkeeper poses. No external characters or clips are used.
glove = mat('GoalkeeperGloves', (.76,.82,.79), .7)
glove_start = len(objects)
for side,sfx in ((-1,'L'),(1,'R')):
    palm_size=(.063,.051,.104) if GOALKEEPER_V2 else (.052,.045,.09)
    ellipsoid('Goalkeeper palm '+sfx,(side*.426,-.027,.80),palm_size,glove,'Hand.'+sfx,16 if GOALKEEPER_V2 else 14,9 if GOALKEEPER_V2 else 8)
    rings('Glove wrist '+sfx,[(.855,side*.416,.058,.059,0),(.885,side*.412,.060,.059,0)] if GOALKEEPER_V2 else [(.855,side*.416,.055,.055,0),(.885,side*.412,.057,.055,0)],glove,'Hand.'+sfx,14)
    if GOALKEEPER_V2:
        ellipsoid('Glove thumb '+sfx,(side*.372,-.058,.814),(.029,.032,.050),glove,'Hand.'+sfx,12,7)
        rings('Glove cuff trim '+sfx,[(.862,side*.416,.060,.061,0),(.876,side*.414,.061,.061,0)],white,'Hand.'+sfx,14)
new_parts = objects[glove_start:]
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
for obj in new_parts:
    if obj.name in bpy.data.objects and obj != body:
        obj.select_set(True)
bpy.context.view_layer.objects.active=body
bpy.ops.object.join()
left_extension={'UpperArm.L':(0,0,2.4),'UpperArm.R':(0,0,2.25),'Forearm.L':(.1,0,0),'Forearm.R':(.1,0,0),'Chest':(.12,0,-.35),'Thigh.L':(.5,0,0),'Shin.L':(-.4,0,0)}
right_extension={'UpperArm.R':(0,0,-2.4),'UpperArm.L':(0,0,-2.25),'Forearm.R':(.1,0,0),'Forearm.L':(.1,0,0),'Chest':(.12,0,.35),'Thigh.R':(.5,0,0),'Shin.R':(-.4,0,0)}
if GOALKEEPER_V2:
    # Wind up in the opposite direction, push off the far leg, then bring both
    # hands together toward the shot. The trailing leg follows through.
    left_windup={'Chest':(.10,0,.16),'UpperArm.L':(-.25,0,-.32),'UpperArm.R':(-.25,0,-.18),'Thigh.R':(-.36,0,0),'Shin.R':(.52,0,0),'Thigh.L':(.20,0,0)}
    right_windup={'Chest':(.10,0,-.16),'UpperArm.R':(-.25,0,.32),'UpperArm.L':(-.25,0,.18),'Thigh.L':(-.36,0,0),'Shin.L':(.52,0,0),'Thigh.R':(.20,0,0)}
    left_extension={'UpperArm.L':(-.22,0,2.48),'UpperArm.R':(-.22,0,2.22),'Forearm.L':(-.22,0,-.08),'Forearm.R':(-.18,0,.12),'Chest':(.14,0,-.27),'Thigh.L':(.50,0,0),'Shin.L':(-.48,0,0),'Thigh.R':(-.42,0,0),'Shin.R':(.46,0,0)}
    right_extension={'UpperArm.R':(-.22,0,-2.48),'UpperArm.L':(-.22,0,-2.22),'Forearm.R':(-.22,0,.08),'Forearm.L':(-.18,0,-.12),'Chest':(.14,0,.27),'Thigh.R':(.50,0,0),'Shin.R':(-.48,0,0),'Thigh.L':(-.42,0,0),'Shin.L':(.46,0,0)}
    low_left_extension={**left_extension,'UpperArm.L':(-1.38,0,2.45),'UpperArm.R':(-1.32,0,2.19),'Chest':(.24,0,-.23)}
    low_right_extension={**right_extension,'UpperArm.R':(-1.38,0,-2.45),'UpperArm.L':(-1.32,0,-2.19),'Chest':(.24,0,.23)}
    save_left=clip('SaveLeft',[(1,{}),(4,left_windup),(9,left_extension),(17,left_extension),(23,{})],23)
    save_right=clip('SaveRight',[(1,{}),(4,right_windup),(9,right_extension),(17,right_extension),(23,{})],23)
    save_low_left=clip('SaveLowLeft',[(1,{}),(4,left_windup),(9,low_left_extension),(17,low_left_extension),(23,{})],23)
    save_low_right=clip('SaveLowRight',[(1,{}),(4,right_windup),(9,low_right_extension),(17,low_right_extension),(23,{})],23)
else:
    save_left=clip('SaveLeft',[(1,{}),(4,{'UpperArm.L':(-.15,0,.85),'UpperArm.R':(-.15,0,.85),'Thigh.L':(-.18,0,0),'Chest':(0,0,-.18)}),(9,left_extension),(19,left_extension),(25,{})],25)
    save_right=clip('SaveRight',[(1,{}),(4,{'UpperArm.R':(-.15,0,-.85),'UpperArm.L':(-.15,0,-.85),'Thigh.R':(-.18,0,0),'Chest':(0,0,.18)}),(9,right_extension),(19,right_extension),(25,{})],25)
    low_left_extension={**left_extension,'UpperArm.L':(-1.50,0,2.4),'UpperArm.R':(-1.50,0,2.25)}
    low_right_extension={**right_extension,'UpperArm.R':(-1.50,0,-2.4),'UpperArm.L':(-1.50,0,-2.25)}
    save_low_left=clip('SaveLowLeft',[(1,{}),(4,{'UpperArm.L':(-.50,0,.85),'UpperArm.R':(-.50,0,.85),'Thigh.L':(-.18,0,0),'Chest':(0,0,-.18)}),(9,low_left_extension),(19,low_left_extension),(25,{})],25)
    save_low_right=clip('SaveLowRight',[(1,{}),(4,{'UpperArm.R':(-.50,0,-.85),'UpperArm.L':(-.50,0,-.85),'Thigh.R':(-.18,0,0),'Chest':(0,0,.18)}),(9,low_right_extension),(19,low_right_extension),(25,{})],25)
catch=clip('Catch',[(1,{}),(8,{'UpperArm.L':(-1.0,0,0),'UpperArm.R':(-1.0,0,0),'Chest':(.08,0,0)}),(18,{'UpperArm.L':(-1.0,0,0),'UpperArm.R':(-1.0,0,0),'Chest':(.08,0,0)})],18)
rig.animation_data.action=idle
scene.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_OUT/('goalkeeper_v2.blend' if GOALKEEPER_V2 else 'goalkeeper_original.blend')))
bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True)
body.select_set(True)
beard.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=str(OUT/('goalkeeper_v2.glb' if GOALKEEPER_V2 else 'goalkeeper_original.glb')),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_apply=False,export_yup=True)
print('GOALKEEPER_V2' if GOALKEEPER_V2 else 'ORIGINAL_GOALKEEPER',len(body.data.vertices),len(body.data.polygons),len(body.material_slots),[(a.name,a.frame_range[:]) for a in bpy.data.actions])
