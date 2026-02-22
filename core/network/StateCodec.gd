extends RefCounted
class_name StateCodec

const _DECK_PLACEHOLDER_BASE: int = -900000
const _HAND_PLACEHOLDER_BASE: int = -800000
const SEAT_ADAPTER_SCRIPT: Script = preload("res://core/network/SeatViewAdapter.gd")

static func encode_host_state(state: GameState) -> Dictionary:
	return _encode_state(state, -1, false)

static func encode_for_client(state: GameState, local_abs_seat: int) -> Dictionary:
	return _encode_state(state, local_abs_seat, true)

static func decode_client_snapshot(payload: Dictionary) -> GameState:
	var state := GameState.new()
	state.phase = int(payload.get("phase", GameState.Phase.SETUP))
	state.current_player_index = int(payload.get("current_player_index", 0))
	state.turn_required_use_tile_id = int(payload.get("turn_required_use_tile_id", -1))
	state.last_finish_all_in_one_turn = bool(payload.get("last_finish_all_in_one_turn", false))
	state.dealer_index = int(payload.get("dealer_index", -1))
	state.indicator_stack_index = int(payload.get("indicator_stack_index", -1))
	state.indicator_tile_index = int(payload.get("indicator_tile_index", -1))
	state.draw_stack_indices = _as_int_array(payload.get("draw_stack_indices", []))
	state.round_index = int(payload.get("round_index", 1))
	state.round_end_reason = String(payload.get("round_end_reason", ""))
	state.last_winner_index = int(payload.get("last_winner_index", -1))
	state.last_finish_type = String(payload.get("last_finish_type", ""))
	state.match_finished = bool(payload.get("match_finished", false))
	state.match_winner_indices = _as_int_array(payload.get("match_winner_indices", []))

	var cfg_data = payload.get("rule_config", {})
	if typeof(cfg_data) == TYPE_DICTIONARY:
		state.rule_config = RuleConfig.from_dict(cfg_data)
	else:
		state.rule_config = RuleConfig.new()

	state.okey_context = _decode_okey_context(payload.get("okey_context", {}))
	state.players = _decode_players(payload.get("players", []))
	state.deck = _decode_tiles_or_placeholder(payload.get("deck", []), int(payload.get("deck_size", 0)), _DECK_PLACEHOLDER_BASE)
	state.discard_pile = _decode_tiles_or_placeholder(payload.get("discard_pile", []), int(payload.get("discard_pile_size", 0)), _DECK_PLACEHOLDER_BASE - 10000)
	state.player_discard_stacks = _decode_discard_stacks(payload.get("player_discard_stacks", []))
	state.table_melds = _decode_melds(payload.get("table_melds", []))
	return state

