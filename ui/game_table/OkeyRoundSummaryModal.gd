class_name OkeyRoundSummaryModal
extends Control

signal next_round_requested
signal main_menu_requested

@onready var modal_title: Label = %ModalTitle
@onready var reason_label: Label = %ReasonLabel
@onready var score_grid: GridContainer = %ScoreGrid
@onready var next_round_btn: Button = %NextRoundButton
@onready var menu_btn: Button = %MenuButton

var _row_tweens: Array[Tween] = []

func _ready() -> void:
	_ensure_nodes()

func _ensure_nodes() -> void:
	if modal_title == null:
		modal_title = get_node_or_null("%ModalTitle") as Label
		if modal_title == null:
			modal_title = get_node_or_null("CenterContainer/CardPanel/CardMargin/VBox/HeaderBox/ModalTitle") as Label
	if reason_label == null:
		reason_label = get_node_or_null("%ReasonLabel") as Label
		if reason_label == null:
			reason_label = get_node_or_null("CenterContainer/CardPanel/CardMargin/VBox/HeaderBox/ReasonLabel") as Label
	if score_grid == null:
		score_grid = get_node_or_null("%ScoreGrid") as GridContainer
		if score_grid == null:
			score_grid = get_node_or_null("CenterContainer/CardPanel/CardMargin/VBox/ScoreScroll/ScoreGrid") as GridContainer
	if next_round_btn == null:
		next_round_btn = get_node_or_null("%NextRoundButton") as Button
		if next_round_btn == null:
			next_round_btn = get_node_or_null("CenterContainer/CardPanel/CardMargin/VBox/ButtonBox/NextRoundButton") as Button
	if menu_btn == null:
		menu_btn = get_node_or_null("%MenuButton") as Button
		if menu_btn == null:
			menu_btn = get_node_or_null("CenterContainer/CardPanel/CardMargin/VBox/ButtonBox/MenuButton") as Button

	if next_round_btn != null and not next_round_btn.pressed.is_connected(_on_next_round_pressed):
		next_round_btn.pressed.connect(_on_next_round_pressed)
	if menu_btn != null and not menu_btn.pressed.is_connected(_on_menu_pressed):
		menu_btn.pressed.connect(_on_menu_pressed)

func _on_next_round_pressed() -> void:
	next_round_requested.emit()

func _on_menu_pressed() -> void:
	main_menu_requested.emit()

func display_summary(state, is_match_finished: bool = false) -> void:
	_ensure_nodes()
	visible = true

	if modal_title != null:
		modal_title.text = "MATCH COMPLETE" if is_match_finished else "ROUND COMPLETE"

	var reason_text: String = "Round concluded."
	if state != null:
		if "round_end_reason" in state:
			reason_text = str(state.round_end_reason)
		elif "reason" in state:
			reason_text = str(state.reason)
	if reason_label != null:
		reason_label.text = reason_text

	if next_round_btn != null:
		next_round_btn.visible = not is_match_finished
		if not is_match_finished and is_inside_tree():
			next_round_btn.grab_focus()
	if menu_btn != null and is_match_finished and is_inside_tree():
		menu_btn.grab_focus()

	_populate_score_grid(state)

func _populate_score_grid(state) -> void:
	if score_grid == null:
		return

	# Clear previous rows (preserve headers: first 5 children)
	var children = score_grid.get_children()
	for i in range(5, children.size()):
		children[i].queue_free()

	if state == null or not ("players" in state):
		return

	var players: Array = state.players
	var stagger: float = 0.0
	var resolved_winner: int = -1
	if "winner_player_index" in state and int(state.winner_player_index) >= 0:
		resolved_winner = int(state.winner_player_index)
	else:
		var lowest_total: float = INF
		for i in range(players.size()):
			var p_item = players[i]
			var t_val: float = float(p_item.score_total) if "score_total" in p_item else 0.0
			if t_val < lowest_total:
				lowest_total = t_val
				resolved_winner = i

	for pi in range(players.size()):
		var p = players[pi]
		var is_winner: bool = (pi == resolved_winner)

		# Col 1: Player Name
		var name_lbl := Label.new()
		name_lbl.text = ("★ YOU" if pi == 0 else "Player %d" % (pi + 1)) + (" (Winner)" if is_winner else "")
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color("#d6af64") if is_winner else Color("#ffffff"))
		name_lbl.modulate.a = 0.0
		score_grid.add_child(name_lbl)

		# Col 2: Opening Mode
		var mode_lbl := Label.new()
		var has_opened: bool = bool(p.has_opened) if "has_opened" in p else false
		var opened_pairs: bool = bool(p.opened_by_pairs) if "opened_by_pairs" in p else false
		if not has_opened:
			mode_lbl.text = "Unopened"
		elif opened_pairs:
			mode_lbl.text = "5+ Pairs"
		else:
			mode_lbl.text = "101+ Series"
		mode_lbl.add_theme_font_size_override("font_size", 13)
		mode_lbl.add_theme_color_override("font_color", Color("#a0b2c6"))
		mode_lbl.modulate.a = 0.0
		score_grid.add_child(mode_lbl)

		# Col 3: Rack Remainder Penalty
		var rem_lbl := Label.new()
		var rem_pts: int = int(p.hand_value) if "hand_value" in p else (p.hand.size() * 5 if "hand" in p and p.hand is Array else 0)
		rem_lbl.text = "+%d pts" % rem_pts if rem_pts > 0 else "0"
		rem_lbl.add_theme_font_size_override("font_size", 13)
		rem_lbl.modulate.a = 0.0
		score_grid.add_child(rem_lbl)

		# Col 4: Penalties
		var pen_lbl := Label.new()
		var pen_pts: int = int(p.penalty_points) if "penalty_points" in p else 0
		pen_lbl.text = "+%d" % pen_pts if pen_pts > 0 else "-"
		pen_lbl.add_theme_font_size_override("font_size", 13)
		pen_lbl.modulate.a = 0.0
		score_grid.add_child(pen_lbl)

		# Col 5: Total Score
		var total_lbl := Label.new()
		var total_score: int = int(p.score_total) if "score_total" in p else 0
		total_lbl.text = "%d" % total_score
		total_lbl.add_theme_font_size_override("font_size", 15)
		total_lbl.add_theme_color_override("font_color", Color("#56e39f") if is_winner else Color("#ffffff"))
		total_lbl.modulate.a = 0.0
		score_grid.add_child(total_lbl)

		if is_inside_tree():
			var t := create_tween()
			t.tween_interval(stagger)
			t.tween_property(name_lbl, ^"modulate:a", 1.0, 0.18)
			t.parallel().tween_property(mode_lbl, ^"modulate:a", 1.0, 0.18)
			t.parallel().tween_property(rem_lbl, ^"modulate:a", 1.0, 0.18)
			t.parallel().tween_property(pen_lbl, ^"modulate:a", 1.0, 0.18)
			t.parallel().tween_property(total_lbl, ^"modulate:a", 1.0, 0.18)
			_row_tweens.append(t)
		else:
			name_lbl.modulate.a = 1.0
			mode_lbl.modulate.a = 1.0
			rem_lbl.modulate.a = 1.0
			pen_lbl.modulate.a = 1.0
			total_lbl.modulate.a = 1.0

		stagger += 0.08

func close() -> void:
	visible = false
	for t in _row_tweens:
		if t != null and t.is_running():
			t.kill()
	_row_tweens.clear()
