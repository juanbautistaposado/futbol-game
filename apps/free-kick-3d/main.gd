extends Node3D

var shot_limit := 5
var player_count := 1
var active_player := 0
var local_scores: Array[int] = []
@export var save_path := "user://free_kick_3d.cfg"
const GOAL_Z := 52.5
const GOAL_WIDTH := 8.4
const GOAL_HEIGHT := 2.9
const BALL_RADIUS := 0.22
const AI_SHOT_FLIGHT_TIME := 1.22
const ShotMeter = preload("res://shot_meter.gd")
const Keeper = preload("res://keeper.gd")
const GraphicsQuality = preload("res://graphics_quality.gd")
const ShotTactics = preload("res://shot_tactics.gd")


enum Phase { ATTACK, DEFEND, RESOLVING, FINISHED, KICKING }

var phase: Phase = Phase.ATTACK
var turn := 1
var player_goals := 0
var rival_goals := 0
var sudden_death := false
var best_score := 0
var difficulty := "medio"
var player_name := "Jugador"

var kicker: Node3D
var hit_woodwork := false
var previous_ball_position := Vector3.ZERO
var keeper_rng := RandomNumberGenerator.new()
var ai_shot_target := Vector3.ZERO
var ai_shot_crossed := false
var last_ai_shot_crossed := false
var defense_windup := false
var defense_dive_time := -1.0
var last_shot_target := Vector3.ZERO
var last_aim_target := Vector3.ZERO

var ball_effect: Tween
var holding_keeper: Keeper
var last_flight_velocity := Vector3.ZERO

var ball: RigidBody3D
var away_keeper: Keeper
var home_keeper: Keeper
var camera: Camera3D
var weather: Node3D
var status_label: Label
var score_label: Label
var score_detail: Label
var hint_label: Label
var aim_label: Label
var aim_marker: MeshInstance3D
var match_overlay: CanvasLayer
var match_audio: Node
var defense_target: Control
var defense_aim := Vector2(0.0, 1.45)
var touch_aiming := false
var shot_meter: ShotMeter
var last_accuracy := 1.0

var ball_in_flight := false
var shot_time := 0.0
var shot_goal := 0
var resolved := false
var defense_countdown := 0.0
var keeper_height := 0
var spin := 0.0
var keeper_lane := 0
var keeper_dived := false
var aim_x := 0.0
var aim_y := 0.0
var shot_power := 0.0
var is_charging := false

func _ready() -> void:
	load_best_score()
	keeper_rng.randomize()
	local_scores.resize(player_count)
	local_scores.fill(0)
	create_world()
	create_pitch()
	create_goal(-1)
	create_goal(1)
	away_keeper = create_keeper(-1, Color("f59e0b"))
	home_keeper = create_keeper(1, Color("22c55e"))
	apply_player_appearance()
	ball = create_ball()
	kicker = preload("res://kicker.gd").new()
	add_child(kicker)
	kicker.scale = Vector3.ONE * 1.15
	aim_marker = create_aim_marker()
	create_interface()
	match_audio = preload("res://match_audio.gd").new()
	add_child(match_audio)
	var settings_profile := ConfigFile.new()
	settings_profile.load(save_path)
	preload("res://match_audio.gd").set_global_volume(float(settings_profile.get_value("settings", "sound_volume", 0.8)))
	start_attack()
	GraphicsQuality.apply(self, str(settings_profile.get_value("settings", "graphics_quality", "alto")))

func _process(delta: float) -> void:
	if is_instance_valid(holding_keeper):
		ball.global_position = holding_keeper.held_ball_position(shot_goal)
	if phase == Phase.ATTACK and is_charging:
		shot_meter.advance(delta)
		shot_power = shot_meter.power
		refresh_aim_marker()
	if ball_in_flight:
		shot_time += delta
		if shot_time > 4.0 or abs(ball.position.z) > GOAL_Z + 7.0 or ball.position.y < -1.0:
			resolve_shot(false, "¡Palo y afuera!" if hit_woodwork else "¡Afuera!")
	if phase == Phase.DEFEND and not ball_in_flight:
		defense_countdown -= delta
		if defense_countdown <= 0.35:
			kicker.prepare_shot(ai_shot_target, ai_shot_crossed)
		if defense_countdown <= 0.0:
			fire_ai_shot()
	update_aim_label()
	if defense_active() and defense_target.visible:
		refresh_defense_target()

