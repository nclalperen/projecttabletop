class_name OkeyTableArt
extends RefCounted
## Shared procedural meshes for the seated Okey table. Units are metres.
## Standing tiles face +Z. Flat tiles face +Y (rotation.x = -PI / 2).
## Tile origin is its centre; lettering belongs at local z = 0.0048.

const TILE_SIZE := Vector3(0.045, 0.065, 0.009)
const FELT_SHADER = preload("res://ui/game_table/art/felt.gdshader")
const WOOD_SHADER = preload("res://ui/game_table/art/wood.gdshader")
const FLOOR_SHADER = preload("res://ui/game_table/art/floor.gdshader")
static var _meshes: Dictionary = {}
static var _materials: Dictionary = {}


static func build_table(parent: Node3D, surface_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "CraftedOkeyTable"
	root.position.y = surface_y
	parent.add_child(root)
	var wood := material("walnut")
	var mahogany := material("mahogany")
	var dark_wood := material("dark_wood")
	var binding := _material("felt_binding", Color("#061c12"), 0.90)
	var brass := material("table_brass")
	var medallion_felt := material("medallion_felt")
	var floor_mat := material("salon_floor")

	# 1. Deep walnut base structure
	_piece(root, "WalnutBase", Vector3(1.26, 0.062, 1.04), Vector3(0, -0.041, 0), 0.026, wood)

	# 2. Continuous solid walnut outer armrest rail
	_ring(root, "WalnutFrame", Vector2(1.26, 1.04), Vector2(1.174, 0.954), 0.032, -0.025, 0.009, 0.0035, wood)

	# 3. Fine 3mm polished gold marquetry pinstripe
	_ring(root, "BrassInlay", Vector2(1.174, 0.954), Vector2(1.168, 0.948), 0.022, -0.012, 0.004, 0.0015, brass)

	# 4. Deep forest felt bevel edge
	_piece(root, "FeltBinding", Vector3(1.170, 0.020, 0.950), Vector3(0, -0.009, 0), 0.009, binding)

	# 5. Rich emerald tournament baize
	_piece(root, "WovenTealFelt", Vector3(1.158, 0.016, 0.938), Vector3(0, -0.008, 0), 0.007, _shader_material("felt", FELT_SHADER))

	# 6. Polished Brass Corner Protectors on Bolster Rail
	for cx in [-0.595, 0.595]:
		for cz in [-0.485, 0.485]:
			_piece(root, "CornerBrassCap", Vector3(0.080, 0.036, 0.080), Vector3(cx, -0.008, cz), 0.008, brass)

	# 7. Tournament Corner Drink Caddies (matching authentic tournament table)
	for cx in [-0.640, 0.640]:
		for cz in [-0.530, 0.530]:
			_piece(root, "CornerArm", Vector3(0.050, 0.024, 0.050), Vector3(cx * 0.94, -0.028, cz * 0.94), 0.008, wood)
			_piece(root, "CornerCaddy", Vector3(0.088, 0.030, 0.088), Vector3(cx, -0.032, cz), 0.012, mahogany)
			_piece(root, "CornerDrinkBrass", Vector3(0.072, 0.006, 0.072), Vector3(cx, -0.015, cz), 0.006, brass)
			_piece(root, "CornerCupWell", Vector3(0.058, 0.014, 0.058), Vector3(cx, -0.018, cz), 0.004, dark_wood)

	# 8. Center Tournament Medallion (Framing stock pile & indicator tile)
	var medallion := Node3D.new()
	medallion.name = "CenterTournamentMedallion"
	medallion.position = Vector3(0.0, 0.0, -0.03)
	root.add_child(medallion)

	# Medallion outer brass pinstripe frame (18cm wide x 13.6cm deep)
	_ring(medallion, "MedallionBrassRing", Vector2(0.180, 0.136), Vector2(0.174, 0.130), 0.006, -0.002, 0.0016, 0.0005, brass)
	# Medallion inner dark velvet baize bed
	_piece(medallion, "MedallionFelt", Vector3(0.172, 0.0012, 0.128), Vector3(0.0, 0.0005, 0.0), 0.004, medallion_felt)

	# Left Stock Deck Bay (centered at X = -0.035)
	_piece(medallion, "StockBayBorder", Vector3(0.052, 0.0006, 0.072), Vector3(-0.035, 0.0007, 0.0), 0.002, binding)
	_piece(medallion, "StockBayBed", Vector3(0.048, 0.0006, 0.068), Vector3(-0.035, 0.0008, 0.0), 0.002, dark_wood)

	# Right Indicator Tile Bay (centered at X = +0.035)
	_piece(medallion, "IndicatorBayBorder", Vector3(0.072, 0.0006, 0.052), Vector3(0.035, 0.0007, 0.0), 0.002, binding)
	_piece(medallion, "IndicatorBayBed", Vector3(0.068, 0.0006, 0.048), Vector3(0.035, 0.0008, 0.0), 0.002, dark_wood)

	# Center Polished Brass Divider Line & Emblem
	_piece(medallion, "MedallionDivider", Vector3(0.002, 0.0008, 0.088), Vector3(0.0, 0.0008, 0.0), 0.0006, brass)
	var star := _piece(medallion, "MedallionStar", Vector3(0.016, 0.0010, 0.016), Vector3(0.0, 0.0009, 0.0), 0.001, brass)
	star.rotation_degrees.y = 45.0

	# Corner brass florets on the medallion
	for mx in [-0.078, 0.078]:
		for mz in [-0.056, 0.056]:
			_piece(medallion, "MedallionFloret", Vector3(0.012, 0.0010, 0.012), Vector3(mx, 0.0009, mz), 0.0015, brass)

	# 9. Architectural Skirt / Apron
	_piece(root, "FurnitureApron", Vector3(1.234, 0.110, 1.014), Vector3(0, -0.115, 0), 0.016, mahogany)
	_piece(root, "ApronReveal", Vector3(1.216, 0.014, 0.996), Vector3(0, -0.078, 0), 0.005, dark_wood)
	_piece(root, "LowerWoodBead", Vector3(1.246, 0.020, 1.026), Vector3(0, -0.175, 0), 0.008, wood)
	_ring(root, "LowerBrassTrim", Vector2(1.248, 1.028), Vector2(1.242, 1.022), 0.012, -0.186, -0.180, 0.001, brass)

	# 10. Solid Tapered Walnut Legs with Polished Brass Ferrules & Stretchers
	for lx in [-0.53, 0.53]:
		for lz in [-0.42, 0.42]:
			_piece(root, "TableLeg", Vector3(0.078, 0.360, 0.078), Vector3(lx, -0.355, lz), 0.014, wood)
			_piece(root, "BrassFoot", Vector3(0.084, 0.045, 0.084), Vector3(lx, -0.535, lz), 0.004, brass)

	for lx in [-0.53, 0.53]:
		_piece(root, "SideStretcher", Vector3(0.034, 0.042, 0.76), Vector3(lx, -0.46, 0.0), 0.006, wood)
	for lz in [-0.42, 0.42]:
		_piece(root, "EndStretcher", Vector3(0.98, 0.042, 0.034), Vector3(0.0, -0.46, lz), 0.006, wood)

	# 11. Warm Hardwood Parquet Salon Floor
	_piece(root, "SalonFloor", Vector3(4.6, 0.020, 4.6), Vector3(0, -0.565, 0), 0.004, floor_mat)

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
	# Geometry is shared across every tile. Smooth chamfered edges catch the light.
	_piece(root, "IvoryBody", TILE_SIZE, Vector3.ZERO, 0.0028, _material("tile_ivory", Color("f4efe6"), 0.28))
	if not face_up:
		# Luxury engraved tile back facing AWAY (-Z in local coordinates)
		_piece(root, "BackInset", Vector3(0.034, 0.052, 0.0006), Vector3(0, 0, -0.0042), 0.0010, _material("tile_back_wood", Color("341a0e"), 0.35))
		_piece(root, "BackDiamond", Vector3(0.020, 0.032, 0.0008), Vector3(0, 0, -0.0044), 0.0010, _material("tile_back_gold", Color("c5a059"), 0.25))
	if not standing:
		root.rotation.x = PI * 0.5
	return root


static func material(key: String) -> Material:
	if _materials.has(key):
		return _materials[key] as Material
	match key:
		"walnut":
			if _materials.has("walnut"):
				return _materials["walnut"] as Material
			var mat := ShaderMaterial.new()
			mat.shader = WOOD_SHADER
			var base_col := Color("#23140c").srgb_to_linear()
			var high_col := Color("#3d2417").srgb_to_linear()
			mat.set_shader_parameter("wood_color", base_col)
			mat.set_shader_parameter("wood_highlight", high_col)
			_materials["walnut"] = mat
			return mat
		"mahogany":
			return _material("mahogany", Color("#1e0f08"), 0.35)
		"dark_wood":
			return _material("dark_wood", Color("#140a05"), 0.42)
		"table_brass":
			return _material("table_brass", Color("#d4af37"), 0.22, 0.88)
		"medallion_felt":
			return _material("medallion_felt", Color("#061f14"), 0.88)
		"salon_floor":
			return _shader_material("salon_floor", FLOOR_SHADER)
		"felt":
			return _shader_material("felt", FELT_SHADER)
		"honey_beech":
			if _materials.has("honey_beech"):
				return _materials["honey_beech"] as Material
			var mat := ShaderMaterial.new()
			mat.shader = WOOD_SHADER
			var base_col := Color("#7e4218").srgb_to_linear()
			var high_col := Color("#be7c3e").srgb_to_linear()
			mat.set_shader_parameter("wood_color", base_col)
			mat.set_shader_parameter("wood_highlight", high_col)
			mat.set_shader_parameter("grain_scale", 140.0)
			_materials["honey_beech"] = mat
			return mat
		"honey_beech_edge":
			return _material("honey_beech_edge", Color("#723812"), 0.38)
		"honey_beech_dark":
			return _material("honey_beech_dark", Color("#2e1406"), 0.75)
		"rack_bracket_cream":
			return _material("rack_bracket_cream", Color("#ece7dc"), 0.32)
		"bracket_screw":
			return _material("bracket_screw", Color("#d4af37"), 0.22, 0.88)
		"tray_wood":
			return _material("tray_wood", Color("#6e3612"), 0.36)
		"tray_felt":
			return _material("tray_felt", Color("#061c12"), 0.85)
		"tray_glow":
			if _materials.has("tray_glow"):
				return _materials["tray_glow"] as Material
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.72, 0.18, 0.75)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.65, 0.12)
			mat.emission_energy_multiplier = 0.8
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_materials["tray_glow"] = mat
			return mat
		"rack_walnut":
			return _material("rack_walnut", Color("452717"), 0.36)
		"rack_walnut_edge":
			return _material("rack_walnut_edge", Color("5a3521"), 0.40)
		"rack_bed":
			return _material("rack_bed", Color("22130b"), 0.80)
		"rack_badge":
			return _material("rack_badge", Color("c5a059"), 0.30, 0.85)
		"plum":
			return _material("plum", Color("2a170e"), 0.36)
		"inset":
			return _material("inset", Color("142c30"), 0.85)
		"brass_inlay":
			return _material("brass_inlay", Color("d4af37"), 0.28, 0.90)
		"tile_ivory":
			return _material("tile_ivory", Color("f4e6c6"), 0.36)
	return null


static func _material(key: String, color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.metallic_specular = 0.6 if metallic > 0.0 else 0.28
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


static func ring(parent: Node3D, part_name: String, outer_size: Vector2, inner_size: Vector2, corner: float, bottom: float, top: float, bevel: float, material: Material) -> MeshInstance3D:
	return _ring(parent, part_name, outer_size, inner_size, corner, bottom, top, bevel, material)


static func _ring(parent: Node3D, part_name: String, outer_size: Vector2, inner_size: Vector2, corner: float, bottom: float, top: float, bevel: float, material: Material) -> MeshInstance3D:
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
	return node
