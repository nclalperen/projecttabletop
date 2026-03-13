extends Control

const GAME_TABLE_2D_SCENE_PATH: String = "res://ui/GameTable.tscn"
const GAME_TABLE_3D_SCENE_PATH: String = "res://ui/GameTable3D.tscn"
const GAME_CATALOG: Script = preload("res://gd/config/TabletopGameCatalog.gd")
const ONLINE_SERVICE_SCRIPT: Script = preload("res://net/OnlineServiceEOS.gd")
const LOBBY_SERVICE_SCRIPT: Script = preload("res://net/LobbyServiceEOS.gd")
const P2P_TRANSPORT_SCRIPT: Script = preload("res://net/P2PTransportEOS.gd")
const HOST_MATCH_CONTROLLER_SCRIPT_PATH: String = "res://net/HostMatchController.gd"
const CLIENT_MATCH_CONTROLLER_SCRIPT_PATH: String = "res://net/ClientMatchController.gd"
const PROTOCOL_SCRIPT: Script = preload("res://net/Protocol.gd")
const EOS_BACKEND_POLICY_SCRIPT: Script = preload("res://net/EOSBackendPolicy.gd")
const MENU_AUDIO_SERVICE_SCRIPT: Script = preload("res://ui/services/MenuAudioService.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const SEAT_SLOT_SCENE: PackedScene = preload("res://ui/widgets/LobbySeatSlot.tscn")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const IMPORTED_FLAGS_ROOT: String = "/root/ImportedFeatureFlags"

const PANEL_GRID_ID: StringName = ASSET_IDS.UI_PANEL_PATTERN_DIAGONAL_TRANSPARENT_SMALL

const ATTR_PROTOCOL_REV: String = "protocol_rev"
const ATTR_BUILD_FAMILY: String = "build_family"
const ATTR_DISPLAY_NAME: String = "display_name"
const ATTR_GAME_ID: String = "game_id"
const ATTR_SEAT_COUNT: String = "seat_count"
const ATTR_SEAT_PLAN_JSON: String = "seat_plan_json"

const ACTION_ADD_BOT: int = 1
const ACTION_INVITE_PLAYER: int = 2
const ACTION_REMOVE_BOT: int = 3
const ACTION_REPLACE_WITH_INVITE: int = 4
const ACTION_RESEND_INVITE: int = 5
const ACTION_CLEAR_SLOT: int = 6

const STATUS_COPY := {
	&"stage_waiting_login": "Sign in to stage a private lobby. Your P0 seat is already reserved.",
	&"online_unavailable": "Online unavailable: {reason}",
	&"online_ready": "Online ready ({mode}, policy: {policy}).",
	&"online_required": "Online requires EOS runtime in this build. {reason}",
	&"login_pending": "Signing in via EOS Account Portal...",
	&"signed_in": "Signed in as {display_name}. Creating your private table...",
	&"login_failed": "Login failed: {reason}",
	&"creating_private_pending": "Creating a private {game} lobby...",
	&"creating_private_done": "Private {game} lobby ready. Fill the remaining seats from the left column.",
	&"operation_failed": "{reason}",
	&"game_updated": "{game} selected. Fill the remaining seats from the left column.",
	&"seat_plan_saved": "Seat plan updated.",
	&"seat_invite_loading": "Loading EOS friends for seat P{seat}...",
	&"seat_invite_overlay_opened": "Epic friends overlay opened.",
	&"seat_invite_overlay_failed": "Could not open Epic friends overlay: {reason}",
	&"seat_invite_sent": "Invite sent to {name}.",
	&"seat_invite_failed": "Invite failed: {reason}",
	&"seat_invite_disabled": "Invites require EOS runtime with friend queries.",
	&"ready_blocked": "Join or create a lobby first.",
	&"ready_pending": "Updating ready state...",
	&"ready_done": "Ready state updated.",
	&"start_no_lobby": "No active lobby.",
	&"start_blocked": "{reason}",
	&"start_local": "Starting local bot table...",
	&"start_publish": "Publishing match start...",
	&"attr_update": "Updating lobby: {key}...",
	&"attr_update_failed": "Failed to update lobby: {reason}",
	&"lobby_error": "Lobby error ({code}): {reason}",
	&"seat_map_missing": "Seat map missing local player.",
	&"start_missing_host": "Match start missing host.",
	&"invite_dialog_empty": "No invitable EOS friends are available for this seat right now.",
}

@onready var _background: TextureRect = $Background
@onready var _backdrop_tint: ColorRect = $BackdropTint
@onready var _root_card: PanelContainer = $Margin/RootCard
@onready var _card_margin: MarginContainer = $Margin/RootCard/CardMargin
@onready var _main_hbox: HBoxContainer = $Margin/RootCard/CardMargin/MainHBox
@onready var _seats_panel: PanelContainer = $Margin/RootCard/CardMargin/MainHBox/SeatsPanel
@onready var _right_panel: PanelContainer = $Margin/RootCard/CardMargin/MainHBox/RightPanel
@onready var _seats_header: Label = $Margin/RootCard/CardMargin/MainHBox/SeatsPanel/SeatsMargin/SeatsVBox/SeatsHeader
@onready var _seats_subheader: Label = $Margin/RootCard/CardMargin/MainHBox/SeatsPanel/SeatsMargin/SeatsVBox/SeatsSubheader
@onready var _seats_scroll: ScrollContainer = $Margin/RootCard/CardMargin/MainHBox/SeatsPanel/SeatsMargin/SeatsVBox/SeatsScroll
@onready var _seats_list: VBoxContainer = $Margin/RootCard/CardMargin/MainHBox/SeatsPanel/SeatsMargin/SeatsVBox/SeatsScroll/SeatsList
@onready var _stage_header: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/StageHeader
@onready var _selected_game_title: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/SelectedGameTitle
@onready var _selected_game_subtitle: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/SelectedGameSubtitle
@onready var _game_buttons_flow: FlowContainer = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/GameButtonsFlow
@onready var _seat_count_header: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/SeatCountHeader
@onready var _seat_count_row: HBoxContainer = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/SeatCountRow
@onready var _game_description: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/GameDescription
@onready var _lock_label: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/LockLabel
@onready var _status_label: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/Status
@onready var _ready_btn: Button = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/ActionButtons/ReadyBtn
@onready var _start_btn: Button = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/ActionButtons/StartBtn
@onready var _back_btn: Button = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/ActionButtons/BackBtn
@onready var _hint_label: Label = $Margin/RootCard/CardMargin/MainHBox/RightPanel/RightMargin/RightVBox/HintLabel
@onready var _quit_btn: Button = $TopRightStatus/TopVBox/QuitRow/QuitBtn
@onready var _online_status_dot: ColorRect = $TopRightStatus/TopVBox/OnlineRow/StatusDot
@onready var _online_status_label: Label = $TopRightStatus/TopVBox/OnlineRow/OnlineStatusLabel
@onready var _login_btn: Button = $TopRightStatus/TopVBox/LoginBtn
@onready var _welcome_label: Label = $TopRightStatus/TopVBox/WelcomeLabel
@onready var _seat_action_menu: PopupMenu = $SeatActionMenu
@onready var _invite_dialog: ConfirmationDialog = $InviteDialog
@onready var _invite_info: Label = $InviteDialog/DialogVBox/InviteInfo
@onready var _overlay_invite_btn: Button = $InviteDialog/DialogVBox/OverlayInviteBtn
@onready var _refresh_friends_btn: Button = $InviteDialog/DialogVBox/RefreshFriendsBtn
@onready var _friends_list: ItemList = $InviteDialog/DialogVBox/FriendsList
@onready var _invite_status: Label = $InviteDialog/DialogVBox/InviteStatus

var _online_service = null
var _lobby_service = null
var _rule_config = null
var _game_seed: int = -1
var _player_count: int = 4
var _presentation_mode: String = "3d"
var _selected_game_id: StringName = GAME_CATALOG.default_game_id()

var _local_seat_plan: Array = []
var _effective_seat_plan: Array = []
var _seat_slot_nodes: Dictionary = {}
var _game_buttons: Dictionary = {}
var _player_count_buttons: Array = []
var _config_attr_queue: Array = []
var _config_focus_after_publish: bool = false
var _start_attr_queue: Array = []
var _pending_seat_action_index: int = -1
var _invite_seat_index: int = -1
var _invite_friends: Array = []
var _creating_lobby: bool = false
var _launch_started: bool = false
var _leave_requested: bool = false
var _active_host_controller = null
var _last_member_connected: Dictionary = {}
var _pending_cleanup_sync: bool = false
var _menu_audio = null


func set_start_config(rule_config, game_seed: int, player_count: int, presentation_mode: String, selected_game_id: StringName = GAME_CATALOG.default_game_id()) -> void:
	_rule_config = rule_config
	_game_seed = game_seed
	_selected_game_id = selected_game_id if GAME_CATALOG.has_game(selected_game_id) else GAME_CATALOG.default_game_id()
	_player_count = GAME_CATALOG.clamp_player_count(_selected_game_id, player_count)
	_presentation_mode = presentation_mode
	_local_seat_plan = _build_default_editable_seat_plan(_player_count)


func _ready() -> void:
	if _menu_audio == null:
		_menu_audio = MENU_AUDIO_SERVICE_SCRIPT.new()
		_menu_audio.name = "MenuAudioService"
		add_child(_menu_audio)
	if _local_seat_plan.is_empty():
		_local_seat_plan = _build_default_editable_seat_plan(_player_count)
	_bind_ui()
	_apply_background_pattern()
	_apply_shell_styles()
	_build_game_selector()
	_rebuild_player_count_buttons()
	_refresh_game_panel()
	_render_seat_slots()
	_apply_responsive_layout()
	_online_service = ONLINE_SERVICE_SCRIPT.new()
	_lobby_service = LOBBY_SERVICE_SCRIPT.new()
	add_child(_online_service)
	add_child(_lobby_service)
	_online_service.availability_changed.connect(_on_online_availability_changed)
	_online_service.login_succeeded.connect(_on_login_succeeded)
	_online_service.login_failed.connect(_on_login_failed)
	_online_service.logged_out.connect(_on_logged_out)
	_lobby_service.lobby_updated.connect(_on_lobby_updated)
	_lobby_service.lobby_error.connect(func(code: String, reason: String) -> void:
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"lobby_error", {"code": code, "reason": reason})
	)
	var init_res: Dictionary = _online_service.initialize()
	_sync_lobby_service_backend()
	_apply_runtime_profile_to_lobby_service()
	if _online_service.local_puid.strip_edges() != "":
		_on_login_succeeded(_online_service.local_puid)
	elif not bool(init_res.get("ok", false)):
		var policy_name: String = String(init_res.get("backend_policy", _online_service.get_backend_policy()))
		var unavailable_reason: String = String(init_res.get("reason", "Online unavailable"))
		if policy_name == EOS_BACKEND_POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED:
			_set_status(&"online_required", {"reason": unavailable_reason})
		else:
			_set_status(&"online_unavailable", {"reason": unavailable_reason})
	else:
		_set_status(&"stage_waiting_login")
	_refresh_online_status_display()
	_refresh_action_buttons()
	call_deferred("_focus_game_selection")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_responsive_layout()