static func _encode_state(state: GameState, local_abs_seat: int, redact: bool) -> Dictionary:
	if state == null:
		return {}
	var player_count: int = state.players.size()
	var projected: bool = local_abs_seat >= 0 and player_count > 0
	var normalized_seat: int = _normalize(local_abs_seat, player_count) if projected else 0
	var out: Dictionary = {
		"phase": int(state.phase),
		"turn_required_use_tile_id": int(state.turn_required_use_tile_id),
		"last_finish_all_in_one_turn": bool(state.last_finish_all_in_one_turn),
		"indicator_stack_index": int(state.indicator_stack_index),
		"indicator_tile_index": int(state.indicator_tile_index),
		"draw_stack_indices": state.draw_stack_indices.duplicate(true),
		"round_index": int(state.round_index),
		"round_end_reason": String(state.round_end_reason),
		"last_finish_type": String(state.last_finish_type),
		"match_finished": bool(state.match_finished),
		"rule_config": state.rule_config.to_dict() if state.rule_config != null else RuleConfig.new().to_dict(),
		"okey_context": _encode_okey_context(state.okey_context),
		"deck_size": int(state.deck.size()),
		"discard_pile_size": int(state.discard_pile.size()),
	}

	if redact:
		out["deck"] = []
	else:
		out["deck"] = _encode_tiles(state.deck)
	out["discard_pile"] = _encode_tiles(state.discard_pile)

	if projected:
		out["current_player_index"] = SEAT_ADAPTER_SCRIPT.to_local(int(state.current_player_index), normalized_seat, player_count)
		out["dealer_index"] = SEAT_ADAPTER_SCRIPT.to_local(int(state.dealer_index), normalized_seat, player_count) if int(state.dealer_index) >= 0 else -1
		out["last_winner_index"] = SEAT_ADAPTER_SCRIPT.to_local(int(state.last_winner_index), normalized_seat, player_count) if int(state.last_winner_index) >= 0 else -1
		out["match_winner_indices"] = SEAT_ADAPTER_SCRIPT.remap_index_array_to_local(state.match_winner_indices, normalized_seat, player_count)
	else:
		out["current_player_index"] = int(state.current_player_index)
		out["dealer_index"] = int(state.dealer_index)
		out["last_winner_index"] = int(state.last_winner_index)
		out["match_winner_indices"] = state.match_winner_indices.duplicate(true)

	var players_out: Array = []
	for local_idx in range(player_count):
		var abs_idx: int = local_idx
		if projected:
			abs_idx = SEAT_ADAPTER_SCRIPT.to_abs(local_idx, normalized_seat, player_count)
		var p = state.players[abs_idx]
		var hand_count: int = p.hand.size()
		var include_hand: bool = not redact or local_idx == 0
		players_out.append({
			"has_opened": bool(p.has_opened),
			"opened_by_pairs": bool(p.opened_by_pairs),
			"opened_mode": String(p.opened_mode),
			"score_total": int(p.score_total),
			"score_round": int(p.score_round),
			"deal_penalty_points": int(p.deal_penalty_points),
			"last_round_breakdown": p.last_round_breakdown.duplicate(true),
			"hand_count": hand_count,
			"hand_tiles": _encode_tiles(p.hand) if include_hand else [],
		})
	out["players"] = players_out

	var stack_src: Array = state.player_discard_stacks
	var stacks_out: Array = []
	for local_stack_idx in range(player_count):
		var abs_stack_idx: int = local_stack_idx
		if projected:
			abs_stack_idx = SEAT_ADAPTER_SCRIPT.to_abs(local_stack_idx, normalized_seat, player_count)
		if abs_stack_idx >= 0 and abs_stack_idx < stack_src.size():
			stacks_out.append(_encode_tiles(stack_src[abs_stack_idx]))
		else:
			stacks_out.append([])
	out["player_discard_stacks"] = stacks_out

	var melds_out: Array = []
	for meld in state.table_melds:
		var owner_index: int = int(meld.owner_index)
		if projected and owner_index >= 0:
			owner_index = SEAT_ADAPTER_SCRIPT.to_local(owner_index, normalized_seat, player_count)
		melds_out.append({
			"kind": int(meld.kind),
			"owner_index": owner_index,
			"tiles": meld.tiles.duplicate(true),
			"tiles_data": _encode_tiles(meld.tiles_data),
		})
	out["table_melds"] = melds_out
	return out

static func _encode_okey_context(ctx: OkeyContext) -> Dictionary:
	if ctx == null:
		return {}
	return {
		"okey_color": int(ctx.okey_color),
		"okey_number": int(ctx.okey_number),
		"indicator_tile": _encode_tile(ctx.indicator_tile),
	}

static func _decode_okey_context(raw) -> OkeyContext:
	if typeof(raw) != TYPE_DICTIONARY:
		return OkeyContext.new(Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, _DECK_PLACEHOLDER_BASE - 20000))
	var indicator: Tile = _decode_tile(raw.get("indicator_tile", {}), _DECK_PLACEHOLDER_BASE - 20000)
	var ctx := OkeyContext.new(indicator)
	ctx.okey_color = int(raw.get("okey_color", ctx.okey_color))
	ctx.okey_number = int(raw.get("okey_number", ctx.okey_number))
	return ctx

static func _encode_tiles(tiles: Array) -> Array:
	var out: Array = []
	for t in tiles:
		out.append(_encode_tile(t))
	return out

