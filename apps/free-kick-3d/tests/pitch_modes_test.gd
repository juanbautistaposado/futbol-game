extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-size-preview.cfg"
	root.add_child(game)
	assert(is_equal_approx(game.ball.position.z,-28.5))
	await create_timer(0.1).timeout
	assert(absf(game.ball.position.z+28.5)<0.05)
	game.start_attack()
	assert(is_equal_approx(game.ball.position.z,-28.5))
	await create_timer(0.1).timeout
	assert(absf(game.ball.position.z+28.5)<0.05)
	game.start_defense()
	assert(is_equal_approx(game.ball.position.z,28.5))
	await create_timer(0.1).timeout
	assert(absf(game.ball.position.z-28.5)<0.05)
	print("PASS: tiro libre y defensa mantienen la posición de la pelota")
	quit()
