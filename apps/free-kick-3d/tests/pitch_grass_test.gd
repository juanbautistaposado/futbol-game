extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var grass = load("res://pitch_grass.gd").new()
	root.add_child(grass)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(0, 3.8, 36.5)
	camera.look_at(Vector3(0, 1, 18.5), Vector3.UP)
	camera.current = true
	grass._process(0.016)
	assert(grass.patches.size() == 49)
	assert(grass.patterns.size() == 4)
	var mesh_ids := []
	for pattern in grass.patterns:
		assert(pattern.instance_count == grass.CLOSEUP_BLADES_PER_TILE)
		assert(pattern.visible_instance_count == grass.BLADES_PER_TILE)
		mesh_ids.append(pattern.get_instance_id())
	for patch in grass.patches:
		assert(patch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	grass.set_quality("medio")
	for pattern in grass.patterns:
		assert(pattern.visible_instance_count == grass.MEDIUM_BLADES_PER_TILE)
	grass.set_quality("bajo")
	assert(not grass.visible)
	assert(not grass.is_processing())
	grass.set_quality("alto")
	camera.position = Vector3(0,0.65,36.5)
	camera.look_at(Vector3(0,0.65,18.5),Vector3.UP)
	grass._process(0.016)
	assert(grass._closeup_active, "La cámara baja debe mostrar un dosel más denso")
	for pattern in grass.patterns:
		assert(pattern.visible_instance_count == grass.CLOSEUP_BLADES_PER_TILE)
	assert(is_equal_approx(grass.blade_material.get_shader_parameter("focus_radius"),3.0))
	assert(is_equal_approx(grass.blade_material.get_shader_parameter("focus_offset"),0.0))
	for patch in grass.patches:
		if patch.visible:
			assert(Vector2(patch.global_position.x-camera.position.x,patch.global_position.z-camera.position.z).length() < 4.84, "Los parches densos deben quedar cerca de la cámara")
	grass.set_quality("medio")
	grass._process(0.016)
	for pattern in grass.patterns:
		assert(pattern.visible_instance_count == grass.CLOSEUP_BLADES_PER_TILE/2)
	grass.set_quality("alto")
	camera.position = Vector3(0, 4.4, 60.5)
	camera.look_at(Vector3(0, 1.2, 40.5), Vector3.UP)
	grass._process(0.016)
	assert(not grass._closeup_active, "La cámara normal restaura el presupuesto del partido")
	for pattern in grass.patterns:
		assert(pattern.visible_instance_count == grass.BLADES_PER_TILE)
	assert(is_equal_approx(grass.blade_material.get_shader_parameter("focus_offset"),5.0))
	for i in grass.patterns.size():
		assert(grass.patterns[i].get_instance_id() == mesh_ids[i])
	assert(grass._last_cell.y > 18)
	camera.position = Vector3(0, 2.2, -34.5)
	camera.look_at(Vector3(0, 1, -40), Vector3.UP)
	grass._process(0.016)
	assert(grass._last_cell.y < -10)
	assert(grass.patches.size() == 49)
	var triangles_per_crown := 10
	assert(grass.patches.size()*grass.BLADES_PER_TILE*triangles_per_crown <= 735000, "El follaje debe conservar su presupuesto geométrico")
	for pattern in grass.patterns:
		var blade = pattern.mesh
		var arrays = blade.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		assert(vertices.size() == 16, "Tres hojas con extremos cortados comparten vertices indexados")
		assert(arrays[Mesh.ARRAY_INDEX].size() == triangles_per_crown*3)
		assert(normals.size() == vertices.size())
		var clipped_tips: Array[Vector3] = []
		for i in vertices.size():
			var vertex := vertices[i]
			assert(vertex.is_finite() and vertex.y >= 0.0 and vertex.y <= 0.036)
			assert(is_equal_approx(normals[i].length(),1.0))
			assert(normals[i].y > 0.5, "Las hojas dobladas deben tener normales coherentes con el dosel")
			if is_equal_approx(uvs[i].y,1.0):
				clipped_tips.append(vertex)
		assert(clipped_tips.size() == 6)
		for leaf in 3:
			var left := clipped_tips[leaf*2]
			var right := clipped_tips[leaf*2+1]
			assert(left.distance_to(right) > 0.0018, "El corte deja extremos planos, no púas")
			var center := (left+right)*0.5
			assert(Vector2(center.x,center.z).length() > center.y, "Las hojas deben inclinarse sobre el césped")
	root.remove_child(grass)
	grass.free()
	root.remove_child(camera)
	camera.free()
	print("PASS: grass geometry pool, quality density, low visibility, camera mode recycling")
	quit()
