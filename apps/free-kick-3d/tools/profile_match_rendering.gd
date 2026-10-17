extends SceneTree
## Reproducible match view. Measure each revision with the same binary and window.
func _initialize() -> void:
	call_deferred("measure")

func measure() -> void:
	var args := OS.get_cmdline_user_args()
	var quality := args[1] if args.size() > 1 else "alto"
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	seed(13013)
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/realism-profile-unused.cfg"
	root.add_child(game)
	preload("res://graphics_quality.gd").apply(game, quality)
	for i in range(120): await RenderingServer.frame_post_draw
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	var draws := 0.0
	var primitives := 0.0
	for i in range(240):
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME) / 240.0
		primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 240.0
	var average := 0.0
	for value in samples: average += value / samples.size()
	samples.sort()
	var report := {"quality": quality, "renderer": RenderingServer.get_current_rendering_method(),
		"resolution": [1280, 720], "frames": samples.size(), "average_frame_ms": average,
		"p95_frame_ms": samples[roundi(samples.size() * .95) - 1], "draw_calls": draws,
		"rendered_primitives": primitives, "texture_memory_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"scope": "Native debug executable on this machine, fixed attack view; not release web/mobile FPS"}
	if args.size():
		var file := FileAccess.open(args[0], FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	print("MATCH_RENDER_PROFILE ", JSON.stringify(report))
	quit()
