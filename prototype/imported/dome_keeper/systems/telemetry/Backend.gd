extends RefCounted

class_name ImportedTelemetryBackend

var base_url: String = ""
var session_id: String = ""
var enabled: bool = false


func configure(url: String, sid: String, is_enabled: bool) -> void:
	base_url = url.strip_edges()
	session_id = sid.strip_edges()
	enabled = is_enabled and base_url != "" and session_id != ""


func can_send() -> bool:
	return enabled

