extends Control

const GAME_TABLE_2D_SCENE: PackedScene = preload("res://ui/GameTable.tscn")
const GAME_TABLE_3D_SCENE: PackedScene = preload("res://ui/GameTable3D.tscn")
const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")
const P2P_TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_CONTROLLER_SCRIPT: Script = preload("res://net/HostMatchController.gd")
const CLIENT_MATCH_CONTROLLER_SCRIPT: Script = preload("res://net/ClientMatchController.gd")
const PROTOCOL_SCRIPT: Script = preload("res://net/Protocol.gd")
const EOS_BACKEND_POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")
const MENU_AUDIO_SERVICE_SCRIPT: Script = preload("res://ui/services/MenuAudioService.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const PLAYER_CHIP_SCENE: PackedScene = preload("res://ui/widgets/LobbyPlayerChip.tscn")
const PROMPT_BADGE_SCENE: PackedScene = preload("res://ui/widgets/InputPromptBadge.tscn")
const EMOTE_BUTTON_SCENE: PackedScene = preload("res://ui/widgets/LobbyEmoteButton.tscn")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")

const PANEL_BORDER_ID: StringName = ASSET_IDS.UI_PANEL_BORDER_GREY_DETAIL
const PANEL_FILL_ID: StringName = ASSET_IDS.UI_PANEL_GREY_DARK
const PANEL_GRID_ID: StringName = ASSET_IDS.UI_PANEL_PATTERN_DIAGONAL_TRANSPARENT_SMALL
const ICON_LOGIN_ID: StringName = ASSET_IDS.UI_ICON_LOCK_OPEN
const ICON_QUICK_ID: StringName = ASSET_IDS.UI_ICON_CARDS_STACK
const ICON_PRIVATE_ID: StringName = ASSET_IDS.UI_ICON_LOCK_CLOSED
const ICON_READY_ON_ID: StringName = ASSET_IDS.UI_ICON_CHECKMARK
const ICON_READY_WAIT_ID: StringName = ASSET_IDS.UI_ICON_HOURGLASS
const ICON_START_ID: StringName = ASSET_IDS.UI_ICON_CROWN_A
const ICON_BACK_ID: StringName = ASSET_IDS.UI_ICON_RETURN

const PROMPT_ESC_ID: StringName = ASSET_IDS.UI_PROMPT_ESC
const PROMPT_ENTER_ID: StringName = ASSET_IDS.UI_PROMPT_ENTER
const PROMPT_SPACE_ID: StringName = ASSET_IDS.UI_PROMPT_SPACE
const PROMPT_LMB_ID: StringName = ASSET_IDS.UI_PROMPT_MOUSE_LEFT
const PROMPT_RMB_ID: StringName = ASSET_IDS.UI_PROMPT_MOUSE_RIGHT

const EMOTE_DATA: Array[Dictionary] = [
	{"id": "question", "label": "Question", "icon_id": ASSET_IDS.UI_ICON_QUESTION},
	{"id": "checkmark", "label": "Ready", "icon_id": ASSET_IDS.UI_ICON_CHECKMARK},
	{"id": "warning", "label": "Warning", "icon_id": ASSET_IDS.UI_ICON_WARNING},
	{"id": "star", "label": "Nice", "icon_id": ASSET_IDS.UI_ICON_STAR},
	{"id": "trophy", "label": "GG", "icon_id": ASSET_IDS.UI_ICON_TROPHY},
]

const ATTR_PROTOCOL_REV: String = "protocol_rev"
const ATTR_BUILD_FAMILY: String = "build_family"
const ATTR_DISPLAY_NAME: String = "display_name"

const STATUS_COPY := {
	&"online_unavailable": "Online unavailable: {reason}",
	&"online_ready": "Online ready ({mode}, policy: {policy}). {reason}",
	&"online_required": "Online requires EOS runtime in this build. {reason}",
	&"login_pending": "Signing in via EOS Account Portal...",
	&"login_success": "Logged in as {display_name} ({puid}, {mode}).",
	&"signed_in": "Signed in: {display_name} ({puid})",
	&"login_failed": "Login failed: {reason}",
	&"operation_failed": "{reason}",
	&"sign_in_required": "Sign in first.",
	&"quick_searching": "Searching lobbies...",
	&"quick_search_failed": "Quick match search failed: {reason}",
	&"quick_invalid_lobby": "Search returned invalid lobby id.",
	&"joining_lobby": "Joining lobby {lobby_id}...",
	&"joined_lobby": "Joined lobby {lobby_id}.",
	&"creating_private_pending": "Creating private lobby...",
	&"creating_private_done": "Private lobby created.",
	&"creating_public_pending": "Creating public lobby...",
	&"creating_public_done": "Public lobby created.",
	&"ready_blocked": "Join or create a lobby first.",
	&"ready_pending": "Updating ready state...",
	&"ready_done": "Ready state updated.",
	&"start_no_lobby": "No active lobby.",
	&"start_not_host": "Only lobby creator can start.",
	&"start_need_players": "Need {count} players to start.",
	&"start_need_ready": "All players must be ready.",
	&"start_incompatible": "Cannot start: {reason}",
	&"start_publish": "Publishing match start...",
	&"attr_update": "Updating lobby: {key}...",
	&"attr_update_failed": "Failed to update lobby attrs: {reason}",
	&"lobby_error": "Lobby error ({code}): {reason}",
	&"seat_map_missing": "Seat map missing local player.",
	&"start_missing_host": "Match start missing host.",
	&"join_incompatible": "Lobby incompatible: {reason}",
	&"emote": "Emote: {label}",
	&"emote_generic": "Emote sent.",
}

@onready var _status_label: Label = $Margin/RootCard/CardMargin/VBox/Status
@onready var _background: TextureRect = $Background
@onready var _root_card: PanelContainer = $Margin/RootCard
@onready var _card_margin: MarginContainer = $Margin/RootCard/CardMargin
@onready var _buttons_grid: GridContainer = $Margin/RootCard/CardMargin/VBox/Buttons
@onready var _roster_header: Label = $Margin/RootCard/CardMargin/VBox/RosterHeader
@onready var _roster_scroll: ScrollContainer = $Margin/RootCard/CardMargin/VBox/RosterScroll
@onready var _roster_list: VBoxContainer = $Margin/RootCard/CardMargin/VBox/RosterScroll/RosterList
@onready var _login_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/LoginBtn
@onready var _quick_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/QuickBtn
@onready var _private_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/PrivateBtn
@onready var _ready_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/ReadyBtn
@onready var _start_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/StartBtn
@onready var _back_btn: Button = $Margin/RootCard/CardMargin/VBox/Buttons/BackBtn
@onready var _prompt_strip: FlowContainer = $Margin/RootCard/CardMargin/VBox/PromptStrip
@onready var _emote_row: HBoxContainer = $Margin/RootCard/CardMargin/VBox/EmoteRow
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
		_set_status(&"lobby_error", {"code": code, "reason": reason})
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
	if _lobby_service.has_method("set_backend_policy"):
		_lobby_service.call("set_backend_policy", _online_service.get_backend_policy())
	if not bool(init_res.get("ok", false)):
		var policy: String = String(init_res.get("backend_policy", _online_service.get_backend_policy()))
		var unavailable_reason: String = String(init_res.get("reason", "Online unavailable"))
		if policy == EOS_BACKEND_POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED:
			_set_status(&"online_required", {"reason": unavailable_reason})
		else:
			_set_status(&"online_unavailable", {"reason": unavailable_reason})
	else:
		var mode: String = String(init_res.get("backend_mode", "mock"))
		var policy_name: String = String(init_res.get("backend_policy", _online_service.get_backend_policy()))
		var reason: String = String(init_res.get("reason", "")).strip_edges()
		_set_status(&"online_ready", {
			"mode": mode,
			"policy": policy_name,
			"reason": reason if reason != "" else "Sign in to continue.",
		})
	_apply_runtime_profile_to_lobby_service()
	_refresh_button_states()


func _apply_button_icons() -> void:
	_set_icon_button(_login_btn, _texture(ICON_LOGIN_ID), "Login", 1)
	_set_icon_button(_quick_btn, _texture(ICON_QUICK_ID), "Quick Match", 0)
	_set_icon_button(_private_btn, _texture(ICON_PRIVATE_ID), "Private", 1)
	_set_icon_button(_ready_btn, _texture(ICON_READY_WAIT_ID), "Ready", 0)
	_set_icon_button(_start_btn, _texture(ICON_START_ID), "Start", 0)
	_set_icon_button(_back_btn, _texture(ICON_BACK_ID), "Back", 1)


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
	var title: Label = $Margin/RootCard/CardMargin/VBox/Title
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", _style_color(&"title_text"))
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.add_theme_color_override("font_color", _style_color(&"body_text"))
	if _roster_header != null:
		_roster_header.add_theme_font_size_override("font_size", 21)
		_roster_header.add_theme_color_override("font_color", _style_color(&"subtitle_text"))
	if _emote_label != null:
		_emote_label.add_theme_font_size_override("font_size", 17)
		_emote_label.add_theme_color_override("font_color", _style_color(&"subtitle_text"))


func _apply_background_pattern() -> void:
	if _background != null:
		_background.texture = _texture(PANEL_GRID_ID)
		_background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		_background.stretch_mode = TextureRect.STRETCH_TILE
		_background.modulate = _style_color(&"bg_pattern")


func _apply_panel_shell() -> void:
	if _root_card == null:
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
		_root_card.add_theme_stylebox_override("panel", panel_style)

	var border_tex: Texture2D = _texture(PANEL_BORDER_ID)
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
		var border_margin: int = int(round(_style_scalar(&"panel_border_margin")))
		border.patch_margin_left = border_margin
		border.patch_margin_top = border_margin
		border.patch_margin_right = border_margin
		border.patch_margin_bottom = border_margin
		_root_card.add_child(border)
	border.texture = border_tex
	border.modulate = _style_color(&"panel_border")


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
		var scale_amount: float = _style_scalar(&"press_scale")
		button.scale = Vector2(scale_amount, scale_amount)


func _on_lobby_button_up(button: Button) -> void:
	if button != null:
		button.scale = Vector2.ONE


func _build_prompt_strip() -> void:
	for child in _prompt_strip.get_children():
		child.queue_free()
	var prompts: Array[Dictionary] = []
	if OS.get_name() == "Android":
		prompts = [
			{"icon": _texture(PROMPT_ESC_ID), "text": "Back"},
			{"icon": _texture(PROMPT_SPACE_ID), "text": "Tap Ready"},
			{"icon": _texture(PROMPT_ENTER_ID), "text": "Tap Start"},
			{"icon": _texture(PROMPT_LMB_ID), "text": "Tap Select"},
		]
	else:
		prompts = [
			{"icon": _texture(PROMPT_ESC_ID), "text": "ESC Back"},
			{"icon": _texture(PROMPT_ENTER_ID), "text": "ENTER Start"},
			{"icon": _texture(PROMPT_SPACE_ID), "text": "SPACE Ready"},
			{"icon": _texture(PROMPT_LMB_ID), "text": "LMB Select"},
			{"icon": _texture(PROMPT_RMB_ID), "text": "RMB Menu"},
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
				_texture(StringName(entry.get("icon_id", StringName(""))))
			)
		emote_btn.connect("emote_selected", Callable(self, "_on_emote_selected"))


func _on_emote_selected(emote_id: String) -> void:
	if _menu_audio != null:
		_menu_audio.play_toggle()
	for entry in EMOTE_DATA:
		if String(entry.get("id", "")) == emote_id:
			_set_status(&"emote", {"label": String(entry.get("label", ""))})
			return
	_set_status(&"emote_generic")


func _on_online_availability_changed(available: bool, reason: String) -> void:
	var policy_name: String = _online_service.get_backend_policy()
	if _lobby_service != null and _lobby_service.has_method("set_backend_policy"):
		_lobby_service.call("set_backend_policy", policy_name)
	if _lobby_service != null and _lobby_service.has_method("set_backend_mode"):
		_lobby_service.call("set_backend_mode", _online_service.get_backend_mode())
	if not available:
		if policy_name == EOS_BACKEND_POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED:
			_set_status(&"online_required", {"reason": reason})
		else:
			_set_status(&"online_unavailable", {"reason": reason})
	else:
		var mode: String = _online_service.get_backend_mode()
		var detail: String = reason.strip_edges()
		_set_status(&"online_ready", {
			"mode": mode,
			"policy": policy_name,
			"reason": detail if detail != "" else "Sign in to continue.",
		})
	_refresh_button_states()


func _on_login_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	if not _online_service.is_available():
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"online_unavailable", {"reason": _online_service.get_unavailable_reason()})
		return
	var login_res: Dictionary = _online_service.login_account_portal()
	if not bool(login_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"login_failed", {"reason": String(login_res.get("reason", "Unknown error"))})
		return
	if String(login_res.get("code", "")) == "pending":
		_set_status(&"login_pending")
		return
	_set_status(&"login_success", {
		"puid": String(login_res.get("local_puid", "")),
		"display_name": String(login_res.get("display_name", "Player")),
		"mode": String(login_res.get("backend_mode", _online_service.get_backend_mode())),
	})


