extends RefCounted


func run() -> bool:
	return _test_controller_legacy_paths_removed() and _test_rule_config_legacy_fields_removed()


func _test_controller_legacy_paths_removed() -> bool:
	var controller = LocalGameController.new()
	if controller.has_signal("round_cancelled"):
		push_error("Legacy signal round_cancelled should not exist")
		return false
	if controller.has_method("get_discard_penalty_info"):
		push_error("Legacy method get_discard_penalty_info should not exist")
		return false
	if controller.has_method("apply_illegal_manipulation_penalty"):
		push_error("Legacy method apply_illegal_manipulation_penalty should not exist")
		return false
	if controller.has_method("peek_discard"):
		push_error("Legacy method peek_discard should not exist")
		return false
	return true


func _test_rule_config_legacy_fields_removed() -> bool:
	var cfg = RuleConfig.new()
	if cfg.get("ruleset") != null:
		push_error("Legacy RuleConfig field ruleset should not exist")
		return false
	if cfg.get("scoring_mode") != null:
		push_error("Legacy RuleConfig field scoring_mode should not exist")
		return false
	if cfg.get("cancel_round_if_all_pairs_open") != null:
		push_error("Legacy RuleConfig field cancel_round_if_all_pairs_open should not exist")
		return false
	return true
