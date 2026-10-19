extends Control

## Party-game main menu: a 2D HUD floating over a live 3D table backdrop.
## The HUD owns the left 40% action zone; the right 60% stays open for the scene.

signal cta_hovered
signal cta_pressed

const SETTINGS_MENU_SCENE_PATH: String = "res://ui/SettingsMenu.tscn"
const ONLINE_LOBBY_SCENE_PATH: String = "res://ui/OnlineLobby.tscn"
const BACKDROP_SCENE_PATH: String = "res://ui/menu_backdrop/MenuBackdrop3D.tscn"
const GLASS_SHADER_PATH: String = "res://ui/shaders/glass_blur.gdshader"
const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const RULE_CONFIG_SCRIPT_PATH: String = "res://core/rules/RuleConfig.gd"
const MENU_AUDIO_SERVICE_SCRIPT: Script = preload("res://ui/services/MenuAudioService.gd")
const UI_SETTINGS_SCRIPT: Script = preload("res://ui/services/UISettings.gd")
const DISPLAY_SETTINGS_SCRIPT: Script = preload("res://ui/services/DisplaySettingsService.gd")
const PLATFORM_PROFILE_SCRIPT: Script = preload("res://ui/services/PlatformProfile.gd")
const VISUAL_QUALITY: Script = preload("res://ui/services/VisualQualityService.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const PLAYER_PROFILE: Script = preload("res://ui/services/PlayerProfile.gd")
const GAME_CATALOG: Script = preload("res://gd/config/TabletopGameCatalog.gd")
const INPUT_PROMPT_SCENE: PackedScene = preload("res://ui/widgets/InputPromptBadge.tscn")

const AVATAR_IDS: Array[StringName] = [
	ASSET_IDS.UI_AVATAR_FACE_1,
	ASSET_IDS.UI_AVATAR_FACE_2,
	ASSET_IDS.UI_AVATAR_FACE_3,
	ASSET_IDS.UI_AVATAR_FACE_4,
]

## Featured party modes, in display order. Titles use the table's local name.
const MODE_CARDS: Array[Dictionary] = [
	{"id": &"okey101", "title": "Okey 101", "chaos": "Joker Rain", "icon": ASSET_IDS.UI_ICON_CARDS_STACK},
	{"id": &"backgammon", "title": "Tavla", "chaos": "Double Dice", "icon": ASSET_IDS.UI_ICON_PAWNS},
	{"id": &"poker", "title": "Poker", "chaos": "All-In Frenzy", "icon": ASSET_IDS.UI_ICON_CARD_ADD},
	{"id": &"chess", "title": "Satranç", "chaos": "Blitz Clock", "icon": ASSET_IDS.UI_ICON_CROWN_A},
]

const EMOTE_LINES: Array[String] = ["Hadi, masaya!", "101!", "GG!", "Okey var mı?", "Let's party!", "Bir el daha?"]
const REACTION_LINES: Array[String] = ["+1", "WOW", "Hahaha", "Ooo!"]

@onready var _banner: Node = $StatusBanner
@onready var _background: TextureRect = $Background
@onready var _viewport_container: SubViewportContainer = $BackdropViewportContainer
@onready var _sub_viewport: SubViewport = $BackdropViewportContainer/SubViewport
@onready var _left_scrim: TextureRect = $LeftScrim
@onready var _emote_layer: Control = $EmoteLayer
@onready var _hud: MarginContainer = $HUD
@onready var _profile_pill: PanelContainer = $HUD/HUDColumn/TopBar/ProfilePill
@onready var _avatar_frame: PanelContainer = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/AvatarFrame
@onready var _avatar: TextureRect = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/AvatarFrame/Avatar
@onready var _nickname: Label = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/ProfileText/Nickname
@onready var _leader_badge: PanelContainer = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/ProfileText/BadgeRow/LeaderBadge
@onready var _crown_icon: TextureRect = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/ProfileText/BadgeRow/LeaderBadge/LeaderRow/CrownIcon
@onready var _leader_label: Label = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/ProfileText/BadgeRow/LeaderBadge/LeaderRow/LeaderLabel
@onready var _status_dot: Panel = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/ProfileText/BadgeRow/StatusDot
@onready var _status_label: Label = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/ProfileText/BadgeRow/StatusLabel
@onready var _login_btn: Button = $HUD/HUDColumn/TopBar/ProfilePill/ProfileRow/LoginButton
@onready var _party_tray: PanelContainer = $HUD/HUDColumn/TopBar/PartyTray
@onready var _invite_button: Button = $HUD/HUDColumn/TopBar/PartyTray/TrayRow/InviteButton
@onready var _mic_toggle: Button = $HUD/HUDColumn/TopBar/PartyTray/TrayRow/MicToggle
@onready var _settings_button: Button = $HUD/HUDColumn/TopBar/PartyTray/TrayRow/SettingsButton
@onready var _quit_button: Button = $HUD/HUDColumn/TopBar/PartyTray/TrayRow/QuitButton
@onready var _game_logo: VBoxContainer = $HUD/HUDColumn/BodySplit/ActionZone/GameLogo
@onready var _logo_top: Label = $HUD/HUDColumn/BodySplit/ActionZone/GameLogo/LogoTop
@onready var _logo_bottom: Label = $HUD/HUDColumn/BodySplit/ActionZone/GameLogo/LogoBottom
@onready var _modes_header: Label = $HUD/HUDColumn/BodySplit/ActionZone/ModesHeader
@onready var _mode_grid: GridContainer = $HUD/HUDColumn/BodySplit/ActionZone/ModeCards
@onready var _settings_summary: Label = $HUD/HUDColumn/BodySplit/ActionZone/SettingsSummary
@onready var _start_button: Button = $HUD/HUDColumn/BodySplit/ActionZone/StartButton
@onready var _cta_title: Label = $HUD/HUDColumn/BodySplit/ActionZone/StartButton/CTAContent/CTATitle
@onready var _cta_sub: Label = $HUD/HUDColumn/BodySplit/ActionZone/StartButton/CTAContent/CTASub
@onready var _customize_button: Button = $HUD/HUDColumn/BodySplit/ActionZone/SecondaryRow/CustomizeButton
@onready var _rules_button: Button = $HUD/HUDColumn/BodySplit/ActionZone/SecondaryRow/RulesButton

# Game configuration
var selected_game_id: StringName = GAME_CATALOG.default_game_id()
var player_count: int = GAME_CATALOG.default_player_count(GAME_CATALOG.default_game_id())
var game_seed: int = -1  # -1 means random
var rule_config = null
var presentation_mode: String = PLATFORM_PROFILE_SCRIPT.default_presentation_mode()

var _animations_enabled: bool = true
var _reduced_motion: bool = false
var _blur_enabled: bool = false
var _visual_settings: Dictionary = {}
var _menu_audio = null
var _online_available: bool = false
var _logged_in: bool = false
var _display_font: Font = null
var _body_font: Font = null
var _glass_material: ShaderMaterial = null
var _backdrop: Node3D = null
var _mode_buttons: Dictionary = {}
var _mode_chaos_labels: Array[Label] = []
var _juice_tweens: Dictionary = {}
var _cta_glow: Panel = null
var _emote_bubbles: Array[Control] = []
var _emote_timer: float = 0.0
var _emote_index: int = 0
var _time: float = 0.0


func _make_rule_config():
	var rule_config_script: Script = load(RULE_CONFIG_SCRIPT_PATH)
	if rule_config_script != null and rule_config_script.can_instantiate():
		return rule_config_script.new()
	return null


func _ready() -> void:
	if _menu_audio == null:
		_menu_audio = MENU_AUDIO_SERVICE_SCRIPT.new()
		_menu_audio.name = "MenuAudioService"
		add_child(_menu_audio)
	PLAYER_PROFILE.ensure_loaded()
	rule_config = _make_rule_config()

	var ui_settings: Dictionary = UI_SETTINGS_SCRIPT.load_from_disk()
	_sync_presentation_mode_from_settings(ui_settings)
	_apply_runtime_display_settings(ui_settings)
	_visual_settings = VISUAL_QUALITY.sanitize(ui_settings)
	_reduced_motion = bool(ui_settings.get("reduced_motion", false))
	_blur_enabled = _should_enable_blur()

	_load_fonts()
	_setup_backdrop()
	_style_hud()
	_build_mode_cards()
	_build_cta_extras()
	_build_emote_bubbles()
	_connect_signals()
	_wire_focus()
	_probe_online()
	_refresh_profile()
	_apply_selected_game_state()
	_apply_responsive_layout()

	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "")
	_animate_menu_in()
	if not Input.get_connected_joypads().is_empty():
		_start_button.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	_update_emote_bubbles(delta)


