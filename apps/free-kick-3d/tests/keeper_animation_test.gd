extends SceneTree

const Keeper = preload("res://keeper.gd")
const KeeperAnimation = preload("res://keeper_animation.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func bone_world(keeper: Node3D, bone: String) -> Vector3:
	keeper.skeleton.force_update_all_bone_transforms()
	return keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone(bone)).origin

func advance_frames(count: int) -> void:
	for frame in range(count):
		await physics_frame

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-keeper-animation-test.cfg"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	var keeper: Keeper = game.away_keeper
	var other_keeper: Keeper = game.home_keeper
	await process_frame
	check(keeper.goalkeeper_animation.current_animation == KeeperAnimation.READY, "El arquero debe esperar en guardia")
	check(keeper.goalkeeper_animation.get_animation(KeeperAnimation.READY) != other_keeper.goalkeeper_animation.get_animation(KeeperAnimation.READY), "Cada arquero debe tener clips propios sin alterar el recurso compartido")
	var thigh := bone_world(keeper, "Thigh.R")
	var knee := bone_world(keeper, "Shin.R")
	var ankle := bone_world(keeper, "Foot.R")
	check((knee - thigh).angle_to(ankle - knee) > deg_to_rad(25.0), "La guardia debe flexionar las rodillas visiblemente")
	check(ankle.y > 0.10 and ankle.y < 0.18, "La pelvis debe acompañar la flexión sin hacer flotar las botas")
	var waiting_hand := bone_world(keeper, "Hand.R")
	var waiting_shoulder := bone_world(keeper, "UpperArm.R")
	check(absf(waiting_hand.x - bone_world(keeper, "Head").x) > 0.65 and absf(waiting_hand.y - waiting_shoulder.y) < 0.06,
		"Los guantes deben esperar bien abiertos lateralmente a la altura de los hombros")
	check(waiting_hand.z - waiting_shoulder.z > 0.05,
		"La guardia lateral debe mantener los guantes ligeramente delante del hombro")
	for direction in [-1, 1]:
		keeper.reset_pose()
		keeper.dive(direction * 2.8, 1.25, 0.20)
		await advance_frames(7)
		check(keeper.position.is_equal_approx(keeper.rest_position), "La anticipación debe respetar el retardo físico")
		check(keeper.goalkeeper_animation.current_animation == KeeperAnimation.READY, "El arquero debe conservar la guardia mientras reacciona")
		await advance_frames(26)
		var hand := bone_world(keeper, "Hand.L" if direction < 0 else "Hand.R")
		var other_hand := bone_world(keeper, "Hand.R" if direction < 0 else "Hand.L")
		var head := bone_world(keeper, "Head")
		check(hand.y > 1.15 and direction * (hand.x - head.x) > 0.3, "El guante principal debe alcanzar la pelota")
		var support_side := "R" if direction < 0 else "L"
		var support_local := keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("Hand." + support_side)).origin
		var support_shoulder := keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("UpperArm." + support_side)).origin
		check(other_hand.y > 1.05 and other_hand.y < hand.y - 0.05 and -direction * (support_local.x - support_shoulder.x) >= -0.10,
			"El rechazo con una mano debe mantener el apoyo debajo del principal y junto a su propio hombro")
		check(hand.distance_to(other_hand) > 0.10, "La estirada debe conservar el alcance asimétrico de los brazos")
		check(not keeper.dive_reach_collision.disabled, "La física debe conservar el alcance de atajada durante la estirada")
		var paused_position := keeper.position
		var paused_hand := hand
		paused = true
		await create_timer(0.15, true).timeout
		check(keeper.position.is_equal_approx(paused_position), "Pausa debe detener la trayectoria")
		check(bone_world(keeper, "Hand.L" if direction < 0 else "Hand.R").distance_to(paused_hand) < 0.001, "Pausa debe detener los huesos junto con el cuerpo")
		paused = false
		await advance_frames(38)
		check(keeper.busy and keeper.goalkeeper_animation.current_animation.begins_with("keeper_motion/Save"), "La caída debe mantener su clip y no volver prematuramente a Idle")
		check(keeper.goalkeeper_animation.current_animation_position > 0.9, "El clip debe continuar durante la absorción del impacto")
		await advance_frames(42)
		check(keeper.busy and keeper.goalkeeper_animation.current_animation != KeeperAnimation.READY and keeper.position.y < 0.60 and absf(keeper.rotation.z) > deg_to_rad(65), "La atajada debe terminar baja y de costado hasta el siguiente tiro")
		check(keeper.dive_reach_collision.disabled, "La recuperación debe retirar el alcance adicional")
	keeper.reset_pose()
	keeper.dive(0.0, 1.25)
	await advance_frames(18)
	check(keeper.goalkeeper_animation.current_animation == "keeper_motion/SaveCentre", "Los tiros al cuerpo requieren una parada central")
	check(absf(keeper.rotation.z) < 0.001, "Una parada central debe mantener el cuerpo erguido")
	keeper.catch_pose(-1)
	await advance_frames(12)
	var midpoint := (bone_world(keeper, "Hand.L") + bone_world(keeper, "Hand.R")) * 0.5
	check(keeper.held_ball_position(-1).distance_to(midpoint) < 0.001, "La pelota retenida debe seguir ambos guantes durante Catch")
	keeper.reset_pose()
	keeper.dive(-2.5, 0.7)
	await advance_frames(12)
	check(keeper.goalkeeper_animation.current_animation == "keeper_motion/SaveLowLeft", "Una pelota baja debe seleccionar la variante baja")
	keeper.reset_pose()
	await advance_frames(27)
	check(keeper.position.is_equal_approx(keeper.rest_position) and keeper.rotation == Vector3.ZERO, "Reset debe cancelar impulso, arco y recuperación")
	check(keeper.goalkeeper_animation.current_animation == KeeperAnimation.READY and keeper.dive_reach_collision.disabled, "Reset debe restaurar guardia y colisión")
	keeper.celebrate(keeper.rest_position)
	await advance_frames(16)
	keeper.reset_pose()
	other_keeper.reset_pose()
	for bone_index in range(keeper.skeleton.get_bone_count()):
		check(keeper.skeleton.get_bone_pose_rotation(bone_index).is_equal_approx(other_keeper.skeleton.get_bone_pose_rotation(bone_index)), "Reset debe limpiar todos los canales después de celebrar: " + keeper.skeleton.get_bone_name(bone_index))
		check(keeper.skeleton.get_bone_pose_position(bone_index).is_equal_approx(other_keeper.skeleton.get_bone_pose_position(bone_index)), "Reset debe limpiar posiciones después de celebrar: " + keeper.skeleton.get_bone_name(bone_index))
	print("PASS: guardia, reacción, alcance, pausa, aterrizaje, recuperación, parada central y reset" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
