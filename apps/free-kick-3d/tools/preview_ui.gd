extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var screens := (args[0] if args.size() > 0 else "home").split(",")
	var output := args[1] if args.size() > 1 else "/tmp/futbol-ui.png"
	if args.size() > 3:
		root.size = Vector2i(int(args[2]), int(args[3]))
	if screens.size() > 1:
		DirAccess.make_dir_recursive_absolute(output)
	for screen in screens:
		var scene: Node
		if screen in ["match", "pause", "long", "result", "winner", "multi", "charge", "locked"]:
			var game = load("res://Main.tscn").instantiate()
			game.save_path = "/tmp/futbol-ui-preview.cfg"
			root.add_child(game)
			game.set_process(false)
			game.update_aim_label()
			if screen == "long":
				game.player_name = "JugadorDieciseis"
				game.sudden_death = true
				game.turn = game.shot_limit + 1
				game.update_score()
				game.start_defense()
				game.update_aim_label()
			if screen == "multi":
				game.player_count = 4
				game.local_scores.assign([1, 2, 0, 3])
				game.update_score()
			if screen in ["charge", "locked"]:
				game.shot_meter.begin()
				game.shot_meter.advance(0.55)
				if screen == "locked": game.shot_meter.lock_shot()
			if screen == "result": game.match_overlay.show_result("¡GOL!", preload("res://ui/visual_theme.gd").SUCCESS)
			if screen == "winner": game.match_overlay.show_result("JugadorDieciseis gana 7 — 5", preload("res://ui/visual_theme.gd").ENERGY, true)
			if screen == "pause": game.match_overlay.set_paused(true)
			scene = game
		else:
			var menu = load("res://Menu.tscn").instantiate()
			menu.save_path = "/tmp/futbol-ui-preview.cfg"
			root.add_child(menu)
			match screen:
				"settings": menu.show_settings()
				"characters": menu.show_characters()
				"setup": menu.show_setup()
				"play-bot", "play-individual":
					menu.show_setup()
				"keeper": menu.show_keepers()
				"striker": menu.show_strikers()
				"custom": menu.show_custom_keeper()
				"custom-striker": menu.show_custom_striker()
				"editor-face", "editor-facial-hair", "editor-kit", "editor-back":
					menu.show_custom_striker()
					var editor: Control = menu.page.get_node("CharacterEditor")
					if screen in ["editor-face", "editor-facial-hair"]: editor.get_node("CategoryAppearance").pressed.emit()
					else: editor.get_node("CategoryKit").pressed.emit()
					if screen == "editor-facial-hair":
						editor.find_child("FieldBeard", true, false).pressed.emit()
						editor.find_child("BeardOff", true, false).pressed.emit()
					if screen == "editor-back": menu.background.rotate_editor(PI)
				"home-hover", "home-pressed":
					var motion := InputEventMouseMotion.new()
					motion.position = menu.play_button.get_global_rect().get_center()
					motion.global_position = motion.position
					Input.parse_input_event(motion)
					await process_frame
					if screen == "home-pressed":
						var click := InputEventMouseButton.new()
						click.button_index = MOUSE_BUTTON_LEFT
						click.pressed = true
						click.position = motion.position
						click.global_position = motion.position
						Input.parse_input_event(click)
			scene = menu
		for i in range(12): await process_frame
		if screen.begins_with("editor-"):
			await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var path := output.path_join(screen + ".png") if screens.size() > 1 else output
		var error := root.get_viewport().get_texture().get_image().save_png(path)
		print("UI_PREVIEW ", path, " ", error)
		if error != OK:
			quit(1)
			return
		paused = false
		scene.queue_free()
		await process_frame
	quit(0)
