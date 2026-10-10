extends SceneTree
var failures := 0
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/athlete-v3-test.cfg"
	root.add_child(game)
	var avatar: Node3D = game.kicker.footballer_visual
	var body: MeshInstance3D = avatar.get_node("FootballerRig/Skeleton3D/FootballerBody")
	var rig: Skeleton3D = avatar.get_node("FootballerRig/Skeleton3D")
	check(rig.get_bone_count() > 18 and rig.find_bone("index_01_l") >= 0, "La base debe conservar el rig anatómico y dedos")
	var jersey_index := -1
	for i in body.mesh.get_surface_count():
		var source := body.mesh.surface_get_material(i) as StandardMaterial3D
		if source.resource_name == "MeshyPlayer":
			check(source.albedo_texture != null and source.normal_texture != null, "El cuerpo debe conservar detalle de textura")
			check(source.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Piel y ojos deben ser opacos para evitar superficies internas visibles")
		if source.resource_name == "Jersey": jersey_index = i
	check(avatar.get_node_or_null("FootballerRig/Skeleton3D/Beard") == null, "El rostro usa el atlas de la base Meshy completa")
	check(jersey_index >= 0, "El uniforme debe tener una región personalizable")
	var fabric := body.get_surface_override_material(jersey_index) as ShaderMaterial
	var texture: Texture2D = fabric.get_shader_parameter("albedo_map")
	var uvs: PackedVector2Array = body.mesh.surface_get_arrays(jersey_index)[Mesh.ARRAY_TEX_UV2]
	var has_print := false
	var has_blank := false
	for uv in uvs:
		if uv.x >= 0 and uv.x <= 1 and uv.y >= 0 and uv.y <= 1: has_print = true
		if uv.x < 0: has_blank = true
	check(has_print and has_blank, "Las UV del dorsal deben reservar espalda y excluir frente/mangas")
	var print_id := avatar.get_node("JerseyPrint").get_instance_id()
	var profile: Dictionary = load("res://footballer_model.gd").PROFILES[0].duplicate()
	profile.shirt = "7a2244"
	game.kicker.apply_identity(3, "ÁLVAREZ", 27, profile)
	check(game.kicker.footballer_visual == avatar, "Cambiar identidad debe reutilizar malla/rig")
	check(avatar.get_node("JerseyPrint").get_instance_id() == print_id, "El dorsal no debe recrear el viewport cada turno")
	check(fabric.get_shader_parameter("albedo_map") == texture, "Recolorear no debe perder los mapas")
	check(fabric.get_shader_parameter("tint") == Color("7a2244"), "El color nuevo debe aplicarse")
	check(avatar.get_node("JerseyPrint/Name").text == "ÁLVAREZ" and avatar.get_node("JerseyPrint/Number").text == "27", "Nombre y dorsal deben actualizarse")
	var other: MeshInstance3D = game.home_keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	for i in other.mesh.get_surface_count():
		if other.mesh.surface_get_material(i).resource_name == "Jersey":
			check(other.get_surface_override_material(i) != fabric, "Arquero y delantero deben mantener materiales independientes")
	print("PASS: anatomía, texturas, dorsal UV y personalización independiente" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
