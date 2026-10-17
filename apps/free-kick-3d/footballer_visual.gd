extends RefCounted
## Preserve texture detail and independent colors; jersey text follows skinned UVs.
const HAIR = preload("res://shaders/athlete_hair.gdshader")
const FABRIC = preload("res://shaders/athlete_kit.gdshader")
const LATEX = preload("res://shaders/goalkeeper_latex.gdshader")
const APPEARANCE_MASK = preload("res://assets/footballer/meshy_appearance_mask.png")
const CLOTH_MASK = preload("res://assets/footballer/meshy_cloth_mask.png")
const FACIAL_MASK = preload("res://assets/footballer/meshy_facial_mask.png")
const GROOM = preload("res://shaders/athlete_groom.gdshader")
const EYES = preload("res://shaders/athlete_eyes.gdshader")
const SKIN_DETAIL = preload("res://assets/footballer/skin_microdetail.png")
const FACE = preload("res://shaders/athlete_face.gdshader")
const FACE_ALBEDO = preload("res://assets/footballer/face_albedo.png")
const FACIAL_MOTION = preload("res://footballer_facial_motion.gd")

static func apply_profile(mesh: MeshInstance3D, profile: Dictionary) -> void:
	if not mesh.has_node("FacialMotion"):
		for index in mesh.mesh.get_blend_shape_count():
			if mesh.mesh.get_blend_shape_name(index) != "Blink": continue
			var motion := FACIAL_MOTION.new()
			motion.name = "FacialMotion"
			motion.target = mesh
			motion.blink_index = index
			mesh.add_child(motion)
			break
	var shirt := Color(str(profile.shirt))
	var skin := Color(str(profile.skin))
	var colors := {"Jersey":shirt,"Shorts":Color(str(profile.shorts)),"Skin":skin,"Hair":Color(str(profile.hair)),"HairScalp":Color(str(profile.hair)),"HairStrands":Color(str(profile.hair)),"Beard":Color(str(profile.hair)).lerp(skin,0.08),"Socks":shirt}
	for i in range(mesh.mesh.get_surface_count()):
		var source := mesh.mesh.surface_get_material(i) as StandardMaterial3D
		if source == null: continue
		var region: String = source.resource_name.get_slice(".", 0)
		if region == "FaceSkin":
			var face := mesh.get_surface_override_material(i) as ShaderMaterial
			if face == null: face = ShaderMaterial.new()
			face.shader = FACE
			face.set_shader_parameter("face_albedo", FACE_ALBEDO)
			face.set_shader_parameter("skin_microdetail", SKIN_DETAIL)
			face.set_shader_parameter("skin_tint", skin)
			face.set_shader_parameter("hair_tint", colors.Hair)
			face.set_shader_parameter("beard_enabled", bool(profile.get("beard", false)))
			mesh.set_surface_override_material(i, face)
			continue
		if region == "EyeSurface":
			var eyes := mesh.get_surface_override_material(i) as ShaderMaterial
			if eyes == null: eyes = ShaderMaterial.new()
			eyes.shader = EYES
			mesh.set_surface_override_material(i, eyes)
			continue
		if region in ["HairGroom", "BeardGroom", "BrowGroom"]:
			var groom := mesh.get_surface_override_material(i) as ShaderMaterial
			if groom == null: groom = ShaderMaterial.new()
			groom.shader = GROOM
			groom.set_shader_parameter("hair_tint", colors.Hair)
			groom.set_shader_parameter("facial_hair", region == "BeardGroom")
			groom.set_shader_parameter("groom_visible", region != "BeardGroom" or bool(profile.get("beard", false)))
			mesh.set_surface_override_material(i, groom)
			continue
		if region == "TailoredShorts": region = "Shorts"
		if region == "CollarKnit":
			var collar := source.duplicate() as StandardMaterial3D
			collar.roughness = 0.86
			collar.metallic_specular = 0.22
			mesh.set_surface_override_material(i, collar)
			continue
		if region == "MeshyPlayer":
			var atlas := mesh.get_surface_override_material(i) as ShaderMaterial
			if atlas == null:
				apply_meshy(mesh)
				atlas = mesh.get_surface_override_material(i) as ShaderMaterial
			atlas.set_shader_parameter("appearance_mask", APPEARANCE_MASK)
			atlas.set_shader_parameter("cloth_mask", CLOTH_MASK)
			atlas.set_shader_parameter("facial_mask", FACIAL_MASK)
			atlas.set_shader_parameter("personalization_enabled", not bool(profile.get("preserve_atlas", false)))
			atlas.set_shader_parameter("skin_tint", skin)
			atlas.set_shader_parameter("hair_tint", colors.Hair)
			atlas.set_shader_parameter("shorts_tint", colors.Shorts)
			atlas.set_shader_parameter("shirt_tint", shirt)
			atlas.set_shader_parameter("beard_enabled", bool(profile.get("beard", false)))
			continue
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
			fabric.set_shader_parameter("shorts_details", region == "Shorts" and source.resource_name.get_slice(".", 0) != "TailoredShorts")
			fabric.set_shader_parameter("atlas_shorts_enabled", source.resource_name.get_slice(".", 0) == "TailoredShorts")
			fabric.set_shader_parameter("albedo_map", source.albedo_texture)
			fabric.set_shader_parameter("normal_map", source.normal_texture)
			fabric.set_shader_parameter("normal_depth", source.normal_scale)
			fabric.set_shader_parameter("roughness_map", source.roughness_texture)
			fabric.set_shader_parameter("surface_detail_enabled", true)
			fabric.set_shader_parameter("cloth_coverage_override", 1.0)
			fabric.set_shader_parameter("white_cloth_override", 1.0 if region in ["Jersey", "Socks"] else 0.0)
			fabric.set_shader_parameter("semantic_masks_enabled", false)
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

