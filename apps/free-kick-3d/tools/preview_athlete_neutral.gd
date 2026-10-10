extends SceneTree
## Neutral studio review of the exported mesh, without stadium or gameplay.
const Visual = preload("res://footballer_visual.gd")
const Player = preload("res://kicker.gd")
const Keeper = preload("res://keeper.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() else "/tmp/athlete-v3-neutral.png"
	var view := args[1] if args.size() > 1 else "front"
	var studio := Node3D.new()
	root.add_child(studio)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("454950")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.65
	studio.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-28, -30, 0)
	light.light_energy = 0.8
	studio.add_child(light)
	var role := args[4] if args.size() > 4 else "goalkeeper"
	var avatar = (Keeper.GOALKEEPER_SCENE if role == "goalkeeper" else Player.FOOTBALLER_SCENE).instantiate()
	studio.add_child(avatar)
	var body := avatar.get_node("FootballerRig/Skeleton3D/FootballerBody") as MeshInstance3D
	Visual.apply_profile(body, {"skin":"c99068", "shirt":"406a92", "shorts":"243345", "hair":"30241d"})
	Visual.apply_lettering(avatar, body, "ATLETA", 10)
	avatar.get_node("FootballerRig/Skeleton3D/Beard").visible = view in ["head", "head_profile"]
	var animation := avatar.get_node("AnimationPlayer") as AnimationPlayer
	animation.play(args[2] if args.size() > 2 else "Idle")
	animation.advance(float(args[3]) if args.size() > 3 else (0.4 if args.size() > 2 else 0.0))
	animation.pause()
	var camera := Camera3D.new()
	studio.add_child(camera)
	camera.position = Vector3(4.5, 1.15, 0) if view == "profile" else Vector3(0, 1.15, -4.5 if view == "back" else 4.5)
	camera.fov = 30
	camera.look_at(Vector3(0, 0.98, 0))
	if view in ["head", "head_profile"]:
		camera.position = Vector3(1.1, 1.75, 0.9) if view == "head_profile" else Vector3(0, 1.75, 1.6)
		camera.fov = 23
		camera.look_at(Vector3(0, 1.73, 0))
	if view in ["shorts", "shorts_profile"]:
		camera.position = Vector3(1.1, 1.1, 1.2) if view == "shorts_profile" else Vector3(0, 1.1, 1.5)
		camera.fov = 28
		camera.look_at(Vector3(0, 0.88, 0))
	if view in ["torso", "torso_profile"]:
		camera.position = Vector3(0.9, 1.4, 1.5) if view == "torso_profile" else Vector3(0, 1.4, 1.8)
		camera.fov = 29
		camera.look_at(Vector3(0, 1.35, 0))
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("ATHLETE_NEUTRAL ", view, " ", error)
	quit(0 if error == OK else 1)
