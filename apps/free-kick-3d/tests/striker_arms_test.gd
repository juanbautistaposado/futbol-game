extends SceneTree

const Kicker = preload("res://kicker.gd")
const Human = preload("res://footballer_model.gd")
const Original = preload("res://assets/footballer/footballer_v3.glb")
const PROTECTED_BONES := ["Root", "Hips", "Spine", "SpineMid", "Chest", "Neck", "Head", "Thigh.R", "Shin.R", "Foot.R", "Thigh.L", "Shin.L", "Foot.L"]

func _initialize() -> void:
	call_deferred("run")

func bone_position(rig: Skeleton3D, name: String) -> Vector3:
	return rig.get_bone_global_pose(rig.find_bone(name)).origin

func pose(animation: AnimationPlayer, rig: Skeleton3D, clip: String, time: float) -> void:
	animation.play(clip)
	animation.seek(time, true)
	animation.pause()
	rig.force_update_all_bone_transforms()

func run() -> void:
	var kicker := Kicker.new()
	root.add_child(kicker)
	kicker.apply_identity(Human.MESHY_STRIKER_INDEX, "PLAYER", 10)
	var rig: Skeleton3D = kicker.footballer_visual.get_node("FootballerRig/Skeleton3D")
	var baseline := Original.instantiate()
	root.add_child(baseline)
	var original_rig: Skeleton3D = baseline.get_node("FootballerRig/Skeleton3D")
	var original_animation: AnimationPlayer = baseline.get_node("AnimationPlayer")
	assert(rig.get_bone_count() == 53)
	for clip in ["Idle", "Kick"]:
		assert(is_equal_approx(kicker.footballer_animation.get_animation(clip).length, original_animation.get_animation(clip).length))
	for sample in [["Idle", 0.0], ["Kick", 0.0], ["Kick", .2], ["Kick", .48], ["Kick", .68], ["Kick", .93]]:
		pose(kicker.footballer_animation, rig, sample[0], sample[1])
		pose(original_animation, original_rig, sample[0], sample[1])
		for name in PROTECTED_BONES:
			var current := rig.get_bone_global_pose(rig.find_bone(name))
			var previous := original_rig.get_bone_global_pose(original_rig.find_bone(name))
			assert(current.origin.distance_to(previous.origin) < .00001, "La corrección de brazos no puede mover %s" % name)
			assert(current.basis.get_rotation_quaternion().angle_to(previous.basis.get_rotation_quaternion()) < .001, "La corrección de brazos no puede girar %s" % name)
	pose(kicker.footballer_animation, rig, "Idle", 0.0)
	var ready_left := bone_position(rig, "Hand.L")
	for side in ["R", "L"]:
		var upper := bone_position(rig, "Forearm." + side) - bone_position(rig, "UpperArm." + side)
		var forearm := bone_position(rig, "Hand." + side) - bone_position(rig, "Forearm." + side)
		assert(upper.angle_to(forearm) > .3, "El jugador listo debe tener codos suaves, no brazos rígidos rectos")
	pose(kicker.footballer_animation, rig, "Kick", .48)
	var left := bone_position(rig, "Hand.L")
	var right := bone_position(rig, "Hand.R")
	assert(left.y > ready_left.y + .1, "El brazo contralateral sube como contrapeso")
	assert(absf(left.x) > absf(right.x) + .15, "La patada debe mostrar balance asimétrico")
	var previous_rotations: Dictionary = {}
	for frame in range(30):
		pose(kicker.footballer_animation, rig, "Kick", float(frame) / 30.0)
		for side in ["R", "L"]:
			for kind in ["UpperArm", "Forearm", "Hand"]:
				var name: String = kind + "." + side
				var rotation := rig.get_bone_pose_rotation(rig.find_bone(name))
				if previous_rotations.has(name):
					assert(rotation.angle_to(previous_rotations[name]) < .45, "El gesto no debe saltar entre cuadros en %s" % name)
				previous_rotations[name] = rotation
	print("PASS: codos flexionados, contrapeso asimétrico, 53 huesos y piernas/torso/contacto conservados")
	quit()
