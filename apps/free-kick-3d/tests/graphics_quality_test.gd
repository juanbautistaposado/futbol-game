extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func find_sun(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D: return node
	for child in node.get_children():
		var found := find_sun(child)
		if found != null: return found
	return null

func find_environment(node: Node) -> Environment:
	if node is WorldEnvironment: return node.environment
	for child in node.get_children():
		var found := find_environment(child)
		if found != null: return found
	return null

func run() -> void:
	var save_path := "/tmp/futbol-graphics-quality-test.cfg"
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = save_path
	root.add_child(menu)
	menu.select_graphics_quality("bajo")
	assert(root.get_viewport().msaa_3d == Viewport.MSAA_DISABLED)
	assert(not find_sun(menu).shadow_enabled)
	assert(not find_environment(menu).ssao_enabled and not find_environment(menu).glow_enabled)
	menu.select_graphics_quality("medio")
	assert(root.get_viewport().msaa_3d == Viewport.MSAA_2X)
	assert(find_sun(menu).shadow_enabled)
	assert(not find_environment(menu).ssao_enabled)
	menu.select_graphics_quality("alto")
	assert(root.get_viewport().msaa_3d == Viewport.MSAA_4X)
	var game = load("res://Main.tscn").instantiate()
	game.save_path = save_path
	root.add_child(game)
	assert(root.get_viewport().msaa_3d == Viewport.MSAA_4X)
	assert(find_sun(game).shadow_enabled)
	assert(find_environment(game).ssao_enabled and find_environment(game).glow_enabled)
	DirAccess.remove_absolute(save_path)
	print("PASS: perfiles gráficos guardados y aplicados en menú y partido")
	quit()
