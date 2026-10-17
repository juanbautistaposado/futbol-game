extends RefCounted
## Authored football motion: two approach steps, plant, strike and recovery.
## EA's composed striking / power-shot preparation guide the phases; no EA clips
## or motion data are used. Work on a private library, preserving imported assets.
const LIBRARY := &"athlete"
const CLIP := &"athlete/MatchStrike"
const CONTACT_TIME := 0.48
const DURATION := 1.16
const SAMPLE_RATE := 100.0
const READY_DURATION := 2.8
const READY_LEFT_FOOT := Vector3(-.205, .079, .14)
const READY_RIGHT_FOOT := Vector3(.205, .079, -.16)
const MODIFIED_BONES := ["Hips", "Spine", "Chest", "Head", "Thigh.L", "Shin.L", "Foot.L", "Thigh.R", "Shin.R", "Foot.R", "UpperArm.L", "UpperArm.R", "Forearm.L", "Forearm.R", "Hand.L", "Hand.R", "thumb_01_r"]

static func install(player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	if player.has_animation(CLIP):
		return
	var source := player.get_animation("Kick")
	var idle := player.get_animation("Idle")
	var clip := Animation.new()
	clip.length = DURATION
	var indices: Dictionary = {}
	var tracks: Dictionary = {}
	var rest: Array[Transform3D] = []
	for bone in range(skeleton.get_bone_count()):
		indices[skeleton.get_bone_name(bone)] = bone
		rest.append(skeleton.get_bone_rest(bone))
	for name in MODIFIED_BONES:
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("FootballerRig/Skeleton3D:" + name))
		tracks[name] = track
	var hips_track := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(hips_track, NodePath("FootballerRig/Skeleton3D:Hips"))
	# Pelvis rotation/height need reset channels in the private idle, so switching
	# identities, celebrating or cancelling a kick cannot leave a residual pose.
	var ready := _ready_clip(skeleton, rest, source, idle, indices)
	var ready_pose := _ready_pose(skeleton, rest, source, indices, 0.0)
	var celebration := _with_resets(player.get_animation("Celebrate"), rest, indices)
	var support := _source_foot(skeleton, rest, source, indices, "Foot.L", CONTACT_TIME)
	for frame in range(roundi(DURATION * SAMPLE_RATE) + 1):
		var time := float(frame) / SAMPLE_RATE
		var locals: Array[Transform3D] = rest.duplicate()
		var source_time := _source_time(time, source.length)
		for track in range(source.get_track_count()):
			if source.track_get_type(track) != Animation.TYPE_ROTATION_3D:
				continue
			var name := String(source.track_get_path(track).get_subname(0))
			if indices.has(name):
				locals[indices[name]].basis = Basis(source.rotation_track_interpolate(track, source_time))
		var globals := _globals(skeleton, locals)
		# Gather the source support/contact pose before adding torso weight shifts.
		var right_foot := globals[indices["Foot.R"]].origin
		var left_foot := globals[indices["Foot.L"]].origin
		var load := _envelope(time, 0.16, 0.29, CONTACT_TIME)
		var follow := _envelope(time, CONTACT_TIME, 0.68, 1.10)
		var run := _envelope(time, 0.0, 0.12, 0.28)
		# World axes are converted to each bone's parent space. This rig's local
		# axes differ from Godot's world axes, so local Euler offsets are unsafe.
		_rotate_world(skeleton, locals, indices.Hips, Quaternion(Vector3.UP, -0.10 * load + 0.13 * follow))
		_rotate_world(skeleton, locals, indices.Spine, Quaternion(Vector3.UP, -0.08 * load + 0.10 * follow))
		_rotate_world(skeleton, locals, indices.Chest, Quaternion(Vector3.RIGHT, 0.07 * run) * Quaternion(Vector3.UP, -0.12 * load + 0.15 * follow))
		globals = _globals(skeleton, locals)
		var parent := skeleton.get_bone_parent(indices.Hips)
		var parent_basis := globals[parent].basis if parent >= 0 else Basis.IDENTITY
		locals[indices.Hips].origin += parent_basis.inverse() * Vector3(0.0, -0.025 * run - 0.023 * load, 0.0)
		if time < 0.28:
			# Alternating steps instead of translating a held backswing pose.
			var handoff := _smooth(0.24, 0.28, time)
			right_foot = _step_foot(time, true).lerp(right_foot,handoff)
			left_foot = _step_foot(time, false).lerp(left_foot,handoff)
			_solve_leg(skeleton, locals, indices, "R", right_foot)
			_solve_leg(skeleton, locals, indices, "L", left_foot)
			var arm_swing := sin(time / 0.24 * TAU) * run
			_rotate_world(skeleton, locals, indices["UpperArm.L"], Quaternion(Vector3.RIGHT, -0.25 * arm_swing))
			_rotate_world(skeleton, locals, indices["UpperArm.R"], Quaternion(Vector3.RIGHT, 0.25 * arm_swing))
		else:
			# Preserve the right boot's authored impact exactly. Pelvis/torso
			# additions are zero at .48; support IK affects only the left chain.
			var plant := _smooth(0.28, 0.36, time) * (1.0 - _smooth(0.66, 0.94, time))
			_solve_leg(skeleton, locals, indices, "L", left_foot.lerp(support, plant))
			if load > 0.0:
				_solve_leg(skeleton, locals, indices, "R", right_foot)
		# Match the waiting stance at both boundaries. Only the first .10 s and
		# recovery after .94 s change, leaving the calibrated strike untouched.
		var ready_weight := 1.0 - _smooth(0.0, .10, time) + _smooth(.94, DURATION, time)
		for name in MODIFIED_BONES:
			var bone: int = indices[name]
			locals[bone].basis = Basis(locals[bone].basis.get_rotation_quaternion().slerp(ready_pose[bone].basis.get_rotation_quaternion(), ready_weight))
		locals[indices.Hips].origin = locals[indices.Hips].origin.lerp(ready_pose[indices.Hips].origin, ready_weight)
		for name in MODIFIED_BONES:
			clip.rotation_track_insert_key(tracks[name], time, locals[indices[name]].basis.get_rotation_quaternion())
		clip.position_track_insert_key(hips_track, time, locals[indices.Hips].origin)
	var library := AnimationLibrary.new()
	library.add_animation(&"MatchStrike", clip)
	library.add_animation(&"Ready", ready)
	library.add_animation(&"Celebrate", celebration)
	player.add_animation_library(LIBRARY, library)

