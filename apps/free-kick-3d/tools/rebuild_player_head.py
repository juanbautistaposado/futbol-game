"""Reconstruct the Meshy head from the project's CC0 anatomical source.

Blender source pass, independent of the preceding garment/groom builder:
  blender -b --factory-startup --python tools/rebuild_player_head.py -- prepare
  blender -b --factory-startup --python tools/rebuild_player_head.py -- striker keeper

The head gets a dedicated UV layout, real eye openings/eyeballs and fitted neck.
All existing rig/clip channels and non-head mesh data remain authored data.
"""
import hashlib
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_player_realism import material, normalize_weights, smooth
from pose_striker_arms import preserve_unedited_clip_channels
from fit_player_groom import fit_scalp, build_beard

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / 'source-assets/footballer'
MASTER = SOURCE / 'head-2026-10-14'
ASSETS = ROOT / 'apps/free-kick-3d/assets/footballer'
REPORT = ROOT / 'docs/research/player-head-2026-10-14'


def fit(p):
    """Match the new anatomical landmarks to the existing athlete's silhouette."""
    p = p.copy()
    p.x *= .97
    p.y += .065
    p.z = 1.764 + (p.z - 1.783) * 1.08
    # A slightly firmer jaw and cheek plane, without moving eyelids/lips.
    cheek = math.exp(-((abs(p.x) - .050) / .022) ** 2 - ((p.z - 1.737) / .023) ** 2)
    p.y -= .0018 * cheek
    return p


def head_uv(uv):
    # Expand the anterior face to most of the atlas. The rear scalp has a
    # smaller texel allocation; the source's facial loops stay distortion-free.
    return (float(np.interp(uv.y, [0, .30, .483168, .666336, 1], [0, .05, .5, .95, 1])),
            float(np.interp(uv.x, [.60, .74, .965, 1], [1, .95, .05, 0])))


def refine_expression(p):
    """A less sleepy neutral gaze, with small proportional corrections."""
    p = p.copy()
    front = 1 - smooth(-.045, .015, p.y)
    x, z = abs(p.x), p.z
    # Upper lids previously crossed the iris center and hid its upper half.
    # Raise the lid and its crease together; leave globe and lower rim intact.
    upper_lid = math.exp(-((x-.0306)/.017)**2 - ((z-1.767)/.009)**2)
    p.z += .0025 * upper_lid * smooth(1.760, 1.765, z) * front
    # Slightly broader mandibular plane balances the long, narrow lower face.
    jaw = math.exp(-((z-1.662)/.027)**2)
    p.x *= 1 + .035 * jaw * front
    # Relax the downturned corners without adding a smile or changing the lips.
    corner = math.exp(-((x-.025)/.010)**2 - ((z-1.680)/.009)**2)
    p.z += .0008 * corner * front
    return p


def add_blink(body):
    """A real eyelid morph, independent of the eight skeletal clips."""
    body.shape_key_add(name='Basis')
    blink = body.shape_key_add(name='Blink')
    skin = {v for p in body.data.polygons
            if body.data.materials[p.material_index].name in ['FaceSkin', 'FaceInterior']
            for v in p.vertices}
    for i in skin:
        p = body.data.vertices[i].co
        lateral = 1 - smooth(.010, .021, abs(abs(p.x)-.0306375))
        front = 1 - smooth(-.065, -.040, p.y)
        upper = math.exp(-((p.z-1.767)/.010)**2) * smooth(1.760, 1.766, p.z)
        lower = math.exp(-((p.z-1.756)/.005)**2) * (1-smooth(1.759, 1.762, p.z))
        blink.data[i].co.z += (-.0102*upper + .0012*lower) * lateral * front


