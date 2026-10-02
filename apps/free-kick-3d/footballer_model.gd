extends RefCounted
## Original procedural footballer meshes. Ring contours replace primitive limbs.
const PROFILES := [
	{"name":"MATEO", "skin":"bb8868", "hair":"29221f", "shirt":"245baa", "shorts":"172f58", "beard":false},
	{"name":"BRUNO", "skin":"70462f", "hair":"171616", "shirt":"c53938", "shorts":"252a35", "beard":true},
	{"name":"NICOLÁS", "skin":"e0b294", "hair":"70513a", "shirt":"ebebdf", "shorts":"213d6e", "beard":false}
]
const DONNARUMMA := {"name":"DONNARUMMA", "skin":"c39578", "hair":"211c19", "shirt":"648740", "shorts":"283421", "beard":true}

static func material(color: Color, cloth := false) -> Material:
	if cloth:
		var fabric := ShaderMaterial.new()
		fabric.shader = preload("res://shaders/kit.gdshader")
		fabric.set_shader_parameter("tint",color)
		return fabric
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	return mat

static func contour(parent: Node3D, pos: Vector3, rings: Array, mat: Material, segments := 32) -> MeshInstance3D:
	# Smooth the anatomical cross-sections, preserving the original joints.
	var smooth: Array = []
	for i in range(rings.size()-1):
		var a: Vector3 = rings[maxi(0,i-1)]
		var b: Vector3 = rings[i]
		var c: Vector3 = rings[i+1]
		var d: Vector3 = rings[mini(rings.size()-1,i+2)]
		for step in range(4):
			var t := float(step)/4.0
			var curve := b.cubic_interpolate(c,a,d,t)
			smooth.append(Vector3(lerpf(b.x,c.x,t),maxf(curve.y,0.001),maxf(curve.z,0.001)))
	smooth.append(rings.back())
	rings = smooth
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings.size()-1):
		for j in range(segments):
			for corner in [Vector2i(r,j),Vector2i(r+1,j+1),Vector2i(r+1,j),Vector2i(r,j),Vector2i(r,j+1),Vector2i(r+1,j+1)]:
				var ring: Vector3 = rings[corner.x]
				var angle := TAU*float(corner.y)/segments
				var prev: Vector3 = rings[maxi(corner.x-1,0)]
				var next: Vector3 = rings[mini(corner.x+1,rings.size()-1)]
				var dy := maxf(next.x-prev.x,0.001)
				var nx := cos(angle)/maxf(ring.y,0.001)
				var nz := sin(angle)/maxf(ring.z,0.001)
				var slope := nx*cos(angle)*(next.y-prev.y)/dy+nz*sin(angle)*(next.z-prev.z)/dy
				st.set_normal(Vector3(nx,-slope,nz).normalized())
				st.set_uv(Vector2(float(corner.y)/segments,float(corner.x)/(rings.size()-1)))
				st.add_vertex(Vector3(cos(angle)*ring.y,ring.x,sin(angle)*ring.z))
	var node := MeshInstance3D.new()
	st.index()
	node.mesh = st.commit()
	node.material_override = mat
	node.position = pos
	parent.add_child(node)
	return node

