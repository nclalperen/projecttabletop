extends Control

class_name SettingsMenu

signal settings_changed(new_config)
signal cancelled

const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")
const VISUAL_QUALITY_SCRIPT: Script = preload("res://ui/services/VisualQualityService.gd")
const DISPLAY_SETTINGS_SCRIPT: Script = preload("res://ui/services/DisplaySettingsService.gd")
const MENU_AUDIO_SERVICE_SCRIPT: Script = preload("res://ui/services/MenuAudioService.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const PROMPT_BADGE_SCENE: PackedScene = preload("res://ui/widgets/InputPromptBadge.tscn")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const IMPORTED_FLAGS_ROOT: String = "/root/ImportedFeatureFlags"

const PANEL_BORDER_ID: StringName = ASSET_IDS.UI_PANEL_BORDER_GREY_DETAIL
const PANEL_FILL_ID: StringName = ASSET_IDS.UI_PANEL_GREY_DARK
const PANEL_GRID_ID: StringName = ASSET_IDS.UI_PANEL_PATTERN_DIAGONAL_TRANSPARENT_SMALL
const ICON_SAVE_ID: StringName = ASSET_IDS.UI_ICON_CHECKMARK
const ICON_CANCEL_ID: StringName = ASSET_IDS.UI_ICON_RETURN
const PROMPT_ENTER_ID: StringName = ASSET_IDS.UI_PROMPT_ENTER
const PROMPT_ESC_ID: StringName = ASSET_IDS.UI_PROMPT_ESC

@onready var _background: TextureRect = $Background
@onready var _panel: Panel = $Panel
@onready var _main_vbox: VBoxContainer = $Panel/MarginContainer/VBoxContainer
@onready var settings_list = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList
@onready var initial_open_points = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/InitialOpenPoints/Value
@onready var allow_five_pairs_open = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/AllowFivePairsOpen/Value
@onready var turn_timer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/TurnTimer/Value
@onready var match_end_condition = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndCondition/Value
@onready var match_end_value = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndValue/Value
@onready var _prompt_strip: Container = $Panel/MarginContainer/VBoxContainer/PromptStrip

@onready var save_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SaveButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

var _config: RuleConfig
var _ui_settings = null
var _sfx_volume_spin: SpinBox = null
var _music_volume_spin: SpinBox = null
var _graphics_profile_option: OptionButton = null
var _aa_mode_option: OptionButton = null
var _ssao_quality_option: OptionButton = null
var _shadow_quality_option: OptionButton = null
var _ssr_enabled_check: CheckBox = null
var _resolution_scale_spin: SpinBox = null
var _postfx_strength_spin: SpinBox = null
var _presentation_mode_option: OptionButton = null
var _display_monitor_option: OptionButton = null
var _display_mode_option: OptionButton = null
var _display_resolution_option: OptionButton = null
var _display_refresh_option: OptionButton = null
var _display_vsync_option: OptionButton = null
var _display_fps_cap_option: OptionButton = null
var _display_monitors: Array[Dictionary] = []
var _status_label: Label = null
var _menu_audio = null
var _suppress_feedback_audio: bool = false
var _last_toggle_sound_msec: int = -1
var _preview_dialog: ConfirmationDialog = null
var _preview_timer: Timer = null
var _preview_seconds_left: int = 0
var _preview_active: bool = false
var _preview_previous_display: Dictionary = {}
var _preview_candidate_display: Dictionary = {}
var _imported_feature_checks: Dictionary = {}

func _ready():
	if _menu_audio == null:
		_menu_audio = MENU_AUDIO_SERVICE_SCRIPT.new()
		_menu_audio.name = "MenuAudioService"
		add_child(_menu_audio)

	_ui_settings = UI_SETTINGS_SCRIPT.load_from_disk()
	_ensure_visual_rows()
	_ensure_display_rows()
	_ensure_audio_rows()
	_ensure_imported_feature_rows()
	_ensure_status_row()
	_apply_kenney_fonts()
	_apply_form_skin()
	_apply_background_pattern()
	_apply_panel_shell()
	_apply_button_icons()
	_build_prompt_strip()
	_configure_feedback_copy()
	_bind_audio_feedback()
	_init_preview_dialog()
	_apply_responsive_layout()

	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	match_end_condition.add_item("Rounds", 0)
	match_end_condition.add_item("Target Score", 1)
	if _config != null:
		load_config()


func _apply_button_icons() -> void:
	_set_icon_button(save_button, _texture(ICON_SAVE_ID), "Save", 0)
	_set_icon_button(cancel_button, _texture(ICON_CANCEL_ID), "Cancel", 1)


func _set_icon_button(button: Button, texture: Texture2D, label_text: String, variant: int = 0) -> void:
	if button == null:
		return
	button.text = label_text
	button.icon = texture
	if _has_property(button, "button_label"):
		button.set("button_label", label_text)
	if _has_property(button, "icon_texture"):
		button.set("icon_texture", texture)
	if _has_property(button, "style_variant"):
		button.set("style_variant", variant)


func _has_property(target: Object, property_name: String) -> bool:
	for entry in target.get_property_list():
		if String(entry.get("name", "")) == property_name:
			return true
	return false


func _texture(id: StringName) -> Texture2D:
	return ASSET_REGISTRY.texture(id)


func _apply_kenney_fonts() -> void:
	var title: Label = $Panel/MarginContainer/VBoxContainer/Label
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", _style_color(&"title_text"))
	for label in settings_list.find_children("*", "Label", true, false):
		var item: Label = label as Label
		if item == null:
			continue
		var is_header: bool = item.name == "VisualLabel" or item.name == "DisplayLabel"
		item.add_theme_font_size_override("font_size", 20 if is_header else 18)
		item.add_theme_color_override("font_color", _style_color(&"subtitle_text") if is_header else _style_color(&"body_text"))


func _apply_background_pattern() -> void:
	if _background != null:
		_background.texture = _texture(PANEL_GRID_ID)
		_background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_background.stretch_mode = TextureRect.STRETCH_TILE
		_background.modulate = _style_color(&"bg_pattern")


func _apply_panel_shell() -> void:
	if _panel == null:
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
		_panel.add_theme_stylebox_override("panel", panel_style)

	var border_tex: Texture2D = _texture(PANEL_BORDER_ID)
	if border_tex == null:
		return
	var border := _panel.get_node_or_null("KenneyBorder") as NinePatchRect
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
		_panel.add_child(border)
	border.texture = border_tex
	border.modulate = _style_color(&"panel_border")


func _apply_form_skin() -> void:
	var field_normal := StyleBoxFlat.new()
	field_normal.bg_color = _style_color(&"field_bg")
	field_normal.border_width_left = 2
	field_normal.border_width_top = 2
	field_normal.border_width_right = 2
	field_normal.border_width_bottom = 2
	field_normal.border_color = _style_color(&"field_border")
	field_normal.corner_radius_top_left = 10
	field_normal.corner_radius_top_right = 10
	field_normal.corner_radius_bottom_right = 10
	field_normal.corner_radius_bottom_left = 10
	field_normal.content_margin_left = 10
	field_normal.content_margin_top = 6
	field_normal.content_margin_right = 10
	field_normal.content_margin_bottom = 6

	var field_focus := field_normal.duplicate() as StyleBoxFlat
	field_focus.border_color = _style_color(&"field_border_focus")
	field_focus.shadow_color = _style_color(&"field_shadow")
	field_focus.shadow_size = 3

	for node in settings_list.find_children("*", "OptionButton", true, false):
		var opt: OptionButton = node as OptionButton
		if opt == null:
			continue
		opt.custom_minimum_size = Vector2(220, 42)
		opt.add_theme_stylebox_override("normal", field_normal)
		opt.add_theme_stylebox_override("hover", field_focus)
		opt.add_theme_stylebox_override("pressed", field_focus)
		opt.add_theme_color_override("font_color", _style_color(&"field_text"))
		opt.add_theme_color_override("font_hover_color", _style_color(&"field_text").lightened(0.04))
		opt.add_theme_color_override("font_pressed_color", _style_color(&"field_text").lightened(0.04))

	for node in settings_list.find_children("*", "SpinBox", true, false):
		var spin: SpinBox = node as SpinBox
		if spin == null:
			continue
		spin.custom_minimum_size = Vector2(120, 40)
		var line: LineEdit = spin.get_line_edit()
		if line != null:
			line.add_theme_stylebox_override("normal", field_normal)
			line.add_theme_stylebox_override("focus", field_focus)
			line.add_theme_color_override("font_color", _style_color(&"field_text"))
			line.add_theme_color_override("font_placeholder_color", _style_color(&"field_placeholder"))
			line.add_theme_font_size_override("font_size", 19)
			line.add_theme_constant_override("minimum_character_width", 6)
			line.alignment = HORIZONTAL_ALIGNMENT_CENTER

	for node in settings_list.find_children("*", "CheckBox", true, false):
		var check: CheckBox = node as CheckBox
		if check == null:
			continue
		check.add_theme_color_override("font_color", _style_color(&"field_text"))
		check.add_theme_color_override("font_hover_color", _style_color(&"field_text").lightened(0.04))
		check.add_theme_font_size_override("font_size", 18)
		check.custom_minimum_size = Vector2(68, 40)


func _build_prompt_strip() -> void:
	for child in _prompt_strip.get_children():
		child.queue_free()
	var prompts: Array[Dictionary] = [
		{"icon": _texture(PROMPT_ENTER_ID), "text": "ENTER Save & Apply"},
		{"icon": _texture(PROMPT_ESC_ID), "text": "ESC Cancel Changes"},
	]
	for entry in prompts:
		var badge: Node = PROMPT_BADGE_SCENE.instantiate()
		_prompt_strip.add_child(badge)
		if badge.has_method("configure"):
			badge.call("configure", entry.get("icon", null), String(entry.get("text", "")))


func _ensure_status_row() -> void:
	if _main_vbox == null:
		return
	_status_label = _main_vbox.get_node_or_null("StatusLabel") as Label
	if _status_label == null:
		_status_label = Label.new()
		_status_label.name = "StatusLabel"
		_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_status_label.custom_minimum_size = Vector2(0, 26)
		_status_label.add_theme_font_size_override("font_size", 15)
		_status_label.add_theme_color_override("font_color", _style_color(&"chip_text"))
		var prompt_index: int = _prompt_strip.get_index()
		_main_vbox.add_child(_status_label)
		_main_vbox.move_child(_status_label, prompt_index)


func _set_status_text(text: String, is_error: bool = false) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_label.modulate = Color(1.0, 0.85, 0.72, 1.0) if is_error else Color(0.94, 0.9, 0.8, 0.96)


func _configure_feedback_copy() -> void:
	if save_button != null:
		save_button.tooltip_text = "Save and apply settings"
	if cancel_button != null:
		cancel_button.tooltip_text = "Discard changes and return"


func _bind_audio_feedback() -> void:
	for button in [save_button, cancel_button]:
		if button == null:
			continue
		button.mouse_entered.connect(_on_settings_button_hover.bind(button))
	if not match_end_condition.item_selected.is_connected(_on_match_end_condition_selected):
		match_end_condition.item_selected.connect(_on_match_end_condition_selected)
	if not allow_five_pairs_open.toggled.is_connected(_on_allow_five_pairs_toggled):
		allow_five_pairs_open.toggled.connect(_on_allow_five_pairs_toggled)
	for opt in [
		_graphics_profile_option,
		_aa_mode_option,
		_ssao_quality_option,
		_shadow_quality_option,
		_presentation_mode_option,
		_display_resolution_option,
		_display_refresh_option,
		_display_vsync_option,
		_display_fps_cap_option
	]:
		var option: OptionButton = opt as OptionButton
		if option != null and not option.item_selected.is_connected(_on_visual_option_selected):
			option.item_selected.connect(_on_visual_option_selected)
	if _ssr_enabled_check != null and not _ssr_enabled_check.toggled.is_connected(_on_visual_toggle_changed):
		_ssr_enabled_check.toggled.connect(_on_visual_toggle_changed)
	if _display_monitor_option != null:
		if not _display_monitor_option.item_selected.is_connected(_on_display_monitor_selected):
			_display_monitor_option.item_selected.connect(_on_display_monitor_selected)
	if _display_mode_option != null:
		if not _display_mode_option.item_selected.is_connected(_on_display_mode_selected):
			_display_mode_option.item_selected.connect(_on_display_mode_selected)


func _on_settings_button_hover(_button: Button) -> void:
	if _menu_audio != null:
		_menu_audio.play_hover()


func _on_match_end_condition_selected(_idx: int) -> void:
	_play_toggle_feedback()


func _on_allow_five_pairs_toggled(_pressed: bool) -> void:
	_play_toggle_feedback()


func _on_visual_option_selected(_idx: int) -> void:
	_play_toggle_feedback()


func _on_visual_toggle_changed(_pressed: bool) -> void:
	_play_toggle_feedback()


func _on_display_monitor_selected(_idx: int) -> void:
	_rebuild_resolution_and_refresh_options_for_selected_monitor()
	_play_toggle_feedback()
	_update_display_mode_hints()


func _on_display_mode_selected(_idx: int) -> void:
	_play_toggle_feedback()
	_update_display_mode_hints()


func _play_toggle_feedback() -> void:
	if _suppress_feedback_audio or _menu_audio == null:
		return
	var now_ms: int = Time.get_ticks_msec()
	if _last_toggle_sound_msec >= 0 and now_ms - _last_toggle_sound_msec < 40:
		return
	_last_toggle_sound_msec = now_ms
	_menu_audio.play_toggle()


func set_config(config: RuleConfig):
	_config = config
	load_config()


func load_config():
	if not _config:
		return

	_suppress_feedback_audio = true
	initial_open_points.value = _config.open_min_points_initial
	allow_five_pairs_open.button_pressed = _config.allow_open_by_five_pairs
	turn_timer.value = _config.timer_seconds

	if _config.match_end_mode == "rounds":
		match_end_condition.select(0)
	else:
		match_end_condition.select(1)

	match_end_value.value = _config.match_end_value
	if _sfx_volume_spin != null and _ui_settings != null:
		_sfx_volume_spin.value = round(float(_ui_settings.get("sfx_volume", 0.82)) * 100.0)
	if _music_volume_spin != null and _ui_settings != null:
		_music_volume_spin.value = round(float(_ui_settings.get("music_volume", 0.30)) * 100.0)
	_sync_visual_controls_from_settings()
	_sync_display_controls_from_settings()
	_sync_imported_feature_controls_from_flags()
	_suppress_feedback_audio = false


func save_config(display_override: Dictionary = {}):
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
	if _ui_settings != null:
		var sfx_volume: float = clampf(float(_sfx_volume_spin.value) / 100.0, 0.0, 1.0) if _sfx_volume_spin != null else 0.82
		var music_volume: float = clampf(float(_music_volume_spin.value) / 100.0, 0.0, 1.0) if _music_volume_spin != null else 0.30
		var visual_settings: Dictionary = _collect_visual_settings_from_controls()
		var display_settings: Dictionary = _collect_display_settings_from_controls()
		var presentation_mode: String = _collect_presentation_mode_from_controls()
		if not display_override.is_empty():
			display_settings = UI_SETTINGS_SCRIPT.sanitize_display_settings(display_override)
		UI_SETTINGS_SCRIPT.save_to_disk(sfx_volume, music_volume, visual_settings, display_settings, presentation_mode)
		_ui_settings["sfx_volume"] = sfx_volume
		_ui_settings["music_volume"] = music_volume
		_ui_settings["presentation_mode"] = presentation_mode
		for key in visual_settings.keys():
			_ui_settings[key] = visual_settings[key]
		for key in display_settings.keys():
			_ui_settings[key] = display_settings[key]
	_save_imported_feature_controls_to_flags()


func _on_save_pressed():
	if _preview_active:
		return
	if _menu_audio != null:
		_menu_audio.play_confirm()
	var candidate_display: Dictionary = _collect_display_settings_from_controls()
	_update_display_mode_hints()
	var current_display: Dictionary = DISPLAY_SETTINGS_SCRIPT.current_runtime_settings()
	if not _display_settings_equal(candidate_display, current_display):
		_start_display_preview(candidate_display, current_display)
		return
	save_config(candidate_display)
	emit_signal("settings_changed", _config)
	queue_free()


func _on_cancel_pressed():
	if _preview_active:
		_cancel_display_preview("Display preview cancelled. Reverted changes.")
	if _menu_audio != null:
		_menu_audio.play_back()
	emit_signal("cancelled")
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _ensure_audio_rows() -> void:
	if settings_list == null:
		return
	if _sfx_volume_spin == null:
		var sfx_row := _build_percent_row("SFX Volume")
		settings_list.add_child(sfx_row.get("row"))
		_sfx_volume_spin = sfx_row.get("spin") as SpinBox
	if _music_volume_spin == null:
		var music_row := _build_percent_row("Music Volume")
		settings_list.add_child(music_row.get("row"))
		_music_volume_spin = music_row.get("spin") as SpinBox


func _ensure_imported_feature_rows() -> void:
	if settings_list == null:
		return
	if settings_list.get_node_or_null("ImportedPrototypeLabel") != null:
		return
	var section := Label.new()
	section.name = "ImportedPrototypeLabel"
	section.text = "Imported Prototype Runtime"
	section.add_theme_font_size_override("font_size", 20)
	section.add_theme_color_override("font_color", _style_color(&"subtitle_text"))
	settings_list.add_child(section)
	var rows: Array[Dictionary] = [
		{"id": "prototype_table_enabled", "label": "Route All Games To ImportedTable3D"},
		{"id": "tabletop_club", "label": "Enable Tabletop Club Module"},
		{"id": "buckshot", "label": "Enable Buckshot Module"},
		{"id": "dome_keeper", "label": "Enable Dome Keeper Module"},
		{"id": "halls_torment", "label": "Enable Halls Of Torment Module"},
		{"id": "brotato", "label": "Enable Brotato Module"},
		{"id": "slay2", "label": "Enable Slay2 Module"},
		{"id": "cruelty_squad", "label": "Enable Cruelty Squad Module"},
	]
	for row in rows:
		var line := HBoxContainer.new()
		line.name = "ImportedFlag_%s" % String(row.get("id", "unknown"))
		line.add_theme_constant_override("separation", 14)
		var label := Label.new()
		label.text = String(row.get("label", ""))
		label.custom_minimum_size = Vector2(360, 0)
		label.add_theme_font_size_override("font_size", 17)
		line.add_child(label)
		var check := CheckBox.new()
		check.text = "Enabled"
		check.button_pressed = false
		check.toggled.connect(_on_visual_toggle_changed)
		line.add_child(check)
		settings_list.add_child(line)
		_imported_feature_checks[StringName(row.get("id", ""))] = check


func _sync_imported_feature_controls_from_flags() -> void:
	var flags: Node = get_node_or_null(IMPORTED_FLAGS_ROOT)
	if flags == null:
		return
	for feature_id in _imported_feature_checks.keys():
		var check: CheckBox = _imported_feature_checks[feature_id]
		if check == null:
			continue
		check.button_pressed = bool(flags.call("is_enabled", feature_id))


func _save_imported_feature_controls_to_flags() -> void:
	var flags: Node = get_node_or_null(IMPORTED_FLAGS_ROOT)
	if flags == null:
		return
	for feature_id in _imported_feature_checks.keys():
		var check: CheckBox = _imported_feature_checks[feature_id]
		if check == null:
			continue
		flags.call("set_enabled", feature_id, check.button_pressed)


func _ensure_visual_rows() -> void:
	if settings_list == null:
		return
	if settings_list.get_node_or_null("VisualSeparator") == null:
		var sep := HSeparator.new()
		sep.name = "VisualSeparator"
		settings_list.add_child(sep)
	if settings_list.get_node_or_null("VisualLabel") == null:
		var header := Label.new()
		header.name = "VisualLabel"
		header.text = "Visual Quality"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		settings_list.add_child(header)
	if _graphics_profile_option == null:
		var profile_row := _build_option_row("Graphics Profile", [
			{"label": "Low", "id": VISUAL_QUALITY_SCRIPT.PROFILE_LOW},
			{"label": "Medium", "id": VISUAL_QUALITY_SCRIPT.PROFILE_MEDIUM},
			{"label": "High", "id": VISUAL_QUALITY_SCRIPT.PROFILE_HIGH},
			{"label": "Ultra", "id": VISUAL_QUALITY_SCRIPT.PROFILE_ULTRA},
		])
		settings_list.add_child(profile_row.get("row"))
		_graphics_profile_option = profile_row.get("option") as OptionButton
	if _aa_mode_option == null:
		var aa_row := _build_option_row("AA Mode", [
			{"label": "Off", "id": VISUAL_QUALITY_SCRIPT.AA_OFF},
			{"label": "FXAA", "id": VISUAL_QUALITY_SCRIPT.AA_FXAA},
			{"label": "TAA", "id": VISUAL_QUALITY_SCRIPT.AA_TAA},
			{"label": "FSR2 (Fallback)", "id": VISUAL_QUALITY_SCRIPT.AA_FSR2},
		])
		settings_list.add_child(aa_row.get("row"))
		_aa_mode_option = aa_row.get("option") as OptionButton
	if _ssao_quality_option == null:
		var ssao_row := _build_option_row("SSAO Quality", [
			{"label": "Off", "id": 0},
			{"label": "Low", "id": 1},
			{"label": "Medium", "id": 2},
			{"label": "High", "id": 3},
		])
		settings_list.add_child(ssao_row.get("row"))
		_ssao_quality_option = ssao_row.get("option") as OptionButton
	if _shadow_quality_option == null:
		var shadow_row := _build_option_row("Shadow Quality", [
			{"label": "Off", "id": 0},
			{"label": "Low", "id": 1},
			{"label": "Medium", "id": 2},
			{"label": "High", "id": 3},
		])
		shadow_row.get("row").name = "ShadowQuality"
		settings_list.add_child(shadow_row.get("row"))
		_shadow_quality_option = shadow_row.get("option") as OptionButton
	if _ssr_enabled_check == null:
		var ssr_row := _build_toggle_row("SSR Reflections")
		settings_list.add_child(ssr_row.get("row"))
		_ssr_enabled_check = ssr_row.get("check") as CheckBox
	if _resolution_scale_spin == null:
		var res_row := _build_percent_row("Resolution Scale")
		settings_list.add_child(res_row.get("row"))
		_resolution_scale_spin = res_row.get("spin") as SpinBox
		if _resolution_scale_spin != null:
			_resolution_scale_spin.min_value = 55.0
			_resolution_scale_spin.max_value = 120.0
			_resolution_scale_spin.step = 1.0
	if _postfx_strength_spin == null:
		var post_row := _build_percent_row("PostFX Strength")
		settings_list.add_child(post_row.get("row"))
		_postfx_strength_spin = post_row.get("spin") as SpinBox
		if _postfx_strength_spin != null:
			_postfx_strength_spin.min_value = 0.0
			_postfx_strength_spin.max_value = 100.0
			_postfx_strength_spin.step = 1.0
	_sync_visual_controls_from_settings()


func _ensure_display_rows() -> void:
	if settings_list == null:
		return
	if settings_list.get_node_or_null("DisplaySeparator") == null:
		var sep := HSeparator.new()
		sep.name = "DisplaySeparator"
		settings_list.add_child(sep)
	if settings_list.get_node_or_null("DisplayLabel") == null:
		var header := Label.new()
		header.name = "DisplayLabel"
		header.text = "Display & Hardware"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		settings_list.add_child(header)
	if _display_monitor_option == null:
		var monitor_row := _build_option_row("Monitor", [])
		monitor_row.get("row").name = "DisplayMonitor"
		settings_list.add_child(monitor_row.get("row"))
		_display_monitor_option = monitor_row.get("option") as OptionButton
	if _presentation_mode_option == null:
		var presentation_row := _build_option_row("Presentation Mode", [
			{"label": "2D Table", "id": "2d"},
			{"label": "3D Table", "id": "3d"},
		])
		presentation_row.get("row").name = "DisplayPresentationMode"
		settings_list.add_child(presentation_row.get("row"))
		_presentation_mode_option = presentation_row.get("option") as OptionButton
	if _display_mode_option == null:
		var mode_row := _build_option_row("Display Mode", [
			{"label": "Windowed", "id": DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED},
			{"label": "Borderless", "id": DISPLAY_SETTINGS_SCRIPT.MODE_BORDERLESS},
			{"label": "Exclusive Fullscreen", "id": DISPLAY_SETTINGS_SCRIPT.MODE_EXCLUSIVE},
		])
		mode_row.get("row").name = "DisplayMode"
		settings_list.add_child(mode_row.get("row"))
		_display_mode_option = mode_row.get("option") as OptionButton
	if _display_resolution_option == null:
		var res_row := _build_option_row("Resolution", [])
		res_row.get("row").name = "DisplayResolution"
		settings_list.add_child(res_row.get("row"))
		_display_resolution_option = res_row.get("option") as OptionButton
	if _display_refresh_option == null:
		var refresh_row := _build_option_row("Refresh Rate", [])
		refresh_row.get("row").name = "DisplayRefreshRate"
		settings_list.add_child(refresh_row.get("row"))
		_display_refresh_option = refresh_row.get("option") as OptionButton
	if _display_vsync_option == null:
		var vsync_row := _build_option_row("VSync", [
			{"label": "Enabled", "id": DISPLAY_SETTINGS_SCRIPT.VSYNC_ENABLED},
			{"label": "Disabled", "id": DISPLAY_SETTINGS_SCRIPT.VSYNC_DISABLED},
			{"label": "Adaptive", "id": DISPLAY_SETTINGS_SCRIPT.VSYNC_ADAPTIVE},
			{"label": "Mailbox", "id": DISPLAY_SETTINGS_SCRIPT.VSYNC_MAILBOX},
		])
		vsync_row.get("row").name = "DisplayVSync"
		settings_list.add_child(vsync_row.get("row"))
		_display_vsync_option = vsync_row.get("option") as OptionButton
	if _display_fps_cap_option == null:
		var fps_row := _build_option_row("FPS Cap", [
			{"label": "Uncapped", "id": 0},
			{"label": "30", "id": 30},
			{"label": "60", "id": 60},
			{"label": "90", "id": 90},
			{"label": "120", "id": 120},
			{"label": "144", "id": 144},
			{"label": "165", "id": 165},
			{"label": "240", "id": 240},
		])
		fps_row.get("row").name = "DisplayFpsCap"
		settings_list.add_child(fps_row.get("row"))
		_display_fps_cap_option = fps_row.get("option") as OptionButton
	_populate_display_controls()
	_sync_display_platform_capabilities()


func _sync_visual_controls_from_settings() -> void:
	if _ui_settings == null:
		_ui_settings = UI_SETTINGS_SCRIPT.default_visual_settings()
	var visual: Dictionary = UI_SETTINGS_SCRIPT.sanitize_visual_settings(_ui_settings)
	_select_option_by_id(_graphics_profile_option, str(visual.get("graphics_profile", VISUAL_QUALITY_SCRIPT.PROFILE_HIGH)))
	_select_option_by_id(_aa_mode_option, str(visual.get("aa_mode", VISUAL_QUALITY_SCRIPT.AA_FXAA)))
	_select_option_by_id(_ssao_quality_option, int(visual.get("ssao_quality", 2)))
	_select_option_by_id(_shadow_quality_option, int(visual.get("shadow_quality", 2)))
	if _ssr_enabled_check != null:
		_ssr_enabled_check.button_pressed = bool(visual.get("ssr_enabled", true))
	if _resolution_scale_spin != null:
		_resolution_scale_spin.value = round(float(visual.get("resolution_scale", 1.0)) * 100.0)
	if _postfx_strength_spin != null:
		_postfx_strength_spin.value = round(float(visual.get("postfx_strength", 0.70)) * 100.0)


func _populate_display_controls() -> void:
	_display_monitors = DISPLAY_SETTINGS_SCRIPT.list_monitors()
	_clear_option(_display_monitor_option)
	for m in _display_monitors:
		var idx: int = int(m.get("index", 0))
		var label: String = String(m.get("label", "Display %d" % (idx + 1)))
		_display_monitor_option.add_item(label)
		_display_monitor_option.set_item_metadata(_display_monitor_option.get_item_count() - 1, idx)
	_rebuild_resolution_and_refresh_options_for_selected_monitor()
	_sync_display_controls_from_settings()


func _rebuild_resolution_and_refresh_options_for_selected_monitor() -> void:
	var monitor_index: int = _selected_monitor_index()
	_clear_option(_display_resolution_option)
	for res in DISPLAY_SETTINGS_SCRIPT.list_resolutions(monitor_index):
		var key: String = _resolution_key(res)
		_display_resolution_option.add_item(key)
		_display_resolution_option.set_item_metadata(_display_resolution_option.get_item_count() - 1, key)
	_clear_option(_display_refresh_option)
	var rates: PackedInt32Array = DISPLAY_SETTINGS_SCRIPT.list_refresh_rates(monitor_index)
	if rates.is_empty():
		rates = PackedInt32Array([0])
	for hz in rates:
		var label: String = "Auto" if hz == 0 else "%d Hz" % hz
		_display_refresh_option.add_item(label)
		_display_refresh_option.set_item_metadata(_display_refresh_option.get_item_count() - 1, int(hz))


func _sync_display_controls_from_settings() -> void:
	if _ui_settings == null:
		_ui_settings = UI_SETTINGS_SCRIPT.load_from_disk()
	var display: Dictionary = UI_SETTINGS_SCRIPT.sanitize_display_settings(_ui_settings)
	_select_option_by_id(
		_presentation_mode_option,
		UI_SETTINGS_SCRIPT.sanitize_presentation_mode(str(_ui_settings.get("presentation_mode", UI_SETTINGS_SCRIPT.default_presentation_mode())))
	)
	_select_option_by_id(_display_monitor_option, int(display.get("monitor_index", 0)))
	_rebuild_resolution_and_refresh_options_for_selected_monitor()
	_select_option_by_id(_display_mode_option, str(display.get("display_mode", DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED)))
	_select_option_by_id(_display_resolution_option, _resolution_key(Vector2i(
		int(display.get("resolution_width", 1280)),
		int(display.get("resolution_height", 720))
	)))
	_select_option_by_id(_display_refresh_option, int(display.get("refresh_rate_hz", 0)))
	_select_option_by_id(_display_vsync_option, str(display.get("vsync_mode", DISPLAY_SETTINGS_SCRIPT.VSYNC_ENABLED)))
	_select_option_by_id(_display_fps_cap_option, int(display.get("fps_cap", 0)))
	_sync_display_platform_capabilities()
	_update_display_mode_hints()


func _collect_visual_settings_from_controls() -> Dictionary:
	var selected_profile: String = str(_selected_option_id(_graphics_profile_option, VISUAL_QUALITY_SCRIPT.PROFILE_HIGH))
	var current_visual: Dictionary = UI_SETTINGS_SCRIPT.sanitize_visual_settings(_ui_settings if _ui_settings != null else {})
	var current_profile: String = str(current_visual.get("graphics_profile", VISUAL_QUALITY_SCRIPT.PROFILE_HIGH))
	if selected_profile != current_profile:
		return UI_SETTINGS_SCRIPT.sanitize_visual_settings(VISUAL_QUALITY_SCRIPT.defaults_for_profile(selected_profile))

	var raw: Dictionary = {
		"graphics_profile": selected_profile,
		"aa_mode": _selected_option_id(_aa_mode_option, VISUAL_QUALITY_SCRIPT.AA_FXAA),
		"ssao_quality": int(_selected_option_id(_ssao_quality_option, 2)),
		"shadow_quality": int(_selected_option_id(_shadow_quality_option, 2)),
		"ssr_enabled": _ssr_enabled_check.button_pressed if _ssr_enabled_check != null else true,
		"resolution_scale": (float(_resolution_scale_spin.value) / 100.0) if _resolution_scale_spin != null else 1.0,
		"postfx_strength": (float(_postfx_strength_spin.value) / 100.0) if _postfx_strength_spin != null else 0.70,
	}
	return UI_SETTINGS_SCRIPT.sanitize_visual_settings(raw)


func _collect_display_settings_from_controls() -> Dictionary:
	var resolution: Vector2i = _selected_resolution()
	var raw: Dictionary = {
		"display_mode": str(_selected_option_id(_display_mode_option, DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED)),
		"monitor_index": int(_selected_option_id(_display_monitor_option, 0)),
		"resolution_width": resolution.x,
		"resolution_height": resolution.y,
		"refresh_rate_hz": int(_selected_option_id(_display_refresh_option, 0)),
		"vsync_mode": str(_selected_option_id(_display_vsync_option, DISPLAY_SETTINGS_SCRIPT.VSYNC_ENABLED)),
		"fps_cap": int(_selected_option_id(_display_fps_cap_option, 0)),
	}
	return UI_SETTINGS_SCRIPT.sanitize_display_settings(raw)


func _collect_presentation_mode_from_controls() -> String:
	return UI_SETTINGS_SCRIPT.sanitize_presentation_mode(
		str(_selected_option_id(_presentation_mode_option, UI_SETTINGS_SCRIPT.default_presentation_mode()))
	)


func _update_display_mode_hints() -> void:
	_refresh_display_control_enabled_state()
	if _preview_active:
		return
	if not DISPLAY_SETTINGS_SCRIPT.supports_desktop_window_controls():
		_set_status_text("This platform manages window size automatically. Use presentation mode and visual quality options.")
		return
	var mode: String = str(_selected_option_id(_display_mode_option, DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED))
	match mode:
		DISPLAY_SETTINGS_SCRIPT.MODE_BORDERLESS:
			_set_status_text("Borderless uses native monitor resolution. Use resolution scale for render sharpness.")
		DISPLAY_SETTINGS_SCRIPT.MODE_EXCLUSIVE:
			_set_status_text("Exclusive may fallback to borderless on unsupported displays.")
		_:
			_set_status_text("Windowed mode applies selected resolution.")


func _refresh_display_control_enabled_state() -> void:
	var supports_window_controls: bool = DISPLAY_SETTINGS_SCRIPT.supports_desktop_window_controls()
	if _display_monitor_option != null:
		_display_monitor_option.disabled = not supports_window_controls
		_display_monitor_option.tooltip_text = "Managed automatically on this platform." if not supports_window_controls else ""
	if _display_mode_option != null:
		_display_mode_option.disabled = not supports_window_controls
		_display_mode_option.tooltip_text = "Managed automatically on this platform." if not supports_window_controls else ""
	if not supports_window_controls:
		if _display_resolution_option != null:
			_display_resolution_option.disabled = true
			_display_resolution_option.tooltip_text = "Managed automatically on this platform."
		if _display_refresh_option != null:
			_display_refresh_option.disabled = true
			_display_refresh_option.tooltip_text = "Managed automatically on this platform."
		return
	var mode: String = str(_selected_option_id(_display_mode_option, DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED))
	var borderless: bool = mode == DISPLAY_SETTINGS_SCRIPT.MODE_BORDERLESS
	if _display_resolution_option != null:
		_display_resolution_option.disabled = borderless
		_display_resolution_option.tooltip_text = "Unavailable in borderless mode." if borderless else ""
	if _display_refresh_option != null:
		_display_refresh_option.disabled = borderless
		_display_refresh_option.tooltip_text = "Unavailable in borderless mode." if borderless else ""


func _sync_display_platform_capabilities() -> void:
	var supports_window_controls: bool = DISPLAY_SETTINGS_SCRIPT.supports_desktop_window_controls()
	_set_row_visible("DisplayMonitor", supports_window_controls)
	_set_row_visible("DisplayMode", supports_window_controls)
	_set_row_visible("DisplayResolution", supports_window_controls)
	_set_row_visible("DisplayRefreshRate", supports_window_controls)


func _set_row_visible(row_name: String, visible: bool) -> void:
	if settings_list == null:
		return
	var row: Control = settings_list.get_node_or_null(row_name) as Control
	if row != null:
		row.visible = visible


func _build_percent_row(label_text: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = label_text.replace(" ", "")
	row.add_theme_constant_override("separation", 14)
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = label_text
	row.add_child(lbl)

	var spin := SpinBox.new()
	spin.name = "Value"
	spin.min_value = 0.0
	spin.max_value = 100.0
	spin.step = 1.0
	spin.rounded = true
	spin.value = 100.0
	spin.custom_minimum_size = Vector2(138, 0)
	spin.suffix = "%"
	row.add_child(spin)
	return {"row": row, "spin": spin}


func _build_option_row(label_text: String, items: Array) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = label_text.replace(" ", "")
	row.add_theme_constant_override("separation", 14)
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = label_text
	row.add_child(lbl)

	var option := OptionButton.new()
	option.name = "Value"
	option.custom_minimum_size = Vector2(220, 0)
	for item in items:
		var i_label: String = str(item.get("label", "Option"))
		var i_id = item.get("id", i_label.to_lower())
		option.add_item(i_label)
		option.set_item_metadata(option.get_item_count() - 1, i_id)
	row.add_child(option)
	return {"row": row, "option": option}


func _build_toggle_row(label_text: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = label_text.replace(" ", "")
	row.add_theme_constant_override("separation", 14)
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = label_text
	row.add_child(lbl)

	var check := CheckBox.new()
	check.name = "Value"
	check.text = "On"
	check.button_pressed = true
	row.add_child(check)
	return {"row": row, "check": check}


func _selected_option_id(opt: OptionButton, fallback):
	if opt == null or opt.selected < 0 or opt.selected >= opt.get_item_count():
		return fallback
	var md = opt.get_item_metadata(opt.selected)
	return md if md != null else fallback


func _select_option_by_id(opt: OptionButton, target) -> void:
	if opt == null:
		return
	for i in range(opt.get_item_count()):
		var md = opt.get_item_metadata(i)
		if md == target:
			opt.select(i)
			return
	if opt.get_item_count() > 0:
		opt.select(0)


func _clear_option(opt: OptionButton) -> void:
	if opt == null:
		return
	opt.clear()


func _selected_monitor_index() -> int:
	return int(_selected_option_id(_display_monitor_option, 0))


func _selected_resolution() -> Vector2i:
	var fallback := Vector2i(1280, 720)
	var key: String = str(_selected_option_id(_display_resolution_option, _resolution_key(fallback)))
	var parts: PackedStringArray = key.split("x")
	if parts.size() != 2:
		return fallback
	var w: int = int(parts[0])
	var h: int = int(parts[1])
	if w <= 0 or h <= 0:
		return fallback
	return Vector2i(w, h)


func _resolution_key(resolution: Vector2i) -> String:
	return "%dx%d" % [resolution.x, resolution.y]


func _display_settings_equal(a: Dictionary, b: Dictionary) -> bool:
	var left: Dictionary = UI_SETTINGS_SCRIPT.sanitize_display_settings(a)
	var right: Dictionary = UI_SETTINGS_SCRIPT.sanitize_display_settings(b)
	var keys: PackedStringArray = [
		"display_mode",
		"monitor_index",
		"resolution_width",
		"resolution_height",
		"refresh_rate_hz",
		"vsync_mode",
		"fps_cap",
	]
	for key in keys:
		if left.get(key) != right.get(key):
			return false
	return true


func _init_preview_dialog() -> void:
	if _preview_dialog == null:
		_preview_dialog = ConfirmationDialog.new()
		_preview_dialog.name = "DisplayPreviewDialog"
		_preview_dialog.title = "Keep display settings?"
		_preview_dialog.get_ok_button().text = "Keep"
		_preview_dialog.get_cancel_button().text = "Revert"
		_preview_dialog.confirmed.connect(_on_preview_confirmed)
		_preview_dialog.canceled.connect(_on_preview_canceled)
		add_child(_preview_dialog)
	if _preview_timer == null:
		_preview_timer = Timer.new()
		_preview_timer.name = "DisplayPreviewTimer"
		_preview_timer.wait_time = 1.0
		_preview_timer.one_shot = false
		_preview_timer.timeout.connect(_on_preview_tick)
		add_child(_preview_timer)


func _start_display_preview(candidate: Dictionary, previous_runtime: Dictionary) -> void:
	_init_preview_dialog()
	var apply_res: Dictionary = DISPLAY_SETTINGS_SCRIPT.apply_safe(candidate)
	if not bool(apply_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status_text("Display apply failed: %s" % String(apply_res.get("reason", "unknown")), true)
		return
	_preview_active = true
	_preview_previous_display = UI_SETTINGS_SCRIPT.sanitize_display_settings(previous_runtime)
	_preview_candidate_display = UI_SETTINGS_SCRIPT.sanitize_display_settings(apply_res.get("applied", candidate))
	_preview_seconds_left = 15
	_update_preview_dialog_text()
	_preview_dialog.popup_centered(Vector2i(520, 170))
	_preview_timer.start()
	var apply_code: String = String(apply_res.get("code", "applied"))
	var applied_mode: String = str(_preview_candidate_display.get("display_mode", DISPLAY_SETTINGS_SCRIPT.MODE_WINDOWED))
	if applied_mode == DISPLAY_SETTINGS_SCRIPT.MODE_BORDERLESS:
		_set_status_text("Previewing borderless mode (%s). Resolution follows monitor native size." % apply_code)
	else:
		_set_status_text("Previewing display settings (%s). Confirm to keep them." % apply_code)


func _cancel_display_preview(status_text: String) -> void:
	if not _preview_active:
		return
	DISPLAY_SETTINGS_SCRIPT.apply_safe(_preview_previous_display)
	_preview_active = false
	_preview_timer.stop()
	if _preview_dialog != null:
		_preview_dialog.hide()
	_set_status_text(status_text, true)
	_suppress_feedback_audio = true
	for key in _preview_previous_display.keys():
		_ui_settings[key] = _preview_previous_display[key]
	_sync_display_controls_from_settings()
	_suppress_feedback_audio = false


func _on_preview_confirmed() -> void:
	if not _preview_active:
		return
	_preview_active = false
	_preview_timer.stop()
	save_config(_preview_candidate_display)
	_set_status_text("Display settings saved.")
	emit_signal("settings_changed", _config)
	queue_free()


func _on_preview_canceled() -> void:
	_cancel_display_preview("Display changes reverted.")


func _on_preview_tick() -> void:
	if not _preview_active:
		return
	_preview_seconds_left -= 1
	if _preview_seconds_left <= 0:
		_cancel_display_preview("Display preview timed out. Reverted.")
		return
	_update_preview_dialog_text()


func _update_preview_dialog_text() -> void:
	if _preview_dialog == null:
		return
	_preview_dialog.dialog_text = "Keep these display settings? Reverting in %d seconds." % _preview_seconds_left


func _apply_responsive_layout() -> void:
	if _panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var min_size: Vector2 = _style_vector(&"settings_panel_min")
	var max_size: Vector2 = _style_vector(&"settings_panel_max")
	var width: float = clampf(viewport_size.x - 74.0, min_size.x, max_size.x)
	var height: float = clampf(viewport_size.y - 84.0, min_size.y, max_size.y)
	_panel.size = Vector2(width, height)
	_panel.position = (viewport_size - _panel.size) * 0.5


func _style_color(id: StringName) -> Color:
	return MENU_STYLE.color(id)


func _style_scalar(id: StringName) -> float:
	return MENU_STYLE.scalar(id)


func _style_vector(id: StringName) -> Vector2:
	return MENU_STYLE.vector(id)
