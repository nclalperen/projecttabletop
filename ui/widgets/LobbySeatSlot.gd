extends PanelContainer
class_name LobbySeatSlot

signal seat_action_requested(seat_index, action_id)

const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")

@onready var _seat_label: Label = $Margin/HBox/SeatTag
@onready var _name_label: Label = $Margin/HBox/Info/Name
@onready var _subtitle_label: Label = $Margin/HBox/Info/Subtitle
@onready var _meta_label: Label = $Margin/HBox/Info/Meta
@onready var _status_label: Label = $Margin/HBox/StatusTag

var _seat_index: int = -1
var _interactive: bool = false
var _slot_state: String = "open"
var _hovered: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(func() -> void:
		_hovered = true
		_refresh_style()
	)
	mouse_exited.connect(func() -> void:
		_hovered = false
		_refresh_style()
	)
	focus_entered.connect(_refresh_style)
	focus_exited.connect(_refresh_style)


func configure(slot_model: Dictionary, local_puid: String, owner_puid: String, interactive: bool) -> void:
	_seat_index = int(slot_model.get("seat", -1))
	_interactive = interactive
	_slot_state = String(slot_model.get("state", "open")).strip_edges().to_lower()
	var puid: String = String(slot_model.get("puid", slot_model.get("target_puid", ""))).strip_edges()
	var display_name: String = String(slot_model.get("display_name", "")).strip_edges()
	if display_name == "":
		display_name = "Empty Seat"
	if puid != "" and puid == local_puid:
		display_name = "%s (You)" % display_name
	var subtitle: String = _subtitle_for(slot_model, puid, owner_puid)
	var meta_text: String = _meta_for(slot_model)
	var status_text: String = _status_for(slot_model)
	_seat_label.text = "P%d" % maxi(0, _seat_index)
	_name_label.text = display_name
	_subtitle_label.text = subtitle
	_meta_label.text = meta_text
	_meta_label.visible = meta_text != ""
	_status_label.text = status_text
	_status_label.visible = status_text != ""
	tooltip_text = subtitle if subtitle != "" else display_name
	_refresh_style()


func _gui_input(event: InputEvent) -> void:
	if not _interactive:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		release_focus()
		grab_focus()
		emit_signal("seat_action_requested", _seat_index, &"open_context")
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		emit_signal("seat_action_requested", _seat_index, &"open_context")
		accept_event()


func _subtitle_for(_slot_model: Dictionary, puid: String, owner_puid: String) -> String:
	match _slot_state:
		"host":
			return "Lobby host" if puid == owner_puid else "Host seat"
		"human":
			return "Player joined"
		"invited":
			return "Invite pending"
		"bot":
			return "Bot seat"
		_:
			return "Click to add a bot or invite a player" if _interactive else "Waiting for host"


func _meta_for(slot_model: Dictionary) -> String:
	var parts: Array[String] = []
	var status: String = String(slot_model.get("status", "")).strip_edges().to_upper()
	var platform_tag: String = String(slot_model.get("platform", "")).strip_edges().to_lower()
	if _slot_state == "human" or _slot_state == "host":
		if status != "":
			parts.append(status)
		if platform_tag != "":
			parts.append(platform_tag)
	elif _slot_state == "invited":
		var target_puid: String = String(slot_model.get("target_puid", "")).strip_edges()
		if target_puid != "":
			parts.append(target_puid)
	return " | ".join(parts)


func _status_for(slot_model: Dictionary) -> String:
	match _slot_state:
		"bot":
			return "BOT"
		"invited":
			return "INVITED"
		"human", "host":
			return "READY" if bool(slot_model.get("ready", false)) else "WAITING"
		_:
			return "OPEN"


