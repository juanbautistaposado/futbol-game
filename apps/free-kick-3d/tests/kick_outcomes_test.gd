extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func new_game():
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-outcome-test-unused.cfg"
	root.add_child(game)
	return game
func outcome(target: Vector3, keeper: bool, decision_roll := 0.99) -> Array:
	var game = new_game()
	game.difficulty = "dificil"
	game.keeper_rng.seed = 42
	game.shot_power = 0.0
	if not keeper:
		game.away_keeper.position.x = -8
		game.reset_ball(Vector3(0,0.8,-47.5))
	game.launch_ball(target,1.65 if keeper else 0.6,-1)
	if keeper: game.move_keeper_for_attack(target,decision_roll)
	while not game.resolved: await physics_frame
	var result := [game.player_goals,game.hit_woodwork,game.status_label.text]
	game.queue_free()
	await process_frame
	return result
func run() -> void:
	# Accelerate wall-clock time without increasing the simulation step.
	Engine.time_scale = 4
	Engine.physics_ticks_per_second = 240
	var game = new_game()
	var counts: Array[int] = []
	for difficulty in ["facil","medio","dificil"]:
		game.difficulty = difficulty
		var wrong := 0
		for i in range(100):
			if game.keeper_read(Vector3(2,1,-52.8),float(i)/100).x < 0: wrong += 1
		counts.append(wrong)
	check(counts == [60,40,20], "Wrong-way probability must be 60/40/20 percent by difficulty")
	game.aim_x = 2
	game.aim_y = 3
	var wide: Vector3 = game.player_shot_target(1.0)
	check(wide.x > game.GOAL_WIDTH/2 and wide.y > game.GOAL_HEIGHT,"Perfect timing must still allow aiming outside")
	game.queue_free()
	await process_frame
	var slow := await outcome(Vector3(0,1.35,-52.8),true)
	check(slow[0] == 0 and str(slow[2]).begins_with("¡Atajada"), "Keeper must save a reachable zero-power shot: " + str(slow))
	var wrong_center := await outcome(Vector3(0,1.35,-52.8),true,0.0)
	check(wrong_center[0] == 1, "A wrong-way dive must concede a centered on-target shot: " + str(wrong_center))
	var wrong_side := await outcome(Vector3(2.0,1.35,-52.8),true,0.0)
	check(wrong_side[0] == 1, "A wrong-way dive must concede an on-target side shot: " + str(wrong_side))
	var post_in := await outcome(Vector3(4.2,0.8,-52.8),false)
	check(post_in[0] == 1 and post_in[1], "Inside post must physically rebound into goal: " + str(post_in))
	var post_out := await outcome(Vector3(4.5,0.8,-52.8),false)
	check(post_out[0] == 0 and post_out[1], "Outside post must rebound away: " + str(post_out))
	var outside := await outcome(Vector3(6,1,-52.8),false)
	check(outside[0] == 0 and not outside[1], "Wide shot must miss without touching the post")
	var over := await outcome(Vector3(0,4,-52.8),false)
	check(over[0] == 0 and not over[1], "Shot over the bar must miss")
	print("PASS: dificultad, tiro débil atajado, palo y gol, palo afuera y tiros desviados" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures else 0)
