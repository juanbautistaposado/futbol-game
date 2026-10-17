extends SceneTree

const Keeper = preload("res://keeper.gd")
const STEP := 1.0 / 60.0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func exercise(field_side: int) -> void:
	var keeper := Keeper.new()
	keeper.configure(field_side, Color.GREEN)
	root.add_child(keeper)
	keeper.set_process(false)
	keeper.goalkeeper_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for height in [0.65, 1.25, 1.60]:
		for caught in [false, true]:
			for direction in [-1.0, 1.0]:
				keeper.reset_pose()
				keeper.dive(direction * 2.8, height)
				keeper.motion.pause()
				for frame in range(1, 121):
					var arc: Tween = keeper.dive_arc
					if keeper.motion and keeper.motion.is_valid():
						keeper.motion.custom_step(STEP)
					if arc and arc.is_valid():
						arc.custom_step(STEP)
					if keeper.dive_arc and keeper.dive_arc.is_valid():
						keeper.dive_arc.pause()
					keeper.goalkeeper_animation.advance(STEP)
					if caught and frame == 27:
						keeper.catch_pose(-1)
					if caught and frame > 27:
						check(keeper.held_ball_position(-1).y >= 0.22, "La pelota retenida debe mantenerse sobre el suelo mientras cae")
					if caught and frame >= 36:
						var ball_position := keeper.held_ball_position(-1)
						for side in ["L", "R"]:
							var hand := keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("Hand." + side))
							var palm := hand * Vector3(0.0, 0.12, 0.0)
							check(hand.basis.z.normalized().dot((ball_position - palm).normalized()) > 0.65, "Las palmas retenedoras deben mirar hacia la pelota")
							check(palm.distance_to(ball_position) < 0.30, "La pelota debe tocar ambos guantes, no quedar suspendida entre muñecas")
				await process_frame
				check(keeper.position.y < 0.60 and absf(keeper.rotation.z) > deg_to_rad(65),
					"El final lateral debe quedar bajo y de costado, no volver a estar parado")
				check(keeper.busy and keeper.goalkeeper_animation.current_animation != "keeper_motion/Ready",
					"La postura final debe conservarse hasta el próximo tiro")
				check(keeper.dive_reach_collision.disabled, "El alcance de intercepción debe retirarse al terminar")
				print("GROUND_FINISH h=%.2f caught=%s dir=%+.0f y=%.3f roll=%.1f" % [height, caught, direction, keeper.position.y, rad_to_deg(keeper.rotation.z)])
	keeper.reset_pose()
	check(not keeper.busy and keeper.position.is_equal_approx(keeper.rest_position) and keeper.rotation == Vector3.ZERO,
		"El siguiente tiro debe restaurar la posición inicial")
	check(keeper.goalkeeper_animation.current_animation == "keeper_motion/Ready", "El reinicio debe restaurar la guardia abierta")
	keeper.free()

func run() -> void:
	for field_side in [-1, 1]:
		await exercise(field_side)
	print("PASS: caída completa, captura sobre el suelo y final bajo hasta el reinicio" if failures == 0 else "FAIL: %d fallos" % failures)
	quit(1 if failures else 0)
