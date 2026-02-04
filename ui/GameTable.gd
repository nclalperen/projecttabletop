extends Control

@onready var _banner: Node = $StatusBanner
@onready var _hand_list: ItemList = $HandList
@onready var _meld_list: ItemList = $PlayerInfo/MeldList
@onready var _deck_label: Label = $CenterInfo/DeckCount
@onready var _discard_label: Label = $CenterInfo/DiscardTop
@onready var _indicator_label: Label = $CenterInfo/Indicator
@onready var _okey_label: Label = $CenterInfo/Okey
@onready var _turn_log: Label = $CenterInfo/TurnLog
@onready var _history_list: ItemList = $CenterInfo/ActionHistory
@onready var _preview_list: ItemList = $CenterInfo/MeldPreview
@onready var _turn_label: Label = $PlayerInfo/TurnIndicator
@onready var _hands_label: Label = $PlayerInfo/PlayerHands
@onready var _required_label: Label = $PlayerInfo/RequiredTile
@onready var _btn_new_round: Button = $Controls/NewRound
@onready var _btn_draw: Button = $Controls/Draw
@onready var _btn_take_discard: Button = $Controls/TakeDiscard
@onready var _btn_end_play: Button = $Controls/EndPlay
@onready var _meld_type: OptionButton = $Controls/MeldType
@onready var _btn_add_group: Button = $Controls/AddGroup
@onready var _btn_remove_group: Button = $Controls/RemoveGroup
@onready var _btn_group_up: Button = $Controls/GroupUp
@onready var _btn_group_down: Button = $Controls/GroupDown
@onready var _btn_clear_groups: Button = $Controls/ClearGroups
@onready var _btn_open_melds: Button = $Controls/OpenMelds
@onready var _btn_finish: Button = $Controls/Finish
@onready var _btn_sort_hand: Button = $Controls/SortHand
@onready var _btn_auto_bot: CheckButton = $Controls/AutoBot
@onready var _btn_next_tile: Button = $Controls/NextTile
@onready var _btn_discard: Button = $Controls/Discard
@onready var _btn_bot_turn: Button = $Controls/BotTurn

var _controller: LocalGameController
var _selected_index: int = 0
var _bot := BotHeuristic.new()
var _discard_confirm_pending: bool = false
var _discard_confirm_tile_id: int = -1
var _auto_bot_enabled: bool = false

var _grouped_melds: Array = []
var _grouped_tile_ids: Dictionary = {}
var _selected_group_index: int = -1

func _ready() -> void:
	_controller = LocalGameController.new()
	_controller.state_changed.connect(_on_state_changed)
	_controller.round_cancelled.connect(_on_round_cancelled)
	_controller.action_rejected.connect(_on_action_rejected)
	_controller.action_applied.connect(_on_action_applied)

	_btn_new_round.pressed.connect(_on_new_round)
	_btn_draw.pressed.connect(_on_draw)
	_btn_take_discard.pressed.connect(_on_take_discard)
	_btn_end_play.pressed.connect(_on_end_play)
	_btn_add_group.pressed.connect(_on_add_group)
	_btn_remove_group.pressed.connect(_on_remove_group)
	_btn_group_up.pressed.connect(_on_group_up)
	_btn_group_down.pressed.connect(_on_group_down)
	_btn_clear_groups.pressed.connect(_on_clear_groups)
	_btn_open_melds.pressed.connect(_on_open_melds)
	_btn_finish.pressed.connect(_on_finish)
	_btn_sort_hand.pressed.connect(_on_sort_hand)
	_btn_auto_bot.toggled.connect(_on_auto_bot_toggled)
	_btn_next_tile.pressed.connect(_on_next_tile)
	_btn_discard.pressed.connect(_on_discard)
	_btn_bot_turn.pressed.connect(_on_bot_turn)
	_hand_list.item_selected.connect(_on_hand_selected)
	_hand_list.item_activated.connect(_on_hand_activated)
	_preview_list.item_selected.connect(_on_group_selected)
	if _preview_list.has_signal("reorder_requested"):
		_preview_list.reorder_requested.connect(_on_group_reorder)
	if _preview_list.has_signal("remove_requested"):
		_preview_list.remove_requested.connect(_on_group_remove_requested)

	_setup_meld_type_options()
	_start_round()

