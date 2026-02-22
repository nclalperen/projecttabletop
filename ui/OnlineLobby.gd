extends Control

const GAME_TABLE_2D_SCENE: PackedScene = preload("res://ui/GameTable.tscn")
const GAME_TABLE_3D_SCENE: PackedScene = preload("res://ui/GameTable3D.tscn")
const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")
const P2P_TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_CONTROLLER_SCRIPT: Script = preload("res://net/HostMatchController.gd")
const CLIENT_MATCH_CONTROLLER_SCRIPT: Script = preload("res://net/ClientMatchController.gd")
const MENU_AUDIO_SERVICE_SCRIPT: Script = preload("res://ui/services/MenuAudioService.gd")
const PLAYER_CHIP_SCENE: PackedScene = preload("res://ui/widgets/LobbyPlayerChip.tscn")
const PROMPT_BADGE_SCENE: PackedScene = preload("res://ui/widgets/InputPromptBadge.tscn")
const EMOTE_BUTTON_SCENE: PackedScene = preload("res://ui/widgets/LobbyEmoteButton.tscn")
const KENNEY_ASSET_LOADER: Script = preload("res://ui/services/KenneyAssetLoader.gd")

const FONT_MAIN_PATH := "res://Kenney_c0/kenney_ui-pack/Font/Kenney Future.ttf"
const PANEL_BORDER_PATH := "res://Kenney_c0/kenney_ui-pack-adventure/PNG/Default/panel_border_grey_detail.png"
const PANEL_FILL_PATH := "res://Kenney_c0/kenney_ui-pack-adventure/PNG/Default/panel_grey_dark.png"
const PANEL_GRID_PATH := "res://Kenney_c0/kenney_ui-pack-adventure/PNG/Default/pattern_diagonal_transparent_small.png"
const ICON_LOGIN_PATH := "res://Kenney_c0/kenney_board-game-icons/PNG/Default (64px)/lock_open.png"
const ICON_QUICK_PATH := "res://Kenney_c0/kenney_board-game-icons/PNG/Default (64px)/cards_stack.png"
const ICON_PRIVATE_PATH := "res://Kenney_c0/kenney_board-game-icons/PNG/Default (64px)/lock_closed.png"
const ICON_READY_ON_PATH := "res://Kenney_c0/kenney_game-icons/PNG/White/1x/checkmark.png"
const ICON_READY_WAIT_PATH := "res://Kenney_c0/kenney_board-game-icons/PNG/Default (64px)/hourglass.png"
const ICON_START_PATH := "res://Kenney_c0/kenney_board-game-icons/PNG/Default (64px)/crown_a.png"
const ICON_BACK_PATH := "res://Kenney_c0/kenney_game-icons/PNG/White/1x/return.png"

const PROMPT_ESC_PATH := "res://Kenney_c0/kenney_input-prompts-pixel-16/Tiles/tile_0017.png"
const PROMPT_ENTER_PATH := "res://Kenney_c0/kenney_input-prompts-pixel-16/Tiles/tile_0133.png"
const PROMPT_SPACE_PATH := "res://Kenney_c0/kenney_input-prompts-pixel-16/Tiles/tile_0135.png"
const PROMPT_LMB_PATH := "res://Kenney_c0/kenney_game-icons-expansion/PNG/White/1x/mouseLeft.png"
const PROMPT_RMB_PATH := "res://Kenney_c0/kenney_game-icons-expansion/PNG/White/1x/mouseRight.png"

const EMOTE_DATA: Array[Dictionary] = [
	{"id": "question", "label": "Question", "icon_path": "res://Kenney_c0/kenney_game-icons/PNG/White/1x/question.png"},
	{"id": "checkmark", "label": "Ready", "icon_path": "res://Kenney_c0/kenney_game-icons/PNG/White/1x/checkmark.png"},
	{"id": "warning", "label": "Warning", "icon_path": "res://Kenney_c0/kenney_game-icons/PNG/White/1x/warning.png"},
	{"id": "star", "label": "Nice", "icon_path": "res://Kenney_c0/kenney_game-icons/PNG/White/1x/star.png"},
	{"id": "trophy", "label": "GG", "icon_path": "res://Kenney_c0/kenney_game-icons/PNG/White/1x/trophy.png"},
]