func _unhandled_input(event: InputEvent) -> void:
	if phase == Phase.RESOLVING or (phase == Phase.KICKING and not defense_windup):
		return
	if phase == Phase.FINISHED:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			get_tree().change_scene_to_file("res://Menu.tscn")
		return

	if event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if phase == Phase.ATTACK and not ball_in_flight:
			set_attack_target_from_screen(event.position)
		elif defense_active() and not keeper_dived:
			preview_defense_target(event.position)
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if phase == Phase.ATTACK and not ball_in_flight:
			if event.pressed:
				set_attack_target_from_screen(event.position)
				shot_power = 0.0
				is_charging = true
				shot_meter.begin()
			elif is_charging:
				is_charging = false
				fire_player_shot()
		elif defense_active() and event.pressed:
			dive_home_keeper_from_screen(event.position)
		return

	if event is InputEventScreenTouch:
		if phase == Phase.ATTACK and not ball_in_flight:
			if event.pressed:
				set_attack_target_from_screen(event.position)
				shot_power = 0.0
				is_charging = true
				shot_meter.begin()
			elif is_charging:
				is_charging = false
				fire_player_shot()
		elif defense_active():
			if event.pressed and not keeper_dived:
				touch_aiming = true
				preview_defense_target(event.position)
			elif not event.pressed and touch_aiming:
				touch_aiming = false
				dive_home_keeper_from_screen(event.position)
		return

	if event is InputEventScreenDrag:
		if phase == Phase.ATTACK and is_charging:
			set_attack_target_from_screen(event.position)
		elif defense_active() and touch_aiming and not keeper_dived:
			preview_defense_target(event.position)
		return

	if event is InputEventKey and not event.echo and phase == Phase.ATTACK and not ball_in_flight:
		if event.keycode == KEY_SPACE:
			if event.pressed and not is_charging:
				is_charging = true
				shot_meter.begin()
			elif not event.pressed and is_charging:
				fire_player_shot()
		return

	if event is InputEventKey and event.pressed and not event.echo and defense_active():
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			keeper_height = 1
			defense_aim.y = 2.65
		elif event.keycode == KEY_S:
			keeper_height = -1
			defense_aim.y = 0.3
		if event.keycode == KEY_W or event.keycode == KEY_UP or event.keycode == KEY_S:
			defense_target.set_target(defense_screen_from_target(defense_aim))
		if event.keycode == KEY_LEFT:
			dive_home_keeper(-1)
		elif event.keycode == KEY_RIGHT:
			dive_home_keeper(1)
		elif event.keycode == KEY_SPACE or event.keycode == KEY_DOWN:
			dive_home_keeper(0)

func create_world() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("203d5c")
	sky_material.sky_horizon_color = Color("a6bac8")
	sky_material.ground_horizon_color = Color("98abae")
	sky_material.ground_bottom_color = Color("33444a")
	sky.sky_material = sky_material
	settings.sky = sky
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	preload("res://pitch_lighting.gd").apply_environment(settings, sun)
	add_child(sun)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 55.0
	add_child(camera)

	weather = preload("res://match_weather.gd").new()
	weather.name = "MatchWeather"
	add_child(weather)
	weather.configure(settings, sun, camera)

func create_pitch() -> void:
	var pitch := create_static_box("pitch", Vector3(0, -0.15, 0), Vector3(76, 0.3, 115), Color.WHITE)
	var grass := ShaderMaterial.new()
	grass.shader = preload("res://shaders/turf.gdshader")
	pitch.get_child(0).material_override = grass
	var stadium := preload("res://stadium.gd").new()
	stadium.name = "Stadium"
	add_child(stadium)
	var paint := Color("e3e5cf")
	# Full 105 × 68 m pitch.
	for x in [-34.0,34.0]:
		create_static_box("touchline",Vector3(x,0.012,0),Vector3(0.12,0.015,105),paint,false)
	for z in [-52.5,0.0,52.5]:
		create_static_box("line",Vector3(0,0.012,z),Vector3(68,0.015,0.12),paint,false)
	for side in [-1,1]:
		for width_depth in [Vector2(40.32,16.5),Vector2(18.32,5.5)]:
			create_static_box("area_line",Vector3(0,0.012,side*(GOAL_Z-width_depth.y)),Vector3(width_depth.x,0.015,0.075),paint,false)
			for edge in [-1,1]:
				create_static_box("area_edge",Vector3(edge*width_depth.x/2,0.012,side*(GOAL_Z-width_depth.y/2)),Vector3(0.075,0.015,width_depth.y),paint,false)
		create_static_box("penalty_spot",Vector3(0,0.013,side*(GOAL_Z-11)),Vector3(0.17,0.015,0.17),paint,false)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 9.09
	torus.outer_radius = 9.21
	torus.rings = 96
	torus.ring_segments = 8
	ring.mesh = torus
	ring.position.y = 0.014
	ring.scale.y = 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = paint
	ring.material_override = mat
	add_child(ring)

func create_goal(side: int) -> void:
	var goal_z := GOAL_Z * side
	for x in [-GOAL_WIDTH / 2.0, GOAL_WIDTH / 2.0]:
		create_goal_post(Vector3(x,GOAL_HEIGHT/2.0,goal_z),GOAL_HEIGHT,false)
	create_goal_post(Vector3(0,GOAL_HEIGHT,goal_z),GOAL_WIDTH,true)
	get_node("Stadium").goal(side)

func create_goal_post(location: Vector3, length: float, horizontal: bool) -> void:
	var body := StaticBody3D.new()
	body.position = location
	body.add_to_group("woodwork")
	var material := PhysicsMaterial.new()
	material.bounce = 0.8
	material.friction = 0.15
	body.physics_material_override = material
	var collision := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.08
	cylinder.height = length
	collision.shape = cylinder
	if horizontal: collision.rotation.z = PI / 2.0
	body.add_child(collision)
	add_child(body)