func _bind_ui() -> void:
	_login_btn.pressed.connect(_on_login_pressed)
	_ready_btn.pressed.connect(_on_ready_pressed)
	_start_btn.pressed.connect(_on_start_pressed)
	_back_btn.pressed.connect(_on_back_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	_seat_action_menu.id_pressed.connect(_on_seat_action_selected)
	_invite_dialog.confirmed.connect(_on_invite_dialog_confirmed)
	_overlay_invite_btn.pressed.connect(_on_overlay_invite_pressed)
	_refresh_friends_btn.pressed.connect(_on_refresh_friends_pressed)
	_friends_list.item_selected.connect(_on_friend_selected)
	_invite_dialog.get_ok_button().disabled = true


func _apply_background_pattern() -> void:
	_background.texture = ASSET_REGISTRY.texture(PANEL_GRID_ID)
	_background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_background.stretch_mode = TextureRect.STRETCH_TILE
	_background.modulate = MENU_STYLE.color(&"bg_pattern")
	_backdrop_tint.color = MENU_STYLE.color(&"backdrop_tint")


func _apply_shell_styles() -> void:
	_apply_panel_style(_root_card, Color(0.18, 0.15, 0.11, 0.96), MENU_STYLE.color(&"panel_border"), 18)
	_apply_panel_style(_seats_panel, Color(0.13, 0.11, 0.09, 0.92), Color(0.66, 0.58, 0.47, 0.36), 16)
	_apply_panel_style(_right_panel, Color(0.16, 0.13, 0.1, 0.92), Color(0.66, 0.58, 0.47, 0.36), 16)
	_style_button(_login_btn, true)
	_style_button(_ready_btn, false)
	_style_button(_start_btn, true)
	_style_button(_back_btn, false)
	_style_button(_quit_btn, false, Color(0.48, 0.24, 0.2, 1.0), Color(0.58, 0.28, 0.23, 1.0))
	_style_button(_overlay_invite_btn, false)
	_style_button(_refresh_friends_btn, false)


func _apply_panel_style(panel: PanelContainer, bg: Color, border: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)


func _style_button(button: Button, primary: bool, custom_bg: Color = Color.TRANSPARENT, custom_hover: Color = Color.TRANSPARENT) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 18)
	var normal_bg: Color = custom_bg if custom_bg != Color.TRANSPARENT else (MENU_STYLE.color(&"button_primary_tint") if primary else MENU_STYLE.color(&"button_secondary_tint"))
	var hover_bg: Color = custom_hover if custom_hover != Color.TRANSPARENT else (MENU_STYLE.color(&"button_primary_hover_tint") if primary else MENU_STYLE.color(&"button_secondary_hover_tint"))
	var pressed_bg: Color = MENU_STYLE.color(&"button_primary_pressed_tint") if primary else MENU_STYLE.color(&"button_secondary_pressed_tint")
	var disabled_bg: Color = MENU_STYLE.color(&"button_disabled_tint")
	button.add_theme_stylebox_override("normal", _button_style(normal_bg))
	button.add_theme_stylebox_override("hover", _button_style(hover_bg))
	button.add_theme_stylebox_override("pressed", _button_style(pressed_bg))
	button.add_theme_stylebox_override("disabled", _button_style(disabled_bg))
	button.add_theme_color_override("font_color", MENU_STYLE.color(&"button_primary_font") if primary else MENU_STYLE.color(&"button_secondary_font"))
	button.add_theme_color_override("font_hover_color", MENU_STYLE.color(&"button_primary_hover_font") if primary else MENU_STYLE.color(&"button_secondary_hover_font"))
	button.add_theme_color_override("font_disabled_color", MENU_STYLE.color(&"button_disabled_font"))


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.border_color = Color(0.33, 0.26, 0.18, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _build_game_selector() -> void:
	for child in _game_buttons_flow.get_children():
		child.queue_free()
	_game_buttons.clear()
	for game_id in GAME_CATALOG.all_game_ids():
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(156, 40)
		button.text = GAME_CATALOG.display_name(game_id)
		button.pressed.connect(_on_game_selected.bind(game_id))
		_game_buttons_flow.add_child(button)
		_game_buttons[String(game_id)] = button
	_style_choice_buttons()


func _rebuild_player_count_buttons() -> void:
	for child in _seat_count_row.get_children():
		child.queue_free()
	_player_count_buttons.clear()
	for count in GAME_CATALOG.player_counts(_selected_game_id):
		var button := Button.new()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(64, 38)
		button.text = str(count)
		button.pressed.connect(_on_player_count_selected.bind(count))
		_seat_count_row.add_child(button)
		_player_count_buttons.append(button)
	_style_choice_buttons()


func _style_choice_buttons() -> void:
	var game_locked: bool = _is_game_locked()
	for game_key in _game_buttons.keys():
		var button: Button = _game_buttons[game_key]
		var active: bool = game_key == String(_selected_game_id)
		button.disabled = game_locked and not active
		_style_button(button, active)
		button.button_pressed = active
	for button in _player_count_buttons:
		var count_active: bool = int(button.text) == _player_count
		button.disabled = game_locked
		_style_button(button, count_active)
		button.button_pressed = count_active


func _apply_responsive_layout() -> void:
	if _root_card == null or _card_margin == null or _main_hbox == null or _seats_panel == null or _seats_scroll == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var min_size: Vector2 = MENU_STYLE.vector(&"online_card_min")
	var max_size: Vector2 = MENU_STYLE.vector(&"online_card_max")
	_root_card.custom_minimum_size = Vector2(
		clampf(viewport_size.x - 80.0, min_size.x, max_size.x + 180.0),
		clampf(viewport_size.y - 70.0, min_size.y, max_size.y + 120.0)
	)
	var compact: bool = viewport_size.x < 1320.0
	_card_margin.add_theme_constant_override("margin_left", 18 if compact else 22)
	_card_margin.add_theme_constant_override("margin_top", 18 if compact else 22)
	_card_margin.add_theme_constant_override("margin_right", 18 if compact else 22)
	_card_margin.add_theme_constant_override("margin_bottom", 18 if compact else 22)
	_main_hbox.add_theme_constant_override("separation", 14 if compact else 18)
	_seats_panel.custom_minimum_size.x = 360 if compact else 420
	_seats_scroll.custom_minimum_size.y = clampf(viewport_size.y * 0.55, 320.0, 720.0)


func _refresh_game_panel() -> void:
	_stage_header.text = "Table Locked" if _is_game_locked() else "Choose The Table"
	_selected_game_title.text = GAME_CATALOG.display_name(_selected_game_id)
	_selected_game_subtitle.text = GAME_CATALOG.subtitle(_selected_game_id)
	_seat_count_header.text = "Seat Count"
	_game_description.text = GAME_CATALOG.description(_selected_game_id)
	_seats_header.text = "%s Seats" % GAME_CATALOG.display_name(_selected_game_id)
	_seats_subheader.text = "P0 is always you. Fill the remaining %d seat(s)." % maxi(0, _player_count - 1)
	_lock_label.text = "Game locked because a real guest has already joined." if _is_game_locked() else "Game and seat count stay editable until the first real guest joins."
	_hint_label.text = "Select a table on the right, then click dark seats on the left to add bots or invite players."
	_style_choice_buttons()


func _refresh_online_status_display() -> void:
	if _online_service == null:
		return
	if not _online_service.is_available():
		_online_status_dot.color = MENU_STYLE.color(&"online_status_offline")
		_online_status_label.text = "Offline"
		_login_btn.visible = false
		_welcome_label.visible = false
	elif _online_service.local_puid.strip_edges() == "":
		_online_status_dot.color = MENU_STYLE.color(&"online_status_idle")
		_online_status_label.text = "Not logged in"
		_login_btn.visible = true
		_welcome_label.visible = false
	else:
		_online_status_dot.color = MENU_STYLE.color(&"online_status_online")
		_online_status_label.text = "Online"
		_login_btn.visible = false
		_welcome_label.visible = true
		_welcome_label.text = "Signed in as %s" % _resolved_local_display_name()


func _render_seat_slots() -> void:
	_seat_slot_nodes.clear()
	for child in _seats_list.get_children():
		child.queue_free()
	var plan: Array = _display_seat_plan()
	for slot in plan:
		var seat_node: Node = SEAT_SLOT_SCENE.instantiate()
		_seats_list.add_child(seat_node)
		var seat_dict: Dictionary = slot as Dictionary
		var seat_index: int = int(seat_dict.get("seat", -1))
		var state: String = String(seat_dict.get("state", "open")).strip_edges().to_lower()
		var interactive: bool = _can_edit_seats() and seat_index > 0 and (state == "open" or state == "bot" or state == "invited")
		seat_node.call("configure", seat_dict, _online_service.local_puid if _online_service != null else "", _current_owner_puid(), interactive)
		if interactive:
			seat_node.connect("seat_action_requested", Callable(self, "_on_seat_action_requested"))
		_seat_slot_nodes[seat_index] = seat_node


func _display_seat_plan() -> Array:
	if not _effective_seat_plan.is_empty():
		return _effective_seat_plan
	return _build_provisional_display_plan()


func _build_provisional_display_plan() -> Array:
	var out: Array = []
	var base_plan: Array = _sanitize_local_seat_plan(_local_seat_plan, _player_count)
	var display_name: String = _resolved_local_display_name()
	for slot in base_plan:
		var cloned: Dictionary = (slot as Dictionary).duplicate(true)
		if int(cloned.get("seat", 0)) == 0:
			cloned["state"] = "host"
			cloned["display_name"] = display_name if display_name != "" else "You"
			cloned["puid"] = _online_service.local_puid if _online_service != null else ""
			cloned["ready"] = false
			cloned["status"] = "STAGING"
		elif String(cloned.get("state", "open")) == "open":
			cloned["display_name"] = "Empty Seat"
			cloned["status"] = "OPEN"
		out.append(cloned)
	return out


func _refresh_action_buttons() -> void:
	var lobby: Dictionary = _current_lobby()
	var in_lobby: bool = not lobby.is_empty()
	var ready_now: bool = in_lobby and _current_member_ready(lobby)
	_ready_btn.text = "Unready" if ready_now else "Ready"
	_set_button_enabled(_ready_btn, in_lobby, "Stage a private lobby first.")
	var start_reason: String = _start_block_reason(lobby, _display_seat_plan())
	_set_button_enabled(_start_btn, start_reason == "", start_reason)
	_style_button(_ready_btn, false)
	_style_button(_start_btn, true)
	_style_button(_back_btn, false)


func _set_button_enabled(button: Button, enabled: bool, disabled_reason: String) -> void:
	button.disabled = not enabled
	button.tooltip_text = "" if enabled else disabled_reason


func _focus_game_selection() -> void:
	var target: Button = _game_buttons.get(String(_selected_game_id), null)
	if target != null:
		target.grab_focus()


func _focus_first_actionable_seat() -> void:
	if not _can_edit_seats():
		return
	for seat_index in range(1, _player_count):
		var slot_node = _seat_slot_nodes.get(seat_index, null)
		if slot_node is Control:
			(slot_node as Control).grab_focus()
			return


func _on_online_availability_changed(available: bool, reason: String) -> void:
	_sync_lobby_service_backend()
	_apply_runtime_profile_to_lobby_service()
	if not available:
		var policy_name: String = _online_service.get_backend_policy()
		if policy_name == EOS_BACKEND_POLICY_SCRIPT.POLICY_RUNTIME_REQUIRED:
			_set_status(&"online_required", {"reason": reason})
		else:
			_set_status(&"online_unavailable", {"reason": reason})
	elif _online_service.local_puid.strip_edges() == "":
		_set_status(&"stage_waiting_login")
	_refresh_online_status_display()
	_refresh_action_buttons()


func _on_login_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	var login_res: Dictionary = _online_service.login_account_portal()
	if not bool(login_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"login_failed", {"reason": String(login_res.get("reason", "Unknown error"))})
		return
	if String(login_res.get("code", "")) == "pending":
		_set_status(&"login_pending")
		return
	_on_login_succeeded(String(login_res.get("local_puid", "")))


func _on_login_succeeded(local_puid: String) -> void:
	_sync_lobby_service_backend()
	_lobby_service.set_local_puid(local_puid)
	_apply_runtime_profile_to_lobby_service()
	_set_status(&"signed_in", {"display_name": _resolved_local_display_name()})
	_refresh_online_status_display()
	_refresh_action_buttons()
	call_deferred("_create_staged_lobby_if_needed")


func _on_login_failed(reason: String) -> void:
	if _menu_audio != null:
		_menu_audio.play_error()
	_set_status(&"login_failed", {"reason": reason})
	_refresh_online_status_display()
	_refresh_action_buttons()


func _on_logged_out() -> void:
	_effective_seat_plan.clear()
	_set_status(&"stage_waiting_login")
	_refresh_online_status_display()
	_refresh_action_buttons()
	_render_seat_slots()


func _create_staged_lobby_if_needed() -> void:
	if _online_service == null or _lobby_service == null:
		return
	if _launch_started or _leave_requested or _creating_lobby:
		return
	if _online_service.local_puid.strip_edges() == "":
		return
	if not _current_lobby().is_empty():
		return
	_creating_lobby = true
	var seat_plan_json: String = JSON.stringify(_sanitize_local_seat_plan(_local_seat_plan, _player_count))
	var create_res: Dictionary = _lobby_service.create_lobby({
		"ruleset_id": _selected_ruleset_id(),
		ATTR_GAME_ID: String(_selected_game_id),
		ATTR_SEAT_COUNT: _player_count,
		"version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"phase": "FILLING",
		"privacy": "INVITE_ONLY",
		"max_lobby_members": _player_count,
		ATTR_PROTOCOL_REV: _local_protocol_revision(),
		ATTR_BUILD_FAMILY: _local_build_family(),
		ATTR_SEAT_PLAN_JSON: seat_plan_json,
	})
	if not bool(create_res.get("ok", false)):
		_creating_lobby = false
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"operation_failed", {"reason": String(create_res.get("reason", "Failed to create lobby"))})
		return
	_set_status(&"creating_private_pending" if String(create_res.get("code", "")) == "pending" else &"creating_private_done", {"game": _selected_game_name()})
	_refresh_action_buttons()


