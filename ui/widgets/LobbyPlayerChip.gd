extends PanelContainer
class_name LobbyPlayerChip

const KENNEY_ASSET_LOADER: Script = preload("res://ui/services/KenneyAssetLoader.gd")
const AVATAR_PATHS: Array[String] = [
	"res://Kenney_c0/kenney_modular-characters/PNG/Face/Completes/face1.png",
	"res://Kenney_c0/kenney_modular-characters/PNG/Face/Completes/face2.png",
	"res://Kenney_c0/kenney_modular-characters/PNG/Face/Completes/face3.png",
	"res://Kenney_c0/kenney_modular-characters/PNG/Face/Completes/face4.png",
]

const ICON_HOST_PATH := "res://Kenney_c0/kenney_board-game-icons/PNG/Default (64px)/crown_a.png"
const ICON_READY_PATH := "res://Kenney_c0/kenney_game-icons/PNG/White/1x/checkmark.png"
const ICON_WAITING_PATH := "res://Kenney_c0/kenney_board-game-icons/PNG/Default (64px)/hourglass.png"

@onready var _avatar: TextureRect = $Margin/HBox/Avatar
@onready var _name_label: Label = $Margin/HBox/Info/Name
@onready var _meta_label: Label = $Margin/HBox/Info/Meta
@onready var _host_icon: TextureRect = $Margin/HBox/Badges/HostIcon
@onready var _ready_icon: TextureRect = $Margin/HBox/Badges/ReadyIcon
@onready var _ready_label: Label = $Margin/HBox/Badges/ReadyLabel

func set_member(member: Dictionary, owner_puid: String, local_puid: String) -> void:
	var puid: String = String(member.get("puid", ""))
	var attrs: Dictionary = member.get("attrs", {})
	var seat: int = int(attrs.get("seat", 0))
	var ready: bool = bool(attrs.get("ready", false))
	var status: String = String(attrs.get("status", "OK")).to_upper()
	var display_name: String = puid
	if puid == local_puid:
		display_name = "%s (You)" % puid
	_name_label.modulate = Color(1.0, 0.96, 0.74, 1.0) if puid == local_puid else Color(0.95, 0.97, 1.0, 1.0)
	_name_label.text = display_name
	_meta_label.text = "Seat %d \u00b7 %s" % [seat, status]
	_avatar.texture = _avatar_for_index(seat)
	_host_icon.texture = _texture(ICON_HOST_PATH)
	_host_icon.visible = puid == owner_puid
	_ready_icon.texture = _texture(ICON_READY_PATH) if ready else _texture(ICON_WAITING_PATH)
	_ready_label.text = "Ready" if ready else "Waiting"
	_ready_label.modulate = Color(0.45, 0.86, 0.54) if ready else Color(0.94, 0.8, 0.42)


func _avatar_for_index(index: int) -> Texture2D:
	if AVATAR_PATHS.is_empty():
		return null
	var wrapped: int = index % AVATAR_PATHS.size()
	if wrapped < 0:
		wrapped += AVATAR_PATHS.size()
	return _texture(AVATAR_PATHS[wrapped])


func _texture(path: String) -> Texture2D:
	return KENNEY_ASSET_LOADER.texture(path)
