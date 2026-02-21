extends Resource
class_name RuleConfig

@export var preset_name: String = "seokey11"
@export var ruleset_name: String = "tr_101_classic"

@export var tiles_per_player: int = 21
@export var starter_tiles: int = 22
@export var open_min_points_initial: int = 101
@export var allow_open_by_five_pairs: bool = true
@export var open_by_pairs_locks_to_pairs: bool = true
@export var one_turn_finish_ignores_101: bool = false
@export var allow_joker_reclaim_after_open: bool = true
@export var enable_devam: bool = false
@export var cancel_deal_if_all_open_doubles: bool = false

@export var require_discard_take_to_be_used: bool = true
@export var if_not_opened_discard_take_requires_open_and_includes_tile: bool = true
@export var discard_take_must_be_used_always: bool = true
@export var end_on_stock_empty: String = "score_no_winner" # "score_no_winner" | "redeal" | "platform_default"

# - "redraw": reveal a new indicator
# - "risk_mode": allow play to continue if indicator is fake okey
@export var indicator_fake_joker_behavior: String = "redraw" # "redraw" | "risk_mode"

@export var penalty_value: int = 101
@export var unopened_penalty: int = 202
@export var joker_hand_value: int = 101
@export var pairs_okey_unopened_penalty: int = 404
@export var unopened_gets_extra_joker_penalty: bool = false
@export var penalty_discard_joker: bool = true
@export var penalty_discard_playable_tile: bool = true
@export var penalty_failed_open_attempt: bool = true
@export var penalty_illegal_takeback: bool = true

# Turn timer in seconds (0 disables timer)
@export var timer_seconds: int = 45 # 0..180

# Match ending rules
@export var match_end_mode: String = "rounds" # "rounds" | "target_score"
@export var match_end_value: int = 7

func to_dict() -> Dictionary:
	return {
		"preset_name": preset_name,
		"ruleset_name": ruleset_name,
		"tiles_per_player": tiles_per_player,
		"starter_tiles": starter_tiles,
		"open_min_points_initial": open_min_points_initial,
		"allow_open_by_five_pairs": allow_open_by_five_pairs,
		"open_by_pairs_locks_to_pairs": open_by_pairs_locks_to_pairs,
		"one_turn_finish_ignores_101": one_turn_finish_ignores_101,
		"allow_joker_reclaim_after_open": allow_joker_reclaim_after_open,
		"enable_devam": enable_devam,
		"cancel_deal_if_all_open_doubles": cancel_deal_if_all_open_doubles,
		"require_discard_take_to_be_used": require_discard_take_to_be_used,
		"if_not_opened_discard_take_requires_open_and_includes_tile": if_not_opened_discard_take_requires_open_and_includes_tile,
		"discard_take_must_be_used_always": discard_take_must_be_used_always,
		"end_on_stock_empty": end_on_stock_empty,
		"indicator_fake_joker_behavior": indicator_fake_joker_behavior,
		"penalty_value": penalty_value,
		"unopened_penalty": unopened_penalty,
		"joker_hand_value": joker_hand_value,
		"pairs_okey_unopened_penalty": pairs_okey_unopened_penalty,
		"unopened_gets_extra_joker_penalty": unopened_gets_extra_joker_penalty,
		"penalty_discard_joker": penalty_discard_joker,
		"penalty_discard_playable_tile": penalty_discard_playable_tile,
		"penalty_failed_open_attempt": penalty_failed_open_attempt,
		"penalty_illegal_takeback": penalty_illegal_takeback,
		"timer_seconds": timer_seconds,
		"match_end_mode": match_end_mode,
		"match_end_value": match_end_value,
	}

