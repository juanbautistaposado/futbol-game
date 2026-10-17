extends SceneTree
const Human = preload("res://footballer_model.gd")

func appearance_material(body: MeshInstance3D) -> ShaderMaterial:
	for i in body.mesh.get_surface_count():
		if body.mesh.surface_get_material(i).resource_name == "MeshyPlayer":
			return body.get_surface_override_material(i) as ShaderMaterial
	return null

func check_appearance(body: MeshInstance3D, profile: Dictionary) -> void:
	var atlas := appearance_material(body)
	assert(atlas != null and atlas.get_shader_parameter("personalization_enabled"))
	assert(atlas.get_shader_parameter("appearance_mask") != null, "El nuevo atlas necesita regiones independientes")
	assert(atlas.get_shader_parameter("cloth_mask") != null, "La camiseta cubre también zonas residuales del atlas")
	assert(atlas.get_shader_parameter("skin_tint") == Color(str(profile.skin)), "Piel personalizada")
	assert(atlas.get_shader_parameter("hair_tint") == Color(str(profile.hair)), "Cabello personalizado")
	assert(atlas.get_shader_parameter("shorts_tint") == Color(str(profile.shorts)), "Short personalizado")
	assert(atlas.get_shader_parameter("shirt_tint") == Color(str(profile.shirt)), "Camiseta independiente del short")
	assert(atlas.get_shader_parameter("beard_enabled") == bool(profile.beard), "Barba personalizada")
	assert(atlas.get_shader_parameter("albedo_map") != null and atlas.get_shader_parameter("normal_map") != null)
	assert(atlas.get_shader_parameter("skin_microdetail") != null)
	for i in body.mesh.get_surface_count():
		var region: String = body.mesh.surface_get_material(i).resource_name
		var detail := body.get_surface_override_material(i) as ShaderMaterial
		if region in ["HairGroom", "BrowGroom", "BeardGroom"]:
			assert(detail.get_shader_parameter("hair_tint") == Color(str(profile.hair)))
			assert(detail.get_shader_parameter("groom_visible") == (region != "BeardGroom" or bool(profile.beard)), "La geometría de barba responde al editor")
		elif region == "TailoredShorts":
			assert(detail.get_shader_parameter("tint") == Color(str(profile.shorts)))
		elif region == "EyeSurface":
			assert(detail.shader == preload("res://shaders/athlete_eyes.gdshader"))
		elif region == "FaceSkin":
			assert(detail.shader == preload("res://shaders/athlete_face.gdshader"))
			assert(detail.get_shader_parameter("face_albedo") == preload("res://assets/footballer/face_albedo.png"))
			assert(detail.get_shader_parameter("skin_tint") == Color(str(profile.skin)), "La cabeza acompaña el tono del cuerpo")
			assert(detail.get_shader_parameter("hair_tint") == Color(str(profile.hair)))
			assert(detail.get_shader_parameter("beard_enabled") == bool(profile.beard), "La nueva cara conserva la barba opcional")

