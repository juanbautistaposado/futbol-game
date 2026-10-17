extends SceneTree
## Inter-character limb/glove clearance through the real dive at 60 Hz.
## Unlike wrist-centre checks, this catches crossing forearms and finger strips.
const Keeper = preload("res://keeper.gd")
const STEP := 1.0 / 60.0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func bone(keeper: Keeper, name: String) -> Transform3D:
	return keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.skeleton.find_bone(name))

func distance_between_segments(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> float:
	var closest := Geometry3D.get_closest_points_between_segments(a, b, c, d)
	return closest[0].distance_to(closest[1])

func projected_distance(camera: Camera3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> float:
	var points: Array[Vector3] = []
	for world: Vector3 in [a, b, c, d]:
		var screen := camera.unproject_position(world)
		points.append(Vector3(screen.x, screen.y, 0.0))
	return distance_between_segments(points[0], points[1], points[2], points[3])

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/futbol-keeper-arm-separation.cfg"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	await process_frame
	var viewport_width: float = game.camera.get_viewport().get_visible_rect().size.x
	for keeper: Keeper in [game.home_keeper, game.away_keeper]:
		keeper.set_process(false)
		keeper.goalkeeper_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		# Call the product camera methods, rather than creating a front preview.
		if keeper == game.home_keeper:
			game.look_from_keeper()
		else:
			game.reset_ball(Vector3(0.0, 0.13, -game.GOAL_Z + game.shooting_distance()))
			game.look_from_kicker()
		for height: float in [0.7, 1.25, 1.6]:
			for direction: float in [-1.0, 1.0]:
				keeper.reset_pose()
				var rig_direction := signf((keeper.skeleton.global_basis.inverse() * Vector3(direction, 0.0, 0.0)).x)
				var principal_side := "R" if rig_direction > 0.0 else "L"
				var support_side := "L" if rig_direction > 0.0 else "R"
				keeper.dive(direction * 2.8, height)
				keeper.motion.pause()
				var minimum_arm := INF
				var minimum_glove := INF
				var minimum_wrist := INF
				var minimum_projection := INF
				var minimum_reach_projection := INF
				var projection_time := 0.0
				var arm_time := 0.0
				var glove_time := 0.0
				var minimum_support_hemisphere := INF
				var minimum_principal_height_gap := INF
				for frame in range(1, 96):
					var existing_arc: Tween = keeper.dive_arc
					keeper.motion.custom_step(STEP)
					if existing_arc and existing_arc.is_valid():
						existing_arc.custom_step(STEP)
					if keeper.dive_arc and keeper.dive_arc.is_valid():
						keeper.dive_arc.pause()
					keeper.goalkeeper_animation.advance(STEP)
					keeper.skeleton.force_update_all_bone_transforms()
					var left := bone(keeper, "Hand.L")
					var right := bone(keeper, "Hand.R")
					var left_elbow := bone(keeper, "Forearm.L").origin
					var right_elbow := bone(keeper, "Forearm.R").origin
					var left_shoulder := bone(keeper, "UpperArm.L").origin
					var right_shoulder := bone(keeper, "UpperArm.R").origin
					var arm_clearance := minf(
						distance_between_segments(left_elbow, left.origin, right_shoulder, right_elbow),
						distance_between_segments(right_elbow, right.origin, left_shoulder, left_elbow))
					arm_clearance = minf(arm_clearance, distance_between_segments(left_elbow, left.origin, right_elbow, right.origin))
					# Conservative core strips inside the visible rigid Meshy gloves:
					# palm-to-fingers +Y, offset towards the centre of each palm.
					# Each ~3 cm core radius excludes the thumb's empty bounding box.
					var left_start := left * Vector3(0.035, 0.06, 0.0)
					var left_end := left * Vector3(0.035, 0.23, 0.0)
					var right_start := right * Vector3(-0.035, 0.06, 0.0)
					var right_end := right * Vector3(-0.035, 0.23, 0.0)
					var glove_clearance := distance_between_segments(left_start, left_end, right_start, right_end)
					if arm_clearance < minimum_arm:
						minimum_arm = arm_clearance
						arm_time = frame * STEP
					if glove_clearance < minimum_glove:
						minimum_glove = glove_clearance
						glove_time = frame * STEP
					minimum_wrist = minf(minimum_wrist, left.origin.distance_to(right.origin))
					var projection := projected_distance(game.camera, left_start, left_end, right_start, right_end)
					if projection < minimum_projection:
						minimum_projection = projection
						projection_time = frame * STEP
					if frame >= 15 and frame <= 46:
						minimum_reach_projection = minf(minimum_reach_projection, projection)
						if height >= 0.85:
							# Medium/high lateral saves use a one-hand rejection:
							# support stays beside its own shoulder, below the leading
							# glove, instead of crossing the face towards the shot.
							var support := bone(keeper, "Hand." + support_side)
							var principal := bone(keeper, "Hand." + principal_side)
							var shoulder := bone(keeper, "UpperArm." + support_side)
							var inverse_rig := keeper.skeleton.global_transform.affine_inverse()
							var support_local := inverse_rig * support.origin
							var shoulder_local := inverse_rig * shoulder.origin
							var outward := -1.0 if support_side == "L" else 1.0
							minimum_support_hemisphere = minf(minimum_support_hemisphere, outward * (support_local.x - shoulder_local.x))
							var support_center := support * Vector3(0.035 * outward * -1.0, 0.13, 0.0)
							var principal_center := principal * Vector3(0.035 * outward, 0.13, 0.0)
							minimum_principal_height_gap = minf(minimum_principal_height_gap, principal_center.y - support_center.y)
				var label := "%s %s %.2fm" % [keeper.name, "Left" if direction < 0 else "Right", height]
				print("ARM_CLEARANCE %s: arms=%.4fm@%.3fs glove_core=%.4fm@%.3fs wrists=%.4fm projected_core=%.2fpx@%.3fs reach_projection=%.2fpx" % [label, minimum_arm, arm_time, minimum_glove, glove_time, minimum_wrist, minimum_projection, projection_time, minimum_reach_projection])
				if height >= 0.85:
					print("ARM_ROLE %s: own_shoulder_margin=%.4f rig_m principal_above_support=%.4fm" % [label, minimum_support_hemisphere, minimum_principal_height_gap])
					if minimum_support_hemisphere < -0.10 or minimum_principal_height_gap < 0.05:
						failures += 1
						push_error("%s: el apoyo debe quedarse junto a su propio hombro y debajo del guante principal, sin cruzar la cara" % label)
				# Limb radii around 3 cm each, plus uniform visual scale. Tolerate
				# small surface contact, but reject limbs deeply crossing each other.
				if minimum_arm < 0.06:
					failures += 1
					push_error("%s: antebrazo atraviesa el brazo contrario (ejes separados %.4fm)" % [label, minimum_arm])
				if minimum_glove < 0.06:
					failures += 1
					push_error("%s: palmas/dedos atraviesan el otro guante (núcleos separados %.4fm)" % [label, minimum_glove])
				# The defender must read two separate gloves from the fixed
				# gameplay camera. Normalize two pixels at 1280 px viewport width,
				# so this silhouette regression is independent of window scaling.
				# The distant attack camera remains diagnostic only.
				if keeper == game.home_keeper and minimum_projection / viewport_width < 2.0 / 1280.0:
					failures += 1
					push_error("%s: las siluetas de los guantes se cruzan desde la cámara de defensa (%.2fpx a %.0fpx de ancho)" % [label, minimum_projection, viewport_width])
				keeper.reset_pose()
	print("PASS: brazos y guantes separados durante ambos arqueros/lados/alturas" if failures == 0 else "FAIL: %d cruces de brazos/guantes" % failures)
	quit(1 if failures else 0)