func _on_login_succeeded(local_puid: String) -> void:
	_lobby_service.set_local_puid(local_puid)
	if _lobby_service.has_method("set_backend_mode"):
		_lobby_service.call("set_backend_mode", _online_service.get_backend_mode())
	if _lobby_service.has_method("set_backend_policy"):
		_lobby_service.call("set_backend_policy", _online_service.get_backend_policy())
	_apply_runtime_profile_to_lobby_service()
	_set_status(&"signed_in", {
		"puid": local_puid,
		"display_name": _resolved_local_display_name(),
	})
	_refresh_button_states()


func _on_login_failed(reason: String) -> void:
	if _menu_audio != null:
		_menu_audio.play_error()
	_set_status(&"login_failed", {"reason": reason})
	_refresh_button_states()


func _on_quick_match_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	if _online_service.local_puid == "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"sign_in_required")
		return
	_quick_match_pending = true
	var search: Dictionary = _lobby_service.search_lobbies({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"open_slots": 1,
		ATTR_PROTOCOL_REV: _local_protocol_revision(),
		ATTR_BUILD_FAMILY: _local_build_family(),
	})
	if not bool(search.get("ok", false)):
		_quick_match_pending = false
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"quick_search_failed", {"reason": String(search.get("reason", "Unknown error"))})
		return
	if String(search.get("code", "")) == "pending":
		_set_status(&"quick_searching")
		return
	_handle_quick_search_result(search.get("lobbies", []))


