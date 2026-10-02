extends SceneTree

const SHOTS_PER_DIFFICULTY := 100

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Engine.time_scale = 6.0
	Engine.physics_ticks_per_second = 240
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-ai-balance-test.cfg"
	root.add_child(game)
	var shot_rng := RandomNumberGenerator.new()
	shot_rng.seed = 27591
	var failures := 0
	var expected_goals := {"facil": 60, "medio": 40, "dificil": 20}
	for level in ["facil", "medio", "dificil"]:
		game.difficulty = level
		game.player_goals = 0
		game.keeper_rng.seed = 74621
		var goals := 0
		var saves := 0
		var other := 0
		for i in range(SHOTS_PER_DIFFICULTY):
			game.away_keeper.reset_pose()
			game.reset_ball(Vector3(0.0, game.BALL_RADIUS + 0.02, -game.GOAL_Z + game.shooting_distance()))
			game.phase = game.Phase.ATTACK
			game.shot_power = shot_rng.randf_range(0.35, 0.85)
			var target := Vector3(shot_rng.randf_range(-3.25, 3.25), shot_rng.randf_range(0.65, 2.25), -game.GOAL_Z - 0.3)
			game.launch_ball(target, lerpf(1.65, 0.75, game.shot_power), -1)
			game.move_keeper_for_attack(target, float(i) / SHOTS_PER_DIFFICULTY)
			while not game.resolved:
				await physics_frame
			if game.player_goals > goals:
				goals += 1
			elif game.status_label.text.begins_with("¡Atajada"):
				saves += 1
			else:
				other += 1
			for child in game.get_children():
				if child is Timer:
					child.stop()
					child.queue_free()
			await physics_frame
		print("%s: %d goles, %d atajadas, %d otros en %d tiros válidos" % [level, goals, saves, other, SHOTS_PER_DIFFICULTY])
		if abs(goals - int(expected_goals[level])) > 3 or other > 0:
			failures += 1
			push_error("Balance de %s fuera de objetivo: %d goles" % [level, goals])
	game.queue_free()
	quit(1 if failures else 0)
