extends Node

class_name ImportedPlatformProviderBase


func get_type() -> String:
	return "base"


func get_user_id() -> String:
	return "local_user"


func get_language() -> String:
	return TranslationServer.get_locale()


func is_dlc_owned(_dlc_id: String) -> bool:
	return false

