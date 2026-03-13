extends RefCounted

class_name ImportedTelemetryEvent

var name: String = ""
var payload: Dictionary = {}
var ts_unix: int = 0


func _init(event_name: String = "", event_payload: Dictionary = {}) -> void:
	name = event_name
	payload = event_payload.duplicate(true)
	ts_unix = Time.get_unix_time_from_system()


func as_dict() -> Dictionary:
	return {
		"name": name,
		"payload": payload.duplicate(true),
		"ts_unix": ts_unix,
	}

