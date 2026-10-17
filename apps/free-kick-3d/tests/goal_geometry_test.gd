extends SceneTree

func _initialize() -> void:
	var stadium = load("res://stadium.gd").new()
	for side in [-1,1]:
		stadium.goal(side)
		var net: MeshInstance3D = stadium.net_meshes[side]
		assert(net.mesh.get_surface_count() == 1, "La red debe usar una única superficie")
		assert(RenderingServer.mesh_get_surface(net.mesh.get_rid(),0).primitive == Mesh.PRIMITIVE_TRIANGLES, "La red debe tener volumen real, no líneas GL")
		var arrays: Array = net.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		assert(vertices.size()%3 == 0)
		assert(vertices.size()/3 < 50000, "Mantener el presupuesto geométrico de cada arco")
		assert(normals.size() == vertices.size(), "Los hilos necesitan normales para recibir luz")
		var bounds := net.mesh.get_aabb()
		assert(is_equal_approx(bounds.size.x,8.41))
		assert(is_equal_approx(bounds.size.y,2.91))
		assert(is_equal_approx(bounds.size.z,1.81))
		assert(absf(bounds.get_center().z-side*53.4) < 0.001, "No desplazar el arco respecto de las colisiones")
		for i in vertices.size():
			var vertex := vertices[i]
			assert(vertex.is_finite())
			assert(is_equal_approx(normals[i].length(),1.0))
			# The open mouth must remain empty, including from the keeper camera.
			if absf(absf(vertex.z)-52.5) < 0.012:
				assert(absf(vertex.x) > 4.18 or vertex.y > 2.88, "No tejer una red frente al arquero")
		stadium.set_net_opacity(side,0.18)
		assert(is_equal_approx(stadium.net_materials[side].get_shader_parameter("opacity"),0.18))
		print("PASS: arco %d, %d triángulos, red iluminada y boca abierta" % [side,vertices.size()/3])
	stadium.free()
	quit()
