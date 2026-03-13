extends RefCounted
class_name TabletopGameCatalog

const GAME_POKER: StringName = &"poker"
const GAME_BLACKJACK: StringName = &"blackjack"
const GAME_BACKGAMMON: StringName = &"backgammon"
const GAME_CHESS: StringName = &"chess"
const GAME_OKEY_101: StringName = &"okey101"

const FLOW_PLACEHOLDER: StringName = &"placeholder"
const FLOW_OKEY: StringName = &"okey"

static var _games: Dictionary = {
	GAME_POKER: {
		"id": GAME_POKER,
		"name": "Poker",
		"subtitle": "Texas Hold'em table",
		"description": "Blinds, dealer rotation, community cards, and showdown support are next. The multiplayer room flow is wired now.",
		"player_counts": [2, 4, 6],
		"default_players": 6,
		"ruleset_id": "tabletop_poker_holdem",
		"chip_copy": "Prototype Table",
		"flow": FLOW_PLACEHOLDER,
	},
	GAME_BLACKJACK: {
		"id": GAME_BLACKJACK,
		"name": "Blackjack",
		"subtitle": "Shared dealer table",
		"description": "Multiplayer seating, table setup, and match launch are in place. Turn handling, dealer logic, and betting are still to come.",
		"player_counts": [2, 3, 4],
		"default_players": 4,
		"ruleset_id": "tabletop_blackjack_classic",
		"chip_copy": "Prototype Table",
		"flow": FLOW_PLACEHOLDER,
	},
	GAME_BACKGAMMON: {
		"id": GAME_BACKGAMMON,
		"name": "Backgammon",
		"subtitle": "Head-to-head race board",
		"description": "Two-seat multiplayer tables are available now. Checker movement, dice resolution, and doubling cube rules will land in the next pass.",
		"player_counts": [2],
		"default_players": 2,
		"ruleset_id": "tabletop_backgammon_standard",
		"chip_copy": "Prototype Table",
		"flow": FLOW_PLACEHOLDER,
	},
	GAME_CHESS: {
		"id": GAME_CHESS,
		"name": "Chess",
		"subtitle": "Classic two-player board",
		"description": "The multiplayer room, seating, and launch flow are ready. Piece movement, clocks, and move validation are still pending.",
		"player_counts": [2],
		"default_players": 2,
		"ruleset_id": "tabletop_chess_classic",
		"chip_copy": "Prototype Table",
		"flow": FLOW_PLACEHOLDER,
	},
	GAME_OKEY_101: {
		"id": GAME_OKEY_101,
		"name": "Okey 101",
		"subtitle": "Legacy implemented table",
		"description": "The original rules implementation stays available while the project expands into a broader tabletop platform.",
		"player_counts": [4],
		"default_players": 4,
		"ruleset_id": "tr_101_classic",
		"chip_copy": "Legacy Rules Live",
		"flow": FLOW_OKEY,
	},
}

static func default_game_id() -> StringName:
	return GAME_POKER


static func primary_game_ids() -> Array[StringName]:
	return [GAME_POKER, GAME_BLACKJACK, GAME_BACKGAMMON, GAME_CHESS]


static func all_game_ids() -> Array[StringName]:
	return [GAME_POKER, GAME_BLACKJACK, GAME_BACKGAMMON, GAME_CHESS, GAME_OKEY_101]


static func game(id: StringName) -> Dictionary:
	var normalized: StringName = _normalize_id(id)
	return (_games.get(normalized, _games[default_game_id()]) as Dictionary).duplicate(true)


static func has_game(id: StringName) -> bool:
	return _games.has(_normalize_id(id))


static func display_name(id: StringName) -> String:
	return String(game(id).get("name", "Tabletop"))


static func subtitle(id: StringName) -> String:
	return String(game(id).get("subtitle", "Multiplayer table"))


static func description(id: StringName) -> String:
	return String(game(id).get("description", ""))


static func chip_copy(id: StringName) -> String:
	return String(game(id).get("chip_copy", "Multiplayer"))


static func ruleset_id(id: StringName) -> String:
	return String(game(id).get("ruleset_id", "tabletop_unknown"))


static func default_player_count(id: StringName) -> int:
	return int(game(id).get("default_players", 4))


static func player_counts(id: StringName) -> Array:
	return (game(id).get("player_counts", [4]) as Array).duplicate()


static func supports_player_count(id: StringName, player_count: int) -> bool:
	return player_counts(id).has(player_count)


static func clamp_player_count(id: StringName, player_count: int) -> int:
	var supported: Array = player_counts(id)
	if supported.is_empty():
		return maxi(2, player_count)
	if supported.has(player_count):
		return player_count
	return int(supported[0])


static func player_count_summary(id: StringName) -> String:
	var supported: Array = player_counts(id)
	if supported.is_empty():
		return "Multiplayer"
	if supported.size() == 1:
		return "%d Players" % int(supported[0])
	return "%d-%d Players" % [int(supported[0]), int(supported[supported.size() - 1])]


static func flow(id: StringName) -> StringName:
	return StringName(game(id).get("flow", FLOW_PLACEHOLDER))


static func uses_okey_table(id: StringName) -> bool:
	return flow(id) == FLOW_OKEY


static func launch_scene_path(id: StringName, presentation_mode: String) -> String:
	if _prototype_table_scene_enabled():
		return "res://ui/ImportedTable3D.tscn"
	if uses_okey_table(id):
		return "res://ui/GameTable3D.tscn" if presentation_mode == "3d" else "res://ui/GameTable.tscn"
	return "res://ui/PlaceholderTable.tscn"


static func legacy_label(id: StringName) -> String:
	return "Legacy" if uses_okey_table(id) else "New"


static func _normalize_id(id: StringName) -> StringName:
	var raw: String = String(id).strip_edges().to_lower()
	if raw == "":
		return default_game_id()
	return StringName(raw)


static func _prototype_table_scene_enabled() -> bool:
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return false
	var tree: SceneTree = loop as SceneTree
	if tree.root == null:
		return false
	var flags := tree.root.get_node_or_null("ImportedFeatureFlags")
	if flags == null:
		return false
	if not flags.has_method("is_prototype_table_enabled"):
		return false
	return bool(flags.call("is_prototype_table_enabled"))
