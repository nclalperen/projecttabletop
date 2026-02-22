extends RefCounted
class_name GameConfigRegistry

const CATALOG: Script = preload("res://gd/config/GameConfigCatalog.gd")
const IDS: Script = preload("res://gd/config/GameConfigIds.gd")

static func default_turn_timer_seconds() -> int:
	return int(CATALOG.value_for(IDS.TURN_TIMER_DEFAULT, 45))

static func default_player_count() -> int:
	return int(CATALOG.value_for(IDS.PLAYER_COUNT_DEFAULT, 4))
