extends Node3D

const REGULATION_TURNS := 5
const GOAL_Z := 12.0
const GOAL_WIDTH := 7.2
const GOAL_HEIGHT := 2.5
const BALL_RADIUS := 0.22

enum Phase { ATTACK, DEFEND, RESOLVING, FINISHED }

var phase: Phase = Phase.ATTACK
var turn := 1
var player_goals := 0
var rival_goals := 0
var sudden_death := false

var ball: RigidBody3D
var away_keeper: AnimatableBody3D
var home_keeper: AnimatableBody3D
var camera: Camera3D
var status_label: Label
var score_label: Label
var hint_label: Label
var aim_label: Label

var ball_in_flight := false
var shot_time := 0.0
var shot_goal := 0
var resolved := false
var defense_countdown := 0.0
var keeper_lane := 0
var keeper_height := 0
var keeper_dived := false
var aim_x := 0.0
var aim_y := 0.0
var spin := 0.0
var drag_start := Vector2.ZERO
var is_dragging := false

func _ready() -> void:
	create_world()
	create_pitch()
	create_goal(-1)
	create_goal(1)
	away_keeper = create_keeper(-1, Color("f59e0b"))
	home_keeper = create_keeper(1, Color("22c55e"))
	ball = create_ball()
	create_interface()
	start_attack()

func _process(delta: float) -> void:
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
	if phase == Phase.FINISHED or phase == Phase.RESOLVING:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			reset_match()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and phase == Phase.ATTACK and not ball_in_flight:
			drag_start = event.position
			is_dragging = true
		elif not event.pressed and is_dragging:
			is_dragging = false
			if phase == Phase.ATTACK and not ball_in_flight:
				set_attack_from_drag(event.position - drag_start)
				fire_player_shot()

	if event is InputEventScreenTouch:
		if event.pressed and phase == Phase.ATTACK:
			drag_start = event.position
			is_dragging = true
		elif is_dragging:
			is_dragging = false
			set_attack_from_drag(event.position - drag_start)
			fire_player_shot()

	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if phase == Phase.ATTACK and not ball_in_flight:
		if event.keycode == KEY_A:
			aim_x = clampf(aim_x - 0.12, -1.0, 1.0)
		elif event.keycode == KEY_D:
			aim_x = clampf(aim_x + 0.12, -1.0, 1.0)
		elif event.keycode == KEY_W:
			aim_y = clampf(aim_y + 0.12, -1.0, 1.0)
		elif event.keycode == KEY_S:
			aim_y = clampf(aim_y - 0.12, -1.0, 1.0)
		elif event.keycode == KEY_Q:
			spin = clampf(spin - 0.2, -1.0, 1.0)
		elif event.keycode == KEY_E:
			spin = clampf(spin + 0.2, -1.0, 1.0)
		elif event.keycode == KEY_SPACE:
			fire_player_shot()
	elif phase == Phase.DEFEND:
		if event.keycode == KEY_A:
			keeper_lane = maxi(-1, keeper_lane - 1)
		elif event.keycode == KEY_D:
			keeper_lane = mini(1, keeper_lane + 1)
		elif event.keycode == KEY_W:
			keeper_height = 1
		elif event.keycode == KEY_S:
			keeper_height = -1
		elif event.keycode == KEY_SPACE:
			dive_home_keeper()

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

func create_keeper(side: int, shirt_color: Color) -> AnimatableBody3D:
	var keeper := AnimatableBody3D.new()
	keeper.name = "keeper_%s" % side
	keeper.position = Vector3(0, 0.9, GOAL_Z * side - 0.7 * side)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.7
	collision.shape = shape
	keeper.add_child(collision)

	var torso := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.38
	mesh.height = 1.7
	torso.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = shirt_color
	material.roughness = 0.45
	torso.material_override = material
	keeper.add_child(torso)
	add_child(keeper)
	return keeper

func create_ball() -> RigidBody3D:
	var new_ball := RigidBody3D.new()
	new_ball.name = "ball"
	new_ball.mass = 0.43
	new_ball.gravity_scale = 0.55
	new_ball.continuous_cd = true
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
	panel.color = Color(0.02, 0.08, 0.13, 0.82)
	panel.position = Vector2(20, 18)
	panel.size = Vector2(500, 148)
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