func _on_private_lobby_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	if _online_service.local_puid == "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"sign_in_required")
		return
	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "INVITE_ONLY",
		ATTR_PROTOCOL_REV: _local_protocol_revision(),
		ATTR_BUILD_FAMILY: _local_build_family(),
	})
	if not bool(create_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"operation_failed", {"reason": String(create_res.get("reason", "Failed to create lobby"))})
		return
	_set_status(&"creating_private_pending" if String(create_res.get("code", "")) == "pending" else &"creating_private_done")


func _on_ready_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_toggle()
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"ready_blocked")
		return
	var ready_now: bool = _current_member_ready(lobby)
	var res: Dictionary = _lobby_service.set_ready(not ready_now)
	if not bool(res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"operation_failed", {"reason": String(res.get("reason", "Failed to update ready"))})
		return
	_set_status(&"ready_pending" if String(res.get("code", "")) == "pending" else &"ready_done")


func _on_start_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	var lobby: Dictionary = _lobby_service.get_current_lobby()
	if lobby.is_empty():
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"start_no_lobby")
		return
	if not _is_local_host(lobby):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"start_not_host")
		return
	if int(lobby.get("members", []).size()) != _player_count:
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"start_need_players", {"count": _player_count})
		return
	if not _all_members_ready(lobby):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"start_need_ready")
		return
	var compatibility_reason: String = _compatibility_reason_for_lobby(lobby)
	if compatibility_reason != "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"start_incompatible", {"reason": compatibility_reason})
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
	_set_status(&"start_publish")
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
		var compatible_lobby: Dictionary = _first_compatible_lobby(lobbies)
		if compatible_lobby.is_empty():
			if _menu_audio != null:
				_menu_audio.play_error()
			var mismatch_reason: String = _compatibility_reason_for_lobby(lobbies[0] as Dictionary)
			_set_status(&"join_incompatible", {"reason": mismatch_reason})
			return
		var lobby_id: String = String(compatible_lobby.get("lobby_id", ""))
		if lobby_id == "":
			if _menu_audio != null:
				_menu_audio.play_error()
			_set_status(&"quick_invalid_lobby")
			return
		var join_res: Dictionary = _lobby_service.join_lobby(lobby_id)
		if not bool(join_res.get("ok", false)):
			if _menu_audio != null:
				_menu_audio.play_error()
			_set_status(&"operation_failed", {"reason": String(join_res.get("reason", "Failed to join lobby"))})
			return
		_set_status(&"joining_lobby" if String(join_res.get("code", "")) == "pending" else &"joined_lobby", {"lobby_id": lobby_id})
		return

	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": _rule_config.ruleset_name,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "PUBLIC",
		ATTR_PROTOCOL_REV: _local_protocol_revision(),
		ATTR_BUILD_FAMILY: _local_build_family(),
	})
	if not bool(create_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"operation_failed", {"reason": String(create_res.get("reason", "Failed to create lobby"))})
		return
	_set_status(&"creating_public_pending" if String(create_res.get("code", "")) == "pending" else &"creating_public_done")


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
		empty_label.modulate = _style_color(&"body_text")
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
		_set_status(&"attr_update_failed", {"reason": String(set_res.get("reason", "Unknown error"))})
		return
	if String(set_res.get("code", "")) == "pending":
		_set_status(&"attr_update", {"key": key})
		return
	_start_attr_queue.remove_at(0)
	call_deferred("_drain_host_start_attr_queue")