func _physics_process(_delta: float) -> void:
	if not ball_in_flight:
		return
	# Count only once the complete ball crosses the line inside the frame.
	var plane_z := shot_goal * (GOAL_Z + BALL_RADIUS)
	if (previous_ball_position.z - plane_z) * shot_goal < 0 and (ball.position.z - plane_z) * shot_goal >= 0:
		var fraction := (plane_z - previous_ball_position.z) / (ball.position.z - previous_ball_position.z)
		var crossing := previous_ball_position.lerp(ball.position, fraction)
		if absf(crossing.x) < GOAL_WIDTH/2.0 - 0.08 and crossing.y < GOAL_HEIGHT - 0.08 and crossing.y >= BALL_RADIUS - 0.04:
			resolve_shot(true, "¡Palo y gol!" if hit_woodwork else "¡Gol!")
		else:
			resolve_shot(false, "¡Palo y afuera!" if hit_woodwork else "¡Afuera!")
	previous_ball_position = ball.position
	last_flight_velocity = ball.linear_velocity

func create_static_box(node_name: String, location: Vector3, dimensions: Vector3, color: Color, collide := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = location
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.08
	material.roughness = 0.65
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collide:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		body.add_child(collision)
	add_child(body)
	return body

func create_keeper(side: int, shirt_color: Color) -> Keeper:
	var keeper := Keeper.new()
	keeper.configure(side, shirt_color)
	add_child(keeper)
	return keeper

func create_ball() -> RigidBody3D:
	var new_ball := RigidBody3D.new()
	new_ball.name = "ball"
	new_ball.mass = 0.43
	new_ball.gravity_scale = 0.55
	new_ball.continuous_cd = true
	new_ball.linear_damp = 0.0
	new_ball.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	new_ball.contact_monitor = true
	new_ball.max_contacts_reported = 8
	new_ball.body_entered.connect(_on_ball_contact)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = BALL_RADIUS
	collision.shape = shape
	new_ball.add_child(collision)
	var visible := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = BALL_RADIUS
	mesh.height = BALL_RADIUS * 2.0
	visible.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/ball.gdshader")
	visible.material_override = material
	new_ball.add_child(visible)
	add_child(new_ball)
	return new_ball

func create_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var visual = preload("res://ui/visual_theme.gd")
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = visual.create()
	canvas.add_child(ui)
	var panel := preload("res://ui/poster_panel.gd").new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(24, 24)
	ui.add_child(panel)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 4)
	panel.add_child(stack)
	score_label = preload("res://ui/scoreboard.gd").new()
	score_label.custom_minimum_size.y = 34
	score_label.add_theme_font_override("font", visual.EMPHASIS)
	score_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	score_detail = make_label(Vector2.ZERO, 16, visual.MUTED)
	status_label = make_label(Vector2.ZERO, 20, visual.INK)
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.add_theme_font_override("font", visual.DISPLAY)

	aim_label = make_label(Vector2.ZERO, 16, visual.MUTED)
	for item in [score_label]:
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		stack.add_child(item)
	var turn_plate := preload("res://ui/poster_panel.gd").new()
	turn_plate.fill = visual.BLUE
	turn_plate.position = Vector2(24, 84)
	turn_plate.size = Vector2(240, 42)
	ui.add_child(turn_plate)
	turn_plate.add_child(status_label)
	ui.add_child(score_detail)
	ui.add_child(aim_label)
	score_detail.hide()
	aim_label.hide()
	var layout_score := func() -> void:
		panel.size = Vector2(minf(660.0 if player_count > 1 else 500.0, ui.size.x - 232.0), 54)
	ui.resized.connect(layout_score)
	layout_score.call()
	hint_label = make_label(Vector2.ZERO, 18, visual.BASE)
	hint_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ui.add_child(hint_label)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 24
	hint_label.anchor_right = 0.0
	hint_label.offset_right = 680
	hint_label.offset_top = -64
	hint_label.offset_bottom = -24
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_override("font", visual.EMPHASIS)
	var help_style := StyleBoxTexture.new()
	help_style.texture = preload("res://ui/plates/help.svg")
	help_style.texture_margin_left = 0
	help_style.texture_margin_right = 0
	help_style.texture_margin_top = 0
	help_style.texture_margin_bottom = 0
	help_style.content_margin_left = 60
	help_style.content_margin_right = 22
	help_style.content_margin_top = 8
	help_style.content_margin_bottom = 8
	hint_label.add_theme_stylebox_override("normal", help_style)

	shot_meter = ShotMeter.new()
	canvas.add_child(shot_meter)
	shot_meter.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	shot_meter.offset_left = -480
	shot_meter.offset_right = -20
	shot_meter.offset_top = -124
	shot_meter.offset_bottom = -24
	defense_target = preload("res://defense_target.gd").new()
	canvas.add_child(defense_target)
	defense_target.hide()
	match_overlay = preload("res://match_overlay.gd").new()
	add_child(match_overlay)
	match_overlay.exit_requested.connect(func() -> void: get_tree().change_scene_to_file("res://Menu.tscn"))
	match_overlay.pause_changed.connect(func(paused: bool) -> void:
		if paused:
			touch_aiming = false
		if paused and is_charging:
			is_charging = false
			shot_power = 0.0
			shot_meter.reset()
	)


