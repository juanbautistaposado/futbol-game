extends RefCounted

# These original clips reuse the rig's authored save poses, keeping glove reach
# intact while fitting anticipation, landing and recovery to the physical dive.
const LIBRARY := &"keeper_motion"
const READY := &"keeper_motion/Ready"
const DIVE_LENGTH := 1.59
const POSE_BONES := ["Chest", "UpperArm.L", "UpperArm.R", "Forearm.L", "Forearm.R", "Thigh.L", "Thigh.R", "Shin.L", "Shin.R"]
const GloveMotion = preload("res://keeper_glove_motion.gd")

static func install(player: AnimationPlayer, rig: Skeleton3D) -> void:
	if player.has_animation_library(LIBRARY):
		return
	var library := AnimationLibrary.new()
	library.add_animation(&"Ready", _ready_clip(player, rig))
	for clip_name in ["SaveLeft", "SaveRight", "SaveLowLeft", "SaveLowRight"]:
		library.add_animation(clip_name, _dive_clip(player, rig, clip_name))
		library.add_animation(clip_name.replace("Save", "Hold"), _dive_clip(player, rig, clip_name, true))
	library.add_animation(&"SaveCentre", _centre_clip(player, rig, false))
	library.add_animation(&"SaveCentreLow", _centre_clip(player, rig, true))
	player.add_animation_library(LIBRARY, library)
	for clip_name in ["SaveLeft", "SaveRight", "SaveLowLeft", "SaveLowRight", "SaveCentre", "SaveCentreLow"]:
		player.set_blend_time(StringName("keeper_motion/" + clip_name), &"Catch", 0.08)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	player.set_blend_time(&"Catch", READY, 0.16)

static func save_clip(direction: float, height: float, lateral: bool) -> StringName:
	if not lateral:
		return &"keeper_motion/SaveCentreLow" if height < 0.85 else &"keeper_motion/SaveCentre"
	var clip := "SaveLeft" if direction < 0.0 else "SaveRight"
	if height < 0.85:
		clip = "SaveLowLeft" if direction < 0.0 else "SaveLowRight"
	return StringName("keeper_motion/" + clip)

static func hold_clip(save: StringName) -> StringName:
	return StringName(str(save).replace("Save", "Hold"))

static func _rotation(player: AnimationPlayer, rig: Skeleton3D, clip_name: StringName, bone: String, time: float) -> Quaternion:
	var clip := player.get_animation(clip_name)
	var path := NodePath("FootballerRig/Skeleton3D:" + bone)
	var track := clip.find_track(path, Animation.TYPE_ROTATION_3D)
	if track >= 0:
		return clip.rotation_track_interpolate(track, time)
	return rig.get_bone_rest(rig.find_bone(bone)).basis.get_rotation_quaternion()

static func _ready_rotation(player: AnimationPlayer, rig: Skeleton3D, bone: String) -> Quaternion:
	var neutral := _rotation(player, rig, &"Idle", bone, 0.0)
	if bone.begins_with("Thigh.") or bone.begins_with("Shin."):
		# Each supporting leg loads identically; the keeper starts flexed rather
		# than borrowing the striker's almost straight-legged idle.
		var source: StringName = &"SaveLeft" if bone.ends_with(".R") else &"SaveRight"
		var flexed := neutral.slerp(_rotation(player, rig, source, bone, 0.30), 0.85)
		return flexed * Quaternion(Vector3.RIGHT, 0.25) if bone.begins_with("Shin.") else flexed
	if bone.begins_with("UpperArm."):
		return neutral.slerp(_rotation(player, rig, &"Catch", bone, 0.23), 0.60)
	if bone.begins_with("Forearm."):
		return neutral * Quaternion(Vector3.RIGHT, 0.75)
	if bone == "Chest":
		return neutral * Quaternion(Vector3.RIGHT, 0.085)
	return neutral

static func _track(clip: Animation, bone: String, times: Array[float], poses: Array[Quaternion]) -> void:
	var track := clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(track, NodePath("FootballerRig/Skeleton3D:" + bone))
	for index in range(times.size()):
		clip.rotation_track_insert_key(track, times[index], poses[index])

static func _hips_track(clip: Animation, rig: Skeleton3D, times: Array[float], drops: Array[float]) -> void:
	# Root's imported basis maps the hips' local Z to standing height. Lower
	# the pelvis with the bent knees so the boots retain their ground contact.
	var neutral := rig.get_bone_rest(rig.find_bone("Hips")).origin
	var track := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(track, NodePath("FootballerRig/Skeleton3D:Hips"))
	for index in range(times.size()):
		clip.position_track_insert_key(track, times[index], neutral - Vector3(0.0, 0.0, drops[index]))

