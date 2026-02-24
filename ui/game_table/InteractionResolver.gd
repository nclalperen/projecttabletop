class_name InteractionResolver
extends RefCounted

const DECISION_NO_OP: StringName = &"no_op"
const DECISION_DISCARD: StringName = &"discard"
const DECISION_END_PLAY_THEN_DISCARD: StringName = &"end_play_then_discard"
const DECISION_ADD_TO_COMMITTED_MELD: StringName = &"add_to_committed_meld"
const DECISION_MOVE_RACK_TO_DRAFT: StringName = &"move_rack_to_draft"
const DECISION_MOVE_DRAFT_SLOT: StringName = &"move_draft_slot"
const DECISION_MOVE_RACK_SLOT: StringName = &"move_rack_slot"
const DECISION_MOVE_DRAFT_TO_RACK: StringName = &"move_draft_to_rack"

static func resolve_drop(ctx: Dictionary) -> Dictionary:
	if not bool(ctx.get("is_my_turn", false)):
		return _no_op("not_my_turn")

	var phase: int = int(ctx.get("phase", -1))
	var tile_id: int = int(ctx.get("tile_id", -1))
	var from_rack_slot: int = int(ctx.get("from_rack_slot", -1))
	var from_draft_slot: int = int(ctx.get("from_draft_slot", -1))
	var from_has_source: bool = from_rack_slot != -1 or from_draft_slot != -1
	if not from_has_source:
		return _no_op("missing_source")

	# 1) Discard has highest precedence and only from rack source.
	if from_rack_slot != -1 and bool(ctx.get("discard_intent", false)):
		if phase == GameState.Phase.STARTER_DISCARD or phase == GameState.Phase.TURN_DISCARD:
			return {"kind": DECISION_DISCARD, "tile_id": tile_id}
		if phase == GameState.Phase.TURN_PLAY and bool(ctx.get("allow_end_play_then_discard", true)):
			return {"kind": DECISION_END_PLAY_THEN_DISCARD, "tile_id": tile_id}

	# 2) Add to committed meld.
	var committed_meld_index: int = int(ctx.get("committed_meld_index", -1))
	if phase == GameState.Phase.TURN_PLAY \
		and bool(ctx.get("committed_meld_hit", false)) \
		and committed_meld_index != -1:
		return {
			"kind": DECISION_ADD_TO_COMMITTED_MELD,
			"tile_id": tile_id,
			"meld_index": committed_meld_index,
		}

	# 3) Draft interactions.
	var draft_target_slot: int = int(ctx.get("draft_target_slot", -1))
	if phase == GameState.Phase.TURN_PLAY \
		and bool(ctx.get("draft_lane_intent", false)) \
		and draft_target_slot != -1:
		if from_rack_slot != -1:
			return {
				"kind": DECISION_MOVE_RACK_TO_DRAFT,
				"from_slot": from_rack_slot,
				"to_draft_slot": draft_target_slot,
				"tile_id": tile_id,
			}
		if from_draft_slot != -1 and from_draft_slot != draft_target_slot:
			return {
				"kind": DECISION_MOVE_DRAFT_SLOT,
				"from_draft_slot": from_draft_slot,
				"to_draft_slot": draft_target_slot,
				"tile_id": tile_id,
			}

	# 4) Rack interactions.
	var rack_target_slot: int = int(ctx.get("rack_target_slot", -1))
	if bool(ctx.get("rack_intent", false)) and rack_target_slot != -1:
		if from_rack_slot != -1 and bool(ctx.get("allow_rack_reorder", true)) and rack_target_slot != from_rack_slot:
			return {
				"kind": DECISION_MOVE_RACK_SLOT,
				"from_slot": from_rack_slot,
				"to_slot": rack_target_slot,
				"tile_id": tile_id,
			}
		if from_draft_slot != -1:
			return {
				"kind": DECISION_MOVE_DRAFT_TO_RACK,
				"from_draft_slot": from_draft_slot,
				"to_slot": rack_target_slot,
				"tile_id": tile_id,
			}

	return _no_op("no_matching_intent")

static func _no_op(reason: String) -> Dictionary:
	return {"kind": DECISION_NO_OP, "reason": reason}
