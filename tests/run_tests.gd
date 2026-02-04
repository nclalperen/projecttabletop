extends SceneTree

const TEST_SCRIPTS = [
	"res://tests/test_deck_builder.gd",
	"res://tests/test_game_setup.gd",
	"res://tests/test_turn_loop.gd",
	"res://tests/test_meld_validator.gd",
	"res://tests/test_open_melds.gd",
	"res://tests/test_add_to_meld.gd",
	"res://tests/test_pairs_mode.gd",
	"res://tests/test_discard_take_rule.gd",
	"res://tests/test_discard_take_strict_unopened.gd",
	"res://tests/test_discard_penalties.gd",
	"res://tests/test_penalty_edges.gd",
	"res://tests/test_failed_opening_penalty.gd",
	"res://tests/test_round_cancel_pairs.gd",
	"res://tests/test_no_winner_penalty.gd",
	"res://tests/test_round_cancel_signal.gd",
	"res://tests/test_discard_penalty_info.gd",
	"res://tests/test_discard_peek.gd",
	"res://tests/test_peek_controller.gd",
	"res://tests/test_finish_requirements.gd",
	"res://tests/test_deck_exhausted.gd",
	"res://tests/test_scoring_matrix.gd",
	"res://tests/test_bot_discard_safety.gd",
	"res://tests/test_bot_random.gd",
	"res://tests/test_bot_heuristic.gd",
	"res://tests/test_finish_scoring.gd",
	"res://tests/test_local_controller.gd",
]

func _initialize() -> void:
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
		if test is Object:
			test.free()
		test = null
		script = null

	if ok:
		print("All tests passed")
	else:
		print("Tests failed")

	quit()
