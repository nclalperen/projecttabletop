extends Control

@onready var _banner: Node = $StatusBanner
@onready var _background: TextureRect = $Background
@onready var _start_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/StartButton
@onready var _buttons_box: VBoxContainer = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons
@onready var _settings_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/SettingsButton
@onready var _quit_button: Button = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var _menu_card: PanelContainer = $CenterContainer/MenuCard
@onready var _settings_summary: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/SettingsSummary
@onready var _players_chip_icon: TextureRect = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/MetaChips/PlayersChipIcon
@onready var _players_chip: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/MetaChips/PlayersChip
@onready var _timer_chip_icon: TextureRect = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/MetaChips/TimerChipIcon
@onready var _timer_chip: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/MetaChips/TimerChip
@onready var _online_chip_icon: TextureRect = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/MetaChips/OnlineChipIcon
@onready var _online_chip: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/MetaChips/OnlineChip

const SETTINGS_MENU_SCENE: PackedScene = preload("res://ui/SettingsMenu.tscn")
const ONLINE_LOBBY_SCENE: PackedScene = preload("res://ui/OnlineLobby.tscn")
const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const MENU_AUDIO_SERVICE_SCRIPT: Script = preload("res://ui/services/MenuAudioService.gd")
const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")
const DISPLAY_SETTINGS_SCRIPT: Script = preload("res://ui/services/DisplaySettingsService.gd")
const PLATFORM_PROFILE_SCRIPT: Script = preload("res://ui/services/PlatformProfile.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const ICON_BUTTON_SCENE: PackedScene = preload("res://ui/widgets/IconTextButton.tscn")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")

const PANEL_BORDER_ID: StringName = ASSET_IDS.UI_PANEL_BORDER_GREY_DETAIL
const PANEL_FILL_ID: StringName = ASSET_IDS.UI_PANEL_GREY_DARK
const PANEL_GRID_ID: StringName = ASSET_IDS.UI_PANEL_PATTERN_DIAGONAL_TRANSPARENT_SMALL
const ICON_START_ID: StringName = ASSET_IDS.UI_ICON_CARD_ADD
const ICON_ONLINE_ID: StringName = ASSET_IDS.UI_ICON_PAWNS
const ICON_SETTINGS_ID: StringName = ASSET_IDS.UI_ICON_GEAR
const ICON_QUIT_ID: StringName = ASSET_IDS.UI_ICON_CROSS
const ICON_TIMER_ID: StringName = ASSET_IDS.UI_ICON_TIMER_100
const ICON_ONLINE_LOCKED_ID: StringName = ASSET_IDS.UI_ICON_LOCK_CLOSED
const ICON_ONLINE_UNLOCKED_ID: StringName = ASSET_IDS.UI_ICON_LOCK_OPEN

# Game configuration
var player_count: int = 4
var game_seed: int = -1  # -1 means random
var rule_config: RuleConfig = null
var _animations_enabled: bool = true
var presentation_mode: String = PLATFORM_PROFILE_SCRIPT.default_presentation_mode() # "2d" | "3d"
var _online_button: Button = null
var _menu_audio = null

func _ready() -> void:
	if _menu_audio == null:
		_menu_audio = MENU_AUDIO_SERVICE_SCRIPT.new()
		_menu_audio.name = "MenuAudioService"
		add_child(_menu_audio)
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	# Initialize default config.
	rule_config = RuleConfig.new()
	var ui_settings: Dictionary = UI_SETTINGS_SCRIPT.load_from_disk()
	_sync_presentation_mode_from_settings(ui_settings)
	_apply_runtime_display_settings(ui_settings)
	_apply_background_pattern()
	_apply_panel_shell()
	_ensure_online_button()
	_apply_kenney_fonts()
	_apply_meta_chip_icons()
	_apply_main_button_icons()
	_apply_responsive_layout()

	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Welcome to Okey 101!")

	_refresh_settings_summary()
	_sync_meta_chips()
	_bind_button_feedback()
	_animate_menu_in()


func _animate_menu_in() -> void:
	if not _animations_enabled or _menu_card == null:
		return
	var menu_in_time: float = _style_scalar(&"motion_menu_in")
	var button_in_time: float = _style_scalar(&"motion_button_in")
	var stagger: float = _style_scalar(&"motion_stagger")
	_menu_card.modulate = Color(1, 1, 1, 0)
	_menu_card.position.y += 18
	var card_tween = create_tween()
	card_tween.tween_property(_menu_card, "modulate", Color(1, 1, 1, 1), menu_in_time)
	card_tween.parallel().tween_property(_menu_card, "position:y", _menu_card.position.y - 18, menu_in_time)

	var buttons: Array = _button_list()
	for i in range(buttons.size()):
		var b: Button = buttons[i]
		if b == null:
			continue
		var original_x: float = b.position.x
		b.modulate = Color(1, 1, 1, 0)
		b.position.x -= 12.0
		var tween = create_tween()
		var delay: float = float(i) * stagger
		tween.tween_property(b, "modulate", Color(1, 1, 1, 1), button_in_time).set_delay(delay)
		tween.parallel().tween_property(b, "position:x", original_x, button_in_time).set_delay(delay)


func _bind_button_feedback() -> void:
	for item in _button_list():
		var b: Button = item
		if b == null:
			continue
		b.mouse_entered.connect(_on_menu_button_hover.bind(b))
		b.button_down.connect(_on_menu_button_down.bind(b))
		b.button_up.connect(_on_menu_button_up.bind(b))


func _on_menu_button_hover(_button: Button) -> void:
	if _menu_audio != null:
		_menu_audio.play_hover()


func _on_menu_button_down(button: Button) -> void:
	if button != null:
		var scale_amount: float = _style_scalar(&"press_scale")
		button.scale = Vector2(scale_amount, scale_amount)


func _on_menu_button_up(button: Button) -> void:
	if button != null:
		button.scale = Vector2.ONE


func _button_list() -> Array:
	return [_start_button, _online_button, _settings_button, _quit_button]


func _apply_main_button_icons() -> void:
	_set_icon_text_button(_start_button, _texture(ICON_START_ID), "Start Game", 0)
	_set_icon_text_button(_settings_button, _texture(ICON_SETTINGS_ID), "Settings", 1)
	_set_icon_text_button(_quit_button, _texture(ICON_QUIT_ID), "Quit", 1)
	if _online_button != null:
		_set_icon_text_button(_online_button, _texture(ICON_ONLINE_ID), "Online (EOS)", 0)


func _set_icon_text_button(button: Button, icon_texture: Texture2D, label_text: String, variant: int = 0) -> void:
	if button == null:
		return
	button.text = label_text
	button.icon = icon_texture
	if _has_property(button, "button_label"):
		button.set("button_label", label_text)
	if _has_property(button, "icon_texture"):
		button.set("icon_texture", icon_texture)
	if _has_property(button, "style_variant"):
		button.set("style_variant", variant)


func _has_property(target: Object, property_name: String) -> bool:
	for entry in target.get_property_list():
		if String(entry.get("name", "")) == property_name:
			return true
	return false


func _texture(id: StringName) -> Texture2D:
	return ASSET_REGISTRY.texture(id)


func _apply_background_pattern() -> void:
	if _background != null:
		_background.texture = _texture(PANEL_GRID_ID)
		_background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_background.stretch_mode = TextureRect.STRETCH_TILE
		_background.modulate = _style_color(&"bg_pattern")


func _apply_panel_shell() -> void:
	if _menu_card == null:
		return
	var panel_margin: float = _style_scalar(&"panel_margin")
	var panel_content_x: float = _style_scalar(&"panel_content_x")
	var panel_content_y: float = _style_scalar(&"panel_content_y")
	var panel_tex: Texture2D = _texture(PANEL_FILL_ID)
	if panel_tex != null:
		var panel_style := StyleBoxTexture.new()
		panel_style.texture = panel_tex
		panel_style.modulate_color = _style_color(&"panel_shell")
		panel_style.texture_margin_left = panel_margin
		panel_style.texture_margin_top = panel_margin
		panel_style.texture_margin_right = panel_margin
		panel_style.texture_margin_bottom = panel_margin
		panel_style.content_margin_left = panel_content_x
		panel_style.content_margin_top = panel_content_y
		panel_style.content_margin_right = panel_content_x
		panel_style.content_margin_bottom = panel_content_y
		_menu_card.add_theme_stylebox_override("panel", panel_style)

	var border_tex: Texture2D = _texture(PANEL_BORDER_ID)
	if border_tex == null:
		return
	var border := _menu_card.get_node_or_null("KenneyBorder") as NinePatchRect
	if border == null:
		border = NinePatchRect.new()
		border.name = "KenneyBorder"
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.draw_center = false
		border.anchor_right = 1.0
		border.anchor_bottom = 1.0
		var border_margin: int = int(round(_style_scalar(&"panel_border_margin")))
		border.patch_margin_left = border_margin
		border.patch_margin_top = border_margin
		border.patch_margin_right = border_margin
		border.patch_margin_bottom = border_margin
		_menu_card.add_child(border)
	border.texture = border_tex
	border.modulate = _style_color(&"panel_border")


func _apply_meta_chip_icons() -> void:
	if _players_chip_icon != null:
		_players_chip_icon.texture = _texture(ICON_ONLINE_ID)
		_players_chip_icon.modulate = _style_color(&"chip_icon")
	if _timer_chip_icon != null:
		_timer_chip_icon.texture = _texture(ICON_TIMER_ID)
		_timer_chip_icon.modulate = _style_color(&"chip_icon")
	_update_online_chip_icon()


func _update_online_chip_icon() -> void:
	if _online_chip_icon == null:
		return
	var locked: bool = _online_button != null and _online_button.disabled
	_online_chip_icon.texture = _texture(ICON_ONLINE_LOCKED_ID if locked else ICON_ONLINE_UNLOCKED_ID)


func _apply_kenney_fonts() -> void:
	var title: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Title
	var subtitle: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Subtitle
	var version: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/Version
	var summary: Label = $CenterContainer/MenuCard/MarginContainer/VBoxContainer/SettingsSummary
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", _style_color(&"title_text"))
	subtitle.add_theme_font_size_override("font_size", 23)
	subtitle.add_theme_color_override("font_color", _style_color(&"subtitle_text"))
	version.add_theme_font_size_override("font_size", 15)
	version.add_theme_color_override("font_color", _style_color(&"muted_text"))
	summary.add_theme_font_size_override("font_size", 17)
	summary.add_theme_color_override("font_color", _style_color(&"body_text"))
	for chip in [_players_chip, _timer_chip, _online_chip]:
		if chip != null:
			chip.add_theme_font_size_override("font_size", 16)
			chip.add_theme_color_override("font_color", _style_color(&"chip_text"))


func _on_start_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	# Generate random seed if not set.
	var actual_seed: int = game_seed if game_seed >= 0 else randi()

	# Load GameTable scene and pass configuration.
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

	if game_table.has_method("configure_game"):
		game_table.configure_game(rule_config, actual_seed, player_count)
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Starting %s mode (%s players, %s seed)" % [_presentation_label_from(launched_mode), player_count, "random" if game_seed < 0 else str(game_seed)])

	if _animations_enabled:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), _style_scalar(&"motion_fade_out"))
		tween.tween_callback(func():
			get_tree().root.add_child(game_table)
			queue_free()
		)
	else:
		get_tree().root.add_child(game_table)
		queue_free()


