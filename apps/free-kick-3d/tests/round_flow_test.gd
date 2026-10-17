extends SceneTree

const TEST_SAVE := "/tmp/futbol-round-flow-test.cfg"

func _initialize() -> void:
	call_deferred("run")

func make_game() -> Node:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = TEST_SAVE
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	return game

func complete_regular_pairs(game: Node) -> void:
	for shot in range(1, 5):
		assert(game.turn == shot and game.phase == game.Phase.ATTACK)
		game.shot_goal = -1
		game.advance_after_shot()
		assert(game.phase == game.Phase.DEFEND and game.turn == shot)
		game.shot_goal = 1
		game.advance_after_shot()
		assert(not game.sudden_death)
	assert(game.turn == 5 and game.phase == game.Phase.ATTACK)

func run() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "shots", 15)
	config.set_value("settings", "players", 4)
	config.set_value("settings", "difficulty", "dificil")
	config.save(TEST_SAVE)
	var game = make_game()
	assert(game.shot_limit == 5 and game.player_count == 1)
	complete_regular_pairs(game)
	game.player_goals = 3
	game.rival_goals = 2
	game.shot_goal = -1
	game.advance_after_shot()
	assert(game.phase == game.Phase.DEFEND and game.turn == 5)
	game.shot_goal = 1
	game.advance_after_shot()
	assert(game.phase == game.Phase.FINISHED and not game.sudden_death)
	assert(game.turn == 5)
	await scene_changed
	assert(current_scene.name == "MainMenu")
	config.load(TEST_SAVE)
	assert(config.get_value("scores", "shots_5") == 3)
	assert(config.get_value("settings", "difficulty") == "dificil")
	current_scene.queue_free()
	await process_frame
	game = make_game()
	complete_regular_pairs(game)
	game.player_goals = 2
	game.rival_goals = 2
	game.shot_goal = -1
	game.advance_after_shot()
	assert(game.phase == game.Phase.DEFEND and not game.sudden_death)
	game.shot_goal = 1
	game.advance_after_shot()
	assert(game.sudden_death and game.turn == 6 and game.phase == game.Phase.ATTACK)
	# An extra tied pair continues; neither side gets an unpaired extra shot.
	game.player_goals = 3
	game.shot_goal = -1
	game.advance_after_shot()
	assert(game.phase == game.Phase.DEFEND and game.turn == 6)
	game.rival_goals = 3
	game.shot_goal = 1
	game.advance_after_shot()
	assert(game.turn == 7 and game.phase == game.Phase.ATTACK)
	game.player_goals = 4
	game.shot_goal = -1
	game.advance_after_shot()
	assert(game.phase == game.Phase.DEFEND and game.turn == 7)
	game.shot_goal = 1
	game.advance_after_shot()
	assert(game.phase == game.Phase.FINISHED and game.turn == 7)
	await scene_changed
	assert(current_scene.name == "MainMenu")
	DirAccess.remove_absolute(TEST_SAVE)
	print("PASS: fixed bot duel despite legacy save, 5 paired rounds, no extra shots without tie, paired sudden death until winner, score and return")
	quit()
