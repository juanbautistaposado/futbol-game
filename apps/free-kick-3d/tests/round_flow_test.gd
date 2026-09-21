extends SceneTree

const TEST_SAVE := "/tmp/futbol-round-flow-test.cfg"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "shots", 5)
	config.set_value("settings", "players", 4)
	config.set_value("settings", "difficulty", "dificil")
	config.save(TEST_SAVE)
	var game = load("res://Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	assert(game.shot_limit == 5 and game.player_count == 4)
	Engine.time_scale = 15.0
	for shot in range(20):
		assert(game.active_player == shot % 4)
		assert(game.turn == shot / 4 + 1)
		assert(game.phase == game.Phase.ATTACK)
		game.shot_goal = -1
		game.resolved = false
		game.resolve_shot(shot % 4 == 0, "Prueba")
		await create_timer(1.35).timeout
	assert(game.phase == game.Phase.FINISHED)
	assert(game.local_scores == [5, 0, 0, 0])
	assert(game.status_label.text == "Gana J1")
	await scene_changed
	Engine.time_scale = 1.0
	assert(current_scene.name == "MainMenu")
	config.load(TEST_SAVE)
	assert(config.get_value("scores", "shots_5") == 5)
	assert(config.get_value("settings", "difficulty") == "dificil")
	# Single player still alternates attack/defense and uses the chosen limit.
	current_scene.queue_free()
	await process_frame
	config.set_value("settings", "players", 1)
	config.set_value("settings", "shots", 15)
	config.save(TEST_SAVE)
	game = load("res://Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game.shot_goal = -1
	game.advance_after_shot()
	assert(game.phase == game.Phase.DEFEND)
	game.turn = 15
	game.shot_goal = 1
	game.player_goals = 1
	game.rival_goals = 1
	game.advance_after_shot()
	assert(game.sudden_death and game.turn == 16)
	game.player_goals = 2
	game.shot_goal = 1
	game.advance_after_shot()
	assert(game.phase == game.Phase.FINISHED)
	await scene_changed
	assert(current_scene.name == "MainMenu")
	DirAccess.remove_absolute(TEST_SAVE)
	print("PASS: 4 jugadores × 5 tiros, puntajes, récord, duelo de 15, desempate y regreso automático")
	quit()