static func _ready_clip(skeleton: Skeleton3D, rest: Array[Transform3D], source: Animation, idle: Animation, indices: Dictionary) -> Animation:
	var ready := _with_resets(idle, rest, indices)
	ready.length = READY_DURATION
	var tracks: Dictionary = {}
	for name in MODIFIED_BONES:
		var track := _track_for(ready, name, Animation.TYPE_ROTATION_3D)
		while ready.track_get_key_count(track) > 0:
			ready.track_remove_key(track, 0)
		tracks[name] = track
	var hips := _track_for(ready, "Hips", Animation.TYPE_POSITION_3D)
	while ready.track_get_key_count(hips) > 0:
		ready.track_remove_key(hips, 0)
	for frame in range(roundi(READY_DURATION * SAMPLE_RATE) + 1):
		var time := float(frame) / SAMPLE_RATE
		var locals := _ready_pose(skeleton, rest, source, indices, time / READY_DURATION * TAU)
		for name in MODIFIED_BONES:
			ready.rotation_track_insert_key(tracks[name], time, locals[indices[name]].basis.get_rotation_quaternion())
		ready.position_track_insert_key(hips, time, locals[indices.Hips].origin)
	return ready

static func _ready_pose(skeleton: Skeleton3D, rest: Array[Transform3D], source: Animation, indices: Dictionary, phase: float) -> Array[Transform3D]:
	var locals: Array[Transform3D] = rest.duplicate()
	for track in range(source.get_track_count()):
		if source.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			var name := String(source.track_get_path(track).get_subname(0))
			if indices.has(name):
				locals[indices[name]].basis = Basis(source.rotation_track_interpolate(track, 0.0))
	var breath := sin(phase)
	_rotate_world(skeleton, locals, indices.Hips, Quaternion(Vector3.UP, -.035))
	_rotate_world(skeleton, locals, indices.Spine, Quaternion(Vector3.RIGHT, .055 + .002 * breath))
	_rotate_world(skeleton, locals, indices.Chest, Quaternion(Vector3.RIGHT, .035 + .003 * breath))
	_rotate_world(skeleton, locals, indices.Head, Quaternion(Vector3.RIGHT, -.055))
	var globals := _globals(skeleton, locals)
	var parent := skeleton.get_bone_parent(indices.Hips)
	locals[indices.Hips].origin += globals[parent].basis.inverse() * Vector3(0.0, -.052 + .0015 * breath, 0.0)
	# A split stance gives the run-up a visible intention while both boots stay
	# on the turf throughout the breathing loop. It is not the striking plant.
	_solve_leg(skeleton, locals, indices, "L", READY_LEFT_FOOT)
	_solve_leg(skeleton, locals, indices, "R", READY_RIGHT_FOOT)
	for side in ["L", "R"]:
		var sign_x := -1.0 if side == "L" else 1.0
		_relax_arm(skeleton, locals, indices, side, Vector3(sign_x * .30, .97 + .0015 * breath, .07))
	return locals