static func _encode_tile(tile) -> Dictionary:
	if tile == null:
		return {}
	return {
		"color": int(tile.color),
		"number": int(tile.number),
		"kind": int(tile.kind),
		"unique_id": int(tile.unique_id),
	}

static func _decode_tiles_or_placeholder(raw, expected_size: int, base_id: int) -> Array:
	if typeof(raw) == TYPE_ARRAY and not raw.is_empty():
		return _decode_tiles(raw)
	return _make_placeholder_tiles(maxi(0, expected_size), base_id)

static func _decode_tiles(raw: Array) -> Array:
	var out: Array = []
	for i in range(raw.size()):
		out.append(_decode_tile(raw[i], _DECK_PLACEHOLDER_BASE - i))
	return out

static func _decode_tile(raw, fallback_id: int) -> Tile:
	if typeof(raw) != TYPE_DICTIONARY:
		return Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, fallback_id)
	return Tile.new(
		int(raw.get("color", Tile.TileColor.RED)),
		int(raw.get("number", 1)),
		int(raw.get("kind", Tile.Kind.NORMAL)),
		int(raw.get("unique_id", fallback_id))
	)

static func _decode_players(raw) -> Array:
	if typeof(raw) != TYPE_ARRAY:
		return []
	var players: Array = []
	for i in range(raw.size()):
		var data = raw[i]
		var p := PlayerState.new()
		if typeof(data) == TYPE_DICTIONARY:
			p.has_opened = bool(data.get("has_opened", false))
			p.opened_by_pairs = bool(data.get("opened_by_pairs", false))
			p.opened_mode = String(data.get("opened_mode", ""))
			p.score_total = int(data.get("score_total", 0))
			p.score_round = int(data.get("score_round", 0))
			p.deal_penalty_points = int(data.get("deal_penalty_points", 0))
			if typeof(data.get("last_round_breakdown", {})) == TYPE_DICTIONARY:
				p.last_round_breakdown = data.get("last_round_breakdown", {}).duplicate(true)
			var hand_tiles = data.get("hand_tiles", [])
			if typeof(hand_tiles) == TYPE_ARRAY and not hand_tiles.is_empty():
				p.hand = _decode_tiles(hand_tiles)
			else:
				p.hand = _make_placeholder_tiles(int(data.get("hand_count", 0)), _HAND_PLACEHOLDER_BASE - i * 1000)
		players.append(p)
	return players

static func _decode_discard_stacks(raw) -> Array:
	if typeof(raw) != TYPE_ARRAY:
		return []
	var out: Array = []
	for i in range(raw.size()):
		var stack_raw = raw[i]
		if typeof(stack_raw) == TYPE_ARRAY:
			out.append(_decode_tiles(stack_raw))
		else:
			out.append([])
	return out

static func _decode_melds(raw) -> Array:
	if typeof(raw) != TYPE_ARRAY:
		return []
	var out: Array = []
	for i in range(raw.size()):
		var m = raw[i]
		if typeof(m) != TYPE_DICTIONARY:
			continue
		var tile_ids: Array = []
		if typeof(m.get("tiles", [])) == TYPE_ARRAY:
			tile_ids = m.get("tiles", []).duplicate(true)
		var tiles_data: Array = []
		if typeof(m.get("tiles_data", [])) == TYPE_ARRAY:
			tiles_data = _decode_tiles(m.get("tiles_data", []))
		out.append(Meld.new(
			int(m.get("kind", Meld.Kind.RUN)),
			tile_ids,
			tiles_data,
			int(m.get("owner_index", -1))
		))
	return out

static func _make_placeholder_tiles(count: int, start_id: int) -> Array:
	var out: Array = []
	for i in range(maxi(0, count)):
		out.append(Tile.new(Tile.TileColor.RED, 1, Tile.Kind.NORMAL, start_id - i))
	return out

static func _as_int_array(raw) -> Array:
	if typeof(raw) != TYPE_ARRAY:
		return []
	var out: Array = []
	for v in raw:
		out.append(int(v))
	return out

static func _normalize(index: int, player_count: int) -> int:
	if player_count <= 0:
		return 0
	var value: int = index % player_count
	if value < 0:
		value += player_count
	return value
