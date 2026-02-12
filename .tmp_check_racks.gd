extends SceneTree

func _init() -> void:
	var sc: PackedScene = load("res://ui/GameTable3D.tscn") as PackedScene
	var n := sc.instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	var racks: Array = n.get("_world_racks")
	print("racks:", racks.size())
	for i in range(racks.size()):
		var rack := racks[i] as Node3D
		if rack == null:
			continue
		var visual := rack.get_node_or_null("Visual") as Node3D
		var model := rack.get_node_or_null("Visual/Model") as Node3D
		var bn := _find_black_normal(model)
		var world_n := (visual.global_transform.basis * bn).normalized()
		var to_center := (Vector3.ZERO - rack.global_position)
		to_center.y = 0.0
		world_n.y = 0.0
		if to_center.length() > 0.0001:
			to_center = to_center.normalized()
		if world_n.length() > 0.0001:
			world_n = world_n.normalized()
		print("rack", i, "pos", rack.global_position, "rot", rack.rotation_degrees, "bn_local", bn, "world_n", world_n, "dot", world_n.dot(to_center))
	n.queue_free()
	quit(0)

func _find_black_normal(root: Node3D) -> Vector3:
	if root == null:
		return Vector3(0,0,-1)
	var stats: Array[Dictionary] = []
	_collect(root, Transform3D.IDENTITY, stats)
	var best_luma := 999.0
	var best_n := Vector3(0,0,-1)
	for st in stats:
		var c: Color = st.get("color", Color(0.5,0.5,0.5))
		var n: Vector3 = st.get("normal", Vector3.ZERO)
		if n.length() < 0.0001:
			continue
		var luma := c.r + c.g + c.b
		if luma < best_luma:
			best_luma = luma
			best_n = n.normalized()
	return best_n

func _collect(node: Node, parent_xf: Transform3D, out_stats: Array[Dictionary]) -> void:
	if node is not Node3D:
		return
	var n3d := node as Node3D
	var xform: Transform3D = parent_xf * n3d.transform
	if n3d is MeshInstance3D:
		var mi := n3d as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				var arrays: Array = mi.mesh.surface_get_arrays(s)
				var verts = arrays[Mesh.ARRAY_VERTEX]
				if verts is not PackedVector3Array:
					continue
				var count: int = (verts as PackedVector3Array).size()
				if count <= 0:
					continue
				var normal: Vector3 = Vector3.ZERO
				var normals = arrays[Mesh.ARRAY_NORMAL]
				if normals is PackedVector3Array and (normals as PackedVector3Array).size() == count:
					for nn in normals as PackedVector3Array:
						normal += (xform.basis * nn).normalized()
				if normal.length() > 0.0001:
					normal = normal.normalized()
				out_stats.append({"color": _get_surface_color(mi, s), "normal": normal})
	for child in n3d.get_children():
		_collect(child, xform, out_stats)

func _get_surface_color(mi: MeshInstance3D, surface_idx: int) -> Color:
	var mat: Material = mi.get_surface_override_material(surface_idx)
	if mat == null and mi.mesh != null:
		mat = mi.mesh.surface_get_material(surface_idx)
	if mat is BaseMaterial3D:
		return (mat as BaseMaterial3D).albedo_color
	return Color(0.5,0.5,0.5,1)
