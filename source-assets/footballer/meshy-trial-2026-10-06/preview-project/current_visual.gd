extends RefCounted
## Preserve texture detail and independent colors; jersey text follows skinned UVs.
const HAIR = preload("res://shaders/athlete_hair.gdshader")
const FABRIC = preload("res://shaders/athlete_kit.gdshader")

static func apply_profile(mesh: MeshInstance3D, profile: Dictionary) -> void:
	var shirt := Color(str(profile.shirt))
	var skin := Color(str(profile.skin))
	var colors := {"Jersey":shirt,"Shorts":Color(str(profile.shorts)),"Skin":skin,"Hair":Color(str(profile.hair)),"HairScalp":Color(str(profile.hair)),"HairStrands":Color(str(profile.hair)),"Beard":Color(str(profile.hair)).lerp(skin,0.08),"Socks":shirt}
	for i in range(mesh.mesh.get_surface_count()):
		var source := mesh.mesh.surface_get_material(i) as StandardMaterial3D
		if source == null: continue
		var region: String = source.resource_name.get_slice(".", 0)
		if not colors.has(region): continue
		if region == "HairScalp":
			var haircut := mesh.get_surface_override_material(i) as ShaderMaterial
			if haircut == null: haircut = ShaderMaterial.new()
			haircut.shader = HAIR
			haircut.set_shader_parameter("hair_tint", colors[region])
			haircut.set_shader_parameter("skin_tint", skin)
			mesh.set_surface_override_material(i, haircut)
		elif region in ["Jersey", "Shorts", "Socks"]:
			var fabric := mesh.get_surface_override_material(i) as ShaderMaterial
			if fabric == null: fabric = ShaderMaterial.new()
			fabric.shader = FABRIC
			fabric.set_shader_parameter("tint", colors[region])
			fabric.set_shader_parameter("shorts_details", region == "Shorts")
			fabric.set_shader_parameter("albedo_map", source.albedo_texture)
			fabric.set_shader_parameter("normal_map", source.normal_texture)
			fabric.set_shader_parameter("normal_depth", source.normal_scale)
			fabric.set_shader_parameter("roughness_map", source.roughness_texture)
			mesh.set_surface_override_material(i, fabric)
		else:
			var personalized := mesh.get_surface_override_material(i) as StandardMaterial3D
			if personalized == null: personalized = source.duplicate()
			personalized.albedo_color = colors[region]
			if region == "HairStrands":
				personalized.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				personalized.alpha_scissor_threshold = 0.35
				personalized.cull_mode = BaseMaterial3D.CULL_DISABLED
				personalized.roughness = 0.9
				personalized.metallic_specular = 0.15
			mesh.set_surface_override_material(i, personalized)

static func apply_lettering(avatar: Node3D, mesh: MeshInstance3D, player_name: String, number: int) -> void:
	var existing := avatar.get_node_or_null("JerseyPrint") as SubViewport
	if existing:
		(existing.get_node("Name") as Label).text = player_name.to_upper()
		(existing.get_node("Name") as Label).add_theme_font_size_override("font_size", mini(48, roundi(330.0 / maxf(float(player_name.length()) * 0.62, 1.0))))
		(existing.get_node("Number") as Label).text = str(number)
		existing.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	var print_view := SubViewport.new()
	print_view.name = "JerseyPrint"
	print_view.size = Vector2i(512, 512)
	print_view.transparent_bg = true
	print_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	print_view.disable_3d = true
	avatar.add_child(print_view)
	for item in [["Name", player_name.to_upper(), 32, 48, 52], ["Number", str(number), 96, 142, 228]]:
		var label := Label.new()
		label.name = item[0]
		label.text = item[1]
		label.position = Vector2(8, item[2])
		label.size = Vector2(496, item[4])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var font_size: int = mini(int(item[3]), roundi(330.0 / maxf(float(player_name.length()) * 0.62, 1.0))) if item[0] == "Name" else int(item[3])
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color("f0eee5"))
		print_view.add_child(label)
	for i in range(mesh.mesh.get_surface_count()):
		var source := mesh.mesh.surface_get_material(i)
		if source.resource_name.get_slice(".", 0) != "Jersey": continue
		var fabric := mesh.get_surface_override_material(i) as ShaderMaterial
		if fabric:
			fabric.set_shader_parameter("lettering_map", print_view.get_texture())
			fabric.set_shader_parameter("lettering_enabled", true)