def donor():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'footballer_v4.blend'))
    body = bpy.data.objects['FootballerBody']
    # Separate head skin and eyes before any other source material is removed.
    parts = {}
    for kind, material_id in [('face', 0), ('eyes', 1)]:
        obj = body.copy()
        obj.data = body.data.copy()
        bpy.context.collection.objects.link(obj)
        obj.name = 'ReconstructedHead' if kind == 'face' else 'AnatomicalEyes'
        obj.parent = None
        obj.modifiers.clear()
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bad = [f for f in bm.faces if f.material_index != material_id or
               any(v.co.z < 1.59 or abs(v.co.x) > .14 for v in f.verts)]
        bmesh.ops.delete(bm, geom=bad, context='FACES')
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
        bm.to_mesh(obj.data)
        bm.free()
        if 'custom_normal' in obj.data.attributes:
            obj.data.attributes.remove(obj.data.attributes['custom_normal'])
        for p in obj.data.polygons:
            p.use_smooth = True
        for e in obj.data.edges:
            e.use_edge_sharp = False
        parts[kind] = obj
    return parts


def prepare():
    """Bake the licensed source into the dedicated layout as an image edit guide."""
    face = donor()['face']
    mesh = face.data
    source_uv = mesh.uv_layers['UVMap']
    dedicated = mesh.uv_layers.new(name='DedicatedFaceUV')
    for loop in mesh.loops:
        dedicated.data[loop.index].uv = head_uv(source_uv.data[loop.index].uv)
    image = bpy.data.images.load(str(ASSETS / 'footballer_v4_skin_detail.png'))
    width, height = image.size
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(height, width, 4)
    size = 2048
    # Rasterize in UV space, not a lit render: preserves anatomical pigment
    # and yields a reproducible map without baked directional lighting.
    output = np.ones((size, size, 4), dtype=np.float32)
    output[:, :, :3] = (.94, .77, .59)
    mesh.calc_loop_triangles()
    for tri in mesh.loop_triangles:
        original = np.array([source_uv.data[l].uv[:] for l in tri.loops])
        if not np.all(original[:, 0] > .60):
            continue  # interior mouth/eye sockets use their own material
        uv = np.array([dedicated.data[l].uv[:] for l in tri.loops]) * (size - 1)
        lo = np.maximum(np.floor(uv.min(axis=0)).astype(int), 0)
        hi = np.minimum(np.ceil(uv.max(axis=0)).astype(int), size - 1)
        if np.any(hi < lo): continue
        a, b, c = uv
        det = (b-a)[0]*(c-a)[1] - (b-a)[1]*(c-a)[0]
        if abs(det) < 1e-9: continue
        yy, xx = np.mgrid[lo[1]:hi[1]+1, lo[0]:hi[0]+1]
        q = np.stack([xx, yy], axis=-1) - a
        w1 = (q[..., 0] * (c-a)[1] - q[..., 1] * (c-a)[0]) / det
        w2 = ((b-a)[0] * q[..., 1] - (b-a)[1] * q[..., 0]) / det
        w0 = 1-w1-w2
        inside = (w0 >= -.001) & (w1 >= -.001) & (w2 >= -.001)
        src = w0[..., None]*original[0] + w1[..., None]*original[1] + w2[..., None]*original[2]
        sx = np.clip((src[..., 0]*(width-1)).astype(int), 0, width-1)
        sy = np.clip((src[..., 1]*(height-1)).astype(int), 0, height-1)
        patch = output[lo[1]:hi[1]+1, lo[0]:hi[0]+1]
        patch[inside] = pixels[sy[inside], sx[inside]]
    # Small bake-margin dilation avoids unmapped subpixel cracks in the guide.
    guide = bpy.data.images.new('facial_uv_guide', width=size, height=size, alpha=False)
    guide.pixels.foreach_set(output.ravel())
    MASTER.mkdir(parents=True, exist_ok=True)
    guide.filepath_raw = str(MASTER / 'facial_uv_guide.png')
    guide.file_format = 'PNG'
    guide.save()
    print('HEAD_GUIDE', guide.filepath_raw)