# ═══════════════════════════════════════════
# 3D BACKDROP
# ═══════════════════════════════════════════

func _setup_backdrop() -> void:
	var headless: bool = DisplayServer.get_name() == "headless"
	if headless:
		_viewport_container.visible = false
		_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	var scene: PackedScene = load(BACKDROP_SCENE_PATH)
	if scene == null:
		_viewport_container.visible = false
		return
	VISUAL_QUALITY.apply_to_viewport(_sub_viewport, _visual_settings)
	_backdrop = scene.instantiate() as Node3D
	if _backdrop == null:
		_viewport_container.visible = false
		return
	_backdrop.set("visual_settings", _visual_settings)
	_backdrop.set("camera_h_offset", _style_scalar(&"party_backdrop_h_offset"))
	if _reduced_motion:
		_backdrop.set("orbit_degrees", 0.0)
	_sub_viewport.add_child(_backdrop)
	if _backdrop.has_method("play_wave"):
		cta_hovered.connect(Callable(_backdrop, "play_wave"))
	if _backdrop.has_method("play_cheer"):
		cta_pressed.connect(Callable(_backdrop, "play_cheer"))


func _pause_backdrop() -> void:
	if _backdrop != null and _backdrop.has_method("set_paused"):
		_backdrop.call("set_paused", true)
	if _sub_viewport != null:
		_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _should_enable_blur() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	if OS.has_feature("web") or OS.has_feature("mobile"):
		return false
	var profile: String = str(_visual_settings.get("graphics_profile", "medium"))
	return profile == VISUAL_QUALITY.PROFILE_HIGH or profile == VISUAL_QUALITY.PROFILE_ULTRA


# ═══════════════════════════════════════════
# STYLING
# ═══════════════════════════════════════════

