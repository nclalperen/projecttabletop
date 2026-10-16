## Factory for the default Okey 101 four-seat table configuration.
## Produces a TableConfig with the exact geometry used by the classic 3D table.
class_name Okey101TableConfig
extends RefCounted


static func create() -> TableConfig:
	var config := TableConfig.new()
	config.table_id = &"okey101_classic"
	config.display_name = "Okey 101 Classic"
	config.seat_count = 4

	# Table body
	config.table_width = 1.0
	config.table_depth = 1.0
	config.table_height = 0.075
	config.felt_width = 0.80
	config.felt_depth = 0.80

	# Rack dimensions
	config.rack_length = 0.82
	config.rack_depth = 0.15
	config.rack_height = 0.11
	config.rack_gap_to_felt = 0.005

	# Tile dimensions
	config.tile_width = 0.045
	config.tile_height = 0.065
	config.tile_depth = 0.009

	# Visual theme
	config.felt_color = Color("163428")
	config.wood_color = Color("6b3721")
	config.rack_color = Color("4c243e")
	config.opponent_rack_color = Color("4c243e")
	config.tile_face_color = Color("f4e4bd")
	config.tile_back_color = Color("f4e4bd")
	config.use_procedural_art = true

	# Deck & Indicator
	config.deck_position = Vector2(-0.04, -0.22)
	config.indicator_gap = 0.012

	var rc: float = config.rack_center()  # 0.42
	var fh: float = config.felt_half()    # 0.40

	# Seat 0: South (local player)
	var s0 := SeatConfig.create(0, "You", true,
		Vector2(0.0, rc), 0.0,
		Vector2(0.40, 0.08),
		Rect2(Vector2(-0.33, 0.11), Vector2(0.66, 0.15)))
	s0.rack_scale = Vector3.ONE
	s0.rack_tilt_x_deg = 0.0
	s0.camera_fov = 44.0
	s0.camera_focus = Vector3(0.0, 0.015, 0.06)

	# Seat 1: East
	var s1 := SeatConfig.create(1, "East", false,
		Vector2(0.475, 0.0), 90.0,
		Vector2(0.40, -0.26),
		Rect2(Vector2(fh - 0.040 - 0.090, -0.22), Vector2(0.090, 0.44)))
	s1.rack_scale = Vector3.ONE * 0.48

	# Seat 2: North
	var s2 := SeatConfig.create(2, "North", false,
		Vector2(0.0, -rc), 180.0,
		Vector2(-0.40, -0.26),
		Rect2(Vector2(-0.22, -fh + 0.040), Vector2(0.44, 0.090)))
	s2.rack_scale = Vector3.ONE * 0.48

	# Seat 3: West
	var s3 := SeatConfig.create(3, "West", false,
		Vector2(-0.475, 0.0), -90.0,
		Vector2(-0.40, 0.08),
		Rect2(Vector2(-fh + 0.040, -0.22), Vector2(0.090, 0.44)))
	s3.rack_scale = Vector3.ONE * 0.48

	config.seats = [s0, s1, s2, s3]
	return config
