extends Node3D

var shot_limit := 7
var player_count := 1
var active_player := 0
var local_scores: Array[int] = []
@export var save_path := "user://free_kick_3d.cfg"
const GOAL_Z := 12.0
const GOAL_WIDTH := 7.2
const GOAL_HEIGHT := 2.5
const BALL_RADIUS := 0.22
const ShotMeter = preload("res://shot_meter.gd")
const Keeper = preload("res://keeper.gd")


enum Phase { ATTACK, DEFEND, RESOLVING, FINISHED }

var phase: Phase = Phase.ATTACK
var turn := 1
var player_goals := 0
var rival_goals := 0
var sudden_death := false
var best_score := 0
var difficulty := "medio"
var player_name := "Jugador"

var ball: RigidBody3D
var away_keeper: Keeper
var home_keeper: Keeper
var camera: Camera3D
var status_label: Label
var score_label: Label
var hint_label: Label
var aim_label: Label
var aim_marker: MeshInstance3D
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
	aim_marker = create_aim_marker()
	create_interface()
	start_attack()

func _process(delta: float) -> void:
	if phase == Phase.ATTACK and is_charging:
		shot_meter.advance(delta)
		shot_power = shot_meter.power
		refresh_aim_marker()
	if ball_in_flight:
		shot_time += delta
		if shot_time > 4.0 or abs(ball.position.z) > 18.0 or ball.position.y < -1.0:
			resolve_shot(false, "Fuera o atajada")
	if phase == Phase.DEFEND and not ball_in_flight:
		defense_countdown -= delta
		if defense_countdown <= 0.0:
			fire_ai_shot()
	update_aim_label()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://Menu.tscn")
		return
	if phase == Phase.RESOLVING:
		return
	if phase == Phase.FINISHED:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			get_tree().change_scene_to_file("res://Menu.tscn")
		return

	if event is InputEventMouseMotion and phase == Phase.ATTACK and not ball_in_flight:
		set_attack_target_from_screen(event.position)
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if phase == Phase.ATTACK and not ball_in_flight:
			if event.pressed:
				set_attack_target_from_screen(event.position)
				shot_power = 0.0
				is_charging = true
				shot_meter.begin()
			elif is_charging:
				is_charging = false
				fire_player_shot()
		elif phase == Phase.DEFEND and event.pressed:
			dive_home_keeper(lane_from_screen_x(event.position.x))
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
		elif phase == Phase.DEFEND and event.pressed:
			dive_home_keeper(lane_from_screen_x(event.position.x))
		return

	if event is InputEventScreenDrag and phase == Phase.ATTACK and is_charging:
		set_attack_target_from_screen(event.position)
		return

	if event is InputEventKey and not event.echo and phase == Phase.ATTACK and not ball_in_flight:
		if event.keycode == KEY_SPACE:
			if event.pressed and not is_charging:
				is_charging = true
				shot_meter.begin()
			elif not event.pressed and is_charging:
				fire_player_shot()
		return

	if event is InputEventKey and event.pressed and not event.echo and phase == Phase.DEFEND:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			keeper_height = 1
		elif event.keycode == KEY_S:
			keeper_height = -1
		if event.keycode == KEY_LEFT:
			dive_home_keeper(-1)
		elif event.keycode == KEY_RIGHT:
			dive_home_keeper(1)
		elif event.keycode == KEY_SPACE or event.keycode == KEY_DOWN:
			dive_home_keeper(0)

func create_world() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("0b1f2a")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b9d9ff")
	settings.ambient_light_energy = 0.55
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	camera = Camera3D.new()
	camera.current = true
	add_child(camera)

func create_pitch() -> void:
	create_static_box("pitch", Vector3(0, -0.15, 0), Vector3(28, 0.3, 34), Color("16753c"))
	create_static_box("center_line", Vector3(0, 0.01, 0), Vector3(0.12, 0.02, 32), Color("d9f99d"))
	for x in [-10.0, 10.0]:
		create_static_box("stadium_wall", Vector3(x, 1.0, 0), Vector3(0.3, 2.0, 34), Color("123047"))

