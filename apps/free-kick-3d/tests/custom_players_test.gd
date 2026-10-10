extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = "/tmp/futbol-custom-players-test.cfg"
	root.add_child(menu)
	menu.show_custom_striker()
	menu.save_custom("skin","805135")
	menu.save_custom("shirt","aa2233")
	menu.save_custom("beard",true)
	menu.save_appearance("name","PRUEBA")
	menu.select_keeper(2)
	menu.show_custom_keeper()
	menu.save_custom("shirt","7733aa")
	menu.save_custom("hair","faf0ab")
	menu.save_appearance("keeper_name","ARQUERO")
	menu.save_appearance("keeper_number",17)
	var stored := ConfigFile.new()
	assert(stored.load(menu.save_path) == OK)
	assert(stored.get_value("appearance","striker") == 3)
	assert(stored.get_value("appearance","keeper") == 3)
	assert(stored.get_value("custom_striker","shirt") == "aa2233")
	var game = load("res://Main.tscn").instantiate()
	game.save_path = menu.save_path
	root.add_child(game)
	assert(game.player_name == "PRUEBA")
	var striker_body: MeshInstance3D = game.kicker.footballer_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	var keeper_body: MeshInstance3D = game.home_keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	var striker_materials: Array[String] = []
	var keeper_materials: Array[String] = []
	for i in range(striker_body.mesh.get_surface_count()):
		striker_materials.append(striker_body.mesh.surface_get_material(i).resource_name)
	for i in range(keeper_body.mesh.get_surface_count()):
		keeper_materials.append(keeper_body.mesh.surface_get_material(i).resource_name)
	assert("MeshyPlayer" in striker_materials and "Jersey" in striker_materials)
	assert("GoalkeeperGloves" not in striker_materials and "GoalkeeperGloves" in keeper_materials)
	assert(game.kicker.footballer_visual.get_node("FootballerRig/Skeleton3D").get_bone_count() == game.home_keeper.skeleton.get_bone_count())
	for sample in [[striker_body, Color("aa2233")], [keeper_body, Color("7733aa")]]:
		var body: MeshInstance3D = sample[0]
		for i in body.mesh.get_surface_count():
			if body.mesh.surface_get_material(i).resource_name == "Jersey":
				var fabric := body.get_surface_override_material(i) as ShaderMaterial
				assert(fabric.get_shader_parameter("tint") == sample[1])
				assert(fabric.get_shader_parameter("albedo_map") != null)
				assert(fabric.get_shader_parameter("normal_map") != null)
				assert(fabric.get_shader_parameter("lettering_enabled"))
	var print_view: SubViewport = game.home_keeper.goalkeeper_visual.get_node("JerseyPrint")
	assert(print_view.get_node("Name").text == "ARQUERO")
	assert(print_view.get_node("Number").text == "17")
	assert(game.kicker.visual_model == load("res://footballer_model.gd").MESHY_STRIKER_INDEX)
	assert(game.kicker.footballer_animation.has_animation("Kick"))
	assert(game.home_keeper.goalkeeper_animation.has_animation("SaveLeft"))
	DirAccess.remove_absolute(menu.save_path)
	print("PASS: delantero personalizado y arquero elegido persisten y se aplican en la partida")
	quit()
