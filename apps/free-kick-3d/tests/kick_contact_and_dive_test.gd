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
		var support_side := "R" if direction < 0 else "L"
		var support_local: Vector3 = keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("Hand." + support_side)).origin
		var support_shoulder: Vector3 = keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("UpperArm." + support_side)).origin
		check(other_hand.y > 1.05 and other_hand.y < hand.y - 0.05 and -direction * (support_local.x - support_shoulder.x) >= -0.10,
			"El rechazo con una mano debe dejar el apoyo bajo y en su propio lado, fuera de la cara")
		check(keeper.position.y > keeper.rest_position.y + 0.1, "El cuerpo debe despegar durante la estirada")
	print("PASS: patada sincronizada y estirada del arquero" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
