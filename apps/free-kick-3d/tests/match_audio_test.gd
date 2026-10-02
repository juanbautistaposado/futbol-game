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
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("Stadium")))
	slider.value = 50
	assert(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Match SFX")))
	var profile := ConfigFile.new()
	assert(profile.load(PROFILE_PATH) == OK)
	assert(is_equal_approx(float(profile.get_value("settings", "sound_volume")), 0.5))
	menu.queue_free()
	await process_frame
	var audio = preload("res://match_audio.gd").new()
	root.add_child(audio)
	assert(audio.crowd_player.playing)
	audio.play_effect("kick", Vector3.ZERO)
	assert(audio.has_node("Sound_kick"))
	audio.play_effect("save", Vector3.ZERO)
	assert(audio.has_node("Sound_save"))
	audio.play_effect("post", Vector3.ZERO)
	assert(audio.has_node("Sound_post"))
	audio.play_effect("net", Vector3.ZERO)
	assert(audio.has_node("Sound_net"))
	audio.play_goal_cheer()
	assert(audio.has_node("GoalCheer"))
	assert(audio.has_node("GoalCall"))
	assert(audio.get_node("GoalCall").stream.get_length() > 1.0)
	assert(is_equal_approx(audio.get_node("GoalCheer").stream.get_length(), 1.85))
	audio.queue_free()
	await process_frame
	DirAccess.remove_absolute(PROFILE_PATH)
	print("PASS: ambiente, efectos y volumen persistente")
	quit()
