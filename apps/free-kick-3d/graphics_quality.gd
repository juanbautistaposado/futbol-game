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

static func _set_shadows(node: Node, enabled: bool) -> void:
	if node is DirectionalLight3D:
		node.shadow_enabled = enabled
	for child in node.get_children():
		_set_shadows(child, enabled)
