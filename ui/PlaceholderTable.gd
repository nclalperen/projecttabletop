extends Control

const GAME_CATALOG: Script = preload("res://gd/config/TabletopGameCatalog.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")

@onready var _eyebrow: Label = $Margin/RootCard/CardMargin/VBox/Eyebrow
@onready var _title: Label = $Margin/RootCard/CardMargin/VBox/Title
@onready var _subtitle: Label = $Margin/RootCard/CardMargin/VBox/Subtitle
@onready var _summary: Label = $Margin/RootCard/CardMargin/VBox/Summary
@onready var _roster_header: Label = $Margin/RootCard/CardMargin/VBox/RosterHeader
@onready var _roster_list: VBoxContainer = $Margin/RootCard/CardMargin/VBox/RosterList
@onready var _match_meta: Label = $Margin/RootCard/CardMargin/VBox/Footer/MatchMeta
@onready var _back_button: Button = $Margin/RootCard/CardMargin/VBox/Footer/BackButton

var _game_id: StringName = GAME_CATALOG.default_game_id()
var _lobby_model: Dictionary = {}
var _local_puid: String = ""
var _seat_by_puid: Dictionary = {}
var _match_id: String = ""
var _match_seed: int = -1


func _ready() -> void:
	_apply_theme_overrides()
	_back_button.pressed.connect(_on_back_pressed)
	_refresh_view()


func configure_table(game_id: StringName, lobby_model: Dictionary, local_puid: String, seat_by_puid: Dictionary, match_id: String, match_seed: int) -> void:
	_game_id = game_id
	_lobby_model = lobby_model.duplicate(true)
	_local_puid = local_puid
	_seat_by_puid = seat_by_puid.duplicate(true)
	_match_id = match_id
	_match_seed = match_seed
	if is_node_ready():
		_refresh_view()


func _refresh_view() -> void:
	var game_meta: Dictionary = GAME_CATALOG.game(_game_id)
	_eyebrow.text = "%s Multiplayer Table" % GAME_CATALOG.legacy_label(_game_id)
	_title.text = String(game_meta.get("name", "Tabletop"))
	_subtitle.text = String(game_meta.get("subtitle", "Tabletop session"))
	_summary.text = String(game_meta.get("description", ""))
	_roster_header.text = "Table Seats"
	_match_meta.text = "Match: %s  |  Seed: %s  |  Seats: %s" % [
		_match_id if _match_id != "" else "pending",
		"random" if _match_seed < 0 else str(_match_seed),
		String(_lobby_model.get("attrs", {}).get("seat_count", GAME_CATALOG.default_player_count(_game_id))),
	]
	_rebuild_roster()


func _rebuild_roster() -> void:
	for child in _roster_list.get_children():
		child.queue_free()

	var members: Array = (_lobby_model.get("members", []) as Array).duplicate(true)
	members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("attrs", {}).get("seat", 999)) < int(b.get("attrs", {}).get("seat", 999))
	)

	if members.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Waiting for roster data from the lobby."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", MENU_STYLE.color(&"body_text"))
		_roster_list.add_child(empty_label)
		return

	for member in members:
		var row := Label.new()
		var attrs: Dictionary = member.get("attrs", {})
		var seat_index: int = int(attrs.get("seat", _seat_by_puid.get(String(member.get("puid", "")), 0)))
		var display_name: String = String(attrs.get("display_name", member.get("puid", "Player")))
		var local_suffix: String = "  |  You" if String(member.get("puid", "")) == _local_puid else ""
		var host_suffix: String = "  |  Host" if String(member.get("puid", "")) == String(_lobby_model.get("owner_puid", "")) else ""
		var ready_suffix: String = "  |  Ready" if bool(attrs.get("ready", false)) else "  |  Waiting"
		row.text = "Seat %d  |  %s%s%s%s" % [seat_index + 1, display_name, local_suffix, host_suffix, ready_suffix]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 17)
		row.add_theme_color_override("font_color", MENU_STYLE.color(&"body_text"))
		_roster_list.add_child(row)


func _apply_theme_overrides() -> void:
	_eyebrow.add_theme_font_size_override("font_size", 18)
	_eyebrow.add_theme_color_override("font_color", MENU_STYLE.color(&"subtitle_text"))
	_title.add_theme_font_size_override("font_size", 46)
	_title.add_theme_color_override("font_color", MENU_STYLE.color(&"title_text"))
	_subtitle.add_theme_font_size_override("font_size", 24)
	_subtitle.add_theme_color_override("font_color", MENU_STYLE.color(&"subtitle_text"))
	_summary.add_theme_font_size_override("font_size", 18)
	_summary.add_theme_color_override("font_color", MENU_STYLE.color(&"body_text"))
	_roster_header.add_theme_font_size_override("font_size", 22)
	_roster_header.add_theme_color_override("font_color", MENU_STYLE.color(&"title_text"))
	_match_meta.add_theme_font_size_override("font_size", 16)
	_match_meta.add_theme_color_override("font_color", MENU_STYLE.color(&"muted_text"))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/Main.tscn")
