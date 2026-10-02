extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func hand_position(skeleton: Skeleton3D, side: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hand." + side)).origin

func check_hands(keeper: Node, skeleton: Skeleton3D) -> void:
	keeper.catch_pose(-1)
	keeper.goalkeeper_animation.advance(0.4)
	var left := hand_position(skeleton, "L")
	var right := hand_position(skeleton, "R")
	var ball_center: Vector3 = keeper.held_ball_position(-1)
	assert(ball_center.distance_to((left + right) * 0.5) < 0.15, "La pelota debe seguir las manos visibles")
	assert(left.distance_to(right) < 0.65, "Las manos deben rodear una pelota de 44 cm")

func run() -> void:
	var keeper = load("res://keeper.gd").new()
	root.add_child(keeper)
	keeper.configure(-1, Color.GREEN)
	var skeleton: Skeleton3D = keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D")
	check_hands(keeper, skeleton)
	keeper.celebrate(Vector3.ZERO)
	keeper.goalkeeper_animation.advance(0.4)
	var head := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin
	assert(hand_position(skeleton, "L").y > head.y + 0.1 and hand_position(skeleton, "R").y > head.y + 0.1, "Celebración: las dos manos deben quedar sobre la cabeza")
	print("PASS: captura con manos y celebración")
	quit()
