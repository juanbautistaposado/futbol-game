extends SceneTree

const Kicker = preload("res://kicker.gd")
const Motion = preload("res://striker_animation.gd")
const Model = preload("res://assets/footballer/meshy_striker.glb")

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

# Calculate evaluated FK directly: skeleton render caches update later in frame.
func pose(player: AnimationPlayer, skeleton: Skeleton3D, clip: StringName, time: float) -> Array[Transform3D]:
	player.play(clip, 0.0)
	player.seek(time, true)
	player.pause()
	var result: Array[Transform3D] = []
	for bone in range(skeleton.get_bone_count()):
		var parent := skeleton.get_bone_parent(bone)
		result.append(result[parent] * skeleton.get_bone_pose(bone) if parent >= 0 else skeleton.get_bone_pose(bone))
	return result

func run() -> void:
	var kicker := Kicker.new()
	root.add_child(kicker)
	var skeleton: Skeleton3D = kicker.footballer_visual.get_node("FootballerRig/Skeleton3D")
	var player := kicker.footballer_animation
	var baseline := Model.instantiate()
	root.add_child(baseline)
	var baseline_player: AnimationPlayer = baseline.get_node("AnimationPlayer")
	var baseline_rig: Skeleton3D = baseline.get_node("FootballerRig/Skeleton3D")
	check(not baseline_player.has_animation(Motion.CLIP), "Runtime motion must not mutate the shared imported library")
	check(skeleton.get_bone_count() == 53, "Animation must preserve the skinned rig")
	var original := pose(baseline_player, baseline_rig, &"Kick", Motion.CONTACT_TIME)
	var impact := pose(player, skeleton, Motion.CLIP, Motion.CONTACT_TIME)
	var right := skeleton.find_bone("Foot.R")
	var left := skeleton.find_bone("Foot.L")
	var ready := pose(player, skeleton, Kicker.READY_CLIP, 0.0)
	check(ready[left].origin.z - ready[right].origin.z > .25, "Waiting stance must visibly stagger the left boot ahead of the right")
	check(ready[skeleton.find_bone("Hips")].origin.y < original[skeleton.find_bone("Hips")].origin.y - .04, "Preparation must lower the pelvis to flex both knees")
	for side in ["L", "R"]:
		var hand := skeleton.find_bone("Hand." + side)
		check(ready[hand].origin.y < 1.03 and absf(ready[hand].origin.z) < .15, "Waiting arms must hang naturally beside the hips")
	for time in [0.0, .7, 1.4, 2.1, Motion.READY_DURATION]:
		var sample := pose(player, skeleton, Kicker.READY_CLIP, time)
		check(sample[left].origin.distance_to(ready[left].origin) < .001 and sample[right].origin.distance_to(ready[right].origin) < .001, "Breathing must keep both ready boots on the grass")
	for time in [0.0, Motion.DURATION]:
		var boundary := pose(player, skeleton, Motion.CLIP, time)
		for bone in range(skeleton.get_bone_count()):
			check(boundary[bone].origin.distance_to(ready[bone].origin) < .002, "Strike boundaries must return to the waiting stance without a position jump: %s" % skeleton.get_bone_name(bone))
			check(boundary[bone].basis.get_rotation_quaternion().angle_to(ready[bone].basis.get_rotation_quaternion()) < .003, "Strike boundaries must match waiting rotations: %s" % skeleton.get_bone_name(bone))
	check(impact[right].origin.distance_to(original[right].origin) < .001, "Right boot must preserve the calibrated .48 second contact")
	check(impact[right].basis.get_rotation_quaternion().angle_to(original[right].basis.get_rotation_quaternion()) < .001, "Boot orientation must preserve contact")
	var first_step := pose(player, skeleton, Motion.CLIP, .08)
	var second_step := pose(player, skeleton, Motion.CLIP, .17)
	check(first_step[right].origin.y > first_step[left].origin.y + .10, "Approach must lift the right foot during its first step")
	check(second_step[left].origin.y > second_step[right].origin.y + .10, "Approach must alternate the left foot on its second step")
	var support_origin := pose(player, skeleton, Motion.CLIP, .36)[left].origin
	for frame in range(36, 65):
		var sample := pose(player, skeleton, Motion.CLIP, float(frame) / 100.0)
		check(sample[left].origin.distance_to(support_origin) < .004, "Support foot must stay planted through the strike and early follow-through")
	var follow := pose(player, skeleton, Motion.CLIP, .68)
	check(follow[right].origin.y > .4, "Follow-through must carry the striking boot above the grass")
	var before: Array[Quaternion] = []
	for frame in range(117):
		pose(player, skeleton, Motion.CLIP, float(frame) / 100.0)
		for bone in range(skeleton.get_bone_count()):
			var rotation := skeleton.get_bone_pose_rotation(bone)
			if frame > 0:
				check(rotation.angle_to(before[bone]) < .35, "No rotation may snap between sampled frames: %s at %.2f" % [skeleton.get_bone_name(bone), float(frame)/100.0])
			if frame == 0:
				before.append(rotation)
			else:
				before[bone] = rotation
	for tick_rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = tick_rate
		for direction in [-1, 1]:
			var ball := Vector3(0.0, .22, 0.0)
			kicker.reset_pose(ball, direction)
			var contact := {"count": 0, "time": -1.0, "position": Vector3.ZERO}
			kicker.kick(func() -> void:
				contact.count += 1
				contact.time = player.current_animation_position
				var evaluated: Array[Transform3D] = []
				for bone in range(skeleton.get_bone_count()):
					var parent := skeleton.get_bone_parent(bone)
					evaluated.append(evaluated[parent] * skeleton.get_bone_pose(bone) if parent >= 0 else skeleton.get_bone_pose(bone))
				contact.position = skeleton.global_transform * evaluated[right].origin)
			check(player.current_animation == Motion.CLIP, "Gameplay must select the new striking clip")
			await create_timer(.58).timeout
			check(contact.count == 1, "Strike callback must fire exactly once at all physics rates")
			check(absf(contact.time - Motion.CONTACT_TIME) <= 1.0 / tick_rate + .001, "Physics animation and callback must share the .48 contact timeline")
			check(contact.position.distance_to(ball) < .42, "New motion must contact the ball in both pitch directions")
			await create_timer(.75).timeout
			check(player.current_animation == Kicker.READY_CLIP, "Completed strike must recover to ready, not hold the follow-through")
	Engine.physics_ticks_per_second = 60
	var cancelled := {"count": 0}
	kicker.kick(func() -> void: cancelled.count += 1)
	await create_timer(.18).timeout
	kicker.reset_pose(Vector3(0.0,.22,0.0),-1)
	await create_timer(.45).timeout
	check(cancelled.count == 0, "Reset must cancel a pending kick without releasing the ball")
	print("PASS: staggered preparation, grounded breathing, seamless boundaries, alternating steps, planted support, preserved impact and physics synchronization" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
