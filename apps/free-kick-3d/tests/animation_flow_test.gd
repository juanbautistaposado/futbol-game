extends SceneTree
## Gameplay contracts across pause, cancellation and independent character instances.

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-animation-flow-test.cfg"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var contacts := {"count": 0}
	game.kicker.kick(func() -> void: contacts.count += 1)
	await create_timer(0.20).timeout
	paused = true
	var position_before: Vector3 = game.kicker.position
	var animation_before: float = game.kicker.footballer_animation.current_animation_position
	await create_timer(0.35).timeout
	assert(contacts.count == 0, "Pausar antes del golpe debe mantener la pelota quieta")
	assert(game.kicker.position.is_equal_approx(position_before), "La carrera debe congelarse durante pausa")
	assert(is_equal_approx(game.kicker.footballer_animation.current_animation_position, animation_before))
	paused = false
	await create_timer(1.10).timeout
	assert(contacts.count == 1, "Reanudar debe liberar exactamente un remate")
	game.kicker.reset_pose(game.ball.global_position, -1)
	game.kicker.kick(func() -> void: contacts.count += 1)
	await create_timer(0.15).timeout
	game.kicker.reset_pose(game.ball.global_position, 1)
	await create_timer(0.65).timeout
	assert(contacts.count == 1, "Cambiar de turno debe cancelar el contacto pendiente")
	var keeper = game.away_keeper
	keeper.reset_pose()
	keeper.dive(2.8, 1.55)
	await create_timer(0.32).timeout
	paused = true
	position_before = keeper.position
	animation_before = keeper.goalkeeper_animation.current_animation_position
	var rotation_before: Vector3 = keeper.rotation
	await create_timer(0.25).timeout
	assert(keeper.position.is_equal_approx(position_before), "La estirada debe congelarse durante pausa")
	assert(keeper.rotation.is_equal_approx(rotation_before))
	assert(is_equal_approx(keeper.goalkeeper_animation.current_animation_position, animation_before))
	paused = false
	keeper.reset_pose()
	keeper.dive(-2.8, 0.65, 0.30)
	await create_timer(0.10).timeout
	keeper.reset_pose()
	await create_timer(0.55).timeout
	assert(not keeper.busy and keeper.position.is_equal_approx(keeper.rest_position), "Reset debe cancelar una reacción diferida")
	assert(keeper.dive_reach_collision.disabled, "Reset debe retirar el alcance físico temporal")
	assert(not game.home_keeper.busy, "La animación de un arquero no debe activar al otro")
	game.queue_free()
	print("PASS: pausa, contacto único, cancelación de turnos y reacción diferida")
	quit()
