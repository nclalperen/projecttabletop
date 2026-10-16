extends RefCounted

const AUDIO_CONTROLLER = preload("res://ui/game_table/AudioController.gd")

class MockAudioService extends Node:
	var played: Array[StringName] = []

	func play_sfx(event_id: StringName) -> void:
		played.append(event_id)

	func reset() -> void:
		played.clear()


func _expect(cond: bool, msg: String) -> bool:
	if not cond:
		push_error("FAIL: %s" % msg)
		print("FAIL: %s" % msg)
		return false
	return true


func run() -> bool:
	var ok: bool = true

	# 1. Class and constants verification
	ok = _expect(AUDIO_CONTROLLER.SFX_DRAW_FROM_DECK == &"draw_from_deck", "SFX_DRAW_FROM_DECK constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_TAKE_DISCARD == &"take_discard", "SFX_TAKE_DISCARD constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_RACK_MOVE == &"rack_move", "SFX_RACK_MOVE constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_DRAFT_MOVE == &"stage_move", "SFX_DRAFT_MOVE constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_ADD_TO_MELD == &"add_to_meld", "SFX_ADD_TO_MELD constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_DISCARD == &"discard", "SFX_DISCARD constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_INVALID_ACTION == &"invalid_action", "SFX_INVALID_ACTION constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_ROUND_END == &"round_end", "SFX_ROUND_END constant mismatch") and ok
	ok = _expect(AUDIO_CONTROLLER.SFX_NEW_ROUND == &"new_round", "SFX_NEW_ROUND constant mismatch") and ok

	# 2. Silent mode / null service
	var silent_ctrl = AUDIO_CONTROLLER.new()
	ok = _expect(silent_ctrl.audio_service == null, "Default audio_service should be null") and ok
	ok = _expect(silent_ctrl.sound_enabled == true, "Default sound_enabled should be true") and ok
	silent_ctrl.play_draw()
	silent_ctrl.play(&"anything")

	# 3. Mock service playback
	var mock = MockAudioService.new()
	var ctrl = AUDIO_CONTROLLER.new(mock, true)
	ok = _expect(ctrl.audio_service == mock, "audio_service reference should match passed service") and ok
	ok = _expect(ctrl.sound_enabled == true, "sound_enabled should match passed parameter") and ok

	ctrl.play_draw()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_DRAW_FROM_DECK, "play_draw failed") and ok
	mock.reset()

	ctrl.play_take_discard()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_TAKE_DISCARD, "play_take_discard failed") and ok
	mock.reset()

	ctrl.play_rack_move()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_RACK_MOVE, "play_rack_move failed") and ok
	mock.reset()

	ctrl.play_draft_move()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_DRAFT_MOVE, "play_draft_move failed") and ok
	mock.reset()

	ctrl.play_add_to_meld()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_ADD_TO_MELD, "play_add_to_meld failed") and ok
	mock.reset()

	ctrl.play_discard()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_DISCARD, "play_discard failed") and ok
	mock.reset()

	ctrl.play_invalid()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_INVALID_ACTION, "play_invalid failed") and ok
	mock.reset()

	ctrl.play_round_end()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_ROUND_END, "play_round_end failed") and ok
	mock.reset()

	ctrl.play_new_round()
	ok = _expect(mock.played.size() == 1 and mock.played[0] == AUDIO_CONTROLLER.SFX_NEW_ROUND, "play_new_round failed") and ok
	mock.reset()

	# Generic play
	ctrl.play(&"custom_sound")
	ok = _expect(mock.played.size() == 1 and mock.played[0] == &"custom_sound", "generic play failed") and ok
	mock.reset()

	# 4. Sound disabled flag
	ctrl.sound_enabled = false
	ctrl.play_draw()
	ctrl.play_discard()
	ctrl.play(&"custom_sound")
	ok = _expect(mock.played.is_empty(), "Disabled sound should suppress playback") and ok

	# Free mock
	mock.free()

	if ok:
		print("PASS test_audio_controller")
	return ok
