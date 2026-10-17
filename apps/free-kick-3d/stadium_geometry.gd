extends RefCounted
## Bake the static meshes of one stand into one draw surface per shared material.
## SurfaceTool applies each source transform to vertices, normals and tangents.
static func merge_stand(parent: Node3D, first_child: int, origin: Vector3, basis: Basis) -> void:
	var groups: Dictionary = {}
	var source_nodes := parent.get_children().slice(first_child)
	for child in source_nodes:
		if not child is MeshInstance3D:
			continue
		var source := child as MeshInstance3D
		for surface in source.mesh.get_surface_count():
			var mat := source.get_active_material(surface)
			var material_key := mat.get_instance_id() if mat else 0
			if not groups.has(material_key):
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				tool.set_material(mat)
				groups[material_key] = tool
			var tool: SurfaceTool = groups[material_key]
			tool.append_from(source.mesh, surface, source.transform)
		parent.remove_child(source)
		source.free()
	var index := 0
	for material_key in groups:
		var tool: SurfaceTool = groups[material_key]
		var merged := MeshInstance3D.new()
		merged.name = "StandArchitecture_%d_%d" % [first_child, index]
		merged.mesh = tool.commit()
		merged.transform = Transform3D(basis, origin)
		parent.add_child(merged)
		index += 1
