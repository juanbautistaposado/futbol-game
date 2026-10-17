extends SceneTree
## Real dive/tween regression: an airborne keeper must not freeze for 0.1 s.
## Tick the actual runtime tweens manually, independent of renderer/wall time.
const Keeper = preload("res://keeper.gd")
const STEP := 1.0 / 60.0
const MARKERS := ["Hips", "Chest", "Head", "Hand.L", "Hand.R", "Foot.L", "Foot.R"]
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func world_markers(keeper: Keeper) -> Array[Vector3]:
	keeper.skeleton.force_update_all_bone_transforms()
	var result: Array[Vector3] = []
	for marker: String in MARKERS:
		result.append(keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone(marker)).origin)
	return result

func run() -> void:
	var keeper := Keeper.new()
	keeper.configure(-1, Color.WHITE)
	root.add_child(keeper)
	keeper.set_process(false)
	keeper.goalkeeper_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	await process_frame
	for height: float in [0.7, 1.25, 1.6]:
		for direction: float in [-1.0, 1.0]:
			keeper.reset_pose()
			keeper.dive(direction * 2.8, height)
			keeper.motion.pause()
			var previous := world_markers(keeper)
			var frozen_frames := 0
			var longest_freeze := 0
			var pelvis_travel := 0.0
			var min_marker_y := INF
			var lowest_landing_foot := INF
			for frame in range(1, 97):
				# A secondary arc created inside motion's callback starts on the
				# following physics tick, matching SceneTree tween scheduling.
				var existing_arc: Tween = keeper.dive_arc
				keeper.motion.custom_step(STEP)
				if existing_arc and existing_arc.is_valid():
					existing_arc.custom_step(STEP)
				if keeper.dive_arc and keeper.dive_arc.is_valid():
					keeper.dive_arc.pause()
				keeper.goalkeeper_animation.advance(STEP)
				var current := world_markers(keeper)
				var time := frame * STEP
				var frame_lowest := INF
				for marker: Vector3 in current:
					frame_lowest = minf(frame_lowest, marker.y)
				if OS.get_cmdline_user_args().has("--diagnostics") and frame in [15, 27, 46, 61, 73, 95]:
					print("DIVE_PHASE direction=%+.0f height=%.2f t=%.3f root=%s pelvis=%s chest=%s low=%.3f" % [direction, height, time, keeper.position, current[0], current[1], frame_lowest])
				if time >= 0.75 and time <= 1.45:
					lowest_landing_foot = minf(lowest_landing_foot, minf(current[5].y, current[6].y))
				if time >= 0.48 and time <= 0.73:
					var maximum_displacement := 0.0
					for marker in range(current.size()):
						maximum_displacement = maxf(maximum_displacement, current[marker].distance_to(previous[marker]))
						min_marker_y = minf(min_marker_y, current[marker].y)
					pelvis_travel += current[0].distance_to(previous[0])
					if maximum_displacement < 0.0005 and frame_lowest > 0.05:
						frozen_frames += 1
					else:
						frozen_frames = 0
					longest_freeze = maxi(longest_freeze, frozen_frames)
				previous = current
			var label := "%s %.2fm" % ["Left" if direction < 0 else "Right", height]
			print("DIVE_MOTION %s: airborne_freeze=%.3fs pelvis_path=%.4fm lowest_marker=%.3fm landing_foot=%.3fm" % [label, longest_freeze * STEP, pelvis_travel, min_marker_y, lowest_landing_foot])
			if longest_freeze >= 6:
				failures += 1
				push_error("%s: la estirada congela todo el cuerpo en el aire durante al menos 0.10s" % label)
			# These are ankle origins, not sole vertices. A generous six cm
			# tolerance only catches deep penetration during landing/recovery.
			if lowest_landing_foot < -0.06:
				failures += 1
				push_error("%s: un tobillo atraviesa profundamente el suelo durante la caída (%.3fm)" % [label, lowest_landing_foot])
			keeper.reset_pose()
	print("PASS: vuelo continuo y tobillos sobre el suelo durante caída" if failures == 0 else "FAIL: %d fallos de vuelo/caída" % failures)
	quit(1 if failures else 0)
