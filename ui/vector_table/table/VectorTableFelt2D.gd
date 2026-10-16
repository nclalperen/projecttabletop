## Procedural Vector Felt Table for Okey 101.
## Renders deep emerald felt, beveled walnut rim, 3D-layered vector deck stack,
## indicator tile well, and 4 player discard inlays.
class_name VectorTableFelt2D
extends Control

signal deck_clicked
signal discard_left_clicked

const VectorTile2D = preload("res://ui/vector_table/render/VectorTile2D.gd")

# Table dimensions
const FELT_COLOR: Color = Color(0.08, 0.22, 0.16, 1.0)
const FELT_INNER_GLOW: Color = Color(0.12, 0.28, 0.20, 0.85)
const WALNUT_RIM_COLOR: Color = Color(0.26, 0.14, 0.08, 1.0)
const GOLD_BEAD_COLOR: Color = Color(0.72, 0.58, 0.28, 0.80)
const DISCARD_WELL_COLOR: Color = Color(0.06, 0.16, 0.12, 0.70)
const DISCARD_WELL_BORDER: Color = Color(0.18, 0.36, 0.28, 0.50)

# Deck & Discard anchors (relative to center)
var deck_pos: Vector2 = Vector2.ZERO
var indicator_pos: Vector2 = Vector2.ZERO
var discard_positions: Dictionary = {} # seat_index -> Vector2

var _deck_tile: VectorTile2D = null
var _indicator_tile: VectorTile2D = null
var _discard_tiles: Dictionary = {} # seat_index -> VectorTile2D
var _deck_remaining: int = 106


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	_update_anchors()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_anchors()
		queue_redraw()


func _update_anchors() -> void:
	var center := size * 0.5
	# Center deck and indicator in the upper-middle area of the felt
	deck_pos = center + Vector2(-38.0, -60.0)
	indicator_pos = center + Vector2(38.0, -60.0)

	# 4 Discard positions around the table
	discard_positions[0] = center + Vector2(280.0, 90.0)   # Local player right (outgoing)
	discard_positions[1] = center + Vector2(380.0, -60.0)  # East player
	discard_positions[2] = center + Vector2(0.0, -210.0)   # North player
	discard_positions[3] = center + Vector2(-380.0, -60.0) # West player (incoming to local player)


func update_deck(remaining_count: int, indicator_data: Dictionary) -> void:
	_deck_remaining = remaining_count

	# Update or create indicator tile
	if not indicator_data.is_empty():
		if _indicator_tile == null:
			_indicator_tile = VectorTile2D.new()
			add_child(_indicator_tile)
		_indicator_tile.setup_tile(
			indicator_data.get("unique_id", -1),
			indicator_data.get("number", 1),
			indicator_data.get("color", 0),
			indicator_data.get("kind", 0) != 0,
			true
		)
		_indicator_tile.set_target_position(indicator_pos - (_indicator_tile.size * 0.5), true)
	elif _indicator_tile != null:
		_indicator_tile.queue_free()
		_indicator_tile = null

	queue_redraw()


func update_discard(seat: int, tile_data: Dictionary) -> void:
	var pos: Vector2 = discard_positions.get(seat, Vector2.ZERO)
	if tile_data.is_empty():
		if _discard_tiles.has(seat) and is_instance_valid(_discard_tiles[seat]):
			_discard_tiles[seat].queue_free()
			_discard_tiles.erase(seat)
		return

	var tile: VectorTile2D = _discard_tiles.get(seat)
	if tile == null:
		tile = VectorTile2D.new()
		add_child(tile)
		_discard_tiles[seat] = tile

	tile.setup_tile(
		tile_data.get("unique_id", -1),
		tile_data.get("number", 1),
		tile_data.get("color", 0),
		tile_data.get("kind", 0) != 0,
		true
	)
	tile.set_target_position(pos - (tile.size * 0.5), false)


func _draw() -> void:
	var full_rect := Rect2(Vector2.ZERO, size)

	# 1. Beveled Walnut Outer Table Rim
	draw_rect(full_rect, WALNUT_RIM_COLOR, true)

	# 2. Gold Trim Inlay Line
	var felt_margin := 28.0
	var felt_rect := full_rect.grow(-felt_margin)
	draw_rect(felt_rect.grow(4.0), GOLD_BEAD_COLOR, false, 2.5)

	# 3. Deep Emerald Felt
	draw_rect(felt_rect, FELT_COLOR, true)

	# 5. Deck Stack Pseudo-3D Layering
	_draw_vector_deck_stack(deck_pos)

	# 6. Discard Well Inlays
	for seat_idx in discard_positions.keys():
		var pos: Vector2 = discard_positions[seat_idx]
		var well_size := Vector2(68.0, 92.0)
		var well_rect := Rect2(pos - (well_size * 0.5), well_size)
		draw_rect(well_rect, DISCARD_WELL_COLOR, true)
		draw_rect(well_rect, DISCARD_WELL_BORDER, false, 1.5)


func _draw_vector_deck_stack(at: Vector2) -> void:
	if _deck_remaining <= 0:
		return

	var w := VectorTile2D.DEFAULT_WIDTH
	var h := VectorTile2D.DEFAULT_HEIGHT
	# Render 4 pseudo-3D offset layers to give the stack tactile physical depth
	var layers := 4
	for i in range(layers):
		var offset := Vector2(0.0, -float(i) * 3.5)
		var layer_rect := Rect2(at - Vector2(w * 0.5, h * 0.5) + offset, Vector2(w, h))
		# Shadow
		draw_rect(layer_rect.grow(1.5), Color(0.04, 0.08, 0.06, 0.25), true)
		# Ivory side edge
		draw_rect(layer_rect, Color(0.92, 0.88, 0.80), true)
		draw_rect(layer_rect, Color(0.72, 0.66, 0.56), false, 1.0)

	# Deck face-down top tile pattern
	var top_offset := Vector2(0.0, -float(layers) * 3.5)
	var top_rect := Rect2(at - Vector2(w * 0.5, h * 0.5) + top_offset, Vector2(w, h))
	draw_rect(top_rect, VectorTile2D.COLOR_IVORY_BASE, true)
	var top_inner := top_rect.grow(-3.5)
	draw_rect(top_inner, Color(0.86, 0.80, 0.69), true)
	draw_rect(top_rect, VectorTile2D.COLOR_IVORY_EDGE, false, 1.0)

	# Remaining cards badge
	var font := ThemeDB.fallback_font
	draw_string(font, at + top_offset + Vector2(0.0, 5.0), str(_deck_remaining), HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.35, 0.28, 0.20))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var w := VectorTile2D.DEFAULT_WIDTH
			var h := VectorTile2D.DEFAULT_HEIGHT
			# Check click on deck
			var deck_rect := Rect2(deck_pos - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
			if deck_rect.has_point(mb.position):
				deck_clicked.emit()
				return

			# Check click on left discard (Seat 3 incoming)
			var left_discard_pos: Vector2 = discard_positions.get(3, Vector2.ZERO)
			var discard_rect := Rect2(left_discard_pos - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
			if discard_rect.has_point(mb.position):
				discard_left_clicked.emit()
				return
