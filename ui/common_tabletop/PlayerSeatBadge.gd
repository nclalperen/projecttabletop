class_name PlayerSeatBadge
extends PanelContainer

@onready var avatar_label: Label = %AvatarLabel
@onready var name_label: Label = %NameLabel
@onready var stats_label: Label = %StatsLabel
@onready var turn_indicator: ColorRect = %TurnIndicator

const SEAT_COLORS: Array[Color] = [
	Color("#d6af64"), # Gold / Player
	Color("#569c91"), # Teal / Seat 1 (Right)
	Color("#9a79b3"), # Purple / Seat 2 (Top)
	Color("#c87e6d"), # Coral / Seat 3 (Left)
]

func _ensure_nodes() -> void:
	if avatar_label == null:
		avatar_label = get_node_or_null("%AvatarLabel") as Label
	if name_label == null:
		name_label = get_node_or_null("%NameLabel") as Label
	if stats_label == null:
		stats_label = get_node_or_null("%StatsLabel") as Label
	if turn_indicator == null:
		turn_indicator = get_node_or_null("%TurnIndicator") as ColorRect

func _ready() -> void:
	theme_type_variation = &"HUDGlassPanel"
	_ensure_nodes()
	if turn_indicator != null:
		turn_indicator.visible = false

func configure_seat(seat_idx: int, p_name: String, local: bool = false) -> void:
	update_seat({"seat_index": seat_idx, "name": p_name, "is_local": local})

func set_turn_active(active: bool) -> void:
	_ensure_nodes()
	if turn_indicator != null:
		turn_indicator.visible = active

func set_score(score_val: int) -> void:
	_ensure_nodes()
	if stats_label != null:
		stats_label.text = "%d pts" % score_val

func set_melds(has_opened: bool, pts: int) -> void:
	_ensure_nodes()
	if stats_label != null:
		stats_label.text = ("OPEN (%d pts)" if has_opened else "CLOSED") % pts

func update_seat(data) -> void:
	_ensure_nodes()
	if data == null:
		visible = false
		return
	visible = true


	var seat_idx: int = 0
	var player_name: String = ""
	var is_turn: bool = false
	var is_local: bool = false
	var tile_count: int = 0
	var has_opened: bool = false
	var score: int = 0

	if data is Dictionary:
		seat_idx = int(data.get("seat_index", 0))
		player_name = str(data.get("name", ""))
		is_turn = bool(data.get("is_turn", false))
		is_local = bool(data.get("is_local", seat_idx == 0))
		tile_count = int(data.get("tile_count", 0))
		has_opened = bool(data.get("has_opened", false))
		score = int(data.get("score", 0))
	elif data is Object:
		if "seat_index" in data:
			seat_idx = int(data.seat_index)
		if "name" in data:
			player_name = str(data.name)
		if "hand" in data and data.hand is Array:
			tile_count = data.hand.size()
		if "has_opened" in data:
			has_opened = bool(data.has_opened)
		if "score_total" in data:
			score = int(data.score_total)

	if player_name.is_empty():
		player_name = "YOU" if is_local or seat_idx == 0 else "Player %d" % (seat_idx + 1)

	var color_idx: int = posmod(seat_idx, SEAT_COLORS.size())
	var seat_color: Color = SEAT_COLORS[color_idx]

	if avatar_label != null:
		avatar_label.text = "★" if (is_local or seat_idx == 0) else str(seat_idx + 1)
		avatar_label.modulate = Color.WHITE
		avatar_label.add_theme_color_override("font_color", seat_color.lightened(0.18))

	if name_label != null:
		name_label.text = ("▶ " if is_turn else "") + player_name
		name_label.modulate = Color.WHITE
		name_label.add_theme_color_override("font_color", Color("#fff6dc") if is_turn else Color("#efe6d5"))

	if stats_label != null:
		var open_str: String = "OPEN" if has_opened else "101"
		stats_label.text = "%d tiles · %s · %d pts" % [tile_count, open_str, score]
		stats_label.modulate = Color.WHITE
		stats_label.add_theme_color_override("font_color", Color("#e2c88a") if is_turn else Color("#bfb4a3"))

	if turn_indicator != null:
		turn_indicator.visible = is_turn
		turn_indicator.color = seat_color