func make_label(location: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = location
	label.add_theme_font_override("font", preload("res://ui/visual_theme.gd").DISPLAY if font_size >= 26 else preload("res://ui/visual_theme.gd").BODY)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func start_attack() -> void:
	match_overlay.result_label.hide()
	phase = Phase.ATTACK
	defense_windup = false
	hint_label.offset_right = minf(620, get_viewport().get_visible_rect().size.x - 500)
	hint_label.offset_top = -64
	is_charging = false
	shot_power = 0.0
	shot_meter.reset()
	defense_target.hide()
	touch_aiming = false
	away_keeper.show()
	away_keeper.reset_pose()
	home_keeper.reset_pose()
	refresh_aim_marker()
	reset_ball(Vector3(0, BALL_RADIUS + 0.02, -GOAL_Z + shooting_distance()))
	var identity := ConfigFile.new()
	identity.load(save_path)
	kicker.apply_identity(int(identity.get_value("appearance","striker",0)),player_name,int(identity.get_value("appearance","number",10)),preload("res://footballer_model.gd").custom_profile(identity))
	kicker.reset_pose(ball.position, -1)
	look_from_kicker()
	status_label.text = ("TIRO · MS %s" % (turn - shot_limit) if sudden_death else "TIRO %s" % turn_label()) if player_count == 1 else "J%s · TIRO %s" % [active_player + 1, turn_label()]
	hint_label.text = "Variá tus tiros · Apuntá · Soltá en verde"
	update_score()

func start_defense() -> void:
	match_overlay.result_label.hide()
	phase = Phase.DEFEND
	defense_windup = false
	hint_label.offset_right = get_viewport().get_visible_rect().size.x - 24
	hint_label.offset_top = -80
	shot_meter.hide()
	away_keeper.hide()
	away_keeper.reset_pose()
	home_keeper.reset_pose()
	aim_marker.hide()
	keeper_lane = 0
	keeper_height = 0
	keeper_dived = false
	defense_dive_time = -1.0
	touch_aiming = false
	defense_aim = Vector2(0.0, 1.45)
	defense_countdown = 2.2
	reset_ball(Vector3(0, BALL_RADIUS + 0.02, GOAL_Z - shooting_distance()))
	var rival_index := randi_range(0,2)
	kicker.apply_identity(rival_index,preload("res://footballer_model.gd").PROFILES[rival_index].name,randi_range(7,11))
	kicker.reset_pose(ball.position, 1)
	# Lock the shot and any opposite-side feint before the player commits a dive.
	ai_shot_target = Vector3(randf_range(-2.9, 2.9), randf_range(0.55, 2.25), GOAL_Z + 0.3)
	ai_shot_crossed = ShotTactics.lane(ai_shot_target.x) != 0 and randf() < 0.30
	look_from_keeper()
	refresh_defense_target()
	status_label.text = "ATAJÁS · MS %s" % (turn - shot_limit) if sudden_death else "ATAJÁS %s" % turn_label()
	hint_label.text = "Observá la salida de la pelota · Clic para estirarte · ← / ESPACIO / →, W alta / S baja"
	update_score()

func fire_player_shot() -> void:
	if phase != Phase.ATTACK or ball_in_flight:
		return
	phase = Phase.KICKING
	ball.freeze = true
	last_accuracy = shot_meter.accuracy()
	shot_meter.lock_shot()
	var target := player_shot_target(last_accuracy)
	last_aim_target = Vector3(aim_x * 3.7, 1.5 + aim_y * 1.1, target.z)
	is_charging = false
	aim_marker.hide()
	kicker.kick(func() -> void:
		phase = Phase.ATTACK
		match_audio.play_effect("kick", ball.global_position)
		launch_ball(target, lerpf(1.65, 0.75, shot_power), -1)
		move_keeper_for_attack()
		status_label.text = "%s · precisión %d%%" % [shot_meter.feedback, roundi(last_accuracy * 100)]
	)

func launch_ball(target: Vector3, flight_time: float, side: int) -> void:
	ball.freeze = false
	ball_in_flight = true
	shot_goal = side
	last_shot_target = target
	shot_time = 0.0
	resolved = false
	hit_woodwork = false
	previous_ball_position = ball.position
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity",9.8)
	ball.linear_velocity = (target-ball.position)/flight_time + Vector3.UP*gravity*ball.gravity_scale*flight_time*0.5
	last_flight_velocity = ball.linear_velocity
	ball.angular_velocity = Vector3(-8,0,spin*16)

func create_aim_marker() -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.14
	mesh.height = 0.28
	marker.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("facc15")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	add_child(marker)
	return marker

func refresh_aim_marker() -> void:
	aim_marker.visible = phase == Phase.ATTACK and not ball_in_flight
	aim_marker.position = Vector3(aim_x * 3.7, 1.5 + aim_y * 1.1, -GOAL_Z + 0.2)
	aim_marker.scale = Vector3.ONE * (1.0 + shot_power * 0.6)

func set_attack_target_from_screen(screen_position: Vector2) -> void:
	var goal_plane := Plane(Vector3.FORWARD, GOAL_Z)
	var hit: Variant = goal_plane.intersects_ray(camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))
	if hit == null:
		return
	aim_x = clampf(hit.x / 3.7, -2.3, 2.3)
	aim_y = clampf((hit.y - 1.5) / 1.1, -1.15, 3.5)
	refresh_aim_marker()

