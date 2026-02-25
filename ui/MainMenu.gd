extends Control

@onready var _banner: Node = $StatusBanner
@onready var _background: TextureRect = $Background
@onready var _start_button: Button = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/Buttons/StartButton
@onready var _buttons_box: VBoxContainer = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/Buttons
@onready var _settings_button: Button = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/Buttons/SettingsButton
@onready var _quit_button: Button = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/Buttons/QuitButton
@onready var _menu_card: PanelContainer = $LayoutSplit/CardArea/MenuCard
@onready var _settings_summary: Label = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/SettingsSummary
@onready var _players_chip_icon: TextureRect = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/MetaChips/PlayersChipIcon
@onready var _players_chip: Label = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/MetaChips/PlayersChip
@onready var _timer_chip_icon: TextureRect = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/MetaChips/TimerChipIcon
@onready var _timer_chip: Label = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/MetaChips/TimerChip
@onready var _online_chip_icon: TextureRect = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/MetaChips/OnlineChipIcon
@onready var _online_chip: Label = $LayoutSplit/CardArea/MenuCard/MarginContainer/VBoxContainer/MetaChips/OnlineChip
@onready var _branding_area: Control = $LayoutSplit/BrandingArea

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
const PLAYER_PROFILE: Script = preload("res://ui/services/PlayerProfile.gd")

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

const WELCOME_MESSAGES: Array[String] = [
	"Welcome %s, be careful not to discard your okey tile :)",
	"Welcome %s! May your runs be long and your sets be full.",
	"Welcome %s, today's the day you master 101.",
	"Welcome %s! Remember: 101 points to open, patience to win.",
	"Welcome %s, the tiles are shuffled and ready!",
	"Welcome %s! A wise player never discards a joker... right?",
	"Welcome %s, may the indicator be in your favor!",
	"Welcome %s! Let's see if the bots stand a chance today.",
	"Welcome %s, the table is set. Time to play!",
	"Welcome %s! Pro tip: pairs can save your opening.",
]

# Game configuration
var player_count: int = 4
var game_seed: int = -1  # -1 means random
var rule_config: RuleConfig = null
var _animations_enabled: bool = true
var presentation_mode: String = PLATFORM_PROFILE_SCRIPT.default_presentation_mode()
var _online_button: Button = null
var _customize_button: Button = null
var _menu_audio = null
var _online_available: bool = false
var _logged_in: bool = false

# Online status UI
var _status_dot: ColorRect = null
var _login_btn: Button = null
var _welcome_label: Label = null
var _quit_x_btn: Button = null


func _ready() -> void:
	if _menu_audio == null:
		_menu_audio = MENU_AUDIO_SERVICE_SCRIPT.new()
		_menu_audio.name = "MenuAudioService"
		add_child(_menu_audio)
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	rule_config = RuleConfig.new()
	var ui_settings: Dictionary = UI_SETTINGS_SCRIPT.load_from_disk()
	_sync_presentation_mode_from_settings(ui_settings)
	_apply_runtime_display_settings(ui_settings)
	_apply_background_pattern()
	_apply_panel_shell()
	_ensure_online_button()
	_ensure_customize_button()
	_apply_kenney_fonts()
	_apply_meta_chip_icons()
	_apply_main_button_icons()
	_build_top_right_status()
	_build_branding_welcome()
	_apply_responsive_layout()

	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "")

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
	return [_start_button, _online_button, _customize_button, _settings_button, _quit_button]


