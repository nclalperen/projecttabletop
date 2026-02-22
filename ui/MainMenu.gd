extends Control

@onready var _banner: Node = $StatusBanner
@onready var _start_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/StartButton
@onready var _buttons_box: VBoxContainer = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons
@onready var _settings_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/SettingsButton
@onready var _quit_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var _menu_card: PanelContainer = $CenterContainer/MenuCard
@onready var _settings_summary: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/SettingsSummary

const SETTINGS_MENU_SCENE: PackedScene = preload("res://ui/SettingsMenu.tscn")
const ONLINE_LOBBY_SCENE: PackedScene = preload("res://ui/OnlineLobby.tscn")
const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")

# Game configuration
var player_count: int = 4
var game_seed: int = -1  # -1 means random
var rule_config: RuleConfig = null
var _animations_enabled: bool = true
var presentation_mode: String = "3d" # "2d" | "3d"
var _online_button: Button = null

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_ensure_online_button()

	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Welcome to Okey 101!")

	# Initialize default config
	rule_config = RuleConfig.new()
	_refresh_settings_summary()
	_bind_button_feedback()
	_animate_menu_in()

func _animate_menu_in() -> void:
	if not _animations_enabled or _menu_card == null:
		return
	_menu_card.modulate = Color(1, 1, 1, 0)
	_menu_card.position.y += 24
	var tween = create_tween()
	tween.tween_property(_menu_card, "modulate", Color(1, 1, 1, 1), 0.25)
	tween.parallel().tween_property(_menu_card, "position:y", _menu_card.position.y - 24, 0.25)

func _bind_button_feedback() -> void:
	var buttons = [_start_button, _online_button, _settings_button, _quit_button]
	for b in buttons:
		if b == null:
			continue
		b.button_down.connect(func(): b.scale = Vector2(1.05, 1.05))
		b.button_up.connect(func(): b.scale = Vector2(1, 1))

func _on_start_pressed() -> void:
	# Generate random seed if not set
	var actual_seed: int = game_seed if game_seed >= 0 else randi()

	# Load GameTable scene and pass configuration
	var scene_path: String = "res://ui/GameTable3D.tscn" if presentation_mode == "3d" else "res://ui/GameTable.tscn"
	var launched_mode: String = presentation_mode
	var game_table_scene: PackedScene = load(scene_path)
	if game_table_scene == null and presentation_mode == "3d":
		scene_path = "res://ui/GameTable.tscn"
		launched_mode = "2d"
		game_table_scene = load(scene_path)
	if game_table_scene == null:
		if _banner != null and _banner.has_method("set_text"):
			_banner.call("set_text", "Failed to load game scene")
		return
	var game_table: Node = game_table_scene.instantiate()

	# Set game configuration if GameTable has methods for it
	if game_table.has_method("configure_game"):
		game_table.configure_game(rule_config, actual_seed, player_count)
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Starting %s mode (%s players, %s seed)" % [_presentation_label_from(launched_mode), player_count, "random" if game_seed < 0 else str(game_seed)])

	# Switch to game scene
	if _animations_enabled:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(func():
			get_tree().root.add_child(game_table)
			queue_free()
		)
	else:
		get_tree().root.add_child(game_table)
		queue_free()

func _on_settings_pressed() -> void:
	var settings_menu = SETTINGS_MENU_SCENE.instantiate()
	add_child(settings_menu)
	settings_menu.set_config(rule_config)
	settings_menu.settings_changed.connect(_on_settings_changed)

func _on_online_pressed() -> void:
	var online_lobby: Node = ONLINE_LOBBY_SCENE.instantiate()
	if online_lobby.has_method("set_start_config"):
		online_lobby.call("set_start_config", rule_config, game_seed, player_count, presentation_mode)
	if _animations_enabled:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(func():
			get_tree().root.add_child(online_lobby)
			queue_free()
		)
	else:
		get_tree().root.add_child(online_lobby)
		queue_free()

func _on_settings_changed(new_config: RuleConfig):
	rule_config = new_config
	_refresh_settings_summary()
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Settings updated!")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _refresh_settings_summary() -> void:
	if _settings_summary == null:
		return
	var seed_text = "Random" if game_seed < 0 else str(game_seed)
	_settings_summary.text = "101-Okey | %s | %s players | Seed: %s" % [rule_config.preset_name, player_count, seed_text]

func _presentation_label_from(mode: String) -> String:
	return "3D" if mode == "3d" else "2D"

func _ensure_online_button() -> void:
	if _buttons_box == null:
		return
	if _online_button == null:
		_online_button = Button.new()
		_online_button.name = "OnlineButton"
		_online_button.text = "Online (EOS)"
		_online_button.custom_minimum_size = Vector2(0.0, 48.0)
		_buttons_box.add_child(_online_button)
		_buttons_box.move_child(_online_button, 1)
		_online_button.pressed.connect(_on_online_pressed)
	var online_service = ONLINE_SERVICE_SCRIPT.new()
	var init_res: Dictionary = online_service.initialize()
	online_service.free()
	var available: bool = bool(init_res.get("ok", false))
	_online_button.disabled = not available
	if not available:
		_online_button.tooltip_text = String(init_res.get("reason", "Online unavailable"))
	else:
		_online_button.tooltip_text = "Backend: %s" % String(init_res.get("backend_mode", "mock"))
