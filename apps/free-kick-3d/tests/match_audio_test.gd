extends SceneTree

const PROFILE_PATH := "/tmp/futbol-match-audio-test.cfg"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = PROFILE_PATH
	root.add_child(menu)
	menu.show_settings()
	var slider: HSlider
	for child in menu.page.get_children():
		if child is HSlider:
			slider = child
	assert(slider != null)
	slider.value = 0
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Match SFX")))
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Results")))
	slider.value = 50
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Match SFX")))
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Results")))
	var profile := ConfigFile.new()
	assert(profile.load(PROFILE_PATH) == OK)
	assert(is_equal_approx(float(profile.get_value("settings", "sound_volume")), 0.5))
	menu.queue_free()
	await process_frame
	var audio = preload("res://match_audio.gd").new()
	root.add_child(audio)
	assert(not audio.result_player.playing)
	assert(not audio.has_node("CrowdAmbience"))
	audio.play_effect("kick", Vector3.ZERO)
	assert(audio.has_node("Sound_kick"))
	audio.play_effect("save", Vector3.ZERO)
	assert(audio.has_node("Sound_save"))
	audio.play_effect("post", Vector3.ZERO)
	assert(audio.has_node("Sound_post"))
	audio.play_effect("net", Vector3.ZERO)
	assert(audio.has_node("Sound_net"))
	audio.play_result(true)
	assert(audio.result_player.playing)
	assert(audio.result_player.stream == audio.GOAL_SIGNAL)
	assert(audio.result_player.stream.get_length() < 0.6)
	# Allow the audio mixer to deliver completion, still before the next turn (1.25 s).
	await create_timer(1.0).timeout
	assert(not audio.result_player.playing)
	audio.play_result(false)
	assert(audio.result_player.playing)
	assert(audio.result_player.stream == audio.MISS_SIGNAL)
	assert(audio.result_player.stream.get_length() < 0.6)
	await create_timer(1.0).timeout
	assert(not audio.result_player.playing)
	assert(audio.get_child_count() == 1, "One result player; finished impact players must be freed")
	audio.queue_free()
	await process_frame
	DirAccess.remove_absolute(PROFILE_PATH)
	print("PASS: señales breves de gol/fallo, limpieza de efectos y volumen persistente")
	quit()
