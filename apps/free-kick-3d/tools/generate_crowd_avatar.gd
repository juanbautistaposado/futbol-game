extends SceneTree
## Bake the striker's own geometry and UVs once, rather than run thousands of skeletons.
const SOURCE = preload("res://assets/footballer/meshy_striker.glb")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/crowd")
	var avatar = SOURCE.instantiate()
	root.add_child(avatar)
	var body: MeshInstance3D = avatar.get_node("FootballerRig/Skeleton3D/FootballerBody")
	var skeleton: Skeleton3D = body.get_parent()
	var animation: AnimationPlayer = avatar.get_node("AnimationPlayer")
	for variant in ["idle", "cheering"]:
		animation.play("Celebrate" if variant == "cheering" else "Idle")
		animation.seek(0.35 if variant == "cheering" else 0.0,true)
		skeleton.force_update_all_bone_transforms()
		var transforms: Array[Transform3D] = []
		for bind in body.skin.get_bind_count():
			var bone := body.skin.get_bind_bone(bind)
			if bone < 0: bone = skeleton.find_bone(body.skin.get_bind_name(bind))
			transforms.append(skeleton.get_bone_global_pose(bone)*body.skin.get_bind_pose(bind))
		var merged_vertices := PackedVector3Array()
		var merged_normals := PackedVector3Array()
		var merged_uvs := PackedVector2Array()
		var merged_masks := PackedVector2Array()
		var merged_indices := PackedInt32Array()
		for surface in body.mesh.get_surface_count():
			var source: Array = body.mesh.surface_get_arrays(surface)
			var points: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
			var bones: PackedInt32Array = source[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = source[Mesh.ARRAY_WEIGHTS]
			var influence_count := bones.size()/points.size()
			var posed_points := PackedVector3Array()
			var posed_normals := PackedVector3Array()
			var masks := PackedVector2Array()
			for vertex in points.size():
				var point := Vector3.ZERO
				var normal := Vector3.ZERO
				for influence in influence_count:
					var offset := vertex*influence_count+influence
					var weight := weights[offset]
					if weight <= 0.0: continue
					var transform := transforms[bones[offset]]
					point += (transform*points[vertex])*weight
					normal += (transform.basis*normals[vertex])*weight
				posed_points.append(point)
				posed_normals.append(normal.normalized())
				# Surface 1 is the striker's jersey; the shorts keep their own tint.
				var shorts := 1.0 if surface == 0 and points[vertex].y > 0.69 and points[vertex].y < 1.09 and absf(points[vertex].x) < 0.30 else 0.0
				masks.append(Vector2(1.0 if surface == 1 else 0.0,shorts))
			# Simplify anatomical regions independently: global decimation can
			# erase disconnected heads and hands before reducing the large jersey.
			var regions := {}
			var original_indices: PackedInt32Array = source[Mesh.ARRAY_INDEX]
			for triangle in range(0,original_indices.size(),3):
				var center := (points[original_indices[triangle]]+points[original_indices[triangle+1]]+points[original_indices[triangle+2]])/3.0
				var region := "shirt"
				if surface == 0:
					if center.y > 1.59: region = "head"
					elif absf(center.x) > 0.24 and center.y > 0.94: region = "arm_left" if center.x < 0 else "arm_right"
					elif center.y < 0.18: region = "boot_left" if center.x < 0 else "boot_right"
					elif center.y < 0.71: region = "leg_left" if center.x < 0 else "leg_right"
					else: region = "shorts"
				if not regions.has(region): regions[region] = PackedInt32Array()
				for corner in 3: regions[region].append(original_indices[triangle+corner])
			for region in regions:
				var arrays: Array = []
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX] = posed_points
				arrays[Mesh.ARRAY_NORMAL] = posed_normals
				arrays[Mesh.ARRAY_TEX_UV] = source[Mesh.ARRAY_TEX_UV]
				arrays[Mesh.ARRAY_TEX_UV2] = masks
				arrays[Mesh.ARRAY_INDEX] = regions[region]
				var importer := ImporterMesh.new()
				importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays)
				importer.generate_lods(60.0,60.0,[])
				var selected: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var target := 400 if region == "head" else 700 if region == "shirt" else 200 if region.begins_with("arm") else 150
				for lod in importer.get_surface_lod_count(0):
					selected = importer.get_surface_lod_indices(0,lod)
					if selected.size()/3 < target: break
				print("REGION ",variant," ",region," tris ",selected.size()/3)
				var remap := {}
				for original in selected:
					if not remap.has(original):
						remap[original] = merged_vertices.size()
						merged_vertices.append(posed_points[original])
						merged_normals.append(posed_normals[original])
						merged_uvs.append(source[Mesh.ARRAY_TEX_UV][original])
						merged_masks.append(masks[original])
					merged_indices.append(remap[original])
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = merged_vertices
		arrays[Mesh.ARRAY_NORMAL] = merged_normals
		arrays[Mesh.ARRAY_TEX_UV] = merged_uvs
		arrays[Mesh.ARRAY_TEX_UV2] = merged_masks
		arrays[Mesh.ARRAY_INDEX] = merged_indices
		var result := ArrayMesh.new()
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.set_meta("source_avatar","res://assets/footballer/meshy_striker.glb")
		result.set_meta("pose",variant)
		var error := ResourceSaver.save(result,"res://assets/crowd/striker_"+variant+".res")
		print("CROWD_AVATAR ",variant," triangles ",merged_indices.size()/3," bounds ",result.get_aabb()," save ",error)

	avatar.free()
	quit()

# Next run tools/bake_crowd_impostors.gd with the native renderer to regenerate far views.