static func from_dict(data: Dictionary) -> RuleConfig:
	var cfg = RuleConfig.new()
	if data.has("preset_name"):
		cfg.preset_name = String(data["preset_name"])
	if data.has("ruleset_name"):
		cfg.ruleset_name = String(data["ruleset_name"])
	elif data.has("ruleset"):
		cfg.ruleset_name = String(data["ruleset"])
	else:
		cfg.ruleset_name = cfg.preset_name
	if data.has("tiles_per_player"):
		cfg.tiles_per_player = int(data["tiles_per_player"])
	if data.has("starter_tiles"):
		cfg.starter_tiles = int(data["starter_tiles"])
	if data.has("open_min_points_initial"):
		cfg.open_min_points_initial = int(data["open_min_points_initial"])
	if data.has("allow_open_by_five_pairs"):
		cfg.allow_open_by_five_pairs = bool(data["allow_open_by_five_pairs"])
	if data.has("open_by_pairs_locks_to_pairs"):
		cfg.open_by_pairs_locks_to_pairs = bool(data["open_by_pairs_locks_to_pairs"])
	if data.has("one_turn_finish_ignores_101"):
		cfg.one_turn_finish_ignores_101 = bool(data["one_turn_finish_ignores_101"])
	elif data.has("opening") and data["opening"] is Dictionary:
		var opening: Dictionary = data["opening"]
		cfg.one_turn_finish_ignores_101 = bool(opening.get("one_turn_finish_ignores_101", cfg.one_turn_finish_ignores_101))
	if data.has("allow_joker_reclaim_after_open"):
		cfg.allow_joker_reclaim_after_open = bool(data["allow_joker_reclaim_after_open"])
	elif data.has("allow_joker_reclaim"):
		cfg.allow_joker_reclaim_after_open = bool(data["allow_joker_reclaim"])
	if data.has("enable_devam"):
		cfg.enable_devam = bool(data["enable_devam"])
	elif data.has("devam_enabled"):
		cfg.enable_devam = bool(data["devam_enabled"])
	if data.has("cancel_deal_if_all_open_doubles"):
		cfg.cancel_deal_if_all_open_doubles = bool(data["cancel_deal_if_all_open_doubles"])
	elif data.has("all_players_open_pairs_aborts_hand"):
		cfg.cancel_deal_if_all_open_doubles = bool(data["all_players_open_pairs_aborts_hand"])
	elif data.has("cancel_round_if_all_pairs_open"):
		cfg.cancel_deal_if_all_open_doubles = bool(data["cancel_round_if_all_pairs_open"])
	if data.has("require_discard_take_to_be_used"):
		cfg.require_discard_take_to_be_used = bool(data["require_discard_take_to_be_used"])
	if data.has("if_not_opened_discard_take_requires_open_and_includes_tile"):
		cfg.if_not_opened_discard_take_requires_open_and_includes_tile = bool(data["if_not_opened_discard_take_requires_open_and_includes_tile"])
	if data.has("discard_take_must_be_used_always"):
		cfg.discard_take_must_be_used_always = bool(data["discard_take_must_be_used_always"])
	if data.has("end_on_stock_empty"):
		cfg.end_on_stock_empty = String(data["end_on_stock_empty"])
	elif data.has("stock_exhaustion_ends_hand"):
		cfg.end_on_stock_empty = "score_no_winner" if bool(data["stock_exhaustion_ends_hand"]) else "redeal"
	elif data.has("end_conditions") and data["end_conditions"] is Dictionary:
		var end_conditions: Dictionary = data["end_conditions"]
		if end_conditions.has("stock_exhaustion_ends_hand"):
			cfg.end_on_stock_empty = "score_no_winner" if bool(end_conditions["stock_exhaustion_ends_hand"]) else "redeal"
	if data.has("indicator_fake_joker_behavior"):
		cfg.indicator_fake_joker_behavior = String(data["indicator_fake_joker_behavior"])
	if data.has("penalty_value"):
		cfg.penalty_value = int(data["penalty_value"])
	elif data.has("infractions") and data["infractions"] is Dictionary:
		var infractions: Dictionary = data["infractions"]
		cfg.penalty_value = int(infractions.get("invalid_open_penalty", cfg.penalty_value))
	if data.has("unopened_penalty"):
		cfg.unopened_penalty = int(data["unopened_penalty"])
	elif data.has("penalty_unopened"):
		cfg.unopened_penalty = int(data["penalty_unopened"])
	if data.has("joker_hand_value"):
		cfg.joker_hand_value = int(data["joker_hand_value"])
	elif data.has("joker_tile_unplayed_value"):
		cfg.joker_hand_value = int(data["joker_tile_unplayed_value"])
	if data.has("pairs_okey_unopened_penalty"):
		cfg.pairs_okey_unopened_penalty = int(data["pairs_okey_unopened_penalty"])
	elif data.has("cap_unopened_penalty_when_pairs_and_okey") and data["cap_unopened_penalty_when_pairs_and_okey"] != null:
		cfg.pairs_okey_unopened_penalty = int(data["cap_unopened_penalty_when_pairs_and_okey"])
	if data.has("unopened_gets_extra_joker_penalty"):
		cfg.unopened_gets_extra_joker_penalty = bool(data["unopened_gets_extra_joker_penalty"])
	if data.has("penalty_discard_joker"):
		cfg.penalty_discard_joker = bool(data["penalty_discard_joker"])
	elif data.has("penalties") and data["penalties"] is Dictionary:
		var penalties: Dictionary = data["penalties"]
		cfg.penalty_discard_joker = bool(penalties.get("discarding_joker", cfg.penalty_discard_joker))
	if data.has("penalty_discard_playable_tile"):
		cfg.penalty_discard_playable_tile = bool(data["penalty_discard_playable_tile"])
	elif data.has("penalties") and data["penalties"] is Dictionary:
		var penalties2: Dictionary = data["penalties"]
		cfg.penalty_discard_playable_tile = bool(penalties2.get("discarding_playable_tile", cfg.penalty_discard_playable_tile))
	if data.has("penalty_failed_open_attempt"):
		cfg.penalty_failed_open_attempt = bool(data["penalty_failed_open_attempt"])
	elif data.has("penalties") and data["penalties"] is Dictionary:
		var penalties3: Dictionary = data["penalties"]
		cfg.penalty_failed_open_attempt = bool(penalties3.get("failed_open_attempt", cfg.penalty_failed_open_attempt))
	if data.has("penalty_illegal_takeback"):
		cfg.penalty_illegal_takeback = bool(data["penalty_illegal_takeback"])
	elif data.has("penalties") and data["penalties"] is Dictionary:
		var penalties4: Dictionary = data["penalties"]
		cfg.penalty_illegal_takeback = bool(penalties4.get("illegal_takeback", cfg.penalty_illegal_takeback))
	if data.has("timer_seconds"):
		cfg.timer_seconds = int(data["timer_seconds"])
	if data.has("match_end_mode"):
		cfg.match_end_mode = String(data["match_end_mode"])
	if data.has("match_end_value"):
		cfg.match_end_value = int(data["match_end_value"])

	return cfg