func create_goal(side: int) -> void:
	var goal_z := GOAL_Z * side
	var frame_color := Color("f8fafc")
	create_static_box("post", Vector3(-GOAL_WIDTH / 2.0, GOAL_HEIGHT / 2.0, goal_z), Vector3(0.16, GOAL_HEIGHT, 0.16), frame_color)
	create_static_box("post", Vector3(GOAL_WIDTH / 2.0, GOAL_HEIGHT / 2.0, goal_z), Vector3(0.16, GOAL_HEIGHT, 0.16), frame_color)
	create_static_box("crossbar", Vector3(0, GOAL_HEIGHT, goal_z), Vector3(GOAL_WIDTH, 0.16, 0.16), frame_color)
	create_static_box("net_back", Vector3(0, GOAL_HEIGHT / 2.0, goal_z + 1.0 * side), Vector3(GOAL_WIDTH, GOAL_HEIGHT, 0.08), Color(0.8, 0.9, 1.0, 0.16), false)

	var goal_area := Area3D.new()
	goal_area.name = "goal_area_%s" % side
	goal_area.position = Vector3(0, GOAL_HEIGHT / 2.0, goal_z + 0.35 * side)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(GOAL_WIDTH - 0.25, GOAL_HEIGHT - 0.2, 0.45)
	collision.shape = shape
	goal_area.add_child(collision)
	goal_area.body_entered.connect(_on_goal_body_entered.bind(side))
	add_child(goal_area)

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
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("f8fafc")
	material.roughness = 0.3
	visible.material_override = material
	new_ball.add_child(visible)
	add_child(new_ball)
	return new_ball

func create_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := ColorRect.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.color = Color(0.02, 0.08, 0.13, 0.82)
	panel.position = Vector2(20, 18)
	panel.size = Vector2(940, 148)
	canvas.add_child(panel)

	score_label = make_label(Vector2(36, 28), 30, Color("f8fafc"))
	status_label = make_label(Vector2(36, 68), 22, Color("facc15"))
	aim_label = make_label(Vector2(36, 102), 17, Color("dbeafe"))
	hint_label = make_label(Vector2(20, 660), 18, Color("f8fafc"))
	hint_label.size = Vector2(1200, 44)
	canvas.add_child(score_label)
	canvas.add_child(status_label)
	canvas.add_child(aim_label)
	canvas.add_child(hint_label)
	shot_meter = ShotMeter.new()
	canvas.add_child(shot_meter)
	shot_meter.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	shot_meter.offset_left = -480
	shot_meter.offset_right = -20
	shot_meter.offset_top = -190
	shot_meter.offset_bottom = -76

