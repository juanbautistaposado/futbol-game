extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() > 0 else "/tmp/futbol-match.png"
	var defense := args.size() > 1 and args[1] == "defense"
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-match-visual.cfg"
	root.add_child(game)
	if defense: game.start_defense()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("MATCH_VISUAL ", output, " ", error)
	quit(0 if error == OK else 1)
