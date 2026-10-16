class_name OkeyTableArt
extends RefCounted
## Shared procedural meshes for the seated Okey table. Units are metres.
## Standing tiles face +Z. Flat tiles face +Y (rotation.x = -PI / 2).
## Tile origin is its centre; lettering belongs at local z = 0.0048.

const TILE_SIZE := Vector3(0.045, 0.065, 0.009)
const FELT_SHADER = preload("res://ui/game_table/art/felt.gdshader")
const WOOD_SHADER = preload("res://ui/game_table/art/wood.gdshader")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build_table(parent: Node3D, surface_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "CraftedOkeyTable"
	root.position.y = surface_y
	parent.add_child(root)
	var wood := _shader_material("walnut", WOOD_SHADER)
	var plum := _material("plum", Color("2a170e"), 0.36)
	var inset := _material("inset", Color("142c30"), 0.85)
	var brass := _material("brass_inlay", Color("b59659"), 0.32)
	# Nested rounded shells create a continuous wood rim with a fine brass inlay.
	_piece(root, "WalnutBase", Vector3(1.26, 0.062, 1.04), Vector3(0, -0.041, 0), 0.026, wood)
	_ring(root, "WalnutFrame", Vector2(1.26, 1.04), Vector2(1.204, 0.984), 0.032, -0.025, 0.009, 0.0035, wood)
	_ring(root, "BrassInlay", Vector2(1.207, 0.987), Vector2(1.168, 0.948), 0.022, -0.012, 0.004, 0.002, brass)
	_piece(root, "FeltBinding", Vector3(1.170, 0.020, 0.950), Vector3(0, -0.009, 0), 0.009, inset)
	_piece(root, "WovenTealFelt", Vector3(1.158, 0.016, 0.938), Vector3(0, -0.008, 0), 0.007, _shader_material("felt", FELT_SHADER))
	# A dark apron and a second wood bead give the edge a crafted profile.
	_piece(root, "PlumApron", Vector3(1.242, 0.033, 1.022), Vector3(0, -0.081, 0), 0.014, plum)
	_piece(root, "LowerWoodBead", Vector3(1.254, 0.014, 1.034), Vector3(0, -0.097, 0), 0.006, wood)
	return root


static func build_rack(width: float = 0.82, height: float = 0.05, depth: float = 0.15) -> Node3D:
	var root := Node3D.new()
	root.name = "SculptedTwoTierRack"
	var shell := _material("rack_walnut", Color("452717"), 0.36)
	var edge := _material("rack_walnut_edge", Color("5a3521"), 0.40)
	var bed := _material("rack_bed", Color("22130b"), 0.80)
	var gold := _material("rack_badge", Color("c4a46c"), 0.38)
	var sy := height / 0.05
	# The rack is assembled from chamfered supports with open, recessed tile beds.
	_piece(root, "RoundedPlumBase", Vector3(width, 0.023 * sy, depth), Vector3(0, -0.009 * sy, 0), 0.010, shell)
	_piece(root, "LowerRecess", Vector3(width - 0.034, 0.008 * sy, depth * 0.49), Vector3(0, 0.005 * sy, depth * 0.235), 0.003, bed)
	_piece(root, "UpperSupport", Vector3(width - 0.020, 0.047 * sy, depth * 0.48), Vector3(0, 0.021 * sy, -depth * 0.255), 0.009, shell)
	_piece(root, "UpperRecess", Vector3(width - 0.034, 0.007 * sy, depth * 0.39), Vector3(0, 0.0445 * sy, -depth * 0.22), 0.0028, bed)
	_piece(root, "LowFrontLip", Vector3(width - 0.012, 0.022 * sy, 0.013), Vector3(0, 0.006 * sy, depth * 0.46), 0.005, edge)
	_piece(root, "UpperToeRail", Vector3(width - 0.030, 0.008 * sy, 0.008), Vector3(0, 0.049 * sy, -depth * 0.04), 0.003, edge)
	_piece(root, "RearRoundedRail", Vector3(width - 0.012, 0.037 * sy, 0.017), Vector3(0, 0.049 * sy, -depth * 0.455), 0.007, edge)
	for side in [-1.0, 1.0]:
		_piece(root, "CurvedSide", Vector3(0.019, 0.065 * sy, depth - 0.010), Vector3(side * (width * 0.5 - 0.011), 0.015 * sy, 0), 0.008, shell)
	_piece(root, "MakerInlay", Vector3(0.033, 0.004 * sy, 0.0015), Vector3(0, -0.007 * sy, depth * 0.502), 0.00065, gold)
	return root


static func build_tile(standing: bool = true, face_up: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "IvoryTile"
	# Geometry is shared across every tile. Rounded edges catch the key light.
	_piece(root, "IvoryBody", TILE_SIZE, Vector3.ZERO, 0.0028, _material("tile_ivory", Color("f4e6c6"), 0.36))
	if face_up:
		_piece(root, "InsetFace", Vector3(0.0402, 0.0598, 0.00065), Vector3(0, 0, 0.0042), 0.0004, _material("tile_face", Color("faf0d7"), 0.46))
		_piece(root, "PipWell", Vector3(0.0096, 0.0096, 0.00045), Vector3(0, -0.0130, 0.00445), 0.0046, _material("tile_pip_well", Color("dfd0b0"), 0.65))
	else:
		# A restrained inset on the concealed back distinguishes it from the face.
		_piece(root, "BackInset", Vector3(0.032, 0.050, 0.0006), Vector3(0, 0, 0.0042), 0.00025, _material("tile_back", Color("e8d6af"), 0.54))
	if not standing:
		root.rotation.x = -PI * 0.5
	return root


static func material(key: String) -> Material:
	if _materials.has(key):
		return _materials[key] as Material
	match key:
		"walnut":
			return _shader_material("walnut", WOOD_SHADER)
		"felt":
			return _shader_material("felt", FELT_SHADER)
		"rack_walnut":
			return _material("rack_walnut", Color("452717"), 0.36)
		"rack_walnut_edge":
			return _material("rack_walnut_edge", Color("5a3521"), 0.40)
		"rack_bed":
			return _material("rack_bed", Color("22130b"), 0.80)
		"rack_badge":
			return _material("rack_badge", Color("c4a46c"), 0.38)
		"plum":
			return _material("plum", Color("2a170e"), 0.36)
		"inset":
			return _material("inset", Color("142c30"), 0.85)
		"brass_inlay":
			return _material("brass_inlay", Color("b59659"), 0.32)
		"tile_ivory":
			return _material("tile_ivory", Color("f4e6c6"), 0.36)
	return null


static func _material(key: String, color: Color, roughness: float) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic_specular = 0.28
	_materials[key] = mat
	return mat


static func _shader_material(key: String, shader: Shader) -> ShaderMaterial:
	if _materials.has(key):
		return _materials[key] as ShaderMaterial
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_materials[key] = mat
	return mat


static func piece(parent: Node3D, part_name: String, size: Vector3, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	return _piece(parent, part_name, size, at, radius, material)


static func _piece(parent: Node3D, part_name: String, size: Vector3, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = _rounded_box(size, radius)
	node.material_override = material
	node.position = at
	parent.add_child(node)
	return node


static func _rounded_box(size: Vector3, radius: float) -> ArrayMesh:
	var key := "%s/%s" % [size, radius]
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var half := size * 0.5
	var r: float = minf(radius, minf(half.x, minf(half.y, half.z)) * 0.95)
	var inner := half - Vector3.ONE * r
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var axes: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	# Concentrate subdivisions at bevels: broad faces remain perfectly planar.
	for normal in axes:
		var tangent := Vector3.RIGHT if absf(normal.y) > 0.5 else Vector3.UP
		var bitangent := normal.cross(tangent)
		var extent_u: float = absf(tangent.dot(half))
		var extent_v: float = absf(bitangent.dot(half))
		var extent_n: float = absf(normal.dot(half))
		var us := _bevel_samples(extent_u, r)
		var vs := _bevel_samples(extent_v, r)
		var base := vertices.size()
		for v in vs:
			for u in us:
				var cube := normal * extent_n + tangent * u + bitangent * v
				var nearest := cube.clamp(-inner, inner)
				var outward := (cube - nearest).normalized()
				vertices.append(nearest + outward * r)
				normals.append(outward)
				uvs.append(Vector2(u / (extent_u * 2.0) + 0.5, v / (extent_v * 2.0) + 0.5))
		for y in range(vs.size() - 1):
			for x in range(us.size() - 1):
				var a := base + y * us.size() + x
				var b := a + 1
				var c := a + us.size()
				var d := c + 1
				indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[key] = mesh
	return mesh


static func _bevel_samples(extent: float, radius: float) -> PackedFloat32Array:
	return PackedFloat32Array([-extent, -extent + radius * 0.134, -extent + radius * 0.5, -extent + radius, extent - radius, extent - radius * 0.5, extent - radius * 0.134, extent])


static func _ring(parent: Node3D, part_name: String, outer_size: Vector2, inner_size: Vector2, corner: float, bottom: float, top: float, bevel: float, material: Material) -> void:
	# A genuinely hollow rim: the raised wood edge never covers the felt.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var outer := outer_size * 0.5
	var inner := inner_size * 0.5
	var thickness: float = (outer.x - inner.x + outer.y - inner.y) * 0.5
	var inner_corner: float = maxf(corner - thickness, 0.006)
	var profiles := [
		Vector4(outer.x, outer.y, bottom + bevel, corner),
		Vector4(outer.x, outer.y, top - bevel, corner),
		Vector4(outer.x - bevel, outer.y - bevel, top, corner - bevel),
		Vector4(inner.x + bevel, inner.y + bevel, top, inner_corner + bevel),
		Vector4(inner.x, inner.y, top - bevel, inner_corner),
		Vector4(inner.x, inner.y, bottom + bevel, inner_corner),
		Vector4(inner.x + bevel, inner.y + bevel, bottom, inner_corner + bevel),
		Vector4(outer.x - bevel, outer.y - bevel, bottom, corner - bevel)
	]
	var normal_profile := [Vector2(1, -0.4), Vector2(1, 0.4), Vector2(0.4, 1), Vector2(-0.4, 1), Vector2(-1, 0.4), Vector2(-1, -0.4), Vector2(-0.4, -1), Vector2(0.4, -1)]
	var count := 36
	for i in range(profiles.size()):
		var profile: Vector4 = profiles[i]
		for j in range(count):
			var quadrant: int = j / 9
			var angle: float = float(quadrant) * PI * 0.5 + float(j % 9) / 8.0 * PI * 0.5
			var radial := Vector2(cos(angle), sin(angle))
			var quadrant_sign := Vector2(1 if quadrant == 0 or quadrant == 3 else -1, 1 if quadrant < 2 else -1)
			var p := quadrant_sign * (Vector2(profile.x, profile.y) - Vector2.ONE * profile.w) + radial * profile.w
			vertices.append(Vector3(p.x, profile.z, p.y))
			var pn: Vector2 = normal_profile[i]
			normals.append(Vector3(radial.x * pn.x, pn.y, radial.y * pn.x).normalized())
	for i in range(profiles.size()):
		for j in range(count):
			var a := i * count + j
			var b := i * count + (j + 1) % count
			var c := ((i + 1) % profiles.size()) * count + j
			var d := ((i + 1) % profiles.size()) * count + (j + 1) % count
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
