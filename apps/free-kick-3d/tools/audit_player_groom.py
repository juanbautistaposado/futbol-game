"""Blender geometry regression check for the nape and fitted beard.

blender -b --factory-startup --python tools/audit_player_groom.py -- /tmp/player-groom-baseline
"""
import collections
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, str(Path(__file__).resolve().parent))
from audit_player_head import GLB, ASSETS, ROOT, surfaces
from fit_player_groom import BEARD_RINGS, BEARD_STRANDS


def rows(model, name):
    attrs = surfaces(model)[name]['attributes']
    keys = ['POSITION', 'TEXCOORD_0', 'TEXCOORD_1', 'JOINTS_0', 'WEIGHTS_0']
    return collections.Counter(tuple(x for a in row for x in a)
                               for row in zip(*(model.values(attrs[k]) for k in keys)))


def audit(role, prior):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / f'source-assets/footballer/meshy_{role}_head.blend'))
    mesh = bpy.data.objects['FootballerBody'].data
    mesh.calc_loop_triangles()
    indices = {m.name: i for i, m in enumerate(mesh.materials)}
    trees = {}
    for name in ['FaceSkin', 'MeshyPlayer', 'EyeSurface']:
        triangles = [tuple(t.vertices) for t in mesh.loop_triangles if t.material_index == indices[name]]
        trees[name] = BVHTree.FromPolygons([v.co for v in mesh.vertices], triangles, all_triangles=True)
    clearance = []
    for ix in range(21):
        for iz in range(25):
            origin = Vector((-.05 + .005*ix, .3, 1.74 + .005*iz))
            scalp = trees['MeshyPlayer'].ray_cast(origin, Vector((0,-1,0)))[0]
            skin = trees['FaceSkin'].ray_cast(origin, Vector((0,-1,0)))[0]
            assert scalp is not None and skin is not None, ('Missing scalp', tuple(origin))
            gap = scalp.y - skin.y
            assert gap > .0007, ('Skin penetrates nape', tuple(origin), gap)
            clearance.append(gap)
    ids = sorted({v for p in mesh.polygons if p.material_index == indices['BeardGroom'] for v in p.vertices})
    stride = BEARD_RINGS * 3
    assert len(ids) == BEARD_STRANDS*stride
    distances = []
    lengths = []
    for i in range(0, len(ids), stride):
        root = sum((mesh.vertices[j].co for j in ids[i:i+3]), Vector()) / 3
        hit, normal, _, distance = trees['FaceSkin'].find_nearest(root)
        assert distance < .0005, ('Detached beard root', distance)
        assert (root-hit).dot(normal) > -.00002, 'Root inside skin'
        assert root.z > 1.632 and abs(root.x) < .081, 'Beard on neck or ear'
        distances.append(distance)
        tip = sum((mesh.vertices[j].co for j in ids[i+stride-3:i+stride]), Vector()) / 3
        lengths.append((tip-root).length)
        # Fibers must read as hair rather than the previous submillimetre dots.
        assert .001 < lengths[-1] < .010
    new = GLB(ASSETS/f'meshy_{role}.glb')
    old = GLB(prior/f'meshy_{role}.glb')
    assert rows(new, 'EyeSurface') == rows(old, 'EyeSurface'), 'Eyeballs moved'
    # Blender recalculates normals when exporting morph targets; tolerate only
    # floating-point drift while requiring geometry, UV and bindings exact.
    def eye_normals(model):
        a = surfaces(model)['EyeSurface']['attributes']
        return sorted(zip(model.values(a['POSITION']), model.values(a['TEXCOORD_0']), model.values(a['NORMAL'])))
    normal_drift = max(abs(x-y) for a,b in zip(eye_normals(old), eye_normals(new)) for x,y in zip(a[2],b[2]))
    assert normal_drift < .0001
    apertures = []
    closed_vertices = [v.co for v in bpy.data.objects['FootballerBody'].data.shape_keys.key_blocks['Blink'].data]
    closed_tree = BVHTree.FromPolygons(closed_vertices,
        [tuple(t.vertices) for t in mesh.loop_triangles if t.material_index == indices['FaceSkin']], all_triangles=True)
    for sign in [-1, 1]:
        visible = []
        for iz in range(81):
            z = 1.754 + .00025*iz
            origin = Vector((sign*.0306375, -.3, z))
            eye = trees['EyeSurface'].ray_cast(origin, Vector((0,1,0)))[0]
            skin = trees['FaceSkin'].ray_cast(origin, Vector((0,1,0)))[0]
            if eye is not None and skin is not None and eye.y < skin.y:
                visible.append(z)
        assert visible and 1.766 < max(visible) < 1.771, 'Upper eyelid still covers iris center'
        assert .008 < max(visible)-min(visible) < .014, 'Unnatural eye aperture'
        apertures.append([min(visible), max(visible)])
        # The closed morph must cover the iris, not merely move the brow.
        for z in [1.760, 1.762, 1.764, 1.766]:
            origin = Vector((sign*.0306375, -.3, z))
            eye = trees['EyeSurface'].ray_cast(origin, Vector((0,1,0)))[0]
            lid = closed_tree.ray_cast(origin, Vector((0,1,0)))[0]
            assert lid is not None and lid.y < eye.y, ('Blink does not close', sign, z)
    attrs = surfaces(new)['FaceSkin']['attributes']
    assert 'COLOR_0' in attrs
    color = new.values(attrs['COLOR_0'])
    assert min(c[0] for c in color) == 0 and max(c[0] for c in color) > 0
    # glTF normalizes integer colors on import; zero must remain exact on the
    # forehead, upper nose, rear skull and throat even when beard is enabled.
    for p, c in zip(new.values(attrs['POSITION']), color):
        if p[1] > 1.76 or p[1] < 1.63 or p[2] < -.02:
            assert c[0] == 0, ('Stray beard mask', p, c)
    return {'role': role, 'nape_rays': len(clearance), 'minimum_nape_clearance_m': min(clearance),
            'beard_strands': len(ids)//stride, 'maximum_beard_root_gap_m': max(distances),
            'beard_length_range_m': [min(lengths), max(lengths)],
            'eye_apertures_z_m': apertures, 'eyeball_geometry_exact': True, 'eye_normal_drift': normal_drift,
            'blink_closes_iris': True, 'mask_exported': True}


prior = Path(sys.argv[sys.argv.index('--')+1])
report = [audit(role, prior) for role in ['striker', 'keeper']]
target = ROOT / 'docs/research/player-face-polish-2026-10-14/geometry-checks.json'
target.write_text(json.dumps(report, indent=2)+'\n')
print('GROOM_AUDIT_PASS', json.dumps(report))