func _on_settings_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	var settings_menu = SETTINGS_MENU_SCENE.instantiate()
	add_child(settings_menu)
	settings_menu.set_config(rule_config)
	settings_menu.settings_changed.connect(_on_settings_changed)


func _on_online_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	var online_lobby: Node = ONLINE_LOBBY_SCENE.instantiate()
	if online_lobby.has_method("set_start_config"):
		online_lobby.call("set_start_config", rule_config, game_seed, player_count, presentation_mode)
	if _animations_enabled:
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), _style_scalar(&"motion_fade_out"))
		tween.tween_callback(func():
			get_tree().root.add_child(online_lobby)
			queue_free()
		)
	else:
		get_tree().root.add_child(online_lobby)
		queue_free()


func _on_settings_changed(new_config: RuleConfig):
	rule_config = new_config
	_sync_presentation_mode_from_settings()
	_refresh_settings_summary()
	_sync_meta_chips()
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Settings updated!")


func _on_quit_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_back()
	get_tree().quit()


func _refresh_settings_summary() -> void:
	if _settings_summary == null:
		return
	if rule_config == null:
		_settings_summary.text = "Preset: Classic 101"
		return
	var seed_text = "Random" if game_seed < 0 else str(game_seed)
	_settings_summary.text = "Preset: %s  |  %d players  |  Seed: %s" % [rule_config.preset_name, player_count, seed_text]


