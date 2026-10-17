extends RefCounted
## Solve the arm before orienting the visible rigid glove. Meshy glove fingers
## follow Hand-local +Y and curl towards +Z; finger bones have no mesh influence.

static func author(clip: Animation, rig: Skeleton3D, save_name := "", holding := false) -> void:
	var replacements: Dictionary = {}
	var indices: Dictionary = {}
	var arm_transport: Dictionary = {}
	for bone in range(rig.get_bone_count()):
		indices[rig.get_bone_name(bone)] = bone
	for side in ["L", "R"]:
		for part in ["UpperArm", "Forearm"]:
			replacements[part + "." + side] = []
	# Solve independent wrist lanes at the action's phases and carry their
	# bone roll between poses. Imported twists made interpolated elbows sweep
	# through the opposite arm; palms are baked at physics cadence below.
	var times: Array[float] = []
	for track in range(clip.get_track_count()):
		for key in range(clip.track_get_key_count(track)):
			var time := clip.track_get_key_time(track, key)
			if not times.has(time):
				times.append(time)
	if save_name.ends_with("Left") or save_name.ends_with("Right"):
		# The supporting arm follows the principal, rather than overtaking it
		# between the guard and full reach keys.
		times.append(0.34)
	times.sort()
	for time in times:
		var local: Array[Transform3D] = []
		for bone in range(rig.get_bone_count()):
			var name := rig.get_bone_name(bone)
			var path := NodePath("FootballerRig/Skeleton3D:" + name)
			var pose := rig.get_bone_rest(bone)
			var rotation := clip.find_track(path, Animation.TYPE_ROTATION_3D)
			var position := clip.find_track(path, Animation.TYPE_POSITION_3D)
			if rotation >= 0:
				pose.basis = Basis(clip.rotation_track_interpolate(rotation, time))
			if position >= 0:
				pose.origin = clip.position_track_interpolate(position, time)
			local.append(pose)
		for side in ["L", "R"]:
			var current := _globals(rig, local)
			var wrist: Vector3 = current[indices["Hand." + side]].origin
			# Match the supplied keeper reference: broad arms around shoulder
			# height, soft elbows, and open gloves pointing towards either side.
			var shoulder: Vector3 = current[indices["UpperArm." + side]].origin
			var ready_target := shoulder + Vector3(signf(shoulder.x) * 0.46, -0.02, 0.08)
			var ready_weight := 1.0 if save_name == "Ready" else (1.0 - smoothstep(0.09, 0.25, time)) + smoothstep(1.21, clip.length, time)
			wrist = wrist.lerp(ready_target, ready_weight)
			var pole := Vector3.ZERO
			if save_name.ends_with("Left") or save_name.ends_with("Right"):
				var direction := -1.0 if save_name.ends_with("Left") else 1.0
				var reach_weight := smoothstep(0.09, 0.25, time) * (1.0 - smoothstep(0.77, 1.21, time))
				if side == ("L" if direction < 0.0 else "R"):
					# Keep the reaching elbow outside its own shoulder instead of
					# folding it into the opposite arm's path through the chest.
					pole = Vector3(direction, -0.45, -0.10).lerp(Vector3(direction * 0.15, -1.0, -0.20), reach_weight)
					if not save_name.begins_with("SaveLow"):
						# Extend towards the shot with nearly the same world height,
						# instead of keeping the glove folded beside the forehead.
						wrist += Vector3(direction * 0.08, 0.07, 0.0) * reach_weight
				else:
					# A one-hand rejection keeps the secondary glove beside its
					# own shoulder and below the face, with an outboard elbow.
					if not save_name.begins_with("SaveLow"):
						wrist = ready_target.lerp(Vector3(-direction * 0.18, 1.35, 0.28), smoothstep(0.09, 0.34, time))
						wrist = wrist.lerp(ready_target, smoothstep(1.21, clip.length, time))
					pole = Vector3(-direction, -0.45, -0.10).lerp(Vector3(-direction * 0.80, -0.55, 0.70), reach_weight)
			if save_name.begins_with("SaveLow"):
				# A low dive needs the lower glove behind the shot and the other
				# above it. The old wrists were only 15 cm apart: whole rigid
				# gloves overlapped after the palms were turned towards the ball.
				var direction := -1.0 if save_name.ends_with("Left") else 1.0
				var leading: bool = side == ("L" if direction < 0.0 else "R")
				var target := Vector3(direction * 0.48, 1.62, 0.36) if leading else Vector3(-direction * 0.05, 1.55, 0.45)
				var reach_weight := smoothstep(0.09, 0.25, time) * (1.0 - smoothstep(0.77, 1.21, time))
				wrist = wrist.lerp(target, reach_weight)
			if save_name.ends_with("Left") or save_name.ends_with("Right"):
				# After interception, gather the gloves beside the chest for the
				# forearm-supported side landing. Leaving the reaching wrist fully
				# lateral would drive it through the turf as the body rolls over.
				var direction := -1.0 if save_name.ends_with("Left") else 1.0
				var leading: bool = side == ("L" if direction < 0.0 else "R")
				var landing_target := Vector3(direction * 0.28 if leading else -direction * 0.28, 1.20 if leading else 1.22, 0.46 if leading else 0.42)
				var landing_weight := smoothstep(0.77, 1.01, time) * (1.0 - smoothstep(1.21, clip.length, time))
				wrist = wrist.lerp(landing_target, landing_weight)
			if holding:
				# Gather both gloves around a retained ball in front of the chest
				# while the same root trajectory completes the side landing.
				var held_target := Vector3(signf(shoulder.x) * 0.20, 1.30, 0.50)
				wrist = wrist.lerp(held_target, smoothstep(0.25, 0.45, time))
			var arm_pole := Vector3(signf(shoulder.x), -0.45, -0.10) if pole == Vector3.ZERO else pole
			pole = arm_pole.lerp(Vector3(0.0, -0.20, -1.0), ready_weight)
			if holding:
				pole = pole.lerp(Vector3(signf(shoulder.x) * 0.35, -1.0, 0.05), smoothstep(0.25, 0.45, time))
			_solve_arm(rig, local, indices, side, wrist, pole, arm_transport if save_name.ends_with("Left") or save_name.ends_with("Right") else {}, time, clip.length)
			for part in ["UpperArm", "Forearm"]:
				var name: String = part + "." + side
				replacements[name].append(local[indices[name]].basis.get_rotation_quaternion())
	for name: String in replacements:
		var track := clip.find_track(NodePath("FootballerRig/Skeleton3D:" + name), Animation.TYPE_ROTATION_3D)
		for key in range(clip.track_get_key_count(track) - 1, -1, -1):
			clip.track_remove_key(track, key)
		for key in range(times.size()):
			clip.rotation_track_insert_key(track, times[key], replacements[name][key])
	# The loading key belongs to the legs. Carry the raised arms continuously
	# from guard to reach instead of dipping both open hands back at the thighs.
	if save_name != "Ready":
		for side in ["L", "R"]:
			for part in ["UpperArm", "Forearm"]:
				var track := clip.find_track(NodePath("FootballerRig/Skeleton3D:" + part + "." + side), Animation.TYPE_ROTATION_3D)
				var start := clip.rotation_track_interpolate(track, 0.0)
				var reach := clip.rotation_track_interpolate(track, 0.25)
				clip.rotation_track_insert_key(track, 0.09, start.slerp(reach, 0.09 / 0.25))
	_bake_palms(clip, rig, indices, holding)

