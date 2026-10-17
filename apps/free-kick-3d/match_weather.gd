extends Node3D
## One independent weather draw per match; gameplay randomness stays separate.
const TYPES := ["soleado", "nublado", "lluvia"]
var current := "soleado"
var environment: Environment
var sun: DirectionalLight3D
var camera: Camera3D
var rain: CPUParticles3D

static func select_for_roll(roll: float) -> String:
	assert(roll >= 0.0 and roll <= 1.0)
	if roll < 0.60: return "soleado"
	if roll < 0.90: return "nublado"
	return "lluvia"

func configure(settings: Environment, sunlight: DirectionalLight3D, view: Camera3D) -> void:
	environment = settings
	sun = sunlight
	camera = view
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	set_weather(select_for_roll(rng.randf()))

func set_weather(value: String) -> void:
	assert(value in TYPES)
	current = value
	preload("res://pitch_lighting.gd").apply_environment(environment, sun)
	if current != "soleado":
		var storm := current == "lluvia"
		var sky: ShaderMaterial = environment.sky.sky_material
		sky.set_shader_parameter("zenith_color", Color("65717e") if storm else Color("9aa8b5"))
		sky.set_shader_parameter("horizon_color", Color("a0abb4") if storm else Color("c3cbd0"))
		sky.set_shader_parameter("cloud_color", Color("aab5c0") if storm else Color("dbe0e4"))
		environment.ambient_light_energy = 0.78 if storm else 0.85
		environment.ambient_light_color = Color("bdc9d7") if storm else Color("d4dbe1")
		environment.fog_light_color = Color("9baab8") if storm else Color("bdc9d1")
		environment.fog_density = 0.0028 if storm else 0.0018
		environment.fog_light_energy = 0.62
		sun.light_color = Color("ced9e3")
		sun.light_energy = 0.30 if storm else 0.48
		sun.shadow_opacity = 0.18 if storm else 0.30
	if current == "lluvia" and not is_instance_valid(rain):
		build_rain()
	if is_instance_valid(rain):
		rain.emitting = current == "lluvia"
		rain.visible = current == "lluvia"
	set_process(current == "lluvia")
	if current == "lluvia": _process(0.0)

func build_rain() -> void:
	rain = CPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 900
	rain.lifetime = 1.4
	rain.preprocess = 1.4
	rain.local_coords = true
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(10, 4, 10)
	rain.direction = Vector3(-0.10, -1.0, 0.04)
	rain.spread = 2.0
	rain.gravity = Vector3(0, -3, 0)
	rain.initial_velocity_min = 16.0
	rain.initial_velocity_max = 20.0
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var drop := QuadMesh.new()
	drop.size = Vector2(0.008, 0.20)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.78, 0.85, 0.92, 0.40)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.18, 0.70, 1.0])
	gradient.colors = PackedColorArray([Color(1,1,1,0), Color.WHITE, Color.WHITE, Color(1,1,1,0)])
	var streak := GradientTexture2D.new()
	streak.gradient = gradient
	streak.width = 4
	streak.height = 32
	streak.fill_from = Vector2(0.5, 0.0)
	streak.fill_to = Vector2(0.5, 1.0)
	material.albedo_texture = streak
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	drop.material = material
	rain.mesh = drop
	add_child(rain)

func _process(_delta: float) -> void:
	if is_instance_valid(camera) and is_instance_valid(rain):
		# Keep a fixed small rain volume ahead of both the shooting and keeper cameras.
		rain.global_position = camera.global_position - camera.global_basis.z * 8.0 + Vector3.UP * 7.0
