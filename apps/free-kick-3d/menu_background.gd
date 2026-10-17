extends Node3D
const MENU_BALL_RADIUS := 0.13
const STUDIO_GRAY := Color("343b43")
var keeper_preview: Node3D
var player: Node3D
var preview_camera: Camera3D
var stadium_stage: Node3D
var editor_stage: Node3D
var world_environment: WorldEnvironment
var stadium_environment: Environment
var studio_environment: Environment
var editor_enabled := false
var editor_mode := "body"
var editor_yaw := PI
var editor_viewport_size := Vector2(1280, 720)
var editor_content_scale := 1.125
var camera_motion: Tween

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
	environment.environment = settings
	add_child(environment)
	world_environment = environment
	var sun := DirectionalLight3D.new()
	preload("res://pitch_lighting.gd").apply_environment(settings, sun)
	stadium_environment = settings
	studio_environment = settings.duplicate()
	studio_environment.background_mode = Environment.BG_COLOR
	studio_environment.background_color = STUDIO_GRAY
	# Stadium aerial perspective otherwise paints a pale band above the floor.
	studio_environment.fog_enabled = false
	studio_environment.fog_aerial_perspective = 0.0
	add_child(sun)
	stadium_stage = Node3D.new()
	add_child(stadium_stage)
	var stadium := preload("res://stadium.gd").new()
	stadium.show_board_labels = false
	stadium_stage.add_child(stadium)
	stadium.goal(-1)
	var turf := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(76,115)
	turf.mesh = plane
	var grass := ShaderMaterial.new()
	grass.shader = preload("res://shaders/turf.gdshader")
	turf.material_override = grass
	stadium_stage.add_child(turf)
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
	ball.name = "MenuBall"
	var mesh := SphereMesh.new()
	mesh.radius = MENU_BALL_RADIUS
	mesh.height = MENU_BALL_RADIUS * 2.0
	ball.mesh = mesh
	var leather := ShaderMaterial.new()
	leather.shader = preload("res://shaders/ball.gdshader")
	ball.material_override = leather
	ball.position = Vector3(2.1,MENU_BALL_RADIUS,-39.6)
	stadium_stage.add_child(ball)
	preview_camera = Camera3D.new()
	var camera := preview_camera
	camera.position = Vector3(0,2.2,-34.5)
	camera.fov = 48
	add_child(camera)
	camera.look_at(Vector3(-0.1,1.0,-40))
	camera.current = true
	build_editor_stage()

func refresh_player(config_override: ConfigFile = null) -> void:
	player.show()
	if is_instance_valid(keeper_preview): keeper_preview.hide()
	var config := ConfigFile.new()
	if config_override != null:
		config = config_override
	else:
		config.load("user://free_kick_3d.cfg")
	player.apply_identity(int(config.get_value("appearance","striker",0)),str(config.get_value("appearance","name","Jugador")),int(config.get_value("appearance","number",10)),preload("res://footballer_model.gd").custom_profile(config))
	if editor_enabled:
		pose_editor_player()

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
	if editor_enabled:
		pose_editor_player()

func frame_home_poster(enabled: bool) -> void:
	preview_camera.fov = 40 if enabled else 48
	preview_camera.look_at(Vector3(0.2 if enabled else -0.1, 1.0, -40))

func rotate_home(amount: float) -> void:
	if editor_enabled or not is_instance_valid(player):
		return
	player.rotation.y = wrapf(player.rotation.y + amount, 0.0, TAU)

func build_editor_stage() -> void:
	editor_stage = Node3D.new()
	editor_stage.name = "CharacterStudio"
	add_child(editor_stage)
	# A single backdrop avoids a floor/sky horizon at every preview zoom.
	var rim := OmniLight3D.new()
	rim.position = Vector3(2.8, 2.7, -42.4)
	rim.light_color = Color("c5d9ea")
	rim.light_energy = 1.4
	rim.omni_range = 6.0
	editor_stage.add_child(rim)
	editor_stage.hide()

func set_editor_preview(enabled: bool) -> void:
	if camera_motion:
		camera_motion.kill()
	editor_enabled = enabled
	stadium_stage.visible = not enabled
	editor_stage.visible = enabled
	world_environment.environment = studio_environment if enabled else stadium_environment
	editor_yaw = PI
	if enabled:
		editor_mode = "body"
		pose_editor_player()
		frame_editor("body", false)
	else:
		preview_camera.h_offset = 0.0
		preview_camera.position = Vector3(0, 2.2, -34.5)
		player.rotation.y = PI - 0.3
		if is_instance_valid(keeper_preview):
			keeper_preview.rotation.y = PI - 0.3
		frame_home_poster(false)

func pose_editor_player() -> void:
	var actor: Node3D = keeper_preview if is_instance_valid(keeper_preview) and keeper_preview.visible else player
	actor.rotation.y = editor_yaw
	var animation: AnimationPlayer = actor.goalkeeper_animation if actor == keeper_preview else actor.footballer_animation
	if animation.has_animation("Idle"):
		animation.play("Idle")
		animation.advance(0.0)
		animation.pause()

func layout_editor(viewport_size: Vector2, content_scale: float) -> void:
	editor_viewport_size = viewport_size
	editor_content_scale = content_scale
	if editor_enabled:
		frame_editor(editor_mode, false)

func frame_editor(mode: String, animated := true) -> void:
	editor_mode = mode
	if not editor_enabled:
		return
	if camera_motion:
		camera_motion.kill()
	var face := mode == "face"
	var target := Vector3(1.4, 2.05 if face else 1.30, -40)
	var distance := 2.0 if face else 6.3
	var fov := 28.0 if face else 32.0
	var camera_position := target + Vector3(0, 0, distance)
	# Put the preview at x=748 of the centered 1024-wide UI, at any aspect.
	var world_per_pixel := 2.0 * distance * tan(deg_to_rad(fov * 0.5)) / editor_viewport_size.y
	var horizontal_offset := -(748.0 - 512.0) * editor_content_scale * world_per_pixel
	if animated:
		camera_motion = create_tween().set_parallel(true)
		camera_motion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		camera_motion.tween_property(preview_camera, "position", camera_position, 0.25)
		camera_motion.tween_property(preview_camera, "rotation", Vector3.ZERO, 0.25)
		camera_motion.tween_property(preview_camera, "fov", fov, 0.25)
		camera_motion.tween_property(preview_camera, "h_offset", horizontal_offset, 0.25)
	else:
		preview_camera.position = camera_position
		preview_camera.look_at(target)
		preview_camera.fov = fov
		preview_camera.h_offset = horizontal_offset

func rotate_editor(amount: float) -> void:
	if not editor_enabled:
		return
	editor_yaw = wrapf(editor_yaw + amount, 0.0, TAU)
	pose_editor_player()
