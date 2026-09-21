extends AnimatableBody3D

var motion: Tween
var rest_position := Vector3.ZERO
var visual: Node3D
var left_arm: Node3D
var right_arm: Node3D
var busy := false
var idle_time := 0.0

func configure(side: int, shirt: Color) -> void:
	# Motion runs on physics ticks; avoid separately synchronizing each transform property.
	sync_to_physics = false
	name = "keeper_%s" % side
	rest_position = Vector3(0, 0.9, 12.0 * side - 0.7 * side)
	position = rest_position
	visual = Node3D.new()
	add_child(visual)
	add_part(visual, Vector3(0, 0.12, 0), Vector3(0.62, 0.68, 0.34), shirt)
	add_part(visual, Vector3(0, 0.66, 0), Vector3(0.34, 0.36, 0.34), Color("d7a47c"))
	add_part(visual, Vector3(-0.20, -0.55, 0), Vector3(0.22, 0.68, 0.26), Color("172b40"))
	add_part(visual, Vector3(0.20, -0.55, 0), Vector3(0.22, 0.68, 0.26), Color("172b40"))
	left_arm = make_arm(-1, shirt)
	right_arm = make_arm(1, shirt)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.8
	collision.shape = capsule
	add_child(collision)

func add_part(parent: Node3D, location: Vector3, dimensions: Vector3, color: Color) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	part.mesh = mesh
	part.position = location
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	part.material_override = material
	parent.add_child(part)

func make_arm(side: int, shirt: Color) -> Node3D:
	var arm := Node3D.new()
	arm.position = Vector3(side * 0.38, 0.35, 0)
	visual.add_child(arm)
	add_part(arm, Vector3(0, -0.20, 0), Vector3(0.19, 0.48, 0.22), shirt)
	add_part(arm, Vector3(0, -0.48, -0.04), Vector3(0.25, 0.22, 0.29), Color("f8fafc"))
	return arm

func _process(delta: float) -> void:
	if busy:
		return
	idle_time += delta
	visual.position.y = sin(idle_time * 4.0) * 0.025
	left_arm.rotation.z = -0.22
	right_arm.rotation.z = 0.22

func reset_pose() -> void:
	if motion:
		motion.kill()
	busy = false
	position = rest_position
	rotation = Vector3.ZERO
	visual.position = Vector3.ZERO
	left_arm.rotation = Vector3.ZERO
	right_arm.rotation = Vector3.ZERO

func dive(destination_x: float, height: float, reaction_delay := 0.0) -> void:
	if busy:
		return
	busy = true
	visual.position = Vector3.ZERO
	var reach := clampf(destination_x, -2.65, 2.65)
	var direction := signf(reach - position.x)
	var tilt := -direction * deg_to_rad(68.0) if absf(reach - position.x) > 0.4 else 0.0
	var destination := Vector3(reach, clampf(height, 0.65, 1.6), rest_position.z)
	motion = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if reaction_delay > 0:
		motion.tween_interval(reaction_delay)
	# Plant feet, push off, stretch, land, then get back up.
	motion.tween_property(self, "position:y", 0.78, 0.09).set_trans(Tween.TRANS_SINE)
	motion.tween_property(self, "position", destination, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.parallel().tween_property(self, "rotation:z", tilt, 0.32).set_trans(Tween.TRANS_SINE)
	motion.parallel().tween_property(left_arm, "rotation:z", -2.55, 0.22)
	motion.parallel().tween_property(right_arm, "rotation:z", 2.55, 0.22)
	motion.tween_interval(0.12)
	motion.tween_property(self, "position:y", 0.43 if tilt != 0 else 0.9, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	motion.tween_interval(0.20)
	motion.tween_property(self, "rotation:z", 0.0, 0.38).set_trans(Tween.TRANS_SINE)
	motion.parallel().tween_property(self, "position:y", 0.9, 0.38)
	motion.parallel().tween_property(left_arm, "rotation:z", -0.22, 0.38)
	motion.parallel().tween_property(right_arm, "rotation:z", 0.22, 0.38)
	motion.tween_callback(func() -> void: busy = false)