func _setup_meld_type_options() -> void:
	_meld_type.clear()
	_meld_type.add_item("Auto", 0)
	_meld_type.add_item("Run", 1)
	_meld_type.add_item("Set", 2)
	_meld_type.add_item("Pairs", 3)
	_meld_type.select(0)

func _start_round() -> void:
	var cfg := RuleConfig.new()
	_controller.start_new_round(cfg, 2001, 4)
	_selected_index = 0
	_discard_confirm_pending = false
	_discard_confirm_tile_id = -1
	_history_list.clear()
	_clear_groups()
	_refresh_hand_list()
	_refresh_center_info()
	_refresh_meld_list()
	_refresh_player_info()
	_update_banner("Game started")
	_update_discard_warning()

func _on_state_changed(_state) -> void:
	_update_banner("State: %s" % _controller.state.phase)
	_refresh_hand_list()
	_refresh_center_info()
	_refresh_meld_list()
	_refresh_player_info()
	_update_discard_warning()
	_maybe_auto_bot_turn()

func _on_round_cancelled() -> void:
	_update_warning("Round cancelled (all pairs)")

func _on_action_rejected(reason: String) -> void:
	_update_warning("Action rejected: %s" % reason)
	_add_history("Rejected: %s" % reason)

func _on_action_applied(player_index: int, action_type: int) -> void:
	_turn_log.text = "Last: P%s %s" % [player_index, _action_name(action_type)]
	_add_history("P%s %s" % [player_index, _action_name(action_type)])

func _on_new_round() -> void:
	_start_round()

func _on_draw() -> void:
	_controller.draw_from_deck(_controller.state.current_player_index)

func _on_take_discard() -> void:
	_controller.take_discard(_controller.state.current_player_index)

func _on_end_play() -> void:
	_controller.end_play_turn(_controller.state.current_player_index)

func _on_add_group() -> void:
	_add_group_from_selection()

func _on_hand_activated(_index: int) -> void:
	_add_group_from_selection()

func _add_group_from_selection() -> void:
	var selected_tiles := _selected_tiles()
	if selected_tiles.size() < 2:
		return
	var forced_kind := _selected_meld_kind()
	var melds := _build_melds_from_selection(selected_tiles, forced_kind)
	if melds.is_empty():
		_update_warning("Invalid group selection")
		return
	for meld in melds:
		_grouped_melds.append(meld)
		for id in meld.tile_ids:
			_grouped_tile_ids[id] = true
	_refresh_preview_list()

func _on_remove_group() -> void:
	_remove_group_at(_selected_group_index)

func _on_group_remove_requested(index: int) -> void:
	_remove_group_at(index)

func _remove_group_at(index: int) -> void:
	if index < 0 or index >= _grouped_melds.size():
		return
	_grouped_melds.remove_at(index)
	_rebuild_grouped_tile_ids()
	_selected_group_index = -1
	_refresh_preview_list()

func _on_group_up() -> void:
	if _selected_group_index <= 0:
		return
	var tmp = _grouped_melds[_selected_group_index - 1]
	_grouped_melds[_selected_group_index - 1] = _grouped_melds[_selected_group_index]
	_grouped_melds[_selected_group_index] = tmp
	_selected_group_index -= 1
	_refresh_preview_list()
	_preview_list.select(_selected_group_index)

func _on_group_down() -> void:
	if _selected_group_index < 0 or _selected_group_index >= _grouped_melds.size() - 1:
		return
	var tmp = _grouped_melds[_selected_group_index + 1]
	_grouped_melds[_selected_group_index + 1] = _grouped_melds[_selected_group_index]
	_grouped_melds[_selected_group_index] = tmp
	_selected_group_index += 1
	_refresh_preview_list()
	_preview_list.select(_selected_group_index)

