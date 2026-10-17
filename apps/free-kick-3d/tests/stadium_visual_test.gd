extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stadium = load("res://stadium.gd").new()
	root.add_child(stadium)
	stadium.goal(1)
	var details = stadium.get_node("PitchDetails")
	var poles := 0
	for child in details.get_children():
		assert(not child is CollisionObject3D, "Los detalles nuevos no deben interferir con la pelota")
		if child.name.begins_with("CornerFlagPole") or child.name.begins_with("@MeshInstance3D"):
			if child.mesh is CylinderMesh:
				poles += 1
				assert(is_equal_approx(absf(child.position.x), 34.0))
				assert(is_equal_approx(absf(child.position.z), 52.5))
	assert(poles == 4, "Cuatro banderines fuera del interior de la cancha")
	var crowd = stadium.get_node("StadiumCrowd")
	assert(crowd.spectator_count > 9000, "Mantener tribunas llenas después de optimizar")
	stadium.ripple_net(1, Vector3(0.4, 1.6, 54.3))
	await create_timer(0.15).timeout
	assert(float(crowd.crowd_material.get_shader_parameter("cheer")) > 0.0, "Un gol debe activar el festejo")
	stadium.ripple_net(1, Vector3(-0.4, 1.4, 54.3))
	await create_timer(3.2).timeout
	assert(is_zero_approx(float(crowd.crowd_material.get_shader_parameter("cheer"))), "El festejo debe terminar también tras goles repetidos")
	root.remove_child(stadium)
	stadium.free()
	print("PASS: banderines, decoración sin colisiones, tribuna llena y festejo reiniciable al gol")
	quit()
