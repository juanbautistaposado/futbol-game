extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	scene.save_path = "/tmp/futbol-shot-test-unused.cfg"
	root.add_child(scene)
	await process_frame
	var meter = scene.shot_meter
	meter.begin()
	meter.advance(0.4)
	var single_step: float = meter.indicator
	meter.begin()
	for i in range(40):
		meter.advance(0.01)
	check(is_equal_approx(single_step, meter.indicator), "Timing must not depend on frame rate")
	meter.indicator = 0.5
	check(is_equal_approx(meter.accuracy(), 1.0), "Center must give perfect accuracy")
	scene.aim_x = 0.8
	var precise: Vector3 = scene.player_shot_target(meter.accuracy())
	meter.indicator = 0.0
	var missed: Vector3 = scene.player_shot_target(meter.accuracy())
	check(missed.x > precise.x + 2.0, "Poor timing must physically deviate the target")
	meter.lock_shot()
	var locked: float = meter.indicator
	meter.advance(2.0)
	check(meter.indicator == locked, "Released meter must stop moving")
	var keeper = scene.away_keeper
	keeper.dive(2.4, 1.3, 0.25)
	await create_timer(0.15).timeout
	check(absf(keeper.position.x) < 0.01, "Keeper must respect reaction delay")
	await create_timer(0.48).timeout
	check(keeper.position.x > 1.0 and absf(keeper.rotation.z) > 0.3, "Keeper must move and tilt during dive")
	keeper.reset_pose()
	await create_timer(0.4).timeout
	check(keeper.position.distance_to(keeper.rest_position) < 0.01, "Reset must cancel the prior dive")
	check(keeper.rotation == Vector3.ZERO, "Reset must restore upright collider")
	scene.start_attack()
	meter.begin()
	meter.indicator = 0.5
	scene.shot_power = 0.8
	scene.fire_player_shot()
	check(scene.ball_in_flight and not meter.active, "Shot should launch and lock the meter")
	for i in range(600):
		if scene.phase == scene.Phase.DEFEND:
			break
		await create_timer(0.01).timeout
	check(scene.phase == scene.Phase.DEFEND, "Shot must transition to defense")
	check(not meter.visible, "Attack meter must hide in defense")
	scene.dive_home_keeper(-1)
	check(scene.home_keeper.busy, "Player defense must use the dive animation")
	for i in range(1000):
		if scene.phase == scene.Phase.ATTACK:
			break
		await create_timer(0.01).timeout
	check(scene.turn == 2 and scene.phase == scene.Phase.ATTACK, "Defense must advance to the next turn")
	check(meter.visible and not meter.active, "Next turn must reset the meter")
	print("PASS: precisión, desvío, reacción, estirada, reinicio y ciclo de turnos" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
