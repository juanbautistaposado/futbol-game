extends SceneTree
## Capture the actual gameplay motion, with fixed physics ticks and a fixed camera.
## godot --path apps/free-kick-3d --script res://tools/capture_animation_sequence.gd -- /tmp/strike.png striker

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "/tmp/football-animation.png"
	var mode := args[1] if args.size() > 1 else "striker"
	var side_view := args.has("side")
	var defense_view := args.has("defense")
	var attack_view := args.has("attack")
	var direction := -1.0 if args.has("left") else 1.0
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-animation-preview.cfg"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	if defense_view:
		game.start_defense()
	for child in game.get_children():
		if child is CanvasLayer:
			child.hide()
	game.aim_marker.hide()
	var keeper_mode := mode.begins_with("keeper")
	var caught_save := keeper_mode and mode.contains("hold")
	var home_keeper := keeper_mode and (args.has("home") or defense_view)
	var actor: Node3D = (game.home_keeper if home_keeper else game.away_keeper) if keeper_mode else game.kicker
	var caption_layer := CanvasLayer.new()
	root.add_child(caption_layer)
	var caption := Label.new()
	caption.position = Vector2(28, 24)
	caption.add_theme_font_size_override("font_size", 28)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption_layer.add_child(caption)
	var origin: Vector3 = actor.global_position
	if not defense_view and not attack_view:
		game.camera.position = origin + Vector3(1.1 * direction, 1.5, 5.6 if keeper_mode and not home_keeper else -5.6)
		if side_view:
			game.camera.position = origin + Vector3(5.6, 1.5, 1.0)
		game.camera.fov = 44.0 if keeper_mode else 36.0
		game.camera.look_at(origin + Vector3(direction if keeper_mode else 0.15, 0.65 if keeper_mode else 1.05, 0.0))
		if side_view and keeper_mode:
			# Include the full landing, which drops below the standing framing.
			game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			game.camera.size = 4.5
			game.camera.look_at(origin + Vector3(1.4 * direction, -0.1, 0.0))
	for frame in range(8):
		await process_frame
	if keeper_mode:
		actor.reset_pose()
		actor.dive(0.0 if mode.contains("centre") else direction * 2.8, 0.65 if mode.contains("low") else 1.25 if mode.contains("mid") else 1.55)
	else:
		var ball_start: Vector3 = game.ball.global_position
		actor.kick(func() -> void: game.launch_ball(Vector3(1.5, 1.7, -52.8), 1.22, -1))
		game.ball.global_position = ball_start
	var frames := [0, 6, 15, 24, 29, 41, 54, 78, 99] if keeper_mode else [0, 5, 10, 21, 29, 41, 54, 69, 90]
	if keeper_mode and args.has("landing"):
		frames = [0, 6, 15, 27, 41, 52, 61, 73, 96]
	var sheet := Image.create(1920, 1080, false, Image.FORMAT_RGB8)
	var previous := 0
	var simulation_frame := 0
	for i in range(frames.size()):
		for frame in range(frames[i] - previous):
			await physics_frame
			simulation_frame += 1
			if caught_save and simulation_frame == 27:
				actor.catch_pose(-1)
				game.ball.freeze = true
			if caught_save and simulation_frame >= 27:
				game.ball.global_position = actor.held_ball_position(-1)
		previous = frames[i]
		# physics_frame fires before nodes/tweens advance; capture the completed tick.
		await process_frame
		paused = true
		if caught_save and simulation_frame >= 27:
			game.ball.global_position = actor.held_ball_position(-1)
		caption.text = "%s  ·  %.2f s" % [mode.to_upper(), float(frames[i]) / 60.0]
		var arm_crop := Rect2i()
		if keeper_mode and args.has("hands"):
			arm_crop = _arm_crop(actor, game.camera, Vector2i(root.get_visible_rect().size))
			caption.position = Vector2(arm_crop.position) + Vector2(10, 10)
			caption.add_theme_font_size_override("font_size", 11)
		await RenderingServer.frame_post_draw
		var screenshot := root.get_viewport().get_texture().get_image()
		screenshot.convert(Image.FORMAT_RGB8)
		if keeper_mode and args.has("hands"):
			# Enlarge the arms as rendered by the selected camera; never alter
			# its viewing angle, projection or the character pose for inspection.
			screenshot = screenshot.get_region(arm_crop)
		screenshot.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(screenshot, Rect2i(0, 0, 640, 360), Vector2i((i % 3) * 640, (i / 3) * 360))
		paused = false
	var error := sheet.save_png(output)
	print("ANIMATION_SEQUENCE ", mode, " ", output, " ", error)
	quit(0 if error == OK else 1)

func _arm_crop(actor: Node3D, camera: Camera3D, viewport_size: Vector2i) -> Rect2i:
	actor.skeleton.force_update_all_bone_transforms()
	var bounds := Rect2()
	var first := true
	for bone_name in ["Chest", "Head", "UpperArm.L", "UpperArm.R", "Forearm.L", "Forearm.R", "Hand.L", "Hand.R"]:
		var world: Vector3 = actor.skeleton.global_transform * actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone(bone_name)).origin
		var screen := camera.unproject_position(world)
		bounds = Rect2(screen, Vector2.ZERO) if first else bounds.expand(screen)
		first = false
	var crop_width := minf(viewport_size.x, maxf(240.0, maxf(bounds.size.x + 80.0, (bounds.size.y + 80.0) * 16.0 / 9.0)))
	var crop_size := Vector2(crop_width, minf(viewport_size.y, crop_width * 9.0 / 16.0))
	var crop_origin := bounds.get_center() - crop_size * 0.5
	crop_origin.x = clampf(crop_origin.x, 0.0, viewport_size.x - crop_size.x)
	crop_origin.y = clampf(crop_origin.y, 0.0, viewport_size.y - crop_size.y)
	return Rect2i(crop_origin, crop_size)