func _apply_main_button_icons() -> void:
	_set_icon_text_button(_start_button, _texture(ICON_START_ID), "Play with Bots", 0)
	_set_icon_text_button(_settings_button, _texture(ICON_SETTINGS_ID), "Settings", 1)
	_set_icon_text_button(_quit_button, _texture(ICON_QUIT_ID), "Quit", 1)
	if _online_button != null:
		_set_icon_text_button(_online_button, _texture(ICON_ONLINE_ID), "Play Online", 0)
	if _customize_button != null:
		_set_icon_text_button(_customize_button, _texture(ICON_SETTINGS_ID), "Customize", 1)


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
	var title: Label = _menu_card.get_node("MarginContainer/VBoxContainer/Title")
	var subtitle: Label = _menu_card.get_node("MarginContainer/VBoxContainer/Subtitle")
	var version: Label = _menu_card.get_node("MarginContainer/VBoxContainer/Version")
	var summary: Label = _menu_card.get_node("MarginContainer/VBoxContainer/SettingsSummary")
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", _style_color(&"title_text"))
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", _style_color(&"subtitle_text"))
	version.add_theme_font_size_override("font_size", 15)
	version.add_theme_color_override("font_color", _style_color(&"muted_text"))
	summary.add_theme_font_size_override("font_size", 17)
	summary.add_theme_color_override("font_color", _style_color(&"body_text"))
	for chip in [_players_chip, _timer_chip, _online_chip]:
		if chip != null:
			chip.add_theme_font_size_override("font_size", 16)
			chip.add_theme_color_override("font_color", _style_color(&"chip_text"))


# ═══════════════════════════════════════════
# TOP-RIGHT STATUS AREA
# ═══════════════════════════════════════════

func _build_top_right_status() -> void:
	var container := VBoxContainer.new()
	container.name = "TopRightStatus"
	container.anchor_left = 1.0
	container.anchor_top = 0.0
	container.anchor_right = 1.0
	container.anchor_bottom = 0.0
	container.offset_left = -180
	container.offset_top = 16
	container.offset_right = -16
	container.offset_bottom = 120
	container.add_theme_constant_override("separation", 8)
	add_child(container)

	# Quit X button row
	var quit_row := HBoxContainer.new()
	quit_row.alignment = BoxContainer.ALIGNMENT_END
	container.add_child(quit_row)
	_quit_x_btn = Button.new()
	_quit_x_btn.text = "X"
	_quit_x_btn.custom_minimum_size = Vector2(32, 32)
	_quit_x_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_quit_x_btn.add_theme_color_override("font_color", Color(0.9, 0.3, 0.25))
	_quit_x_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.4, 0.3))
	_quit_x_btn.pressed.connect(_on_quit_pressed)
	quit_row.add_child(_quit_x_btn)

	# Status dot + label row
	var status_row := HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_END
	status_row.add_theme_constant_override("separation", 6)
	container.add_child(status_row)

	_status_dot = ColorRect.new()
	_status_dot.custom_minimum_size = Vector2(12, 12)
	_status_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_row.add_child(_status_dot)

	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", _style_color(&"muted_text"))
	status_row.add_child(status_label)

	# Login button
	_login_btn = Button.new()
	_login_btn.name = "LoginButton"
	_login_btn.text = "Login"
	_login_btn.custom_minimum_size = Vector2(100, 32)
	_login_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_login_btn.pressed.connect(_on_login_pressed)
	container.add_child(_login_btn)

	# Welcome message
	_welcome_label = Label.new()
	_welcome_label.name = "WelcomeLabel"
	_welcome_label.add_theme_font_size_override("font_size", 13)
	_welcome_label.add_theme_color_override("font_color", _style_color(&"welcome_text"))
	_welcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_welcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_welcome_label.visible = false
	container.add_child(_welcome_label)

	_update_online_status_display()


func _update_online_status_display() -> void:
	if _status_dot == null:
		return
	var status_label: Label = _status_dot.get_parent().get_node_or_null("StatusLabel")
	if not _online_available:
		_status_dot.color = _style_color(&"online_status_offline")
		if status_label != null:
			status_label.text = "Offline"
		_login_btn.visible = false
		_welcome_label.visible = false
	elif not _logged_in:
		_status_dot.color = _style_color(&"online_status_idle")
		if status_label != null:
			status_label.text = "Not logged in"
		_login_btn.visible = true
		_welcome_label.visible = false
	else:
		_status_dot.color = _style_color(&"online_status_online")
		if status_label != null:
			status_label.text = "Online"
		_login_btn.visible = false
		_welcome_label.visible = true
		var msg: String = WELCOME_MESSAGES[randi() % WELCOME_MESSAGES.size()]
		_welcome_label.text = msg % PLAYER_PROFILE.display_name


