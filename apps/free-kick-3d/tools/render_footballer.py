"""Render a Blender character source for visual comparison.

Usage: blender -b --factory-startup --python render_footballer.py -- SOURCE.blend OUTPUT.png
"""

import sys
from pathlib import Path

import bpy
from mathutils import Vector


args = sys.argv[sys.argv.index("--") + 1 :]
source = Path(args[0]).resolve()
output = Path(args[1]).resolve()
bpy.ops.wm.open_mainfile(filepath=str(source))
scene = bpy.context.scene

camera_data = bpy.data.cameras.new("Character preview camera")
camera = bpy.data.objects.new("Character preview camera", camera_data)
scene.collection.objects.link(camera)
camera.location = (2.7, -4.5, 2.05)
target = Vector((0, 0, 1.05))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 2.9
scene.camera = camera

def add_light(name, location, power, size):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = power
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


add_light("Key", (-2, -3, 4), 750, 4)
add_light("Rim", (2, 2, 3), 950, 3)
world = bpy.data.worlds.new("Character preview world")
world.use_nodes = True
world.node_tree.nodes.get("Background").inputs["Color"].default_value = (0.08, 0.11, 0.15, 1)
world.node_tree.nodes.get("Background").inputs["Strength"].default_value = 0.7
scene.world = world

scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 640
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(output)
scene.render.film_transparent = False
scene.view_settings.view_transform = "AgX"
bpy.ops.render.render(write_still=True)
print("CHARACTER_PREVIEW", output)
