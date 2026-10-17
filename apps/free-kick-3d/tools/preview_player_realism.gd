extends SceneTree
## Identical studio views for geometry/material review, using runtime identities.
const Human = preload("res://footballer_model.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() else "/tmp/player-realism"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 960)
	if args.size() > 1 and args[1] == "no-lod": root.mesh_lod_threshold = 0.0
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("202832")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c3cedb")
	env.ambient_light_energy = 0.45
	environment.environment = env
	world.add_child(environment)
	for setup in [[Vector3(-25, -30, 0), 0.8, Color("fff1df")], [Vector3(-15, 145, 0), 0.55, Color("c2d7f4")]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = setup[0]
		light.light_energy = setup[1]
		light.light_color = setup[2]
		light.shadow_enabled = not (args.size() > 1 and args[1] == "no-shadows")
		world.add_child(light)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var player = load("res://kicker.gd").new()
	world.add_child(player)
	player.rotation.y = PI
	var profile := Human.PROFILES[0].duplicate()
	profile.shirt = "b7cedb"
	profile.beard = true
	for view in ["face", "profile", "clean", "blink", "beard_detail", "nape", "rear_quarter", "left_profile", "shirt", "back", "kick"]:
		profile.beard = view != "clean"
		player.apply_identity(3, "MATEO", 10, profile)
		var body: MeshInstance3D = player.footballer_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
		if body.has_node("FacialMotion"):
			body.get_node("FacialMotion").set_process(false)
			body.set_blend_shape_value(0, 1.0 if view == "blink" else 0.0)
		player.footballer_animation.play("Kick" if view == "kick" else "Idle")
		player.footballer_animation.seek(0.48 if view == "kick" else 0.0, true)
		player.footballer_animation.pause()
		var target := Vector3(0, 1.72, 0)
		camera.size = 0.53
		camera.position = Vector3(0.17, 1.76, 3)
		if view == "profile": camera.position = Vector3(2.6, 1.76, 2)
		if view == "left_profile": camera.position = Vector3(-3, 1.76, 0.5)
		if view == "nape": camera.position = Vector3(0.0, 1.78, -3)
		if view == "rear_quarter": camera.position = Vector3(2.5, 1.78, -2.5)
		if view == "beard_detail":
			camera.size = 0.34
			camera.position = Vector3(1.3, 1.72, 3)
			target = Vector3(0, 1.71, 0)
		if view in ["shirt", "back", "kick"]:
			target = Vector3(0, 1.02, 0)
			camera.size = 2.15
			camera.position = Vector3(0.45, 1.3, -4 if view == "back" else 4)
		camera.look_at(target)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(output.path_join(view + ".png")) == OK)
		print("PLAYER_REALISM_CAPTURE ", view)
	player.queue_free()
	await process_frame
	quit()