static func apply_meshy(mesh: MeshInstance3D) -> void:
	for i in range(mesh.mesh.get_surface_count()):
		var source := mesh.mesh.surface_get_material(i) as StandardMaterial3D
		if source == null: continue
		if source.resource_name.get_slice(".", 0) == "GoalkeeperGloves":
			var latex := mesh.get_surface_override_material(i) as ShaderMaterial
			if latex == null: latex = ShaderMaterial.new()
			latex.shader = LATEX
			latex.set_shader_parameter("glove_tint", source.albedo_color)
			mesh.set_surface_override_material(i, latex)
			continue
		if source.resource_name.get_slice(".", 0) != "MeshyPlayer": continue
		var fabric := mesh.get_surface_override_material(i) as ShaderMaterial
		if fabric == null: fabric = ShaderMaterial.new()
		fabric.shader = FABRIC
		fabric.set_shader_parameter("tint", Color.WHITE)
		fabric.set_shader_parameter("shorts_details", false)
		fabric.set_shader_parameter("albedo_map", source.albedo_texture)
		fabric.set_shader_parameter("normal_map", source.normal_texture)
		fabric.set_shader_parameter("normal_depth", minf(source.normal_scale, 0.45))
		fabric.set_shader_parameter("roughness_floor", 0.65)
		fabric.set_shader_parameter("specular_strength", 0.2)
		fabric.set_shader_parameter("roughness_map", source.roughness_texture)
		fabric.set_shader_parameter("surface_detail_enabled", true)
		fabric.set_shader_parameter("semantic_masks_enabled", true)
		fabric.set_shader_parameter("appearance_mask", APPEARANCE_MASK)
		fabric.set_shader_parameter("cloth_mask", CLOTH_MASK)
		fabric.set_shader_parameter("facial_mask", FACIAL_MASK)
		fabric.set_shader_parameter("skin_microdetail", SKIN_DETAIL)
		mesh.set_surface_override_material(i, fabric)

static func apply_lettering(avatar: Node3D, mesh: MeshInstance3D, player_name: String, number: int, ink: Color = Color("f0eee5")) -> void:
	var existing := avatar.get_node_or_null("JerseyPrint") as SubViewport
	if existing:
		(existing.get_node("Name") as Label).text = player_name.to_upper()
		(existing.get_node("Name") as Label).add_theme_font_size_override("font_size", mini(48, roundi(330.0 / maxf(float(player_name.length()) * 0.62, 1.0))))
		(existing.get_node("Number") as Label).text = str(number)
		for label in [existing.get_node("Name"), existing.get_node("Number")]:
			label.add_theme_color_override("font_color", ink)
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
		label.add_theme_color_override("font_color", ink)
		print_view.add_child(label)
	for i in range(mesh.mesh.get_surface_count()):
		var source := mesh.mesh.surface_get_material(i)
		if source.resource_name.get_slice(".", 0) not in ["Jersey", "MeshyPlayer"]: continue
		var fabric := mesh.get_surface_override_material(i) as ShaderMaterial
		if fabric:
			fabric.set_shader_parameter("lettering_map", print_view.get_texture())
			fabric.set_shader_parameter("lettering_enabled", true)
