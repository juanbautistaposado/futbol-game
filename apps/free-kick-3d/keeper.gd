extends AnimatableBody3D
const Human = preload("res://footballer_model.gd")
const GOALKEEPER_SCENE = preload("res://assets/footballer/meshy_keeper.glb")
const FootballerVisual = preload("res://footballer_visual.gd")
const KeeperAnimation = preload("res://keeper_animation.gd")

var motion: Tween
var dive_arc: Tween
var rest_position := Vector3.ZERO
var visual: Node3D
var goalkeeper_visual: Node3D
var goalkeeper_animation: AnimationPlayer
var skeleton: Skeleton3D
var left_hand_bone := -1
var right_hand_bone := -1
var dive_reach_collision: CollisionShape3D
var busy := false
var lateral_dive := false
var ball_retained := false
var active_dive_clip: StringName
var idle_time := 0.0

func configure(side: int, shirt: Color) -> void:
	# Motion runs on physics ticks; avoid separately synchronizing each transform property.
	sync_to_physics = false
	name = "keeper_%s" % side
	rest_position = Vector3(0, 1.035, 52.5 * side - 0.7 * side)
	position = rest_position
	visual = Node3D.new()
	visual.scale = Vector3.ONE * 1.15
	visual.rotation.y = PI if side == -1 else 0.0
	add_child(visual)
	var profile: Dictionary = Human.DONNARUMMA.duplicate() if side == -1 else Human.PROFILES[0].duplicate()
	profile.shirt = "648740" if side == -1 else "22724f"
	build_body(profile,"DONNARUMMA" if side == -1 else "JUGADOR",1 if side == -1 else 10)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.39
	capsule.height = 2.07
	collision.shape = capsule
	add_child(collision)
	# The diving arms need a physical reach beyond the torso capsule.
	dive_reach_collision = CollisionShape3D.new()
	var reach_shape := BoxShape3D.new()
	reach_shape.size = Vector3(1.65, 0.46, 0.55)
	dive_reach_collision.shape = reach_shape
	dive_reach_collision.disabled = true
	add_child(dive_reach_collision)

func build_body(profile: Dictionary, player_name: String, number: int) -> void:
	if goalkeeper_visual == null:
		goalkeeper_visual = GOALKEEPER_SCENE.instantiate()
		goalkeeper_visual.position.y = -0.86
		goalkeeper_visual.rotation.y = PI
		visual.add_child(goalkeeper_visual)
	goalkeeper_animation = goalkeeper_visual.get_node("AnimationPlayer")
	skeleton = goalkeeper_visual.get_node("FootballerRig/Skeleton3D")
	left_hand_bone = skeleton.find_bone("Hand.L")
	right_hand_bone = skeleton.find_bone("Hand.R")
	var body: MeshInstance3D = goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	FootballerVisual.apply_meshy(body)
	FootballerVisual.apply_profile(body,profile)
	FootballerVisual.apply_lettering(goalkeeper_visual,body,player_name,number)
	KeeperAnimation.install(goalkeeper_animation, skeleton)
	# Animation resources imported from the GLB are shared by both keepers.
	# Each looping celebration gets its own resource before editing loop mode.
	var library := goalkeeper_animation.get_animation_library("").duplicate()
	var celebration := goalkeeper_animation.get_animation("Celebrate").duplicate() as Animation
	celebration.loop_mode = Animation.LOOP_LINEAR
	library.remove_animation(&"Celebrate")
	library.add_animation(&"Celebrate", celebration)
	goalkeeper_animation.remove_animation_library("")
	goalkeeper_animation.add_animation_library("", library)
	goalkeeper_animation.play(KeeperAnimation.READY)
	for child in visual.get_children():
		if child is Label3D: child.position.z = 0.205

func _process(delta: float) -> void:
	if busy:
		return
	idle_time += delta
	visual.position.y = sin(idle_time * TAU / 1.8) * 0.008

func reset_pose() -> void:
	if motion:
		motion.kill()
	if dive_arc:
		dive_arc.kill()
	busy = false
	lateral_dive = false
	ball_retained = false
	active_dive_clip = &""
	idle_time = 0.0
	position = rest_position
	rotation = Vector3.ZERO
	visual.position = Vector3.ZERO
	visual.rotation.z = 0.0
	dive_reach_collision.set_deferred("disabled", true)
	if goalkeeper_animation:
		goalkeeper_animation.speed_scale = 1.0
		goalkeeper_animation.play(KeeperAnimation.READY, 0.0)
		goalkeeper_animation.seek(0.0, true)

