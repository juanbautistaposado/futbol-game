extends SceneTree
## Inspect the full selectable character, including its runtime materials.
const Player = preload("res://kicker.gd")
const Human = preload("res://footballer_model.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() else "/tmp/meshy-player.png"
	var view := args[1] if args.size() > 1 else "front"
	if view in ["striker", "gameplay", "stadium"]:
		await capture_in_game(output, view, args[2] if args.size() > 2 else "Idle", float(args[3]) if args.size() > 3 else 0.0)
		return
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("454950")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	scene.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-28, -30, 0)
	light.light_energy = 0.8
	scene.add_child(light)
	var player := Player.new()
	scene.add_child(player)
	player.apply_identity(int(args[4]) if args.size() > 4 else Human.MESHY_STRIKER_INDEX, "PLAYER", 10)
	player.rotation.y = PI
	player.footballer_animation.play(args[2] if args.size() > 2 else "Idle")
	player.footballer_animation.advance(float(args[3]) if args.size() > 3 else 0.0)
	player.footballer_animation.pause()
	if view == "pose_a":
		player.footballer_animation.stop()
		var rig := player.footballer_visual.get_node("FootballerRig/Skeleton3D") as Skeleton3D
		rig.reset_bone_poses()
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(4.5, 1.1, 0) if view == "profile" else Vector3(0, 1.1, -4.5 if view == "back" else 4.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.5
	camera.look_at(Vector3(0, 1.05, 0))
	for frame in range(10): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("MESHY_PLAYER_CAPTURE ", view, " ", error)
	quit(0 if error == OK else 1)

func capture_in_game(output: String, view: String, clip: String, time: float) -> void:
	var save_path := "/tmp/futbol-meshy-player-preview.cfg"
	var settings := ConfigFile.new()
	var args := OS.get_cmdline_user_args()
	settings.set_value("appearance", "striker", int(args[4]) if args.size() > 4 else Human.MESHY_STRIKER_INDEX)
	settings.set_value("appearance", "name", "PLAYER")
	settings.set_value("appearance", "number", 10)
	settings.save(save_path)
	if view == "striker":
		var menu = load("res://Menu.tscn").instantiate()
		menu.save_path = save_path
		root.add_child(menu)
		menu.show_strikers()
	else:
		var game = load("res://Main.tscn").instantiate()
		game.save_path = save_path
		root.add_child(game)
		if clip != "Idle":
			game.kicker.position = game.kicker.approach
			game.kicker.footballer_animation.play(clip)
			game.kicker.footballer_animation.advance(time)
			game.kicker.footballer_animation.pause()
			game.set_process(false)
			game.set_physics_process(false)
			game.look_from_kicker()
		if view == "stadium":
			for child in game.get_children():
				if child is CanvasLayer: child.hide()
			game.aim_marker.hide()
			var location: Vector3 = game.kicker.global_position
			game.camera.position = location + Vector3(.5, 1.4, -4.8)
			game.camera.fov = 32.0
			game.camera.look_at(location + Vector3(0, 1.13, 0))
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	DirAccess.remove_absolute(save_path)
	print("MESHY_PLAYER_CAPTURE ", view, " ", error)
	quit(0 if error == OK else 1)
