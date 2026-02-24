extends RefCounted

const RESOLVER = preload("res://ui/game_table/InteractionResolver.gd")

func run() -> bool:
	var ok: bool = true

	var base_ctx := {
		"is_my_turn": true,
		"phase": GameState.Phase.TURN_PLAY,
		"tile_id": 77,
		"from_rack_slot": 3,
		"from_draft_slot": -1,
		"discard_intent": false,
		"committed_meld_hit": false,
		"committed_meld_index": -1,
		"draft_lane_intent": false,
		"draft_target_slot": -1,
		"rack_intent": false,
		"rack_target_slot": -1,
		"allow_rack_reorder": true,
		"allow_end_play_then_discard": true,
	}

	# Invalid zone -> no-op.
	var d0: Dictionary = RESOLVER.resolve_drop(base_ctx)
	ok = _expect(d0.get("kind", &"") == RESOLVER.DECISION_NO_OP, "invalid-zone decision should be no_op") and ok

	# Discard precedence over all other intents (legal discard phase).
	var discard_ctx: Dictionary = base_ctx.duplicate(true)
	discard_ctx["phase"] = GameState.Phase.TURN_DISCARD
	discard_ctx["discard_intent"] = true
	discard_ctx["committed_meld_hit"] = true
	discard_ctx["committed_meld_index"] = 2
	discard_ctx["draft_lane_intent"] = true
	discard_ctx["draft_target_slot"] = 9
	discard_ctx["rack_intent"] = true
	discard_ctx["rack_target_slot"] = 10
	var d1: Dictionary = RESOLVER.resolve_drop(discard_ctx)
	ok = _expect(d1.get("kind", &"") == RESOLVER.DECISION_DISCARD, "discard should take precedence") and ok

	# Rack vs draft disambiguation.
	var rack_ctx: Dictionary = base_ctx.duplicate(true)
	rack_ctx["rack_intent"] = true
	rack_ctx["rack_target_slot"] = 8
	var d2: Dictionary = RESOLVER.resolve_drop(rack_ctx)
	ok = _expect(d2.get("kind", &"") == RESOLVER.DECISION_MOVE_RACK_SLOT, "rack intent should move rack slot") and ok

	var draft_ctx: Dictionary = rack_ctx.duplicate(true)
	draft_ctx["draft_lane_intent"] = true
	draft_ctx["draft_target_slot"] = 6
	var d3: Dictionary = RESOLVER.resolve_drop(draft_ctx)
	ok = _expect(d3.get("kind", &"") == RESOLVER.DECISION_MOVE_RACK_TO_DRAFT, "draft should win when valid draft target exists") and ok

	# Add-to-meld precedence over draft when committed meld hit exists.
	var meld_ctx: Dictionary = draft_ctx.duplicate(true)
	meld_ctx["committed_meld_hit"] = true
	meld_ctx["committed_meld_index"] = 4
	var d4: Dictionary = RESOLVER.resolve_drop(meld_ctx)
	ok = _expect(d4.get("kind", &"") == RESOLVER.DECISION_ADD_TO_COMMITTED_MELD, "add_to_committed_meld should win over draft") and ok

	if ok:
		print("  PASS  test_interaction_resolver")
	else:
		print("  FAIL  test_interaction_resolver")
	return ok

func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
