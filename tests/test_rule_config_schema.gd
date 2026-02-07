extends RefCounted


func run() -> bool:
	return _test_to_dict_schema() and _test_roundtrip()


func _test_to_dict_schema() -> bool:
	var cfg = RuleConfig.new()
	var data = cfg.to_dict()

	var expected_keys = [
		"preset_name",
		"tiles_per_player",
		"starter_tiles",
		"open_min_points_initial",
		"allow_open_by_five_pairs",
		"open_by_pairs_locks_to_pairs",
		"require_discard_take_to_be_used",
		"if_not_opened_discard_take_requires_open_and_includes_tile",
		"discard_take_must_be_used_always",
		"indicator_fake_joker_behavior",
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

	var forbidden = ["ruleset", "scoring_mode", "penalty_value", "cancel_round_if_all_pairs_open", "debug_allow_peek_discard"]
	for key2 in forbidden:
		if data.has(key2):
			push_error("Forbidden legacy key present in RuleConfig.to_dict: %s" % key2)
			return false

	return true


func _test_roundtrip() -> bool:
	var d = {
		"preset_name": "seokey11_custom",
		"tiles_per_player": 21,
		"starter_tiles": 22,
		"open_min_points_initial": 101,
		"allow_open_by_five_pairs": true,
		"open_by_pairs_locks_to_pairs": true,
		"require_discard_take_to_be_used": true,
		"if_not_opened_discard_take_requires_open_and_includes_tile": true,
		"discard_take_must_be_used_always": true,
		"indicator_fake_joker_behavior": "redraw",
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
