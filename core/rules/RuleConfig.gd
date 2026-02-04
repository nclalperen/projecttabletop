extends Resource
class_name RuleConfig

@export var preset_name: String = "canonical_101"

@export var tiles_per_player: int = 21
@export var starter_tiles: int = 22
@export var open_min_points_initial: int = 101
@export var allow_open_by_five_pairs: bool = true
@export var open_by_pairs_locks_to_pairs: bool = true

@export var require_discard_take_to_be_used: bool = true
@export var if_not_opened_discard_take_requires_open_and_includes_tile: bool = true
@export var discard_take_must_be_used_always: bool = true

# Behavior for when the indicator reveals a fake okey tile.
# - "redraw": reveal a new indicator
# - "risk_mode": allow play to continue with fake okey as indicator
@export var indicator_fake_joker_behavior: String = "redraw"  # "redraw" | "risk_mode"

# Turn timer in seconds (0 disables timer)
@export var timer_seconds: int = 45  # 0..180

# Match ending rules
@export var match_end_mode: String = "rounds"  # "rounds" | "target_score"
@export var match_end_value: int = 7

# Scoring and penalties (canonical rules)
@export var scoring_full_rules: bool = true
@export var penalty_value: int = 101
@export var penalty_discard_joker: bool = true
@export var penalty_discard_extendable_tile: bool = true
@export var penalty_failed_opening: bool = true
@export var penalty_illegal_manipulation: bool = true
@export var penalty_joker_in_hand_when_no_winner: bool = true
@export var cancel_round_if_all_pairs_open: bool = true

func to_dict() -> Dictionary:
	return {
		"preset_name": preset_name,
		"tiles_per_player": tiles_per_player,
		"starter_tiles": starter_tiles,
		"open_min_points_initial": open_min_points_initial,
		"allow_open_by_five_pairs": allow_open_by_five_pairs,
		"open_by_pairs_locks_to_pairs": open_by_pairs_locks_to_pairs,
		"require_discard_take_to_be_used": require_discard_take_to_be_used,
		"if_not_opened_discard_take_requires_open_and_includes_tile": if_not_opened_discard_take_requires_open_and_includes_tile,
		"discard_take_must_be_used_always": discard_take_must_be_used_always,
		"indicator_fake_joker_behavior": indicator_fake_joker_behavior,
		"timer_seconds": timer_seconds,
		"match_end_mode": match_end_mode,
		"match_end_value": match_end_value,
		"scoring_full_rules": scoring_full_rules,
		"penalty_value": penalty_value,
		"penalty_discard_joker": penalty_discard_joker,
		"penalty_discard_extendable_tile": penalty_discard_extendable_tile,
		"penalty_failed_opening": penalty_failed_opening,
		"penalty_illegal_manipulation": penalty_illegal_manipulation,
		"penalty_joker_in_hand_when_no_winner": penalty_joker_in_hand_when_no_winner,
		"cancel_round_if_all_pairs_open": cancel_round_if_all_pairs_open,
	}

static func from_dict(data: Dictionary) -> RuleConfig:
	var cfg = RuleConfig.new()
	if data.has("preset_name"):
		cfg.preset_name = data["preset_name"]
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
	if data.has("require_discard_take_to_be_used"):
		cfg.require_discard_take_to_be_used = bool(data["require_discard_take_to_be_used"])
	if data.has("if_not_opened_discard_take_requires_open_and_includes_tile"):
		cfg.if_not_opened_discard_take_requires_open_and_includes_tile = bool(data["if_not_opened_discard_take_requires_open_and_includes_tile"])
	if data.has("discard_take_must_be_used_always"):
		cfg.discard_take_must_be_used_always = bool(data["discard_take_must_be_used_always"])
	if data.has("indicator_fake_joker_behavior"):
		cfg.indicator_fake_joker_behavior = String(data["indicator_fake_joker_behavior"])
	if data.has("timer_seconds"):
		cfg.timer_seconds = int(data["timer_seconds"])
	if data.has("match_end_mode"):
		cfg.match_end_mode = String(data["match_end_mode"])
	if data.has("match_end_value"):
		cfg.match_end_value = int(data["match_end_value"])
	if data.has("scoring_full_rules"):
		cfg.scoring_full_rules = bool(data["scoring_full_rules"])
	if data.has("penalty_value"):
		cfg.penalty_value = int(data["penalty_value"])
	if data.has("penalty_discard_joker"):
		cfg.penalty_discard_joker = bool(data["penalty_discard_joker"])
	if data.has("penalty_discard_extendable_tile"):
		cfg.penalty_discard_extendable_tile = bool(data["penalty_discard_extendable_tile"])
	if data.has("penalty_failed_opening"):
		cfg.penalty_failed_opening = bool(data["penalty_failed_opening"])
	if data.has("penalty_illegal_manipulation"):
		cfg.penalty_illegal_manipulation = bool(data["penalty_illegal_manipulation"])
	if data.has("penalty_joker_in_hand_when_no_winner"):
		cfg.penalty_joker_in_hand_when_no_winner = bool(data["penalty_joker_in_hand_when_no_winner"])
	if data.has("cancel_round_if_all_pairs_open"):
		cfg.cancel_round_if_all_pairs_open = bool(data["cancel_round_if_all_pairs_open"])

	return cfg


