class_name VectorRackBuilder
extends RefCounted
## Procedural Turkish okey istaka (rack), shared by the player rig and opponent racks.
##
## Cross-section (Z = toward the owner, Y = up, base at Y = 0) is a solid triangular
## wedge: sloped back face, two stepped grooves on the front. Grooves are designed
## around the real tile (65 x 45 x 9 mm) leaning back LEAN_DEG:
##  - groove floors are perpendicular to their backrests, so a tile sits flush;
##  - the shelf step (50 mm) leaves the upper row's numeral and pip visible;
##  - the crest rises above the upper row, so opponents' tiles stay hidden.

const LEAN_DEG: float = 10.0
const HEIGHT: float = 0.135
const BASE_BACK_Z: float = -0.045
const BASE_FRONT_Z: float = 0.039

## Tile centres (Vector2(z, y)) for row 0 (upper) and row 1 (lower), rack-base space.
## Derived from: C = F + (TILE_HEIGHT/2)*u + (TILE_DEPTH/2)*n
## where u = (-sin 10°, cos 10°), n = (cos 10°, sin 10°),
## F_1 = (0.02800, 0.00550), F_0 = T_1 - 0.0100*n = (0.00686, 0.06778).
const ROW_CENTERS: Array[Vector2] = [
	Vector2(0.00565, 0.10057),
	Vector2(0.02679, 0.03829),
]

const PROFILE: PackedVector2Array = [
	Vector2(-0.04380, 0.00000), # base back chamfer
	Vector2( 0.03820, 0.00000), # base front chamfer
	Vector2( 0.03932, 0.00090), # front nose bottom
	Vector2( 0.03804, 0.00727), # lower shelf floor front edge (F_1 + 0.0102*n)
	Vector2( 0.02800, 0.00550), # lower groove foot F_1
	Vector2( 0.01671, 0.06951), # lower backrest top T_1 (F_1 + 0.065*u)
	Vector2( 0.00686, 0.06778), # upper groove foot F_0 (T_1 - 0.010*n)
	Vector2(-0.00495, 0.13474), # upper backrest top T_0 (F_0 + 0.068*u)
	Vector2(-0.01100, 0.13474), # crest back
	Vector2(-0.01220, 0.13320), # back face top chamfer
	Vector2(-0.04500, 0.00120), # back face bottom chamfer
]

static var _cache: Dictionary = {}


## Rack-base-space transform for a tile standing in `row` at lateral offset `x`.
static func row_transform(row: int, x: float) -> Transform3D:
	var c: Vector2 = ROW_CENTERS[clampi(row, 0, 1)]
	var basis := Basis.from_euler(Vector3(deg_to_rad(-LEAN_DEG), 0.0, 0.0))
	return Transform3D(basis, Vector3(x, c.y, c.x))


static func build_mesh(width: float, _wood_material: Material = null) -> ArrayMesh:
	var key := "%.4f" % width
	if _cache.has(key):
		return _cache[key] as ArrayMesh

	var hw: float = width * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Body: one flat-shaded quad per profile edge (profile is CCW in (z, y)).
	var n: int = PROFILE.size()
	var perim: float = 0.0
	for i in range(n):
		var a: Vector2 = PROFILE[i]
		var b: Vector2 = PROFILE[(i + 1) % n]
		var d: Vector2 = b - a
		var seg: float = d.length()
		if seg < 1e-6:
			continue
		# Outward normal of a CCW polygon edge in (z, y): (dy, -dz) -> world (0, -dz, dy)
		var nrm := Vector3(0.0, -d.x, d.y).normalized()
		var v0 := Vector3(-hw, a.y, a.x)
		var v1 := Vector3(hw, a.y, a.x)
		var v2 := Vector3(hw, b.y, b.x)
		var v3 := Vector3(-hw, b.y, b.x)
		var u0: float = perim
		var u1: float = perim + seg
		perim = u1
		_tri(st, nrm, [v0, v2, v1], [Vector2(0, u0), Vector2(width, u1), Vector2(width, u0)])
		_tri(st, nrm, [v0, v3, v2], [Vector2(0, u0), Vector2(0, u1), Vector2(width, u1)])

	# End caps: triangulated solid cross-section.
	var tris: PackedInt32Array = Geometry2D.triangulate_polygon(PROFILE)
	for side in [-1.0, 1.0]:
		var nrm := Vector3(side, 0.0, 0.0)
		for t in range(0, tris.size(), 3):
			var p := [PROFILE[tris[t]], PROFILE[tris[t + 1]], PROFILE[tris[t + 2]]]
			var verts: Array = []
			var uvs: Array = []
			for q in p:
				verts.append(Vector3(side * hw, q.y, q.x))
				uvs.append(Vector2(q.x, q.y))
			# Polygon is CCW seen from +X; flip for the -X cap.
			if side > 0.0:
				_tri(st, nrm, [verts[0], verts[1], verts[2]], [uvs[0], uvs[1], uvs[2]])
			else:
				_tri(st, nrm, [verts[0], verts[2], verts[1]], [uvs[0], uvs[2], uvs[1]])

	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


static func _tri(st: SurfaceTool, nrm: Vector3, verts: Array, uvs: Array) -> void:
	# Emit vertices in the caller-supplied clockwise outward order.
	for k in [0, 1, 2]:
		st.set_normal(nrm)
		st.set_uv(uvs[k])
		st.add_vertex(verts[k])