static func _relax_arm(skeleton: Skeleton3D, locals: Array[Transform3D], indices: Dictionary, side: String, target: Vector3) -> void:
	var upper: int = indices["UpperArm." + side]
	var lower: int = indices["Forearm." + side]
	var hand: int = indices["Hand." + side]
	var globals := _globals(skeleton, locals)
	var shoulder := globals[upper].origin
	var length_a := shoulder.distance_to(globals[lower].origin)
	var length_b := globals[lower].origin.distance_to(globals[hand].origin)
	var axis := (target - shoulder).normalized()
	var distance := clampf(shoulder.distance_to(target), .05, length_a + length_b - .001)
	var along := (length_a * length_a - length_b * length_b + distance * distance) / (2.0 * distance)
	var guide := Vector3(signf(shoulder.x) * .3, 0.0, -.7)
	var pole := (guide - axis * guide.dot(axis)).normalized()
	var elbow := shoulder + axis * along + pole * sqrt(maxf(length_a * length_a - along * along, 0.0))
	var wrist := shoulder + axis * distance
	_rotate_world(skeleton, locals, upper, Quaternion((globals[lower].origin - shoulder).normalized(), (elbow - shoulder).normalized()))
	globals = _globals(skeleton, locals)
	_rotate_world(skeleton, locals, lower, Quaternion((globals[hand].origin - globals[lower].origin).normalized(), (wrist - globals[lower].origin).normalized()))

static func _with_resets(source: Animation, rest: Array[Transform3D], indices: Dictionary) -> Animation:
	var result := source.duplicate(true) as Animation
	result.loop_mode = Animation.LOOP_LINEAR
	for name in MODIFIED_BONES:
		if _track_for(result, name, Animation.TYPE_ROTATION_3D) < 0:
			var track := result.add_track(Animation.TYPE_ROTATION_3D)
			result.track_set_path(track, NodePath("FootballerRig/Skeleton3D:" + name))
			result.rotation_track_insert_key(track, 0.0, rest[indices[name]].basis.get_rotation_quaternion())
	if _track_for(result, "Hips", Animation.TYPE_POSITION_3D) < 0:
		var hips := result.add_track(Animation.TYPE_POSITION_3D)
		result.track_set_path(hips, NodePath("FootballerRig/Skeleton3D:Hips"))
		result.position_track_insert_key(hips, 0.0, rest[indices.Hips].origin)
	return result

static func _source_time(time: float, source_length: float) -> float:
	if time < 0.18:
		return 0.0
	if time < 0.34:
		return lerpf(0.0, 0.23, _smooth(0.18, 0.34, time))
	if time < CONTACT_TIME:
		return lerpf(0.23, CONTACT_TIME, (time - 0.34) / (CONTACT_TIME - 0.34))
	if time < 0.76:
		return time
	return lerpf(0.76, source_length, _smooth(0.76, DURATION, time))

