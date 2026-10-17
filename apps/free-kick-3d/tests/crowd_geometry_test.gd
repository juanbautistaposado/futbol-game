extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var crowd = load("res://stadium_crowd.gd").new()
	root.add_child(crowd)
	var seats: Array[Transform3D] = []
	var origins := [Vector3(0,0,-60),Vector3(0,0,60),Vector3(-41,0,0),Vector3(41,0,0)]
	var angles := [0.0,PI,PI/2,-PI/2]
	for stand in 4:
		var facing := Basis(Vector3.UP,angles[stand])
		for x in [-42.0,-14.0,14.0,42.0]:
			for row in 18: seats.append(Transform3D(facing,origins[stand]+facing*Vector3(x,row*0.49+1.0,-row*0.82)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7402
	crowd.build(seats,rng)
	await process_frame
	assert(crowd.spectator_count > 200 and crowd.spectator_count < seats.size())
	assert(crowd.get_child_count() == 32,"16 spatial blocks with two shared striker poses")
	var total := 0
	var colours := {}
	var poses := {}
	for node in crowd.get_children():
		var multi: MultiMesh = node.multimesh
		total += multi.instance_count
		assert(multi.use_colors and multi.use_custom_data)
		assert(node.material_override == crowd.crowd_material)
		assert(node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		assert(node.extra_cull_margin >= 0.2)
		var bounds := multi.get_aabb()
		assert(maxf(bounds.size.x,bounds.size.z) < 30.0)
		assert(multi.mesh.get_meta("source_avatar") == "res://assets/footballer/meshy_striker.glb")
		poses[multi.mesh.get_meta("pose")] = true
		var arrays := multi.mesh.surface_get_arrays(0)
		assert(arrays[Mesh.ARRAY_INDEX].size()/3 < 5000)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var head_vertices := 0
		var hand_vertices := 0
		for point in points:
			if point.y > 1.70: head_vertices += 1
			if absf(point.x) > 0.28 and point.y > 0.8: hand_vertices += 1
		assert(head_vertices > 20 and hand_vertices > 20,"Simplification must retain heads and hands")
		var masks: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		assert(masks.size() == points.size())
		assert(Vector2.ZERO in masks and Vector2(1,0) in masks,"Skin keeps the original atlas; only clothing receives colours")
		for i in multi.instance_count:
			var transform := multi.get_instance_transform(i)
			assert(transform.origin.is_finite() and transform.basis.determinant() > 0)
			var scale := transform.basis.get_scale().x
			assert(scale >= crowd.SPECTATOR_SCALE_MIN-0.001 and scale <= crowd.SPECTATOR_SCALE_MAX+0.001)
			colours[multi.get_instance_color(i).to_html()] = true
	assert(total == crowd.spectator_count,"One complete striker model per supporter")
	assert(colours.size() > total*0.95,"Every spectator receives an independently varied clothing colour")
	assert(poses.size() == 2)
	assert(crowd.crowd_material.get_shader_parameter("albedo_map").resource_path == "res://assets/footballer/meshy_striker_Image_0.jpg")
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	var ids := []
	for chunk in crowd.lod_chunks:
		ids.append(chunk.node.multimesh.get_instance_id())
		assert(chunk.far.get_meta("source_avatar") == "res://assets/footballer/meshy_striker.glb")
		assert(chunk.far.get_meta("complete_silhouette"))
		assert(chunk.far.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() == 6)
	camera.position = Vector3(0,150,0)
	crowd._update_lod()
	for chunk in crowd.lod_chunks:
		assert(chunk.node.multimesh.mesh == chunk.far)
		assert(chunk.node.material_override == crowd.distant_material)
	camera.position = crowd.lod_chunks[0].center+Vector3(0,1,3)
	crowd._update_lod()
	assert(crowd.lod_chunks[0].node.multimesh.mesh == crowd.lod_chunks[0].near)
	assert(crowd.lod_chunks[0].node.material_override == crowd.crowd_material)
	for i in crowd.lod_chunks.size(): assert(crowd.lod_chunks[i].node.multimesh.get_instance_id() == ids[i])
	root.remove_child(camera)
	camera.free()
	crowd.celebrate()
	root.remove_child(crowd)
	crowd.free()
	print("PASS Crowd: shared striker geometry and atlas, heads/hands preserved, smaller scale, varied clothing, spatial batches and celebration")
	quit()
