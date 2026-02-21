extends RefCounted
class_name Action

enum ActionType {
	STARTER_DISCARD,
	DRAW_FROM_DECK,
	TAKE_DISCARD,
	PLACE_TILES,
	OPEN_MELDS,
	ADD_TO_MELD,
	END_PLAY,
	DISCARD,
	FINISH
}

var type: int
var payload: Dictionary = {}

func _init(p_type: int = ActionType.DRAW_FROM_DECK, p_payload: Dictionary = {}) -> void:
	type = p_type
	payload = p_payload