static func _complete_pose(clip: Animation, player: AnimationPlayer, rig: Skeleton3D, source: StringName) -> void:
	# Every clip owns the whole rig. Otherwise a wrist, foot or finger channel
	# from Catch/Celebrate could survive after returning to the ready stance.
	for bone_index in range(rig.get_bone_count()):
		var bone := rig.get_bone_name(bone_index)
		var path := NodePath("FootballerRig/Skeleton3D:" + bone)
		var rest := rig.get_bone_rest(bone_index)
		if clip.find_track(path, Animation.TYPE_ROTATION_3D) < 0:
			_track(clip, bone, [0.0, clip.length],
				[_rotation(player, rig, source, bone, 0.0), _rotation(player, rig, source, bone, 0.0)])
		if clip.find_track(path, Animation.TYPE_POSITION_3D) < 0:
			var track := clip.add_track(Animation.TYPE_POSITION_3D)
			clip.track_set_path(track, path)
			clip.position_track_insert_key(track, 0.0, rest.origin)
			clip.position_track_insert_key(track, clip.length, rest.origin)
		var scale_track := clip.add_track(Animation.TYPE_SCALE_3D)
		clip.track_set_path(scale_track, path)
		clip.scale_track_insert_key(scale_track, 0.0, rest.basis.get_scale())
		clip.scale_track_insert_key(scale_track, clip.length, rest.basis.get_scale())

static func _ready_clip(player: AnimationPlayer, rig: Skeleton3D) -> Animation:
	var clip := Animation.new()
	clip.length = 1.8
	clip.loop_mode = Animation.LOOP_LINEAR
	for bone: String in POSE_BONES:
		var ready := _ready_rotation(player, rig, bone)
		var breathing := ready
		if bone == "Chest":
			breathing = ready * Quaternion(Vector3.RIGHT, 0.018)
		elif bone.begins_with("UpperArm."):
			breathing = ready * Quaternion(Vector3.RIGHT, 0.012)
		_track(clip, bone, [0.0, 0.9, 1.8], [ready, breathing, ready])
	_hips_track(clip, rig, [0.0, 1.8], [0.065, 0.065])
	_complete_pose(clip, player, rig, &"Idle")
	GloveMotion.author(clip, rig, "Ready")
	return clip

static func _dive_clip(player: AnimationPlayer, rig: Skeleton3D, source: String, holding := false) -> Animation:
	var clip := Animation.new()
	clip.length = DIVE_LENGTH
	for bone: String in POSE_BONES:
		var ready := _ready_rotation(player, rig, bone)
		var load_leg := _rotation(player, rig, source, bone, 0.10)
		var extended := _rotation(player, rig, source, bone, 0.30)
		var late_flight := extended.slerp(ready, 0.12)
		var landing := extended.slerp(ready, 0.38)
		var recovery := ready
		if bone.begins_with("UpperArm.") or bone.begins_with("Forearm."):
			# Fold the elbows after reaching, bracing the landing before rising.
			var guard := _rotation(player, rig, &"Catch", bone, 0.23)
			landing = extended.slerp(guard, 0.55)
			recovery = guard.slerp(ready, 0.65)
		elif bone.begins_with("Thigh.") or bone.begins_with("Shin."):
			landing = extended.slerp(load_leg, 0.65)
			recovery = load_leg.slerp(ready, 0.35)
		elif bone == "Chest":
			landing = ready * Quaternion(Vector3.RIGHT, 0.20)
			recovery = ready * Quaternion(Vector3.RIGHT, 0.14)
		_track(clip, bone, [0.0, 0.09, 0.25, 0.45, 0.77, 1.01, 1.21, DIVE_LENGTH],
			[ready, load_leg, extended, extended, late_flight, landing, recovery, ready])
	_hips_track(clip, rig, [0.0, 0.09, 0.25, 0.77, 1.01, 1.21, DIVE_LENGTH],
		[0.065, 0.02, 0.0, 0.0, 0.02, 0.065, 0.065])
	_complete_pose(clip, player, rig, source)
	GloveMotion.author(clip, rig, source, holding)
	_author_landing_legs(clip, rig, source)
	_ground_finish(clip, 1.21)
	return clip

static func _ground_finish(clip: Animation, time: float) -> void:
	# Keep the gathered side pose after impact instead of blending every bone
	# back into Ready. AnimationPlayer preserves this last pose until reset.
	for track in range(clip.get_track_count()):
		var pose: Variant
		match clip.track_get_type(track):
			Animation.TYPE_ROTATION_3D:
				pose = clip.rotation_track_interpolate(track, time)
			Animation.TYPE_POSITION_3D:
				pose = clip.position_track_interpolate(track, time)
			Animation.TYPE_SCALE_3D:
				pose = clip.scale_track_interpolate(track, time)
			_:
				continue
		for key in range(clip.track_get_key_count(track) - 1, -1, -1):
			if clip.track_get_key_time(track, key) >= time:
				clip.track_remove_key(track, key)
		clip.track_insert_key(track, time, pose)
		clip.track_insert_key(track, clip.length, pose)