static func _bake_palms(clip: Animation, rig: Skeleton3D, indices: Dictionary, holding := false) -> void:
	var rotations: Dictionary = {"L": [], "R": []}
	var forearm_rotations: Dictionary = {"L": [], "R": []}
	var previous_forearm: Dictionary = {}
	var times: Array[float] = []
	for frame in range(ceili(clip.length * 60.0) + 1):
		var time := minf(float(frame) / 60.0, clip.length)
		times.append(time)
		var local: Array[Transform3D] = []
		for bone in range(rig.get_bone_count()):
			var path := NodePath("FootballerRig/Skeleton3D:" + rig.get_bone_name(bone))
			var pose := rig.get_bone_rest(bone)
			pose.basis = Basis(clip.rotation_track_interpolate(clip.find_track(path, Animation.TYPE_ROTATION_3D), time))
			pose.origin = clip.position_track_interpolate(clip.find_track(path, Animation.TYPE_POSITION_3D), time)
			local.append(pose)
		var global := _globals(rig, local)
		for side in ["L", "R"]:
			var hand: int = indices["Hand." + side]
			var forearm: int = indices["Forearm." + side]
			var direction := (global[hand].origin - global[forearm].origin).normalized()
			# Transport the forearm's roll along its direction, keeping the wrist
			# target intact. Imported low-save poses otherwise spin the sleeve
			# nearly half a turn and require the glove to counter-spin instantly.
			var forearm_basis: Basis = global[forearm].basis
			if previous_forearm.has(side):
				var previous: Basis = previous_forearm[side]
				forearm_basis = Basis(Quaternion(previous.y.normalized(), direction)) * previous
				if time > 1.21 and clip.loop_mode == Animation.LOOP_NONE:
					forearm_basis = forearm_basis.slerp(global[forearm].basis, smoothstep(1.21, clip.length, time))
			previous_forearm[side] = forearm_basis
			var upper: int = indices["UpperArm." + side]
			forearm_rotations[side].append((global[upper].basis.inverse() * forearm_basis).get_rotation_quaternion())
			# Allow some finger depth when the forearm points directly towards
			# the shot; the palm still faces forward while the wrist stays aligned.
			var depth := clampf(direction.z, -0.72, 0.72)
			var planar := Vector3(direction.x, direction.y, 0.0)
			var outward := -1.0 if side == "L" else 1.0
			# Preserve the open guard, but reduce outward finger bias when an
			# elbow folds outboard and the forearm naturally points inward.
			# Otherwise the rigid glove bends sideways against that forearm.
			var bias := 0.20 * clampf(1.0 + direction.x * outward, 0.20, 1.0)
			planar += Vector3(outward, 0.0, 0.0) * bias
			if planar.length_squared() < 0.0001:
				planar = Vector3.UP
			var fingers := planar.normalized() * sqrt(1.0 - depth * depth) + Vector3.BACK * depth
			var palm := (Vector3.BACK - fingers * fingers.z).normalized()
			var basis := Basis(fingers.cross(palm).normalized(), fingers, palm)
			if holding and time > 0.25:
				# Roll the palms inward to grip the ball. Elbows below the wrists
				# keep fingers following the forearms instead of bending sideways.
				var grip_palm := Vector3(-outward, 0.0, 0.0)
				var grip_fingers := (direction - grip_palm * direction.dot(grip_palm)).normalized()
				var grip_basis := Basis(grip_fingers.cross(grip_palm).normalized(), grip_fingers, grip_palm)
				basis = basis.slerp(grip_basis, smoothstep(0.25, 0.45, time))
			rotations[side].append((forearm_basis.inverse() * basis).get_rotation_quaternion())
	for side in ["L", "R"]:
		# Keep roll continuous when a forearm passes close to the shot axis.
		# Both end poses stay exact; the wrist shares a fast turn over nearby
		# frames rather than making a visible snap in one frame.
		for key in range(1, times.size() - 1):
			var previous: Quaternion = rotations[side][key - 1]
			var rotation: Quaternion = rotations[side][key]
			var angle := previous.angle_to(rotation)
			if angle > 0.28:
				rotations[side][key] = previous.slerp(rotation, 0.28 / angle)
		for key in range(times.size() - 2, 0, -1):
			var following: Quaternion = rotations[side][key + 1]
			var rotation: Quaternion = rotations[side][key]
			var angle := following.angle_to(rotation)
			if angle > 0.28:
				rotations[side][key] = following.slerp(rotation, 0.28 / angle)
		var track := clip.find_track(NodePath("FootballerRig/Skeleton3D:Hand." + side), Animation.TYPE_ROTATION_3D)
		for key in range(clip.track_get_key_count(track) - 1, -1, -1):
			clip.track_remove_key(track, key)
		for key in range(times.size()):
			clip.rotation_track_insert_key(track, times[key], rotations[side][key])
		var forearm_track := clip.find_track(NodePath("FootballerRig/Skeleton3D:Forearm." + side), Animation.TYPE_ROTATION_3D)
		for key in range(clip.track_get_key_count(forearm_track) - 1, -1, -1):
			clip.track_remove_key(forearm_track, key)
		for key in range(times.size()):
			clip.rotation_track_insert_key(forearm_track, times[key], forearm_rotations[side][key])

