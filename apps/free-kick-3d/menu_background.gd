extends Node3D
var keeper_preview: Node3D
var player: Node3D

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("203d5c")
	sky_material.sky_horizon_color = Color("a6bac8")
	sky.sky_material = sky_material
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("c5d2d8")
	settings.ambient_light_energy = 0.51
	environment.environment = settings
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40,-35,0)
	sun.light_color = Color("fff0d9")
	sun.light_energy = 0.96
	sun.shadow_enabled = true
	add_child(sun)
	var stadium := preload("res://stadium.gd").new()
	stadium.show_board_labels = false
	add_child(stadium)
	stadium.goal(-1)
	var turf := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(76,115)
	turf.mesh = plane
	var grass := ShaderMaterial.new()
	grass.shader = preload("res://shaders/turf.gdshader")
	turf.material_override = grass
	add_child(turf)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("dce8e3")
	stadium.box(Vector3(0,0.012,-52.5),Vector3(68,0.015,0.12),paint)
	stadium.box(Vector3(0,0.012,-36),Vector3(40.32,0.015,0.12),paint)
	for side in [-1,1]:
		stadium.box(Vector3(side*20.16,0.012,-44.25),Vector3(0.12,0.015,16.5),paint)
	player = preload("res://kicker.gd").new()
	add_child(player)
	refresh_player()
	player.position = Vector3(1.4,0,-40)
	player.rotation.y = PI-0.3
	player.scale = Vector3.ONE*1.15
	var ball := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.44
	ball.mesh = mesh
	var leather := ShaderMaterial.new()
	leather.shader = preload("res://shaders/ball.gdshader")
	ball.material_override = leather
	ball.position = Vector3(2.1,0.22,-39.6)
	add_child(ball)
	var camera := Camera3D.new()
	camera.position = Vector3(0,2.2,-34.5)
	camera.fov = 48
	add_child(camera)
	camera.look_at(Vector3(-0.1,1.0,-40))
	camera.current = true

func refresh_player(config_override: ConfigFile = null) -> void:
	player.show()
	if is_instance_valid(keeper_preview): keeper_preview.hide()
	var config := ConfigFile.new()
	if config_override != null:
		config = config_override
	else:
		config.load("user://free_kick_3d.cfg")
	player.apply_identity(int(config.get_value("appearance","striker",0)),str(config.get_value("appearance","name","Jugador")),int(config.get_value("appearance","number",10)),preload("res://footballer_model.gd").custom_profile(config))

func show_keeper(config: ConfigFile) -> void:
	player.hide()
	if not is_instance_valid(keeper_preview):
		keeper_preview = preload("res://keeper.gd").new()
		keeper_preview.configure(1,Color.GREEN)
		add_child(keeper_preview)
	keeper_preview.build_body(preload("res://footballer_model.gd").keeper_profile(config),str(config.get_value("appearance","keeper_name",config.get_value("appearance","name","Jugador"))),int(config.get_value("appearance","keeper_number",config.get_value("appearance","number",10))))
	keeper_preview.position = Vector3(1.4,1.035,-40)
	keeper_preview.rotation.y = PI-0.3
	keeper_preview.show()
