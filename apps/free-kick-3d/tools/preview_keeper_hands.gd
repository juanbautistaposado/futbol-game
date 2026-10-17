extends SceneTree
## Close views reveal palm orientation and glove deformation hidden in wide shots.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "/tmp/keeper-hands.png"
	var pose := args[1] if args.size() > 1 else "ready"
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("323d49")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	scene.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	light.light_energy = 1.0
	scene.add_child(light)
	var keeper = load("res://keeper.gd").new()
	keeper.configure(-1, Color.GREEN)
	scene.add_child(keeper)
	keeper.position = Vector3(0.0, 1.035, 0.0)
	keeper.set_process(false)
	# Optional external GLB for a matched before/after deformation comparison.
	if args.size() > 3:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		assert(document.append_from_file(args[3], state) == OK)
		var baseline := document.generate_scene(state)
		var original: MeshInstance3D = baseline.get_node("FootballerRig/Skeleton3D/FootballerBody")
		var body: MeshInstance3D = keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
		for i in body.mesh.get_surface_count(): body.set_surface_override_material(i, null)
		body.mesh = original.mesh
		preload("res://footballer_visual.gd").apply_meshy(body)
		preload("res://footballer_visual.gd").apply_profile(body, preload("res://footballer_model.gd").DONNARUMMA)
		baseline.free()
	var clip := "keeper_motion/Ready"
	var time := 0.0
	if pose == "catch":
		clip = "Catch"
		time = 0.30
	elif pose != "ready":
		var side := -1.0 if pose.ends_with("left") else 1.0
		var low := pose.begins_with("low")
		clip = "keeper_motion/Save" + ("Low" if low else "") + ("Left" if side < 0.0 else "Right")
		time = 0.45
		keeper.rotation.z = -side * deg_to_rad(70.0 if low else 45.0)
		keeper.position.y = 0.65 if low else 1.6
	keeper.goalkeeper_animation.play(clip, 0.0)
	keeper.goalkeeper_animation.seek(time, true)
	keeper.goalkeeper_animation.pause()
	keeper.skeleton.force_update_all_bone_transforms()
	var left: Vector3 = keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.left_hand_bone).origin
	var right: Vector3 = keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.right_hand_bone).origin
	var camera := Camera3D.new()
	scene.add_child(camera)
	var target := (left + right) * 0.5
	camera.position = target + Vector3(0.3, 0.2, 3.0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.3
	camera.look_at(target)
	if args.size() > 2 and args[2] == "side":
		camera.position = target + Vector3(3.0, 0.3, 0.5)
		camera.look_at(target)
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("KEEPER_HANDS ", pose, " ", error)
	quit(0 if error == OK else 1)
