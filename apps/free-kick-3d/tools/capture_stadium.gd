extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() > 0 else "/tmp/free-kick-stadium.png"
	var view := args[1] if args.size() > 1 else "attack"
	var is_menu := view == "menu" or view == "settings"
	var game = load("res://Menu.tscn" if is_menu else "res://Main.tscn").instantiate()
	if not is_menu:
		game.save_path = "/tmp/free-kick-stadium-preview.cfg"
	root.add_child(game)
	if view == "settings":
		game.show_settings()
	elif view == "defense":
		game.start_defense()
	elif view == "low_dive" or view == "high_dive":
		game.start_defense()
		game.keeper_height = -1 if view == "low_dive" else 1
		game.dive_home_keeper(1)
		await create_timer(0.55).timeout
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(output)
	print("Captured %s: %s" % [view, output] if error == OK else "Capture failed: %s" % error)
	quit(0 if error == OK else 1)
