"""Refine the Meshy athlete in Blender; keep the authored skeleton and clips.

Deterministic source pass: local smooth subdivision, garment shells with turned
edges, a fitted collar, and individually tapered hair/beard fibers. Atlas UVs
and lettering UV2 survive. No dependency on an image-generation service.

blender -b --python apps/free-kick-3d/tools/build_player_realism.py -- striker keeper
"""
import bisect
import hashlib
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pose_striker_arms import preserve_unedited_clip_channels

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "source-assets/footballer"
ASSETS = ROOT / "apps/free-kick-3d/assets/footballer"
REPORT = ROOT / "docs/research/player-realism-2026-10-14"


def smooth(a, b, x):
    t = max(0., min(1., (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def material(name, color, roughness=.65):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def normalize_weights(body):
    for v in body.data.vertices:
        pairs = sorted(((g.group, g.weight) for g in v.groups if g.weight > 1e-7),
                       key=lambda pair: pair[1], reverse=True)[:4]
        total = sum(w for _, w in pairs)
        assert total > 0, f"Unbound vertex {v.index}"
        for group_id in [g.group for g in v.groups]:
            body.vertex_groups[group_id].remove([v.index])
        for index, weight in pairs:
            body.vertex_groups[index].add([v.index], weight / total, 'REPLACE')


def build(role):
    rng = random.Random(141026)
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE / f"meshy_{role}_cloth_v2.blend"))
    body = bpy.data.objects["FootballerBody"]
    rig = bpy.data.objects["FootballerRig"]
    mesh = body.data
    mesh.calc_loop_triangles()
    before = len(mesh.loop_triangles)
    # Custom normals from the generated mesh are stale after the rig/cloth
    # edits. Rebuild from the final surface, including the new subdivisions.
    if "custom_normal" in mesh.attributes:
        mesh.attributes.remove(mesh.attributes["custom_normal"])
    for edge in mesh.edges:
        edge.use_edge_sharp = False
    for p in mesh.polygons:
        p.use_smooth = True
    bm = bmesh.new()
    bm.from_mesh(mesh)
    rest = bm.verts.layers.float_vector.get("MeshyRestPosition")
    selected = [e for e in bm.edges if all(v[rest].z > 1.62 for v in e.verts)
                or (e.calc_length() > .018 and all(.22 < v[rest].z < 1.61 for v in e.verts))]
    bmesh.ops.subdivide_edges(bm, edges=selected, cuts=1, smooth=.38,
                             use_grid_fill=True, use_smooth_even=True)
    # Fair the scan's millimetric ripples, keeping eye openings, nose and lips.
    original = {v: v.co.copy() for v in bm.verts}
    for _ in range(5):
        positions = {v: v.co.copy() for v in bm.verts}
        for v in bm.verts:
            p = v[rest]
            head = p.z > 1.63
            if not head or not v.link_edges:
                continue
            front = -p.y
            eyes = abs(p.z - 1.7635) < .013 and front > .065
            lips = abs(p.z - 1.691) < .012 and abs(p.x) < .04 and front > .07
            nose = 1.71 < p.z < 1.76 and abs(p.x) < .023 and front > .083
            weight = .08 if eyes or lips or nose else .26
            neighbors = [e.other_vert(v) for e in v.link_edges]
            average = sum((positions[n] for n in neighbors), Vector()) / len(neighbors)
            target = positions[v].lerp(average, weight)
            delta = target - original[v]
            if delta.length > .002:
                target = original[v] + delta.normalized() * .002
            v.co = target
    # Relax noisy scan facets on broad fabric panels, while retaining the
    # larger folds and all anatomical landmarks.
    cloth_vertices = [v for v in bm.verts if v.link_faces and
                      all(f.material_index == 1 for f in v.link_faces)]
    for _ in range(6):
        bmesh.ops.smooth_vert(bm, verts=cloth_vertices, factor=.35,
                             use_axis_x=True, use_axis_y=True, use_axis_z=True)
    # Preserve authored winding. Automatic outward reorientation is ambiguous
    # on this scan's open components and can invert entire arms/legs.
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()

    # Build sampling data once. Coordinates use Blender Z-up / -Y-forward.
    raw = [e.vector.copy() for e in mesh.attributes["MeshyRestPosition"].data]
    atlas = mesh.materials[0].node_tree.nodes.get("Principled BSDF").inputs["Base Color"].links[0].from_node.image
    pixels = list(atlas.pixels)
    width, height = atlas.size
    uv0 = mesh.uv_layers["UVMap"]

    def pigment(uv):
        x, y = int(uv.x * width) % width, int(uv.y * height) % height
        index = (y * width + x) * 4
        return pixels[index:index + 3]

    shorts = mesh.materials[0].copy()
    shorts.name = "TailoredShorts"
    mesh.materials.append(shorts)
    shorts_index = len(mesh.materials) - 1
    jersey_index = next(i for i, m in enumerate(mesh.materials) if m.name.split('.')[0] == "Jersey")
    collar_material = material("CollarKnit", (.015, .022, .030), .86)
    for face in mesh.polygons:
        center = sum((raw[i] for i in face.vertices), Vector()) / len(face.vertices)
        uv = sum((uv0.data[l].uv for l in face.loop_indices), Vector((0, 0))) / len(face.vertices)
        rgb = pigment(uv)
        if .67 < center.z < 1.035 and abs(center.x) < .28 and max(rgb) < .24 and rgb[0] - rgb[1] < .055:
            face.material_index = shorts_index

    # Give the existing fitted garments a real outer surface and folded edge.
    # Splitting at the cloth boundary prevents smoothing across fabric/skin.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    garment_ids = {jersey_index, shorts_index}
    edges = [e for e in bm.edges if len(e.link_faces) == 2
             and len({f.material_index for f in e.link_faces}) > 1
             and any(f.material_index in garment_ids for f in e.link_faces)]
    bmesh.ops.split_edges(bm, edges=edges)
    bm.normal_update()
    cloth_verts = [v for v in bm.verts if v.link_faces and all(f.material_index in garment_ids for f in v.link_faces)]
    for v in cloth_verts:
        v.co += v.normal * .0018
    # Perimeter returns, not duplicated hidden garment faces: 2 mm thickness
    # at cuffs, waist and leg openings without doubling the whole jersey.
    boundary = [e for e in bm.edges if e.is_boundary and e.link_faces[0].material_index in garment_ids]
    boundary_count = len(boundary)
    for material_id in garment_ids:
        perimeter = [e for e in bm.edges if e.is_boundary and e.link_faces[0].material_index == material_id]
        samples = [(v.co.copy(), v.normal.copy()) for e in perimeter for v in e.verts]
        nearest = KDTree(len(samples))
        for i, (p, n) in enumerate(samples):
            nearest.insert(p, i)
        nearest.balance()
        result = bmesh.ops.extrude_edge_only(bm, edges=perimeter)
        for element in result['geom']:
            if isinstance(element, bmesh.types.BMVert):
                _, i, _ = nearest.find(element.co)
                element.co -= samples[i][1] * .0035
            elif isinstance(element, bmesh.types.BMFace):
                element.material_index = material_id
    for face in bm.faces:
        face.smooth = True
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    mesh.calc_loop_triangles()

    # Extra geometry is joined back to the skinned body so all entry points
    # (editor, home, striker and goalkeeper) share the same material API.
    coords = [v.co.copy() for v in mesh.vertices]
    weights = [{g.group: g.weight for g in v.groups} for v in mesh.vertices]
    triangles = [tuple(t.vertices) for t in mesh.loop_triangles]
    tree = BVHTree.FromPolygons(coords, triangles, all_triangles=True)
    extras = []

    def make_geometry(name, vertices, faces, uvs, assignments, mat):
        data = bpy.data.meshes.new(name)
        data.from_pydata(vertices, [], faces)
        data.materials.append(mat)
        obj = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(obj)
        for group in body.vertex_groups:
            obj.vertex_groups.new(name=group.name)
        for i, values in enumerate(assignments):
            for group, weight in values.items():
                obj.vertex_groups[group].add([i], weight, 'REPLACE')
        uv = data.uv_layers.new(name="UVMap")
        lettering = data.uv_layers.new(name="JerseyPrintUV")
        for loop in data.loops:
            uv.data[loop.index].uv = uvs[loop.vertex_index]
            lettering.data[loop.index].uv = (-2, -2)
        for face in data.polygons:
            face.use_smooth = True
        extras.append(obj)
        return obj

    # Smooth, fitted rib-knit neck band. Project onto the existing neckline;
    # the double row gives the trim a visible sewn edge from side and back.
    vertices, faces, uvs, assignments = [], [], [], []
    for j in range(128):
        angle = j / 128 * math.tau
        front = max(0., -math.sin(angle))
        # The source neck is offset 35 mm toward the back of the body; using
        # the body's origin here would leave the front of the collar floating.
        p = Vector((.081 * math.cos(angle), .035 + .071 * math.sin(angle),
                    1.600 + .016 * math.sin(angle) - .024 * front))
        hit, normal, index, distance = tree.find_nearest(p)
        # Sample a common ring so it stays smooth rather than following every
        # noisy atlas triangle at the neck boundary.
        axis = Vector((math.cos(angle), math.sin(angle), .35)).normalized()
        center = p + axis * .001
        nearest = min(triangles[index], key=lambda i: (coords[i] - hit).length_squared)
        for k in range(8):
            theta = k / 8 * math.tau
            radial = Vector((math.cos(angle), math.sin(angle), 0))
            point = center + radial * (.002 + math.cos(theta) * .007 + math.sin(theta) * .0015)
            point += Vector((0, 0, .002 - math.cos(theta) * .008 + math.sin(theta) * .0015))
            vertices.append(point)
            assignments.append(weights[nearest])
            uvs.append((j / 128, k / 8))
    for j in range(128):
        for k in range(8):
            faces.append((j * 8 + k, ((j + 1) % 128) * 8 + k,
                          ((j + 1) % 128) * 8 + (k + 1) % 8, j * 8 + (k + 1) % 8))
    make_geometry("FittedCollar", vertices, faces, uvs, assignments, collar_material)

    # Fitted sclera/iris surfaces sit inside the scanned eyelids. Their color
    # and wet specular response are independent of skin recoloring.
    vertices, faces, uvs, assignments = [], [], [], []
    for sign in (-1, 1):
        base = len(vertices)
        for row in range(13):
            v = row / 12
            for column in range(33):
                u = (column + .01) / 32.02
                dx = (u - .5) * .034
                taper = math.sin(u * math.pi) ** .65
                dz = (v - .5) * .0084 * taper
                x, z = sign * .033 + dx, 1.7635 + dz
                hit, normal, index, distance = tree.ray_cast(Vector((x, -.3, z)), Vector((0, 1, 0)))
                assert hit is not None
                convex = max(0., 1 - (dx / .017) ** 2) * .0015
                point = hit + Vector((0, -.00065 - convex, 0))
                vertices.append(point)
                uvs.append((u, .5 + dz / .0084))
                assignments.append({body.vertex_groups['Head'].index: 1.})
        for row in range(12):
            for column in range(32):
                i = base + row * 33 + column
                faces.append((i, i + 1, i + 34, i + 33))
    make_geometry("EyeSurface", vertices, faces, uvs, assignments,
                  material("EyeSurface", (.52, .50, .45), .24))

    # Surface-area-weighted samples prevent clumps caused by uneven topology.
    uv0 = mesh.uv_layers["UVMap"]
    pools = {"HairGroom": [], "BeardGroom": [], "BrowGroom": []}
    for tri in mesh.loop_triangles:
        p = sum((coords[i] for i in tri.vertices), Vector()) / 3
        if p.z < 1.635 or tri.material_index != 0:
            continue
        uv = sum((uv0.data[l].uv for l in tri.loops), Vector((0, 0))) / 3
        rgb = pigment(uv)
        value = .2126 * rgb[0] + .7152 * rgb[1] + .0722 * rgb[2]
        front = -p.y
        hair = (p.z > 1.798 or (p.z > 1.71 and front < .021)) and value < .27
        brow = ((abs(p.x) - .039) / .029) ** 2 + ((p.z - 1.779) / .006) ** 2 < 1 and front > .062 and value < .34
        mouth = (p.x / .036) ** 2 + ((p.z - 1.690) / .010) ** 2 < 1.0
        beard = 1.64 < p.z < 1.726 and front > .012 and value < .39 and not mouth
        kind = "HairGroom" if hair else "BrowGroom" if brow else "BeardGroom" if beard else None
        if kind:
            pools[kind].append((tri.area, tuple(tri.vertices)))

    groom_counts = {}
    for kind, count in [("HairGroom", 3400), ("BeardGroom", 2300), ("BrowGroom", 340)]:
        pool = pools[kind]
        cumulative, total = [], 0.
        for area, _ in pool:
            total += area
            cumulative.append(total)
        assert total > 0, kind
        vertices, faces, uvs, assignments = [], [], [], []
        for strand in range(count):
            _, ids = pool[bisect.bisect_left(cumulative, rng.random() * total)]
            a, b = rng.random(), rng.random()
            if a + b > 1:
                a, b = 1 - a, 1 - b
            factors = (a, b, 1 - a - b)
            p = sum((coords[i] * f for i, f in zip(ids, factors)), Vector())
            normal = sum((mesh.vertices[i].normal * f for i, f in zip(ids, factors)), Vector()).normalized()
            values = {}
            for i, f in zip(ids, factors):
                for group, weight in weights[i].items():
                    values[group] = values.get(group, 0) + weight * f
            if kind == "HairGroom":
                direction = Vector((.85, .25, .42 if p.z > 1.82 else -.65))
                length = rng.uniform(.008, .019) if p.z > 1.82 else rng.uniform(.003, .008)
                radius = rng.uniform(.00025, .00048)
                lift = length * .28
            elif kind == "BeardGroom":
                direction = Vector((p.x * 3, -.1, -1))
                length, radius, lift = rng.uniform(.0012, .003), rng.uniform(.00009, .00018), .00055
            else:
                direction = Vector((1 if p.x > 0 else -1, 0, .18))
                length, radius, lift = rng.uniform(.002, .0045), .00016, .0004
            direction = (direction - normal * direction.dot(normal)).normalized()
            side = direction.cross(normal).normalized()
            base = len(vertices)
            # Three-sided tapered fibers: opaque, stable silhouettes and no
            # sorting/alpha-overdraw cost. Three longitudinal segments.
            for step in range(4):
                t = step / 3
                center = p + normal * (.00025 + math.sin(t * math.pi * .8) * lift) + direction * (length * t)
                taper = (1 - t) * .86 + .14
                for corner in range(3):
                    angle = corner * math.tau / 3
                    vertices.append(center + (side * math.cos(angle) + normal * math.sin(angle)) * radius * taper)
                    assignments.append(values)
                    uvs.append(((strand % 101) / 101, t))
            for step in range(3):
                for corner in range(3):
                    i = base + step * 3 + corner
                    next_i = base + step * 3 + (corner + 1) % 3
                    faces.append((i, i + 3, next_i + 3, next_i))
        make_geometry(kind, vertices, faces, uvs, assignments,
                      material(kind, (.025, .019, .014), .68))
        groom_counts[kind] = count

    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    for extra in extras:
        extra.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    normalize_weights(body)
    mesh = body.data
    mesh.calc_loop_triangles()
    assert not mesh.validate(clean_customdata=False)
    body['asset_revision'] = 'player-realism-2026-10-14'
    bpy.context.preferences.filepaths.save_version = 0
    editable = SOURCE / f"meshy_{role}_realism.blend"
    bpy.ops.wm.save_as_mainfile(filepath=str(editable))
    bpy.ops.object.select_all(action='DESELECT')
    body.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    target = ASSETS / f"meshy_{role}.glb"
    # Use a persistent, exact clip baseline from the preceding build. It is
    # unchanged by this builder, including on subsequent deterministic rebuilds.
    baseline = ASSETS / ("meshy_player.glb" if role == "striker" else "goalkeeper_v4.glb")
    bpy.ops.export_scene.gltf(filepath=str(target), export_format='GLB', use_selection=True,
                             export_animations=True, export_animation_mode='NLA_TRACKS',
                             export_apply=False, export_yup=True, export_skins=True,
                             export_all_influences=False)
    copied = preserve_unedited_clip_channels(baseline, target, keep_authored_arms=False)
    report = {"role": role, "source": str(editable.relative_to(ROOT)),
              "triangles_before": before, "triangles_after": len(mesh.loop_triangles),
              "vertices": len(mesh.vertices), "garment_return_edges": boundary_count,
              "groom_fibers": groom_counts, "animation_channels_preserved": copied,
              "sha256": hashlib.sha256(target.read_bytes()).hexdigest()}
    REPORT.mkdir(parents=True, exist_ok=True)
    (REPORT / f"{role}.json").write_text(json.dumps(report, indent=2) + '\n')
    print("PLAYER_REALISM", json.dumps(report), flush=True)


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['striker', 'keeper']
    for role in args:
        assert role in ('striker', 'keeper')
        build(role)
