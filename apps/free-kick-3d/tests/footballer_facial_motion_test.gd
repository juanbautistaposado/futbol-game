extends SceneTree
const Visual = preload("res://footballer_visual.gd")
const Motion = preload("res://footballer_facial_motion.gd")
const Human = preload("res://footballer_model.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var instances: Array[Node3D] = []
	var bodies: Array[MeshInstance3D] = []
	for role in ["striker", "keeper"]:
		var player = load("res://assets/footballer/meshy_" + role + ".glb").instantiate()
		root.add_child(player)
		instances.append(player)
		var body: MeshInstance3D = player.get_node("FootballerRig/Skeleton3D/FootballerBody")
		bodies.append(body)
		Visual.apply_profile(body, Human.PROFILES[0])
		Visual.apply_profile(body, Human.PROFILES[0])
		assert(body.get_node_or_null("FacialMotion") != null)
		assert(body.mesh.get_blend_shape_count() == 1)
		assert(body.mesh.get_blend_shape_name(0) == "Blink")
		var motion = body.get_node("FacialMotion")
		assert(body.get_child_count() == 1, "Editing appearance must not duplicate facial controllers")
		motion.set_process(false)
		motion.elapsed = motion.interval + 0.095
		motion._process(0.0)
		assert(body.get_blend_shape_value(0) > 0.99)
		motion._process(0.3)
		assert(is_zero_approx(body.get_blend_shape_value(0)))
	assert(Motion.blink_amount(-1.0) == 0.0 and Motion.blink_amount(1.0) == 0.0)
	assert(Motion.blink_amount(0.04) > 0.0 and Motion.blink_amount(0.04) < 1.0)
	assert(Motion.blink_amount(0.18) > 0.0 and Motion.blink_amount(0.18) < 1.0)
	bodies[0].set_blend_shape_value(0, 1.0)
	assert(is_zero_approx(bodies[1].get_blend_shape_value(0)), "Avatar blinks must be independent")
	for player in instances: player.free()
	print("PASS: independent eyelid morph, smooth close/open cycle, both roles, no duplicate controller after edits")
	quit()
