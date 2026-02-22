extends Node
class_name MatchControllerPort

signal state_changed(new_state)
signal action_rejected(reason)
signal action_applied(player_index, action_type)
signal turn_advanced(current_player_index, phase)
signal match_finished(winner_indices, final_scores, reason)

var state = null

func start_new_round(_rule_config, _rng_seed: int, _player_count: int = 4) -> void:
	push_warning("start_new_round not implemented on MatchControllerPort")

func start_new_match(_rule_config, _rng_seed: int, _player_count: int = 4) -> void:
	push_warning("start_new_match not implemented on MatchControllerPort")

func submit_action_envelope(_action_dict: Dictionary) -> Dictionary:
	return {"ok": false, "code": "not_implemented", "reason": "submit_action_envelope not implemented"}

func apply_action_if_valid(_player_index: int, _action) -> Dictionary:
	return {"ok": false, "code": "not_implemented", "reason": "apply_action_if_valid not implemented"}

func starter_discard(_player_index: int, _tile_id: int) -> Dictionary:
	return {"ok": false, "code": "not_implemented", "reason": "starter_discard not implemented"}

func draw_from_deck(_player_index: int) -> Dictionary:
	return {"ok": false, "code": "not_implemented", "reason": "draw_from_deck not implemented"}

func take_discard(_player_index: int) -> Dictionary:
	return {"ok": false, "code": "not_implemented", "reason": "take_discard not implemented"}

func end_play_turn(_player_index: int) -> Dictionary:
	return {"ok": false, "code": "not_implemented", "reason": "end_play_turn not implemented"}

func discard_tile(_player_index: int, _tile_id: int) -> Dictionary:
	return {"ok": false, "code": "not_implemented", "reason": "discard_tile not implemented"}

func apply_manual_penalty(_player_index: int, _points: int) -> void:
	push_warning("apply_manual_penalty not implemented on MatchControllerPort")

func request_new_round() -> Dictionary:
	return {"ok": false, "code": "not_supported", "reason": "request_new_round not supported"}