func _on_lobby_updated(lobby_model: Dictionary) -> void:
	_creating_lobby = false
	var previous_effective: Array = _effective_seat_plan.duplicate(true)
	if lobby_model.is_empty():
		_effective_seat_plan.clear()
		if not _leave_requested and _online_service != null and _online_service.local_puid.strip_edges() != "":
			_set_status(&"start_no_lobby")
		_render_seat_slots()
		_refresh_action_buttons()
		return
	_sync_selection_from_lobby(lobby_model)
	_sync_local_plan_from_lobby(lobby_model)
	_effective_seat_plan = _lobby_service.get_effective_seat_plan(lobby_model) if _lobby_service.has_method("get_effective_seat_plan") else _build_provisional_display_plan()
	if _reconcile_departed_reserved_humans(previous_effective, lobby_model):
		_pending_cleanup_sync = true
		if _config_attr_queue.is_empty():
			call_deferred("_flush_pending_cleanup_sync")
	_render_seat_slots()
	_refresh_game_panel()
	if String(lobby_model.get("attrs", {}).get("phase", "")) == "FILLING" and _config_attr_queue.is_empty():
		_set_status(&"creating_private_done", {"game": _selected_game_name()})
	if not _config_attr_queue.is_empty() and _is_local_host(lobby_model):
		call_deferred("_drain_config_attr_queue")
	_bridge_member_presence_to_host(lobby_model)
	_maybe_launch_match_from_lobby(lobby_model)
	_refresh_action_buttons()