func defense_goal_rect() -> Rect2:
	var top_left := camera.unproject_position(Vector3(-GOAL_WIDTH * 0.5, GOAL_HEIGHT, GOAL_Z))
	var bottom_right := camera.unproject_position(Vector3(GOAL_WIDTH * 0.5, 0.0, GOAL_Z))
	return Rect2(top_left, bottom_right - top_left).abs()

func defense_target_from_screen(screen_position: Vector2) -> Vector2:
	var left_post := camera.unproject_position(Vector3(-GOAL_WIDTH * 0.5, 0.0, GOAL_Z))
	var right_post := camera.unproject_position(Vector3(GOAL_WIDTH * 0.5, 0.0, GOAL_Z))
	var top := camera.unproject_position(Vector3(0.0, GOAL_HEIGHT, GOAL_Z))
	var bottom := camera.unproject_position(Vector3(0.0, 0.0, GOAL_Z))
	var horizontal := clampf((screen_position.x - left_post.x) / (right_post.x - left_post.x), 0.0, 1.0)
	var vertical := clampf((screen_position.y - top.y) / (bottom.y - top.y), 0.0, 1.0)
	return Vector2(lerpf(-4.0, 4.0, horizontal), lerpf(2.65, 0.3, vertical))

func defense_screen_from_target(target: Vector2) -> Vector2:
	var left_post := camera.unproject_position(Vector3(-GOAL_WIDTH * 0.5, 0.0, GOAL_Z))
	var right_post := camera.unproject_position(Vector3(GOAL_WIDTH * 0.5, 0.0, GOAL_Z))
	var top := camera.unproject_position(Vector3(0.0, GOAL_HEIGHT, GOAL_Z))
	var bottom := camera.unproject_position(Vector3(0.0, 0.0, GOAL_Z))
	return Vector2(lerpf(left_post.x, right_post.x, (target.x + 4.0) / 8.0), lerpf(top.y, bottom.y, (2.65 - target.y) / 2.35))

func refresh_defense_target() -> void:
	defense_target.show_target(defense_goal_rect(), defense_screen_from_target(defense_aim), keeper_dived)

func preview_defense_target(screen_position: Vector2) -> void:
	if not defense_active() or keeper_dived:
		return
	defense_aim = defense_target_from_screen(screen_position)
	defense_target.set_target(defense_screen_from_target(defense_aim))

func dive_home_keeper_from_screen(screen_position: Vector2) -> void:
	if not defense_active() or keeper_dived:
		return
	defense_aim = defense_target_from_screen(screen_position)
	keeper_lane = -1 if defense_aim.x < -1.25 else 1 if defense_aim.x > 1.25 else 0
	keeper_height = 1 if defense_aim.y > 1.78 else -1 if defense_aim.y < 0.92 else 0
	commit_home_keeper_dive(defense_aim.x * 0.78, lerpf(0.65, 1.6, clampf((defense_aim.y - 0.3) / 2.35, 0.0, 1.0)))

func player_shot_target(accuracy: float) -> Vector3:
	# Missing the timing pushes the shot further toward the aimed side, as in HTML.
	var direction := signf(aim_x) if absf(aim_x) > 0.05 else signf(shot_meter.indicator - 0.5)
	var error := (1.0 - accuracy) * 2.5
	return Vector3(aim_x * 3.7 + direction * error, 1.5 + aim_y * 1.1 + error * 0.18, -GOAL_Z - 0.3)

func keeper_wrong_way_chance() -> float:
	return 0.60 if difficulty == "facil" else 0.20 if difficulty == "dificil" else 0.40

func keeper_read(target: Vector3, roll: float) -> Vector3:
	var error := 0.18 if difficulty == "dificil" else 0.45
	var reach := 0.82 if difficulty == "facil" else 1.0 if difficulty == "dificil" else 0.91
	var read_x := target.x + keeper_rng.randf_range(-error,error)
	if roll < keeper_wrong_way_chance():
		read_x = -signf(target.x) * 3.1 if absf(target.x) > 0.2 else (3.1 if keeper_rng.randf() > 0.5 else -3.1)
		return Vector3(read_x,0.8,0)
	return Vector3(clampf(read_x*reach,-3.25,3.25),clampf(target.y*0.75,0.65,1.6),0)

