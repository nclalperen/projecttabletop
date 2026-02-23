extends SceneTree

const TEST_SCRIPTS = [
	"res://tests/test_deck_builder.gd",
	"res://tests/test_action_surface.gd",
	"res://tests/test_rule_config_schema.gd",
	"res://tests/test_asset_license_registry.gd",
	"res://tests/test_asset_registry_resolves.gd",
	"res://tests/test_no_direct_asset_literals.gd",
	"res://tests/test_game_setup.gd",
	"res://tests/test_dealer_rotation.gd",
	"res://tests/test_turn_loop.gd",
	"res://tests/test_bot_heuristic.gd",
	"res://tests/test_bot_heuristic_draw_policy.gd",
	"res://tests/test_bot_finish_and_random_draw.gd",
	"res://tests/test_bot_turn_progression.gd",
	"res://tests/test_bot_long_round_stability.gd",
	"res://tests/test_meld_validator.gd",
	"res://tests/test_fake_okey_pairs.gd",
	"res://tests/test_open_melds.gd",
	"res://tests/test_add_to_meld.gd",
	"res://tests/test_open_add_discard_flow.gd",
	"res://tests/test_reducer_clone_melds.gd",
	"res://tests/test_discard_stacks_state.gd",
	"res://tests/test_pairs_mode.gd",
	"res://tests/test_discard_take_rule.gd",
	"res://tests/test_discard_take_opened_requires_immediate_use.gd",
	"res://tests/test_discard_take_strict_unopened.gd",
	"res://tests/test_discard_take_pairs_open.gd",
	"res://tests/test_end_play_discard_take_gate.gd",
	"res://tests/test_discard_once_per_turn.gd",
	"res://tests/test_discard_after_meld_count.gd",
	"res://tests/test_turn_progression_invariants.gd",
	"res://tests/test_deck_discard_transition_stability.gd",
	"res://tests/test_action_rejection_consistency.gd",
	"res://tests/test_finish_requirements.gd",
	"res://tests/test_deck_exhausted.gd",
	"res://tests/test_finish_scoring.gd",
	"res://tests/test_scoring_dossier_rules.gd",
	"res://tests/test_scoring_unopened_constant.gd",
	"res://tests/test_scoring_finish_type_matrix.gd",
	"res://tests/test_stock_empty_round_end_modes.gd",
	"res://tests/test_failed_open_penalty_101.gd",
	"res://tests/test_discard_penalties_non_finishing.gd",
	"res://tests/test_match_end_rounds_mode.gd",
	"res://tests/test_match_end_target_score_mode.gd",
	"res://tests/test_api_envelope_translation.gd",
	"res://tests/test_seat_view_adapter.gd",
	"res://tests/test_state_codec_redaction.gd",
	"res://tests/test_protocol_schema.gd",
	"res://tests/test_eos_gdextension_mapping.gd",
	"res://tests/test_online_service_backend_modes.gd",
	"res://tests/test_lobby_service_model_contract.gd",
	"res://tests/test_online_lobby_flow.gd",
	"res://tests/test_transport_envelope_runtime_guard.gd",
	"res://tests/test_host_action_authority.gd",
	"res://tests/test_reconnect_bot_takeover.gd",
	"res://tests/test_client_controller_envelope_translation.gd",
	"res://tests/test_ui_scene_contract.gd",
	"res://tests/test_ui_gametable3d_scene_contract.gd",
	"res://tests/test_ui_no_legacy_controls.gd",
	"res://tests/test_ui_settings_visual.gd",
	"res://tests/test_local_controller.gd",
	"res://tests/test_legacy_paths_removed.gd",
	"res://tests/test_table_geometry_constants.gd",
	"res://tests/test_rack_slot_manager.gd",
]

var _all_ok := true


func _init() -> void:
	_all_ok = _run_all_tests()
	call_deferred("_complete")


func _run_all_tests() -> bool:
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
		LocalGameController.free_test_tracked_instances()
		HostMatchController.free_test_tracked_instances()
		ClientMatchController.free_test_tracked_instances()
		P2PTransportEOS.free_test_tracked_instances()
		OnlineServiceEOS.free_test_tracked_instances()
		LobbyServiceEOS.free_test_tracked_instances()
	return ok

func _complete() -> void:
	# Let queued disposals/resources settle before process shutdown.
	await process_frame
	await process_frame
	if _all_ok:
		print("All tests passed")
	else:
		print("Tests failed")

	quit()