func _sync_selection_from_lobby(lobby: Dictionary) -> void:
	var lobby_game_id: StringName = _lobby_game_id(lobby)
	var lobby_seat_count: int = _lobby_seat_count(lobby)
	var changed: bool = false
	if GAME_CATALOG.has_game(lobby_game_id) and lobby_game_id != _selected_game_id:
		_selected_game_id = lobby_game_id
		changed = true
	if lobby_seat_count != _player_count:
		_player_count = GAME_CATALOG.clamp_player_count(_selected_game_id, lobby_seat_count)
		changed = true
	if changed:
		_rebuild_player_count_buttons()
	_refresh_game_panel()


func _sync_local_plan_from_lobby(lobby: Dictionary) -> void:
	var raw_json: String = String(lobby.get("attrs", {}).get(ATTR_SEAT_PLAN_JSON, "")).strip_edges()
	if raw_json == "":
		_local_seat_plan = _build_default_editable_seat_plan(_player_count)
		return
	var parsed = JSON.parse_string(raw_json)
	if typeof(parsed) == TYPE_ARRAY:
		_local_seat_plan = _sanitize_local_seat_plan(parsed as Array, _player_count)


func _reconcile_departed_reserved_humans(previous_effective: Array, lobby: Dictionary) -> bool:
	if not _is_local_host(lobby):
		return false
	var members_by_puid: Dictionary = {}
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", "")).strip_edges()
		if puid != "":
			members_by_puid[puid] = true
	_local_seat_plan = _sanitize_local_seat_plan(_local_seat_plan, _player_count)
	var changed: bool = false
	var seat_limit: int = mini(previous_effective.size(), mini(_local_seat_plan.size(), _effective_seat_plan.size()))
	for seat_index in range(1, seat_limit):
		if typeof(previous_effective[seat_index]) != TYPE_DICTIONARY:
			continue
		var previous_slot: Dictionary = previous_effective[seat_index] as Dictionary
		if String(previous_slot.get("state", "open")).strip_edges().to_lower() != "human":
			continue
		var local_slot: Dictionary = _local_seat_plan[seat_index] as Dictionary
		if String(local_slot.get("state", "open")).strip_edges().to_lower() != "invited":
			continue
		var reserved_puid: String = String(local_slot.get("target_puid", "")).strip_edges()
		if reserved_puid == "" or members_by_puid.has(reserved_puid):
			continue
		_local_seat_plan[seat_index] = {"seat": seat_index, "state": "open"}
		_effective_seat_plan[seat_index] = {
			"seat": seat_index,
			"state": "open",
			"display_name": "Empty Seat",
			"ready": false,
			"status": "OPEN",
		}
		changed = true
	return changed


func _flush_pending_cleanup_sync() -> void:
	if not _pending_cleanup_sync:
		return
	var lobby: Dictionary = _current_lobby()
	if lobby.is_empty() or not _is_local_host(lobby):
		_pending_cleanup_sync = false
		return
	if not _config_attr_queue.is_empty():
		return
	_pending_cleanup_sync = false
	_queue_seat_plan_sync()


func _on_game_selected(game_id: StringName) -> void:
	if _is_game_locked():
		return
	if _menu_audio != null:
		_menu_audio.play_toggle()
	_selected_game_id = game_id
	_player_count = GAME_CATALOG.clamp_player_count(_selected_game_id, _player_count)
	_rebuild_player_count_buttons()
	_rebuild_local_seat_plan_preserving_non_human()
	_refresh_game_panel()
	_render_seat_slots()
	_enqueue_config_sync(true, true)
	_set_status(&"game_updated", {"game": _selected_game_name()})


func _on_player_count_selected(count: int) -> void:
	if _is_game_locked():
		return
	if _menu_audio != null:
		_menu_audio.play_toggle()
	_player_count = GAME_CATALOG.clamp_player_count(_selected_game_id, count)
	_rebuild_player_count_buttons()
	_rebuild_local_seat_plan_preserving_non_human()
	_refresh_game_panel()
	_render_seat_slots()
	_enqueue_config_sync(true, true)
	_set_status(&"game_updated", {"game": _selected_game_name()})


func _enqueue_config_sync(reset_ready: bool, focus_after_publish: bool) -> void:
	if _current_lobby().is_empty() or not _is_local_host(_current_lobby()):
		if focus_after_publish:
			call_deferred("_focus_first_actionable_seat")
		return
	_config_attr_queue.clear()
	_config_focus_after_publish = focus_after_publish
	_config_attr_queue.append({"kind": "lobby_attr", "key": ATTR_GAME_ID, "value": String(_selected_game_id)})
	_config_attr_queue.append({"kind": "lobby_attr", "key": ATTR_SEAT_COUNT, "value": _player_count})
	_config_attr_queue.append({"kind": "lobby_attr", "key": "ruleset_id", "value": _selected_ruleset_id()})
	_config_attr_queue.append({"kind": "lobby_attr", "key": ATTR_PROTOCOL_REV, "value": _local_protocol_revision()})
	_config_attr_queue.append({"kind": "lobby_attr", "key": ATTR_BUILD_FAMILY, "value": _local_build_family()})
	_config_attr_queue.append({"kind": "lobby_attr", "key": "phase", "value": "FILLING"})
	if reset_ready:
		_config_attr_queue.append({"kind": "member_attr", "key": "ready", "value": false})
	var sanitized: Array = _sanitize_local_seat_plan(_local_seat_plan, _player_count)
	_config_attr_queue.append({"kind": "seat_plan", "value": sanitized, "json": JSON.stringify(sanitized)})
	_drain_config_attr_queue()


func _queue_seat_plan_sync(focus_after_publish: bool = false) -> void:
	if _current_lobby().is_empty() or not _is_local_host(_current_lobby()):
		_render_seat_slots()
		return
	var sanitized: Array = _sanitize_local_seat_plan(_local_seat_plan, _player_count)
	_config_attr_queue.clear()
	_config_attr_queue.append({"kind": "seat_plan", "value": sanitized, "json": JSON.stringify(sanitized)})
	_config_focus_after_publish = focus_after_publish
	_drain_config_attr_queue()


func _drain_config_attr_queue() -> void:
	if _config_attr_queue.is_empty():
		if _pending_cleanup_sync:
			call_deferred("_flush_pending_cleanup_sync")
		if _config_focus_after_publish:
			_config_focus_after_publish = false
			call_deferred("_focus_first_actionable_seat")
		return
	var lobby: Dictionary = _current_lobby()
	if lobby.is_empty() or not _is_local_host(lobby):
		return
	while not _config_attr_queue.is_empty():
		var head: Dictionary = _config_attr_queue[0]
		if not _config_item_satisfied(lobby, head):
			break
		_config_attr_queue.remove_at(0)
	if _config_attr_queue.is_empty():
		if _pending_cleanup_sync:
			call_deferred("_flush_pending_cleanup_sync")
		if _config_focus_after_publish:
			_config_focus_after_publish = false
			call_deferred("_focus_first_actionable_seat")
		return
	var item: Dictionary = _config_attr_queue[0]
	var result: Dictionary = {}
	match String(item.get("kind", "")):
		"lobby_attr":
			result = _lobby_service.set_lobby_attr(String(item.get("key", "")), item.get("value"))
		"member_attr":
			result = _lobby_service.set_member_attr(String(item.get("key", "")), item.get("value"))
		"seat_plan":
			result = _lobby_service.set_seat_plan(item.get("value", []))
	if not bool(result.get("ok", false)):
		_config_attr_queue.clear()
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"attr_update_failed", {"reason": String(result.get("reason", "Unknown error"))})
		return
	if String(result.get("code", "")) == "pending":
		_set_status(&"attr_update", {"key": String(item.get("key", "seat_plan"))})
		return
	_config_attr_queue.remove_at(0)
	call_deferred("_drain_config_attr_queue")


