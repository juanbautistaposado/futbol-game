extends SceneTree

const SAVE := "/tmp/futbol-play-modes-integration.cfg"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var legacy := ConfigFile.new()
	legacy.set_value("settings", "shots", 15)
	legacy.set_value("settings", "players", 4)
	legacy.save(SAVE)
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = SAVE
	root.add_child(menu)
	current_scene = menu
	assert(menu.player_count == 1 and menu.shot_count == 5)
	menu.play_button.pressed.emit()
	await process_frame
	assert(menu.page.has_meta("play_menu"))
	assert(menu.mode_cards.size() == 1)
	assert(menu.mode_cards[0].name == "ModeBot" and menu.mode_cards[0].selected)
	assert(not menu.background.player.visible)
	assert(menu.start_button.has_focus())
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	menu._unhandled_input(escape)
	await process_frame
	assert(menu.play_button.has_focus() and menu.background.player.visible)
	menu.play_button.pressed.emit()
	await process_frame
	root.child_entered_tree.connect(func(scene: Node) -> void:
		if scene.has_method("load_best_score"): scene.save_path = SAVE
	)
	menu.start_button.pressed.emit()
	await scene_changed
	assert(current_scene.name == "FreeKickGame")
	assert(current_scene.player_count == 1 and current_scene.shot_limit == 5)
	assert(current_scene.local_scores.size() == 1)
	var stored := ConfigFile.new()
	assert(stored.load(SAVE) == OK)
	assert(stored.get_value("settings", "players") == 1)
	assert(stored.get_value("settings", "shots") == 5)
	assert(stored.get_value("settings", "shot_mode") == "tiro_libre")
	DirAccess.remove_absolute(SAVE)
	print("PASS: JUGAR only offers bot duel, fixed 5 shots, legacy settings normalized, Esc, focus, game start and persistence")
	quit()
