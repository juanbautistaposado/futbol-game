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
		game.launch_ball(Vector3(corner.x, corner.y, -game.GOAL_Z - 0.3), 1.22, -1)
		game.away_keeper.dive(signf(corner.x) * 3.10, corner.dive_y, 0.45)
		for i in range(150):
			if game.resolved:
				break
			await create_timer(0.01).timeout
		check(game.resolved and game.status_label.text.contains("Atajada"),
			"El arquero rival debe poder llegar al ángulo %s si lee bien el tiro" % corner.name)
		print("%s: %s" % [corner.name, game.status_label.text])
		game.queue_free()
		await process_frame
	print("PASS: el arquero rival puede cubrir los cuatro ángulos" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