func _on_group_reorder(from_index: int, to_index: int) -> void:
	if from_index < 0 or to_index < 0:
		return
	if from_index >= _grouped_melds.size() or to_index >= _grouped_melds.size():
		return
	var item = _grouped_melds[from_index]
	_grouped_melds.remove_at(from_index)
	_grouped_melds.insert(to_index, item)
	_selected_group_index = to_index
	_refresh_preview_list()
	_preview_list.select(_selected_group_index)

func _on_clear_groups() -> void:
	_clear_groups()

func _on_open_melds() -> void:
	if _grouped_melds.is_empty():
		var selected_tiles := _selected_tiles()
		var melds := _build_melds_from_selection(selected_tiles, _selected_meld_kind())
		if melds.is_empty():
			_update_warning("Invalid selection for melds")
			return
		var action := Action.new(Action.ActionType.OPEN_MELDS, {"melds": melds})
		_controller.apply_action_if_valid(_controller.state.current_player_index, action)
		return

	var action2 := Action.new(Action.ActionType.OPEN_MELDS, {"melds": _grouped_melds})
	_controller.apply_action_if_valid(_controller.state.current_player_index, action2)
	_clear_groups()

func _on_finish() -> void:
	if _grouped_melds.is_empty():
		_update_warning("Use Add Group to build finish melds")
		return
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	if hand.is_empty():
		return
	var final_discard_tile = hand[hand.size() - 1]
	var action := Action.new(Action.ActionType.FINISH, {"melds": _grouped_melds, "final_discard_tile_id": final_discard_tile.unique_id, "finish_all_in_one_turn": true})
	_controller.apply_action_if_valid(_controller.state.current_player_index, action)
	_clear_groups()

func _on_sort_hand() -> void:
	var player = _controller.state.players[_controller.state.current_player_index]
	player.hand.sort_custom(func(a, b):
		if a.color == b.color:
			return a.number < b.number
		return a.color < b.color
	)
	_refresh_hand_list()

func _on_auto_bot_toggled(pressed: bool) -> void:
	_auto_bot_enabled = pressed
	_maybe_auto_bot_turn()

func _on_next_tile() -> void:
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	if hand.is_empty():
		return
	_selected_index = (_selected_index + 1) % hand.size()
	_hand_list.select(_selected_index)
	_update_discard_warning()

func _on_hand_selected(index: int) -> void:
	_selected_index = index
	_update_discard_warning()

func _on_group_selected(index: int) -> void:
	_selected_group_index = index
	_apply_group_highlight()

func _on_discard() -> void:
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	if hand.is_empty():
		return
	var tile = hand[_selected_index]
	var info := _controller.get_discard_penalty_info(_controller.state.current_player_index, tile.unique_id)
	if (info.discard_joker or info.extendable) and not _discard_confirm_pending:
		_discard_confirm_pending = true
		_discard_confirm_tile_id = tile.unique_id
		_update_warning("Confirm discard with penalty: press Discard again")
		return
	if _discard_confirm_pending and _discard_confirm_tile_id != tile.unique_id:
		_update_warning("Penalty confirmation reset")
		_discard_confirm_pending = false
		_discard_confirm_tile_id = -1
		return

	_controller.discard_tile(_controller.state.current_player_index, tile.unique_id)
	_discard_confirm_pending = false
	_discard_confirm_tile_id = -1
	_selected_index = 0
	_refresh_hand_list()
	_update_discard_warning()

func _on_bot_turn() -> void:
	var player = _controller.state.current_player_index
	var action = _bot.choose_action(_controller.state, player)
	if action != null:
		_controller.apply_action_if_valid(player, action)

func _refresh_hand_list() -> void:
	_hand_list.clear()
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	for i in range(hand.size()):
		_hand_list.add_item(_tile_label(hand[i]))
	if hand.size() > 0:
		_selected_index = clamp(_selected_index, 0, hand.size() - 1)
		_hand_list.select(_selected_index)
	_apply_required_tile_highlight()
	_apply_group_highlight()

