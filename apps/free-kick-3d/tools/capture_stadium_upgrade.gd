extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() > 0 else "/tmp/stadium-upgrade.png"
	var view := args[1] if args.size() > 1 else "attack"
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-stadium-upgrade-preview.cfg"
	root.add_child(game)
	if view == "defense":
		game.start_defense()
		game.defense_countdown = 999.0
	elif view != "attack":
		game.aim_marker.hide()
		for child in game.get_children():
			if child is CanvasLayer: child.hide()
		match view:
			"turf_detail":
				game.camera.position = Vector3(0.9, 0.34, -27.0)
				game.camera.fov = 52
				game.camera.look_at(Vector3(0.1, 0.13, -29.0))
			"goal":
				game.camera.position = Vector3(9.5, 3.8, -43.0)
				game.camera.fov = 48
				game.camera.look_at(Vector3(0, 1.5, -53.4))
			"crowd":
				game.camera.position = Vector3(7, 4.1, -55)
				game.camera.fov = 45
				game.camera.look_at(Vector3(0, 6.5, -68))
			"pitch":
				game.camera.position = Vector3(8, 1.2, -27)
				game.camera.fov = 55
				game.camera.look_at(Vector3(0, 0, -37))
			"overview":
				game.camera.position = Vector3(30, 24, 7)
				game.camera.fov = 64
				game.camera.look_at(Vector3(0, 0, -24))
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("STADIUM_UPGRADE_CAPTURE %s %s error=%d" % [view, output, error])
	quit(0 if error == OK else 1)
