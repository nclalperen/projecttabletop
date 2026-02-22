extends PanelContainer
class_name LobbyPlayerChip

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
	_name_label.modulate = Color(1.0, 0.96, 0.74, 1.0) if puid == local_puid else Color(0.95, 0.97, 1.0, 1.0)
	_name_label.text = display_name
	_meta_label.text = "Seat %d \u00b7 %s" % [seat, status]
	_avatar.texture = _avatar_for_index(seat)
	_host_icon.texture = _texture(ICON_HOST_ID)
	_host_icon.visible = puid == owner_puid
	_ready_icon.texture = _texture(ICON_READY_ID) if ready else _texture(ICON_WAITING_ID)
	_ready_label.text = "Ready" if ready else "Waiting"
	_ready_label.modulate = Color(0.45, 0.86, 0.54) if ready else Color(0.94, 0.8, 0.42)


func _avatar_for_index(index: int) -> Texture2D:
	if AVATAR_IDS.is_empty():
		return null
	var wrapped: int = index % AVATAR_IDS.size()
	if wrapped < 0:
		wrapped += AVATAR_IDS.size()
	return _texture(AVATAR_IDS[wrapped])


func _texture(id: StringName) -> Texture2D:
	return ASSET_REGISTRY.texture(id)