func _refresh_center_info() -> void:
	_deck_label.text = "Deck: %s" % _controller.state.deck.size()
	if _controller.state.discard_pile.is_empty():
		_discard_label.text = "Discard: (none)"
	else:
		var top = _controller.state.discard_pile[_controller.state.discard_pile.size() - 1]
		_discard_label.text = "Discard: %s" % _tile_label(top)

	_indicator_label.text = "Indicator: %s" % _tile_label(_controller.state.okey_context.indicator_tile)
	_okey_label.text = "Okey: %s" % _tile_label(_controller.state.okey_context.interpret_fake_okey(_controller.state.okey_context.indicator_tile))

func _refresh_meld_list() -> void:
	_meld_list.clear()
	for meld in _controller.state.table_melds:
		_meld_list.add_item(_meld_label(meld))

func _refresh_player_info() -> void:
	_turn_label.text = "Turn: P%s" % _controller.state.current_player_index
	var sizes := []
	for i in range(_controller.state.players.size()):
		sizes.append("P%s:%s" % [i, _controller.state.players[i].hand.size()])
	_hands_label.text = "Hands: %s" % ", ".join(sizes)
	if _controller.state.turn_required_use_tile_id != -1:
		_required_label.text = "Required: %s" % _required_tile_label(_controller.state.turn_required_use_tile_id)
	else:
		_required_label.text = "Required: (none)"

func _selected_tiles() -> Array:
	var tiles := []
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	var selected := _hand_list.get_selected_items()
	for index in selected:
		if index >= 0 and index < hand.size() and not _grouped_tile_ids.has(hand[index].unique_id):
			tiles.append(hand[index])
	if tiles.is_empty() and hand.size() > 0:
		var t = hand[_selected_index]
		if not _grouped_tile_ids.has(t.unique_id):
			tiles.append(t)
	return tiles

func _build_melds_from_selection(tiles: Array, forced_kind: int) -> Array:
	if tiles.size() < 2:
		return []

	if forced_kind == Meld.Kind.RUN:
		return _build_run_meld(tiles)
	if forced_kind == Meld.Kind.SET:
		return _build_set_meld(tiles)
	if forced_kind == Meld.Kind.PAIRS:
		return _build_pairs_melds(tiles)

	# Auto detect
	var pairs := _build_pairs_melds(tiles)
	if not pairs.is_empty() and tiles.size() % 2 == 0 and _is_all_pairs(tiles):
		return pairs
	var setm := _build_set_meld(tiles)
	if not setm.is_empty():
		return setm
	var runm := _build_run_meld(tiles)
	if not runm.is_empty():
		return runm

	return []

func _build_pairs_melds(tiles: Array) -> Array:
	if tiles.size() < 2 or tiles.size() % 2 != 0:
		return []
	if not _is_all_pairs(tiles):
		return []
	var melds := []
	var sorted := _sorted_tiles(tiles)
	for i in range(0, sorted.size(), 2):
		melds.append({"kind": Meld.Kind.PAIRS, "tile_ids": [sorted[i].unique_id, sorted[i + 1].unique_id]})
	return melds

func _build_set_meld(tiles: Array) -> Array:
	if not _is_set_tiles(tiles):
		return []
	var ids := []
	for t in tiles:
		ids.append(t.unique_id)
	return [{"kind": Meld.Kind.SET, "tile_ids": ids}]

func _build_run_meld(tiles: Array) -> Array:
	if not _is_run_tiles(tiles):
		return []
	var sorted := _sorted_tiles(tiles)
	var ids := []
	for t in sorted:
		ids.append(t.unique_id)
	return [{"kind": Meld.Kind.RUN, "tile_ids": ids}]

func _is_all_pairs(tiles: Array) -> bool:
	var sorted := _sorted_tiles(tiles)
	for i in range(0, sorted.size(), 2):
		var a = sorted[i]
		var b = sorted[i + 1]
		if a.color != b.color or a.number != b.number:
			return false
	return true

