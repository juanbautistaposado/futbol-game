"""Give the shared Meshy atlas a recolorable jersey material without new UVs."""
import bpy
from mathutils import Vector


def split_jersey(body):
    mesh = body.data
    original = mesh.materials[0]
    existing = bpy.data.materials.get('Jersey')
    if existing is not None:
        existing.name = 'LegacyJersey'
    jersey = original.copy()
    jersey.name = 'Jersey'
    mesh.materials.append(jersey)
    jersey_index = len(mesh.materials) - 1
    for mat in [original, jersey]:
        bsdf = mat.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Roughness'].default_value = .7
        for node in mat.node_tree.nodes:
            if node.type == 'NORMAL_MAP':
                node.inputs['Strength'].default_value = .45
    rest = mesh.attributes['MeshyRestPosition']
    bsdf = original.node_tree.nodes.get('Principled BSDF')
    image = bsdf.inputs['Base Color'].links[0].from_node.image
    pixels = list(image.pixels)
    width, height = image.size
    uv = mesh.uv_layers['UVMap']
    count = 0
    for polygon in mesh.polygons:
        point = sum((rest.data[i].vector for i in polygon.vertices), Vector()) / len(polygon.vertices)
        if not .985 < point.z < 1.615:
            continue
        colors = []
        for loop in polygon.loop_indices:
            coord = uv.data[loop].uv
            x, y = int(coord.x * width) % width, int(coord.y * height) % height
            colors.append(pixels[(y * width + x) * 4:(y * width + x) * 4 + 3])
        rgb = [sum(c[i] for c in colors) / len(colors) for i in range(3)]
        if max(rgb) > .28 and (max(rgb) - min(rgb)) / max(rgb) < .24:
            polygon.material_index = jersey_index
            count += 1
    return count
