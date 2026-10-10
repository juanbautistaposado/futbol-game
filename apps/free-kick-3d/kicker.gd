extends Node3D
const Human = preload("res://footballer_model.gd")
const MESHY_SCENE = preload("res://assets/footballer/meshy_striker.glb")
const FOOTBALLER_SCENE = MESHY_SCENE
const FootballerVisual = preload("res://footballer_visual.gd")
## The strike callback is the single moment when the ball is released.
var motion: Tween
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
	footballer_animation.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
	footballer_animation.get_animation("Celebrate").loop_mode = Animation.LOOP_LINEAR
	footballer_animation.play("Idle")
	for child in torso.get_children():
		if child is Label3D: child.position.z = 0.205

func reset_pose(ball_position: Vector3, direction: int) -> void:
	if motion: motion.kill()
	show()
	rotation.y = 0 if direction == -1 else PI
	approach = Vector3(ball_position.x - direction * 0.15,0,ball_position.z - direction*0.34)
	position = approach + Vector3(-0.5,0,-direction*1.1)
	if footballer_animation: footballer_animation.play("Idle")

func kick(strike: Callable) -> void:
	if footballer_animation: footballer_animation.play("Kick")
	motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	motion.tween_property(self,"position",approach,0.38).set_trans(Tween.TRANS_SINE)
	# The imported right boot reaches the ball at frame 15 (~0.47 s).
	motion.tween_interval(0.10)
	motion.tween_callback(strike)

func celebrate(location: Vector3) -> void:
	if motion: motion.kill()
	show()
	position = location
	rotation = Vector3(0,PI,0)
	if footballer_animation: footballer_animation.play("Celebrate")
	motion = create_tween().set_loops()
	motion.tween_property(self,"position:y",location.y+0.3,0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion.tween_property(self,"position:y",location.y,0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
