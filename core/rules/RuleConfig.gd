extends Resource
class_name RuleConfig

@export var preset_name: String = "seokey11"

@export var tiles_per_player: int = 21
@export var starter_tiles: int = 22
@export var open_min_points_initial: int = 101
@export var allow_open_by_five_pairs: bool = true
@export var open_by_pairs_locks_to_pairs: bool = true

@export var require_discard_take_to_be_used: bool = true
@export var if_not_opened_discard_take_requires_open_and_includes_tile: bool = true
@export var discard_take_must_be_used_always: bool = true

# - "redraw": reveal a new indicator
# - "risk_mode": allow play to continue if indicator is fake okey
@export var indicator_fake_joker_behavior: String = "redraw" # "redraw" | "risk_mode"

# Turn timer in seconds (0 disables timer)
@export var timer_seconds: int = 45 # 0..180

# Match ending rules
@export var match_end_mode: String = "rounds" # "rounds" | "target_score"
@export var match_end_value: int = 7

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
	}

static func from_dict(data: Dictionary) -> RuleConfig:
	var cfg = RuleConfig.new()
	if data.has("preset_name"):
		cfg.preset_name = String(data["preset_name"])
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

	return cfg
