extends SceneTree
## Same nine-avatar scene before/after; native renderer, no editor viewport.
func _initialize() -> void:
	call_deferred("measure")

func measure() -> void:
	root.size = Vector2i(1280,720)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("454950")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = .65
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30,-25,0)
	world.add_child(light)
	for i in range(9):
		var player = load("res://kicker.gd").new()
		world.add_child(player)
		player.apply_identity(4,"PLAYER",10)
		player.position = Vector3((i % 3 - 1) * 1.65,0,(i / 3) * -2.5)
		player.rotation.y = PI
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0,3,8)
	camera.look_at(Vector3(0,1,-2.5))
	for i in range(60): await RenderingServer.frame_post_draw
	var samples: Array[float] = []
	var cpu: Array[float] = []
	var previous := Time.get_ticks_usec()
	for i in range(240):
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		samples.append((now-previous)/1000.0)
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		previous = now
	var average := 0.0
	var cpu_average := 0.0
	for value in samples: average += value / samples.size()
	for value in cpu: cpu_average += value / cpu.size()
	samples.sort()
	var report := {"frames":samples.size(),"avatars":9,"resolution":[1280,720],
		"average_frame_ms":average,"p95_frame_ms":samples[roundi(samples.size()*.95)-1],
		"median_frame_ms":samples[samples.size()/2],"maximum_frame_ms":samples.back(),
		"average_process_ms":cpu_average,
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"rendered_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"scope":"Native Godot executable; isolated nine-avatar scene, not release web/mobile"}
	var args := OS.get_cmdline_user_args()
	if args.size():
		var file := FileAccess.open(args[0],FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	print("CLOTH_PROFILE ",JSON.stringify(report))
	quit()
