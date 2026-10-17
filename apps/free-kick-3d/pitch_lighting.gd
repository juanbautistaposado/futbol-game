extends RefCounted
## Shared broadcast daylight for the match and menu stadium.
const STADIUM_SKY := preload("res://shaders/stadium_daylight.gdshader")

static func apply_environment(environment: Environment, sun: DirectionalLight3D) -> void:
	var sky := environment.sky if environment.sky != null else Sky.new()
	var material := ShaderMaterial.new()
	material.shader = STADIUM_SKY
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	# IBL gives upward-facing fabric and skin cooler light than the shaded underside.
	# The constant contribution keeps the ball and player readable under the roof.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color("cfdae1")
	environment.ambient_light_sky_contribution = 0.55
	environment.ambient_light_energy = 0.72
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Filmic is supported by Godot's GLES3 shader path as well as Forward+.
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	# A little aerial haze separates distant stands without obscuring the goal mouth.
	environment.fog_enabled = true
	environment.fog_light_color = Color("b6cad9")
	environment.fog_light_energy = 0.72
	environment.fog_density = 0.0012
	environment.fog_sky_affect = 0.0
	environment.fog_aerial_perspective = 0.35
	environment.fog_sun_scatter = 0.08
	sun.rotation_degrees = Vector3(-40.0, -35.0, 0.0)
	sun.light_color = Color("fff2de")
	sun.light_energy = 1.03
	sun.directional_shadow_max_distance = 100.0
	sun.directional_shadow_split_1 = 0.16
	sun.directional_shadow_split_2 = 0.34
	sun.directional_shadow_split_3 = 0.64
	sun.directional_shadow_fade_start = 0.85
	sun.shadow_enabled = true
	# Preserve natural fill rather than adding another shadow-casting light.
	sun.shadow_opacity = 0.90
