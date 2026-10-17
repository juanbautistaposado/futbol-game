extends SceneTree
func _initialize() -> void:
	var stadium = load("res://stadium.gd").new()
	# Keep _ready out of this isolated geometry test.
	var seats: Array[Transform3D] = []
	var colors: Array[Color] = []
	var aisles: Array[Transform3D] = []
	stadium.build_stand(Vector3(41, 0, 0), -PI/2, 110, seats, colors, aisles)
	assert(stadium.get_child_count() <= 9)
	assert(seats.size() > 3900 and aisles.size() >= 168)
	var total_vertices := 0
	for child in stadium.get_children():
		assert(child is MeshInstance3D)
		assert(child.mesh.get_surface_count() == 1)
		assert(child.transform.origin == Vector3(41, 0, 0))
		var arrays: Array = child.mesh.surface_get_arrays(0)
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for normal in normals:
			assert(absf(normal.length()-1.0) < 0.001, "Baked normals must remain normalized")
		total_vertices += arrays[Mesh.ARRAY_VERTEX].size()
	print("PASS Stand: ", stadium.get_child_count(), " material batches, ", total_vertices, " vertices; ", seats.size(), " seats retained, rotated geometry normals valid")
	stadium.free()
	quit()
