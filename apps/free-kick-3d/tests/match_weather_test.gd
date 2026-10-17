extends SceneTree
const Weather = preload("res://match_weather.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	assert(Weather.select_for_roll(0.0) == "soleado")
	assert(Weather.select_for_roll(0.599999) == "soleado")
	assert(Weather.select_for_roll(0.60) == "nublado")
	assert(Weather.select_for_roll(0.899999) == "nublado")
	assert(Weather.select_for_roll(0.90) == "lluvia")
	assert(Weather.select_for_roll(1.0) == "lluvia")
	var counts := {"soleado": 0, "nublado": 0, "lluvia": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 14102026
	for i in 100000: counts[Weather.select_for_roll(rng.randf())] += 1
	assert(abs(counts.soleado - 60000) < 1000)
	assert(abs(counts.nublado - 30000) < 1000)
	assert(abs(counts.lluvia - 10000) < 1000)
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	var sun := DirectionalLight3D.new()
	world.add_child(sun)
	var settings := Environment.new()
	var weather := Weather.new()
	world.add_child(weather)
	weather.configure(settings, sun, camera)
	weather.set_weather("soleado")
	var daylight := sun.light_energy
	assert(weather.rain == null or not weather.rain.emitting)
	weather.set_weather("nublado")
	assert(sun.light_energy < daylight and not weather.is_processing())
	weather.set_weather("lluvia")
	assert(weather.rain.emitting and weather.rain.visible and weather.is_processing())
	var particle_id := weather.rain.get_instance_id()
	camera.position = Vector3(3, 2, -40)
	weather._process(0.0)
	assert(weather.rain.global_position.is_equal_approx(camera.position - camera.basis.z * 8 + Vector3.UP * 7))
	camera.position = Vector3(0, 3, 60)
	camera.rotation.y = PI
	weather._process(0.0)
	assert(weather.rain.global_position.z > camera.position.z)
	assert(weather.rain.get_instance_id() == particle_id, "Reuse rain when switching cameras")
	weather.set_weather("soleado")
	assert(not weather.rain.visible and not weather.rain.emitting)
	assert(is_equal_approx(sun.light_energy, daylight), "Sunny restores the original lighting")
	world.queue_free()
	await process_frame
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-match-weather-test.cfg"
	root.add_child(game)
	var chosen: String = game.weather.current
	assert(chosen in Weather.TYPES)
	var weather_id: int = game.weather.get_instance_id()
	game.start_defense()
	assert(game.weather.current == chosen and game.weather.get_instance_id() == weather_id)
	game.start_attack()
	assert(game.weather.current == chosen and game.weather.get_instance_id() == weather_id, "Weather is drawn once per match, not every shot")
	game.queue_free()
	await process_frame
	print("PASS: weighted weather 60/30/10 ", counts, "; distinct light and camera-following rain")
	quit()
