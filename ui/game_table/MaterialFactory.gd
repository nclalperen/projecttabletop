## Creates and manages StandardMaterial3D instances for the 3D tabletop.
##
## Extracts casual flat materials and PBR texture setup logic from GameTable3D,
## allowing game tables, racks, and tiles to be styled consistently from a
## TableConfig resource or standalone color specifications.
class_name MaterialFactory
extends RefCounted

const TableConfig = preload("res://core/config/TableConfig.gd")
const TABLE_CONFIG = TableConfig

## Standard material for the table wood rim and frame.
var table_wood: StandardMaterial3D = null

## Standard material for the local player's rack.
var rack_wood: StandardMaterial3D = null

## Standard material for opponent player racks.
var opponent_rack: StandardMaterial3D = null

## Standard material for tile front/faces.
var tile_face: StandardMaterial3D = null

## Standard material for tile backs and sides.
var tile_back: StandardMaterial3D = null

## Standard material for the table felt surface.
var felt: StandardMaterial3D = null

## Alias for felt surface material.
var table_felt: StandardMaterial3D = null


## Factory method that instantiates and populates a MaterialFactory using colors
## configured in the supplied TableConfig.
static func create_from_config(config: TableConfig) -> MaterialFactory:
	var factory := MaterialFactory.new()
	if config == null:
		return factory

	factory.table_wood = create_casual(config.wood_color)
	factory.rack_wood = create_casual(config.rack_color)
	factory.opponent_rack = create_casual(config.opponent_rack_color)
	factory.tile_face = create_casual(config.tile_face_color)
	factory.tile_back = create_casual(config.tile_back_color)
	factory.felt = create_casual(config.felt_color)
	factory.table_felt = factory.felt
	return factory


## Factory method creating materials with the classic hardcoded colors from GameTable3D.
static func create_classic() -> MaterialFactory:
	var factory := MaterialFactory.new()
	factory.table_wood = create_casual(Color("6b3721"))
	factory.rack_wood = create_casual(Color("4c243e"))
	factory.opponent_rack = factory.rack_wood
	factory.tile_face = create_casual(Color("f4e4bd"))
	factory.tile_back = factory.tile_face
	factory.felt = create_casual(Color("163428"))
	factory.table_felt = factory.felt
	return factory


## Creates a casual StandardMaterial3D with a solid albedo color and default matte tabletop roughness/specular.
static func create_casual(color: Color = Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.96
	material.metallic_specular = 0.08
	return material


## Applies PBR textures and UV triplanar settings to an existing StandardMaterial3D instance.
static func apply_pbr_textures(
	mat: StandardMaterial3D,
	albedo: Texture2D = null,
	normal_tex: Texture2D = null,
	roughness_tex: Texture2D = null,
	uv_scale: Vector3 = Vector3.ONE,
	triplanar: bool = true,
	normal_strength: float = 1.0
) -> void:
	if mat == null:
		return
	if albedo != null:
		mat.albedo_texture = albedo
	if normal_tex != null:
		mat.normal_enabled = true
		mat.normal_texture = normal_tex
		mat.normal_scale = normal_strength
	if roughness_tex != null:
		mat.roughness_texture = roughness_tex
	mat.uv1_triplanar = triplanar
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.uv1_scale = uv_scale


## Recursively applies a material override to all surface slots of every MeshInstance3D in the node subtree.
static func apply_material_recursive(node: Node, mat: Material) -> void:
	if node == null or mat == null:
		return
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for s in range(mi.mesh.get_surface_count()):
				mi.set_surface_override_material(s, mat)
	for child in node.get_children():
		apply_material_recursive(child, mat)
