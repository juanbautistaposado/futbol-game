extends RefCounted
## Materials for the original Blender footballer GLBs. Each avatar gets its own
## material instances, leaving independent custom striker/keeper colors intact.
const FABRIC = preload("res://shaders/footballer_fabric.gdshader")

static func apply_profile(mesh: MeshInstance3D, profile: Dictionary) -> void:
	var shirt := Color(str(profile.shirt))
	var skin := Color(str(profile.skin))
	var colors := {"Jersey":shirt,"JerseyAccent":shirt.lerp(Color.WHITE,0.32),"Shorts":Color(str(profile.shorts)),"Skin":skin,"SkinShade":skin.darkened(0.22),"Hair":Color(str(profile.hair)),"Socks":shirt}
	for i in range(mesh.mesh.get_surface_count()):
		var source := mesh.mesh.surface_get_material(i)
		if source == null or not colors.has(source.resource_name): continue
		if source.resource_name in ["Jersey","JerseyAccent","Shorts","Socks"]:
			var fabric := ShaderMaterial.new()
			fabric.shader = FABRIC
			fabric.set_shader_parameter("tint",colors[source.resource_name])
			mesh.set_surface_override_material(i,fabric)
		elif source is StandardMaterial3D:
			var personalized: StandardMaterial3D = source.duplicate()
			personalized.albedo_color = colors[source.resource_name]
			mesh.set_surface_override_material(i,personalized)