func make_label(location: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = location
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func start_attack() -> void:
	phase = Phase.ATTACK
	is_charging = false
	shot_power = 0.0
	shot_meter.reset()
	away_keeper.reset_pose()
	home_keeper.reset_pose()
	refresh_aim_marker()
	reset_ball(Vector3(0, BALL_RADIUS + 0.02, 3.0))
	look_from_kicker()
	status_label.text = "%s · tiro %s" % [current_player_label(), turn_label()]
	hint_label.text = "Apuntá con el mouse · Mantené clic o ESPACIO · Soltá cuando la barra pase por el centro"
	update_score()

func start_defense() -> void:
	phase = Phase.DEFEND
	shot_meter.hide()
	away_keeper.reset_pose()
	home_keeper.reset_pose()
	aim_marker.hide()
	keeper_lane = 0
	keeper_height = 0
	keeper_dived = false
	defense_countdown = 2.2
	reset_ball(Vector3(0, BALL_RADIUS + 0.02, -9.5))
	look_from_keeper()
	status_label.text = "Turno %s: atajás" % turn_label()
	hint_label.text = "Atajá con clic o ← / ESPACIO / → · W alta / S baja · Esperá el tiro para estirarte"
	update_score()

func fire_player_shot() -> void:
	if phase != Phase.ATTACK or ball_in_flight:
		return
	ball_in_flight = true
	shot_goal = -1
	shot_time = 0.0
	resolved = false
	last_accuracy = shot_meter.accuracy()
	shot_meter.lock_shot()
	var target := player_shot_target(last_accuracy)
	is_charging = false
	aim_marker.hide()
	var flight_time := lerpf(1.4, 0.75, shot_power)
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var velocity := (target - ball.position) / flight_time + Vector3.UP * gravity * ball.gravity_scale * flight_time * 0.5
	ball.linear_velocity = velocity
	ball.angular_velocity = Vector3(0, 0, spin * 16.0)
	move_keeper_for_attack(target)
	status_label.text = "%s · precisión %d%%" % [shot_meter.feedback, roundi(last_accuracy * 100)]

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
	aim_marker.position = Vector3(aim_x * 3.05, 1.35 + aim_y * 0.95, -GOAL_Z + 0.2)
	aim_marker.scale = Vector3.ONE * (1.0 + shot_power * 0.6)

func set_attack_target_from_screen(screen_position: Vector2) -> void:
	var goal_plane := Plane(Vector3.FORWARD, GOAL_Z)
	var hit: Variant = goal_plane.intersects_ray(camera.project_ray_origin(screen_position), camera.project_ray_normal(screen_position))
	if hit == null:
		return
	aim_x = clampf(hit.x / 3.05, -1.0, 1.0)
	aim_y = clampf((hit.y - 1.35) / 0.95, -1.0, 1.0)
	refresh_aim_marker()

func lane_from_screen_x(screen_x: float) -> int:
	var width := get_viewport().get_visible_rect().size.x
	return -1 if screen_x < width / 3.0 else 1 if screen_x > width * 2.0 / 3.0 else 0

func player_shot_target(accuracy: float) -> Vector3:
	# Missing the timing pushes the shot further toward the aimed side, as in HTML.
	var direction := signf(aim_x) if absf(aim_x) > 0.05 else signf(shot_meter.indicator - 0.5)
	var error := (1.0 - accuracy) * 2.5
	return Vector3(aim_x * 3.05 + direction * error, 1.35 + aim_y * 0.95 + error * 0.18, -GOAL_Z - 0.3)

func move_keeper_for_attack(target: Vector3) -> void:
	# A delayed, imperfect read of the shot; no random dive in the opposite direction.
	var error := 0.45
	var reach := 0.82
	var delay := 0.24
	if difficulty == "facil":
		error = 0.9
		reach = 0.65
		delay = 0.42
	elif difficulty == "dificil":
		error = 0.18
		reach = 0.95
		delay = 0.12
	var read_x := target.x + randf_range(-error, error)
	away_keeper.dive(read_x * reach, target.y * 0.75, randf_range(delay - 0.04, delay + 0.04))

func fire_ai_shot() -> void:
	if phase != Phase.DEFEND or ball_in_flight:
		return
	ball_in_flight = true
	shot_goal = 1
	shot_time = 0.0
	resolved = false
	var target := Vector3(randf_range(-2.9, 2.9), randf_range(0.55, 2.25), GOAL_Z + 0.3)
	var velocity := (target - ball.position) / 1.05 + Vector3.UP * 3.0
	ball.linear_velocity = velocity
	ball.angular_velocity = Vector3(0, randf_range(-11.0, 11.0), 0)
	status_label.text = "El rival patea"
	if not keeper_dived:
		hint_label.text = "¡Todavía podés estirarte con ESPACIO!"

func dive_home_keeper(lane: int) -> void:
	if phase != Phase.DEFEND or keeper_dived:
		return
	keeper_lane = lane
	keeper_dived = true
	var y := 1.6 if keeper_height > 0 else 0.65 if keeper_height < 0 else 1.15
	home_keeper.dive(keeper_lane * 2.35, y)
	status_label.text = "Estirada: %s" % keeper_direction_name()

func _on_ball_contact(body: Node) -> void:
	if not ball_in_flight:
		return
	if (shot_goal == -1 and body == away_keeper) or (shot_goal == 1 and body == home_keeper):
		# Defer physics mutations until after the contact callback.
		resolve_shot.call_deferred(false, "¡Atajada!")

func _on_goal_body_entered(body: Node3D, side: int) -> void:
	if body != ball or not ball_in_flight or side != shot_goal:
		return
	resolve_shot(true, "¡Gol!")

func resolve_shot(scored: bool, message: String) -> void:
	if resolved:
		return
	resolved = true
	ball_in_flight = false
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = true
	if scored:
		if shot_goal == -1:
			player_goals += 1
			local_scores[active_player] += 1
		else:
			rival_goals += 1
	status_label.text = message
	update_score()
	phase = Phase.RESOLVING
	var timer := get_tree().create_timer(1.25)
	timer.timeout.connect(advance_after_shot)

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
	ball_in_flight = false
	is_charging = false
	shot_meter.hide()
	aim_marker.hide()
	var round_best := player_goals if player_count == 1 else int(local_scores.max())
	if round_best > best_score:
		best_score = round_best
		save_best_score()
	look_from_kicker()
	if player_count == 1:
		status_label.text = "Ganaste el duelo" if player_goals > rival_goals else "El rival ganó el duelo"
	else:
		var winners: PackedStringArray = []
		for i in range(player_count):
			if local_scores[i] == round_best:
				winners.append("J%s" % (i + 1))
		status_label.text = "Gana %s" % winners[0] if winners.size() == 1 else "Empate: %s" % " / ".join(winners)
	hint_label.text = "Volviendo al inicio… · ESPACIO para continuar"
	update_score()
	# A node-owned timer is freed if Escape/Space leaves the scene early.
	var return_timer := Timer.new()
	return_timer.one_shot = true
	return_timer.wait_time = 3.0
	add_child(return_timer)
	return_timer.timeout.connect(func() -> void: get_tree().change_scene_to_file("res://Menu.tscn"))
	return_timer.start()

func current_player_label() -> String:
	return player_name if player_count == 1 else "Jugador %s" % (active_player + 1)

func reset_ball(location: Vector3) -> void:
	ball.freeze = true
	ball.position = location
	ball.rotation = Vector3.ZERO
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.freeze = false

func look_from_kicker() -> void:
	camera.position = Vector3(0, 3.1, 8.2)
	camera.look_at(Vector3(0, 1.2, -GOAL_Z), Vector3.UP)

func look_from_keeper() -> void:
	camera.position = Vector3(0, 2.5, GOAL_Z + 5.0)
	camera.look_at(Vector3(0, 1.1, -5.0), Vector3.UP)

func update_score() -> void:
	if player_count > 1:
		var scores: PackedStringArray = []
		for i in range(player_count):
			scores.append("J%s: %s" % [i + 1, local_scores[i]])
		score_label.text = "%s · %s tiros c/u" % ["   |   ".join(scores), shot_limit]
		return
	var suffix := " · muerte súbita" if sudden_death else ""
	score_label.text = "%s %s — %s Rival%s · récord %s" % [player_name, player_goals, rival_goals, suffix, best_score]

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
	var profile := ConfigFile.new()
	if profile.load(save_path) == OK:
		shot_limit = clampi(int(profile.get_value("settings", "shots", 7)), 5, 15)
		player_count = clampi(int(profile.get_value("settings", "players", 1)), 1, 4)
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
	var hair_colors := [Color("ead17c"), Color("69412d"), Color("171717")]
	var hair := clampi(int(profile.get_value("appearance", "hair", 1)), 0, 2)
	home_keeper.add_part(home_keeper.visual, Vector3(0, 0.85, 0), Vector3(0.36, 0.12, 0.36), hair_colors[hair])
	var number := Label3D.new()
	number.text = str(profile.get_value("appearance", "number", 10))
	number.position = Vector3(0, 0.15, 0.18)
	number.pixel_size = 0.005
	number.font_size = 64
	home_keeper.visual.add_child(number)