func _load_fonts() -> void:
	_display_font = ASSET_REGISTRY.font(ASSET_IDS.UI_FONT_KENNEY_FUTURE)
	_body_font = ASSET_REGISTRY.font(ASSET_IDS.UI_FONT_BARLOW_CONDENSED_BOLD)
	if _body_font == null:
		_body_font = _display_font


func _font_for(text: String, prefer_display: bool) -> Font:
	if prefer_display and _display_font != null and _font_covers(_display_font, text):
		return _display_font
	return _body_font


func _font_covers(font: Font, text: String) -> bool:
	for i in range(text.length()):
		var code: int = text.unicode_at(i)
		if code == 32:
			continue
		if not font.has_char(code):
			return false
	return true


func _style_label(label: Label, text: String, size: int, color: Color, display: bool = false, outline: int = 0) -> void:
	if label == null:
		return
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font: Font = _font_for(text, display)
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", _style_color(&"party_ink"))


func _flat(fill: Color, border: Color, border_width: int, radius: int, depth: int = 0, depth_color: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 10
	sb.anti_aliasing = true
	if depth > 0:
		sb.shadow_color = depth_color
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, depth)
	return sb


func _glass_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := _flat(fill, border, border_width, radius)
	sb.border_width_bottom = int(_style_scalar(&"party_bevel_width"))
	if not _blur_enabled:
		# Without the blur shader, deepen the fill so text stays legible over the 3D scene.
		sb.bg_color = Color(fill.r, fill.g, fill.b, minf(fill.a + 0.3, 0.9))
	return sb


func _apply_glass(item: CanvasItem) -> void:
	if not _blur_enabled or item == null:
		return
	if _glass_material == null:
		var shader: Shader = load(GLASS_SHADER_PATH)
		if shader == null:
			_blur_enabled = false
			return
		_glass_material = ShaderMaterial.new()
		_glass_material.shader = shader
		_glass_material.set_shader_parameter("blur_lod", _style_scalar(&"party_blur_lod"))
	item.material = _glass_material


func _set_button_styles(button: Button, fill: Color, border: Color, radius: int, depth: int, depth_color: Color, font_color: Color) -> void:
	var border_width: int = int(_style_scalar(&"party_border_width"))
	var normal := _flat(fill, border, border_width, radius, depth, depth_color)
	var hover := _flat(fill.lightened(0.1), border, border_width, radius, depth, depth_color)
	var pressed := _flat(fill.darkened(0.1), border, border_width, radius, maxi(1, depth / 3), depth_color)
	pressed.content_margin_top = float(depth - maxi(1, depth / 3))
	var disabled := _flat(fill.darkened(0.4), border.darkened(0.4), border_width, radius)
	var focus := _focus_ring(radius)
	for pair in [["normal", normal], ["hover", hover], ["pressed", pressed], ["hover_pressed", pressed], ["disabled", disabled], ["focus", focus]]:
		button.add_theme_stylebox_override(pair[0], pair[1])
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(key, font_color)
	button.add_theme_color_override("icon_normal_color", font_color)
	button.add_theme_color_override("icon_hover_color", font_color)
	button.add_theme_color_override("icon_pressed_color", font_color)
	button.add_theme_color_override("icon_focus_color", font_color)
	if _body_font != null:
		button.add_theme_font_override("font", _body_font)


func _focus_ring(radius: int) -> StyleBoxFlat:
	var ring := _flat(Color(0, 0, 0, 0), _style_color(&"party_teal"), 4, radius + 6)
	ring.draw_center = false
	ring.set_expand_margin_all(6.0)
	return ring


