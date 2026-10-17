extends SceneTree
## Capture actual studio output for facial-hair toggles and every skin preset.
const Editor = preload("res://ui/character_editor.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "/tmp/futbol-appearance"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = "/tmp/futbol-appearance-capture.cfg"
	DirAccess.remove_absolute(menu.save_path)
	root.add_child(menu)
	menu.show_custom_striker()
	var editor: Control = menu.page.get_node("CharacterEditor")
	editor.get_node("CategoryAppearance").pressed.emit()
	await create_timer(0.3).timeout
	for i in range(Editor.SKIN_COLORS.size()):
		editor.find_child("FieldSkinSwatch" + str(i), true, false).pressed.emit()
		await save_frame(output.path_join("skin-" + str(i + 1) + ".png"))
	editor.find_child("FieldSkinSwatch3", true, false).pressed.emit()
	editor.find_child("FieldBeard", true, false).pressed.emit()
	for sample in [[false, "clean"], [true, "beard"]]:
		editor.find_child("BeardOn" if sample[0] else "BeardOff", true, false).pressed.emit()
		await save_frame(output.path_join(sample[1] + ".png"))
	menu.show_custom_keeper()
	editor = menu.page.get_node("CharacterEditor")
	editor.get_node("CategoryAppearance").pressed.emit()
	editor.find_child("FieldBeard", true, false).pressed.emit()
	await create_timer(0.3).timeout
	await save_frame(output.path_join("keeper-clean.png"))
	DirAccess.remove_absolute(menu.save_path)
	quit()

func save_frame(path: String) -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("APPEARANCE_PREVIEW ", path)
