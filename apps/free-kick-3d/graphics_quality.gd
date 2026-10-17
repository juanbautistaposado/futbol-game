extends RefCounted

## Three predictable PC presets. Keep gameplay geometry and hitboxes identical.
const PROFILES := ["bajo", "medio", "alto"]

static func normalized(value: String) -> String:
	return value if value in PROFILES else "alto"

static func apply(scene: Node, value: String) -> void:
	var quality := normalized(value)
	var viewport := scene.get_viewport()
	viewport.msaa_3d = Viewport.MSAA_DISABLED if quality == "bajo" else Viewport.MSAA_2X if quality == "medio" else Viewport.MSAA_4X
	_set_shadows(scene, quality != "bajo")
	_set_grass_quality(scene, quality)
	_set_environment_quality(scene, quality)

static func _set_environment_quality(node: Node, quality: String) -> void:
	if node is WorldEnvironment and node.environment != null:
		var environment: Environment = node.environment
		# Contact shading adds depth to boots, folds and stadium structures.
		# Both effects are available in the project's Godot 4.7 Compatibility path.
		environment.ssao_enabled = quality == "alto"
		environment.ssao_radius = 0.65
		environment.ssao_intensity = 0.85
		environment.ssao_power = 1.15
		environment.ssao_detail = 0.35
		environment.ssao_light_affect = 0.0
		environment.glow_enabled = quality == "alto"
		environment.glow_intensity = 0.18
		environment.glow_bloom = 0.0
		environment.glow_hdr_threshold = 1.05
	for child in node.get_children():
		_set_environment_quality(child, quality)

static func _set_grass_quality(node: Node, quality: String) -> void:
	if node.name == "PitchGrass" and node.has_method("set_quality"):
		node.set_quality(quality)
	for child in node.get_children():
		_set_grass_quality(child, quality)

static func _set_shadows(node: Node, enabled: bool) -> void:
	if node is DirectionalLight3D:
		node.shadow_enabled = enabled
	for child in node.get_children():
		_set_shadows(child, enabled)