@onready var _status_label: Label = $Margin/RootCard/CardMargin/VBox/Status
@onready var _background: TextureRect = $Background
@onready var _root_card: PanelContainer = $Margin/RootCard
@onready var _buttons_grid: GridContainer = $Margin/RootCard/CardMargin/VBox/Buttons
@onready var _roster_header: Label = $Margin/RootCard/CardMargin/VBox/RosterHeader
@onready var _roster_list: VBoxContainer = $Margin/RootCard/CardMargin/VBox/RosterScroll/RosterList
@onready var _login_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/LoginBtn
@onready var _quick_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/QuickBtn
@onready var _private_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/PrivateBtn
@onready var _ready_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/ReadyBtn
@onready var _start_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/StartBtn
@onready var _back_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/BackBtn
@onready var _prompt_strip: FlowContainer = $Margin/RootCard/CardMargin/VBox/PromptStrip
@onready var _emote_label: Label = $Margin/RootCard/CardMargin/VBox/EmoteRow/EmoteLabel
@onready var _emote_buttons_box: FlowContainer = $Margin/RootCard/CardMargin/VBox/EmoteRow/EmoteButtons

var _online_service = null
var _lobby_service = null
var _rule_config: RuleConfig = RuleConfig.new()
var _game_seed: int = -1
var _player_count: int = 4
var _presentation_mode: String = "3d"

var _quick_match_pending: bool = false
var _start_attr_queue: Array = []
var _launch_started: bool = false
var _active_host_controller = null
var _last_member_connected: Dictionary = {}
var _menu_audio = null

func set_start_config(rule_config: RuleConfig, game_seed: int, player_count: int, presentation_mode: String) -> void:
	_rule_config = rule_config
	_game_seed = game_seed
	_player_count = player_count
	_presentation_mode = presentation_mode


func _ready() -> void:
	if _menu_audio == null:
		_menu_audio = MENU_AUDIO_SERVICE_SCRIPT.new()
		_menu_audio.name = "MenuAudioService"
		add_child(_menu_audio)

	_apply_kenney_fonts()
	_apply_background_pattern()
	_apply_panel_shell()
	_apply_button_icons()
	_build_prompt_strip()
	_build_emote_row()
	_bind_button_feedback()
	_apply_responsive_layout()

	_online_service = ONLINE_SERVICE_SCRIPT.new()
	_lobby_service = LOBBY_SERVICE_SCRIPT.new()
	add_child(_online_service)
	add_child(_lobby_service)

	_online_service.availability_changed.connect(_on_online_availability_changed)
	_online_service.login_succeeded.connect(_on_login_succeeded)
	_online_service.login_failed.connect(_on_login_failed)
	_lobby_service.lobby_updated.connect(_on_lobby_updated)
	_lobby_service.lobby_list_updated.connect(_on_lobby_list_updated)
	_lobby_service.lobby_error.connect(func(code: String, reason: String) -> void:
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Lobby error (%s): %s" % [code, reason]
	)

	_login_btn.pressed.connect(_on_login_pressed)
	_quick_btn.pressed.connect(_on_quick_match_pressed)
	_private_btn.pressed.connect(_on_private_lobby_pressed)
	_ready_btn.pressed.connect(_on_ready_pressed)
	_start_btn.pressed.connect(_on_start_pressed)
	_back_btn.pressed.connect(_on_back_pressed)

	var init_res: Dictionary = _online_service.initialize()
	if _lobby_service.has_method("set_backend_mode"):
		_lobby_service.call("set_backend_mode", _online_service.get_backend_mode())
	if not bool(init_res.get("ok", false)):
		_status_label.text = String(init_res.get("reason", "Online unavailable"))
	else:
		var mode: String = String(init_res.get("backend_mode", "mock"))
		_status_label.text = "Online ready (%s backend)." % mode
	_refresh_button_states()