func _config_item_satisfied(lobby: Dictionary, item: Dictionary) -> bool:
	match String(item.get("kind", "")):
		"lobby_attr":
			return String(lobby.get("attrs", {}).get(String(item.get("key", "")), "")) == String(item.get("value", ""))
		"member_attr":
			return String(_local_member_attr(lobby, String(item.get("key", "")))) == String(item.get("value", ""))
		"seat_plan":
			return String(lobby.get("attrs", {}).get(ATTR_SEAT_PLAN_JSON, "")).strip_edges() == String(item.get("json", "")).strip_edges()
		_:
			return true


func _local_member_attr(lobby: Dictionary, key: String):
	for member in lobby.get("members", []):
		if String(member.get("puid", "")) == _online_service.local_puid:
			return member.get("attrs", {}).get(key)
	return null


func _on_seat_action_requested(seat_index: int, _action_id: StringName) -> void:
	_open_seat_action_menu(seat_index)


func _open_seat_action_menu(seat_index: int) -> void:
	if not _can_edit_seats():
		return
	var slot: Dictionary = _slot_for_index(_display_seat_plan(), seat_index)
	if slot.is_empty() or seat_index <= 0:
		return
	_pending_seat_action_index = seat_index
	_seat_action_menu.clear()
	var slot_state: String = String(slot.get("state", "open")).strip_edges().to_lower()
	match slot_state:
		"bot":
			_seat_action_menu.add_item("Remove Bot", ACTION_REMOVE_BOT)
			_seat_action_menu.add_item("Replace With Invite", ACTION_REPLACE_WITH_INVITE)
			_seat_action_menu.set_item_disabled(1, not _can_invite_humans())
		"invited":
			_seat_action_menu.add_item("Resend Invite", ACTION_RESEND_INVITE)
			_seat_action_menu.set_item_disabled(0, not _can_invite_humans() or String(slot.get("target_puid", "")).strip_edges() == "")
			_seat_action_menu.add_item("Clear Slot", ACTION_CLEAR_SLOT)
		_:
			_seat_action_menu.add_item("Add Bot", ACTION_ADD_BOT)
			_seat_action_menu.add_item("Invite Player", ACTION_INVITE_PLAYER)
			_seat_action_menu.set_item_disabled(1, not _can_invite_humans())
	_seat_action_menu.position = Vector2i(get_global_mouse_position())
	_seat_action_menu.reset_size()
	_seat_action_menu.popup()


func _on_seat_action_selected(action_id: int) -> void:
	if _pending_seat_action_index < 1:
		return
	match action_id:
		ACTION_ADD_BOT:
			_set_local_slot_bot(_pending_seat_action_index)
			_queue_seat_plan_sync()
			_set_status(&"seat_plan_saved")
		ACTION_REMOVE_BOT, ACTION_CLEAR_SLOT:
			_set_local_slot_open(_pending_seat_action_index)
			_queue_seat_plan_sync()
			_set_status(&"seat_plan_saved")
		ACTION_INVITE_PLAYER, ACTION_REPLACE_WITH_INVITE:
			_open_invite_dialog(_pending_seat_action_index)
		ACTION_RESEND_INVITE:
			call_deferred("_resend_seat_invite", _pending_seat_action_index)
	_pending_seat_action_index = -1
	_render_seat_slots()
	_refresh_action_buttons()


func _open_invite_dialog(seat_index: int) -> void:
	_invite_seat_index = seat_index
	_invite_friends.clear()
	_friends_list.clear()
	_invite_status.text = ""
	_invite_info.text = "Choose a friend to invite into P%d." % seat_index
	_overlay_invite_btn.visible = _online_service != null and _online_service.supports_eos_overlay()
	_refresh_friends_btn.disabled = not _can_invite_humans()
	_invite_dialog.get_ok_button().disabled = true
	_invite_dialog.popup_centered(Vector2i(560, 520))
	if _can_invite_humans():
		call_deferred("_load_invitable_friends_for_dialog")
	else:
		_invite_status.text = String(STATUS_COPY[&"seat_invite_disabled"])


func _load_invitable_friends_for_dialog() -> void:
	if _invite_seat_index < 1 or not _can_invite_humans():
		return
	_invite_status.text = _render_status_template(String(STATUS_COPY[&"seat_invite_loading"]), {"seat": _invite_seat_index})
	var result: Dictionary = await _lobby_service.list_invitable_friends()
	if not is_instance_valid(self) or not _invite_dialog.visible:
		return
	if not bool(result.get("ok", false)):
		_invite_status.text = String(result.get("reason", "Failed to load friends"))
		return
	var available_friends: Array = _filter_invitable_friends(result.get("friends", []), _invite_seat_index)
	_invite_friends = available_friends
	_friends_list.clear()
	for friend in available_friends:
		var friend_dict: Dictionary = friend as Dictionary
		var label: String = String(friend_dict.get("display_name", friend_dict.get("product_user_id", "Friend"))).strip_edges()
		var item_index: int = _friends_list.add_item(label)
		_friends_list.set_item_metadata(item_index, friend_dict)
	_invite_status.text = String(STATUS_COPY[&"invite_dialog_empty"]) if available_friends.is_empty() else "Select a friend, then send the invite."


func _filter_invitable_friends(friends: Array, seat_index: int) -> Array:
	var blocked: Dictionary = {}
	for slot in _display_seat_plan():
		if typeof(slot) != TYPE_DICTIONARY:
			continue
		var slot_dict: Dictionary = slot as Dictionary
		if int(slot_dict.get("seat", -1)) == seat_index:
			continue
		var used_puid: String = String(slot_dict.get("puid", slot_dict.get("target_puid", ""))).strip_edges()
		if used_puid != "":
			blocked[used_puid] = true
	var filtered: Array = []
	for friend in friends:
		if typeof(friend) != TYPE_DICTIONARY:
			continue
		var friend_dict: Dictionary = friend as Dictionary
		var target_puid: String = String(friend_dict.get("product_user_id", "")).strip_edges()
		if target_puid != "" and not blocked.has(target_puid):
			filtered.append(friend_dict)
	return filtered


func _on_friend_selected(_index: int) -> void:
	_invite_dialog.get_ok_button().disabled = _friends_list.get_selected_items().is_empty()


func _on_refresh_friends_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	call_deferred("_load_invitable_friends_for_dialog")


func _on_overlay_invite_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_click()
	var result: Dictionary = _online_service.open_friends_overlay()
	if bool(result.get("ok", false)):
		_set_status(&"seat_invite_overlay_opened")
		_invite_status.text = "Epic friends overlay opened."
	else:
		_set_status(&"seat_invite_overlay_failed", {"reason": String(result.get("reason", "Overlay unavailable"))})
		_invite_status.text = String(result.get("reason", "Overlay unavailable"))


func _on_invite_dialog_confirmed() -> void:
	var selected_items: PackedInt32Array = _friends_list.get_selected_items()
	if selected_items.is_empty() or _invite_seat_index < 1:
		return
	var friend: Dictionary = _friends_list.get_item_metadata(selected_items[0]) as Dictionary
	var display_name: String = String(friend.get("display_name", friend.get("product_user_id", "Friend"))).strip_edges()
	_invite_status.text = "Sending invite..."
	var result: Dictionary = await _lobby_service.invite_to_current_lobby(String(friend.get("product_user_id", "")))
	if not is_instance_valid(self):
		return
	if not bool(result.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"seat_invite_failed", {"reason": String(result.get("reason", "Invite failed"))})
		_invite_status.text = String(result.get("reason", "Invite failed"))
		return
	_set_local_slot_invited(_invite_seat_index, friend)
	_queue_seat_plan_sync()
	_invite_dialog.hide()
	_set_status(&"seat_invite_sent", {"name": display_name})
	_render_seat_slots()
	_refresh_action_buttons()


func _resend_seat_invite(seat_index: int) -> void:
	var slot: Dictionary = _slot_for_index(_display_seat_plan(), seat_index)
	if slot.is_empty():
		return
	if not _can_invite_humans():
		_set_status(&"seat_invite_disabled")
		return
	var target_puid: String = String(slot.get("target_puid", "")).strip_edges()
	if target_puid == "":
		_open_invite_dialog(seat_index)
		return
	var invite_res: Dictionary = await _lobby_service.invite_to_current_lobby(target_puid)
	if not bool(invite_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"seat_invite_failed", {"reason": String(invite_res.get("reason", "Invite failed"))})
		return
	_set_status(&"seat_invite_sent", {"name": String(slot.get("display_name", "Player"))})