func _sync_meta_chips() -> void:
	if _players_chip != null:
		_players_chip.text = "%d Players" % player_count
	if _timer_chip != null:
		var timer_val: int = int(rule_config.timer_seconds) if rule_config != null else 45
		_timer_chip.text = "%ds Turn" % timer_val
	if _online_chip != null:
		var available_text: String = "Available"
		if _online_button != null and _online_button.disabled:
			available_text = "Unavailable"
		_online_chip.text = "Online: %s" % available_text
	_update_online_chip_icon()


func _presentation_label_from(mode: String) -> String:
	return "3D" if mode == "3d" else "2D"


func _ensure_online_button() -> void:
	if _buttons_box == null:
		return
	if _online_button == null:
		var button_node: Node = ICON_BUTTON_SCENE.instantiate()
		_online_button = button_node as Button
		if _online_button == null:
			_online_button = Button.new()
		_online_button.name = "OnlineButton"
		_online_button.custom_minimum_size = _style_vector(&"icon_button_min")
		_buttons_box.add_child(_online_button)
		_buttons_box.move_child(_online_button, 1)
		_online_button.pressed.connect(_on_online_pressed)
	_set_icon_text_button(_online_button, _texture(ICON_ONLINE_ID), "Online (EOS)", 0)

	var online_service = ONLINE_SERVICE_SCRIPT.new()
	var init_res: Dictionary = online_service.initialize()
	online_service.free()
	var available: bool = bool(init_res.get("ok", false))
	var policy: String = String(init_res.get("backend_policy", ""))
	_online_button.disabled = not available
	if not available:
		_online_button.tooltip_text = String(init_res.get("reason", "Online unavailable"))
		_set_icon_text_button(_online_button, _texture(ICON_ONLINE_LOCKED_ID), "Online (EOS)", 0)
	else:
		_online_button.tooltip_text = "Backend: %s | Policy: %s" % [
			String(init_res.get("backend_mode", "mock")),
			policy,
		]
		_set_icon_text_button(_online_button, _texture(ICON_ONLINE_UNLOCKED_ID), "Online (EOS)", 0)
	_sync_meta_chips()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if _menu_card == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var width_pad: float = 84.0 if viewport_size.x >= 1366.0 else 46.0
	var height_pad: float = 98.0 if viewport_size.y >= 768.0 else 52.0
	var min_size: Vector2 = _style_vector(&"main_menu_min")
	var max_size: Vector2 = _style_vector(&"main_menu_max")
	var width: float = clampf(viewport_size.x - width_pad * 2.0, min_size.x, max_size.x)
	var height: float = clampf(viewport_size.y - height_pad * 2.0, min_size.y, max_size.y)
	_menu_card.custom_minimum_size = Vector2(width, height)


