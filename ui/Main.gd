extends Control

const PLAYER_PROFILE: Script = preload("res://ui/services/PlayerProfile.gd")

@onready var _main_menu_scene: PackedScene = preload("res://ui/MainMenu.tscn")

func _ready() -> void:
	var version: String = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	var build: String = str(ProjectSettings.get_setting("application/config/build", "dev"))
	var engine: Dictionary = Engine.get_version_info()
	print("Game Version: %s | Build: %s | Godot %s.%s.%s" % [version, build, engine.major, engine.minor, engine.patch])

	PLAYER_PROFILE.ensure_loaded()

	var main_menu: Node = _main_menu_scene.instantiate()
	add_child(main_menu)