func _refresh_style() -> void:
	var palette: Dictionary = _palette_for_state()
	var panel := StyleBoxFlat.new()
	panel.bg_color = palette.get("bg", Color(0.2, 0.16, 0.12, 0.92))
	panel.border_color = palette.get("border", MENU_STYLE.color(&"panel_border"))
	panel.border_width_left = 2
	panel.border_width_top = 2
	panel.border_width_right = 2
	panel.border_width_bottom = 2
	panel.corner_radius_top_left = 14
	panel.corner_radius_top_right = 14
	panel.corner_radius_bottom_right = 14
	panel.corner_radius_bottom_left = 14
	panel.content_margin_left = 14
	panel.content_margin_top = 12
	panel.content_margin_right = 14
	panel.content_margin_bottom = 12
	if has_focus():
		panel.shadow_size = 8
		panel.shadow_color = Color(0, 0, 0, 0.32)
	add_theme_stylebox_override("panel", panel)
	_seat_label.add_theme_color_override("font_color", palette.get("seat", MENU_STYLE.color(&"panel_border")))
	_name_label.add_theme_color_override("font_color", palette.get("title", MENU_STYLE.color(&"title_text")))
	_subtitle_label.add_theme_color_override("font_color", palette.get("subtitle", MENU_STYLE.color(&"subtitle_text")))
	_meta_label.add_theme_color_override("font_color", palette.get("meta", MENU_STYLE.color(&"muted_text")))
	_status_label.add_theme_color_override("font_color", palette.get("status_text", MENU_STYLE.color(&"button_primary_font")))
	var status_panel := StyleBoxFlat.new()
	status_panel.bg_color = palette.get("status_bg", MENU_STYLE.color(&"button_primary_tint"))
	status_panel.corner_radius_top_left = 9
	status_panel.corner_radius_top_right = 9
	status_panel.corner_radius_bottom_right = 9
	status_panel.corner_radius_bottom_left = 9
	status_panel.content_margin_left = 8
	status_panel.content_margin_right = 8
	status_panel.content_margin_top = 4
	status_panel.content_margin_bottom = 4
	_status_label.add_theme_stylebox_override("normal", status_panel)
	_status_label.add_theme_font_size_override("font_size", 13)
	if _interactive:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		mouse_default_cursor_shape = Control.CURSOR_ARROW


func _palette_for_state() -> Dictionary:
	var active_border: Color = MENU_STYLE.color(&"field_border_focus") if has_focus() else MENU_STYLE.color(&"panel_border")
	var hover_mix: float = 0.16 if _hovered and _interactive else 0.0
	match _slot_state:
		"host":
			return {
				"bg": Color(0.35, 0.28, 0.18, 0.98).lightened(hover_mix),
				"border": active_border,
				"seat": Color(1.0, 0.92, 0.72, 1.0),
				"title": MENU_STYLE.color(&"title_text"),
				"subtitle": MENU_STYLE.color(&"subtitle_text"),
				"meta": MENU_STYLE.color(&"body_text"),
				"status_bg": MENU_STYLE.color(&"button_primary_tint"),
				"status_text": MENU_STYLE.color(&"button_primary_font"),
			}
		"human":
			return {
				"bg": Color(0.24, 0.2, 0.16, 0.98).lightened(hover_mix),
				"border": active_border,
				"seat": MENU_STYLE.color(&"panel_border"),
				"title": MENU_STYLE.color(&"lobby_player_remote"),
				"subtitle": MENU_STYLE.color(&"subtitle_text"),
				"meta": MENU_STYLE.color(&"muted_text"),
				"status_bg": MENU_STYLE.color(&"button_secondary_tint"),
				"status_text": MENU_STYLE.color(&"button_secondary_font"),
			}
		"bot":
			return {
				"bg": Color(0.2, 0.25, 0.18, 0.96).lightened(hover_mix),
				"border": active_border,
				"seat": Color(0.85, 0.93, 0.74, 1.0),
				"title": Color(0.9, 0.96, 0.84, 1.0),
				"subtitle": MENU_STYLE.color(&"subtitle_text"),
				"meta": MENU_STYLE.color(&"muted_text"),
				"status_bg": Color(0.78, 0.9, 0.68, 1.0),
				"status_text": Color(0.15, 0.2, 0.12, 1.0),
			}
		"invited":
			return {
				"bg": Color(0.18, 0.2, 0.26, 0.96).lightened(hover_mix),
				"border": active_border,
				"seat": Color(0.8, 0.87, 0.98, 1.0),
				"title": Color(0.9, 0.95, 1.0, 1.0),
				"subtitle": MENU_STYLE.color(&"subtitle_text"),
				"meta": MENU_STYLE.color(&"muted_text"),
				"status_bg": Color(0.48, 0.62, 0.92, 1.0),
				"status_text": Color(0.1, 0.14, 0.2, 1.0),
			}
		_:
			return {
				"bg": Color(0.12, 0.11, 0.1, 0.88).lightened(hover_mix),
				"border": active_border if _interactive else Color(0.45, 0.4, 0.35, 0.42),
				"seat": MENU_STYLE.color(&"muted_text"),
				"title": MENU_STYLE.color(&"subtitle_text"),
				"subtitle": MENU_STYLE.color(&"muted_text"),
				"meta": MENU_STYLE.color(&"muted_text"),
				"status_bg": Color(0.24, 0.23, 0.22, 1.0),
				"status_text": MENU_STYLE.color(&"subtitle_text"),
			}
