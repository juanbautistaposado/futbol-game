extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-net-feedback-test.cfg"
	root.add_child(game)
	game.camera.position = Vector3(5,3,-7)
	game.camera.look_at(Vector3(0,1,-53.2))
	game.away_keeper.hide()
	game.shot_goal = -1
	game.ball.position = Vector3(1,1.2,-52.75)
	game.resolve_shot(true,"¡Gol!")
	assert(game.match_audio.result_player.stream == game.match_audio.GOAL_SIGNAL)
	await create_timer(0.24).timeout
	assert(game.get_node("Stadium").net_materials[-1].get_shader_parameter("age") > 0)
	game.start_attack()
	game.ball_in_flight = true
	game.last_flight_velocity = Vector3(0,0,-10)
	game.ball.position = game.away_keeper.position
	assert(game.should_hold_save(10,0.1,0.8))
	assert(not game.should_hold_save(10,0.1,0.2))
	for candidate in range(100):
		seed(candidate)
		if randf() >= 0.45:
			seed(candidate)
			break
	game.show_save(game.away_keeper)
	assert(game.match_audio.result_player.stream == game.match_audio.MISS_SIGNAL)
	assert(game.holding_keeper == game.away_keeper and game.ball.freeze)

	game.start_attack()
	game.ball_in_flight = true
	game.last_flight_velocity = Vector3(0,0,-24)
	game.show_save(game.away_keeper)
	assert(game.holding_keeper == null and not game.ball.freeze and game.ball.linear_velocity.z > 0)
	var start: Vector3 = game.ball.position
	await create_timer(0.35).timeout
	assert(game.ball.position.z > start.z+0.7, "Parried ball must physically travel back into the field")
	assert(game.phase == game.Phase.RESOLVING)
	print("PASS: red animada, pelota agarrada y rebote de atajada")
	quit()
