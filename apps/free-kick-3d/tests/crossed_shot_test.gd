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
	game.save_path = "/tmp/futbol-crossed-shot-test.cfg"
	root.add_child(game)
	for crossed in [false, true]:
		for side in [-1, 1]:
			game.start_defense()
			game.defense_countdown = 999.0
			var actual_target := Vector3(side * 2.65, 1.35, game.GOAL_Z + 0.3)
			game.ai_shot_target = actual_target
			game.ai_shot_crossed = crossed
			var start: Vector3 = game.kicker.position
			game.kicker.prepare_shot(actual_target, crossed)
			await create_timer(0.22).timeout
			var cue_side := int(signf(game.kicker.footballer_visual.rotation.y - PI))
			check(cue_side == (-side if crossed else side), "El remate cruzado debe preparar el cuerpo hacia el lado opuesto")
			check(game.kicker.position.is_equal_approx(start), "El amague debe conservar la carrera y la posición de inicio")
			game.fire_ai_shot()
			while not game.ball_in_flight:
				await physics_frame
			check(game.last_shot_target.is_equal_approx(actual_target), "La pelota debe salir al destino elegido antes de la estirada")
			check(game.last_ai_shot_crossed == crossed, "El resultado debe conservar si el tiro era cruzado")
			check(game.status_label.text == "¡Remate!", "El HUD no debe revelar el amague ni el destino")
			await create_timer(0.35).timeout
			# Normal shots: react to the ball. Crossed shots: fall for the feint.
			var chosen_side: int = -side if crossed else side
			game.dive_home_keeper_from_screen(game.defense_screen_from_target(Vector2(chosen_side * 2.65, 1.35)))
			while not game.resolved:
				await physics_frame
			check(game.status_label.text.contains("Gol") if crossed else game.status_label.text.contains("Atajada"), "Seguir el amague debe fallar; seguir la pelota debe permitir atajar")
			if crossed:
				check(game.hint_label.text.contains("cruzado"), "La explicación del engaño debe aparecer después del resultado")
			for child in game.get_children():
				if child is Timer:
					child.stop()
					child.queue_free()
	# A feint is still saveable when the player waits for the actual ball.
	game.start_defense()
	game.defense_countdown = 999.0
	game.ai_shot_target = Vector3(2.65, 1.35, game.GOAL_Z + 0.3)
	game.ai_shot_crossed = true
	game.fire_ai_shot()
	while not game.ball_in_flight:
		await physics_frame
	await create_timer(0.35).timeout
	game.dive_home_keeper_from_screen(game.defense_screen_from_target(Vector2(2.65, 1.35)))
	while not game.resolved:
		await physics_frame
	check(game.status_label.text.contains("Atajada"), "Esperar y leer la pelota debe permitir atajar también un remate cruzado")
	for sound in game.match_audio.get_children():
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer3D:
			sound.stop()
	game.queue_free()
	await process_frame
	print("PASS: remates normales y cruzados a ambos lados, engaño y reacción a la pelota" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures else 0)
