extends RefCounted

var search_range: String = "near"
var lobby_results: Array = []

const RANGE_NEAR: String = "near"
const RANGE_FAR: String = "far"
const RANGE_WORLDWIDE: String = "worldwide"


func set_search_range(value: String) -> void:
	var normalized: String = value.strip_edges().to_lower()
	if normalized in [RANGE_NEAR, RANGE_FAR, RANGE_WORLDWIDE]:
		search_range = normalized


func set_lobby_results(results: Array) -> void:
	lobby_results = results.duplicate(true)


func has_results() -> bool:
	return not lobby_results.is_empty()


func first_open_lobby() -> Dictionary:
	for lobby in lobby_results:
		if typeof(lobby) != TYPE_DICTIONARY:
			continue
		var meta: Dictionary = lobby
		var members: int = int(meta.get("member_count", 0))
		var cap: int = int(meta.get("player_limit", 0))
		if cap <= 0:
			continue
		if members < cap:
			return meta
	return {}

