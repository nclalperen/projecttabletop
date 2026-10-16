## Factory for a classic two-player Chess / Checkers table configuration.
## Produces a TableConfig with a square board and 2 face-to-face seated positions.
class_name ChessTableConfig
extends RefCounted


static func create() -> TableConfig:
	var config := TableConfig.new()
	config.table_id = &"chess_classic"
	config.display_name = "Chess Table"
	config.seat_count = 2

	# Compact square table
	config.table_width = 0.90
	config.table_depth = 0.90
	config.table_height = 0.075
	config.felt_width = 0.60
	config.felt_depth = 0.60

	# Visual theme: Classic walnut wood and warm beige board
	config.felt_color = Color(0.72, 0.65, 0.52)
	config.wood_color = Color(0.20, 0.12, 0.08)
	config.rack_color = Color(0.25, 0.15, 0.10)
	config.opponent_rack_color = Color(0.25, 0.15, 0.10)
	config.tile_face_color = Color(0.92, 0.90, 0.85)
	config.tile_back_color = Color(0.18, 0.16, 0.14)
	config.use_procedural_art = false

	# Center of board
	config.deck_position = Vector2.ZERO
	config.indicator_gap = 0.0

	var dist: float = 0.38

	# Seat 0: White (South, local player)
	var s0 := SeatConfig.create(
		0,
		"White (You)",
		true,
		Vector2(0.0, dist),
		0.0,
		Vector2(0.28, 0.28), # Captured pieces zone
		Rect2(Vector2(-0.25, 0.05), Vector2(0.50, 0.15))
	)
	s0.camera_fov = 42.0
	s0.camera_focus = Vector3(0.0, 0.01, 0.0)

	# Seat 1: Black (North, opponent facing player)
	var s1 := SeatConfig.create(
		1,
		"Black",
		false,
		Vector2(0.0, -dist),
		180.0,
		Vector2(-0.28, -0.28), # Captured pieces zone
		Rect2(Vector2(-0.25, -0.20), Vector2(0.50, 0.15))
	)
	s1.camera_fov = 42.0
	s1.camera_focus = Vector3(0.0, 0.01, 0.0)

	config.seats = [s0, s1]
	return config