func _maybe_launch_match_from_lobby(lobby: Dictionary) -> void:
	if _launch_started:
		return
	var attrs: Dictionary = lobby.get("attrs", {})
	if String(attrs.get("phase", "")) != "MATCH_STARTING":
		return
	var compatibility_reason: String = _compatibility_reason_for_lobby(lobby)
	if compatibility_reason != "":
		_set_status(&"join_incompatible", {"reason": compatibility_reason})
		return
	var seat_by_puid: Dictionary = _extract_or_build_seat_map(lobby)
	if not seat_by_puid.has(_online_service.local_puid):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"seat_map_missing")
		return
	var host_puid: String = String(attrs.get("host_puid", lobby.get("owner_puid", "")))
	if host_puid == "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"start_missing_host")
		return
	var match_seed: int = int(attrs.get("match_seed", _game_seed if _game_seed >= 0 else randi()))
	var match_id: String = String(attrs.get("match_id", ""))

	var scene: PackedScene = GAME_TABLE_3D_SCENE if _presentation_mode == "3d" else GAME_TABLE_2D_SCENE
	var game_table: Node = scene.instantiate()
	var transport = P2P_TRANSPORT_SCRIPT.new()
	if transport.has_method("set_backend_mode"):
		transport.call("set_backend_mode", _online_service.get_backend_mode())
	if transport.has_method("set_backend_policy"):
		transport.call("set_backend_policy", _online_service.get_backend_policy())
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

	var unavailable_reason: String = _online_service.get_unavailable_reason() if _online_service != null else "Online unavailable."
	_set_button_enabled(_login_btn, online_ok, unavailable_reason)
	_set_button_enabled(_quick_btn, logged_in, "Sign in to use quick match.")
	_set_button_enabled(_private_btn, logged_in, "Sign in to create a private lobby.")
	_set_button_enabled(_ready_btn, in_lobby, "Join or create a lobby first.")

	var start_enabled: bool = false
	var start_reason: String = "Join or create a lobby first."
	if in_lobby:
		var compatibility_reason: String = _compatibility_reason_for_lobby(lobby)
		if not local_host:
			start_reason = "Only the host can start."
		elif int(lobby.get("members", []).size()) != _player_count:
			start_reason = "Need %d players to start." % _player_count
		elif not _all_members_ready(lobby):
			start_reason = "All players must be ready."
		elif compatibility_reason != "":
			start_reason = compatibility_reason
		else:
			start_enabled = true
			start_reason = ""
	_set_button_enabled(_start_btn, start_enabled, start_reason)
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
		_texture(ICON_READY_ON_ID if is_ready else ICON_READY_WAIT_ID),
		"Ready" if not is_ready else "Unready",
		0
	)

