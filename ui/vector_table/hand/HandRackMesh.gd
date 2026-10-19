## Authentic procedural 3D Turkish Okey istaka mesh for HandRig.
## Built using VectorRackBuilder:
## - Solid natural blonde beech timber with continuous wood grain and satin sheen
## - Precision dual stepped shelves with 10.0° upright lean angle
## - Seamless solid wood end faces (no tacked-on plastic/composite plates)
class_name HandRackMesh
extends Node3D

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const VectorRackBuilder = preload("res://ui/vector_table/render/VectorRackBuilder.gd")


func _init() -> void:
	_build_mesh()


func _build_mesh() -> void:
	name = "HandRackMesh"

	var beech := TABLE_ART.material("honey_beech")
	var width: float = TUNING.HAND_RACK_LENGTH # 0.80m

	# 1. Pure procedural Vector Rack Mesh
	var rack_mesh: ArrayMesh = VectorRackBuilder.build_mesh(width, beech)
	if rack_mesh != null:
		var rack_inst := MeshInstance3D.new()
		rack_inst.name = "VectorRackMesh"
		rack_inst.mesh = rack_mesh
		rack_inst.set_surface_override_material(0, beech)
		# Center vertically in HandRig local space (Y: 0..0.136m -> center at -0.068m)
		rack_inst.position = Vector3(0.0, -VectorRackBuilder.HEIGHT * 0.5, 0.0)
		add_child(rack_inst)
