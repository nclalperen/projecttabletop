extends Control

class_name SettingsMenu

signal settings_changed(new_config)
signal cancelled

const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")
const VISUAL_QUALITY_SCRIPT: Script = preload("res://ui/services/VisualQualityService.gd")

@onready var settings_list = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList
@onready var initial_open_points = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/InitialOpenPoints/Value
@onready var allow_five_pairs_open = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/AllowFivePairsOpen/Value
@onready var turn_timer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/TurnTimer/Value
@onready var match_end_condition = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndCondition/Value
@onready var match_end_value = $Panel/MarginContainer/VBoxContainer/ScrollContainer/SettingsList/MatchEndValue/Value

@onready var save_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SaveButton
@onready var cancel_button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CancelButton

var _config: RuleConfig
var _ui_settings = null
var _sfx_volume_spin: SpinBox = null
var _music_volume_spin: SpinBox = null
var _graphics_profile_option: OptionButton = null
var _aa_mode_option: OptionButton = null
var _ssao_quality_option: OptionButton = null
var _ssr_enabled_check: CheckBox = null
var _resolution_scale_spin: SpinBox = null
var _postfx_strength_spin: SpinBox = null

func _ready():
	_ui_settings = UI_SETTINGS_SCRIPT.load_from_disk()
	_ensure_visual_rows()
	_ensure_audio_rows()
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	match_end_condition.add_item("Rounds", 0)
	match_end_condition.add_item("Target Score", 1)
	if _config != null:
		load_config()

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
	if _sfx_volume_spin != null and _ui_settings != null:
		_sfx_volume_spin.value = round(float(_ui_settings.get("sfx_volume", 0.82)) * 100.0)
	if _music_volume_spin != null and _ui_settings != null:
		_music_volume_spin.value = round(float(_ui_settings.get("music_volume", 0.30)) * 100.0)
	_sync_visual_controls_from_settings()

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
	if _ui_settings != null:
		var sfx_volume: float = clampf(float(_sfx_volume_spin.value) / 100.0, 0.0, 1.0) if _sfx_volume_spin != null else 0.82
		var music_volume: float = clampf(float(_music_volume_spin.value) / 100.0, 0.0, 1.0) if _music_volume_spin != null else 0.30
		var visual_settings: Dictionary = _collect_visual_settings_from_controls()
		UI_SETTINGS_SCRIPT.save_to_disk(sfx_volume, music_volume, visual_settings)
		_ui_settings["sfx_volume"] = sfx_volume
		_ui_settings["music_volume"] = music_volume
		for key in visual_settings.keys():
			_ui_settings[key] = visual_settings[key]

func _on_save_pressed():
	save_config()
	emit_signal("settings_changed", _config)
	queue_free()

func _on_cancel_pressed():
	emit_signal("cancelled")
	queue_free()


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
	if _ui_settings != null:
		if _sfx_volume_spin != null:
			_sfx_volume_spin.value = round(float(_ui_settings.get("sfx_volume", 0.82)) * 100.0)
		if _music_volume_spin != null:
			_music_volume_spin.value = round(float(_ui_settings.get("music_volume", 0.30)) * 100.0)


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


func _sync_visual_controls_from_settings() -> void:
	if _ui_settings == null:
		_ui_settings = UI_SETTINGS_SCRIPT.default_visual_settings()
	var visual: Dictionary = UI_SETTINGS_SCRIPT.sanitize_visual_settings(_ui_settings)
	_select_option_by_id(_graphics_profile_option, str(visual.get("graphics_profile", VISUAL_QUALITY_SCRIPT.PROFILE_HIGH)))
	_select_option_by_id(_aa_mode_option, str(visual.get("aa_mode", VISUAL_QUALITY_SCRIPT.AA_FXAA)))
	_select_option_by_id(_ssao_quality_option, int(visual.get("ssao_quality", 2)))
	if _ssr_enabled_check != null:
		_ssr_enabled_check.button_pressed = bool(visual.get("ssr_enabled", true))
	if _resolution_scale_spin != null:
		_resolution_scale_spin.value = round(float(visual.get("resolution_scale", 1.0)) * 100.0)
	if _postfx_strength_spin != null:
		_postfx_strength_spin.value = round(float(visual.get("postfx_strength", 0.70)) * 100.0)


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
		"ssr_enabled": _ssr_enabled_check.button_pressed if _ssr_enabled_check != null else true,
		"resolution_scale": (float(_resolution_scale_spin.value) / 100.0) if _resolution_scale_spin != null else 1.0,
		"postfx_strength": (float(_postfx_strength_spin.value) / 100.0) if _postfx_strength_spin != null else 0.70,
	}
	return UI_SETTINGS_SCRIPT.sanitize_visual_settings(raw)


func _build_percent_row(label_text: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = label_text.replace(" ", "")
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = label_text
	row.add_child(lbl)

	var spin := SpinBox.new()
	spin.min_value = 0.0
	spin.max_value = 100.0
	spin.step = 1.0
	spin.rounded = true
	spin.value = 100.0
	spin.custom_minimum_size = Vector2(100, 0)
	spin.suffix = "%"
	row.add_child(spin)
	return {"row": row, "spin": spin}


func _build_option_row(label_text: String, items: Array) -> Dictionary:
	var row := HBoxContainer.new()
	row.name = label_text.replace(" ", "")
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = label_text
	row.add_child(lbl)

	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(160, 0)
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
	var lbl := Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = label_text
	row.add_child(lbl)

	var check := CheckBox.new()
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