func _apply_runtime_profile_to_lobby_service() -> void:
	if _lobby_service == null:
		return
	if _lobby_service.has_method("set_runtime_profile"):
		_lobby_service.call("set_runtime_profile", {
			ATTR_DISPLAY_NAME: _resolved_local_display_name(),
			ATTR_BUILD_FAMILY: _local_build_family(),
			ATTR_PROTOCOL_REV: _local_protocol_revision(),
		})

func _resolved_local_display_name() -> String:
	var display_name: String = ""
	if _online_service != null and _online_service.has_method("get_local_display_name"):
		display_name = String(_online_service.call("get_local_display_name")).strip_edges()
	if display_name != "":
		return display_name
	if _online_service != null:
		var puid: String = String(_online_service.local_puid)
		if puid.strip_edges() != "":
			return puid
	return "Player"

func _local_protocol_revision() -> int:
	return int(PROTOCOL_SCRIPT.PROTOCOL_VERSION)

func _local_build_family() -> String:
	return EOS_BACKEND_POLICY_SCRIPT.build_family()

func _first_compatible_lobby(lobbies: Array) -> Dictionary:
	for entry in lobbies:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var lobby: Dictionary = entry as Dictionary
		if _compatibility_reason_for_lobby(lobby) == "":
			return lobby
	return {}