func _on_login_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	# Open online lobby which handles EOS login flow
	_on_online_pressed()


# ═══════════════════════════════════════════
# BRANDING AREA (LEFT SIDE)
# ═══════════════════════════════════════════

func _build_branding_welcome() -> void:
	if _branding_area == null:
		return
	# The branding area already has a large faint "Okey 101" label in the tscn.
	# Add a subtitle below it.
	var subtitle := Label.new()
	subtitle.text = "Turkish Tile Rummy"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.5
	subtitle.anchor_top = 0.5
	subtitle.anchor_right = 0.5
	subtitle.anchor_bottom = 0.5
	subtitle.offset_left = -150
	subtitle.offset_top = 50
	subtitle.offset_right = 150
	subtitle.offset_bottom = 80
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", _style_color(&"subtitle_text").darkened(0.5))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_branding_area.add_child(subtitle)


# ═══════════════════════════════════════════
# BUTTON HANDLERS
# ═══════════════════════════════════════════

func _on_start_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	var lobby := preload("res://ui/PreGameLobby.gd").new()
	lobby.set_defaults(player_count, game_seed)
	if rule_config != null:
		lobby.set_rule_config(rule_config)
	lobby.game_started.connect(_on_lobby_game_started)
	lobby.back_pressed.connect(func() -> void: lobby.queue_free())
	add_child(lobby)


func _on_lobby_game_started(pc: int, seed_val: int, bot_difficulties: Array = [], _practice_mode: bool = false) -> void:
	player_count = pc
	var actual_seed: int = seed_val if seed_val >= 0 else randi()

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
		game_table.configure_game(rule_config, actual_seed, player_count, bot_difficulties)
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


func _on_customize_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Customize coming in a future update!")


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


# ═══════════════════════════════════════════
# ONLINE + CUSTOMIZE BUTTONS
# ═══════════════════════════════════════════

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
	_set_icon_text_button(_online_button, _texture(ICON_ONLINE_ID), "Play Online", 0)

	var online_service = ONLINE_SERVICE_SCRIPT.new()
	var init_res: Dictionary = online_service.initialize()
	online_service.free()
	_online_available = bool(init_res.get("ok", false))
	var policy: String = String(init_res.get("backend_policy", ""))
	_online_button.disabled = not _online_available
	if not _online_available:
		_online_button.tooltip_text = String(init_res.get("reason", "Online unavailable"))
		_set_icon_text_button(_online_button, _texture(ICON_ONLINE_LOCKED_ID), "Play Online", 0)
	else:
		_online_button.tooltip_text = "Backend: %s | Policy: %s" % [
			String(init_res.get("backend_mode", "mock")),
			policy,
		]
		_set_icon_text_button(_online_button, _texture(ICON_ONLINE_UNLOCKED_ID), "Play Online", 0)
	_sync_meta_chips()


func _ensure_customize_button() -> void:
	if _buttons_box == null:
		return
	if _customize_button == null:
		var button_node: Node = ICON_BUTTON_SCENE.instantiate()
		_customize_button = button_node as Button
		if _customize_button == null:
			_customize_button = Button.new()
		_customize_button.name = "CustomizeButton"
		_customize_button.custom_minimum_size = _style_vector(&"icon_button_min")
		_buttons_box.add_child(_customize_button)
		_buttons_box.move_child(_customize_button, 2)
		_customize_button.pressed.connect(_on_customize_pressed)
	_set_icon_text_button(_customize_button, _texture(ICON_SETTINGS_ID), "Customize", 1)


# ═══════════════════════════════════════════
# STATE HELPERS
# ═══════════════════════════════════════════

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


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if _menu_card == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	# On narrow screens, hide branding area
	if _branding_area != null:
		_branding_area.visible = viewport_size.x >= 900.0


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