def build(role):
    parts = donor()
    face, eyes = parts['face'], parts['eyes']
    head_skin = material('FaceSkin', (.52, .34, .24), .57)
    image = bpy.data.images.load(str(ASSETS / 'face_albedo.png'))
    image.pack()
    tex = head_skin.node_tree.nodes.new('ShaderNodeTexImage')
    tex.image = image
    head_skin.node_tree.links.new(tex.outputs['Color'], head_skin.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
    interior = material('FaceInterior', (.055, .012, .009), .62)
    mesh = face.data
    old_uv = [l.uv.copy() for l in mesh.uv_layers['UVMap'].data]
    mesh.materials.clear()
    mesh.materials.append(head_skin)
    mesh.materials.append(interior)
    neck_loops = set()
    for p in mesh.polygons:
        in_head_island = all(old_uv[l].x > .60 for l in p.loop_indices)
        external_neck = p.center.z < 1.70 or p.center.y > -.10
        p.material_index = 0 if external_neck or in_head_island else 1
        if external_neck and not in_head_island:
            neck_loops.update(p.loop_indices)
    for l in mesh.loops:
        uv = head_uv(old_uv[l.index])
        # Align the generated nose/lip pigment to the exact source geometry.
        v = float(np.interp(uv[1], [0, .05, .273, .393, .552, 1], [0, .05, .290, .406, .552, 1]))
        mesh.uv_layers['UVMap'].data[l.index].uv = (uv[0], v)
        mesh.uv_layers['JerseyPrintUV'].data[l.index].uv = (-2, -2)
        if l.index in neck_loops:
            p = mesh.vertices[l.vertex_index].co
            mesh.uv_layers['UVMap'].data[l.index].uv = (.50 + p.x*.1, .85 + (p.z-1.65)*.1)
    for v in mesh.vertices:
        v.co = refine_expression(fit(v.co))
    # Relax sub-millimetre subdivision artifacts, preserving mouth/eye openings.
    bm = bmesh.new(); bm.from_mesh(mesh)
    for _ in range(2):
        bmesh.ops.smooth_vert(bm, verts=[v for v in bm.verts if not v.is_boundary],
                             factor=.12, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bm.normal_update(); bm.to_mesh(mesh); bm.free()
    mesh.update()
    # The CC0 low-poly eyeballs are anatomical volumes, not decals. Smooth them
    # before fitting; skin eyelids provide the natural occlusion of each sphere.
    eyes.data.materials.clear()
    eyes.data.materials.append(material('EyeSurface', (.5, .48, .44), .19))
    for p in eyes.data.polygons: p.material_index = 0
    bpy.context.view_layer.objects.active = eyes
    sub = eyes.modifiers.new('SmoothEyeballs', 'SUBSURF')
    sub.levels = 2
    bpy.ops.object.modifier_apply(modifier=sub.name)
    for v in eyes.data.vertices: v.co = fit(v.co)
    centers = {}
    for sign in [-1, 1]:
        vs = [v for v in eyes.data.vertices if v.co.x * sign > 0]
        centers[sign] = Vector(tuple((min(v.co[k] for v in vs) + max(v.co[k] for v in vs)) / 2 for k in range(3)))
    for v in eyes.data.vertices:
        center = centers[1 if v.co.x > 0 else -1]
        dx, dz = v.co.x-center.x, v.co.z-center.z
        radius = math.hypot(dx, dz)
        if v.co.y < center.y:
            v.co.y -= .00065 * max(0, 1-(radius/.0062)**2)**2
    for loop in eyes.data.loops:
        p = eyes.data.vertices[loop.vertex_index].co
        center = centers[1 if p.x > 0 else -1]
        eyes.data.uv_layers['UVMap'].data[loop.index].uv = (.5+(p.x-center.x)/.030, .5+(p.z-center.z)/.030)
        eyes.data.uv_layers['JerseyPrintUV'].data[loop.index].uv = (-2, -2)
    # Store the two pieces in a temporary library, then open the unmodified
    # previous source to keep its animation data and garment/groom geometry.
    library = Path('/tmp/player-head-parts.blend')
    bpy.data.libraries.write(str(library), {face, eyes}, path_remap='ABSOLUTE')
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE / f'meshy_{role}_realism.blend'))
    body = bpy.data.objects['FootballerBody']
    rig = bpy.data.objects['FootballerRig']
    with bpy.data.libraries.load(str(library), link=False) as (src, dst):
        dst.objects = ['ReconstructedHead', 'AnatomicalEyes']
    face, eyes = dst.objects
    for obj in [face, eyes]:
        bpy.context.collection.objects.link(obj)
    mesh = body.data
    mesh.calc_loop_triangles()
    atlas = mesh.materials[0].node_tree.nodes['Principled BSDF'].inputs['Base Color'].links[0].from_node.image
    pixels = np.array(atlas.pixels[:], dtype=np.float32).reshape(atlas.size[1], atlas.size[0], 4)
    uv0 = mesh.uv_layers['UVMap']
    keep_scalp = set()
    for p in mesh.polygons:
        if p.material_index != 0: continue
        center = p.center
        if center.z < 1.70: continue
        uv = sum((uv0.data[l].uv for l in p.loop_indices), Vector((0, 0))) / len(p.loop_indices)
        rgb = pixels[int(uv.y*atlas.size[1]) % atlas.size[1], int(uv.x*atlas.size[0]) % atlas.size[0], :3]
        value = float(rgb @ np.array([.2126,.7152,.0722]))
        if (center.z > 1.798 or (center.z > 1.71 and center.y > -.021)) and value < .27:
            keep_scalp.add(p.index)
    # Build the donor's surface BVH for roots and neck placement.
    face.data.calc_loop_triangles()
    skin_triangles = [tuple(t.vertices) for t in face.data.loop_triangles if t.material_index == 0]
    head_tree = BVHTree.FromPolygons([v.co for v in face.data.vertices], skin_triangles, all_triangles=True)
    fit_scalp(mesh, keep_scalp, head_tree)
    # A clean anatomical eyebrow arch, with dense tapered fibers and softened
    # ends. The previous 340 fibers relied on painted eyebrows in the old atlas.
    rng = random.Random(14102026)
    vertices, polygons, uv_values = [], [], []
    for sign in [-1, 1]:
        for strand in range(850):
            u = rng.random()
            x = sign * (.013 + u*.049)
            taper = math.sin(math.pi * (.08 + u*.86)) ** .7
            z = 1.779 + .0027 * math.sin(u*math.pi) + rng.uniform(-.0022,.0022)*taper
            hit, normal, _, _ = head_tree.ray_cast(Vector((x,-.25,z)),Vector((0,1,0)))
            if hit is None: continue
            direction = Vector((sign, 0, .30-.7*u)).normalized()
            direction = (direction - normal*direction.dot(normal)).normalized()
            side = direction.cross(normal).normalized()
            length = rng.uniform(.0024,.0041)
            radius = rng.uniform(.000085,.00014)*taper
            base = len(vertices)
            for step in range(3):
                t = step/2
                center = hit + normal*(.00012 + math.sin(t*math.pi)*.00025) + direction*length*t
                for corner in range(3):
                    angle = corner*math.tau/3
                    vertices.append(center + (side*math.cos(angle)+normal*math.sin(angle))*radius*(1-t*.85))
                    uv_values.append(((strand%101)/101,t))
            for step in range(2):
                for corner in range(3):
                    a=base+step*3+corner; b=base+step*3+(corner+1)%3
                    polygons.append((a,a+3,b+3,b))
    data = bpy.data.meshes.new('AnatomicalBrows')
    data.from_pydata(vertices, [], polygons)
    data.materials.append(next(m for m in mesh.materials if m.name=='BrowGroom'))
    brows = bpy.data.objects.new('AnatomicalBrows',data)
    bpy.context.collection.objects.link(brows)
    for group in body.vertex_groups: brows.vertex_groups.new(name=group.name)
    brows.vertex_groups['Head'].add(list(range(len(vertices))),1.,'REPLACE')
    uv=data.uv_layers.new(name='UVMap'); lettering=data.uv_layers.new(name='JerseyPrintUV')
    for loop in data.loops:
        uv.data[loop.index].uv=uv_values[loop.vertex_index]
        lettering.data[loop.index].uv=(-2,-2)
    for p in data.polygons: p.use_smooth=True
    # Fit the new neck's lower rings to the existing collar opening. The
    # transition sits below the jaw and overlaps the retained neck under cloth.
    for v in face.data.vertices:
        if v.co.z < 1.65:
            t = 1 - smooth(1.59, 1.65, v.co.z)
            angle = math.atan2(v.co.y-.035, v.co.x)
            target = Vector((.068*math.cos(angle), .035+.058*math.sin(angle), v.co.z))
            v.co = v.co.lerp(target, t*.85)
    face.data.update()
    beard = build_beard(face, body)
    bm = bmesh.new(); bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    eye_index = next(i for i,m in enumerate(mesh.materials) if m.name == 'EyeSurface')
    brow_index = next(i for i,m in enumerate(mesh.materials) if m.name == 'BrowGroom')
    beard_index = next(i for i,m in enumerate(mesh.materials) if m.name == 'BeardGroom')
    remove = [f for f in bm.faces if f.material_index in [eye_index,brow_index,beard_index] or
              (f.material_index == 0 and f.index not in keep_scalp and
               all(v.co.z > 1.575 and abs(v.co.x) < .14 for v in f.verts))]
    removed_faces = len(remove)
    bmesh.ops.delete(bm, geom=remove, context='FACES')
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bm.normal_update(); bm.to_mesh(mesh); bm.free(); mesh.update()
    # Rebind by bone name: donor and target use the same authored 53-bone rig.
    for obj in [face, eyes]:
        obj.parent = None
        for v in obj.data.vertices:
            if obj == eyes or v.co.z > 1.68:
                for group in list(v.groups): obj.vertex_groups[group.group].remove([v.index])
                obj.vertex_groups['Head'].add([v.index], 1., 'REPLACE')
        normalize_weights(obj)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [body, face, eyes, brows, beard]: obj.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    # Only the face consumes this attribute as a mask. Neutral white on all
    # other surfaces preserves glTF standard materials such as the collar.
    skin_vertices = {v for p in body.data.polygons
                     if body.data.materials[p.material_index].name == 'FaceSkin'
                     for v in p.vertices}
    coverage = body.data.color_attributes['FacialCoverage']
    for v in body.data.vertices:
        if v.index not in skin_vertices:
            coverage.data[v.index].color = (1, 1, 1, 1)
    # Remove the old eye slot and collapse the new EyeSurface name to a stable
    # runtime contract (Blender otherwise appends .001 to duplicate names).
    used = {p.material_index for p in body.data.polygons}
    for i in reversed(range(len(body.data.materials))):
        if i not in used: body.data.materials.pop(index=i)
    for m in body.data.materials:
        if m.name.startswith('EyeSurface.'):
            unused = bpy.data.materials.get('EyeSurface')
            if unused and unused.users == 0: bpy.data.materials.remove(unused)
            m.name = 'EyeSurface'
    # The existing body was already normalized. Re-normalizing it here would
    # introduce rounding drift in protected garment weights on every rebuild.
    body.data.calc_loop_triangles()
    assert not body.data.validate(clean_customdata=False)
    add_blink(body)
    body['asset_revision'] = 'expressive-face-groom-2026-10-14'
    bpy.context.preferences.filepaths.save_version = 0
    editable = SOURCE / f'meshy_{role}_head.blend'
    bpy.ops.wm.save_as_mainfile(filepath=str(editable))
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True); rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    target = ASSETS / f'meshy_{role}.glb'
    baseline = ASSETS / ('meshy_player.glb' if role == 'striker' else 'goalkeeper_v4.glb')
    bpy.ops.export_scene.gltf(filepath=str(target), export_format='GLB', use_selection=True,
        export_animations=True, export_animation_mode='NLA_TRACKS', export_apply=False,
        export_vertex_color='NAME', export_vertex_color_name='FacialCoverage',
        export_all_vertex_colors=False,
        export_yup=True, export_skins=True, export_all_influences=False)
    copied = preserve_unedited_clip_channels(baseline, target, keep_authored_arms=False)
    report = {'role':role, 'source':str(editable.relative_to(ROOT)),
        'removed_head_faces':removed_faces, 'triangles':len(body.data.loop_triangles),
        'vertices':len(body.data.vertices), 'animation_channels_preserved':copied,
        'eye_centers_blender':{str(k):list(v) for k,v in centers.items()},
        'materials':[m.name for m in body.data.materials],
        'sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
    REPORT.mkdir(parents=True, exist_ok=True)
    (REPORT/f'{role}.json').write_text(json.dumps(report,indent=2)+'\n')
    print('REBUILT_HEAD', json.dumps(report), flush=True)


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['prepare']
    if args == ['prepare']:
        prepare()
    else:
        for role in args:
            assert role in ['striker','keeper']
            build(role)
