extends Control

class_name SettingsMenu

signal settings_changed(new_config)
signal cancelled

@onready var initial_open_points = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/InitialOpenPoints/Value
@onready var allow_five_pairs_open = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/AllowFivePairsOpen/Value
@onready var turn_timer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/TurnTimer/Value
@onready var match_end_condition = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndCondition/Value
@onready var match_end_value = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndValue/Value

@onready var save_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SaveButton
@onready var cancel_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

var _config: RuleConfig

func _ready():
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	match_end_condition.add_item("Rounds", 0)
	match_end_condition.add_item("Target Score", 1)

func set_config(config: RuleConfig):
	_config = config
	load_config()

func load_config():
	if not _config:
		return
	
	initial_open_points.value = _config.open_min_points_initial
	allow_five_pairs_open.button_pressed = _config.allow_open_by_five_pairs
	turn_timer.value = _config.timer_seconds
	
	if _config.match_end_mode == "rounds":
		match_end_condition.select(0)
	else:
		match_end_condition.select(1)
	
	match_end_value.value = _config.match_end_value

func save_config():
	if not _config:
		return
	
	_config.open_min_points_initial = initial_open_points.value
	_config.allow_open_by_five_pairs = allow_five_pairs_open.button_pressed
	_config.timer_seconds = turn_timer.value
	
	if match_end_condition.selected == 0:
		_config.match_end_mode = "rounds"
	else:
		_config.match_end_mode = "target_score"
		
	_config.match_end_value = match_end_value.value

func _on_save_pressed():
	save_config()
	emit_signal("settings_changed", _config)
	queue_free()

func _on_cancel_pressed():
	emit_signal("cancelled")
	queue_free()