func make_label(location: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = location
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func start_attack() -> void:
	phase = Phase.ATTACK
	reset_ball(Vector3(0, BALL_RADIUS + 0.02, 3.0))
	away_keeper.position = Vector3(0, 0.9, -GOAL_Z + 0.7)
	look_from_kicker()
	status_label.text = "Turno %s: pateás" % turn_label()
	hint_label.text = "Arrastrá para patear · Teclado: A/D dirección, W/S altura, Q/E efecto, ESPACIO tira"
	update_score()

func start_defense() -> void:
	phase = Phase.DEFEND
	keeper_lane = 0
	keeper_height = 0
	keeper_dived = false
	defense_countdown = 2.2
	reset_ball(Vector3(0, BALL_RADIUS + 0.02, -9.5))
	home_keeper.position = Vector3(0, 0.9, GOAL_Z - 0.7)
	look_from_keeper()
	status_label.text = "Turno %s: atajás" % turn_label()
	hint_label.text = "Leé la carrera rival · A/D elegí lado · W/S altura · ESPACIO estirada"
	update_score()

func fire_player_shot() -> void:
	if phase != Phase.ATTACK or ball_in_flight:
		return
	ball_in_flight = true
	shot_goal = -1
	shot_time = 0.0
	resolved = false
	var target := Vector3(aim_x * 3.05, 1.35 + aim_y * 0.95, -GOAL_Z - 0.3)
	var velocity := (target - ball.position) / 1.12 + Vector3.UP * 3.4
	ball.linear_velocity = velocity
	ball.angular_velocity = Vector3(0, 0, spin * 16.0)
	move_keeper_for_attack(target)
	status_label.text = "Tu tiro está en vuelo"

func set_attack_from_drag(drag: Vector2) -> void:
	aim_x = clampf(drag.x / 180.0, -1.0, 1.0)
	aim_y = clampf(-drag.y / 140.0, -1.0, 1.0)
	spin = clampf(drag.x / 260.0, -1.0, 1.0)

func move_keeper_for_attack(target: Vector3) -> void:
	var reads_shot := randf() < 0.55
	var destination_x := target.x * (0.76 if reads_shot else -0.36)
	var destination_y := 0.9 + maxf(0.0, target.y - 1.4) * 0.36
	var tween := create_tween()
	tween.tween_property(away_keeper, "position", Vector3(clampf(destination_x, -2.7, 2.7), destination_y, -GOAL_Z + 0.7), 0.5)

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

func dive_home_keeper() -> void:
	if phase != Phase.DEFEND or keeper_dived:
		return
	keeper_dived = true
	var y := 0.9 + (0.72 if keeper_height > 0 else -0.12 if keeper_height < 0 else 0.25)
	var destination := Vector3(keeper_lane * 2.35, y, GOAL_Z - 0.7)
	var tween := create_tween()
	tween.tween_property(home_keeper, "position", destination, 0.28)
	status_label.text = "Estirada: %s" % keeper_direction_name()

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
		else:
			rival_goals += 1
	status_label.text = message
	update_score()
	phase = Phase.RESOLVING
	var timer := get_tree().create_timer(1.25)
	timer.timeout.connect(advance_after_shot)

func advance_after_shot() -> void:
	ball.freeze = false
	if shot_goal == -1:
		start_defense()
		return
	if turn < REGULATION_TURNS:
		turn += 1
		start_attack()
	elif player_goals == rival_goals:
		sudden_death = true
		turn += 1
		start_attack()
	else:
		finish_match()

func finish_match() -> void:
	phase = Phase.FINISHED
	look_from_kicker()
	status_label.text = "Ganaste el duelo" if player_goals > rival_goals else "El rival ganó el duelo"
	hint_label.text = "ESPACIO para jugar otro duelo"
	update_score()

func reset_match() -> void:
	turn = 1
	player_goals = 0
	rival_goals = 0
	sudden_death = false
	aim_x = 0.0
	aim_y = 0.0
	spin = 0.0
	start_attack()

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
	var suffix := " · muerte súbita" if sudden_death else ""
	score_label.text = "Tu selección %s — %s Rival%s" % [player_goals, rival_goals, suffix]

func update_aim_label() -> void:
	if phase == Phase.ATTACK and not ball_in_flight:
		aim_label.text = "Dirección %+.0f · altura %+.0f · efecto %+.0f" % [aim_x * 100.0, aim_y * 100.0, spin * 100.0]
	elif phase == Phase.DEFEND and not ball_in_flight:
		aim_label.text = "Estirada seleccionada: %s" % keeper_direction_name()
	else:
		aim_label.text = ""

func keeper_direction_name() -> String:
	var horizontal := "izquierda" if keeper_lane < 0 else "derecha" if keeper_lane > 0 else "centro"
	var vertical := "alta" if keeper_height > 0 else "baja" if keeper_height < 0 else "media"
	return "%s %s" % [horizontal, vertical]

func turn_label() -> String:
	return "muerte súbita %s" % (turn - REGULATION_TURNS) if sudden_death else "%s/%s" % [turn, REGULATION_TURNS]