static func _step_foot(time: float, right: bool) -> Vector3:
	var side := 1.0 if right else -1.0
	var times := [0.0, 0.08, 0.17, 0.24, 0.28]
	var targets: Array[Vector3]
	if right:
		targets = [Vector3(.213, .079, .012), Vector3(.21, .22, .29), Vector3(.22, .085, -.12), Vector3(.23, .17, -.25), Vector3(.23, .17, -.25)]
	else:
		targets = [Vector3(-.213, .079, .012), Vector3(-.21, .08, -.16), Vector3(-.21, .23, .30), Vector3(-.218, .09, -.13), Vector3(-.218, .09, -.13)]
	for i in range(times.size() - 1):
		if time <= times[i + 1]:
			return targets[i].lerp(targets[i + 1], _smooth(times[i], times[i + 1], time))
	return Vector3(side * .218, .09, -.13)

static func _source_foot(skeleton: Skeleton3D, rest: Array[Transform3D], source: Animation, indices: Dictionary, name: String, time: float) -> Vector3:
	var locals: Array[Transform3D] = rest.duplicate()
	for track in range(source.get_track_count()):
		if source.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			var bone := String(source.track_get_path(track).get_subname(0))
			locals[indices[bone]].basis = Basis(source.rotation_track_interpolate(track, time))
	return _globals(skeleton, locals)[indices[name]].origin

static func _globals(skeleton: Skeleton3D, locals: Array[Transform3D]) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone in range(locals.size()):
		var parent := skeleton.get_bone_parent(bone)
		result.append(result[parent] * locals[bone] if parent >= 0 else locals[bone])
	return result

static func _rotate_world(skeleton: Skeleton3D, locals: Array[Transform3D], bone: int, rotation: Quaternion) -> void:
	var globals := _globals(skeleton, locals)
	var parent := skeleton.get_bone_parent(bone)
	var parent_basis := globals[parent].basis if parent >= 0 else Basis.IDENTITY
	locals[bone].basis = parent_basis.inverse() * Basis(rotation) * globals[bone].basis

static func _solve_leg(skeleton: Skeleton3D, locals: Array[Transform3D], indices: Dictionary, side: String, target: Vector3) -> void:
	var thigh: int = indices["Thigh." + side]
	var shin: int = indices["Shin." + side]
	var foot: int = indices["Foot." + side]
	var globals := _globals(skeleton, locals)
	var foot_basis := globals[foot].basis
	var hip := globals[thigh].origin
	var upper_length := hip.distance_to(globals[shin].origin)
	var lower_length := globals[shin].origin.distance_to(globals[foot].origin)
	var axis := (target - hip).normalized()
	var distance := clampf(hip.distance_to(target), .05, upper_length + lower_length - .001)
	var along := (upper_length * upper_length - lower_length * lower_length + distance * distance) / (2.0 * distance)
	var pole := (Vector3.BACK - axis * Vector3.BACK.dot(axis)).normalized()
	var knee := hip + axis * along + pole * sqrt(maxf(upper_length * upper_length - along * along, 0.0))
	var actual_target := hip + axis * distance
	_rotate_world(skeleton, locals, thigh, Quaternion((globals[shin].origin - hip).normalized(), (knee - hip).normalized()))
	globals = _globals(skeleton, locals)
	_rotate_world(skeleton, locals, shin, Quaternion((globals[foot].origin - globals[shin].origin).normalized(), (actual_target - globals[shin].origin).normalized()))
	globals = _globals(skeleton, locals)
	locals[foot].basis = globals[shin].basis.inverse() * foot_basis

static func _track_for(animation: Animation, bone: String, type: int) -> int:
	return animation.find_track(NodePath("FootballerRig/Skeleton3D:" + bone), type)

static func _smooth(start: float, end: float, time: float) -> float:
	var t := clampf((time - start) / (end - start), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func _envelope(time: float, start: float, peak: float, end: float) -> float:
	return _smooth(start, peak, time) * (1.0 - _smooth(peak, end, time))
