extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() else "/tmp/athlete-v3.png"
	var view := args[1] if args.size() > 1 else "front"
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/athlete-v3-preview.cfg"
	root.add_child(game)
	for child in game.get_children():
		if child is CanvasLayer: child.hide()
	if view == "dive":
		game.away_keeper.dive(2.4, 1.4)
		for i in range(23): await physics_frame
	var behind := view == "back"
	game.aim_marker.hide()
	game.aim_marker.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.position = Vector3(1.1, 2.0, -55.8 if behind else -47.2)
	game.camera.fov = 32.0
	game.camera.look_at(Vector3(1.0 if view == "dive" else 0.0, 1.2, -51.8))
	if view == "dive":
		game.camera.fov = 44.0
	if view in ["player_front", "player_back"]:
		var player_position: Vector3 = game.kicker.global_position
		game.camera.position = player_position + Vector3(0.5, 1.4, -4.8 if view == "player_front" else 4.8)
		game.camera.fov = 32.0
		game.camera.look_at(player_position + Vector3(0, 1.13, 0))
	if view == "gameplay":
		game.camera.fov = 55.0
		game.look_from_kicker()
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	game.set_process(false)
	game.set_physics_process(false)
	game.aim_marker.hide()
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("ATHLETE_V3_PREVIEW ", view, " ", output, " ", error)
	quit(0 if error == OK else 1)
