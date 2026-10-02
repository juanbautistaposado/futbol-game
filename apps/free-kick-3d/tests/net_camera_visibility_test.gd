extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-net-camera-test.cfg"
	root.add_child(game)
	var stadium = game.get_node("Stadium")
	var home_net: MeshInstance3D = stadium.net_meshes[1]
	var away_net: MeshInstance3D = stadium.net_meshes[-1]
	assert(home_net.visible and away_net.visible, "Ambas redes deben estar presentes")
	assert(stadium.net_materials[1].get_shader_parameter("opacity") == 1.0, "La red propia debe verse entera al atacar")
	game.start_defense()
	game.defense_countdown = 999.0
	assert(is_equal_approx(stadium.net_materials[1].get_shader_parameter("opacity"), 0.18), "La red propia debe verse tenue durante la atajada")
	assert(stadium.net_materials[-1].get_shader_parameter("opacity") == null or stadium.net_materials[-1].get_shader_parameter("opacity") == 1.0, "La red rival no debe atenuarse")
	game.shot_goal = 1
	game.resolve_shot(true, "¡Gol!")
	assert(stadium.net_materials[1].get_shader_parameter("opacity") == 1.0, "La red debe verse entera al entrar la pelota")
	await create_timer(0.24).timeout
	assert(stadium.net_materials[1].get_shader_parameter("age") > 0.0, "El gol debe ondular la red propia")
	game.start_attack()
	assert(stadium.net_materials[1].get_shader_parameter("opacity") == 1.0, "La cámara de ataque debe restaurar la red")
	print("PASS: red tenue al atajar y visible al convertir gol")
	quit()
