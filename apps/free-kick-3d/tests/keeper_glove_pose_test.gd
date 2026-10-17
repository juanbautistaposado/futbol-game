extends SceneTree

# This checks the visible Meshy gloves, whose surface is weighted to Hand,
# rather than the imported finger joints (which currently have no influence).
const Keeper = preload("res://keeper.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func sample(keeper: Node, clip: String, time: float) -> void:
	keeper.goalkeeper_animation.play(clip, 0.0)
	keeper.goalkeeper_animation.advance(0.0)
	keeper.goalkeeper_animation.seek(time, true)
	keeper.skeleton.force_update_all_bone_transforms()

func hand_pose(keeper: Node, side: String) -> Transform3D:
	return keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("Hand." + side))

func check_presented_palm(keeper: Node, side: String, minimum: float, context: String) -> void:
	# Actual exported glove: fingers run along Hand-local +Y, palm lies in XY,
	# and its thickness lies along Z. Evaluate in skeleton space so turning
	# either keeper to face the other goal does not change this condition.
	var palm := hand_pose(keeper, side).basis.z.normalized()
	check(palm.dot(Vector3.BACK) >= minimum,
		"%s: guante %s debe presentar la palma al tiro (avance %.3f, mínimo %.2f)" %
		[context, side, palm.z, minimum])
	var fingers := hand_pose(keeper, side).basis.y.normalized()
	var wrist := hand_pose(keeper, side).origin
	var elbow: Vector3 = keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("Forearm." + side)).origin
	var forearm := (wrist - elbow).normalized()
	check(fingers.dot(forearm) >= 0.65,
		"%s: guante %s debe seguir el antebrazo sin doblar la muñeca (alineación %.3f)" %
		[context, side, fingers.dot(forearm)])

func run() -> void:
	var keeper := Keeper.new()
	root.add_child(keeper)
	keeper.configure(-1, Color.GREEN)
	keeper.set_process(false)
	keeper.goalkeeper_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	sample(keeper, "keeper_motion/Ready", 0.0)
	var ready_hands: Dictionary = {}
	for side in ["L", "R"]:
		check_presented_palm(keeper, side, 0.60, "Guardia")
		var hand := hand_pose(keeper, side)
		ready_hands[side] = hand
		var elbow: Vector3 = keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("Forearm." + side)).origin
		var outward := -1.0 if side == "L" else 1.0
		check(hand.origin.y > 1.38 and hand.origin.y < 1.52 and absf(hand.origin.x) > 0.62,
			"Antes de tirarse, los guantes deben estar bien abiertos a la altura de los hombros como la referencia")
		var shoulder: Vector3 = keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("UpperArm." + side)).origin
		var elbow_flexion := (elbow - shoulder).angle_to(hand.origin - elbow)
		check(elbow_flexion > 0.35 and elbow_flexion < 1.60, "La guardia debe tener codos suaves, sin bloquear el brazo")
		check(absf(hand.basis.y.y) < 0.25 and hand.basis.y.x * outward > 0.70,
			"Los dedos abiertos deben apuntar mayormente hacia los lados como la referencia")
	for clip in ["Ready", "SaveLeft", "SaveRight", "SaveLowLeft", "SaveLowRight", "SaveCentre", "SaveCentreLow"]:
		for time in [0.0, keeper.goalkeeper_animation.get_animation("keeper_motion/" + clip).length]:
			sample(keeper, "keeper_motion/" + clip, time)
			for side in ["L", "R"]:
				var hand := hand_pose(keeper, side)
				var ready: Transform3D = ready_hands[side]
				if is_zero_approx(time) or clip == "Ready":
					check(hand.origin.distance_to(ready.origin) < 0.0001 and hand.basis.get_rotation_quaternion().angle_to(ready.basis.get_rotation_quaternion()) < 0.001,
						"Cada atajada debe empezar con los guantes abiertos de la guardia")
				else:
					check(hand.origin.distance_to(ready.origin) > 0.15, "El final debe recoger los guantes en vez de volver a la guardia inicial")
		for time in [0.25, 0.45, 0.70]:
			sample(keeper, "keeper_motion/" + clip, time)
			for side in ["L", "R"]:
				check_presented_palm(keeper, side, 0.60, "%s %.2f s" % [clip, time])
		var previous: Dictionary = {}
		var length: float = keeper.goalkeeper_animation.get_animation("keeper_motion/" + clip).length
		for frame in range(ceili(length * 60.0) + 1):
			sample(keeper, "keeper_motion/" + clip, minf(float(frame) / 60.0, length))
			for side in ["L", "R"]:
				# A solver may satisfy authored keys while quaternion interpolation
				# twists the wrist between them, especially during low recovery.
				check_presented_palm(keeper, side, 0.60, "%s %.3f s" % [clip, float(frame) / 60.0])
				for pair in [["Forearm", "UpperArm"], ["Hand", "Forearm"]]:
					var child: int = keeper.skeleton.find_bone(pair[0] + "." + side)
					var parent: int = keeper.skeleton.find_bone(pair[1] + "." + side)
					var actual_length: float = keeper.skeleton.get_bone_global_pose(child).origin.distance_to(keeper.skeleton.get_bone_global_pose(parent).origin)
					var rest_length: float = keeper.skeleton.get_bone_rest(child).origin.length()
					check(absf(actual_length - rest_length) < 0.0001,
						"Resolver las manos debe conservar la longitud de %s.%s" % [pair[0], side])
				for part in ["UpperArm", "Forearm", "Hand"]:
					var name: String = part + "." + side
					var rotation: Quaternion = keeper.skeleton.get_bone_pose_rotation(keeper.skeleton.find_bone(name))
					if previous.has(name):
						check(rotation.angle_to(previous[name]) < 0.30, "La orientación no debe saltar en %s/%s: %.2f s" % [clip, name, float(frame) / 60.0])
					previous[name] = rotation
		if clip.begins_with("SaveLow"):
			sample(keeper, "keeper_motion/" + clip, 0.45)
			var left := hand_pose(keeper, "L")
			var right := hand_pose(keeper, "R")
			var left_palm_center := left.origin + left.basis.y * 0.12
			var right_palm_center := right.origin + right.basis.y * 0.12
			check(left_palm_center.distance_to(right_palm_center) > 0.18,
				"Los guantes bajos deben tener espacio entre las palmas, sin superponerse")
	# Both directions must preserve handedness and mirrored orientations.
	for clips in [["SaveLeft", "SaveRight"], ["SaveLowLeft", "SaveLowRight"]]:
		sample(keeper, "keeper_motion/" + clips[0], 0.45)
		var left_palm := hand_pose(keeper, "L").basis.z.normalized()
		var left_tip := hand_pose(keeper, "L").basis.y.normalized()
		sample(keeper, "keeper_motion/" + clips[1], 0.45)
		var right_palm := hand_pose(keeper, "R").basis.z.normalized()
		var right_tip := hand_pose(keeper, "R").basis.y.normalized()
		check(Vector3(-left_palm.x, left_palm.y, left_palm.z).distance_to(right_palm) < 0.01,
			"Las palmas principales deben reflejarse entre atajadas izquierda/derecha")
		check(Vector3(-left_tip.x, left_tip.y, left_tip.z).distance_to(right_tip) < 0.01,
			"Los dedos principales deben conservar su orientación simétrica")
	print("PASS: palmas frontales, muñecas alineadas, longitudes, continuidad, espacio y simetría a 60 Hz" if failures == 0 else "FAIL: %d comprobaciones de guantes" % failures)
	keeper.free()
	quit(1 if failures else 0)