func _on_ready_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_toggle()
	var lobby: Dictionary = _current_lobby()
	if lobby.is_empty():
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"ready_blocked")
		return
	var ready_res: Dictionary = _lobby_service.set_ready(not _current_member_ready(lobby))
	if not bool(ready_res.get("ok", false)):
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"operation_failed", {"reason": String(ready_res.get("reason", "Failed to update ready"))})
		return
	_set_status(&"ready_pending" if String(ready_res.get("code", "")) == "pending" else &"ready_done")


func _on_start_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_confirm()
	var lobby: Dictionary = _current_lobby()
	var plan: Array = _display_seat_plan()
	if _can_start_local_bot_match(lobby, plan):
		_set_status(&"start_local")
		_launch_local_bot_match(plan)
		return
	if lobby.is_empty():
		_set_status(&"start_no_lobby")
		return
	var block_reason: String = _start_block_reason(lobby, plan)
	if block_reason != "":
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"start_blocked", {"reason": block_reason})
		return
	var seat_by_puid: Dictionary = _build_seat_map_from_plan(plan)
	var match_seed: int = _game_seed if _game_seed >= 0 else randi()
	var match_id: String = String(lobby.get("attrs", {}).get("match_id", ""))
	if match_id == "":
		match_id = "M_%08x" % int(abs(hash("%s|%s" % [_online_service.local_puid, Time.get_unix_time_from_system()])))
	var seat_plan_json: String = JSON.stringify(_sanitize_local_seat_plan(_local_seat_plan, _player_count))
	_start_attr_queue.clear()
	_start_attr_queue.append({"key": "host_puid", "value": _online_service.local_puid})
	_start_attr_queue.append({"key": "match_id", "value": match_id})
	_start_attr_queue.append({"key": "match_seed", "value": match_seed})
	_start_attr_queue.append({"key": "seat_map_json", "value": JSON.stringify(seat_by_puid)})
	_start_attr_queue.append({"key": ATTR_SEAT_PLAN_JSON, "value": seat_plan_json})
	_start_attr_queue.append({"key": "phase", "value": "MATCH_STARTING"})
	_set_status(&"start_publish")
	_drain_host_start_attr_queue()


func _drain_host_start_attr_queue() -> void:
	if _start_attr_queue.is_empty() or _launch_started:
		return
	var lobby: Dictionary = _current_lobby()
	if lobby.is_empty():
		return
	while not _start_attr_queue.is_empty():
		var head: Dictionary = _start_attr_queue[0]
		if String(lobby.get("attrs", {}).get(String(head.get("key", "")), "")) == String(head.get("value", "")):
			_start_attr_queue.remove_at(0)
			continue
		break
	if _start_attr_queue.is_empty():
		return
	var item: Dictionary = _start_attr_queue[0]
	var set_res: Dictionary = _lobby_service.set_lobby_attr(String(item.get("key", "")), item.get("value"))
	if not bool(set_res.get("ok", false)):
		_start_attr_queue.clear()
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"attr_update_failed", {"reason": String(set_res.get("reason", "Unknown error"))})
		return
	if String(set_res.get("code", "")) == "pending":
		_set_status(&"attr_update", {"key": String(item.get("key", ""))})
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
		_set_status(&"start_blocked", {"reason": compatibility_reason})
		return
	var seat_by_puid: Dictionary = _extract_or_build_seat_map(lobby)
	if not seat_by_puid.has(_online_service.local_puid):
		_set_status(&"seat_map_missing")
		return
	var host_puid: String = String(attrs.get("host_puid", lobby.get("owner_puid", "")))
	if host_puid == "":
		_set_status(&"start_missing_host")
		return
	var match_seed: int = int(attrs.get("match_seed", _game_seed if _game_seed >= 0 else randi()))
	var match_id: String = String(attrs.get("match_id", ""))
	var launched_game_id: StringName = _lobby_game_id(lobby)
	if GAME_CATALOG.uses_okey_table(launched_game_id) and not _is_imported_prototype_enabled():
		var scene_path: String = GAME_TABLE_3D_SCENE_PATH if _presentation_mode == "3d" else GAME_TABLE_2D_SCENE_PATH
		var scene: PackedScene = load(scene_path)
		if scene == null:
			_set_status(&"operation_failed", {"reason": "Failed to load the legacy Okey table scene."})
			return
		var game_table: Node = scene.instantiate()
		var host_controller_script: Script = load(HOST_MATCH_CONTROLLER_SCRIPT_PATH)
		var client_controller_script: Script = load(CLIENT_MATCH_CONTROLLER_SCRIPT_PATH)
		if host_controller_script == null or client_controller_script == null:
			_set_status(&"operation_failed", {"reason": "Failed to load the legacy Okey network controllers."})
			return
		var transport = P2P_TRANSPORT_SCRIPT.new()
		if transport.has_method("set_backend_mode"):
			transport.call("set_backend_mode", _online_service.get_backend_mode())
		if transport.has_method("set_backend_policy"):
			transport.call("set_backend_policy", _online_service.get_backend_policy())
		if transport.has_method("set_runtime_context"):
			transport.call("set_runtime_context", String(lobby.get("lobby_id", "")), String(attrs.get("rtc_room_name", "")))
		var controller = null
		if _online_service.local_puid == host_puid:
			controller = host_controller_script.new()
			controller.configure_host(_online_service.local_puid, transport, seat_by_puid, match_id, match_seed)
			controller.start_new_match(_rule_config, match_seed, _lobby_seat_count(lobby))
			_active_host_controller = controller
			_sync_member_presence_baseline(lobby)
		else:
			controller = client_controller_script.new()
			controller.configure_client(_online_service.local_puid, host_puid, transport, int(seat_by_puid.get(_online_service.local_puid, 0)), match_id)
			_active_host_controller = null
		game_table.add_child(transport)
		game_table.add_child(controller)
		if game_table.has_method("inject_controller"):
			game_table.call("inject_controller", controller)
		if game_table.has_method("configure_game"):
			game_table.call("configure_game", _rule_config, match_seed, _lobby_seat_count(lobby))
		_launch_started = true
		_replace_self_in_shell(game_table)
		return
	var target_scene: PackedScene = load(GAME_CATALOG.launch_scene_path(launched_game_id, _presentation_mode))
	if target_scene == null:
		_set_status(&"operation_failed", {"reason": "Failed to load the target table scene."})
		return
	var table_root: Node = target_scene.instantiate()
	if table_root.has_method("configure_table"):
		table_root.call("configure_table", launched_game_id, lobby, _online_service.local_puid, seat_by_puid, match_id, match_seed)
	_active_host_controller = null
	_launch_started = true
	_replace_self_in_shell(table_root)


func _on_back_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_back()
	_leave_requested = true
	if _lobby_service != null and _lobby_service.current_lobby_id != "":
		_lobby_service.leave_lobby()
	get_tree().change_scene_to_file("res://ui/Main.tscn")


func _on_quit_pressed() -> void:
	if _menu_audio != null:
		_menu_audio.play_back()
	get_tree().quit()


func _replace_self_in_shell(next_node: Node) -> void:
	if next_node == null:
		return
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


func _bridge_member_presence_to_host(lobby: Dictionary) -> void:
	if _active_host_controller == null or not _active_host_controller.has_method("mark_peer_disconnected"):
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


func _build_default_editable_seat_plan(seat_count: int) -> Array:
	var out: Array = []
	for seat_index in range(maxi(2, seat_count)):
		if seat_index == 0:
			out.append({"seat": 0, "state": "host", "display_name": "You"})
		else:
			out.append({"seat": seat_index, "state": "open"})
	return out


func _sanitize_local_seat_plan(seat_plan: Array, seat_count: int) -> Array:
	var out: Array = []
	for seat_index in range(maxi(2, seat_count)):
		var source: Dictionary = {}
		if seat_index < seat_plan.size() and typeof(seat_plan[seat_index]) == TYPE_DICTIONARY:
			source = (seat_plan[seat_index] as Dictionary).duplicate(true)
		var state: String = String(source.get("state", "open")).strip_edges().to_lower()
		if seat_index == 0:
			state = "host"
		elif state != "bot" and state != "invited":
			state = "open"
		var slot: Dictionary = {"seat": seat_index, "state": state}
		if state == "host":
			slot["display_name"] = String(source.get("display_name", _resolved_local_display_name())).strip_edges()
		elif state == "bot":
			var bot_name: String = String(source.get("bot_name", source.get("display_name", "Bot %d" % seat_index))).strip_edges()
			slot["bot_name"] = bot_name if bot_name != "" else "Bot %d" % seat_index
			slot["display_name"] = slot["bot_name"]
		elif state == "invited":
			slot["target_puid"] = String(source.get("target_puid", "")).strip_edges()
			slot["epic_account_id"] = String(source.get("epic_account_id", "")).strip_edges()
			slot["display_name"] = String(source.get("display_name", "Invite Pending")).strip_edges()
		out.append(slot)
	return out


