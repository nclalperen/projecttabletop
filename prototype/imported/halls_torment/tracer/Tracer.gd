extends RefCounted

class_name ImportedTracer

enum Level {
	DEBUG,
	INFO,
	WARN,
	ERROR,
}

var min_level: int = Level.INFO
var prefix: String = "ImportedTracer"


func trace(level: int, message: String, data: Dictionary = {}) -> void:
	if level < min_level:
		return
	var level_text: String = _level_to_text(level)
	var suffix: String = ""
	if not data.is_empty():
		suffix = " | " + JSON.stringify(data)
	print("[%s] %s: %s%s" % [prefix, level_text, message, suffix])


func debug(message: String, data: Dictionary = {}) -> void:
	trace(Level.DEBUG, message, data)


func info(message: String, data: Dictionary = {}) -> void:
	trace(Level.INFO, message, data)


func warn(message: String, data: Dictionary = {}) -> void:
	trace(Level.WARN, message, data)


func error(message: String, data: Dictionary = {}) -> void:
	trace(Level.ERROR, message, data)


func _level_to_text(level: int) -> String:
	match level:
		Level.DEBUG:
			return "DEBUG"
		Level.INFO:
			return "INFO"
		Level.WARN:
			return "WARN"
		Level.ERROR:
			return "ERROR"
		_:
			return "UNKNOWN"