func _style_hud() -> void:
	var hud_margin: Vector2 = _style_vector(&"party_hud_margin")
	for side in ["left", "right"]:
		_hud.add_theme_constant_override("margin_" + side, int(hud_margin.x))
	for side in ["top", "bottom"]:
		_hud.add_theme_constant_override("margin_" + side, int(hud_margin.y))

	if _background != null:
		_background.visible = _backdrop == null
	if _left_scrim != null:
		_left_scrim.modulate = Color(1, 1, 1, 1.0 if _backdrop != null else 0.6)

	var cream: Color = _style_color(&"party_cream")
	var ink: Color = _style_color(&"party_ink")
	var amber: Color = _style_color(&"party_amber")
	var teal: Color = _style_color(&"party_teal")
	var border_width: int = int(_style_scalar(&"party_border_width"))
	var pill_radius: int = int(_style_scalar(&"party_pill_radius"))

	# Profile pill
	var profile_style := _glass_style(_style_color(&"party_glass"), cream, border_width, pill_radius)
	profile_style.content_margin_left = 8
	profile_style.content_margin_right = 22
	profile_style.content_margin_top = 8
	profile_style.content_margin_bottom = 8
	_profile_pill.add_theme_stylebox_override("panel", profile_style)
	_apply_glass(_profile_pill)
	var avatar_size: Vector2 = _style_vector(&"party_avatar")
	_avatar_frame.custom_minimum_size = avatar_size
	_avatar_frame.add_theme_stylebox_override("panel", _flat(teal, teal, 0, int(avatar_size.x * 0.5)))
	_style_label(_nickname, PLAYER_PROFILE.display_name, 26, cream)
	var leader_style := _flat(amber, amber, 0, 12)
	leader_style.content_margin_left = 8
	leader_style.content_margin_right = 10
	leader_style.content_margin_top = 1
	leader_style.content_margin_bottom = 1
	_leader_badge.add_theme_stylebox_override("panel", leader_style)
	_crown_icon.texture = _texture(ASSET_IDS.UI_ICON_CROWN_A)
	_crown_icon.modulate = ink
	_style_label(_leader_label, "PARTY LEADER", 14, ink)
	_style_label(_status_label, "Offline", 16, cream.darkened(0.15))

	# Party tray
	var tray_style := _glass_style(_style_color(&"party_glass"), cream, border_width, pill_radius)
	tray_style.set_content_margin_all(8)
	tray_style.content_margin_bottom = 12
	_party_tray.add_theme_stylebox_override("panel", tray_style)
	_apply_glass(_party_tray)
	var tray_size: Vector2 = _style_vector(&"party_tray_button")
	var tray_depth: int = int(_style_scalar(&"party_button_depth")) - 2
	for button in [_invite_button, _mic_toggle, _settings_button, _quit_button]:
		button.custom_minimum_size = tray_size
		button.pivot_offset = tray_size * 0.5
		_set_button_styles(button, cream, cream, int(tray_size.x * 0.5), tray_depth, cream.darkened(0.45), ink)
		button.add_theme_font_size_override("font_size", 18)
	_invite_button.add_theme_font_size_override("font_size", 34)
	_set_button_styles(_quit_button, _style_color(&"party_danger"), cream, int(tray_size.x * 0.5), tray_depth, _style_color(&"party_danger").darkened(0.45), cream)
	_settings_button.icon = _texture(ASSET_IDS.UI_ICON_GEAR)
	_quit_button.icon = _texture(ASSET_IDS.UI_ICON_CROSS)
	for button in [_settings_button, _quit_button]:
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		for key in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var sb: StyleBox = button.get_theme_stylebox(key)
			if sb != null:
				sb.set_content_margin_all(14)

	# Login pill
	_set_button_styles(_login_btn, teal, cream, 18, 4, teal.darkened(0.45), ink)
	_login_btn.add_theme_font_size_override("font_size", 18)
	_login_btn.custom_minimum_size = Vector2(96, 40)

	# Logo
	var logo_rotation: float = deg_to_rad(_style_scalar(&"party_logo_rotation_deg"))
	_game_logo.rotation = 0.0 if _reduced_motion else logo_rotation
	_style_label(_logo_top, "TABLETOP PARTY", 30, cream, true, 8)
	_style_label(_logo_bottom, "101 OKEY", 96, amber, true, 14)
	_logo_bottom.add_theme_color_override("font_shadow_color", _style_color(&"party_amber_deep"))
	_logo_bottom.add_theme_constant_override("shadow_offset_x", 0)
	_logo_bottom.add_theme_constant_override("shadow_offset_y", 8)
	_logo_bottom.add_theme_constant_override("shadow_outline_size", 14)

	_style_label(_modes_header, "OYUN SEÇ  ·  PICK A GAME", 20, cream.darkened(0.1))
	_style_label(_settings_summary, "", 19, cream.darkened(0.2))

	# Big CTA
	var cta_min: Vector2 = _style_vector(&"party_cta_min")
	_start_button.custom_minimum_size = cta_min
	var cta_depth: int = int(_style_scalar(&"party_cta_depth"))
	_set_button_styles(_start_button, amber, cream, 30, cta_depth, _style_color(&"party_amber_deep"), ink)
	_start_button.text = ""
	_style_label(_cta_title, "MASAYA OTUR", 46, ink, true)
	_style_label(_cta_sub, "PLAY NOW", 18, ink.lightened(0.15), true)

	# Secondary pills
	var pill_min: Vector2 = _style_vector(&"party_pill_min")
	for pair in [[_customize_button, "Karakter Stüdyosu", "CUSTOMIZE"], [_rules_button, "Masa Ayarları", "TABLE RULES"]]:
		var button: Button = pair[0]
		button.custom_minimum_size = pill_min
		button.text = ""
		var glass_fill: Color = _style_color(&"party_glass")
		var style := _glass_style(glass_fill, cream, border_width, pill_radius)
		var hover := _glass_style(_style_color(&"party_glass_hover"), cream, border_width, pill_radius)
		var pressed := _glass_style(_style_color(&"party_glass_selected"), teal, border_width, pill_radius)
		for key_style in [["normal", style], ["hover", hover], ["pressed", pressed], ["hover_pressed", pressed], ["disabled", style], ["focus", _focus_ring(pill_radius)]]:
			button.add_theme_stylebox_override(key_style[0], key_style[1])
		_apply_glass(button)
		_stack_button_labels(button, pair[1], pair[2], 24, 13)


func _stack_button_labels(button: Button, title: String, subtitle: String, title_size: int, subtitle_size: int) -> void:
	var box := VBoxContainer.new()
	box.name = "Content"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", -2)
	button.add_child(box)
	var title_label := Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(title_label, title, title_size, _style_color(&"party_cream"))
	box.add_child(title_label)
	var sub_label := Label.new()
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label(sub_label, subtitle, subtitle_size, _style_color(&"party_teal"))
	box.add_child(sub_label)
	button.tooltip_text = "%s (%s)" % [title, subtitle.capitalize()]


