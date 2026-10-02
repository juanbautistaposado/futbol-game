extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var samples := [
		{"name": "centro medio", "x": 0.0, "y": 1.35, "lane": 0, "height": 0, "save": true},
		{"name": "izquierda baja", "x": -2.65, "y": 0.65, "lane": -1, "height": -1, "save": true},
		{"name": "derecha baja", "x": 2.65, "y": 0.65, "lane": 1, "height": -1, "save": true},
		{"name": "izquierda alta", "x": -2.65, "y": 2.20, "lane": -1, "height": 1, "save": true},
		{"name": "derecha alta", "x": 2.65, "y": 2.20, "lane": 1, "height": 1, "save": true},
		{"name": "ángulo superior izquierdo", "x": -3.75, "y": 2.52, "lane": -1, "height": 1, "save": true},
		{"name": "ángulo superior derecho", "x": 3.75, "y": 2.52, "lane": 1, "height": 1, "save": true},
		{"name": "ángulo inferior izquierdo", "x": -3.75, "y": 0.38, "lane": -1, "height": -1, "save": true},
		{"name": "ángulo inferior derecho", "x": 3.75, "y": 0.38, "lane": 1, "height": -1, "save": true},
		{"name": "lado equivocado", "x": -2.65, "y": 1.35, "lane": 1, "height": 0, "save": false},
		{"name": "altura equivocada", "x": 2.65, "y": 2.20, "lane": 1, "height": -1, "save": false},
		{"name": "ángulo con lado equivocado", "x": -3.75, "y": 2.52, "lane": 1, "height": 1, "save": false},
		{"name": "ángulo con altura equivocada", "x": 3.75, "y": 2.52, "lane": 1, "height": -1, "save": false},
	]
	for sample in samples:
		var game = load("res://Main.tscn").instantiate()
		game.save_path = "/tmp/futbol-keeper-save-balance.cfg"
		root.add_child(game)
		game.start_defense()
		game.defense_countdown = 999.0
		game.launch_ball(Vector3(sample.x, sample.y, game.GOAL_Z + 0.3), game.AI_SHOT_FLIGHT_TIME, 1)
		await create_timer(0.35).timeout
		var aim_x: float = sample.x if sample.save else float(sample.lane) * 3.75
		var aim_y: float = sample.y if sample.save else 2.52 if sample.height > 0 else 0.38 if sample.height < 0 else 1.35
		var screen_position: Vector2 = game.defense_screen_from_target(Vector2(aim_x, aim_y))
		game.dive_home_keeper_from_screen(screen_position)
		check(game.keeper_lane == sample.lane and game.keeper_height == sample.height,
			"%s: el toque debe elegir el sector y la altura" % sample.name)
		for i in range(150):
			if game.resolved:
				break
			await create_timer(0.01).timeout
		var saved: bool = game.status_label.text.contains("Atajada")
		check(game.resolved, "%s: el tiro debe tener resultado" % sample.name)
		check(saved == sample.save, "%s: resultado esperado atajada=%s, obtenido=%s" % [sample.name, sample.save, saved])
		print("%s: %s" % [sample.name, game.status_label.text])
		game.queue_free()
		await process_frame
	print("PASS: atajadas por sector y altura" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
