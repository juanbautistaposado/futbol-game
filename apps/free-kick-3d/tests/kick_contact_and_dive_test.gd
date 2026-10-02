extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func bone_world(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	skeleton.force_update_all_bone_transforms()
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin

func kick_foot(game: Node) -> Vector3:
	var skeleton: Skeleton3D = game.kicker.footballer_visual.get_node("FootballerRig/Skeleton3D")
	return bone_world(skeleton, "Foot.R")

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-kick-contact-test.cfg"
	root.add_child(game)
	for direction in [-1, 1]:
		if direction == 1:
			game.start_defense()
		var ball_position: Vector3 = game.ball.global_position
		var contact := {"distance": -1.0}
		game.kicker.kick(func() -> void: contact.distance = kick_foot(game).distance_to(ball_position))
		await create_timer(0.55).timeout
		check(contact.distance >= 0.0 and contact.distance < 0.42, "El pie debe tocar la pelota antes de lanzarla (dirección %d): %.2f m" % [direction, contact.distance])
	var keeper = game.away_keeper
	for direction in [-1, 1]:
		keeper.reset_pose()
		keeper.dive(direction * 2.8, 1.25, 0.0)
		await create_timer(0.35).timeout
		var hand: Vector3 = bone_world(keeper.skeleton, "Hand.L" if direction < 0 else "Hand.R")
		var other_hand: Vector3 = bone_world(keeper.skeleton, "Hand.R" if direction < 0 else "Hand.L")
		var head: Vector3 = bone_world(keeper.skeleton, "Head")
		check(hand.y > 1.15 and direction * (hand.x - head.x) > 0.3, "El guante debe estirarse hacia el tiro a la altura de la pelota")
		check(other_hand.y > 1.05 and direction * (other_hand.x - head.x) > 0.15, "Los dos guantes deben acompañar la estirada")
		check(keeper.position.y > keeper.rest_position.y + 0.1, "El cuerpo debe despegar durante la estirada")
	print("PASS: patada sincronizada y estirada del arquero" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