func dive(destination_x: float, height: float, reaction_delay := 0.0) -> void:
	if busy:
		return
	busy = true
	visual.position = Vector3.ZERO
	visual.rotation.z = 0.0
	var reach := clampf(destination_x, -3.35, 3.35)
	var direction := signf(reach - position.x)
	# The two goalkeepers face opposite ends of the pitch. Clip names describe
	# the rig's own X axis; movement, roll and collision remain in world space.
	var rig_direction := signf((skeleton.global_basis.inverse() * Vector3(direction, 0.0, 0.0)).x)
	var tilt := -direction * deg_to_rad(70.0 if height < 0.85 else 45.0) if absf(reach - position.x) > 0.4 else 0.0
	var destination := Vector3(reach, clampf(height, 0.65, 1.6), rest_position.z)
	lateral_dive = tilt != 0.0
	active_dive_clip = KeeperAnimation.save_clip(rig_direction, destination.y, lateral_dive)
	if direction != 0.0:
		var glove_height := 2.28 if destination.y > 1.35 else 0.66 if destination.y < 0.85 else 1.45
		var arm_offset := Vector3(direction * 0.34, glove_height - destination.y, 0.0)
		dive_reach_collision.position = Basis(Vector3.BACK, tilt).inverse() * arm_offset
		dive_reach_collision.rotation.z = -rotation.z
		dive_reach_collision.set_deferred("disabled", false)
	motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if reaction_delay > 0:
		motion.tween_interval(reaction_delay)
	motion.tween_callback(func() -> void:
		if goalkeeper_animation:
			goalkeeper_animation.speed_scale = 1.0
			goalkeeper_animation.play(active_dive_clip))
	# Load the pushing leg, then launch the body and extend both hands toward
	# the shot. X and Y run on separate tweens so the dive has a visible arc.
	motion.tween_property(self, "position:y", 0.78, 0.09).set_trans(Tween.TRANS_SINE)
	motion.tween_callback(func() -> void:
		# Stay below the final reach during a low save: even the old 8 cm hop
		# lifted the gloves above a ground-level ball arriving at full speed.
		var apex := destination.y - 0.03 if destination.y < 0.85 else maxf(destination.y + 0.13, 1.38)
		dive_arc = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		dive_arc.tween_property(self, "position:y", apex, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		dive_arc.tween_property(self, "position:y", destination.y, 0.21).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN))
	motion.tween_property(self, "position:x", destination.x, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.parallel().tween_method(_set_dive_roll, rotation.z, tilt, 0.32).set_trans(Tween.TRANS_SINE)
	# Finish the reach with a small continuation while the legs gather; the
	# ball can still cross this interception window after maximum extension.
	# Previously a .32 s interval held the entire keeper stationary in midair.
	motion.tween_property(self, "position:y", destination.y - 0.02, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	motion.parallel().tween_method(_set_dive_roll, tilt, tilt - direction * deg_to_rad(1.0) if tilt != 0.0 else 0.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	motion.parallel().tween_property(self, "position:x", destination.x + direction * 0.05 if tilt != 0.0 else destination.x, 0.32)
	# Turn onto the side while the animation bends the elbows for contact.
	var side_landing := -direction * deg_to_rad(82.0) if tilt != 0.0 else 0.0
	motion.tween_property(self, "position:y", 0.43 if tilt != 0 else 0.9, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	motion.parallel().tween_method(_set_dive_roll, tilt - direction * deg_to_rad(1.0) if tilt != 0.0 else 0.0, side_landing, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Absorb the side impact, gather the legs and settle on the turf. A saved
	# or missed free kick ends here; standing belongs to the next shot's reset.
	motion.tween_property(self, "position:y", 0.50 if lateral_dive else 0.9, 0.30).set_trans(Tween.TRANS_SINE)
	motion.parallel().tween_method(_set_dive_roll, side_landing, -direction * deg_to_rad(76.0) if lateral_dive else 0.0, 0.30).set_trans(Tween.TRANS_SINE)
	motion.tween_interval(0.28)
	motion.tween_callback(func() -> void:
		dive_reach_collision.set_deferred("disabled", true))

func _set_dive_roll(angle: float) -> void:
	rotation.z = angle
	# Keep the arm reach level throughout the actual roll, not only at its
	# final angle. A tilted outer edge left a gap above ground-level shots.
	dive_reach_collision.rotation.z = -angle

func celebrate(location: Vector3) -> void:
	reset_pose()
	show()
	busy = true
	position = location
	if goalkeeper_animation: goalkeeper_animation.play("Celebrate")
	motion = create_tween().set_loops()
	motion.tween_property(visual,"position:y",0.28,0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion.tween_property(visual,"position:y",0.0,0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func catch_pose(side: int) -> void:
	if lateral_dive and busy:
		ball_retained = true
		# Retaining the ball must not kill the dive and freeze the keeper in
		# midair. Switch arm action at the same phase and keep falling.
		var phase := goalkeeper_animation.current_animation_position if goalkeeper_animation.is_playing() else KeeperAnimation.DIVE_LENGTH
		goalkeeper_animation.play(KeeperAnimation.hold_clip(active_dive_clip), 0.08)
		goalkeeper_animation.seek(phase, true)
		dive_reach_collision.set_deferred("disabled", true)
		return
	if motion: motion.kill()
	if dive_arc: dive_arc.kill()
	busy = true
	dive_reach_collision.set_deferred("disabled", true)
	if goalkeeper_animation:
		goalkeeper_animation.speed_scale = 1.0
		goalkeeper_animation.play("Catch")

func held_ball_position(_side: int) -> Vector3:
	# The ball follows the skinned gloves, including during the catch clip and
	# after a lateral dive. A fixed offset made it float away from both hands.
	skeleton.force_update_all_bone_transforms()
	var left_hand := skeleton.global_transform * skeleton.get_bone_global_pose(left_hand_bone).origin
	var right_hand := skeleton.global_transform * skeleton.get_bone_global_pose(right_hand_bone).origin
	if ball_retained and lateral_dive:
		# The glove's palm centre lies beyond the wrist along its finger axis.
		# Retaining at the wrist midpoint made the ball hang below both palms.
		var left_pose := skeleton.global_transform * skeleton.get_bone_global_pose(left_hand_bone)
		var right_pose := skeleton.global_transform * skeleton.get_bone_global_pose(right_hand_bone)
		return (left_pose * Vector3(0.0, 0.12, 0.0) + right_pose * Vector3(0.0, 0.12, 0.0)) * 0.5
	return (left_hand + right_hand) * 0.5