func move_keeper_for_attack(decision_roll := -1.0) -> void:
	var target := last_shot_target
	var delay := 0.12 if difficulty == "dificil" else 0.24
	var roll := keeper_rng.randf() if decision_roll < 0.0 else decision_roll
	var read := keeper_read(target,roll)
	if roll < keeper_wrong_way_chance():
		# Commit to the wrong side before the ball arrives; the save still depends
		# on physical contact rather than a hidden outcome switch.
		away_keeper.dive(read.x,read.y,0.05)
		return
	# Slow shots arrive after the original dive has already landed. Time the
	# extension for the ball crossing the keeper plane, including its arc.
	var flight := lerpf(1.65,0.75,shot_power)
	var fraction := clampf((away_keeper.position.z-ball.position.z)/(target.z-ball.position.z),0.0,1.0)
	var arrival := flight*fraction
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity",9.8)*ball.gravity_scale
	var height := lerpf(ball.position.y,target.y,fraction)+0.5*gravity*flight*flight*fraction*(1.0-fraction)
	read.y = clampf(height-0.25,0.65,1.6)
	delay = maxf(delay,arrival-0.43)
	away_keeper.dive(read.x,read.y,keeper_rng.randf_range(delay-0.025,delay+0.025))

func defense_active() -> bool:
	return phase == Phase.DEFEND or (phase == Phase.KICKING and defense_windup)

func fire_ai_shot() -> void:
	if phase != Phase.DEFEND or ball_in_flight:
		return
	phase = Phase.KICKING
	defense_windup = true
	ball.freeze = true
	kicker.prepare_shot(ai_shot_target, ai_shot_crossed)
	var target := ai_shot_target
	var crossed := ai_shot_crossed
	kicker.kick(func() -> void:
		phase = Phase.DEFEND
		defense_windup = false
		match_audio.play_effect("kick", ball.global_position)
		launch_ball(target,AI_SHOT_FLIGHT_TIME,1)
		last_ai_shot_crossed = crossed
		status_label.text = "¡Remate!"
		if not keeper_dived:
			hint_label.text = "¡Estirate ahora! Apuntá al balón y clic, o arrastrá y soltá · ← / ESPACIO / →, W alta / S baja"
	)

func dive_home_keeper(lane: int) -> void:
	if not defense_active() or keeper_dived:
		return
	keeper_lane = lane
	var y := 1.6 if keeper_height > 0 else 0.65 if keeper_height < 0 else 1.15
	defense_aim = Vector2(keeper_lane * 3.97, 2.65 if keeper_height > 0 else 0.3 if keeper_height < 0 else 1.45)
	commit_home_keeper_dive(keeper_lane * 3.10, y)

func commit_home_keeper_dive(x: float, y: float) -> void:
	defense_dive_time = shot_time if ball_in_flight else -1.0
	keeper_dived = true
	touch_aiming = false
	defense_target.set_target(defense_screen_from_target(defense_aim), true)
	home_keeper.dive(x, y)
	status_label.text = "Estirada: %s" % keeper_direction_name()

func _on_ball_contact(body: Node) -> void:
	if not ball_in_flight:
		return
	if body.is_in_group("woodwork"):
		if not hit_woodwork:
			match_audio.play_effect("post", ball.global_position)
		hit_woodwork = true
		status_label.text = "¡Palo!"
	if (shot_goal == -1 and body == away_keeper) or (shot_goal == 1 and body == home_keeper):
		# Defer physics mutations until after the contact callback.
		show_save.call_deferred(body)

