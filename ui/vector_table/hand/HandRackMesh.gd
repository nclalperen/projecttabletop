## Procedural 2-shelf Turkish honey-beech rack mesh for Okey 101 HandRig.
## Authentic Turkish coffeehouse craftsmanship:
## - Rich golden honey-beech wood with natural grain and satin lacquer sheen
## - Deep stepped shelves with dark contrast tile beds
## - Iconic cream enamel end bracket plates with brass mounting screws (Image 3)
## - Polished brass front lip beads and center maker emblem
class_name HandRackMesh
extends Node3D

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")


func _init() -> void:
	_build_mesh()


func _build_mesh() -> void:
	name = "HandRackMesh"

	var beech := TABLE_ART.material("honey_beech")
	var beech_edge := TABLE_ART.material("honey_beech_edge")
	var beech_dark := TABLE_ART.material("honey_beech_dark")
	var bracket_cream := TABLE_ART.material("rack_bracket_cream")
	var brass_screw := TABLE_ART.material("bracket_screw")
	var brass := TABLE_ART.material("brass_inlay")
	var gold := TABLE_ART.material("rack_badge")

	var width: float = TUNING.HAND_RACK_LENGTH # 0.80

	# 1. Main Honey-Beech Backboard (slanted backward to support leaning tiles)
	TABLE_ART.piece(self, "Backboard", Vector3(width - 0.016, TUNING.HAND_RACK_BACK_HEIGHT + 0.012, 0.014), Vector3(0.0, 0.008, -0.024), 0.004, beech)

	# 2. Upper Shelf Bed & Front Retaining Lip with Brass Inlay
	TABLE_ART.piece(self, "UpperBed", Vector3(width - 0.022, 0.008, 0.024), Vector3(0.0, 0.0035, -0.012), 0.002, beech_dark)
	TABLE_ART.piece(self, "UpperLip", Vector3(width - 0.018, 0.008, 0.005), Vector3(0.0, 0.010, 0.002), 0.0015, beech_edge)
	TABLE_ART.piece(self, "UpperLipBrass", Vector3(width - 0.020, 0.002, 0.002), Vector3(0.0, 0.0135, 0.0035), 0.0005, brass)

	# 3. Lower Shelf Bed & Front Retaining Lip with Brass Inlay
	TABLE_ART.piece(self, "LowerBed", Vector3(width - 0.022, 0.008, 0.024), Vector3(0.0, -0.0665, 0.012), 0.002, beech_dark)
	TABLE_ART.piece(self, "LowerLip", Vector3(width - 0.018, 0.008, 0.005), Vector3(0.0, -0.060, 0.026), 0.0015, beech_edge)
	TABLE_ART.piece(self, "LowerLipBrass", Vector3(width - 0.020, 0.002, 0.002), Vector3(0.0, -0.0565, 0.0275), 0.0005, brass)

	# 4. Solid Honey-Beech Base & Under-Support
	TABLE_ART.piece(self, "BaseSupport", Vector3(width - 0.012, 0.034, 0.068), Vector3(0.0, -0.078, 0.004), 0.006, beech)

	# 5. Iconic Turkish Triangular End Caps with Cream Enamel Brackets & Brass Screws (Image 3)
	for side in [-1.0, 1.0]:
		var prefix: String = "L" if side < 0.0 else "R"
		var side_x: float = side * (width * 0.5 - 0.007)

		# Wooden triangular end block
		TABLE_ART.piece(self, "EndCap_%s" % prefix, Vector3(0.014, 0.118, 0.076), Vector3(side_x, -0.015, 0.002), 0.005, beech)

		# Cream enamel triangular bracket reinforcement plate
		TABLE_ART.piece(self, "Bracket_%s" % prefix, Vector3(0.0025, 0.088, 0.054), Vector3(side_x + side * 0.0082, -0.015, 0.004), 0.0025, bracket_cream)
		TABLE_ART.piece(self, "BracketTop_%s" % prefix, Vector3(0.015, 0.003, 0.038), Vector3(side_x, 0.045, -0.016), 0.0015, bracket_cream)

		# Polished brass mounting screws/rivets holding bracket
		TABLE_ART.piece(self, "ScrewTop_%s" % prefix, Vector3(0.003, 0.006, 0.006), Vector3(side_x + side * 0.0094, 0.018, -0.002), 0.002, brass_screw)
		TABLE_ART.piece(self, "ScrewBottom_%s" % prefix, Vector3(0.003, 0.006, 0.006), Vector3(side_x + side * 0.0094, -0.046, 0.016), 0.002, brass_screw)

	# 6. Polished Brass Center Maker Badge
	TABLE_ART.piece(self, "MakerBadge", Vector3(0.042, 0.007, 0.002), Vector3(0.0, -0.075, 0.0385), 0.0006, gold)
