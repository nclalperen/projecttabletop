extends RefCounted


func run() -> bool:
	return _test_to_dict_schema() and _test_roundtrip() and _test_alias_mapping()


func _test_to_dict_schema() -> bool:
	var cfg = RuleConfig.new()
	var data = cfg.to_dict()

	var expected_keys = [
		"preset_name",
		"ruleset_name",
		"tiles_per_player",
		"starter_tiles",
		"open_min_points_initial",
		"allow_open_by_five_pairs",
		"open_by_pairs_locks_to_pairs",
		"one_turn_finish_ignores_101",
		"allow_joker_reclaim_after_open",
		"enable_devam",
		"cancel_deal_if_all_open_doubles",
		"require_discard_take_to_be_used",
		"if_not_opened_discard_take_requires_open_and_includes_tile",
		"discard_take_must_be_used_always",
		"end_on_stock_empty",
		"indicator_fake_joker_behavior",
		"penalty_value",
		"unopened_penalty",
		"joker_hand_value",
		"pairs_okey_unopened_penalty",
		"unopened_gets_extra_joker_penalty",
		"penalty_discard_joker",
		"penalty_discard_playable_tile",
		"penalty_failed_open_attempt",
		"penalty_illegal_takeback",
		"timer_seconds",
		"match_end_mode",
		"match_end_value",
	]

	for key in expected_keys:
		if not data.has(key):
			push_error("Missing canonical RuleConfig key: %s" % key)
			return false

	if data.size() != expected_keys.size():
		push_error("Unexpected extra RuleConfig keys in to_dict")
		return false

	var forbidden = ["ruleset", "scoring_mode", "cancel_round_if_all_pairs_open", "debug_allow_peek_discard"]
	for key2 in forbidden:
		if data.has(key2):
			push_error("Forbidden legacy key present in RuleConfig.to_dict: %s" % key2)
			return false

	return true


func _test_roundtrip() -> bool:
	var d = {
		"preset_name": "seokey11_custom",
		"ruleset_name": "tr_101_custom",
		"tiles_per_player": 21,
		"starter_tiles": 22,
		"open_min_points_initial": 101,
		"allow_open_by_five_pairs": true,
		"open_by_pairs_locks_to_pairs": true,
		"one_turn_finish_ignores_101": false,
		"allow_joker_reclaim_after_open": true,
		"enable_devam": false,
		"cancel_deal_if_all_open_doubles": true,
		"require_discard_take_to_be_used": true,
		"if_not_opened_discard_take_requires_open_and_includes_tile": true,
		"discard_take_must_be_used_always": true,
		"end_on_stock_empty": "score_no_winner",
		"indicator_fake_joker_behavior": "redraw",
		"penalty_value": 101,
		"unopened_penalty": 202,
		"joker_hand_value": 101,
		"pairs_okey_unopened_penalty": 404,
		"unopened_gets_extra_joker_penalty": false,
		"penalty_discard_joker": true,
		"penalty_discard_playable_tile": true,
		"penalty_failed_open_attempt": true,
		"penalty_illegal_takeback": true,
		"timer_seconds": 30,
		"match_end_mode": "rounds",
		"match_end_value": 5,
	}
	var cfg = RuleConfig.from_dict(d)
	var out = cfg.to_dict()
	for key in d.keys():
		if out.get(key) != d.get(key):
			push_error("RuleConfig roundtrip mismatch at key: %s" % key)
			return false
	return true


func _test_alias_mapping() -> bool:
	var alias_payload = {
		"ruleset": "legacy_ruleset_name",
		"stock_exhaustion_ends_hand": true,
		"allow_joker_reclaim": false,
		"devam_enabled": true,
		"penalty_unopened": 303,
		"joker_tile_unplayed_value": 77,
		"all_players_open_pairs_aborts_hand": true,
		"penalties": {
			"discarding_joker": false,
			"discarding_playable_tile": false,
			"failed_open_attempt": false,
			"illegal_takeback": false,
		},
	}
	var cfg = RuleConfig.from_dict(alias_payload)
	if cfg.ruleset_name != "legacy_ruleset_name":
		push_error("Alias mapping failed for ruleset")
		return false
	if cfg.end_on_stock_empty != "score_no_winner":
		push_error("Alias mapping failed for stock_exhaustion_ends_hand")
		return false
	if cfg.allow_joker_reclaim_after_open != false:
		push_error("Alias mapping failed for allow_joker_reclaim")
		return false
	if cfg.enable_devam != true:
		push_error("Alias mapping failed for devam_enabled")
		return false
	if cfg.unopened_penalty != 303:
		push_error("Alias mapping failed for penalty_unopened")
		return false
	if cfg.joker_hand_value != 77:
		push_error("Alias mapping failed for joker_tile_unplayed_value")
		return false
	if cfg.cancel_deal_if_all_open_doubles != true:
		push_error("Alias mapping failed for all_players_open_pairs_aborts_hand")
		return false
	if cfg.penalty_discard_joker != false \
		or cfg.penalty_discard_playable_tile != false \
		or cfg.penalty_failed_open_attempt != false \
		or cfg.penalty_illegal_takeback != false:
		push_error("Alias mapping failed for penalties object")
		return false
	return true
