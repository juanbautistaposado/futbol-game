"""Fit retained scalp and grow a short beard on the reconstructed anatomy."""
import bisect
import math
import random
from collections import Counter, defaultdict

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

from build_player_realism import smooth

BEARD_STRANDS = 8500
BEARD_RINGS = 3


def fit_scalp(mesh, scalp_faces, head_tree):
    center = Vector((0, .015, 1.77))

    def correction(p):
        radial = p - center
        direction = radial.normalized()
        # Cast from outside: avoids an inward normal or a nearby ear capturing
        # a root on the rear skull. Preserve the old sculpt's positive volume.
        hit, normal, _, _ = head_tree.ray_cast(center + direction * .30, -direction)
        if hit is None:
            return Vector()
        clearance = (hit - center).length + .0020 - radial.length
        return direction * max(0., clearance)

    ids = {v for p in mesh.polygons if p.index in scalp_faces for v in p.vertices}
    for i in ids:
        mesh.vertices[i].co += correction(mesh.vertices[i].co)
    # Relax the clipped scan's sawtooth nape edge along its boundary, then
    # project it back above the skull. Front hair styling stays authored.
    edges = Counter(tuple(sorted(edge)) for p in mesh.polygons if p.index in scalp_faces
                    for edge in p.edge_keys)
    neighbors = defaultdict(list)
    for (a, b), count in edges.items():
        if count == 1:
            neighbors[a].append(b)
            neighbors[b].append(a)
    for _ in range(5):
        updates = {}
        for i, linked in neighbors.items():
            p = mesh.vertices[i].co
            if p.y < -.015 or p.z > 1.78 or len(linked) != 2:
                continue
            average = sum((mesh.vertices[j].co for j in linked), Vector()) / 2
            point = p.lerp(average, .45)
            updates[i] = point + correction(point)
        for i, point in updates.items():
            mesh.vertices[i].co = point
    hair_index = next(i for i, m in enumerate(mesh.materials) if m.name == 'HairGroom')
    ids = sorted({v for p in mesh.polygons if p.material_index == hair_index for v in p.vertices})
    assert len(ids) % 12 == 0
    for start in range(0, len(ids), 12):
        group = ids[start:start + 12]
        root = sum((mesh.vertices[i].co for i in group[:3]), Vector()) / 3
        shift = correction(root)
        for i in group:
            mesh.vertices[i].co += shift


def beard_coverage(p, uv):
    x, y, z = abs(p.x), p.y, p.z
    cheek_line = 1.691 + .053 * smooth(.020, .070, x)
    jaw = (1 - smooth(cheek_line - .006, cheek_line + .004, z)) * smooth(1.632, 1.651, z)
    moustache = (1 - smooth(.024, .033, x)) * smooth(1.692, 1.698, z) * (1 - smooth(1.706, 1.712, z))
    # The dedicated lip island is a more reliable exclusion than a rectangular
    # world-space cutout. COLOR travels with the skinned mesh in every clip.
    lip = math.hypot((uv.x - .5) / .067, (uv.y - .290) / .060)
    no_lip = smooth(.93, 1.18, lip)
    front = 1 - smooth(-.028, .008, y)
    no_ear = 1 - smooth(.071, .081, x)
    return max(jaw, moustache) * front * no_lip * no_ear