static func oval(parent: Node3D,pos: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.radial_segments = 20
	mesh.rings = 12
	node.mesh = mesh
	node.scale = size
	node.position = pos
	node.material_override = mat
	parent.add_child(node)
	return node

static func shirt(parent: Node3D, profile: Dictionary) -> void:
	var fabric := material(Color(profile.shirt),true)
	var shorts := material(Color(profile.shorts),true)
	var trim := material(Color("e5e7df"),true)
	contour(parent,Vector3.ZERO,[Vector3(-0.075,0.205,0.127),Vector3(0.03,0.198,0.125),Vector3(0.16,0.19,0.115),Vector3(0.29,0.219,0.144),Vector3(0.40,0.256,0.135),Vector3(0.46,0.249,0.115),Vector3(0.51,0.15,0.079),Vector3(0.53,0.077,0.063)],fabric)
	contour(parent,Vector3.ZERO,[Vector3(0.523,0.081,0.067),Vector3(0.549,0.076,0.064)],trim)
	# A continuous waistband covers the hips; legs sit inside the shorts.
	contour(parent,Vector3.ZERO,[Vector3(-0.15,0.201,0.123),Vector3(-0.05,0.207,0.129),Vector3(-0.02,0.199,0.124)],shorts)
	oval(parent,Vector3(-0.115,0.37,-0.139),Vector3(0.045,0.065,0.008),material(Color("dfc477")))

static func head(parent: Node3D,profile: Dictionary) -> void:
	var skin := material(Color(profile.skin))
	contour(parent,Vector3(0,0.50,0),[Vector3(0,0.067,0.06),Vector3(0.115,0.063,0.06)],skin)
	contour(parent,Vector3(0,0.585,0),[Vector3(0,0.04,0.054),Vector3(0.035,0.084,0.075),Vector3(0.095,0.103,0.086),Vector3(0.18,0.106,0.095),Vector3(0.235,0.089,0.077),Vector3(0.27,0.025,0.025),Vector3(0.273,0.001,0.001)],skin,32)
	var hair := material(Color(profile.hair))
	contour(parent,Vector3(0,0.585,0.008),[Vector3(0.185,0.109,0.092),Vector3(0.235,0.098,0.084),Vector3(0.28,0.06,0.059),Vector3(0.295,0.001,0.001)],hair,32)
	var dark := material(Color("272320"))
	var white := material(Color("dedbd3"))
	for side in [-1,1]:
		oval(parent,Vector3(side*0.109,0.73,0),Vector3(0.036,0.07,0.04),skin)
		oval(parent,Vector3(side*0.043,0.727,-0.082),Vector3(0.032,0.012,0.014),white)
		oval(parent,Vector3(side*0.043,0.727,-0.091),Vector3(0.011,0.011,0.006),dark)
		oval(parent,Vector3(side*0.042,0.751,-0.088),Vector3(0.052,0.011,0.013),hair)
	oval(parent,Vector3(0,0.706,-0.1),Vector3(0.035,0.064,0.044),skin)
	oval(parent,Vector3(0,0.653,-0.075),Vector3(0.05,0.013,0.018),material(Color("885b50")))
	if profile.beard:
		oval(parent,Vector3(0,0.653,-0.038),Vector3(0.135,0.072,0.096),hair)
		for side in [-1,1]:
			oval(parent,Vector3(side*0.076,0.667,-0.037),Vector3(0.024,0.085,0.078),hair)

static func arm(parent: Node3D,profile: Dictionary,glove := false) -> void:
	var skin := material(Color(profile.skin))
	var fabric := material(Color(profile.shirt),true)
	contour(parent,Vector3.ZERO,[Vector3(-0.205,0.078,0.076),Vector3(-0.12,0.09,0.088),Vector3(-0.015,0.108,0.102),Vector3(0.045,0.08,0.084),Vector3(0.064,0.005,0.005)],fabric)
	contour(parent,Vector3.ZERO,[Vector3(-0.208,0.08,0.078),Vector3(-0.188,0.082,0.08)],material(Color("e5e7df"),true))
	contour(parent,Vector3.ZERO,[Vector3(-0.30,0.054,0.054),Vector3(-0.25,0.066,0.065),Vector3(-0.19,0.076,0.074)],skin)
	var elbow := Node3D.new()
	elbow.name = "Elbow"
	elbow.position.y = -0.285
	parent.add_child(elbow)
	oval(elbow,Vector3.ZERO,Vector3(0.113,0.105,0.115),skin)
	contour(elbow,Vector3.ZERO,[Vector3(-0.245,0.038,0.037),Vector3(-0.18,0.043,0.043),Vector3(-0.09,0.065,0.06),Vector3(0.01,0.055,0.055)],skin)
	var palm := material(Color("d4ded5")) if glove else skin
	oval(elbow,Vector3(0,-0.28,-0.007),Vector3(0.099 if glove else 0.076,0.105,0.055),palm)
	for finger in range(4):
		oval(elbow,Vector3(-0.03+finger*0.02,-0.337,-0.012),Vector3(0.019,0.062,0.023),palm)
	oval(elbow,Vector3(0.048,-0.29,-0.015),Vector3(0.025,0.066,0.027),palm)
	if glove:
		contour(elbow,Vector3.ZERO,[Vector3(-0.25,0.047,0.043),Vector3(-0.217,0.049,0.046)],material(Color("273747")))
	elbow.rotation.x = 0.14

static func leg(parent: Node3D,profile: Dictionary) -> void:
	var skin := material(Color(profile.skin))
	contour(parent,Vector3.ZERO,[Vector3(-0.435,0.066,0.067),Vector3(-0.36,0.075,0.082),Vector3(-0.26,0.099,0.10),Vector3(-0.14,0.101,0.111),Vector3(-0.03,0.097,0.107),Vector3(0.02,0.085,0.09)],skin)
	# Each short leg follows its thigh so bent poses cannot expose skin through fabric.
	contour(parent,Vector3.ZERO,[Vector3(-0.285,0.112,0.118),Vector3(-0.20,0.118,0.124),Vector3(-0.10,0.12,0.125),Vector3(0.01,0.11,0.118)],material(Color(profile.shorts),true))
	contour(parent,Vector3.ZERO,[Vector3(-0.289,0.114,0.12),Vector3(-0.267,0.115,0.121)],material(Color("e5e7df"),true))
	var knee := Node3D.new()
	knee.name = "Knee"
	knee.position.y = -0.425
	parent.add_child(knee)
	oval(knee,Vector3(0,0,-0.009),Vector3(0.139,0.12,0.143),skin)
	contour(knee,Vector3.ZERO,[Vector3(-0.39,0.044,0.048),Vector3(-0.30,0.052,0.052),Vector3(-0.18,0.074,0.077),Vector3(-0.07,0.068,0.068),Vector3(-0.035,0.066,0.066)],material(Color(profile.shirt),true))
	for y in [-0.064,-0.085]:
		contour(knee,Vector3.ZERO,[Vector3(y-0.011,0.071,0.071),Vector3(y,0.071,0.071)],material(Color("e5e7df")))
	oval(knee,Vector3(0,-0.405,-0.07),Vector3(0.15,0.12,0.285),material(Color("273240")))
	oval(knee,Vector3(0,-0.448,-0.07),Vector3(0.155,0.029,0.29),material(Color("ced2c9")))
	for i in range(4):
		oval(knee,Vector3(0,-0.35,-0.03-i*0.022),Vector3(0.074,0.009,0.01),material(Color("deded5")))

static func lettering(parent: Node3D, name_text: String, number: int) -> void:
	for item in [[name_text.to_upper(),0.39,28],[str(number),0.2,68]]:
		var label := Label3D.new()
		label.text = item[0]
		label.position = Vector3(0,item[1],0.151)
		label.font_size = item[2]
		label.pixel_size = 0.002 if str(item[0]).length()<12 else 0.0015
		label.outline_size = 3
		label.modulate = Color("f0eee5")
		parent.add_child(label)

static func custom_profile(config: ConfigFile, section := "custom_striker") -> Dictionary:
	return {"name":"PERSONALIZADO", "skin":str(config.get_value(section,"skin","bb8868")), "hair":str(config.get_value(section,"hair","29221f")), "shirt":str(config.get_value(section,"shirt","245baa")), "shorts":str(config.get_value(section,"shorts","172f58")), "beard":bool(config.get_value(section,"beard",false))}

static func keeper_profile(config: ConfigFile) -> Dictionary:
	if int(config.get_value("appearance","keeper",0)) == 3:
		return custom_profile(config,"custom_keeper")
	var index := clampi(int(config.get_value("appearance","keeper",0)),0,2)
	var result: Dictionary = PROFILES[index].duplicate()
	result.shirt = ["22724f","774ba3","dc8232"][index]
	return result
