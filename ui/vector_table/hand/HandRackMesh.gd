## Procedural 2-shelf walnut rack mesh for Okey 101 HandRig.
## Dimensions: 0.80m width, 0.07m depth, 0.10m backboard, two recessed shelves with 0.006m lips.
class_name HandRackMesh
extends Node3D

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")


func _init() -> void:
	_build_mesh()


func _build_mesh() -> void:
	name = "HandRackMesh"

	var walnut := TABLE_ART.material("walnut")
	var shell := TABLE_ART.material("rack_walnut")
	var edge := TABLE_ART.material("rack_walnut_edge")
	var bed := TABLE_ART._material("rack_felt_bed", Color("0c261c"), 0.88)
	var brass := TABLE_ART.material("brass_inlay")
	var gold := TABLE_ART.material("rack_badge")

	var width: float = TUNING.HAND_RACK_LENGTH # 0.80

	# 1. Main Walnut Backboard (0.80m x 0.10m x 0.012m)
	TABLE_ART.piece(self, "Backboard", Vector3(width - 0.016, TUNING.HAND_RACK_BACK_HEIGHT, 0.012), Vector3(0.0, 0.005, -0.022), 0.004, walnut)

	# 2. Upper Shelf Bed & Front Lip with Brass Accent
	TABLE_ART.piece(self, "UpperBed", Vector3(width - 0.024, 0.008, 0.022), Vector3(0.0, 0.0035, -0.012), 0.002, bed)
	TABLE_ART.piece(self, "UpperLip", Vector3(width - 0.018, 0.007, 0.004), Vector3(0.0, 0.010, 0.002), 0.0015, walnut)
	TABLE_ART.piece(self, "UpperLipBrass", Vector3(width - 0.020, 0.0015, 0.002), Vector3(0.0, 0.0135, 0.003), 0.0005, brass)

	# 3. Lower Shelf Bed & Front Lip with Brass Accent
	TABLE_ART.piece(self, "LowerBed", Vector3(width - 0.024, 0.008, 0.022), Vector3(0.0, -0.0665, 0.012), 0.002, bed)
	TABLE_ART.piece(self, "LowerLip", Vector3(width - 0.018, 0.007, 0.004), Vector3(0.0, -0.060, 0.025), 0.0015, walnut)
	TABLE_ART.piece(self, "LowerLipBrass", Vector3(width - 0.020, 0.0015, 0.002), Vector3(0.0, -0.0565, 0.026), 0.0005, brass)

	# 4. Sculpted Plum/Walnut Under-Support Base
	TABLE_ART.piece(self, "BaseSupport", Vector3(width - 0.012, 0.032, 0.064), Vector3(0.0, -0.076, 0.004), 0.006, walnut)

	# 5. Rounded Walnut End Caps (Left and Right)
	for side in [-1.0, 1.0]:
		var side_x: float = side * (width * 0.5 - 0.007)
		TABLE_ART.piece(self, "EndCap_%s" % ("L" if side < 0.0 else "R"), Vector3(0.014, 0.112, 0.066), Vector3(side_x, -0.018, 0.002), 0.005, walnut)

	# 6. Center Brass Maker Badge
	TABLE_ART.piece(self, "MakerBadge", Vector3(0.036, 0.005, 0.0015), Vector3(0.0, -0.075, 0.0365), 0.0006, gold)