func _compatibility_reason_for_lobby(lobby: Dictionary) -> String:
	if lobby.is_empty():
		return ""
	var attrs: Dictionary = lobby.get("attrs", {})
	var expected_protocol: int = _local_protocol_revision()
	var expected_build: String = _local_build_family()
	var lobby_protocol: int = int(attrs.get(ATTR_PROTOCOL_REV, expected_protocol))
	if lobby_protocol != expected_protocol:
		return "protocol mismatch (local=%d lobby=%d)" % [expected_protocol, lobby_protocol]
	var lobby_build: String = String(attrs.get(ATTR_BUILD_FAMILY, expected_build)).strip_edges().to_lower()
	if lobby_build == "":
		lobby_build = expected_build
	if lobby_build != expected_build:
		return "build family mismatch (local=%s lobby=%s)" % [expected_build, lobby_build]
	for member in lobby.get("members", []):
		if typeof(member) != TYPE_DICTIONARY:
			continue
		var member_dict: Dictionary = member as Dictionary
		var member_attrs: Dictionary = member_dict.get("attrs", {})
		var member_protocol: int = int(member_attrs.get(ATTR_PROTOCOL_REV, lobby_protocol))
		if member_protocol != expected_protocol:
			return "member %s protocol mismatch (%d)" % [String(member_dict.get("puid", "?")), member_protocol]
		var member_build: String = String(member_attrs.get(ATTR_BUILD_FAMILY, lobby_build)).strip_edges().to_lower()
		if member_build != "" and member_build != expected_build:
			return "member %s build mismatch (%s)" % [String(member_dict.get("puid", "?")), member_build]
	return ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if _buttons_grid == null or _root_card == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_width: float = viewport_size.x
	var compact: bool = viewport_width < 980.0
	if viewport_width < 760.0:
		_buttons_grid.columns = 1
	elif viewport_width < 1080.0:
		_buttons_grid.columns = 2
	else:
		_buttons_grid.columns = 3
	var width_pad: float = 74.0 if viewport_width >= 1366.0 else 40.0
	var height_pad: float = 70.0 if viewport_size.y >= 768.0 else 40.0
	var min_size: Vector2 = _style_vector(&"online_card_min")
	var max_size: Vector2 = _style_vector(&"online_card_max")
	var width: float = clampf(viewport_size.x - width_pad, min_size.x, max_size.x)
	var height: float = clampf(viewport_size.y - height_pad, min_size.y, max_size.y)
	_root_card.custom_minimum_size = Vector2(width, height)
	if _roster_scroll != null:
		_roster_scroll.custom_minimum_size.y = clampf(viewport_size.y * 0.32, 180.0, 330.0)
	if _card_margin != null:
		var card_margin: int = 14 if compact else 24
		_card_margin.add_theme_constant_override("margin_left", card_margin)
		_card_margin.add_theme_constant_override("margin_top", card_margin)
		_card_margin.add_theme_constant_override("margin_right", card_margin)
		_card_margin.add_theme_constant_override("margin_bottom", card_margin)
	if _prompt_strip != null:
		_prompt_strip.add_theme_constant_override("separation", 8 if compact else 10)
	if _emote_row != null:
		_emote_row.add_theme_constant_override("separation", 8 if compact else 10)
	if _emote_label != null:
		_emote_label.visible = not (compact and _buttons_grid.columns == 1)


func _set_button_enabled(button: Button, enabled: bool, disabled_reason: String) -> void:
	if button == null:
		return
	button.disabled = not enabled
	button.tooltip_text = "" if enabled else disabled_reason


func _set_status(key: StringName, values: Dictionary = {}) -> void:
	if _status_label == null:
		return
	var template: String = String(STATUS_COPY.get(key, String(key)))
	_status_label.text = _render_status_template(template, values)


func _render_status_template(template: String, values: Dictionary) -> String:
	var rendered: String = template
	for key in values.keys():
		rendered = rendered.replace("{%s}" % String(key), String(values[key]))
	return rendered


func _style_color(id: StringName) -> Color:
	return MENU_STYLE.color(id)


func _style_scalar(id: StringName) -> float:
	return MENU_STYLE.scalar(id)


func _style_vector(id: StringName) -> Vector2:
	return MENU_STYLE.vector(id)