# ═══════════════════════════════════════════
# MODE CARDS
# ═══════════════════════════════════════════

func _build_mode_cards() -> void:
	for child in _mode_grid.get_children():
		child.queue_free()
	_mode_buttons.clear()
	_mode_chaos_labels.clear()
	var group := ButtonGroup.new()
	var cream: Color = _style_color(&"party_cream")
	var teal: Color = _style_color(&"party_teal")
	var ink: Color = _style_color(&"party_ink")
	var radius: int = int(_style_scalar(&"party_corner_radius"))
	var border_width: int = int(_style_scalar(&"party_border_width"))
	var card_min: Vector2 = _style_vector(&"party_card_min")
	var available: Array = GAME_CATALOG.all_game_ids()

	for entry in MODE_CARDS:
		var game_id: StringName = entry["id"]
		if not available.has(game_id):
			continue
		var card := Button.new()
		card.name = "ModeCard_%s" % String(game_id)
		card.toggle_mode = true
		card.button_group = group
		card.custom_minimum_size = card_min
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = GAME_CATALOG.description(game_id)
		card.pivot_offset = card_min * 0.5
		var normal := _glass_style(_style_color(&"party_glass"), cream, border_width, radius)
		var hover := _glass_style(_style_color(&"party_glass_hover"), cream, border_width, radius)
		var selected := _glass_style(_style_color(&"party_glass_selected"), teal, border_width + 1, radius)
		for key_style in [["normal", normal], ["hover", hover], ["pressed", selected], ["hover_pressed", selected], ["disabled", normal], ["focus", _focus_ring(radius)]]:
			card.add_theme_stylebox_override(key_style[0], key_style[1])
		_apply_glass(card)

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side in ["left", "right", "top"]:
			margin.add_theme_constant_override("margin_" + side, 14)
		margin.add_theme_constant_override("margin_bottom", 18)
		card.add_child(margin)
		var col := VBoxContainer.new()
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_theme_constant_override("separation", 6)
		margin.add_child(col)

		var icon := TextureRect.new()
		icon.texture = _texture(entry["icon"])
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		icon.modulate = cream
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(icon)

		var title := Label.new()
		_style_label(title, String(entry["title"]), 28, cream)
		col.add_child(title)

		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var badge_style := _flat(_style_color(&"party_lime"), _style_color(&"party_lime"), 0, 10)
		badge_style.content_margin_left = 8
		badge_style.content_margin_right = 8
		badge.add_theme_stylebox_override("panel", badge_style)
		var badge_label := Label.new()
		_style_label(badge_label, GAME_CATALOG.player_count_summary(game_id).to_upper(), 14, ink)
		badge.add_child(badge_label)
		col.add_child(badge)

		var chaos := Label.new()
		_style_label(chaos, "★ " + String(entry["chaos"]) if _body_font != null and _body_font.has_char(9733) else String(entry["chaos"]), 16, teal)
		chaos.clip_text = true
		col.add_child(chaos)
		_mode_chaos_labels.append(chaos)

		card.pressed.connect(_on_game_selected.bind(game_id))
		_attach_juice(card, _style_scalar(&"party_card_hover_scale"))
		_mode_grid.add_child(card)
		_mode_buttons[String(game_id)] = card


# ═══════════════════════════════════════════
# CTA + JUICE
# ═══════════════════════════════════════════

func _build_cta_extras() -> void:
	_cta_glow = Panel.new()
	_cta_glow.name = "CTAGlow"
	_cta_glow.show_behind_parent = true
	_cta_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cta_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	var glow := _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 34)
	glow.shadow_color = Color(_style_color(&"party_amber"), 0.55)
	glow.shadow_size = 26
	_cta_glow.add_theme_stylebox_override("panel", glow)
	_start_button.add_child(_cta_glow)

	var prompt := INPUT_PROMPT_SCENE.instantiate()
	prompt.name = "CTAPrompt"
	_start_button.add_child(prompt)
	if prompt.has_method("configure"):
		prompt.call("configure", _texture(ASSET_IDS.UI_PROMPT_ENTER), "")
	if prompt is Control:
		var prompt_control := prompt as Control
		prompt_control.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		prompt_control.offset_left = -78
		prompt_control.offset_right = -22
		prompt_control.offset_top = -24
		prompt_control.offset_bottom = 24
		_ignore_mouse_recursive(prompt_control)

	_attach_juice(_start_button, _style_scalar(&"party_hover_scale"))
	if not _reduced_motion:
		var period: float = _style_scalar(&"party_glow_period")
		var pulse := create_tween().set_loops()
		pulse.tween_property(_cta_glow, "modulate:a", 0.35, period * 0.5).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(_cta_glow, "modulate:a", 1.0, period * 0.5).set_trans(Tween.TRANS_SINE)


func _ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse_recursive(child)


func _attach_juice(control: Control, hover_scale: float) -> void:
	control.mouse_entered.connect(_juice_hover.bind(control, hover_scale, true))
	control.mouse_exited.connect(_juice_hover.bind(control, hover_scale, false))
	control.focus_entered.connect(_juice_hover.bind(control, hover_scale, true))
	control.focus_exited.connect(_juice_hover.bind(control, hover_scale, false))
	control.resized.connect(func(): control.pivot_offset = control.size * 0.5)
	if control is BaseButton:
		(control as BaseButton).button_down.connect(_juice_press.bind(control))


