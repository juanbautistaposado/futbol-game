extends Node3D
const Human = preload("res://footballer_model.gd")
const FOOTBALLER_SCENE = preload("res://assets/footballer/footballer_v2.glb")
const FootballerVisual = preload("res://footballer_visual.gd")
## The strike callback is the single moment when the ball is released.
var motion: Tween
var footballer_visual: Node3D
var footballer_animation: AnimationPlayer
var torso: Node3D
var approach := Vector3.ZERO

func _ready() -> void:
	apply_identity(0,"MATEO",10)

func apply_identity(index: int, player_name: String, number: int, custom: Dictionary = {}) -> void:
	if motion: motion.kill()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var profile: Dictionary = custom if index == 3 and not custom.is_empty() else Human.PROFILES[clampi(index,0,Human.PROFILES.size()-1)]
	torso = Node3D.new()
	torso.position.y = 0.95
	add_child(torso)
	Human.lettering(torso,player_name,number)
	footballer_visual = FOOTBALLER_SCENE.instantiate()
	footballer_visual.rotation.y = PI
	add_child(footballer_visual)
	footballer_animation = footballer_visual.get_node("AnimationPlayer")
	var body: MeshInstance3D = footballer_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
	FootballerVisual.apply_profile(body,profile)
	var beard: MeshInstance3D = footballer_visual.get_node("FootballerRig/Skeleton3D/Beard")
	beard.visible = bool(profile.beard)
	FootballerVisual.apply_profile(beard,profile)
	footballer_animation.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
	footballer_animation.get_animation("Celebrate").loop_mode = Animation.LOOP_LINEAR
	footballer_animation.play("Idle")
	for child in torso.get_children():
		if child is Label3D: child.position.z = 0.205

func reset_pose(ball_position: Vector3, direction: int) -> void:
	if motion: motion.kill()
	show()
	rotation.y = 0 if direction == -1 else PI
	approach = Vector3(ball_position.x - 0.15,0,ball_position.z - direction*0.34)
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
