extends SceneTree
## Review every preset against the two shared, updated meshes.
const Human = preload("res://footballer_model.gd")
const Visual = preload("res://footballer_visual.gd")
const Player = preload("res://kicker.gd")
const Keeper = preload("res://keeper.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
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
	var entries: Array = []
	for profile in Human.PROFILES:
		entries.append(["footballer", profile.duplicate(), "CAMPO"])
	for i in range(3):
		var config := ConfigFile.new()
		config.set_value("appearance", "keeper", i)
		entries.append(["goalkeeper", Human.keeper_profile(config), "ARQUERO"])
	entries.append(["goalkeeper", Human.DONNARUMMA.duplicate(), "ARQUERO"])
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var profile: Dictionary = entry[1]
		var avatar: Node3D = (Keeper.GOALKEEPER_SCENE if entry[0] == "goalkeeper" else Player.FOOTBALLER_SCENE).instantiate()
		studio.add_child(avatar)
		avatar.position.x = (i - 3) * 0.95
		var body: MeshInstance3D = avatar.get_node("FootballerRig/Skeleton3D/FootballerBody")
		Visual.apply_profile(body, profile)
		var beard: MeshInstance3D = avatar.get_node("FootballerRig/Skeleton3D/Beard")
		beard.visible = bool(profile.beard)
		Visual.apply_profile(beard, profile)
		var animation: AnimationPlayer = avatar.get_node("AnimationPlayer")
		animation.play("Idle")
		animation.advance(0)
		animation.pause()
		var label := Label3D.new()
		label.text = "%s\n%s" % [profile.name, entry[2]]
		label.position = Vector3(avatar.position.x, 2.12, 0)
		label.font_size = 25
		label.pixel_size = 0.0018
		label.outline_size = 4
		studio.add_child(label)
	var camera := Camera3D.new()
	studio.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.9
	camera.position = Vector3(0, 1.1, 10)
	camera.look_at(Vector3(0, 1.1, 0))
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var args := OS.get_cmdline_user_args()
	var output := args[0] if args.size() else "/tmp/athlete-family.png"
	var error := root.get_viewport().get_texture().get_image().save_png(output)
	print("ATHLETE_FAMILY ", entries.size(), " ", error)
	quit(0 if error == OK else 1)
