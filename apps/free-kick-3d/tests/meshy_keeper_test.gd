extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://Main.tscn").instantiate()
	game.save_path = "/tmp/meshy-keeper-test.cfg"
	root.add_child(game)
	for keeper in [game.home_keeper, game.away_keeper]:
		var body: MeshInstance3D = keeper.goalkeeper_visual.get_node("FootballerRig/Skeleton3D/FootballerBody")
		assert(body.mesh.get_surface_count() == 11, "Misma cabeza anatómica del jugador más guantes")
		assert(keeper.skeleton.get_bone_count() == 53)
		for clip in ["Idle", "Catch", "Celebrate", "SaveLeft", "SaveRight", "SaveLowLeft", "SaveLowRight"]:
			assert(keeper.goalkeeper_animation.has_animation(clip))
		var avatar: Node3D = keeper.goalkeeper_visual
		var profile: Dictionary = load("res://footballer_model.gd").DONNARUMMA.duplicate()
		profile.shirt = "7733aa"
		keeper.build_body(profile, "ARQUERO", 1)
		assert(keeper.goalkeeper_visual == avatar)
		for i in range(body.mesh.get_surface_count()):
			var source := body.mesh.surface_get_material(i) as StandardMaterial3D
			if source.resource_name == "Jersey":
				var fabric := body.get_surface_override_material(i) as ShaderMaterial
				assert(fabric.get_shader_parameter("tint") == Color("7733aa"))
				assert(fabric.get_shader_parameter("lettering_enabled"))
			elif source.resource_name == "MeshyPlayer":
				assert((body.get_surface_override_material(i) as ShaderMaterial).get_shader_parameter("tint") == Color.WHITE)
			elif source.resource_name == "GoalkeeperGloves":
				var latex := body.get_surface_override_material(i) as ShaderMaterial
				assert(latex != null and latex.shader == preload("res://shaders/goalkeeper_latex.gdshader"), "Los guantes conservan su material de látex independiente")
		assert(avatar.get_node("JerseyPrint/Name").text == "ARQUERO")
		keeper.catch_pose(1)
		keeper.goalkeeper_animation.advance(.4)
		keeper.skeleton.force_update_all_bone_transforms()
		var left: Vector3 = keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.left_hand_bone).origin
		var right: Vector3 = keeper.skeleton.global_transform * keeper.skeleton.get_bone_global_pose(keeper.right_hand_bone).origin
		assert(keeper.held_ball_position(1).distance_to((left + right) * .5) < .001)
		assert(left.distance_to(right) < .65)
		keeper.reset_pose()
	print("PASS: ambos arqueros usan PLAYER, color/dorsal independientes y captura conserva las manos")
	quit()
