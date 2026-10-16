extends RefCounted
## Tests for MaterialFactory component extracted from GameTable3D.

const MATERIAL_FACTORY = preload("res://ui/game_table/MaterialFactory.gd")
const TABLE_CONFIG = preload("res://core/config/TableConfig.gd")
const OKEY_101_CONFIG = preload("res://core/config/Okey101TableConfig.gd")


func run() -> bool:
	return (
		_test_create_casual()
		and _test_create_from_config()
		and _test_create_from_okey_config()
		and _test_create_classic()
		and _test_apply_pbr_textures()
		and _test_apply_material_recursive()
	)


func _test_create_casual() -> bool:
	var ok: bool = true
	var color := Color(0.2, 0.4, 0.6, 1.0)
	var mat: StandardMaterial3D = MATERIAL_FACTORY.create_casual(color)

	ok = _check(mat != null, "create_casual returns non-null StandardMaterial3D") and ok
	if mat != null:
		ok = _check(mat.albedo_color == color, "create_casual sets correct albedo_color") and ok
		ok = _check(is_equal_approx(mat.roughness, 0.96), "create_casual roughness is 0.96") and ok
		ok = _check(is_equal_approx(mat.metallic_specular, 0.08), "create_casual metallic_specular is 0.08") and ok

	if ok:
		print("  PASS  test_create_casual")
	else:
		print("  FAIL  test_create_casual")
	return ok


func _test_create_from_config() -> bool:
	var ok: bool = true
	var cfg := TableConfig.new()
	cfg.wood_color = Color("6b3721")
	cfg.rack_color = Color("4c243e")
	cfg.opponent_rack_color = Color("381830")
	cfg.tile_face_color = Color("f4e4bd")
	cfg.tile_back_color = Color("e0d0a5")
	cfg.felt_color = Color("1a4030")

	var factory: MaterialFactory = MATERIAL_FACTORY.create_from_config(cfg)
	ok = _check(factory != null, "create_from_config returns instance") and ok
	if factory != null:
		ok = _check(factory.table_wood != null, "table_wood is populated") and ok
		ok = _check(factory.table_wood.albedo_color == cfg.wood_color, "table_wood color matches") and ok

		ok = _check(factory.rack_wood != null, "rack_wood is populated") and ok
		ok = _check(factory.rack_wood.albedo_color == cfg.rack_color, "rack_wood color matches") and ok

		ok = _check(factory.opponent_rack != null, "opponent_rack is populated") and ok
		ok = _check(factory.opponent_rack.albedo_color == cfg.opponent_rack_color, "opponent_rack color matches") and ok

		ok = _check(factory.tile_face != null, "tile_face is populated") and ok
		ok = _check(factory.tile_face.albedo_color == cfg.tile_face_color, "tile_face color matches") and ok

		ok = _check(factory.tile_back != null, "tile_back is populated") and ok
		ok = _check(factory.tile_back.albedo_color == cfg.tile_back_color, "tile_back color matches") and ok

		ok = _check(factory.felt != null, "felt is populated") and ok
		ok = _check(factory.felt.albedo_color == cfg.felt_color, "felt color matches") and ok

	# Null config handling
	var null_factory: MaterialFactory = MATERIAL_FACTORY.create_from_config(null)
	ok = _check(null_factory != null, "create_from_config handles null safely") and ok

	if ok:
		print("  PASS  test_create_from_config")
	else:
		print("  FAIL  test_create_from_config")
	return ok


func _test_create_from_okey_config() -> bool:
	var ok: bool = true
	var cfg: TableConfig = OKEY_101_CONFIG.create()
	var factory: MaterialFactory = MATERIAL_FACTORY.create_from_config(cfg)

	ok = _check(factory.table_wood.albedo_color == cfg.wood_color, "okey table_wood matches") and ok
	ok = _check(factory.rack_wood.albedo_color == cfg.rack_color, "okey rack_wood matches") and ok
	ok = _check(factory.opponent_rack.albedo_color == cfg.opponent_rack_color, "okey opponent_rack matches") and ok
	ok = _check(factory.tile_face.albedo_color == cfg.tile_face_color, "okey tile_face matches") and ok
	ok = _check(factory.tile_back.albedo_color == cfg.tile_back_color, "okey tile_back matches") and ok

	if ok:
		print("  PASS  test_create_from_okey_config")
	else:
		print("  FAIL  test_create_from_okey_config")
	return ok


func _test_create_classic() -> bool:
	var ok: bool = true
	var factory: MaterialFactory = MATERIAL_FACTORY.create_classic()

	ok = _check(factory.table_wood.albedo_color == Color("6b3721"), "classic table_wood") and ok
	ok = _check(factory.rack_wood.albedo_color == Color("4c243e"), "classic rack_wood") and ok
	ok = _check(factory.opponent_rack.albedo_color == Color("4c243e"), "classic opponent_rack") and ok
	ok = _check(factory.tile_face.albedo_color == Color("f4e4bd"), "classic tile_face") and ok
	ok = _check(factory.tile_back.albedo_color == Color("f4e4bd"), "classic tile_back") and ok

	if ok:
		print("  PASS  test_create_classic")
	else:
		print("  FAIL  test_create_classic")
	return ok


func _test_apply_pbr_textures() -> bool:
	var ok: bool = true
	var mat := StandardMaterial3D.new()

	# Null material safety
	MATERIAL_FACTORY.apply_pbr_textures(null)

	# Dummy textures
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var albedo_tex := ImageTexture.create_from_image(img)
	var normal_tex := ImageTexture.create_from_image(img)
	var roughness_tex := ImageTexture.create_from_image(img)
	var uv_scale := Vector3(2.0, 3.0, 1.0)

	MATERIAL_FACTORY.apply_pbr_textures(mat, albedo_tex, normal_tex, roughness_tex, uv_scale, true, 1.5)

	ok = _check(mat.albedo_texture == albedo_tex, "albedo texture applied") and ok
	ok = _check(mat.normal_enabled == true, "normal enabled") and ok
	ok = _check(mat.normal_texture == normal_tex, "normal texture applied") and ok
	ok = _check(is_equal_approx(mat.normal_scale, 1.5), "normal scale applied") and ok
	ok = _check(mat.roughness_texture == roughness_tex, "roughness texture applied") and ok
	ok = _check(mat.uv1_triplanar == true, "triplanar applied") and ok
	ok = _check(mat.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC, "texture filter applied") and ok
	ok = _check(mat.uv1_scale.is_equal_approx(uv_scale), "uv scale applied") and ok

	if ok:
		print("  PASS  test_apply_pbr_textures")
	else:
		print("  FAIL  test_apply_pbr_textures")
	return ok


func _test_apply_material_recursive() -> bool:
	var ok: bool = true
	var root := Node3D.new()
	var mi1 := MeshInstance3D.new()
	mi1.mesh = BoxMesh.new()
	root.add_child(mi1)

	var child_node := Node3D.new()
	root.add_child(child_node)
	var mi2 := MeshInstance3D.new()
	mi2.mesh = BoxMesh.new()
	child_node.add_child(mi2)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	MATERIAL_FACTORY.apply_material_recursive(root, mat)

	ok = _check(mi1.get_surface_override_material(0) == mat, "mi1 surface 0 overridden") and ok
	ok = _check(mi2.get_surface_override_material(0) == mat, "mi2 surface 0 overridden") and ok

	root.free()
	if ok:
		print("  PASS  test_apply_material_recursive")
	else:
		print("  FAIL  test_apply_material_recursive")
	return ok


func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("material_factory_test: " + message)
	return condition
