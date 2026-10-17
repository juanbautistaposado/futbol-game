extends Node3D
const Human = preload("res://footballer_model.gd")
const MESHY_SCENE = preload("res://assets/footballer/meshy_striker.glb")
const FOOTBALLER_SCENE = MESHY_SCENE
const StrikerMotion = preload("res://striker_animation.gd")
const STRIKE_CLIP := StrikerMotion.CLIP
const READY_CLIP := &"athlete/Ready"
const FootballerVisual = preload("res://footballer_visual.gd")
## The strike callback is the single moment when the ball is released.
var motion: Tween
var cue_motion: Tween
var cue_shown := false
var shot_direction := -1
var footballer_visual: Node3D
var footballer_animation: AnimationPlayer
var torso: Node3D
var approach := Vector3.ZERO
var visual_model := -1
var avatar_cache: Dictionary = {}

func _ready() -> void:
	apply_identity(0,"MATEO",10)

func apply_identity(index: int, player_name: String, number: int, custom: Dictionary = {}) -> void:
	if motion: motion.kill()
	if cue_motion: cue_motion.kill()
	var profile: Dictionary = Human.PROFILES[clampi(index,0,Human.PROFILES.size()-1)]
	if index == Human.MESHY_STRIKER_INDEX:
		profile = Human.MESHY_PROFILE
	elif index == 3 and not custom.is_empty():
		profile = custom
	if torso == null:
		torso = Node3D.new()
		torso.position.y = 0.95
		add_child(torso)
	if footballer_visual == null:
		footballer_visual = MESHY_SCENE.instantiate()
		footballer_visual.rotation.y = PI
		add_child(footballer_visual)
		visual_model = Human.MESHY_STRIKER_INDEX
		avatar_cache[visual_model] = footballer_visual
	footballer_animation = footballer_visual.get_node("AnimationPlayer")
	StrikerMotion.install(footballer_animation, footballer_visual.get_node("FootballerRig/Skeleton3D"))
	footballer_animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	var body: MeshInstance3D = footballer_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	FootballerVisual.apply_meshy(body)
	FootballerVisual.apply_profile(body,profile)
	# PLAYER keeps the original white atlas; other identities recolor only cloth.
	var shirt := Color.WHITE if index == Human.MESHY_STRIKER_INDEX else Color(str(profile.shirt))
	for i in range(body.mesh.get_surface_count()):
		if body.mesh.surface_get_material(i).resource_name == "Jersey":
			var fabric := body.get_surface_override_material(i) as ShaderMaterial
			fabric.set_shader_parameter("tint", shirt)
			fabric.set_shader_parameter("roughness_floor", 0.65)
			fabric.set_shader_parameter("specular_strength", 0.2)
	var ink := Color("172438") if (shirt.r + shirt.g + shirt.b) / 3.0 > 0.65 else Color("f0eee5")
	FootballerVisual.apply_lettering(footballer_visual,body,player_name,number,ink)
	footballer_animation.play(READY_CLIP, 0.08)
	for child in torso.get_children():
		if child is Label3D: child.position.z = 0.205

func reset_pose(ball_position: Vector3, direction: int) -> void:
	if motion: motion.kill()
	if cue_motion: cue_motion.kill()
	cue_shown = false
	shot_direction = direction
	footballer_visual.rotation = Vector3(0, PI, 0)
	show()
	rotation.y = 0 if direction == -1 else PI
	approach = Vector3(ball_position.x - direction * 0.15,0,ball_position.z - direction*0.34)
	position = approach + Vector3(-0.5,0,-direction*1.1)
	if footballer_animation: footballer_animation.play(READY_CLIP, 0.08)

func prepare_shot(target: Vector3, crossed := false) -> void:
	if cue_shown:
		return
	cue_shown = true
	var lane := -1 if target.x < -0.85 else 1 if target.x > 0.85 else 0
	if crossed:
		lane = -lane
	var lean := 0.055 if target.y < 1.0 else -0.055 if target.y > 1.7 else 0.0
	# The approach stays identical; only a small, late body adjustment hints at intent.
	cue_motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	cue_motion.tween_property(footballer_visual, "rotation", Vector3(lean, PI + lane * shot_direction * 0.10, 0), 0.18)

func kick(strike: Callable) -> void:
	if motion: motion.kill()
	if cue_motion: cue_motion.kill()
	# Restore the boot's original orientation by contact, preserving the strike pose.
	cue_motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	cue_motion.tween_property(footballer_visual, "rotation", Vector3(0, PI, 0), 0.38)
	if footballer_animation: footballer_animation.play(STRIKE_CLIP, 0.06)
	motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var start := position
	# Accelerate over the two steps, then decelerate into the final plant.
	motion.tween_property(self,"position",start.lerp(approach,0.91),0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	motion.tween_property(self,"position",approach,0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# The private clip preserves the imported right-foot pose at .48 s.
	motion.tween_interval(0.10)
	motion.tween_callback(strike)
	motion.tween_interval(StrikerMotion.DURATION - StrikerMotion.CONTACT_TIME)
	motion.tween_callback(func() -> void:
		if footballer_animation: footballer_animation.play(READY_CLIP,0.12))

func celebrate(location: Vector3) -> void:
	if motion: motion.kill()
	if cue_motion: cue_motion.kill()
	show()
	position = location
	rotation = Vector3(0,PI,0)
	if footballer_animation: footballer_animation.play(&"athlete/Celebrate",0.10)
	motion = create_tween().set_loops()
	motion.tween_property(self,"position:y",location.y+0.3,0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion.tween_property(self,"position:y",location.y,0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
