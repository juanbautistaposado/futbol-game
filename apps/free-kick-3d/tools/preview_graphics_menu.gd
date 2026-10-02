extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = "/tmp/futbol-graphics-menu-preview.cfg"
	root.add_child(menu)
	menu.show_settings()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	var path := "/tmp/futbol-graphics-menu.png"
	var error := root.get_viewport().get_texture().get_image().save_png(path)
	print("GRAPHICS_MENU_PREVIEW ", path, " ", error)
	quit(0 if error == OK else 1)
