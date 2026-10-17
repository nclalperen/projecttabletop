## Authentic 2-shelf Turkish honey-beech rack mesh for Okey 101 HandRig.
## Built directly from authentic Turkish coffeehouse Okey istaka CAD geometry (AssetIds.GAMEPLAY_MODEL_AUTHENTIC_STAKA):
## - Rich golden honey-beech wood with natural grain rings and satin lacquer sheen
## - Real-life ergonomic shelf lean angles for natural eye-line reading
## - Deep stepped shelves with physical retaining lips
## - Polished brass front lip inlays and center maker emblem
class_name HandRackMesh
extends Node3D

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")


func _init() -> void:
	_build_mesh()


func _build_mesh() -> void:
	name = "HandRackMesh"

	var beech := TABLE_ART.material("honey_beech")
	var brass_screw := TABLE_ART.material("bracket_screw")
	var brass := TABLE_ART.material("brass_inlay")
	var gold := TABLE_ART.material("rack_badge")

	var width: float = TUNING.HAND_RACK_LENGTH # 0.80

	# 1. Authentic Turkish Istaka CAD Mesh
	var staka_mesh: Mesh = AssetRegistry.mesh(AssetIds.GAMEPLAY_MODEL_AUTHENTIC_STAKA)
	if staka_mesh != null:
		var staka_inst := MeshInstance3D.new()
		staka_inst.name = "AuthenticStakaMesh"
		staka_inst.mesh = staka_mesh
		staka_inst.set_surface_override_material(0, beech)
		# Mesh natural length is 0.376362. Scale X to desired width (0.80) while preserving CAD height & profile
		staka_inst.scale = Vector3(width / 0.376362, 1.0, 1.0)
		# Center vertically in HandRig local space (Y: 0..0.08661 -> center at 0)
		staka_inst.position = Vector3(0.0, -0.0433, 0.0)
		add_child(staka_inst)

	# 2. Polished Brass Inlays on Shelf Retaining Lips
	# Upper shelf lip
	TABLE_ART.piece(self, "UpperLipBrass", Vector3(width - 0.016, 0.0018, 0.002), Vector3(0.0, 0.0116, -0.0027), 0.0005, brass)
	# Lower shelf front lip
	TABLE_ART.piece(self, "LowerLipBrass", Vector3(width - 0.016, 0.0018, 0.002), Vector3(0.0, -0.0323, 0.0375), 0.0005, brass)

	# 3. Delicate Brass End Rivets on Wooden End Caps
	for side in [-1.0, 1.0]:
		var prefix: String = "L" if side < 0.0 else "R"
		var side_x: float = side * (width * 0.5 - 0.001)

		TABLE_ART.piece(self, "ScrewTop_%s" % prefix, Vector3(0.002, 0.004, 0.004), Vector3(side_x + side * 0.0008, 0.024, -0.015), 0.001, brass_screw)
		TABLE_ART.piece(self, "ScrewBottom_%s" % prefix, Vector3(0.002, 0.004, 0.004), Vector3(side_x + side * 0.0008, -0.022, 0.018), 0.001, brass_screw)

	# 4. Polished Brass Center Maker Badge
	TABLE_ART.piece(self, "MakerBadge", Vector3(0.042, 0.007, 0.002), Vector3(0.0, -0.038, 0.0392), 0.0006, gold)
