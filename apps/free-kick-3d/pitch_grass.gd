extends Node3D
## Recycled close-range geometry for the playing surface. The turf shader
## supplies the distant pitch; these clipped, curved leaves supply parallax.
const TILE_SIZE := 2.5
const GRID_RADIUS := 3
# Each instance is a three-leaf crown, with ten triangles in total.
# 49 * 1500 * 10 keeps the original maximum of 735,000 triangles.
const BLADES_PER_TILE := 1500
const MEDIUM_BLADES_PER_TILE := 750
const CLOSEUP_BLADES_PER_TILE := 9000
const CLOSEUP_CAMERA_HEIGHT := 1.2
const CLOSEUP_RADIUS := 3.0
const PATTERN_COUNT := 4
const INVALID_CELL := Vector2i(100000, 100000)
const BladeShader = preload("res://shaders/grass_blades.gdshader")

var quality := "alto"
var patches: Array[MultiMeshInstance3D] = []
var patterns: Array[MultiMesh] = []
var blade_material: ShaderMaterial
var _last_cell := INVALID_CELL
var _last_camera: Camera3D
var _visibility_clock := 0.0
var _closeup_active := false

func _ready() -> void:
	name = "PitchGrass"
	blade_material = ShaderMaterial.new()
	blade_material.shader = BladeShader
	for variant in PATTERN_COUNT:
		patterns.append(_make_pattern(_make_blade_mesh(variant), variant))
	for i in (GRID_RADIUS * 2 + 1) * (GRID_RADIUS * 2 + 1):
		var patch := MultiMeshInstance3D.new()
		patch.name = "GrassPatch%02d" % i
		patch.multimesh = patterns[i % PATTERN_COUNT]
		patch.material_override = blade_material
		patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Includes curved tips and their millimetre wind movement.
		patch.custom_aabb = AABB(Vector3(-1.30, -0.01, -1.30), Vector3(2.60, 0.10, 2.60))
		patch.visible = false
		add_child(patch)
		patches.append(patch)
	set_quality(quality)

func set_quality(value: String) -> void:
	quality = value if value in ["bajo", "medio", "alto"] else "alto"
	visible = quality != "bajo"
	_closeup_active = false
	_configure_detail()
	_last_cell = INVALID_CELL
	_visibility_clock = 0.0
	set_process(quality != "bajo")

func _configure_detail() -> void:
	# The dense crowns are allocated once. Changing view or quality exposes
	# another prefix of the same buffers, rather than rebuilding the canopy.
	for pattern in patterns:
		if _closeup_active:
			pattern.visible_instance_count = CLOSEUP_BLADES_PER_TILE/2 if quality == "medio" else CLOSEUP_BLADES_PER_TILE
		else:
			pattern.visible_instance_count = MEDIUM_BLADES_PER_TILE if quality == "medio" else BLADES_PER_TILE
	if blade_material != null:
		blade_material.set_shader_parameter("fade_start", 2.6 if _closeup_active else (8.0 if quality == "medio" else 10.0))
		blade_material.set_shader_parameter("fade_end", 3.2 if _closeup_active else (12.0 if quality == "medio" else 15.0))
		blade_material.set_shader_parameter("focus_radius", CLOSEUP_RADIUS if _closeup_active else (7.5 if quality == "medio" else 8.75))
		blade_material.set_shader_parameter("focus_offset", 0.0 if _closeup_active else 5.0)
		blade_material.set_shader_parameter("focus_fade_width", 0.65 if _closeup_active else 2.5)

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var closeup := camera.global_position.y < CLOSEUP_CAMERA_HEIGHT
	if closeup != _closeup_active:
		_closeup_active = closeup
		_configure_detail()
		_last_cell = INVALID_CELL
		_visibility_clock = 0.0
	var forward := -camera.global_basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.001:
		forward = forward.normalized()
	var focus := camera.global_position + forward * (0.0 if _closeup_active else 5.0)
	var cell := Vector2i(floori(focus.x / TILE_SIZE), floori(focus.z / TILE_SIZE))
	var camera_changed := camera != _last_camera
	if cell != _last_cell or camera_changed:
		_place_patches(cell)
		_last_cell = cell
		_last_camera = camera
		_visibility_clock = 0.0
	_visibility_clock -= delta
	if _visibility_clock <= 0.0:
		_update_visibility(camera, focus)
		_visibility_clock = 0.10

func _place_patches(center: Vector2i) -> void:
	# Hashing a world tile selects stable patterns on revisits. Its transform
	# only changes when the camera crosses a tile or switches match side.
	var index := 0
	for z in range(-GRID_RADIUS, GRID_RADIUS + 1):
		for x in range(-GRID_RADIUS, GRID_RADIUS + 1):
			var cell := center + Vector2i(x, z)
			var pattern_index := posmod(cell.x * 73 + cell.y * 151, PATTERN_COUNT)
			var patch := patches[index]
			patch.multimesh = patterns[pattern_index]
			patch.global_position = Vector3((cell.x + 0.5) * TILE_SIZE, 0.001, (cell.y + 0.5) * TILE_SIZE)
			patch.rotation.y = float(posmod(cell.x * 17 + cell.y * 31, 4)) * PI * 0.5
			index += 1