func _is_set_tiles(tiles: Array) -> bool:
	if tiles.size() < 3 or tiles.size() > 4:
		return false
	var number = tiles[0].number
	var colors := {}
	for t in tiles:
		if t.number != number:
			return false
		if colors.has(t.color):
			return false
		colors[t.color] = true
	return true

func _is_run_tiles(tiles: Array) -> bool:
	if tiles.size() < 3:
		return false
	var color = tiles[0].color
	for t in tiles:
		if t.color != color:
			return false
	var sorted := _sorted_tiles(tiles)
	for i in range(1, sorted.size()):
		if sorted[i].number != sorted[i - 1].number + 1:
			return false
	return true

func _sorted_tiles(tiles: Array) -> Array:
	var sorted := tiles.duplicate()
	sorted.sort_custom(func(a, b):
		if a.color == b.color:
			return a.number < b.number
		return a.color < b.color
	)
	return sorted

func _selected_meld_kind() -> int:
	match _meld_type.selected:
		1: return Meld.Kind.RUN
		2: return Meld.Kind.SET
		3: return Meld.Kind.PAIRS
		_: return -1

func _update_banner(text: String) -> void:
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", text)

func _update_warning(text: String) -> void:
	if _banner != null and _banner.has_method("set_warning"):
		_banner.call("set_warning", text)

func _update_discard_warning() -> void:
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	if hand.is_empty():
		return
	var tile = hand[_selected_index]
	var info := _controller.get_discard_penalty_info(_controller.state.current_player_index, tile.unique_id)
	if info.discard_joker or info.extendable:
		_update_warning("Penalty risk on discard for %s" % _tile_label(tile))
	else:
		_update_banner("Selected %s" % _tile_label(tile))

func _add_history(text: String) -> void:
	_history_list.add_item(text)
	_history_list.ensure_current_is_visible()

func _clear_groups() -> void:
	_grouped_melds.clear()
	_grouped_tile_ids.clear()
	_selected_group_index = -1
	_refresh_preview_list()

func _refresh_preview_list() -> void:
	_preview_list.clear()
	var validation = _validate_all_groups()
	for meld in _grouped_melds:
		var label := _meld_preview_label(meld)
		var mval := _validate_group_meld(meld)
		if not mval.ok:
			label = "%s [BAD: %s]" % [label, mval.reason]
		_preview_list.add_item(label)
	if not validation.ok:
		_preview_list.add_item("TOTAL: BAD (%s)" % validation.reason)
	else:
		_preview_list.add_item("TOTAL: OK (%s pts | melds %s | pairs %s)" % [validation.points, validation.meld_points, validation.pairs_points])

func _meld_preview_label(meld) -> String:
	var kind = ["RUN", "SET", "PAIRS"][meld.kind]
	var tiles := []
	for id in meld.tile_ids:
		var t = _tile_from_id(id)
		if t != null:
			tiles.append(_tile_label(t))
		else:
			tiles.append(str(id))
	var points := int(_validate_group_meld(meld).get("points_value", 0))
	return "%s: %s (%s pts)" % [kind, ", ".join(tiles), points]

func _validate_group_meld(meld) -> Dictionary:
	var tiles: Array = []
	for id in meld.tile_ids:
		var t = _tile_from_id(id)
		if t == null:
			return {"ok": false, "reason": "missing tile"}
		tiles.append(t)
	var validator := MeldValidator.new()
	if meld.kind == Meld.Kind.RUN:
		return validator.validate_run(tiles, _controller.state.okey_context)
	if meld.kind == Meld.Kind.SET:
		return validator.validate_set(tiles, _controller.state.okey_context)
	if meld.kind == Meld.Kind.PAIRS:
		if tiles.size() != 2:
			return {"ok": false, "reason": "pair size"}
		if tiles[0].color == tiles[1].color and tiles[0].number == tiles[1].number:
			return {"ok": true, "reason": "", "points_value": tiles[0].number * 2}
		return {"ok": false, "reason": "pair mismatch"}
	return {"ok": false, "reason": "unknown"}

