extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() > 0 else "/tmp/goalkeeper-v2-in-game.png"
	var show_dive := args.size() > 1 and args[1] == "dive"
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/goalkeeper-v2-preview.cfg"
	root.add_child(game)
	var keeper = game.away_keeper
	var animation: AnimationPlayer = keeper.goalkeeper_animation
	var skeleton: Skeleton3D = keeper.skeleton
	assert(skeleton.get_bone_count() == 18)
	for clip in ["Idle", "Catch", "Celebrate", "SaveLeft", "SaveRight", "SaveLowLeft", "SaveLowRight"]:
		assert(animation.has_animation(clip), "Missing %s" % clip)
	if show_dive:
		keeper.dive(2.4, 1.4)
		for i in range(23):
			await physics_frame
	game.camera.position = Vector3(4.0 if show_dive else 3.2, 2.3, -45.2)
	game.camera.look_at(Vector3(1.0 if show_dive else 0.0, 1.25, -51.8))
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("GOALKEEPER_V2_PREVIEW ", output, " ", error)
	quit(0 if error == OK else 1)
