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

func box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = pos
	add_child(node)
	return node

func beam(a: Vector3, b: Vector3, radius: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	node.mesh = mesh
	node.material_override = mat
	node.position = (a + b) * 0.5
	var direction := (b-a).normalized()
	var tangent := Vector3.RIGHT if abs(direction.dot(Vector3.RIGHT)) < 0.95 else Vector3.FORWARD
	var z := tangent.cross(direction).normalized()
	node.basis = Basis(direction.cross(z), direction, z)
	add_child(node)

func _ready() -> void:
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
	var concrete := material("43515c")
	var steel := material("84939b",0.4)
	var roof := material("263847",0.25)
	var fascia := material("1a3040",0.18)
	var accent := material("3d7887")
	var gold := material("a98c5f",0.12)
	var aisle := material("33424d")
	var basis := Basis(Vector3.UP,angle)
	for row in range(24):
		var upper := row >= 12
		var depth := row*0.82 + (2.0 if upper else 0.0)
		var height := 0.9+row*0.49+(1.0 if upper else 0.0)
		box(Vector3(0,height/2,-depth),Vector3(width,height,0.83),concrete)
		var count := int(width/0.58)
		for column in count:
			# Unoccupied strips form stair aisles between seating sections.
			if column % 24 < 3: continue
			var pos := Vector3((column-count/2.0)*0.58,height+0.2,-depth)
			seats.append(Transform3D(basis,origin+basis*pos))
			var section := int(column/24)
			colors.append(Color("24495d") if (row + section*3)%12<7 else Color("376875") if row%12<10 else Color("738a8d"))
		for aisle_start in range(0,count,24):
			var step_x := (aisle_start+1.0-count/2.0)*0.58
			aisle_steps.append(Transform3D(basis,origin+basis*Vector3(step_x,height+0.035,-depth)))
		if row == 11 or row == 23:
			beam(Vector3(-width/2,height+0.8,-depth+0.42),Vector3(width/2,height+0.8,-depth+0.42),0.035,steel)
			for x in range(-int(width/2),int(width/2),4):
				beam(Vector3(x,height,-depth+0.42),Vector3(x,height+0.8,-depth+0.42),0.025,steel)
	box(Vector3(0,16,-12),Vector3(width+2,0.35,25),roof)
	box(Vector3(0,15.6,0.4),Vector3(width+2,0.48,0.25),fascia)
	box(Vector3(0,15.93,0.43),Vector3(width+2,0.10,0.28),accent)
	box(Vector3(0,7.9,-10.25),Vector3(width,1.15,0.35),fascia)
	box(Vector3(0,8.5,-10.1),Vector3(width,0.11,0.38),gold)
	for x in range(-int(width/2)+5,int(width/2),12):
		box(Vector3(x,7.9,-10.03),Vector3(0.13,0.92,0.07),accent)
	for x in range(-int(width/2),int(width/2)+1,7):
		box(Vector3(x,15.72,-12),Vector3(0.13,0.15,23.5),steel)
	box(Vector3(0,8,-22),Vector3(width,16,0.4),concrete)
	for x in range(-int(width/2)+9,int(width/2),20):
		box(Vector3(x,5.0,-21.73),Vector3(3.5,5.2,0.08),aisle)
		box(Vector3(x,7.7,-21.64),Vector3(3.8,0.16,0.12),gold)
	for x in range(-int(width/2),int(width/2)+1,6):
		beam(Vector3(x,0,-22),Vector3(x,16,-22),0.14,steel)
		beam(Vector3(x,16,-22),Vector3(x,15.5,0),0.085,steel)
		beam(Vector3(x,13,-22),Vector3(x,15.5,-5),0.06,steel)
	for i in range(first,get_child_count()):
		var child: Node3D = get_child(i)
		child.position = origin+basis*child.position
		child.basis = basis*child.basis

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
	var white := material("e7ece5", 0.12)
	for x in [-4.2,4.2]:
		beam(Vector3(x,0,side*52.5),Vector3(x,2.9,side*52.5),0.08,white)
		beam(Vector3(x,2.9,side*52.5),Vector3(x,0.05,side*54.3),0.035,white)
	beam(Vector3(-4.2,2.9,side*52.5),Vector3(4.2,2.9,side*52.5),0.08,white)
	# One mesh for the complete fine net, including back, sides and roof.
	var mesh := ImmediateMesh.new()
	var net_material := ShaderMaterial.new()
	net_material.shader = preload("res://shaders/net.gdshader")
	net_material.set_shader_parameter("side",float(side))
	net_materials[side] = net_material
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,net_material)
	for i in range(57):
		var x := -4.2+i*0.15
		net_line(mesh,Vector3(x,0,side*54.3),Vector3(x,2.9,side*54.3))
		net_line(mesh,Vector3(x,2.9,side*54.3),Vector3(x,2.9,side*52.5))
	for i in range(18):
		var y := i*2.9/17
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
	var torsos: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var hair: Array[Transform3D] = []
	var shirts: Array[Color] = []
	var skins: Array[Color] = []
	var hair_colors: Array[Color] = []
	var palette := [Color("203d54"),Color("356477"),Color("8e7255"),Color("a1aaa9"),Color("394552"),Color("765550")]
	var skin_palette := [Color("cfa282"),Color("b78a6b"),Color("966a51"),Color("694635")]
	var hair_palette := [Color("252229"),Color("493426"),Color("9b7151"),Color("67737b")]
	for seat in seats:
		if rng.randf() > 0.65: continue
		torsos.append(seat.translated_local(Vector3(0,0.53,0)))
		heads.append(seat.translated_local(Vector3(0,0.93,0)))
		hair.append(seat.translated_local(Vector3(0,1.05,0)))
		shirts.append(palette[rng.randi_range(0, palette.size()-1)])
		skins.append(skin_palette[rng.randi_range(0, skin_palette.size()-1)])
		hair_colors.append(hair_palette[rng.randi_range(0, hair_palette.size()-1)])
	var torso := CylinderMesh.new()
	torso.top_radius = 0.15
	torso.bottom_radius = 0.20
	torso.height = 0.52
	torso.radial_segments = 8
	add_instances(torso,torsos,shirts)
	var head := SphereMesh.new()
	head.radius = 0.15
	head.height = 0.30
	head.radial_segments = 8
	head.rings = 4
	add_instances(head,heads,skins)
	var cap := SphereMesh.new()
	cap.radius = 0.15
	cap.height = 0.12
	cap.radial_segments = 8
	cap.rings = 3
	add_instances(cap,hair,hair_colors)

func net_line(mesh: ImmediateMesh, a: Vector3, b: Vector3) -> void:
	var segments := maxi(1,ceili(a.distance_to(b)/0.15))
	for i in segments:
		mesh.surface_add_vertex(a.lerp(b,float(i)/segments))
		mesh.surface_add_vertex(a.lerp(b,float(i+1)/segments))

func ripple_net(side: int, point: Vector3) -> void:
	if net_tweens.has(side): net_tweens[side].kill()
	var mat: ShaderMaterial = net_materials[side]
	mat.set_shader_parameter("impact",point)
	mat.set_shader_parameter("age",0.0)
	var motion := create_tween()
	net_tweens[side] = motion
	motion.tween_method(func(age: float) -> void: mat.set_shader_parameter("age",age),0.0,1.4,1.4)