func _style_color(id: StringName) -> Color:
	return MENU_STYLE.color(id)


func _style_scalar(id: StringName) -> float:
	return MENU_STYLE.scalar(id)


func _style_vector(id: StringName) -> Vector2:
	return MENU_STYLE.vector(id)


func _sync_presentation_mode_from_settings(settings: Dictionary = {}) -> void:
	var loaded: Dictionary = settings
	if loaded.is_empty():
		loaded = UI_SETTINGS_SCRIPT.load_from_disk()
	presentation_mode = UI_SETTINGS_SCRIPT.sanitize_presentation_mode(
		str(loaded.get("presentation_mode", PLATFORM_PROFILE_SCRIPT.default_presentation_mode()))
	)


func _apply_runtime_display_settings(settings: Dictionary = {}) -> void:
	var loaded: Dictionary = settings
	if loaded.is_empty():
		loaded = UI_SETTINGS_SCRIPT.load_from_disk()
	var display_settings: Dictionary = UI_SETTINGS_SCRIPT.sanitize_display_settings(loaded)
	var result: Dictionary = DISPLAY_SETTINGS_SCRIPT.apply_safe(display_settings)
	if not bool(result.get("ok", false)):
		if _banner != null and _banner.has_method("set_text"):
			_banner.call("set_text", "Display settings failed: %s" % String(result.get("reason", "unknown")))
