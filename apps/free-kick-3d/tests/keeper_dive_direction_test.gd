extends SceneTree
## A world-space dive must reach towards the shot for either field orientation.
const Keeper = preload("res://keeper.gd")
const KeeperAnimation = preload("res://keeper_animation.gd")
const STEP := 1.0 / 60.0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func bone_world(keeper: Keeper, name: String) -> Vector3:
	return keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone(name)).origin

func sole_samples(keeper: Keeper) -> Dictionary:
	var mesh: MeshInstance3D = keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	var bones: Array[int] = []
	var inverse_binds: Array[Transform3D] = []
	var vertices: Array[Dictionary] = []
	for bind in range(mesh.skin.get_bind_count()):
		var bone := mesh.skin.get_bind_bone(bind)
		if bone < 0:
			bone = keeper.skeleton.find_bone(mesh.skin.get_bind_name(bind))
		bones.append(bone)
		inverse_binds.append(mesh.skin.get_bind_pose(bind))
	for surface in range(mesh.mesh.get_surface_count()):
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if weights.is_empty():
			continue
		var stride := weights.size() / positions.size()
		for vertex in range(positions.size()):
			var foot_weight := 0.0
			for influence in range(stride):
				var bone_name := keeper.skeleton.get_bone_name(bones[indices[vertex * stride + influence]])
				if bone_name.begins_with("Foot.") or bone_name.begins_with("Toe."):
					foot_weight += weights[vertex * stride + influence]
			if foot_weight > 0.5:
				vertices.append({"position": positions[vertex],
					"indices": indices.slice(vertex * stride, (vertex + 1) * stride),
					"weights": weights.slice(vertex * stride, (vertex + 1) * stride)})
	return {"bones": bones, "binds": inverse_binds, "vertices": vertices}

func lowest_sole(keeper: Keeper, samples: Dictionary) -> float:
	var matrices: Array[Transform3D] = []
	for bind in range(samples.bones.size()):
		matrices.append(keeper.skeleton.get_bone_global_pose(samples.bones[bind]) * samples.binds[bind])
	var lowest := INF
	for vertex: Dictionary in samples.vertices:
		var position := Vector3.ZERO
		for influence in range(vertex.weights.size()):
			if vertex.weights[influence] > 0.0:
				position += (matrices[vertex.indices[influence]] * vertex.position) * vertex.weights[influence]
		lowest = minf(lowest, (keeper.skeleton.global_transform * position).y)
	return lowest

func run() -> void:
	for field_side: int in [-1, 1]:
		var keeper := Keeper.new()
		keeper.configure(field_side, Color.WHITE)
		root.add_child(keeper)
		keeper.set_process(false)
		keeper.goalkeeper_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		await process_frame
		var sole := sole_samples(keeper)
		check(not sole.vertices.is_empty(), "El modelo debe proporcionar vértices de las botas para comprobar el suelo")
		for height: float in [0.7, 1.6]:
			for direction: float in [-1.0, 1.0]:
				keeper.reset_pose()
				var local_direction := signf((keeper.skeleton.global_basis.inverse() * Vector3(direction, 0.0, 0.0)).x)
				keeper.dive(direction * 2.8, height)
				keeper.motion.pause()
				var reach_head := Vector3.ZERO
				var reach_pelvis := Vector3.ZERO
				var reach_principal := Vector3.ZERO
				var reach_support := Vector3.ZERO
				var reach_support_local := Vector3.ZERO
				var reach_support_shoulder := Vector3.ZERO
				var reach_clip: StringName
				var reach_roll := 0.0
				var sole_y := INF
				for frame in range(96):
					var existing_arc: Tween = keeper.dive_arc
					keeper.motion.custom_step(STEP)
					if existing_arc and existing_arc.is_valid():
						existing_arc.custom_step(STEP)
					if keeper.dive_arc and keeper.dive_arc.is_valid():
						keeper.dive_arc.pause()
					keeper.goalkeeper_animation.advance(STEP)
					keeper.skeleton.force_update_all_bone_transforms()
					if frame == 26:
						reach_head = bone_world(keeper, "Head")
						reach_pelvis = bone_world(keeper, "Hips")
						reach_principal = bone_world(keeper, "Hand.R" if local_direction > 0.0 else "Hand.L")
						reach_support = bone_world(keeper, "Hand.L" if local_direction > 0.0 else "Hand.R")
						var support_side := "L" if local_direction > 0.0 else "R"
						reach_support_local = keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("Hand." + support_side)).origin
						reach_support_shoulder = keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone("UpperArm." + support_side)).origin
						reach_clip = keeper.goalkeeper_animation.current_animation
						reach_roll = keeper.rotation.z
					if frame >= 65 and frame <= 95:
						var sampled_y := lowest_sole(keeper, sole)
						sole_y = minf(sole_y, sampled_y)
						if OS.get_cmdline_user_args().has("--diagnostics") and frame % 4 == 1:
							print("SOLE field=%d dir=%+.0f h=%.2f t=%.3f min_y=%.4f" % [field_side, direction, height, (frame + 1) * STEP, sampled_y])
				keeper.skeleton.force_update_all_bone_transforms()
				var label := "field=%d direction=%+.0f height=%.2f" % [field_side, direction, height]
				check(reach_clip == KeeperAnimation.save_clip(local_direction, height, true),
					label + ": el clip debe elegir el lado local del rig")
				var reference := reach_pelvis if height < 0.85 else reach_head
				check(direction * (reach_principal.x - reference.x) > (0.50 if height < 0.85 else 0.25),
					label + ": la mano principal debe adelantarse hacia el tiro mundial")
				if height < 0.85:
					check(direction * (reach_support.x - reference.x) > 0.35,
						label + ": la mano de apoyo debe acompañar hacia el tiro mundial")
				else:
					check(reach_support.y < reach_principal.y - 0.05 and -local_direction * (reach_support_local.x - reach_support_shoulder.x) >= -0.10,
						label + ": el rechazo con una mano debe dejar el apoyo debajo y junto a su propio hombro")
				check(reach_principal.y > 1.95 if height > 1.35 else reach_principal.y > 0.30 and reach_principal.y < 0.85,
					label + ": la mano principal debe alcanzar la altura elegida")
				check(signf(reach_roll) == -direction,
					label + ": el giro del cuerpo debe conservar la dirección mundial")
				check(sole_y >= -0.03, label + ": la suela debe quedar sobre el césped durante el apoyo (%.3fm)" % sole_y)
		keeper.reset_pose()
		keeper.queue_free()
		await process_frame
	print("PASS: alcance mundial y lado local del clip en ambos arqueros, direcciones y alturas" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures > 0 else 0)