static func _author_landing_legs(clip: Animation, rig: Skeleton3D, source: String) -> void:
	# Author shortened, asymmetric hip-to-ankle chains without scaling bones.
	# The upper leg gathers first in flight; contact is absorbed by flexed
	# knees. The lower leg then opens for the knee-supported recovery.
	var direction := -1.0 if source.ends_with("Left") else 1.0
	var times: Array[float] = [0.09, 0.77, 1.01, 1.21, 1.40]
	if source.begins_with("SaveLow"):
		times.insert(1, 0.25)
	for time: float in times:
		var local: Array[Transform3D] = []
		for index in range(rig.get_bone_count()):
			var path := NodePath("FootballerRig/Skeleton3D:" + rig.get_bone_name(index))
			local.append(Transform3D(Basis(clip.rotation_track_interpolate(clip.find_track(path, Animation.TYPE_ROTATION_3D), time)),
				clip.position_track_interpolate(clip.find_track(path, Animation.TYPE_POSITION_3D), time)))
		for side in ["L", "R"]:
			var thigh := rig.find_bone("Thigh." + side)
			var shin := rig.find_bone("Shin." + side)
			var foot := rig.find_bone("Foot." + side)
			var global := GloveMotion._globals(rig, local)
			var hip: Vector3 = global[thigh].origin
			var leading: bool = signf(hip.x) == direction
			var support := is_equal_approx(time, 1.21)
			var ankle_drop := (0.56 if leading else 0.58) if support else (0.52 if leading else 0.40)
			var depth := (0.10 if leading else -0.25) if support else (-0.30 if leading else -0.04)
			if time < 0.10:
				# Root lowering must be accompanied by actual knee flexion, so
				# the loading feet do not sink before the impulse starts.
				ankle_drop = 0.70 if leading else 0.73
				depth = 0.02 if leading else -0.10
			elif time < 0.30:
				# Clear the trailing leg behind the low save, instead of lifting
				# both feet using the apex of a high dive.
				ankle_drop = 0.70 if leading else 0.58
				depth = 0.06 if leading else -0.27
			elif time > 1.30:
				# Plant the outside boot before completely unfolding the leg.
				# Interpolating directly to Ready made its sole sink mid-rise.
				ankle_drop = 0.70 if leading else 0.74
				depth = 0.05
			var target := hip + Vector3(signf(hip.x) * 0.09, -ankle_drop, depth)
			if time > 0.30 and time < 1.0:
				target = global[foot].origin.lerp(target, 0.65 if leading else 0.90)
			var axis := (target - hip).normalized()
			var length_a: float = hip.distance_to(global[shin].origin)
			var length_b: float = global[shin].origin.distance_to(global[foot].origin)
			var distance: float = hip.distance_to(target)
			var along := (length_a * length_a - length_b * length_b + distance * distance) / (2.0 * distance)
			var pole := Vector3(signf(hip.x) * 0.15, 0.0, 1.0)
			pole = (pole - axis * pole.dot(axis)).normalized()
			var knee := hip + axis * along + pole * sqrt(maxf(length_a * length_a - along * along, 0.0))
			GloveMotion._rotate(rig, local, thigh, Quaternion((global[shin].origin - hip).normalized(), (knee - hip).normalized()))
			global = GloveMotion._globals(rig, local)
			GloveMotion._rotate(rig, local, shin, Quaternion((global[foot].origin - global[shin].origin).normalized(), (target - global[shin].origin).normalized()))
			for bone in [thigh, shin]:
				var track := clip.find_track(NodePath("FootballerRig/Skeleton3D:" + rig.get_bone_name(bone)), Animation.TYPE_ROTATION_3D)
				clip.rotation_track_insert_key(track, time, local[bone].basis.get_rotation_quaternion())

static func _centre_clip(player: AnimationPlayer, rig: Skeleton3D, low: bool) -> Animation:
	var clip := Animation.new()
	clip.length = DIVE_LENGTH
	for bone: String in POSE_BONES:
		var ready := _ready_rotation(player, rig, bone)
		var gathering := _rotation(player, rig, &"Catch", bone, 0.23)
		if bone.begins_with("Thigh.") or bone.begins_with("Shin."):
			gathering = ready if not low else _rotation(player, rig,
				&"SaveLeft" if bone.ends_with(".R") else &"SaveRight", bone, 0.10)
		_track(clip, bone, [0.0, 0.09, 0.25, 0.77, 1.01, 1.21, DIVE_LENGTH],
			[ready, ready, gathering, gathering, gathering, gathering.slerp(ready, 0.6), ready])
	_hips_track(clip, rig, [0.0, 0.25, 1.01, DIVE_LENGTH], [0.065, 0.0, 0.0, 0.065])
	_complete_pose(clip, player, rig, &"Catch")
	GloveMotion.author(clip, rig, "SaveCentreLow" if low else "SaveCentre")
	_ground_finish(clip, 1.01)
	return clip