func _juice_tween(control: Control) -> Tween:
	var key: int = control.get_instance_id()
	var existing: Tween = _juice_tweens.get(key)
	if existing != null and existing.is_valid():
		existing.kill()
	var tween := create_tween()
	_juice_tweens[key] = tween
	return tween


func _juice_hover(control: Control, hover_scale: float, entering: bool) -> void:
	if _reduced_motion or control == null:
		return
	var tween := _juice_tween(control)
	var duration: float = _style_scalar(&"party_hover_duration")
	tween.set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_scale: float = hover_scale if entering else 1.0
	tween.tween_property(control, "scale", Vector2(target_scale, target_scale), duration)
	var tilt: float = deg_to_rad(_style_scalar(&"party_hover_tilt_deg")) if entering else 0.0
	tween.tween_property(control, "rotation", tilt, duration)


func _juice_press(control: Control) -> void:
	if _reduced_motion or control == null:
		return
	var tween := _juice_tween(control)
	var duration: float = _style_scalar(&"party_press_duration")
	control.scale = Vector2(0.92, 0.92)
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration)


func _animate_menu_in() -> void:
	if _reduced_motion or not _animations_enabled:
		return
	_hud.modulate = Color(1, 1, 1, 0)
	var fade := create_tween()
	fade.tween_property(_hud, "modulate:a", 1.0, 0.3)
	var delay: float = 0.08
	for card in _mode_buttons.values():
		var control: Control = card
		control.scale = Vector2(0.85, 0.85)
		var pop := create_tween()
		pop.tween_interval(delay)
		pop.tween_property(control, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.06


# ═══════════════════════════════════════════
# EMOTE BUBBLES (projected from 3D anchors)
# ═══════════════════════════════════════════

func _build_emote_bubbles() -> void:
	if _backdrop == null or not _backdrop.has_method("get_emote_anchors"):
		return
	var anchors: Array = _backdrop.call("get_emote_anchors")
	for i in range(anchors.size()):
		var bubble := _make_bubble(EMOTE_LINES[0] if i == 0 else REACTION_LINES[0], i == 0)
		bubble.set_meta("anchor", anchors[i])
		bubble.set_meta("phase", float(i) * 1.7)
		_emote_layer.add_child(bubble)
		_emote_bubbles.append(bubble)


func _make_bubble(text: String, large: bool) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body := PanelContainer.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill: Color = _style_color(&"party_cream") if large else _style_color(&"party_teal")
	var style := _flat(fill, _style_color(&"party_ink"), 3, 22, 5, _style_color(&"party_ink"))
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	body.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.name = "Text"
	_style_label(label, text, 30 if large else 22, _style_color(&"party_ink"), false)
	body.add_child(label)
	var tail := Panel.new()
	tail.name = "Tail"
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.size = Vector2(18, 18)
	tail.pivot_offset = Vector2(9, 9)
	tail.rotation = PI * 0.25
	tail.show_behind_parent = false
	var tail_style := _flat(fill, _style_color(&"party_ink"), 3, 3)
	tail.add_theme_stylebox_override("panel", tail_style)
	root.add_child(tail)
	root.add_child(body)
	_layout_bubble(root)
	return root


func _layout_bubble(root: Control) -> void:
	var body := root.get_node("Body") as PanelContainer
	var tail := root.get_node("Tail") as Panel
	body.reset_size()
	body.size = body.get_combined_minimum_size()
	root.size = body.size
	tail.position = Vector2(body.size.x * 0.5 - 9.0, body.size.y - 14.0)


func _set_bubble_text(root: Control, text: String) -> void:
	var label := root.get_node("Body/Text") as Label
	label.text = text
	var font: Font = _font_for(text, false)
	if font != null:
		label.add_theme_font_override("font", font)
	_layout_bubble(root)
	root.pivot_offset = Vector2(root.size.x * 0.5, root.size.y)
	if not _reduced_motion:
		root.scale = Vector2(0.4, 0.4)
		var pop := create_tween()
		pop.tween_property(root, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _update_emote_bubbles(delta: float) -> void:
	if _emote_bubbles.is_empty() or _backdrop == null:
		return
	var camera: Camera3D = _backdrop.call("get_camera") if _backdrop.has_method("get_camera") else null
	if camera == null:
		return
	_emote_timer += delta
	if _emote_timer >= _style_scalar(&"party_emote_interval"):
		_emote_timer = 0.0
		_emote_index += 1
		_set_bubble_text(_emote_bubbles[0], EMOTE_LINES[_emote_index % EMOTE_LINES.size()])
		if _emote_bubbles.size() > 1 and _emote_index % 2 == 0:
			_set_bubble_text(_emote_bubbles[1], REACTION_LINES[(_emote_index / 2) % REACTION_LINES.size()])

	var viewport_size := Vector2(_sub_viewport.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var ratio: Vector2 = _viewport_container.size / viewport_size
	var bob_amount: float = 0.0 if _reduced_motion else _style_scalar(&"party_emote_bob")
	for bubble in _emote_bubbles:
		var anchor := bubble.get_meta("anchor") as Node3D
		if anchor == null or not is_instance_valid(anchor):
			bubble.visible = false
			continue
		var world_pos: Vector3 = anchor.global_position
		if camera.is_position_behind(world_pos):
			bubble.visible = false
			continue
		bubble.visible = true
		var screen: Vector2 = camera.unproject_position(world_pos) * ratio
		var bob: float = sin(_time * 2.4 + float(bubble.get_meta("phase"))) * bob_amount
		bubble.position = screen - Vector2(bubble.size.x * 0.5, bubble.size.y + 12.0 + bob)


# ═══════════════════════════════════════════
# SIGNALS + FOCUS
# ═══════════════════════════════════════════

func _connect_signals() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.mouse_entered.connect(_on_cta_hovered)
	_start_button.focus_entered.connect(_on_cta_hovered)
	_settings_button.pressed.connect(_on_settings_pressed)
	_rules_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_invite_button.pressed.connect(_on_invite_pressed)
	_mic_toggle.toggled.connect(_on_mic_toggled)
	_customize_button.pressed.connect(_on_customize_pressed)
	_login_btn.pressed.connect(_on_login_pressed)
	if _menu_audio != null:
		for button in [_invite_button, _settings_button, _customize_button, _rules_button, _login_btn]:
			_menu_audio.bind_button(button)
		_menu_audio.bind_button(_mic_toggle, true)
		for card in _mode_buttons.values():
			_menu_audio.bind_button(card, true)
		_quit_button.mouse_entered.connect(_menu_audio.play_hover)
	for button in [_invite_button, _mic_toggle, _settings_button, _quit_button, _customize_button, _rules_button]:
		_attach_juice(button, _style_scalar(&"party_hover_scale"))


func _wire_focus() -> void:
	var tray: Array[Control] = [_invite_button, _mic_toggle, _settings_button, _quit_button]
	var cards: Array[Control] = []
	for card in _mode_buttons.values():
		cards.append(card)
	var first_card: Control = cards[0] if not cards.is_empty() else _start_button
	for button in tray:
		button.focus_neighbor_bottom = button.get_path_to(first_card)
	for card in cards:
		card.focus_neighbor_top = card.get_path_to(_settings_button)
		card.focus_neighbor_bottom = card.get_path_to(_start_button)
	_start_button.focus_neighbor_top = _start_button.get_path_to(first_card)
	_start_button.focus_neighbor_bottom = _start_button.get_path_to(_customize_button)
	for button in [_customize_button, _rules_button]:
		button.focus_neighbor_top = button.get_path_to(_start_button)


func _on_cta_hovered() -> void:
	if _menu_audio != null:
		_menu_audio.play_hover()
	cta_hovered.emit()


# ═══════════════════════════════════════════
# PROFILE + ONLINE STATUS
# ═══════════════════════════════════════════

func _probe_online() -> void:
	var online_service = ONLINE_SERVICE_SCRIPT.new()
	var init_res: Dictionary = online_service.initialize()
	online_service.free()
	_online_available = bool(init_res.get("ok", false))
	if not _online_available:
		_invite_button.tooltip_text = "Invite friends (%s)" % String(init_res.get("reason", "online unavailable"))


func _refresh_profile() -> void:
	var avatar_id: StringName = AVATAR_IDS[posmod(PLAYER_PROFILE.avatar_index, AVATAR_IDS.size())]
	_avatar.texture = _texture(avatar_id)
	_nickname.text = PLAYER_PROFILE.display_name
	_update_online_status_display()


func _update_online_status_display() -> void:
	if _status_dot == null:
		return
	var dot_color: Color
	if not _online_available:
		dot_color = _style_color(&"party_danger")
		_status_label.text = "Offline"
		_login_btn.visible = false
	elif not _logged_in:
		dot_color = _style_color(&"party_amber")
		_status_label.text = "Not logged in"
		_login_btn.visible = true
	else:
		dot_color = _style_color(&"party_lime")
		_status_label.text = "Online"
		_login_btn.visible = false
	_status_dot.add_theme_stylebox_override("panel", _flat(dot_color, dot_color, 0, 6))


func _on_login_pressed() -> void:
	# The online lobby owns the EOS login flow.
	_open_selected_game_lobby()


# ═══════════════════════════════════════════
# GAME SELECTION
# ═══════════════════════════════════════════

func _on_game_selected(game_id: StringName) -> void:
	selected_game_id = game_id
	player_count = GAME_CATALOG.default_player_count(selected_game_id)
	_apply_selected_game_state()


func _apply_selected_game_state() -> void:
	for key in _mode_buttons.keys():
		var card: Button = _mode_buttons[key]
		if card != null:
			card.set_pressed_no_signal(key == String(selected_game_id))
	_refresh_settings_summary()
	_update_online_status_display()


# ═══════════════════════════════════════════
# BUTTON HANDLERS
# ═══════════════════════════════════════════

func _on_start_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	cta_pressed.emit()
	_open_selected_game_lobby()


func _on_invite_pressed() -> void:
	_open_selected_game_lobby()


func _on_mic_toggled(muted: bool) -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, muted)
	_mic_toggle.text = "OFF" if muted else "MIC"
	var fill: Color = _style_color(&"party_danger") if muted else _style_color(&"party_cream")
	var font_color: Color = _style_color(&"party_cream") if muted else _style_color(&"party_ink")
	var size: Vector2 = _style_vector(&"party_tray_button")
	var depth: int = int(_style_scalar(&"party_button_depth")) - 2
	_set_button_styles(_mic_toggle, fill, _style_color(&"party_cream"), int(size.x * 0.5), depth, fill.darkened(0.45), font_color)


func _on_customize_pressed() -> void:
	cta_hovered.emit()
	_show_banner("Karakter Stüdyosu is coming soon. Your player is already waiting at the table.")


func _open_selected_game_lobby() -> void:
	var online_lobby_scene: PackedScene = load(ONLINE_LOBBY_SCENE_PATH)
	if online_lobby_scene == null:
		_show_banner("Failed to load the multiplayer lobby scene.")
		return
	var online_lobby: Node = online_lobby_scene.instantiate()
	if online_lobby.has_method("set_start_config"):
		online_lobby.call("set_start_config", rule_config, game_seed, player_count, presentation_mode, selected_game_id)
	_transition_to(online_lobby)


func _on_lobby_game_started(pc: int, seed_val: int, bot_difficulties: Array = [], _practice_mode: bool = false) -> void:
	player_count = pc
	var actual_seed: int = seed_val if seed_val >= 0 else randi()
	var scene_path: String = GAME_CATALOG.launch_scene_path(selected_game_id, presentation_mode)
	var game_table_scene: PackedScene = load(scene_path)
	if game_table_scene == null:
		_show_banner("Failed to load game scene")
		return
	var game_table: Node = game_table_scene.instantiate()
	if game_table.has_method("configure_game"):
		game_table.configure_game(rule_config, actual_seed, player_count, bot_difficulties)
	_show_banner("Starting %s (%s players, %s seed)" % [GAME_CATALOG.display_name(selected_game_id), player_count, "random" if game_seed < 0 else str(game_seed)])
	_transition_to(game_table)


func _transition_to(next_node: Node) -> void:
	if _animations_enabled:
		var delay: float = 0.0 if _reduced_motion else 0.25
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), _style_scalar(&"motion_fade_out"))
		tween.tween_callback(_replace_self_in_shell.bind(next_node))
	else:
		_replace_self_in_shell(next_node)


