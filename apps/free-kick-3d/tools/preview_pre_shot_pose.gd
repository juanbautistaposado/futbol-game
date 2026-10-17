extends SceneTree
## Show the waiting pose in the real duel, before either actor starts its action.
## Arguments: output.png keeper|striker [side]

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "/tmp/pre-shot-pose.png"
	var keeper_mode := args.size() > 1 and args[1] == "keeper"
	var side_view := args.size() > 2 and args[2] == "side"
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-pre-shot-preview.cfg"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	for child in game.get_children():
		if child is CanvasLayer:
			child.hide()
	game.aim_marker.hide()
	var actor: Node3D = game.away_keeper if keeper_mode else game.kicker
	if keeper_mode:
		actor.reset_pose()
	else:
		actor.reset_pose(game.ball.global_position, -1)
	var player: AnimationPlayer = actor.goalkeeper_animation if keeper_mode else actor.footballer_animation
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.play("keeper_motion/Ready" if keeper_mode else "athlete/Ready", 0.0)
	player.advance(0.0)
	player.seek(0.0, true)
	player.pause()
	var target := actor.global_position + Vector3(0.0, 0.0 if keeper_mode else 1.05, 0.0)
	game.camera.position = target + Vector3(0.65, 0.30, 4.8 if keeper_mode else -4.8)
	if side_view:
		game.camera.position = target + Vector3(4.8, 0.3, 0.8)
	game.camera.fov = 29.0
	game.camera.look_at(target)
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("PRE_SHOT_POSE ", "keeper" if keeper_mode else "striker", " ", output, " ", error)
	quit(0 if error == OK else 1)
