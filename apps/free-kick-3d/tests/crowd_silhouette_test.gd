extends SceneTree
## Regression: the far crowd must have complete silhouettes in every direction.
func _initialize() -> void:
	var colour := Image.load_from_file(ProjectSettings.globalize_path("res://assets/crowd/striker_impostor_colour.png"))
	var mask := Image.load_from_file(ProjectSettings.globalize_path("res://assets/crowd/striker_impostor_mask.png"))
	assert(colour != null and mask != null)
	assert(colour.get_size() == Vector2i(2048,704) and mask.get_size() == colour.get_size())
	for pose in 2:
		for view in 8:
			var occupied := 0
			var shirt_pixels := 0
			var shorts_pixels := 0
			var skin_pixels := 0
			for y in 352:
				var row_pixels := 0
				for x in 256:
					var pixel := colour.get_pixel(view*256+x,pose*352+y)
					if pixel.a < 0.35: continue
					occupied += 1
					row_pixels += 1
					var cloth := mask.get_pixel(view*256+x,pose*352+y)
					if cloth.r > 0.8: shirt_pixels += 1
					elif cloth.g > 0.1: shorts_pixels += 1
					else: skin_pixels += 1
				# There must be no gap separating the head, body, legs or boots.
				if y >= 45 and y < 330: assert(row_pixels > 0,"Far crowd silhouette cannot break into detached parts")
			assert(occupied > 10000,"Retain the complete body rather than isolated triangles")
			assert(shirt_pixels > 2000 and shorts_pixels > 200 and skin_pixels > 1000)
			# An opaque torso is the most visible regression from the broken mesh.
			for y in range(115,185):
				for x in range(124,132):
					assert(colour.get_pixel(view*256+x,pose*352+y).a > 0.9,"No holes through the spectator's torso")
	for pose_name in ["idle","cheering"]:
		var mesh: ArrayMesh = load("res://assets/crowd/striker_"+pose_name+"_far.res")
		assert(mesh.get_meta("complete_silhouette"))
		assert(mesh.custom_aabb.size.z >= 1.55,"Culling bounds must contain rotated complete bodies")
		var arrays := mesh.surface_get_arrays(0)
		assert(arrays[Mesh.ARRAY_VERTEX].size() == 4 and arrays[Mesh.ARRAY_INDEX].size() == 6)
	print("PASS: 16 complete far-crowd silhouettes, opaque torsos, head-to-boot coverage and separate clothing masks")
	quit()