static func _globals(rig: Skeleton3D, local: Array[Transform3D]) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone in range(local.size()):
		var parent := rig.get_bone_parent(bone)
		result.append(result[parent] * local[bone] if parent >= 0 else local[bone])
	return result

static func _rotate(rig: Skeleton3D, local: Array[Transform3D], bone: int, rotation: Quaternion) -> void:
	var global := _globals(rig, local)
	var parent := rig.get_bone_parent(bone)
	local[bone].basis = global[parent].basis.inverse() * Basis(rotation) * global[bone].basis

static func _solve_arm(rig: Skeleton3D, local: Array[Transform3D], indices: Dictionary, side: String, target: Vector3, pole_hint: Vector3, transport: Dictionary, time: float, length: float) -> void:
	var upper: int = indices["UpperArm." + side]
	var lower: int = indices["Forearm." + side]
	var hand: int = indices["Hand." + side]
	var global := _globals(rig, local)
	var shoulder := global[upper].origin
	var wrist := target
	var axis := (wrist - shoulder).normalized()
	var length_a := shoulder.distance_to(global[lower].origin)
	var length_b := global[lower].origin.distance_to(global[hand].origin)
	var distance := shoulder.distance_to(wrist)
	var along := (length_a * length_a - length_b * length_b + distance * distance) / (2.0 * distance)
	# Keep the calibrated wrist target and bone lengths; open the elbow away
	# from the ribcage. A stable pole prevents mirrored elbows from flipping.
	var pole := Vector3(signf(shoulder.x), -0.45, -0.10) if pole_hint == Vector3.ZERO else pole_hint
	pole = (pole - axis * pole.dot(axis)).normalized()
	var elbow := shoulder + axis * along + pole * sqrt(maxf(length_a * length_a - along * along, 0.0))
	_rotate(rig, local, upper, Quaternion((global[lower].origin - shoulder).normalized(), (elbow - shoulder).normalized()))
	global = _globals(rig, local)
	if transport.has(side):
		var previous: Dictionary = transport[side]
		var upper_direction := (elbow - shoulder).normalized()
		var upper_basis: Basis = Basis(Quaternion(previous.upper.y.normalized(), upper_direction)) * previous.upper
		if time > 1.21:
			var ready_upper: Basis = previous.ready_upper
			var restored := Basis(Quaternion(ready_upper.y.normalized(), upper_direction)) * ready_upper
			upper_basis = upper_basis.slerp(restored, smoothstep(1.21, length, time))
		local[upper].basis = global[rig.get_bone_parent(upper)].basis.inverse() * upper_basis
		global = _globals(rig, local)
	_rotate(rig, local, lower, Quaternion((global[hand].origin - global[lower].origin).normalized(), (wrist - global[lower].origin).normalized()))
	global = _globals(rig, local)
	if transport.has(side):
		var previous: Dictionary = transport[side]
		var lower_direction := (wrist - global[lower].origin).normalized()
		var lower_basis: Basis = Basis(Quaternion(previous.lower.y.normalized(), lower_direction)) * previous.lower
		if time > 1.21:
			var ready_lower: Basis = previous.ready_lower
			var restored := Basis(Quaternion(ready_lower.y.normalized(), lower_direction)) * ready_lower
			lower_basis = lower_basis.slerp(restored, smoothstep(1.21, length, time))
		local[lower].basis = global[upper].basis.inverse() * lower_basis
		global = _globals(rig, local)
		previous.upper = global[upper].basis
		previous.lower = global[lower].basis
	else:
		transport[side] = {"upper": global[upper].basis, "lower": global[lower].basis,
			"ready_upper": global[upper].basis, "ready_lower": global[lower].basis}
