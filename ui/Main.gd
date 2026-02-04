extends Node

@onready var _main_menu_scene: PackedScene = preload("res://ui/MainMenu.tscn")

func _ready() -> void:
	var version := ProjectSettings.get_setting("application/config/version", "0.0.0")
	var build := ProjectSettings.get_setting("application/config/build", "dev")
	var engine := Engine.get_version_info()
	print("Game Version: %s | Build: %s | Godot %s.%s.%s" % [version, build, engine.major, engine.minor, engine.patch])

	var main_menu := _main_menu_scene.instantiate()
	add_child(main_menu)

