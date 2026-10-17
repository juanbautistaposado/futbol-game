extends SceneTree

const Human = preload("res://footballer_model.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = "/tmp/futbol-meshy-player-test.cfg"
	root.add_child(menu)
	menu.select_striker(Human.MESHY_STRIKER_INDEX)
	menu.save_appearance("name", "PLAYER")
	menu.save_appearance("number", 10)
	var stored := ConfigFile.new()
	assert(stored.load(menu.save_path) == OK)
	assert(stored.get_value("appearance", "striker") == Human.MESHY_STRIKER_INDEX)
	var game = load("res://Main.tscn").instantiate()
	game.save_path = menu.save_path
	root.add_child(game)
	var kicker = game.kicker
	var avatar: Node3D = kicker.footballer_visual
	var body: MeshInstance3D = avatar.get_node("FootballerRig/Skeleton3D/FootballerBody")
	assert(body.mesh.get_surface_count() == 10, "Cabeza anatómica y cavidades separadas del cuerpo y de los ojos")
	assert(body.mesh.surface_get_material(0).resource_name == "MeshyPlayer")
	assert((avatar.get_node("FootballerRig/Skeleton3D") as Skeleton3D).get_bone_count() == 53)
	for clip in ["Idle", "Kick", "Celebrate"]:
		assert(kicker.footballer_animation.has_animation(clip))
	var fabric := body.get_surface_override_material(0) as ShaderMaterial
	assert(fabric.get_shader_parameter("tint") == Color.WHITE)
	assert(fabric.get_shader_parameter("albedo_map") != null)
	assert(fabric.get_shader_parameter("normal_map") != null)
	assert(fabric.get_shader_parameter("lettering_enabled"))
	kicker.apply_identity(Human.MESHY_STRIKER_INDEX, "ÁLEX", 27)
	assert(kicker.footballer_visual == avatar)
	assert(avatar.get_node("JerseyPrint/Name").text == "ÁLEX")
	assert(avatar.get_node("JerseyPrint/Number").text == "27")
	var ball_position: Vector3 = game.ball.global_position
	var contact := {"distance": -1.0}
	kicker.kick(func() -> void:
		var rig: Skeleton3D = avatar.get_node("FootballerRig/Skeleton3D")
		rig.force_update_all_bone_transforms()
		var foot: Vector3 = rig.global_transform * rig.get_bone_global_pose(rig.find_bone("Foot.R")).origin
		contact.distance = foot.distance_to(ball_position)
	)
	await create_timer(0.6).timeout
	assert(contact.distance >= 0 and contact.distance < .42, "El nuevo jugador debe alcanzar la pelota")
	for index in range(5):
		var custom := Human.PROFILES[0].duplicate()
		custom.shirt = "aa2233"
		kicker.apply_identity(index, "PRUEBA", 27, custom)
		assert(kicker.footballer_visual == avatar, "Todas las identidades reutilizan la misma base 3D")
		assert(kicker.visual_model == Human.MESHY_STRIKER_INDEX)
		var expected := Color.WHITE if index == 4 else Color("aa2233") if index == 3 else Color(str(Human.PROFILES[index].shirt))
		for i in range(body.mesh.get_surface_count()):
			if body.mesh.surface_get_material(i).resource_name == "Jersey":
				assert((body.get_surface_override_material(i) as ShaderMaterial).get_shader_parameter("tint") == expected)
	game.start_defense()
	assert(kicker.visual_model == Human.MESHY_STRIKER_INDEX, "El rival también usa la nueva base")
	assert(kicker.footballer_visual == avatar)
	game.start_attack()
	assert(kicker.visual_model == Human.MESHY_STRIKER_INDEX, "El ataque restaura el personaje elegido")
	assert(kicker.avatar_cache.size() == 1, "Todos los turnos reutilizan una sola base")
	assert(kicker.footballer_visual == avatar, "Volver al personaje conserva la instancia y sus materiales")
	assert(kicker.get_children().filter(func(child: Node) -> bool: return child is Node3D and child != kicker.torso and child.visible).size() == 1, "Solo el avatar activo debe ser visible")
	DirAccess.remove_absolute(menu.save_path)
	print("PASS: selección persistente, modelo Meshy completo, dorsal, patada y cambio de turnos")
	quit()
