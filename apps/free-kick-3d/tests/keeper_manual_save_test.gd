extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-keeper-manual-test.cfg"
	root.add_child(game)
	game.start_defense()
	game.dive_home_keeper(-1)
	check(game.home_keeper.busy, "Elegir un lado debe iniciar la estirada de inmediato")
	await create_timer(0.55).timeout
	check(absf(game.home_keeper.position.x + 3.10) < 0.15,
		"La estirada debe ir al carril elegido, sin corregirse por la pelota")
	var glove: Vector3 = game.home_keeper.skeleton.global_transform * game.home_keeper.skeleton.get_bone_global_pose(game.home_keeper.left_hand_bone).origin
	game.launch_ball(Vector3(-2.0, 1.45, game.GOAL_Z + 0.3), 1.05, 1)
	game.ball.freeze = true
	game.ball.global_position = glove
	game.previous_ball_position = glove
	game._physics_process(1.0 / 60.0)
	await process_frame
	check(not game.resolved, "Los guantes no deben activar una atajada automática")
	game._on_ball_contact(game.home_keeper)
	await process_frame
	check(game.resolved and game.status_label.text.contains("Atajada"),
		"El contacto con el cuerpo debe seguir resolviendo la atajada")
	print("PASS: estirada manual inmediata y atajada por contacto" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
