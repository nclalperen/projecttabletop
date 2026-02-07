extends SceneTree

const TEST_SCRIPTS = [
	"res://tests/test_deck_builder.gd",
	"res://tests/test_action_surface.gd",
	"res://tests/test_rule_config_schema.gd",
	"res://tests/test_game_setup.gd",
	"res://tests/test_dealer_rotation.gd",
	"res://tests/test_turn_loop.gd",
	"res://tests/test_bot_heuristic.gd",
	"res://tests/test_bot_heuristic_draw_policy.gd",
	"res://tests/test_bot_turn_progression.gd",
	"res://tests/test_meld_validator.gd",
	"res://tests/test_open_melds.gd",
	"res://tests/test_add_to_meld.gd",
	"res://tests/test_pairs_mode.gd",
	"res://tests/test_discard_take_rule.gd",
	"res://tests/test_discard_take_opened_requires_immediate_use.gd",
	"res://tests/test_discard_take_strict_unopened.gd",
	"res://tests/test_discard_take_pairs_open.gd",
	"res://tests/test_end_play_discard_take_gate.gd",
	"res://tests/test_discard_once_per_turn.gd",
	"res://tests/test_discard_after_meld_count.gd",
	"res://tests/test_finish_requirements.gd",
	"res://tests/test_deck_exhausted.gd",
	"res://tests/test_finish_scoring.gd",
	"res://tests/test_scoring_dossier_rules.gd",
	"res://tests/test_scoring_unopened_constant.gd",
	"res://tests/test_ui_scene_contract.gd",
	"res://tests/test_ui_no_legacy_controls.gd",
	"res://tests/test_local_controller.gd",
	"res://tests/test_legacy_paths_removed.gd",
]

func _init() -> void:
	var ok = true
	for path in TEST_SCRIPTS:
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script == null:
			push_error("Failed to load test: %s" % path)
			ok = false
			continue
		var test = script.new()
		if not test.run():
			ok = false
		test = null
		script = null

	if ok:
		print("All tests passed")
	else:
		print("Tests failed")

	quit()