func _replace_self_in_shell(next_node: Node) -> void:
	if next_node == null:
		return
	_pause_backdrop()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var parent_node: Node = get_parent()
	if parent_node != null:
		var insertion_index: int = get_index()
		parent_node.add_child(next_node)
		parent_node.move_child(next_node, insertion_index)
	else:
		get_tree().root.add_child(next_node)
	queue_free()


func _on_settings_pressed() -> void:
	if not GAME_CATALOG.uses_okey_table(selected_game_id):
		_show_banner("Advanced table rules are available for Okey 101.")
		return
	if rule_config == null:
		_show_banner("Okey settings are unavailable. Please check the game installation.")
		return
	var settings_scene: PackedScene = load(SETTINGS_MENU_SCENE_PATH)
	if settings_scene == null:
		_show_banner("Failed to load Okey settings.")
		return
	var settings_menu = settings_scene.instantiate()
	add_child(settings_menu)
	settings_menu.set_config(rule_config)
	settings_menu.settings_changed.connect(_on_settings_changed)


func _on_settings_changed(new_config) -> void:
	rule_config = new_config
	_sync_presentation_mode_from_settings()
	_refresh_settings_summary()
	_show_banner("Settings updated!")


func _on_quit_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_back()
	get_tree().quit()


# ═══════════════════════════════════════════
# STATE HELPERS
# ═══════════════════════════════════════════