func _update_visibility(camera: Camera3D, focus: Vector3) -> void:
	var radius := CLOSEUP_RADIUS if _closeup_active else (7.5 if quality == "medio" else 8.75)
	for patch in patches:
		var center := patch.global_position
		var on_pitch := absf(center.x) < 35.25 and absf(center.z) < 53.75
		# Keep intersecting tiles until their last leaves have shrunk away.
		var in_range := Vector2(center.x - focus.x, center.z - focus.z).length() < radius + 1.84
		var in_frustum := false
		if on_pitch and in_range:
			# Testing the four corners prevents a tile popping out when its
			# centre passes the edge of the screen. Godot also culls the AABB.
			in_frustum = camera.is_position_in_frustum(center + Vector3(0, 0.03, 0))
			for offset in [Vector3(-1.30, 0.03, -1.30), Vector3(1.30, 0.03, -1.30), Vector3(-1.30, 0.03, 1.30), Vector3(1.30, 0.03, 1.30)]:
				if in_frustum:
					break
				in_frustum = camera.is_position_in_frustum(center + offset)
		patch.visible = on_pitch and in_range and in_frustum

func _make_pattern(mesh: ArrayMesh, variant: int) -> MultiMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 93587 + variant * 349
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_custom_data = true
	instances.mesh = mesh
	instances.instance_count = CLOSEUP_BLADES_PER_TILE
	# A progressive low-discrepancy distribution keeps every quality prefix
	# evenly covered. Small, seeded jitter breaks its diagonal ordering without
	# the empty holes and dense clumps of independent random placement.
	var pattern_shift := Vector2(rng.randf(), rng.randf())
	for i in CLOSEUP_BLADES_PER_TILE:
		var jitter := 0.33 / sqrt(float(i + 1))
		var sample_x := fposmod(pattern_shift.x + float(i) * 0.754877666 + rng.randf_range(-jitter, jitter), 1.0)
		var sample_z := fposmod(pattern_shift.y + float(i) * 0.569840296 + rng.randf_range(-jitter, jitter), 1.0)
		var location := Vector3((sample_x - 0.5) * TILE_SIZE, 0.0, (sample_z - 0.5) * TILE_SIZE)
		var scale_leaf := Vector3(rng.randf_range(0.85, 1.20), rng.randf_range(0.72, 1.15), rng.randf_range(0.85, 1.20))
		var basis_leaf := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(scale_leaf)
		instances.set_instance_transform(i, Transform3D(basis_leaf, location))
		instances.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), rng.randf(), rng.randf()))
	return instances

func _make_blade_mesh(variant := 0) -> ArrayMesh:
	# Two low, curved leaves fan out from a short basal leaf. Flat cut tips,
	# broad shoulders and an overhanging canopy replace the upright spikes.
	# Four reusable variants change the crown, without more draw calls.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var leaf_ids := PackedVector2Array()
	var indices := PackedInt32Array()
	for leaf in 3:
		var centers: Array[Vector3]
		var widths: Array[float]
		var angle: float
		var offset: Vector3
		if leaf == 0:
			centers = [Vector3.ZERO,Vector3(0,0.016,0.012),Vector3(0.001,0.019,0.034)]
			widths = [0.0042,0.0032,0.0014]
			angle = -0.32+variant*0.055
			offset = Vector3(-0.003,0,0)
		elif leaf == 1:
			centers = [Vector3.ZERO,Vector3(0,0.012,0.010),Vector3(-0.001,0.016,0.026)]
			widths = [0.0036,0.0028,0.0011]
			angle = 0.72-variant*0.07
			offset = Vector3(0.004,0,0.003)
		else:
			centers = [Vector3.ZERO,Vector3(0,0.009,0.015)]
			widths = [0.0035,0.0010]
			angle = -1.14+variant*0.09
			offset = Vector3(-0.002,0,-0.003)
		var rotation := Basis(Vector3.UP,angle)
		var length_variation := 0.94+variant*0.04
		var first := vertices.size()
		for ring in centers.size():
			var tangent := centers[mini(ring+1,centers.size()-1)]-centers[maxi(0,ring-1)]
			var normal := rotation*tangent.cross(Vector3.RIGHT).normalized()
			var progress := float(ring)/(centers.size()-1)
			for edge in [-1.0,1.0]:
				var point := centers[ring]+Vector3(widths[ring]*edge,0,0)
				vertices.append(rotation*point*length_variation+offset)
				normals.append(normal)
				uvs.append(Vector2(0 if edge < 0 else 1,progress))
				leaf_ids.append(Vector2(float(leaf)/2.0,0))
		for segment in centers.size()-1:
			var start := first+segment*2
			for index in [0,2,1,1,2,3]:
				indices.append(start+index)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = leaf_ids
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh
