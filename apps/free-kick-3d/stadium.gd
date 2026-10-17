extends Node3D
var show_board_labels := true
var net_materials: Dictionary = {}
var net_tweens: Dictionary = {}
var net_meshes: Dictionary = {}
## Decorative stadium geometry stays separate from gameplay collisions.

func material(color: String, metal := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.roughness = 0.8
	mat.metallic = metal
	return mat

func architectural_material(color: String, roughness: float, metal: float, panel_size: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/stadium_surface.gdshader")
	mat.set_shader_parameter("base_color", Color(color))
	mat.set_shader_parameter("base_roughness", roughness)
	mat.set_shader_parameter("metalness", metal)
	mat.set_shader_parameter("panel_size", panel_size)
	return mat

func box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	add_child(node)
	return node

func beam(a: Vector3, b: Vector3, radius: float, mat: Material, radial_segments := 8) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = radial_segments
	node.mesh = mesh
	node.material_override = mat
	node.position = (a + b) * 0.5
	var direction := (b-a).normalized()
	var tangent := Vector3.RIGHT if abs(direction.dot(Vector3.RIGHT)) < 0.95 else Vector3.FORWARD
	var z := tangent.cross(direction).normalized()
	node.basis = Basis(direction.cross(z), direction, z)
	add_child(node)

func _ready() -> void:
	var turf_shader := preload("res://shaders/turf.gdshader")
	turf_shader.set_default_texture_parameter("surface_detail", preload("res://assets/turf/surface_detail.png"))
	turf_shader.set_default_texture_parameter("surface_normal", preload("res://assets/turf/surface_normal.png"))
	add_child(preload("res://pitch_grass.gd").new())
	var seats: Array[Transform3D] = []
	var colors: Array[Color] = []
	var aisle_steps: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7402
	build_stand(Vector3(0,0,-60),0,84,seats,colors,aisle_steps)
	build_stand(Vector3(0,0,60),PI,84,seats,colors,aisle_steps)
	build_stand(Vector3(-41,0,0),PI/2,110,seats,colors,aisle_steps)
	build_stand(Vector3(41,0,0),-PI/2,110,seats,colors,aisle_steps)
	build_seats(seats,colors)
	build_aisle_steps(aisle_steps)
	build_crowd(seats,rng)
	add_child(preload("res://stadium_pitch_details.gd").new())
	preload("res://stadium_dressing.gd").build(self)
	var steel := material("677985",0.45)
	var dark := material("1b2a36")
	var lamp := material("fff4dc")
	lamp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for x in [-38,38]:
		for z in [-57,57]:
			beam(Vector3(x,0,z),Vector3(x,24,z),0.2,steel)
			box(Vector3(x,24,z),Vector3(6,2,0.4),dark)
			for col in range(8):
				box(Vector3(x-2.6+col*0.75,24,z-sign(z)*0.25),Vector3(0.5,1.4,0.08),lamp)
			var light := SpotLight3D.new()
			light.position = Vector3(x,23,z)
			light.light_color = Color("e4eeff")
			light.light_energy = 1.1
			light.spot_range = 150
			light.spot_angle = 55
			add_child(light)
			light.look_at(Vector3.ZERO)
	var board_trim := material("5ba8a7")
	for side in [-1,1]:
		for i in range(6):
			var x := -30.0+i*12.0
			var board_color := material("17394d" if i%3 == 0 else "205361" if i%3 == 1 else "293d50")
			box(Vector3(x,0.65,side*57),Vector3(11.8,1.18,0.2),board_color)
			box(Vector3(x,1.245,side*56.86),Vector3(11.8,0.035,0.09),board_trim)
			if show_board_labels:
				var label := Label3D.new()
				label.text = "TIROS LIBRES" if i%2 == 0 else "CLUB 3D"
				label.font_size = 64
				label.pixel_size = 0.01
				label.modulate = Color("d7e9e8")
				label.position = Vector3(x,0.65,side*56.82)
				if side == 1: label.rotation.y = PI
				add_child(label)
	for side in [-1,1]:
		for i in range(8):
			var z := -45.5+i*13.0
			var panel := material("214b5c" if i%2 == 0 else "243d51")
			box(Vector3(side*37,0.62,z),Vector3(0.2,1.12,12.8),panel)
			box(Vector3(side*36.87,1.23,z),Vector3(0.08,0.09,12.8),lamp)

func build_stand(origin: Vector3, angle: float, width: float, seats: Array[Transform3D], colors: Array[Color], aisle_steps: Array[Transform3D]) -> void:
	var first := get_child_count()
	var concrete := architectural_material("676b69", 0.91, 0.0, 2.8)
	var steel := material("9aa6af", 0.48)
	var roof := architectural_material("343f48", 0.49, 0.48, 1.2)
	var fascia := architectural_material("283c4d", 0.64, 0.18, 3.2)
	var accent := material("4d819e")
	var aisle := material("34444f")
	var opening := material("17232d")
	var edge := material("c0c9cc")
	var light_strip := material("d6e6ed")
	light_strip.emission_enabled = true
	light_strip.emission = Color("a3c5da")
	light_strip.emission_energy_multiplier = 0.65
	var basis := Basis(Vector3.UP, angle)
	var count := int(width/0.58)
	for row in range(24):
		var upper := row >= 12
		var depth := row*0.82 + (2.0 if upper else 0.0)
		var height := 0.9+row*0.49+(1.0 if upper else 0.0)
		box(Vector3(0, height/2, -depth), Vector3(width, height, 0.83), concrete)
		for column in count:
			# Dedicated stair aisles separate the coloured seating blocks.
			if column % 24 < 3: continue
			var pos := Vector3((column-count/2.0)*0.58, height+0.2, -depth)
			seats.append(Transform3D(basis, origin+basis*pos))
			var section := int(column/24)
			var band := (row + section*2) % 12
			colors.append(Color("214257") if band < 7 else Color("466777") if band < 10 else Color("8d9b9d"))
		for aisle_start in range(0, count, 24):
			var step_x := (aisle_start+1.0-count/2.0)*0.58
			aisle_steps.append(Transform3D(basis, origin+basis*Vector3(step_x, height+0.035, -depth)))
			# Thin safety rails follow each seating tier without screening the crowd.
			if row % 4 == 0:
				beam(Vector3(step_x-0.7, height, -depth), Vector3(step_x-0.7, height+0.84, -depth), 0.027, steel)
			if row != 11 and row != 23:
				beam(Vector3(step_x-0.7, height+0.84, -depth), Vector3(step_x-0.7, height+1.33, -depth-0.82), 0.023, steel)
		if row == 23:
			beam(Vector3(-width/2, height+0.8, -depth+0.42), Vector3(width/2, height+0.8, -depth+0.42), 0.035, steel)
			for x in range(-int(width/2), int(width/2), 4):
				beam(Vector3(x, height, -depth+0.42), Vector3(x, height+0.8, -depth+0.42), 0.025, steel)
	# A recessed concourse and its fascia distinguish the lower and upper tiers.
	box(Vector3(0, 6.76, -10.3), Vector3(width, 0.16, 2.15), concrete)
	box(Vector3(0, 6.42, -9.49), Vector3(width, 0.83, 0.24), fascia)
	box(Vector3(0, 6.88, -9.34), Vector3(width, 0.085, 0.29), edge)
	beam(Vector3(-width/2, 7.65, -10.0), Vector3(width/2, 7.65, -10.0), 0.032, steel)
	for x in range(-int(width/2), int(width/2), 4):
		beam(Vector3(x, 6.87, -10.0), Vector3(x, 7.65, -10.0), 0.026, steel)
	# Simple supporter banners sit below the spectators and stay out of play.
	for x in range(-int(width/2)+6, int(width/2)-3, 14):
		box(Vector3(x, 6.37, -9.34), Vector3(8.4, 0.46, 0.035), accent)
		box(Vector3(x, 6.37, -9.31), Vector3(0.14, 0.47, 0.015), edge)
	# Front barrier, tunnel portals and access markers make the bowl read as a venue.
	box(Vector3(0, 0.52, 0.51), Vector3(width, 0.86, 0.2), fascia)
	box(Vector3(0, 0.97, 0.52), Vector3(width, 0.07, 0.23), edge)
	for aisle_start in range(0, count, 24):
		var x := (aisle_start+1.0-count/2.0)*0.58
		box(Vector3(x, 1.15, -0.25), Vector3(1.50, 2.3, 0.09), opening)
		box(Vector3(x, 2.38, -0.15), Vector3(1.64, 0.16, 0.14), accent)
		for side in [-1.0, 1.0]:
			box(Vector3(x+side*0.82, 1.14, -0.14), Vector3(0.12, 2.4, 0.14), steel)
		box(Vector3(x, 2.4, -0.063), Vector3(0.55, 0.085, 0.035), light_strip)
	# Canopy: layered edge, visible soffit trusses, and a slim luminous underside.
	box(Vector3(0, 16.05, -12), Vector3(width+2, 0.35, 25), roof)
	box(Vector3(0, 15.60, 0.4), Vector3(width+2, 0.50, 0.25), fascia)
	box(Vector3(0, 15.94, 0.43), Vector3(width+2, 0.10, 0.28), accent)
	box(Vector3(0, 15.32, -0.25), Vector3(width, 0.055, 0.12), light_strip)
	for x in range(-int(width/2), int(width/2)+1, 7):
		box(Vector3(x, 15.72, -12), Vector3(0.13, 0.15, 23.5), steel)
	box(Vector3(0, 8, -22), Vector3(width, 16, 0.4), concrete)
	for x in range(-int(width/2)+9, int(width/2), 20):
		box(Vector3(x, 9.8, -21.73), Vector3(3.5, 3.8, 0.08), opening)
		box(Vector3(x, 11.8, -21.64), Vector3(3.8, 0.16, 0.12), accent)
	for x in range(-int(width/2), int(width/2)+1, 6):
		beam(Vector3(x, 0, -22), Vector3(x, 16, -22), 0.14, steel)
		beam(Vector3(x, 16, -22), Vector3(x, 15.5, 0), 0.085, steel)
		beam(Vector3(x, 13, -22), Vector3(x, 15.5, -5), 0.06, steel)
	preload("res://stadium_geometry.gd").merge_stand(self, first, origin, basis)

func build_seats(transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var pan := BoxMesh.new()
	pan.size = Vector3(0.48,0.10,0.43)
	var back := BoxMesh.new()
	back.size = Vector3(0.48,0.45,0.09)
	var backs: Array[Transform3D] = []
	for seat in transforms:
		backs.append(seat.translated_local(Vector3(0,0.22,-0.17)))
	add_instances(pan,transforms,colors)
	add_instances(back,backs,colors)

func build_aisle_steps(transforms: Array[Transform3D]) -> void:
	var tread := BoxMesh.new()
	tread.size = Vector3(1.70,0.07,0.70)
	var colors: Array[Color] = []
	colors.resize(transforms.size())
	colors.fill(Color("53616b"))
	add_instances(tread,transforms,colors)

func add_instances(mesh: PrimitiveMesh, transforms: Array[Transform3D], colors: Array[Color]) -> void:
	if transforms.is_empty():
		return
	var mat := material("ffffff")
	mat.vertex_color_use_as_albedo = true
	mesh.material = mat
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	for i in transforms.size():
		instances.set_instance_transform(i,transforms[i])
		instances.set_instance_color(i,colors[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = instances
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)

func goal(side: int) -> void:
	var white := material("f2f5ef", 0.12)
	white.roughness = 0.32
	var support := material("c4cec9", 0.35)
	support.roughness = 0.48
	var foot := material("52615d", 0.3)
	# Keep the playable frame exactly aligned with the existing goal collisions.
	for x in [-4.2,4.2]:
		beam(Vector3(x,0,side*52.5),Vector3(x,2.9,side*52.5),0.08,white,24)
		beam(Vector3(x,2.9,side*52.5),Vector3(x,2.9,side*54.3),0.027,support,16)
		beam(Vector3(x,0.04,side*54.3),Vector3(x,2.9,side*54.3),0.025,support,16)
		beam(Vector3(x,0.04,side*52.5),Vector3(x,0.04,side*54.3),0.027,support,16)
		box(Vector3(x,0.025,side*54.3),Vector3(0.14,0.05,0.20),foot)
		var corner := MeshInstance3D.new()
		var joint := SphereMesh.new()
		joint.radius = 0.08
		joint.height = 0.16
		joint.radial_segments = 24
		joint.rings = 12
		corner.mesh = joint
		corner.material_override = white
		corner.position = Vector3(x,2.9,side*52.5)
		add_child(corner)
	beam(Vector3(-4.2,2.9,side*52.5),Vector3(4.2,2.9,side*52.5),0.08,white,24)
	beam(Vector3(-4.2,0.04,side*54.3),Vector3(4.2,0.04,side*54.3),0.025,support,16)
	# Four-sided cords share one draw surface. Real thickness survives perspective
	# and lighting; even spacing keeps the back, sides and roof grid connected.
	var mesh := ImmediateMesh.new()
	var net_material := ShaderMaterial.new()
	net_material.shader = preload("res://shaders/net.gdshader")
	net_material.set_shader_parameter("side",float(side))
	net_materials[side] = net_material
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,net_material)
	for i in range(43):
		var x := -4.2+i*8.4/42.0
		net_line(mesh,Vector3(x,0,side*54.3),Vector3(x,2.9,side*54.3))
		net_line(mesh,Vector3(x,2.9,side*54.3),Vector3(x,2.9,side*52.5))
	for i in range(16):
		var y := i*2.9/15.0
		net_line(mesh,Vector3(-4.2,y,side*54.3),Vector3(4.2,y,side*54.3))
		for x in [-4.2,4.2]:
			net_line(mesh,Vector3(x,y,side*52.5),Vector3(x,y,side*54.3))
	for i in range(10):
		var z: float = side*(52.5+i*1.8/9)
		for x in [-4.2,4.2]:
			net_line(mesh,Vector3(x,0,z),Vector3(x,2.9,z))
		net_line(mesh,Vector3(-4.2,2.9,z),Vector3(4.2,2.9,z))
	mesh.surface_end()
	var net := MeshInstance3D.new()
	net.name = "NetHome" if side == 1 else "NetAway"
	net.mesh = mesh
	net.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(net)
	net_meshes[side] = net

func set_net_opacity(side: int, opacity: float) -> void:
	(net_materials[side] as ShaderMaterial).set_shader_parameter("opacity", clampf(opacity, 0.0, 1.0))

func build_crowd(seats: Array[Transform3D], rng: RandomNumberGenerator) -> void:
	var crowd := preload("res://stadium_crowd.gd").new()
	crowd.name = "StadiumCrowd"
	add_child(crowd)
	crowd.build(seats, rng)

func net_line(mesh: ImmediateMesh, a: Vector3, b: Vector3) -> void:
	var segments := maxi(1,ceili(a.distance_to(b)/0.20))
	var direction := (b-a).normalized()
	var tangent := Vector3.RIGHT if abs(direction.dot(Vector3.RIGHT)) < 0.95 else Vector3.UP
	var radial_a := direction.cross(tangent).normalized()
	var radial_b := direction.cross(radial_a).normalized()
	var radius := 0.005
	for i in segments:
		var start := a.lerp(b,float(i)/segments)
		var end := a.lerp(b,float(i+1)/segments)
		for face in 4:
			var angle_a := TAU*face/4.0
			var angle_b := TAU*(face+1)/4.0
			var normal_a := radial_a*cos(angle_a)+radial_b*sin(angle_a)
			var normal_b := radial_a*cos(angle_b)+radial_b*sin(angle_b)
			var points := [start+normal_a*radius,end+normal_a*radius,end+normal_b*radius,start+normal_b*radius]
			for index in [0,1,2,0,2,3]:
				mesh.surface_set_normal(normal_a if index < 2 else normal_b)
				mesh.surface_set_uv(Vector2(float(i+1 if index in [1,2] else i)/segments,float(face+(1 if index > 1 else 0))/4.0))
				mesh.surface_add_vertex(points[index])

func ripple_net(side: int, point: Vector3) -> void:
	var crowd := get_node_or_null("StadiumCrowd")
	if crowd != null:
		crowd.celebrate()
	if net_tweens.has(side): net_tweens[side].kill()
	var mat: ShaderMaterial = net_materials[side]
	mat.set_shader_parameter("impact",point)
	mat.set_shader_parameter("age",0.0)
	var motion := create_tween()
	net_tweens[side] = motion
	motion.tween_method(func(age: float) -> void: mat.set_shader_parameter("age",age),0.0,1.4,1.4)