func _show_banner(text: String) -> void:
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", text)


func _refresh_settings_summary() -> void:
	if _settings_summary == null:
		return
	var parts: PackedStringArray = [GAME_CATALOG.display_name(selected_game_id)]
	if GAME_CATALOG.uses_okey_table(selected_game_id) and rule_config != null:
		parts.append("Preset: %s" % String(rule_config.preset_name))
		parts.append("%ds turns" % int(rule_config.timer_seconds))
	else:
		parts.append(GAME_CATALOG.chip_copy(selected_game_id))
	parts.append("%d seats" % player_count)
	parts.append("Online" if _online_available else "Local + bots")
	_settings_summary.text = "  ·  ".join(parts)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or _mode_grid == null:
		return
	var narrow: bool = viewport_size.x < 1280.0 or viewport_size.x / viewport_size.y < 1.5
	var compact: bool = viewport_size.y < 900.0
	_mode_grid.columns = 2 if narrow else 4
	var card_min: Vector2 = _style_vector(&"party_card_min_compact" if compact else &"party_card_min")
	for card in _mode_buttons.values():
		(card as Control).custom_minimum_size = card_min
	for label in _mode_chaos_labels:
		label.visible = not compact
	if _logo_bottom != null:
		_logo_bottom.add_theme_font_size_override("font_size", 72 if compact else 96)


func _texture(id: StringName) -> Texture2D:
	return ASSET_REGISTRY.texture(id)


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
		_show_banner("Display settings failed: %s" % String(result.get("reason", "unknown")))
