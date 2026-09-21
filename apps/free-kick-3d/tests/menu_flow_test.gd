extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://Menu.tscn")
	await scene_changed
	var menu = current_scene
	assert(menu.name == "MainMenu")
	assert(menu.play_button.has_focus())
	assert(menu.difficulty_buttons.size() == 3)
	menu.show_appearance()
	await process_frame
	var has_name_field := false
	for child in menu.page.get_children():
		if child is LineEdit:
			has_name_field = true
	assert(has_name_field)
	menu.show_menu()
	menu.play_button.pressed.emit()
	assert(is_instance_valid(menu.start_button))
	assert(menu.shot_count >= 5 and menu.shot_count <= 15)
	assert(menu.player_count >= 1 and menu.player_count <= 4)
	menu.start_button.pressed.emit()
	await scene_changed
	assert(current_scene.name == "FreeKickGame")
	assert(current_scene.phase == current_scene.Phase.ATTACK)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	current_scene._unhandled_input(escape)
	await scene_changed
	assert(current_scene.name == "MainMenu")
	assert(current_scene.play_button.has_focus())
	print("PASS: menú, aspecto, jugar y volver con Escape")
	quit()
