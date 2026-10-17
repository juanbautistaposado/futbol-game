extends Node3D

## Paint and corner furniture are decorative: the playable pitch stays unchanged.
func _ready() -> void:
	name = "PitchDetails"
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("e3e5cf")
	paint.roughness = 0.94
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES, paint)
	for side in [-1, 1]:
		var half_angle := acos(5.5 / 9.15)
		arc(lines, Vector3(0, 0.024, side * 41.5), 9.15, -half_angle, half_angle, side, 48)
		for edge in [-1, 1]:
			# Quarter circle inside each corner, one metre from its flag.
			arc(lines, Vector3(edge * 34.0, 0.024, side * 52.5), 1.0, -PI / 2.0 if edge == 1 else 0.0, 0.0 if edge == 1 else PI / 2.0, side, 16)
			corner_flag(Vector3(edge * 34.0, 0, side * 52.5), edge)
	arc(lines, Vector3(0, 0.024, 0), 0.10, 0, TAU, 1, 24, 0.10)
	lines.surface_end()
	var markings := MeshInstance3D.new()
	markings.name = "PenaltyArcsAndCorners"
	markings.mesh = lines
	markings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(markings)

func arc(mesh: ImmediateMesh, center: Vector3, radius: float, start: float, end: float, side: int, segments: int, thickness := 0.09) -> void:
	for i in segments:
		var a := lerpf(start, end, float(i) / segments)
		var b := lerpf(start, end, float(i + 1) / segments)
		var direction_a := Vector3(sin(a), 0, -side * cos(a))
		var direction_b := Vector3(sin(b), 0, -side * cos(b))
		var vertices := [center + direction_a * (radius - thickness / 2), center + direction_a * (radius + thickness / 2), center + direction_b * (radius + thickness / 2), center + direction_b * (radius - thickness / 2)]
		for index in [0, 1, 2, 0, 2, 3]:
			mesh.surface_set_normal(Vector3.UP)
			mesh.surface_add_vertex(vertices[index])

func corner_flag(location: Vector3, outward: int) -> void:
	var pole := MeshInstance3D.new()
	pole.name = "CornerFlagPole"
	var cylinder := CylinderMesh.new()
	cylinder.height = 1.5
	cylinder.top_radius = 0.022
	cylinder.bottom_radius = 0.022
	cylinder.radial_segments = 12
	pole.mesh = cylinder
	pole.position = location + Vector3(0, 0.75, 0)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("e7ece5")
	white.roughness = 0.55
	pole.material_override = white
	add_child(pole)
	var cloth := MeshInstance3D.new()
	cloth.name = "CornerFlagCloth"
	var plane := PlaneMesh.new()
	plane.orientation = PlaneMesh.FACE_Z
	plane.size = Vector2(0.45, 0.30)
	plane.subdivide_width = 8
	cloth.mesh = plane
	cloth.position = location + Vector3(outward * 0.225, 1.32, 0)
	cloth.scale.x = outward
	var flag_material := ShaderMaterial.new()
	flag_material.shader = preload("res://shaders/corner_flag.gdshader")
	cloth.material_override = flag_material
	add_child(cloth)
