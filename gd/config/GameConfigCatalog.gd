extends RefCounted
class_name GameConfigCatalog

const IDS: Script = preload("res://gd/config/GameConfigIds.gd")

static var _values: Dictionary = {
	IDS.TURN_TIMER_DEFAULT: 45,
	IDS.PLAYER_COUNT_DEFAULT: 4,
}

static func value_for(id: StringName, fallback = null):
	return _values.get(id, fallback)
