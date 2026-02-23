extends Button
class_name LobbyEmoteButton

signal emote_selected(emote_id: String)

const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const BUTTON_GOLD_ID: StringName = ASSET_IDS.UI_BUTTON_RECT_GOLD

@export var emote_id: String = "":
	set(value):
		emote_id = value

@export var emote_label: String = "":
	set(value):
		emote_label = value
		tooltip_text = value

@export var emote_icon: Texture2D = null:
	set(value):
		emote_icon = value
		icon = value

func _ready() -> void:
	if custom_minimum_size.x < 54.0 or custom_minimum_size.y < 54.0:
		custom_minimum_size = Vector2(54.0, 54.0)
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = false
	clip_text = true
	add_theme_constant_override("icon_max_width", 24)
	focus_mode = Control.FOCUS_NONE
	_apply_skin()
	icon = emote_icon
	self_modulate = Color(1, 1, 1, 0.98)
	tooltip_text = emote_label
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)


func configure(id: String, label_text: String, icon_texture: Texture2D) -> void:
	emote_id = id
	emote_label = label_text
	emote_icon = icon_texture
	icon = emote_icon
	tooltip_text = emote_label


func _on_pressed() -> void:
	emote_selected.emit(emote_id)


func _apply_skin() -> void:
	var texture: Texture2D = ASSET_REGISTRY.texture(BUTTON_GOLD_ID)
	if texture == null:
		return
	add_theme_stylebox_override("normal", _style_from(texture, Color(0.96, 0.88, 0.7, 1.0)))
	add_theme_stylebox_override("hover", _style_from(texture, Color(1.0, 0.94, 0.76, 1.0)))
	add_theme_stylebox_override("pressed", _style_from(texture, Color(0.88, 0.79, 0.63, 1.0)))
	add_theme_stylebox_override("disabled", _style_from(texture, Color(0.56, 0.5, 0.43, 0.92)))
	add_theme_color_override("icon_normal_color", Color(0.24, 0.17, 0.1, 1.0))
	add_theme_color_override("icon_hover_color", Color(0.2, 0.14, 0.08, 1.0))
	add_theme_color_override("icon_pressed_color", Color(0.17, 0.12, 0.07, 1.0))


func _style_from(texture: Texture2D, tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.texture_margin_left = 14.0
	style.texture_margin_top = 14.0
	style.texture_margin_right = 14.0
	style.texture_margin_bottom = 14.0
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	return style
