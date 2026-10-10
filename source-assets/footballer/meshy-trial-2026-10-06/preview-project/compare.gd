extends SceneTree
## Static comparison only. Loads external GLBs without importing into the game.
const TARGET_HEIGHT := 1.898873
const CurrentVisual = preload("res://current_visual.gd")

func _initialize() -> void:
	call_deferred("capture")

func load_avatar(path: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(path, state, 8 | 16)
	if error != OK:
		push_error("GLB load failed: %s (%s)" % [path, error])
		return null
	return document.generate_scene(state) as Node3D

func mesh_bounds(avatar: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for item in avatar.find_children("*", "MeshInstance3D", true, false):
		var mesh := item as MeshInstance3D
		if not mesh.visible or mesh.mesh == null:
			continue
		var part: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = part if first else bounds.merge(part)
		first = false
	return bounds

func style_current(avatar: Node3D) -> void:
	var body := avatar.get_node("FootballerRig/Skeleton3D/FootballerBody") as MeshInstance3D
	CurrentVisual.apply_profile(body, {"skin":"c99068", "shirt":"ebebdf", "shorts":"213d6e", "hair":"30241d"})
	for item in avatar.find_children("*", "MeshInstance3D", true, false):
		var mesh := item as MeshInstance3D
		if mesh.name == "Beard":
			mesh.visible = false

func label_at(text: String, horizontal: float, width: float, top: float, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(horizontal, top)
	label.size = Vector2(width, 50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	root.add_child(label)

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("Usage: current.glb candidate.glb output.png [front|back|profile|three_quarter] [clay]")
		quit(1)
		return
	var view := args[3] if args.size() > 3 else "front"
	var clay := args.size() > 4 and args[4] == "clay"
	var integrated := args.size() > 4 and args[4] == "integrated"
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
	for index in range(2):
		var pivot := Node3D.new()
		scene.add_child(pivot)
		var avatar := load_avatar(args[index])
		if avatar == null:
			quit(1)
			return
		pivot.add_child(avatar)
		if index == 0 or integrated:
			style_current(avatar)
		if clay:
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("d3d5d7")
			material.roughness = 0.85
			for item in avatar.find_children("*", "MeshInstance3D", true, false):
				(item as MeshInstance3D).material_override = material
		var bounds := mesh_bounds(avatar)
		if bounds.size.y <= 0:
			push_error("Empty GLB bounds")
			quit(1)
			return
		avatar.position -= Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
		pivot.scale = Vector3.ONE * TARGET_HEIGHT / bounds.size.y
		pivot.position.x = -0.86 if index == 0 else 0.86
		match view:
			"back": pivot.rotation.y = PI
			"profile": pivot.rotation.y = PI / 2
			"three_quarter": pivot.rotation.y = -PI / 6
		print("TRIAL_MODEL ", index, " height=", bounds.size.y, " scale=", pivot.scale.x)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.55
	camera.position = Vector3(0, 0.96, 7)
	camera.look_at(Vector3(0, 0.96, 0))
	camera.make_current()
	var screen := root.get_visible_rect().size
	label_at("ACTUAL · uniforme claro", 0, screen.x / 2, 24, 23)
	label_at("UNIFORME MESHY · integrado" if integrated else "MESHY 6 LITE · prueba estática", screen.x / 2, screen.x / 2, 24, 23)
	label_at("Misma altura, cámara y luz · %s" % view, 0, screen.x, screen.y - 45, 19)
	for frame in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_viewport().get_texture().get_image().save_png(args[2])
	print("TRIAL_CAPTURE ", view, " ", error)
	quit(0 if error == OK else 1)
