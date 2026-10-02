extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-keeper-target-test.cfg"
	root.add_child(game)
	game.start_defense()
	game.defense_countdown = 999.0
	check(game.defense_target.visible, "La mira debe mostrarse al empezar la defensa")
	var goal_rect: Rect2 = game.defense_goal_rect()
	check(goal_rect.size.x > 200.0 and goal_rect.size.y > 80.0, "La mira debe seguir el arco proyectado")
	var target := Vector2(1.65, 2.1)
	var screen_position: Vector2 = game.defense_screen_from_target(target)
	game.preview_defense_target(screen_position)
	check(game.defense_aim.distance_to(target) < 0.02, "La mira debe admitir un punto alto entre centro y derecha")
	check(not game.keeper_dived, "Mover la mira no debe lanzar al arquero")
	game.dive_home_keeper_from_screen(screen_position)
	check(game.keeper_dived and game.keeper_lane == 1 and game.keeper_height == 1, "El toque debe lanzar la estirada seleccionada")
	await create_timer(0.55).timeout
	check(game.home_keeper.position.x > 0.9 and game.home_keeper.position.x < 2.0, "El arquero debe ir al punto intermedio, no saltar al ángulo")
	game.start_defense()
	game.defense_countdown = 999.0
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = game.defense_screen_from_target(Vector2.ZERO)
	game._unhandled_input(touch)
	var emulated_mouse := InputEventMouseButton.new()
	emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.position = touch.position
	game._unhandled_input(emulated_mouse)
	check(not game.keeper_dived, "El mouse emulado por el toque no debe anticipar la estirada")
	var drag := InputEventScreenDrag.new()
	drag.position = game.defense_screen_from_target(target)
	game._unhandled_input(drag)
	check(game.defense_aim.distance_to(target) < 0.02 and not game.keeper_dived, "Arrastrar debe actualizar la mira")
	touch.pressed = false
	touch.position = drag.position
	game._unhandled_input(touch)
	check(game.keeper_dived, "Soltar el dedo debe confirmar la estirada")
	game.queue_free()
	print("PASS: mira visible y estirada intermedia" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures else 0)