func _apply_button_icons() -> void:
	_set_icon_button(_login_btn, _texture(ICON_LOGIN_PATH), "Login", 1)
	_set_icon_button(_quick_btn, _texture(ICON_QUICK_PATH), "Quick Match", 0)
	_set_icon_button(_private_btn, _texture(ICON_PRIVATE_PATH), "Private", 1)
	_set_icon_button(_ready_btn, _texture(ICON_READY_WAIT_PATH), "Ready", 0)
	_set_icon_button(_start_btn, _texture(ICON_START_PATH), "Start", 0)
	_set_icon_button(_back_btn, _texture(ICON_BACK_PATH), "Back", 1)


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


func _texture(path: String) -> Texture2D:
	return KENNEY_ASSET_LOADER.texture(path)


func _apply_kenney_fonts() -> void:
	var main_font: FontFile = KENNEY_ASSET_LOADER.font(FONT_MAIN_PATH)
	if main_font != null:
		var title: Label = $Margin/RootCard/CardMargin/VBox/Title
		title.add_theme_font_override("font", main_font)
		title.add_theme_font_size_override("font_size", 42)
		if _roster_header != null:
			_roster_header.add_theme_font_override("font", main_font)
		if _emote_label != null:
			_emote_label.add_theme_font_override("font", main_font)
		for button in [_login_btn, _quick_btn, _private_btn, _ready_btn, _start_btn, _back_btn]:
			if button != null:
				button.add_theme_font_override("font", main_font)
	_status_label.add_theme_font_size_override("font_size", 20)
	_status_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.99, 0.95))
	if _roster_header != null:
		_roster_header.add_theme_font_size_override("font_size", 22)
		_roster_header.add_theme_color_override("font_color", Color(0.91, 0.96, 0.99, 0.95))
	if _emote_label != null:
		_emote_label.add_theme_font_size_override("font_size", 18)
		_emote_label.add_theme_color_override("font_color", Color(0.91, 0.96, 0.99, 0.92))


func _apply_background_pattern() -> void:
	if _background != null:
		_background.texture = _texture(PANEL_GRID_PATH)
		_background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_background.stretch_mode = TextureRect.STRETCH_TILE
		_background.modulate = Color(0.16, 0.25, 0.3, 0.74)


func _apply_panel_shell() -> void:
	if _root_card == null:
		return
	var panel_tex: Texture2D = _texture(PANEL_FILL_PATH)
	if panel_tex != null:
		var panel_style := StyleBoxTexture.new()
		panel_style.texture = panel_tex
		panel_style.modulate_color = Color(0.54, 0.66, 0.76, 0.96)
		panel_style.texture_margin_left = 12.0
		panel_style.texture_margin_top = 12.0
		panel_style.texture_margin_right = 12.0
		panel_style.texture_margin_bottom = 12.0
		panel_style.content_margin_left = 14.0
		panel_style.content_margin_top = 12.0
		panel_style.content_margin_right = 14.0
		panel_style.content_margin_bottom = 12.0
		_root_card.add_theme_stylebox_override("panel", panel_style)

	var border_tex: Texture2D = _texture(PANEL_BORDER_PATH)
	if border_tex == null:
		return
	var border := _root_card.get_node_or_null("KenneyBorder") as NinePatchRect
	if border == null:
		border = NinePatchRect.new()
		border.name = "KenneyBorder"
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.draw_center = false
		border.anchor_right = 1.0
		border.anchor_bottom = 1.0
		border.patch_margin_left = 12
		border.patch_margin_top = 12
		border.patch_margin_right = 12
		border.patch_margin_bottom = 12
		_root_card.add_child(border)
	border.texture = border_tex


func _bind_button_feedback() -> void:
	for button in [_login_btn, _quick_btn, _private_btn, _ready_btn, _start_btn, _back_btn]:
		if button == null:
			continue
		button.mouse_entered.connect(_on_lobby_button_hover.bind(button))
		button.button_down.connect(_on_lobby_button_down.bind(button))
		button.button_up.connect(_on_lobby_button_up.bind(button))