func _validate_all_groups() -> Dictionary:
	var total_points := 0
	var pairs_points := 0
	var meld_points := 0
	var pairs_count := 0
	for meld in _grouped_melds:
		var res := _validate_group_meld(meld)
		if not res.ok:
			return {"ok": false, "reason": res.reason, "points": 0}
		var pts := int(res.get("points_value", 0))
		total_points += pts
		if meld.kind == Meld.Kind.PAIRS:
			pairs_count += 1
			pairs_points += pts
		else:
			meld_points += pts
	# If all groups are pairs, show pairs-opening requirement (>=5 pairs).
	if meld_points == 0 and pairs_count > 0:
		if pairs_count < 5:
			return {"ok": false, "reason": "<5 pairs", "points": total_points, "pairs_points": pairs_points, "meld_points": meld_points}
		return {"ok": true, "reason": "", "points": total_points, "pairs_points": pairs_points, "meld_points": meld_points}
	var min_points = _controller.state.rule_config.open_min_points_initial
	if total_points < min_points:
		return {"ok": false, "reason": "<%s" % min_points, "points": total_points, "pairs_points": pairs_points, "meld_points": meld_points}
	return {"ok": true, "reason": "", "points": total_points, "pairs_points": pairs_points, "meld_points": meld_points}

func _tile_from_id(tile_id: int):
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	for t in hand:
		if t.unique_id == tile_id:
			return t
	return null

func _action_name(action_type: int) -> String:
	var names := ["STARTER_DISCARD", "DRAW", "TAKE_DISCARD", "OPEN_MELDS", "ADD_TO_MELD", "END_PLAY", "DISCARD", "FINISH"]
	if action_type >= 0 and action_type < names.size():
		return names[action_type]
	return "ACTION"

func _tile_label(tile) -> String:
	var colors := ["R", "B", "K", "Y"]
	var color = colors[tile.color] if tile.color >= 0 and tile.color < colors.size() else "?"
	var kind = "F" if tile.kind != 0 else ""
	return "%s%s-%s" % [kind, color, tile.number]

func _meld_label(meld) -> String:
	var kind = ["RUN", "SET", "PAIRS"][meld.kind]
	var tiles := []
	for t in meld.tiles_data:
		tiles.append(_tile_label(t))
	return "%s: %s" % [kind, ", ".join(tiles)]

func _required_tile_label(tile_id: int) -> String:
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	for t in hand:
		if t.unique_id == tile_id:
			return _tile_label(t)
	return str(tile_id)

func _maybe_auto_bot_turn() -> void:
	if not _auto_bot_enabled:
		return
	if _controller.state.current_player_index != 0:
		call_deferred("_on_bot_turn")

func _apply_required_tile_highlight() -> void:
	var required_id = _controller.state.turn_required_use_tile_id
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	for i in range(hand.size()):
		if required_id != -1 and hand[i].unique_id == required_id:
			_hand_list.set_item_custom_fg_color(i, Color(1.0, 0.3, 0.3))
		else:
			_hand_list.set_item_custom_fg_color(i, Color(1, 1, 1))

func _apply_group_highlight() -> void:
	var hand = _controller.state.players[_controller.state.current_player_index].hand
	var group_ids := {}
	if _selected_group_index >= 0 and _selected_group_index < _grouped_melds.size():
		for id in _grouped_melds[_selected_group_index].tile_ids:
			group_ids[id] = true
	for i in range(hand.size()):
		var t = hand[i]
		if group_ids.has(t.unique_id):
			_hand_list.set_item_custom_bg_color(i, Color(0.2, 0.6, 0.2))
		elif _grouped_tile_ids.has(t.unique_id):
			_hand_list.set_item_custom_bg_color(i, Color(0.2, 0.2, 0.2))
		else:
			_hand_list.set_item_custom_bg_color(i, Color(0, 0, 0, 0))

func _rebuild_grouped_tile_ids() -> void:
	_grouped_tile_ids.clear()
	for meld in _grouped_melds:
		for id in meld.tile_ids:
			_grouped_tile_ids[id] = true
