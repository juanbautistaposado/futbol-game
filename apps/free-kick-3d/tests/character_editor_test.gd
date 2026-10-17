extends SceneTree

const SAVE := "/tmp/futbol-character-editor-integration.cfg"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.remove_absolute(SAVE)
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = SAVE
	root.add_child(menu)
	menu.show_custom_striker()
	var editor: Control = menu.page.get_node("CharacterEditor")
	assert(menu.background.editor_enabled)
	assert(not menu.background.stadium_stage.visible)
	assert(menu.background.editor_stage.visible)
	var name_input: LineEdit = editor.find_child("NameInput", true, false)
	name_input.text = "EDITOR"
	name_input.text_changed.emit(name_input.text)
	var number: SpinBox = editor.find_child("NumberInput", true, false)
	number.value = 27
	editor.get_node("CategoryAppearance").pressed.emit()
	await create_timer(0.3).timeout
	assert(menu.background.editor_mode == "face")
	assert(is_equal_approx(menu.background.preview_camera.fov, 28.0))
	var skin: Button = editor.find_child("FieldSkinSwatch4", true, false)
	skin.pressed.emit()
	var selected_skin: String = skin.get_meta("color_hex")
	assert(editor.find_child("FieldSkinSwatch8", true, false) != null)
	editor.find_child("FieldHair", true, false).pressed.emit()
	var hair: ColorPickerButton = editor.find_child("HairPicker", true, false)
	hair.color_changed.emit(Color("a08050"))
	editor.find_child("FieldBeard", true, false).pressed.emit()
	editor.find_child("BeardOn", true, false).pressed.emit()
	assert(editor.find_child("EyebrowsOff", true, false) == null)
	assert(editor.find_child("EyebrowsOn", true, false) == null)
	editor.get_node("CategoryKit").pressed.emit()
	await create_timer(0.3).timeout
	assert(menu.background.editor_mode == "body")
	assert(is_equal_approx(menu.background.preview_camera.fov, 32.0))
	editor.rotation_requested.emit(PI)
	var shirt: ColorPickerButton = editor.find_child("ShirtPicker", true, false)
	shirt.color_changed.emit(Color("c53938"))
	assert(is_equal_approx(menu.background.player.rotation.y, menu.background.editor_yaw))
	editor.find_child("FieldShorts", true, false).pressed.emit()
	editor.find_child("FieldShortsSwatch5", true, false).pressed.emit()
	var stored := ConfigFile.new()
	assert(stored.load(SAVE) == OK)
	assert(stored.get_value("appearance", "striker") == 3)
	assert(stored.get_value("appearance", "name") == "EDITOR")
	assert(stored.get_value("appearance", "number") == 27)
	assert(stored.get_value("custom_striker", "skin") == selected_skin)
	assert(stored.get_value("custom_striker", "hair") == "a08050")
	assert(stored.get_value("custom_striker", "beard"))
	assert(stored.get_value("custom_striker", "shirt") == "c53938")
	assert(stored.get_value("custom_striker", "shorts") == "172438")
	editor.close_requested.emit()
	assert(not menu.background.editor_enabled)
	assert(menu.background.stadium_stage.visible)
	assert(not menu.background.editor_stage.visible)
	assert(is_zero_approx(menu.background.preview_camera.h_offset))
	menu.show_custom_keeper()
	editor = menu.page.get_node("CharacterEditor")
	name_input = editor.find_child("NameInput", true, false)
	name_input.text_changed.emit("ARQUERO")
	editor.get_node("CategoryKit").pressed.emit()
	editor.find_child("FieldShirtSwatch3", true, false).pressed.emit()
	assert(menu.profile.get_value("custom_keeper", "shirt") == "22724f")
	assert(menu.profile.get_value("appearance", "keeper_name") == "ARQUERO")
	assert(menu.profile.get_value("appearance", "name") == "EDITOR")
	var back := InputEventKey.new()
	back.keycode = KEY_ESCAPE
	back.pressed = true
	menu._unhandled_input(back)
	await process_frame
	assert(not menu.background.editor_enabled)
	assert(root.gui_get_focus_owner().text == "PERSONALIZADO")
	menu.queue_free()
	await process_frame
	DirAccess.remove_absolute(SAVE)
	print("PASS: editor changes persist per role, category zoom, rotation survives edits, studio exits and Esc returns to selection")
	quit()