func _rebuild_local_seat_plan_preserving_non_human() -> void:
	var previous: Array = _sanitize_local_seat_plan(_local_seat_plan, maxi(_player_count, _local_seat_plan.size()))
	var next_plan: Array = _build_default_editable_seat_plan(_player_count)
	for seat_index in range(1, mini(previous.size(), next_plan.size())):
		var slot: Dictionary = previous[seat_index] as Dictionary
		var state: String = String(slot.get("state", "open")).strip_edges().to_lower()
		if state == "bot" or state == "invited":
			next_plan[seat_index] = slot.duplicate(true)
			next_plan[seat_index]["seat"] = seat_index
	_local_seat_plan = next_plan


func _set_local_slot_open(seat_index: int) -> void:
	_local_seat_plan = _sanitize_local_seat_plan(_local_seat_plan, _player_count)
	if seat_index > 0 and seat_index < _local_seat_plan.size():
		_local_seat_plan[seat_index] = {"seat": seat_index, "state": "open"}


func _set_local_slot_bot(seat_index: int) -> void:
	_local_seat_plan = _sanitize_local_seat_plan(_local_seat_plan, _player_count)
	if seat_index > 0 and seat_index < _local_seat_plan.size():
		_local_seat_plan[seat_index] = {"seat": seat_index, "state": "bot", "bot_name": "Bot %d" % seat_index, "display_name": "Bot %d" % seat_index}


func _set_local_slot_invited(seat_index: int, friend: Dictionary) -> void:
	_local_seat_plan = _sanitize_local_seat_plan(_local_seat_plan, _player_count)
	if seat_index > 0 and seat_index < _local_seat_plan.size():
		_local_seat_plan[seat_index] = {
			"seat": seat_index,
			"state": "invited",
			"target_puid": String(friend.get("product_user_id", "")).strip_edges(),
			"epic_account_id": String(friend.get("epic_account_id", "")).strip_edges(),
			"display_name": String(friend.get("display_name", "Invite Pending")).strip_edges(),
		}


func _slot_for_index(plan: Array, seat_index: int) -> Dictionary:
	for slot in plan:
		if typeof(slot) == TYPE_DICTIONARY and int((slot as Dictionary).get("seat", -1)) == seat_index:
			return slot as Dictionary
	return {}


func _can_edit_seats() -> bool:
	var lobby: Dictionary = _current_lobby()
	if _launch_started or _leave_requested:
		return false
	if lobby.is_empty():
		return true
	return _is_local_host(lobby)


func _can_invite_humans() -> bool:
	return _can_edit_seats() and _online_service != null and _online_service.supports_friend_queries()


func _start_block_reason(lobby: Dictionary, plan: Array) -> String:
	if not _config_attr_queue.is_empty():
		return "Lobby settings are still updating."
	if _can_start_local_bot_match(lobby, plan):
		return ""
	if lobby.is_empty():
		return "No staged lobby yet."
	if not _is_local_host(lobby):
		return "Only the host can start."
	if not _all_seats_filled(plan):
		return "Fill every seat with a player or bot first."
	if not _all_human_slots_ready(plan):
		return "All human players must be ready."
	if _plan_contains_bot(plan) and GAME_CATALOG.uses_okey_table(_lobby_game_id(lobby)) and not _is_imported_prototype_enabled():
		return "Legacy Okey start does not support staged bot seats."
	var compatibility_reason: String = _compatibility_reason_for_lobby(lobby)
	if compatibility_reason != "":
		return compatibility_reason
	return ""


func _all_seats_filled(plan: Array) -> bool:
	for slot in plan:
		if typeof(slot) == TYPE_DICTIONARY:
			var state: String = String((slot as Dictionary).get("state", "open")).strip_edges().to_lower()
			if state == "open" or state == "invited":
				return false
	return not plan.is_empty()


func _all_human_slots_ready(plan: Array) -> bool:
	for slot in plan:
		if typeof(slot) == TYPE_DICTIONARY:
			var slot_dict: Dictionary = slot as Dictionary
			var state: String = String(slot_dict.get("state", "open")).strip_edges().to_lower()
			if (state == "host" or state == "human") and not bool(slot_dict.get("ready", false)):
				return false
	return true


func _plan_contains_bot(plan: Array) -> bool:
	for slot in plan:
		if typeof(slot) == TYPE_DICTIONARY and String((slot as Dictionary).get("state", "open")).strip_edges().to_lower() == "bot":
			return true
	return false


func _can_start_local_bot_match(lobby: Dictionary, plan: Array) -> bool:
	if not lobby.is_empty():
		return false
	if _online_service != null and String(_online_service.local_puid).strip_edges() != "":
		return false
	if not _all_seats_filled(plan):
		return false
	return _plan_is_local_bot_only(plan)


func _plan_is_local_bot_only(plan: Array) -> bool:
	if plan.is_empty():
		return false
	for slot in plan:
		if typeof(slot) != TYPE_DICTIONARY:
			return false
		var state: String = String((slot as Dictionary).get("state", "open")).strip_edges().to_lower()
		if state != "host" and state != "bot":
			return false
	return true


func _launch_local_bot_match(plan: Array) -> void:
	var local_puid: String = _offline_local_puid()
	var match_seed: int = _game_seed if _game_seed >= 0 else randi()
	var match_id: String = "LOCAL_%08x" % int(abs(hash("%s|%s|%s" % [
		String(_selected_game_id),
		local_puid,
		Time.get_unix_time_from_system(),
	])))
	if GAME_CATALOG.uses_okey_table(_selected_game_id) and not _is_imported_prototype_enabled():
		var scene_path: String = GAME_TABLE_3D_SCENE_PATH if _presentation_mode == "3d" else GAME_TABLE_2D_SCENE_PATH
		var local_scene: PackedScene = load(scene_path)
		if local_scene == null and _presentation_mode == "3d":
			scene_path = GAME_TABLE_2D_SCENE_PATH
			local_scene = load(scene_path)
		if local_scene == null:
			if _menu_audio != null:
				_menu_audio.play_error()
			_set_status(&"operation_failed", {"reason": "Failed to load the local legacy Okey table scene."})
			return
		var legacy_table: Node = local_scene.instantiate()
		if legacy_table.has_method("configure_game"):
			legacy_table.call("configure_game", _rule_config, match_seed, _player_count, _bot_difficulties_for_plan(plan))
		_active_host_controller = null
		_launch_started = true
		_replace_self_in_shell(legacy_table)
		return
	var seat_by_puid: Dictionary = {local_puid: 0}
	var synthetic_lobby: Dictionary = _build_offline_lobby_model(plan, local_puid, seat_by_puid, match_id, match_seed)
	var target_scene: PackedScene = load(GAME_CATALOG.launch_scene_path(_selected_game_id, _presentation_mode))
	if target_scene == null:
		if _menu_audio != null:
			_menu_audio.play_error()
		_set_status(&"operation_failed", {"reason": "Failed to load the local table scene."})
		return
	var table_root: Node = target_scene.instantiate()
	if table_root.has_method("configure_table"):
		table_root.call("configure_table", _selected_game_id, synthetic_lobby, local_puid, seat_by_puid, match_id, match_seed)
	_active_host_controller = null
	_launch_started = true
	_replace_self_in_shell(table_root)


func _offline_local_puid() -> String:
	if _online_service != null:
		var actual_puid: String = String(_online_service.local_puid).strip_edges()
		if actual_puid != "":
			return actual_puid
	return "local_host"


func _bot_difficulties_for_plan(plan: Array) -> Array:
	var bot_difficulties: Array = []
	for seat_index in range(1, min(plan.size(), _player_count)):
		if typeof(plan[seat_index]) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = plan[seat_index] as Dictionary
		var state: String = String(slot.get("state", "open")).strip_edges().to_lower()
		if state == "bot":
			bot_difficulties.append("Normal")
	return bot_difficulties


