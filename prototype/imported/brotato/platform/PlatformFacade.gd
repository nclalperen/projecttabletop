extends Node

const PROVIDER_LOCAL: Script = preload("res://prototype/imported/brotato/platform/PlatformProviderLocal.gd")

var _provider: Node = null


func _ready() -> void:
	_select_provider()


func _select_provider() -> void:
	# Prototype-safe provider routing. Extend with Steam/Epic/GOG providers later.
	_provider = PROVIDER_LOCAL.new()
	add_child(_provider)


func get_type() -> String:
	return _provider.call("get_type")


func get_user_id() -> String:
	return _provider.call("get_user_id")


func get_language() -> String:
	return _provider.call("get_language")


func is_dlc_owned(dlc_id: String) -> bool:
	return bool(_provider.call("is_dlc_owned", dlc_id))

