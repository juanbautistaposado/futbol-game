extends SceneTree
## Render complete striker silhouettes for the far crowd, with a separate clothing mask.
## Baking keeps every triangle of the valid near mesh; no topology clustering is used.
const TILE := Vector2i(256,352)
const VIEWS := 8
const CARD_HEIGHT := 2.15
const CARD_WIDTH := CARD_HEIGHT*float(TILE.x)/float(TILE.y)
const ATLAS = preload("res://assets/footballer/meshy_striker_Image_0.jpg")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Crowd atlas baking requires the native renderer.")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = TILE
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_CLEAR_COLOR
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("cfdae1")
	settings.ambient_light_energy = 0.62
	settings.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = settings
	viewport.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40,-35,0)
	sun.light_color = Color("fff5e8")
	sun.light_energy = 0.88
	viewport.add_child(sun)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CARD_HEIGHT
	camera.current = true
	viewport.add_child(camera)
	var body := MeshInstance3D.new()
	viewport.add_child(body)
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform bool paint_mask = false;
uniform sampler2D albedo_map : source_color,filter_linear_mipmap;
void fragment() {
	vec3 original = texture(albedo_map,UV).rgb;
	float dark = 1.0-smoothstep(0.06,0.18,max(original.r,max(original.g,original.b)));
	float shorts = UV2.y*dark;
	if (paint_mask) {
		ALBEDO = vec3(0.0);
		EMISSION = vec3(UV2.x,shorts,0.0);
	} else {
		ALBEDO = mix(original,vec3(0.72),shorts);
	}
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("albedo_map",ATLAS)
	body.material_override = material
	var colour := Image.create(TILE.x*VIEWS,TILE.y*2,false,Image.FORMAT_RGBA8)
	var mask := Image.create(TILE.x*VIEWS,TILE.y*2,false,Image.FORMAT_RGBA8)
	for pose in 2:
		var pose_name := "idle" if pose == 0 else "cheering"
		body.mesh = load("res://assets/crowd/striker_"+pose_name+".res")
		for view in VIEWS:
			var angle := TAU*float(view)/float(VIEWS)
			var target := Vector3(0,1.045,0)
			camera.position = target+Vector3(sin(angle)*4,0,cos(angle)*4)
			camera.look_at(target)
			for pass_index in 2:
				material.set_shader_parameter("paint_mask",pass_index == 1)
				for frame in 3: await RenderingServer.frame_post_draw
				var tile := viewport.get_texture().get_image()
				tile.convert(Image.FORMAT_RGBA8)
				var atlas := colour if pass_index == 0 else mask
				atlas.blit_rect(tile,Rect2i(Vector2i.ZERO,TILE),Vector2i(view*TILE.x,pose*TILE.y))
		var card := _make_card(pose_name)
		assert(ResourceSaver.save(card,"res://assets/crowd/striker_"+pose_name+"_far.res") == OK)
	assert(colour.save_png("res://assets/crowd/striker_impostor_colour.png") == OK)
	assert(mask.save_png("res://assets/crowd/striker_impostor_mask.png") == OK)
	print("CROWD_IMPOSTORS: complete silhouettes, ",VIEWS," views x 2 poses, ",colour.get_size())
	viewport.queue_free()
	quit()

func _make_card(pose_name: String) -> ArrayMesh:
	var half_width := CARD_WIDTH*0.5
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-half_width,-0.03,0),Vector3(half_width,-0.03,0),Vector3(-half_width,2.12,0),Vector3(half_width,2.12,0)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK,Vector3.BACK,Vector3.BACK,Vector3.BACK])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(1,0)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0,1,2,2,1,3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.custom_aabb = AABB(Vector3(-0.80,-0.10,-0.80),Vector3(1.60,2.40,1.60))
	mesh.set_meta("source_avatar","res://assets/footballer/meshy_striker.glb")
	mesh.set_meta("pose",pose_name)
	mesh.set_meta("distant",true)
	mesh.set_meta("complete_silhouette",true)
	return mesh