func _on_lobby_button_hover(_button: Button) -> void:
	if _menu_audio != null:
		_menu_audio.play_hover()


func _on_lobby_button_down(button: Button) -> void:
	if button != null:
		button.scale = Vector2(1.03, 1.03)


func _on_lobby_button_up(button: Button) -> void:
	if button != null:
		button.scale = Vector2.ONE


func _build_prompt_strip() -> void:
	for child in _prompt_strip.get_children():
		child.queue_free()
	var prompts: Array[Dictionary] = [
		{"icon": _texture(PROMPT_ESC_PATH), "text": "ESC Back"},
		{"icon": _texture(PROMPT_ENTER_PATH), "text": "ENTER Start"},
		{"icon": _texture(PROMPT_SPACE_PATH), "text": "SPACE Ready"},
		{"icon": _texture(PROMPT_LMB_PATH), "text": "LMB Select"},
		{"icon": _texture(PROMPT_RMB_PATH), "text": "RMB Menu"},
	]
	for entry in prompts:
		var badge: Node = PROMPT_BADGE_SCENE.instantiate()
		_prompt_strip.add_child(badge)
		if badge.has_method("configure"):
			badge.call("configure", entry.get("icon", null), String(entry.get("text", "")))


func _build_emote_row() -> void:
	for child in _emote_buttons_box.get_children():
		child.queue_free()
	for entry in EMOTE_DATA:
		var emote_btn: Node = EMOTE_BUTTON_SCENE.instantiate()
		if emote_btn == null:
			continue
		_emote_buttons_box.add_child(emote_btn)
		if emote_btn.has_method("configure"):
			emote_btn.call(
				"configure",
				String(entry.get("id", "")),
				String(entry.get("label", "")),
				_texture(String(entry.get("icon_path", "")))
			)
		emote_btn.connect("emote_selected", Callable(self, "_on_emote_selected"))


func _on_emote_selected(emote_id: String) -> void:
	if _menu_audio != null:
		_menu_audio.play_toggle()
	for entry in EMOTE_DATA:
		if String(entry.get("id", "")) == emote_id:
			_status_label.text = "Emote: %s" % String(entry.get("label", ""))
			return
	_status_label.text = "Emote sent"


func _on_online_availability_changed(available: bool, reason: String) -> void:
	if not available:
		_status_label.text = reason
	else:
		var mode: String = _online_service.get_backend_mode()
		_status_label.text = "Online ready (%s backend). Sign in to continue." % mode
	_refresh_button_states()