func _build_offline_lobby_model(plan: Array, local_puid: String, seat_by_puid: Dictionary, match_id: String, match_seed: int) -> Dictionary:
	var sanitized: Array = _sanitize_local_seat_plan(plan, _player_count)
	var members: Array = []
	var host_display_name: String = _resolved_local_display_name()
	for slot in sanitized:
		if typeof(slot) != TYPE_DICTIONARY:
			continue
		var slot_dict: Dictionary = slot as Dictionary
		var seat_index: int = int(slot_dict.get("seat", -1))
		var state: String = String(slot_dict.get("state", "open")).strip_edges().to_lower()
		if state == "host":
			members.append({
				"puid": local_puid,
				"attrs": {
					"seat": seat_index,
					"display_name": host_display_name,
					"ready": true,
					"status": "LOCAL_READY",
					ATTR_PROTOCOL_REV: _local_protocol_revision(),
					ATTR_BUILD_FAMILY: _local_build_family(),
				},
			})
		elif state == "bot":
			var bot_name: String = String(slot_dict.get("bot_name", slot_dict.get("display_name", "Bot %d" % seat_index))).strip_edges()
			members.append({
				"puid": "bot_%d" % seat_index,
				"attrs": {
					"seat": seat_index,
					"display_name": bot_name if bot_name != "" else "Bot %d" % seat_index,
					"ready": true,
					"status": "BOT_ACTIVE",
				},
			})
	var attrs: Dictionary = {
		ATTR_GAME_ID: String(_selected_game_id),
		ATTR_SEAT_COUNT: _player_count,
		"ruleset_id": _selected_ruleset_id(),
		ATTR_PROTOCOL_REV: _local_protocol_revision(),
		ATTR_BUILD_FAMILY: _local_build_family(),
		ATTR_SEAT_PLAN_JSON: JSON.stringify(sanitized),
		"host_puid": local_puid,
		"match_id": match_id,
		"match_seed": match_seed,
		"seat_map_json": JSON.stringify(seat_by_puid),
		"phase": "MATCH_STARTING",
		"privacy": "LOCAL_BOTS",
	}
	return {
		"lobby_id": "local_bot_match",
		"owner_puid": local_puid,
		"attrs": attrs,
		"members": members,
	}


func _build_seat_map_from_plan(plan: Array) -> Dictionary:
	var out: Dictionary = {}
	for slot in plan:
		if typeof(slot) != TYPE_DICTIONARY:
			continue
		var slot_dict: Dictionary = slot as Dictionary
		var state: String = String(slot_dict.get("state", "open")).strip_edges().to_lower()
		if state != "host" and state != "human":
			continue
		var puid: String = String(slot_dict.get("puid", "")).strip_edges()
		if puid != "":
			out[puid] = int(slot_dict.get("seat", out.size()))
	return out


func _extract_or_build_seat_map(lobby: Dictionary) -> Dictionary:
	var seat_map_json: String = String(lobby.get("attrs", {}).get("seat_map_json", "")).strip_edges()
	if seat_map_json != "":
		var parsed = JSON.parse_string(seat_map_json)
		if typeof(parsed) == TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key in (parsed as Dictionary).keys():
				out[String(key)] = int((parsed as Dictionary)[key])
			if not out.is_empty():
				return out
	return _build_seat_map_from_plan(_lobby_service.get_effective_seat_plan(lobby))


func _current_lobby() -> Dictionary:
	return _lobby_service.get_current_lobby() if _lobby_service != null else {}


func _is_local_host(lobby: Dictionary) -> bool:
	return _online_service != null and String(lobby.get("owner_puid", "")) == _online_service.local_puid


func _current_member_ready(lobby: Dictionary) -> bool:
	for member in lobby.get("members", []):
		if String(member.get("puid", "")) == _online_service.local_puid:
			return bool(member.get("attrs", {}).get("ready", false))
	return false


func _count_non_host_humans(lobby: Dictionary) -> int:
	var owner_puid: String = String(lobby.get("owner_puid", ""))
	var count: int = 0
	for member in lobby.get("members", []):
		var puid: String = String(member.get("puid", ""))
		if puid != "" and puid != owner_puid:
			count += 1
	return count


func _is_game_locked() -> bool:
	var lobby: Dictionary = _current_lobby()
	return not lobby.is_empty() and _count_non_host_humans(lobby) > 0


func _sync_lobby_service_backend() -> void:
	if _lobby_service == null or _online_service == null:
		return
	_lobby_service.set_local_puid(String(_online_service.local_puid))
	if _lobby_service.has_method("set_backend_mode"):
		_lobby_service.call("set_backend_mode", _online_service.get_backend_mode())
	if _lobby_service.has_method("set_backend_policy"):
		_lobby_service.call("set_backend_policy", _online_service.get_backend_policy())


func _apply_runtime_profile_to_lobby_service() -> void:
	if _lobby_service == null or _online_service == null:
		return
	if _lobby_service.has_method("set_runtime_profile"):
		_lobby_service.call("set_runtime_profile", {
			ATTR_DISPLAY_NAME: _resolved_local_display_name(),
			ATTR_BUILD_FAMILY: _local_build_family(),
			ATTR_PROTOCOL_REV: _local_protocol_revision(),
			"epic_account_id": _online_service.get_epic_account_id() if _online_service.has_method("get_epic_account_id") else "",
		})


func _resolved_local_display_name() -> String:
	if _online_service != null:
		var display_name: String = String(_online_service.get_local_display_name()).strip_edges()
		if display_name != "":
			return display_name
		if String(_online_service.local_puid).strip_edges() != "":
			return String(_online_service.local_puid)
	return "You"


func _selected_game_name() -> String:
	return GAME_CATALOG.display_name(_selected_game_id)


func _selected_ruleset_id() -> String:
	return GAME_CATALOG.ruleset_id(_selected_game_id)


func _lobby_game_id(lobby: Dictionary) -> StringName:
	var raw: String = String(lobby.get("attrs", {}).get(ATTR_GAME_ID, String(_selected_game_id))).strip_edges().to_lower()
	return StringName(raw if raw != "" else String(_selected_game_id))


func _lobby_seat_count(lobby: Dictionary) -> int:
	return maxi(2, int(lobby.get("attrs", {}).get(ATTR_SEAT_COUNT, _player_count)))


func _compatibility_reason_for_lobby(lobby: Dictionary) -> String:
	if lobby.is_empty():
		return ""
	var attrs: Dictionary = lobby.get("attrs", {})
	var lobby_game: String = String(_lobby_game_id(lobby))
	if lobby_game != String(_selected_game_id):
		return "game mismatch (local=%s lobby=%s)" % [String(_selected_game_id), lobby_game]
	var expected_ruleset: String = _selected_ruleset_id()
	var lobby_ruleset: String = String(attrs.get("ruleset_id", expected_ruleset)).strip_edges()
	if lobby_ruleset != expected_ruleset:
		return "ruleset mismatch (local=%s lobby=%s)" % [expected_ruleset, lobby_ruleset]
	var lobby_seat_count: int = _lobby_seat_count(lobby)
	if lobby_seat_count != _player_count:
		return "seat count mismatch (local=%d lobby=%d)" % [_player_count, lobby_seat_count]
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
		var member_attrs: Dictionary = member.get("attrs", {})
		if int(member_attrs.get(ATTR_PROTOCOL_REV, lobby_protocol)) != expected_protocol:
			return "member %s protocol mismatch" % String(member.get("puid", "?"))
		var member_build: String = String(member_attrs.get(ATTR_BUILD_FAMILY, lobby_build)).strip_edges().to_lower()
		if member_build != "" and member_build != expected_build:
			return "member %s build mismatch" % String(member.get("puid", "?"))
	return ""


func _local_protocol_revision() -> int:
	return int(PROTOCOL_SCRIPT.PROTOCOL_VERSION)


func _local_build_family() -> String:
	return EOS_BACKEND_POLICY_SCRIPT.build_family()


func _set_status(key: StringName, values: Dictionary = {}) -> void:
	var template: String = String(STATUS_COPY.get(key, String(key)))
	_status_label.text = _render_status_template(template, values)


func _render_status_template(template: String, values: Dictionary) -> String:
	var rendered: String = template
	for key in values.keys():
		rendered = rendered.replace("{%s}" % String(key), String(values[key]))
	return rendered


func _current_owner_puid() -> String:
	var lobby: Dictionary = _current_lobby()
	if not lobby.is_empty():
		return String(lobby.get("owner_puid", ""))
	return _online_service.local_puid if _online_service != null else ""


func _is_imported_prototype_enabled() -> bool:
	var flags: Node = get_node_or_null(IMPORTED_FLAGS_ROOT)
	return flags != null and flags.has_method("is_prototype_table_enabled") and bool(flags.call("is_prototype_table_enabled"))
