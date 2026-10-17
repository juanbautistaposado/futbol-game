extends Node3D
## Spectators share the striker's baked model, atlas and small GPU batches.
const IDLE = preload("res://assets/crowd/striker_idle.res")
const CHEERING = preload("res://assets/crowd/striker_cheering.res")
const IDLE_FAR = preload("res://assets/crowd/striker_idle_far.res")
const CHEERING_FAR = preload("res://assets/crowd/striker_cheering_far.res")
const ATLAS = preload("res://assets/footballer/meshy_striker_Image_0.jpg")
const SPECTATOR_SCALE_MIN := 0.67
const SPECTATOR_SCALE_MAX := 0.75
const SUPPORTER_PALETTE := [Color("273c52"), Color("365d79"), Color("567889"),
	Color("acae9f"), Color("727872"), Color("30383c"), Color("a65448"), Color("9a875e")]
var spectator_count := 0
var crowd_material: ShaderMaterial
var distant_material: ShaderMaterial
var celebration: Tween
var batches: Dictionary = {}
var lod_chunks: Array[Dictionary] = []
var _lod_clock := 0.0

func build(seats: Array[Transform3D], rng: RandomNumberGenerator) -> void:
	crowd_material = ShaderMaterial.new()
	crowd_material.shader = preload("res://shaders/crowd.gdshader")
	crowd_material.set_shader_parameter("albedo_map",ATLAS)
	distant_material = ShaderMaterial.new()
	distant_material.shader = preload("res://shaders/crowd_impostor.gdshader")
	distant_material.set_shader_parameter("colour_atlas",preload("res://assets/crowd/striker_impostor_colour.png"))
	distant_material.set_shader_parameter("clothing_atlas",preload("res://assets/crowd/striker_impostor_mask.png"))
	for seat_index in seats.size():
		if rng.randf() > 0.82:
			continue
		spectator_count += 1
		var seat := seats[seat_index]
		var facing := seat.basis.z
		var stand_id := 0 if facing.z > 0.5 else 1 if facing.z < -0.5 else 2 if facing.x > 0.5 else 3
		var block_id := clampi(int((seat.origin.dot(seat.basis.x)+55.0)/28.0),0,3)
		var raised := rng.randf() < 0.28
		var key := "%d_%d_%s" % [stand_id,block_id,"cheering" if raised else "idle"]
		var scale := rng.randf_range(SPECTATOR_SCALE_MIN,SPECTATOR_SCALE_MAX)
		seat.origin += seat.basis*Vector3(rng.randf_range(-0.035,0.035),-0.20,rng.randf_range(-0.025,0.025))
		seat.basis = seat.basis*Basis(Vector3.UP,rng.randf_range(-0.12,0.12))*Basis.from_scale(Vector3.ONE*scale)
		# Varied supporters with a coherent wardrobe, rather than a full rainbow.
		var hue := fposmod(float(seat_index)*0.61803398875,1.0)
		var wardrobe: Color = SUPPORTER_PALETTE[rng.randi_range(0, SUPPORTER_PALETTE.size()-1)]
		var shirt := Color.from_hsv(fposmod(wardrobe.h+rng.randf_range(-0.018,0.018),1.0),
			clampf(wardrobe.s+rng.randf_range(-0.07,0.07),0.08,0.62),
			clampf(wardrobe.v*rng.randf_range(0.90,1.25),0.25,0.86))
		if not batches.has(key):
			batches[key] = {"mesh":CHEERING if raised else IDLE,"transforms":[],"colors":[],"animation":[]}
		var batch: Dictionary = batches[key]
		batch.transforms.append(seat)
		batch.colors.append(shirt)
		batch.animation.append(Color(rng.randf(),rng.randf_range(0.72,1.24),fposmod(hue+0.24,1.0),1.0 if raised else 0.0))
	_flush_batches()

func _flush_batches() -> void:
	for key in batches:
		var batch: Dictionary = batches[key]
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.use_colors = true
		mesh.use_custom_data = true
		mesh.mesh = batch.mesh
		mesh.instance_count = batch.transforms.size()
		for i in mesh.instance_count:
			mesh.set_instance_transform(i,batch.transforms[i])
			mesh.set_instance_color(i,batch.colors[i])
			mesh.set_instance_custom_data(i,batch.animation[i])
		var node := MultiMeshInstance3D.new()
		node.name = "Spectators_"+key
		node.multimesh = mesh
		node.material_override = crowd_material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.extra_cull_margin = 0.35
		add_child(node)
		var center := Vector3.ZERO
		for transform in batch.transforms: center += transform.origin
		center /= float(batch.transforms.size())
		lod_chunks.append({"node":node,"near":batch.mesh,"far":CHEERING_FAR if batch.mesh == CHEERING else IDLE_FAR,"center":center,"distant":false})
	batches.clear()
	_update_lod()

func _process(delta: float) -> void:
	_lod_clock -= delta
	if _lod_clock <= 0.0:
		_update_lod()
		_lod_clock = 0.15

func _update_lod() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	for chunk in lod_chunks:
		var world_center: Vector3 = global_transform*chunk.center
		var distance := camera.global_position.distance_to(world_center)
		var distant := distance > (17.0 if chunk.distant else 20.0) or not camera.is_position_in_frustum(world_center)
		if distant == chunk.distant: continue
		chunk.distant = distant
		chunk.node.multimesh.mesh = chunk.far if distant else chunk.near
		chunk.node.material_override = distant_material if distant else crowd_material

func celebrate() -> void:
	if celebration: celebration.kill()
	celebration = create_tween()
	celebration.tween_method(_set_cheer,0.0,1.0,0.25)
	celebration.tween_method(_set_cheer,1.0,0.0,2.8)

func _set_cheer(value: float) -> void:
	crowd_material.set_shader_parameter("cheer",value)
	distant_material.set_shader_parameter("cheer",value)