func _on_login_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	if not _online_service.is_available():
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = _online_service.get_unavailable_reason()
		return
	var login_res: Dictionary = _online_service.login_dev_auth("dev_player")
	if not bool(login_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = String(login_res.get("reason", "Login failed"))
		return
	if String(login_res.get("code", "")) == "pending":
		_status_label.text = "Signing in via EOS Dev Auth..."
		return
	_status_label.text = "Logged in as %s (%s)." % [String(login_res.get("local_puid", "")), String(login_res.get("backend_mode", _online_service.get_backend_mode()))]


func _on_login_succeeded(local_puid: String) -> void:
	_lobby_service.set_local_puid(local_puid)
	_status_label.text = "Signed in: %s" % local_puid
	_refresh_button_states()


func _on_login_failed(reason: String) -> void:
	if _menu_audio != null:
		_menu_audio.play_error()
	_status_label.text = reason
	_refresh_button_states()


func _on_quick_match_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	if _online_service.local_puid == "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Sign in first."
		return
	_quick_match_pending = true
	var search: Dictionary = _lobby_service.search_lobbies({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"open_slots": 1,
	})
	if not bool(search.get("ok", false)):
		_quick_match_pending = false
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = String(search.get("reason", "Quick match search failed"))
		return
	if String(search.get("code", "")) == "pending":
		_status_label.text = "Searching lobbies..."
		return
	_handle_quick_search_result(search.get("lobbies", []))


func _on_private_lobby_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	if _online_service.local_puid == "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Sign in first."
		return
	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "INVITE_ONLY",
	})
	if not bool(create_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = String(create_res.get("reason", "Failed to create lobby"))
		return
	_status_label.text = "Creating private lobby..." if String(create_res.get("code", "")) == "pending" else "Created private lobby."


func _on_ready_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_toggle()
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Join or create a lobby first."
		return
	var ready_now: bool = _current_member_ready(lobby)
	var res: Dictionary = _lobby_service.set_ready(not ready_now)
	if not bool(res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = String(res.get("reason", "Failed to update ready"))
		return
	_status_label.text = "Updating ready..." if String(res.get("code", "")) == "pending" else "Ready updated."


func _on_start_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "No active lobby."
		return
	if not _is_local_host(lobby):
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Only lobby creator can start."
		return
	if int(lobby.get("members", []).size()) != _player_count:
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Need %d players to start." % _player_count
		return
	if not _all_members_ready(lobby):
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "All players must be ready."
		return
	if _launch_started:
		return
	_start_attr_queue.clear()
	var seat_by_puid: Dictionary = _extract_or_build_seat_map(lobby)
	var match_seed: int = _game_seed if _game_seed >= 0 else randi()
	var match_id: String = String(lobby.get("attrs", {}).get("match_id", ""))
	if match_id == "":
		match_id = "M_%08x" % int(abs(hash("%s|%s" % [_online_service.local_puid, Time.get_unix_time_from_system()])))
	var seat_json: String = JSON.stringify(seat_by_puid)
	_start_attr_queue.append({"key": "host_puid", "value": _online_service.local_puid})
	_start_attr_queue.append({"key": "match_id", "value": match_id})
	_start_attr_queue.append({"key": "match_seed", "value": match_seed})
	_start_attr_queue.append({"key": "seat_map_json", "value": seat_json})
	_start_attr_queue.append({"key": "phase", "value": "MATCH_STARTING"})
	_status_label.text = "Publishing match start..."
	_drain_host_start_attr_queue()


func _on_back_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_back()
	get_tree().change_scene_to_file("res://ui/Main.tscn")


func _on_lobby_list_updated(lobbies: Array) -> void:
	if _quick_match_pending:
		_handle_quick_search_result(lobbies)


func _handle_quick_search_result(lobbies: Array) -> void:
	_quick_match_pending = false
	if not lobbies.is_empty():
		var lobby_id: String = String(lobbies[0].get("lobby_id", ""))
		if lobby_id == "":
			if _menu_audio != null:
				_menu_audio.play_error()
			_status_label.text = "Search returned invalid lobby id."
			return
		var join_res: Dictionary = _lobby_service.join_lobby(lobby_id)
		if not bool(join_res.get("ok", false)):
			if _menu_audio != null:
				_menu_audio.play_error()
			_status_label.text = String(join_res.get("reason", "Failed to join lobby"))
			return
		_status_label.text = "Joining lobby %s..." % lobby_id if String(join_res.get("code", "")) == "pending" else "Joined lobby %s" % lobby_id
		return

	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "PUBLIC",
	})
	if not bool(create_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = String(create_res.get("reason", "Failed to create lobby"))
		return
	_status_label.text = "Creating public lobby..." if String(create_res.get("code", "")) == "pending" else "Created public lobby."


func _on_lobby_updated(lobby_model: Dictionary) -> void:
	_rebuild_roster(lobby_model)
	if lobby_model.is_empty():
		_last_member_connected.clear()
		_refresh_button_states()
		return

	if not _start_attr_queue.is_empty() and _is_local_host(lobby_model):
		while not _start_attr_queue.is_empty():
			var head: Dictionary = _start_attr_queue[0]
			var key: String = String(head.get("key", ""))
			if key == "":
				_start_attr_queue.remove_at(0)
				continue
			if String(lobby_model.get("attrs", {}).get(key, "")) == String(head.get("value", "")):
				_start_attr_queue.remove_at(0)
				continue
			break
		if not _start_attr_queue.is_empty():
			call_deferred("_drain_host_start_attr_queue")

	_bridge_member_presence_to_host(lobby_model)
	_maybe_launch_match_from_lobby(lobby_model)
	_refresh_button_states()
	_refresh_ready_button_visual()


func _rebuild_roster(lobby_model: Dictionary) -> void:
	for child in _roster_list.get_children():
		child.queue_free()
	if lobby_model.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No lobby joined yet. Use Quick Match or Private to create one."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(0.0, 74.0)
		empty_label.modulate = Color(0.84, 0.92, 0.97, 0.9)
		_roster_list.add_child(empty_label)
		return
	var owner_puid: String = String(lobby_model.get("owner_puid", ""))
	for member in lobby_model.get("members", []):
		var chip: Node = PLAYER_CHIP_SCENE.instantiate()
		_roster_list.add_child(chip)
		if chip.has_method("set_member"):
			chip.call("set_member", member, owner_puid, _online_service.local_puid)


func _drain_host_start_attr_queue() -> void:
	if _start_attr_queue.is_empty():
		return
	if _launch_started:
		return
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		return
	var head: Dictionary = _start_attr_queue[0]
	var key: String = String(head.get("key", ""))
	var value = head.get("value")
	var set_res: Dictionary = _lobby_service.set_lobby_attr(key, value)
	if not bool(set_res.get("ok", false)):
		_start_attr_queue.clear()
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = String(set_res.get("reason", "Failed to update lobby attrs"))
		return
	if String(set_res.get("code", "")) == "pending":
		_status_label.text = "Updating lobby: %s..." % key
		return
	_start_attr_queue.remove_at(0)
	call_deferred("_drain_host_start_attr_queue")


func _maybe_launch_match_from_lobby(lobby: Dictionary) -> void:
	if _launch_started:
		return
	var attrs: Dictionary = lobby.get("attrs", {})
	if String(attrs.get("phase", "")) != "MATCH_STARTING":
		return
	var seat_by_puid: Dictionary = _extract_or_build_seat_map(lobby)
	if not seat_by_puid.has(_online_service.local_puid):
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Seat map missing local player."
		return
	var host_puid: String = String(attrs.get("host_puid", lobby.get("owner_puid", "")))
	if host_puid == "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_status_label.text = "Match start missing host."
		return
	var match_seed: int = int(attrs.get("match_seed", _game_seed if _game_seed >= 0 else randi()))
	var match_id: String = String(attrs.get("match_id", ""))

	var scene: PackedScene = GAME_TABLE_3D_SCENE if _presentation_mode == "3d" else GAME_TABLE_2D_SCENE
	var game_table: Node = scene.instantiate()
	var transport = P2P_TRANSPORT_SCRIPT.new()
	if transport.has_method("set_backend_mode"):
		transport.call("set_backend_mode", _online_service.get_backend_mode())
	if transport.has_method("set_runtime_context"):
		transport.call("set_runtime_context", String(lobby.get("lobby_id", "")), String(attrs.get("rtc_room_name", "")))

	var controller = null
	if _online_service.local_puid == host_puid:
		controller = HOST_MATCH_CONTROLLER_SCRIPT.new()
		controller.configure_host(_online_service.local_puid, transport, seat_by_puid, match_id, match_seed)
		controller.start_new_match(_rule_config, match_seed, _player_count)
		_active_host_controller = controller
		_sync_member_presence_baseline(lobby)
	else:
		controller = CLIENT_MATCH_CONTROLLER_SCRIPT.new()
		controller.configure_client(_online_service.local_puid, host_puid, transport, int(seat_by_puid.get(_online_service.local_puid, 0)), match_id)
		_active_host_controller = null

	game_table.add_child(transport)
	game_table.add_child(controller)
	if game_table.has_method("inject_controller"):
		game_table.call("inject_controller", controller)
	if game_table.has_method("configure_game"):
		game_table.call("configure_game", _rule_config, match_seed, _player_count)

	_launch_started = true
	get_tree().root.add_child(game_table)
	queue_free()


func _bridge_member_presence_to_host(lobby: Dictionary) -> void:
	if _active_host_controller == null:
		return
	if not _active_host_controller.has_method("mark_peer_disconnected"):
		return
	var current_connected: Dictionary = {}
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "" or puid == _online_service.local_puid:
			continue
		var status: String = String(member.get("attrs", {}).get("status", "OK")).to_upper()
		var connected: bool = not (status == "DISCONNECTED" or status == "LEFT" or status == "CLOSED" or status == "KICKED" or status == "BOT_ACTIVE")
		current_connected[puid] = connected
		var was_connected: bool = bool(_last_member_connected.get(puid, true))
		if was_connected and not connected:
			_active_host_controller.call("mark_peer_disconnected", puid)
		elif not was_connected and connected:
			_active_host_controller.call("mark_peer_reconnected", puid)
	_last_member_connected = current_connected


func _sync_member_presence_baseline(lobby: Dictionary) -> void:
	_last_member_connected.clear()
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "" or puid == _online_service.local_puid:
			continue
		var status: String = String(member.get("attrs", {}).get("status", "OK")).to_upper()
		_last_member_connected[puid] = not (status == "DISCONNECTED" or status == "LEFT" or status == "CLOSED" or status == "KICKED" or status == "BOT_ACTIVE")


func _extract_or_build_seat_map(lobby: Dictionary) -> Dictionary:
	var attrs: Dictionary = lobby.get("attrs", {})
	var seat_map_json: String = String(attrs.get("seat_map_json", ""))
	if seat_map_json.strip_edges() != "":
		var parsed = JSON.parse_string(seat_map_json)
		if typeof(parsed) == TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key in (parsed as Dictionary).keys():
				out[String(key)] = int((parsed as Dictionary)[key])
			if not out.is_empty():
				return out
	var out_map: Dictionary = {}
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid == "":
			continue
		out_map[puid] = int(member.get("attrs", {}).get("seat", out_map.size()))
	return out_map


func _refresh_button_states() -> void:
	var online_ok: bool = _online_service != null and _online_service.is_available()
	var logged_in: bool = online_ok and _online_service.local_puid != ""
	var lobby: Dictionary = _lobby_service.get_current_lobby() if _lobby_service != null else {}
	var in_lobby: bool = not lobby.is_empty()
	var local_host: bool = in_lobby and _is_local_host(lobby)
	_login_btn.disabled = not online_ok
	_quick_btn.disabled = not logged_in
	_private_btn.disabled = not logged_in
	_ready_btn.disabled = not in_lobby
	_start_btn.disabled = not (in_lobby and local_host)
	_refresh_ready_button_visual()


func _is_local_host(lobby: Dictionary) -> bool:
	return String(lobby.get("owner_puid", "")) == _online_service.local_puid


func _all_members_ready(lobby: Dictionary) -> bool:
	for member in lobby.get("members", []):
		if not bool(member.get("attrs", {}).get("ready", false)):
			return false
	return true


func _current_member_ready(lobby: Dictionary) -> bool:
	for member in lobby.get("members", []):
		if String(member.get("puid", "")) == _online_service.local_puid:
			return bool(member.get("attrs", {}).get("ready", false))
	return false


func _refresh_ready_button_visual() -> void:
	var lobby: Dictionary = _lobby_service.get_current_lobby() if _lobby_service != null else {}
	var is_ready: bool = not lobby.is_empty() and _current_member_ready(lobby)
	_set_icon_button(
		_ready_btn,
		_texture(ICON_READY_ON_PATH if is_ready else ICON_READY_WAIT_PATH),
		"Ready" if not is_ready else "Unready",
		0
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if _buttons_grid == null or _root_card == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_width: float = viewport_size.x
	if viewport_width < 760.0:
		_buttons_grid.columns = 1
	elif viewport_width < 1080.0:
		_buttons_grid.columns = 2
	else:
		_buttons_grid.columns = 3
	var width: float = clampf(viewport_size.x - 64.0, 460.0, 1480.0)
	var height: float = clampf(viewport_size.y - 72.0, 460.0, 930.0)
	_root_card.custom_minimum_size = Vector2(width, height)
