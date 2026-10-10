extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://Menu.tscn")
	await scene_changed
	var menu = current_scene
	assert(menu.name == "MainMenu")
	menu.save_path = "/tmp/futbol-impeccable-menu-flow.cfg"
	assert(menu.play_button.has_focus())
	menu.show_settings()
	assert(menu.difficulty_buttons.size() == 3)
	menu.show_appearance()
	await process_frame
	var has_name_field := false
	for child in menu.page.get_children():
		if child is LineEdit:
			has_name_field = true
	assert(has_name_field)
	menu.show_custom_keeper()
	await process_frame
	assert(menu.page.is_ancestor_of(root.gui_get_focus_owner()))
	var back := InputEventKey.new()
	back.keycode = KEY_ESCAPE
	back.pressed = true
	menu._unhandled_input(back)
	await process_frame
	assert(menu.page.is_ancestor_of(root.gui_get_focus_owner()))
	assert(root.gui_get_focus_owner().text == "PERSONALIZADO")
	menu._unhandled_input(back)
	assert(menu.difficulty_buttons.size() == 3)
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
	current_scene.match_overlay._unhandled_input(escape)
	assert(paused)
	assert(current_scene.match_overlay.pause_panel.visible)
	current_scene.match_overlay.set_paused(false)
	assert(not paused)
	current_scene.shot_goal = -1
	current_scene.resolve_shot(true,"¡Gol!")
	assert(current_scene.match_overlay.result_label.text == "¡GOL!")
	current_scene.match_overlay.set_paused(true)
	await create_timer(1.5).timeout
	assert(current_scene.phase == current_scene.Phase.RESOLVING)
	current_scene.match_overlay.set_paused(false)
	await create_timer(1.4).timeout
	assert(current_scene.phase != current_scene.Phase.RESOLVING)
	current_scene.match_overlay.set_paused(true)
	current_scene.match_overlay.pause_panel.get_child(1).get_child(2).pressed.emit()
	await scene_changed
	assert(current_scene.name == "MainMenu")
	assert(current_scene.play_button.has_focus())
	DirAccess.remove_absolute("/tmp/futbol-impeccable-menu-flow.cfg")
	print("PASS: foco en personalizado, Esc por niveles, menú, aspecto, jugar, resultado central, pausa real, continuar y salir")
	quit()