func _initialize() -> void: call_deferred("run")
func run() -> void:
	var menu = load("res://Menu.tscn").instantiate()
	menu.save_path = "/tmp/futbol-custom-players-test.cfg"
	DirAccess.remove_absolute(menu.save_path)
	root.add_child(menu)
	menu.show_custom_striker()
	menu.save_custom("skin","805135")
	menu.save_custom("hair","edb467")
	menu.save_custom("shirt","aa2233")
	menu.save_custom("shorts","22aa77")
	menu.save_custom("beard",true)
	# An old save with hidden eyebrows must no longer hide them.
	menu.profile.set_value("custom_striker", "eyebrows", false)
	menu.save_appearance("name","PRUEBA")
	menu.save_appearance("number",23)
	menu.select_keeper(2)
	menu.show_custom_keeper()
	menu.save_custom("shirt","7733aa")
	menu.save_custom("skin","e4bb93")
	menu.save_custom("hair","faf0ab")
	menu.save_custom("shorts","ee8822")
	menu.save_custom("beard",false)
	menu.save_appearance("keeper_name","ARQUERO")
	menu.save_appearance("keeper_number",17)
	var stored := ConfigFile.new()
	assert(stored.load(menu.save_path) == OK)
	assert(stored.get_value("appearance","striker") == 3)
	assert(stored.get_value("appearance","keeper") == 3)
	assert(stored.get_value("custom_striker","shirt") == "aa2233")
	var striker_profile: Dictionary = Human.custom_profile(stored)
	assert(not striker_profile.has("eyebrows"))
	var keeper_profile: Dictionary = Human.keeper_profile(stored)
	var game = load("res://Main.tscn").instantiate()
	game.save_path = menu.save_path
	root.add_child(game)
	assert(game.player_name == "PRUEBA")
	var striker_body: MeshInstance3D = game.kicker.footballer_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	var keeper_body: MeshInstance3D = game.home_keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	assert(game.kicker.footballer_visual.scene_file_path == "res://assets/footballer/meshy_striker.glb", "Personalizar debe conservar la base 3D nueva")
	assert(game.home_keeper.goalkeeper_visual.scene_file_path == "res://assets/footballer/meshy_keeper.glb")
	check_appearance(striker_body, striker_profile)
	check_appearance(keeper_body, keeper_profile)
	assert(appearance_material(striker_body) != appearance_material(keeper_body))
	var striker_materials: Array[String] = []
	var keeper_materials: Array[String] = []
	for i in range(striker_body.mesh.get_surface_count()):
		striker_materials.append(striker_body.mesh.surface_get_material(i).resource_name)
	for i in range(keeper_body.mesh.get_surface_count()):
		keeper_materials.append(keeper_body.mesh.surface_get_material(i).resource_name)
	assert("MeshyPlayer" in striker_materials and "Jersey" in striker_materials)
	for materials in [striker_materials, keeper_materials]:
		assert("FaceSkin" in materials and "FaceInterior" in materials and "EyeSurface" in materials, "Piel facial, cavidades y ojos independientes")
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
	assert(game.kicker.footballer_visual.get_node("JerseyPrint/Name").text == "PRUEBA")
	assert(game.kicker.footballer_visual.get_node("JerseyPrint/Number").text == "23")
	assert(game.kicker.visual_model == load("res://footballer_model.gd").MESHY_STRIKER_INDEX)
	assert(game.kicker.footballer_animation.has_animation("Kick"))
	assert(game.home_keeper.goalkeeper_animation.has_animation("SaveLeft"))
	# Reuse one avatar when switching away and back; a previous identity's
	# pigment or beard must never remain in the next custom appearance.
	var avatar: Node3D = game.kicker.footballer_visual
	game.kicker.apply_identity(Human.MESHY_STRIKER_INDEX, "PLAYER", 10)
	assert(not appearance_material(striker_body).get_shader_parameter("personalization_enabled"))
	check_appearance(keeper_body, keeper_profile)
	game.kicker.apply_identity(3, "PRUEBA", 23, striker_profile)
	assert(game.kicker.footballer_visual == avatar)
	check_appearance(striker_body, striker_profile)
	var clean_profile := striker_profile.duplicate()
	clean_profile.beard = false
	game.kicker.apply_identity(3, "PRUEBA", 23, clean_profile)
	check_appearance(striker_body, clean_profile)
	check_appearance(keeper_body, keeper_profile)
	# A fresh gameplay instance reads both complete appearances from disk.
	game.free()
	var reloaded_game = load("res://Main.tscn").instantiate()
	reloaded_game.save_path = menu.save_path
	root.add_child(reloaded_game)
	check_appearance(reloaded_game.kicker.footballer_visual.get_node("FootballerRig/Skeleton3D/FootballerBody"), striker_profile)
	check_appearance(reloaded_game.home_keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody"), keeper_profile)
	reloaded_game.free()
	DirAccess.remove_absolute(menu.save_path)
	menu.free()
	print("PASS: nueva base 3D, piel/cabello/camiseta/short/barba/dorsal independientes y persistentes para ambos roles")
	quit()
