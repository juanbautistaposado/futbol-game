extends RefCounted
## Shared static venue furniture outside the pitch. No gameplay collision.
static func build(stadium: Node3D) -> void:
	var first := stadium.get_child_count()
	var rubber: Material = stadium.architectural_material("344442", 0.94, 0.0, 2.5)
	var casing: Material = stadium.architectural_material("263640", 0.62, 0.15, 2.0)
	var metal: Material = stadium.material("929b9e", 0.65)
	var dark: Material = stadium.material("22292d")
	var cushions: Material = stadium.material("34566b")
	# Service apron separates the green playing surface from the advertising edge.
	for side in [-1.0, 1.0]:
		stadium.box(Vector3(side*35.55,0.004,0),Vector3(2.8,0.008,105.0),rubber)
		stadium.box(Vector3(0,0.004,side*54.75),Vector3(74.0,0.008,4.3),rubber)
		# Team benches are aligned along the sideline, behind the advertising boards.
		var x: float = side*39.0
		stadium.box(Vector3(x,0.11,-10),Vector3(2.7,0.22,9.3),dark)
		stadium.box(Vector3(x+side*1.24,1.35,-10),Vector3(0.10,2.5,9.3),casing)
		stadium.box(Vector3(x,2.6,-10),Vector3(2.9,0.16,9.6),casing)
		for z in [-14.55,-5.45]:
			stadium.beam(Vector3(x-side*1.15,0.1,z),Vector3(x-side*1.15,2.55,z),0.045,metal)
			stadium.beam(Vector3(x-side*1.15,2.55,z),Vector3(x+side*1.2,2.55,z),0.045,metal)
		for seat in range(11):
			var z := -14.0+seat*0.8
			stadium.box(Vector3(x,0.57,z),Vector3(0.65,0.15,0.58),cushions)
			stadium.box(Vector3(x+side*0.30,0.94,z),Vector3(0.12,0.68,0.58),cushions)
		# Television cameras frame the goals from the service apron.
		for edge in [-1.0,1.0]:
			var camera_origin := Vector3(edge*12.3,0,side*55.5)
			for leg in range(3):
				var angle := leg*TAU/3.0
				stadium.beam(camera_origin+Vector3(cos(angle)*0.34,0.02,sin(angle)*0.34),camera_origin+Vector3(0,1.20,0),0.023,metal)
			stadium.box(camera_origin+Vector3(0,1.34,0),Vector3(0.34,0.30,0.51),dark)
			stadium.box(camera_origin+Vector3(0,1.35,-side*0.30),Vector3(0.23,0.21,0.18),casing)
	preload("res://stadium_geometry.gd").merge_stand(stadium,first,Vector3.ZERO,Basis.IDENTITY)