def build_beard(face, body):
    mesh = face.data
    coverage = mesh.color_attributes.new(name='FacialCoverage', type='FLOAT_COLOR', domain='POINT')
    mesh.color_attributes.active_color = coverage
    mesh.color_attributes.render_color_index = 0
    masks = [[] for _ in mesh.vertices]
    uv = mesh.uv_layers['UVMap']
    for p in mesh.polygons:
        if p.material_index != 0:
            continue
        for l in p.loop_indices:
            index = mesh.loops[l].vertex_index
            masks[index].append(beard_coverage(mesh.vertices[index].co, uv.data[l].uv))
    values = [sum(m) / len(m) if m else 0. for m in masks]
    for i, value in enumerate(values):
        coverage.data[i].color = (value, 0, 0, 1)
    mesh.calc_loop_triangles()
    skin_tree = BVHTree.FromPolygons([v.co for v in mesh.vertices],
        [tuple(t.vertices) for t in mesh.loop_triangles if t.material_index == 0], all_triangles=True)
    triangles, cumulative, total = [], [], 0.
    for t in mesh.loop_triangles:
        if t.material_index != 0:
            continue
        if max(values[i] for i in t.vertices) < .01:
            continue
        total += t.area
        triangles.append(tuple(t.vertices))
        cumulative.append(total)
    rng = random.Random(20261015)
    vertices, polygons, uv_values = [], [], []
    count = 0
    while count < BEARD_STRANDS:
        ids = triangles[bisect.bisect_left(cumulative, rng.random() * total)]
        r, s = math.sqrt(rng.random()), rng.random()
        weights = (1-r, r*(1-s), r*s)
        density = sum(values[i]*w for i, w in zip(ids, weights))
        if rng.random() > density:
            continue
        root = sum((mesh.vertices[i].co*w for i, w in zip(ids, weights)), Vector())
        normal = sum((mesh.vertices[i].normal*w for i, w in zip(ids, weights)), Vector()).normalized()
        # Readable swept fibers, not almost invisible straight stubble. Small
        # coherent changes in direction break up rows without random spikes.
        moustache = root.z > 1.692 and abs(root.x) < .034
        chin = 1 - smooth(.018, .042, abs(root.x))
        sweep = .28 + .16*math.sin(root.z*760 + abs(root.x)*190)
        direction = Vector((math.copysign(sweep, root.x), .08, -1))
        if moustache:
            direction.x = math.copysign(1.5, root.x)
            direction.z = -.65
        direction = (direction - normal * direction.dot(normal)).normalized()
        side = direction.cross(normal).normalized()
        length = rng.uniform(.0045, .0070) * (.65 + .35*density)
        length *= .70 if moustache else 1 + chin*.25
        # Slightly wider than a literal follicle so individual curved hairs
        # remain visible at the game's portrait scale and after the glTF LOD.
        radius = rng.uniform(.00019, .00024)
        curl = rng.uniform(-.00035, .00035)
        base = len(vertices)
        for step in range(BEARD_RINGS):
            t = step/(BEARD_RINGS-1)
            point = root + direction*length*t + side*curl*math.sin(t*math.pi)
            surface, local_normal, _, _ = skin_tree.find_nearest(point)
            lift = .00014 + .0007*math.sin(t*math.pi*.85)
            if surface is not None:
                # Follow the chin's curvature rather than cutting through it.
                point += local_normal*max(lift-(point-surface).dot(local_normal), 0.)
            for corner in range(3):
                angle = corner*math.tau/3
                vertices.append(point + (side*math.cos(angle)+normal*math.sin(angle))*radius*(1-.60*t))
                uv_values.append(((count % 101)/101, t))
        for step in range(BEARD_RINGS-1):
            for corner in range(3):
                a=base+step*3+corner; b=base+step*3+(corner+1)%3
                polygons.append((a,a+3,b+3,b))
        count += 1
    data = bpy.data.meshes.new('FittedShortBeard')
    data.from_pydata(vertices, [], polygons)
    data.materials.append(next(m for m in body.data.materials if m.name == 'BeardGroom'))
    beard = bpy.data.objects.new('FittedShortBeard', data)
    bpy.context.collection.objects.link(beard)
    for group in body.vertex_groups:
        beard.vertex_groups.new(name=group.name)
    beard.vertex_groups['Head'].add(list(range(len(vertices))), 1., 'REPLACE')
    uv = data.uv_layers.new(name='UVMap')
    lettering = data.uv_layers.new(name='JerseyPrintUV')
    for loop in data.loops:
        uv.data[loop.index].uv = uv_values[loop.vertex_index]
        lettering.data[loop.index].uv = (-2, -2)
    for p in data.polygons:
        p.use_smooth = True
    return beard
