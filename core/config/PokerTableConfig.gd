## Factory for a Texas Hold'em Poker table configuration.
## Produces a TableConfig with an oval felt surface and 6 seats arranged elliptically.
class_name PokerTableConfig
extends RefCounted


static func create(seat_count: int = 6) -> TableConfig:
	var config := TableConfig.new()
	config.table_id = &"poker_holdem"
	config.display_name = "Poker Table (Hold'em)"
	config.seat_count = clampi(seat_count, 2, 8)

	# Physical dimensions (oval/horseshoe shape)
	config.table_width = 1.80
	config.table_depth = 1.10
	config.table_height = 0.075
	config.felt_width = 1.55
	config.felt_depth = 0.85

	# Visual theme: Classic casino green felt and dark mahogany wood
	config.felt_color = Color(0.08, 0.28, 0.16)
	config.wood_color = Color(0.24, 0.11, 0.06)
	config.rack_color = Color(0.30, 0.14, 0.08)
	config.opponent_rack_color = Color(0.30, 0.14, 0.08)
	config.tile_face_color = Color(0.98, 0.98, 0.98)
	config.tile_back_color = Color(0.12, 0.22, 0.60)
	config.use_procedural_art = false

	# Dealer chip and community card zone center
	config.deck_position = Vector2(0.0, -0.05)
	config.indicator_gap = 0.020

	# Elliptical seat layout
	config.seats.clear()
	var a: float = config.felt_width * 0.5 - 0.05
	var b: float = config.felt_depth * 0.5 - 0.05
	var count: int = config.seat_count

	for i in range(count):
		# Angle distributed starting from south (PI/2) clockwise
		var angle: float = PI * 0.5 + float(i) * (TAU / float(count))
		var pos := Vector2(cos(angle) * a, sin(angle) * b)
		var rot_deg: float = rad_to_deg(angle - PI * 0.5)

		var label: String = "You" if i == 0 else "Seat %d" % (i + 1)
		var seat := SeatConfig.create(
			i,
			label,
			i == 0,
			pos,
			rot_deg,
			pos * 0.65, # Betting/chip discard zone
			Rect2(pos.x - 0.10, pos.y - 0.05, 0.20, 0.10)
		)
		seat.rack_scale = Vector3.ONE if i == 0 else Vector3.ONE * 0.55
		seat.camera_fov = 48.0
		seat.camera_focus = Vector3(0.0, 0.02, 0.0)
		config.seats.append(seat)

	return config
