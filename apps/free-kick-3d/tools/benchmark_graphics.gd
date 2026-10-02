extends SceneTree

const GraphicsQuality = preload("res://graphics_quality.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-graphics-benchmark.cfg"
	root.add_child(game)
	for quality in GraphicsQuality.PROFILES:
		GraphicsQuality.apply(game, quality)
		game.away_keeper.reset_pose()
		for i in range(90): await RenderingServer.frame_post_draw
		var times: Array[float] = []
		var draw_calls := 0.0
		var previous := Time.get_ticks_usec()
		for i in range(300):
			if i == 40: game.away_keeper.dive(2.4, 1.4)
			if i == 180: game.away_keeper.reset_pose()
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			times.append(float(now - previous) / 1000.0)
			previous = now
			draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		times.sort()
		var sum := 0.0
		for frame_time in times: sum += frame_time
		var average: float = sum / times.size()
		var p95: float = times[mini(roundi(times.size() * 0.95), times.size() - 1)]
		print("GRAPHICS_BENCH %s 1280x720 avg_ms=%.2f p95_ms=%.2f avg_fps=%.1f draw_calls=%.0f" % [quality, average, p95, 1000.0 / average, draw_calls / times.size()])
	quit()
