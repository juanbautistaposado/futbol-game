extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Preserve the gameplay physics step while accelerating wall-clock time.
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = 240
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-keeper-rival-ground.cfg"
	root.add_child(game)
	game.difficulty = "medio"
	for side in [-1.0, 1.0]:
		for y in [0.235, 0.24, 0.3]:
			game.start_attack()
			game.keeper_rng.seed = 2
			game.aim_x = side * 3.85 / 3.7
			game.aim_y = (y - 1.5) / 1.1
			game.shot_power = 1.0
			game.shot_meter.indicator = 0.5
			game.fire_player_shot()
			var tilted_reach := false
			while not game.resolved:
				await physics_frame
				var reach: CollisionShape3D = game.away_keeper.dive_reach_collision
				if not reach.disabled and reach.global_basis.y.normalized().dot(Vector3.UP) < 0.999:
					tilted_reach = true
			if tilted_reach:
				failures += 1
				push_error("El alcance debe permanecer horizontal durante la estirada")
			var saved: bool = game.status_label.text.contains("Atajada")
			print("RIVAL_GROUND x=%.2f y=%.2f: %s" % [side * 3.85, y, game.status_label.text])
			if not saved:
				failures += 1
			for child in game.get_children():
				if child is Timer:
					child.stop()
					child.queue_free()
			await process_frame
	game.queue_free()
	await process_frame
	print("PASS: pateo completo al ras del suelo atajable en ambos lados" if failures == 0 else "FAIL: %d tiros rasos atraviesan el alcance del rival" % failures)
	quit(1 if failures else 0)
