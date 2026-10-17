extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var corners := [
		{"name": "arriba izquierda", "x": -3.75, "y": 2.52, "dive_y": 1.6},
		{"name": "arriba derecha", "x": 3.75, "y": 2.52, "dive_y": 1.6},
		{"name": "abajo izquierda", "x": -3.75, "y": 0.38, "dive_y": 0.65},
		{"name": "abajo derecha", "x": 3.75, "y": 0.38, "dive_y": 0.65},
	]
	for corner in corners:
		var game = load("res://Main.tscn").instantiate()
		game.save_path = "/tmp/futbol-keeper-corner-ai.cfg"
		root.add_child(game)
		game.start_attack()
		check(game.away_keeper.position.is_equal_approx(game.away_keeper.rest_position), "El bot debe empezar cada estirada desde el centro")
		game.difficulty = "medio"
		game.shot_power = 1.0
		game.launch_ball(Vector3(corner.x, corner.y, -game.GOAL_Z - 0.3), lerpf(1.65, 0.75, game.shot_power), -1)
		game.keeper_rng.seed = 7192
		game.move_keeper_for_attack(1.0)
		for i in range(150):
			if game.resolved:
				break
			await create_timer(0.01).timeout
		check(game.resolved and game.status_label.text.contains("Atajada"),
			"El bot debe interceptar el tiro fuerte al ángulo %s cuando elige el lado correcto" % corner.name)
		print("%s: %s" % [corner.name, game.status_label.text])
		game.queue_free()
		await process_frame
	print("PASS: el bot llega desde el centro a los cuatro ángulos con potencia máxima" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
