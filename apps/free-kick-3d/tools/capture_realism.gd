extends SceneTree
## Native evidence in the actual match scene; cameras here do not change gameplay.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var directory := args[0] if args.size() else "/tmp/realism-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	seed(13013)
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/realism-capture-unused.cfg"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.aim_marker.hide()
	for child in game.get_children():
		if child is CanvasLayer: child.hide()
	for view in ["hero", "venue", "ball"]:
		match view:
			"hero":
				game.camera.position = Vector3(-2.8,1.6,game.ball.position.z+5.0)
				game.camera.fov = 46.0
				game.camera.look_at(Vector3(0,1.1,game.ball.position.z-5.0))
			"venue":
				game.camera.position = Vector3(24,5.8,-29)
				game.camera.fov = 66.0
				game.camera.look_at(Vector3(0,9.0,-60))
			"ball":
				game.camera.position = game.ball.position+Vector3(0.65,0.26,1.05)
				game.camera.fov = 40.0
				game.camera.look_at(game.ball.position)
		for frame in range(20): await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(directory.path_join(view+".png")) == OK)
		print("REALISM_CAPTURE ",view)
	quit()
