extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func play_shot(game, x: float, wrong_way := false) -> bool:
	game.keeper_rng.seed = 0 if wrong_way else 2
	game.start_attack()
	game.aim_x = x / 3.7
	game.aim_y = (1.35 - 1.5) / 1.1
	game.shot_meter.begin()
	game.shot_meter.indicator = 0.5
	game.shot_power = 0.8
	game.fire_player_shot()
	while not game.resolved:
		await physics_frame
	for child in game.get_children():
		if child is Timer:
			child.stop()
			child.queue_free()
	return game.status_label.text.contains("Gol")

func run() -> void:
	var realtime := "--realtime" in OS.get_cmdline_user_args()
	Engine.time_scale = 1.0 if realtime else 4.0
	Engine.physics_ticks_per_second = 60 if realtime else 240
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-skill-play-test.cfg"
	root.add_child(game)
	game.difficulty = "medio"
	game.start_attack()
	check(game.away_keeper.position.is_equal_approx(game.away_keeper.rest_position), "El arquero debe esperar en el centro")
	check(is_zero_approx(game.away_keeper.visual.rotation.z), "La guardia debe mantenerse recta antes de estirarse")
	var saved := not await play_shot(game, 2.8)
	check(saved and game.status_label.text.contains("Atajada"), "Una lectura correcta debe poder atajar")
	var goal := await play_shot(game, 2.8, true)
	check(goal, "El mismo tiro debe poder superar una lectura equivocada")
	check(not game.hint_label.text.contains("habitual"), "El arquero no debe atribuir decisiones a la memoria")
	game.start_defense()
	game.defense_countdown = 0.8
	game.ai_shot_target = Vector3(-2.65, 2.2, game.GOAL_Z + 0.3)
	game.ai_shot_crossed = false
	var approach_start: Vector3 = game.kicker.position
	game.kicker.prepare_shot(game.ai_shot_target)
	await create_timer(0.28).timeout
	check(game.kicker.footballer_visual.rotation.x < -0.02, "El tiro alto debe mostrar una inclinación leve hacia atrás")
	check(game.kicker.footballer_visual.rotation.y < PI - 0.04, "La preparación debe conservar una pista sutil del lado")
	check(absf(game.kicker.footballer_visual.rotation.y - PI) < 0.15, "La postura no debe revelar el lado con un giro exagerado")
	check(game.kicker.position.is_equal_approx(approach_start), "La preparación no debe revelar el lado desplazando al pateador")
	game.fire_ai_shot()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = game.defense_screen_from_target(Vector2(-2.65, 2.2))
	game._unhandled_input(event)
	check(game.keeper_dived, "Debe poder anticiparse durante la carrera, antes del contacto")
	paused = true
	var before: Vector3 = game.kicker.footballer_visual.rotation
	await create_timer(0.15).timeout
	check(game.kicker.footballer_visual.rotation.is_equal_approx(before), "La pista y la carrera deben congelarse al pausar")
	paused = false
	await create_timer(0.55).timeout
	check(game.last_shot_target.is_equal_approx(game.ai_shot_target), "El tiro debe respetar la intención señalada antes del golpe")
	check(game.status_label.text == "¡Remate!", "El HUD no debe anunciar el lado ni la altura del tiro")
	check(game.kicker.footballer_visual.rotation.is_equal_approx(Vector3(0, PI, 0)), "La orientación original debe recuperarse para el contacto")
	game.start_attack()
	check(not game.defense_windup, "Cambiar de turno debe cancelar reacciones pendientes")
	game.shot_goal = 1
	game.keeper_dived = true
	game.defense_aim = Vector2(-2.65, 2.2)
	game.last_shot_target = Vector3(-2.65, 2.2, 52.8)
	game.defense_dive_time = -1.0
	check(game.shot_explanation(true, "¡Gol!").contains("muy pronto"), "Un fallo temprano debe ayudar a ajustar el timing")
	game.defense_dive_time = 0.95
	check(game.shot_explanation(true, "¡Gol!").contains("tarde"), "Un fallo tardío debe ayudar a anticipar")
	for sound in game.match_audio.get_children():
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer3D:
			sound.stop()
	game.queue_free()
	await process_frame
	print("PASS: arquero con margen de error, pistas, pausa y aprendizaje" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures else 0)
