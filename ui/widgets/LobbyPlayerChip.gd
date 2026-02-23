extends PanelContainer
class_name LobbyPlayerChip

const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const AVATAR_IDS: Array[StringName] = [
	ASSET_IDS.UI_AVATAR_FACE_1,
	ASSET_IDS.UI_AVATAR_FACE_2,
	ASSET_IDS.UI_AVATAR_FACE_3,
	ASSET_IDS.UI_AVATAR_FACE_4,
]

const ICON_HOST_ID: StringName = ASSET_IDS.UI_ICON_CROWN_A
const ICON_READY_ID: StringName = ASSET_IDS.UI_ICON_CHECKMARK
const ICON_WAITING_ID: StringName = ASSET_IDS.UI_ICON_HOURGLASS

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
	_name_label.modulate = MENU_STYLE.color(&"lobby_player_local") if puid == local_puid else MENU_STYLE.color(&"lobby_player_remote")
	_name_label.text = display_name
	_meta_label.text = "Seat %d | %s" % [seat, status]
	_avatar.texture = _avatar_for_index(seat)
	_host_icon.texture = _texture(ICON_HOST_ID)
	_host_icon.visible = puid == owner_puid
	_ready_icon.texture = _texture(ICON_READY_ID) if ready else _texture(ICON_WAITING_ID)
	_ready_icon.modulate = Color(0.98, 0.88, 0.66, 1.0) if ready else Color(0.92, 0.78, 0.49, 0.95)
	_ready_label.text = "Ready" if ready else "Waiting"
	_ready_label.modulate = MENU_STYLE.color(&"lobby_ready_on") if ready else MENU_STYLE.color(&"lobby_ready_off")


func _avatar_for_index(index: int) -> Texture2D:
	if AVATAR_IDS.is_empty():
		return null
	var wrapped: int = index % AVATAR_IDS.size()
	if wrapped < 0:
		wrapped += AVATAR_IDS.size()
	return _texture(AVATAR_IDS[wrapped])


func _texture(id: StringName) -> Texture2D:
	return ASSET_REGISTRY.texture(id)
