extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	for control in ["bot", "mouse", "keyboard"]:
		for side in [-1, 1]:
			var game = load("res://Main.tscn").instantiate()
			game.save_path = "/tmp/futbol-ground-corner-test.cfg"
			root.add_child(game)
			var goal_side: int = -1 if control == "bot" else 1
			var target := Vector3(side * 3.85, 0.24, goal_side * (game.GOAL_Z + 0.3))
			if control == "bot":
				game.difficulty = "medio"
				game.shot_power = 1.0
				game.launch_ball(target, 0.75, goal_side)
				game.keeper_rng.seed = 7192
				game.move_keeper_for_attack(1.0)
			else:
				game.start_defense()
				game.defense_countdown = 999.0
				game.launch_ball(target, game.AI_SHOT_FLIGHT_TIME, goal_side)
				await create_timer(0.35).timeout
				if control == "mouse":
					game.dive_home_keeper_from_screen(game.defense_screen_from_target(Vector2(side * 3.85, 0.3)))
				else:
					var height_key := InputEventKey.new()
					height_key.pressed = true
					height_key.keycode = KEY_S
					game._unhandled_input(height_key)
					var side_key := InputEventKey.new()
					side_key.pressed = true
					side_key.keycode = KEY_LEFT if side < 0 else KEY_RIGHT
					game._unhandled_input(side_key)
			while not game.resolved:
				await physics_frame
			check(game.status_label.text.contains("Atajada"), "%s: debe alcanzar el ángulo al ras del suelo del lado %s; obtuvo %s" % [control, side, game.status_label.text])
			print("%s %s: %s" % [control, side, game.status_label.text])
			for sound in game.match_audio.get_children():
				if sound is AudioStreamPlayer or sound is AudioStreamPlayer3D:
					sound.stop()
			game.queue_free()
			await process_frame
	print("PASS: dos ángulos al ras del césped, bot, mouse y teclado" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures else 0)