func show_net_goal() -> void:
	if shot_goal == 1:
		# Return the local net to full strength for the impact animation.
		get_node("Stadium").set_net_opacity(1, 1.0)
	var impact := Vector3(clampf(ball.position.x,-3.85,3.85),clampf(ball.position.y,0.3,2.6),shot_goal*(GOAL_Z+1.75))
	ball_effect = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	ball_effect.tween_property(ball,"position",impact,0.14)
	ball_effect.tween_callback(func() -> void:
		get_node("Stadium").ripple_net(shot_goal,impact)
		match_audio.play_effect("net", impact)
	)
	ball_effect.tween_property(ball,"position",Vector3(impact.x,BALL_RADIUS,shot_goal*(GOAL_Z+1.2)),0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_save(keeper: Keeper) -> void:
	if resolved or not ball_in_flight: return
	match_audio.play_effect("save", ball.global_position)
	var incoming := last_flight_velocity
	var offset := absf(ball.position.x-keeper.position.x)
	var caught := should_hold_save(incoming.length(),offset,randf())
	resolve_shot(false,"¡Atajada!",not caught)
	if caught:
		keeper.catch_pose(shot_goal)
		holding_keeper = keeper
		ball.global_position = keeper.held_ball_position(shot_goal)
	else:
		# A visible parry back into the field; the save is already recorded once.
		ball.add_collision_exception_with(keeper)
		ball.freeze = false
		var lateral := signf(ball.position.x-keeper.position.x)
		if lateral == 0: lateral = 1.0
		ball.linear_velocity = Vector3(lateral*4.0,3.0,-shot_goal*maxf(absf(incoming.z)*0.45,5.0))
		ball.angular_velocity = Vector3(6,4,8)
		status_label.text = "¡Atajada con rebote!"

func should_hold_save(speed: float, offset: float, roll: float) -> bool:
	# Even a reachable shot can spill: 45% of otherwise catchable saves rebound.
	return speed < 18.0 and offset < 0.6 and roll >= 0.45

func resolve_shot(scored: bool, message: String, keep_ball_moving := false) -> void:
	if resolved:
		return
	resolved = true
	ball_in_flight = false
	if not keep_ball_moving:
		ball.linear_velocity = Vector3.ZERO
		ball.angular_velocity = Vector3.ZERO
		ball.freeze = true
	if scored:
		if shot_goal == -1:
			player_goals += 1
			local_scores[active_player] += 1
		else:
			rival_goals += 1
	match_audio.play_result(scored)
	if scored:
		show_net_goal()
	status_label.text = message
	shot_meter.hide()
	hint_label.offset_right = get_viewport().get_visible_rect().size.x - 24
	hint_label.offset_top = -100
	hint_label.text = shot_explanation(scored, message)
	var headline := "¡GOL!" if scored else "¡ATAJADA!" if message == "¡Atajada!" else "¡FUERA!"
	if hit_woodwork and message != "¡Atajada!": headline = "¡PALO Y GOL!" if scored else "¡PALO Y FUERA!"
	match_overlay.show_result(headline,preload("res://ui/visual_theme.gd").SUCCESS if scored else preload("res://ui/visual_theme.gd").ENERGY)
	update_score()
	phase = Phase.RESOLVING
	defense_target.hide()
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 2.3
	add_child(timer)
	timer.timeout.connect(func() -> void:
		timer.queue_free()
		advance_after_shot()
	)
	timer.start()

func shot_explanation(scored: bool, message: String) -> String:
	if hit_woodwork:
		return "Pegó en el palo: dejá más margen al apuntar."
	if shot_goal == -1:
		if absf(last_aim_target.x) > GOAL_WIDTH * 0.5 - BALL_RADIUS or last_aim_target.y > GOAL_HEIGHT - BALL_RADIUS:
			return "Apuntaste al borde o fuera del arco: dejá más margen."
		if last_accuracy < 0.7:
			return "El timing desvió el tiro: soltá más cerca del centro verde."
		if scored:
			return "Buena colocación: la pelota quedó fuera de su alcance."
		return "El arquero llegó al tiro: buscá más distancia de su posición." if message == "¡Atajada!" else "El tiro salió afuera: ajustá la mira y el timing."
	if not scored:
		return "Buena lectura y timing: interceptaste la pelota." if message == "¡Atajada!" else "El rival falló el remate."
	if not keeper_dived:
		return "No te estiraste: leé la postura y reaccioná al remate."
	if ShotTactics.lane(defense_aim.x) != ShotTactics.lane(last_shot_target.x):
		if last_ai_shot_crossed and ShotTactics.lane(defense_aim.x) == -ShotTactics.lane(last_shot_target.x):
			return "Te engañó con un remate cruzado: seguí la pelota al salir."
		return "Elegiste otro lado: observá la carrera y la salida de la pelota."
	if absf(defense_aim.y - last_shot_target.y) > 0.7:
		return "La altura no coincidió: ajustá la mira antes de estirarte."
	if defense_dive_time < 0.15:
		return "Te estiraste muy pronto: esperá un poco más antes de comprometerte."
	if defense_dive_time > 0.8:
		return "Te estiraste tarde: usá la postura para anticipar el remate."
	return "La estirada no alcanzó la pelota: ajustá el punto y el timing."

func advance_after_shot() -> void:
	ball.freeze = false
	if player_count > 1:
		active_player += 1
		if active_player == player_count:
			active_player = 0
			turn += 1
		if turn > shot_limit:
			finish_match()
		else:
			aim_x = 0.0
			aim_y = 0.0
			start_attack()
		return
	if shot_goal == -1:
		start_defense()
		return
	if turn < shot_limit:
		turn += 1
		start_attack()
	elif player_goals == rival_goals:
		sudden_death = true
		turn += 1
		start_attack()
	else:
		finish_match()

func finish_match() -> void:
	if phase == Phase.FINISHED:
		return
	phase = Phase.FINISHED
	defense_target.hide()
	ball_in_flight = false
	is_charging = false
	shot_meter.hide()
	aim_marker.hide()
	var round_best := player_goals if player_count == 1 else int(local_scores.max())
	if round_best > best_score:
		best_score = round_best
		save_best_score()
	look_from_kicker()
	var celebrating := player_count == 1 and player_goals > rival_goals
	if player_count == 1:
		status_label.text = "¡Ganó Jugador 1!" if player_goals > rival_goals else "¡Ganó la IA!"
	else:
		var winners: PackedStringArray = []
		for i in range(player_count):
			if local_scores[i] == round_best:
				winners.append("Jugador %s" % (i + 1))
		status_label.text = "¡Ganó %s!" % winners[0] if winners.size() == 1 else "Empate: %s" % " / ".join(winners)
		celebrating = winners.size() == 1
	match_overlay.show_result(status_label.text,preload("res://ui/visual_theme.gd").ENERGY,true)
	if celebrating:
		show_victory_celebration()
	hint_label.text = "Volviendo al inicio… · ESPACIO para continuar"
	update_score()
	# A node-owned timer is freed if Escape/Space leaves the scene early.
	var return_timer := Timer.new()
	return_timer.one_shot = true
	return_timer.wait_time = 3.0
	add_child(return_timer)
	return_timer.timeout.connect(func() -> void: get_tree().change_scene_to_file("res://Menu.tscn"))
	return_timer.start()

func show_victory_celebration() -> void:
	ball.freeze = true
	ball.hide()
	away_keeper.hide()
	var identity := ConfigFile.new()
	identity.load(save_path)
	kicker.apply_identity(int(identity.get_value("appearance","striker",0)),player_name,int(identity.get_value("appearance","number",10)),preload("res://footballer_model.gd").custom_profile(identity))
	home_keeper.celebrate(Vector3(-1.6,0.9,3.0))
	kicker.celebrate(Vector3(1.6,0,3.0))
	camera.position = Vector3(0,2.6,8.8)
	camera.look_at(Vector3(0,1.2,3.0),Vector3.UP)

func current_player_label() -> String:
	return player_name if player_count == 1 else "Jugador %s" % (active_player + 1)

func reset_ball(location: Vector3) -> void:
	if ball_effect: ball_effect.kill()
	holding_keeper = null
	ball.show()
	ball.remove_collision_exception_with(away_keeper)
	ball.remove_collision_exception_with(home_keeper)
	ball_in_flight = false
	resolved = false
	hit_woodwork = false
	ball.freeze = true
	ball.position = location
	ball.rotation = Vector3.ZERO
	PhysicsServer3D.body_set_state(ball.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,ball.global_transform)
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = false

func look_from_kicker() -> void:
	get_node("Stadium").set_net_opacity(1, 1.0)
	camera.position = Vector3(0, 3.8, ball.position.z + 8.0)
	camera.look_at(Vector3(0, 1.0, ball.position.z - 10.0), Vector3.UP)

func look_from_keeper() -> void:
	get_node("Stadium").set_net_opacity(1, 0.18)
	camera.position = Vector3(0, 4.4, GOAL_Z + 8.0)
	camera.look_at(Vector3(0, 1.2, GOAL_Z - shooting_distance() * 0.5), Vector3.UP)

func update_score() -> void:
	if player_count > 1:
		var scores: PackedStringArray = []
		for i in range(player_count):
			scores.append("J%s: %s" % [i + 1, local_scores[i]])
		var entries: Array = []
		for i in range(player_count): entries.append(["J%s" % (i + 1), local_scores[i]])
		score_label.set("entries", entries)
		score_label.queue_redraw()
		score_label.text = "   |   ".join(scores)
		score_detail.text = "%s tiros por jugador" % shot_limit
		return
	var suffix := " · muerte súbita" if sudden_death else ""
	score_label.set("entries", [[player_name, player_goals], ["Arquero", rival_goals]])
	score_label.queue_redraw()
	score_label.text = "%s  %s — %s  Arquero" % [player_name, player_goals, rival_goals]
	score_detail.text = "Mejor marca: %s goles%s" % [best_score, suffix]

func update_aim_label() -> void:
	if phase == Phase.ATTACK and not ball_in_flight:
		aim_label.text = "Dirección %+.0f · altura %+.0f · potencia %.0f%%" % [aim_x * 100.0, aim_y * 100.0, shot_power * 100.0]
	elif phase == Phase.DEFEND and not ball_in_flight:
		aim_label.text = "Estirada seleccionada: %s" % keeper_direction_name()
	else:
		aim_label.text = ""

func keeper_direction_name() -> String:
	var horizontal := "izquierda" if keeper_lane < 0 else "derecha" if keeper_lane > 0 else "centro"
	var vertical := "alta" if keeper_height > 0 else "baja" if keeper_height < 0 else "media"
	return "%s %s" % [horizontal, vertical]

func turn_label() -> String:
	return "muerte súbita %s" % (turn - shot_limit) if sudden_death else "%s/%s" % [turn, shot_limit]

func load_best_score() -> void:
	shot_limit = 5
	player_count = 1
	var profile := ConfigFile.new()
	if profile.load(save_path) == OK:
		best_score = int(profile.get_value("scores", "shots_%s" % shot_limit, 0))
		difficulty = str(profile.get_value("settings", "difficulty", "medio"))
		player_name = str(profile.get_value("appearance", "name", "Jugador"))

func save_best_score() -> void:
	var profile := ConfigFile.new()
	profile.load(save_path)
	profile.set_value("scores", "shots_%s" % shot_limit, best_score)
	profile.save(save_path)

func apply_player_appearance() -> void:
	var profile := ConfigFile.new()
	profile.load(save_path)
	var human: Dictionary = preload("res://footballer_model.gd").keeper_profile(profile)
	var hair_colors := ["c5aa6a","69412d","171717"]
	if int(profile.get_value("appearance","keeper",0)) != 3:
		human.hair = hair_colors[clampi(int(profile.get_value("appearance","hair",1)),0,2)]
	home_keeper.build_body(human,str(profile.get_value("appearance","keeper_name",player_name)),int(profile.get_value("appearance","keeper_number",profile.get_value("appearance","number",10))))

func shooting_distance() -> float:
	return 24.0
