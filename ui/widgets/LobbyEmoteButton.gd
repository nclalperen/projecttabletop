extends Button
class_name LobbyEmoteButton

signal emote_selected(emote_id: String)

const KENNEY_ASSET_LOADER: Script = preload("res://ui/services/KenneyAssetLoader.gd")
const BUTTON_GOLD_PATH := "res://Kenney_c0/kenney_ui-pack/PNG/Yellow/Default/button_rectangle_depth_gradient.png"

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
	if custom_minimum_size.x < 56.0 or custom_minimum_size.y < 56.0:
		custom_minimum_size = Vector2(56.0, 56.0)
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
	var texture: Texture2D = KENNEY_ASSET_LOADER.texture(BUTTON_GOLD_PATH)
	if texture == null:
		return
	add_theme_stylebox_override("normal", _style_from(texture, Color(0.95, 0.95, 0.95, 1.0)))
	add_theme_stylebox_override("hover", _style_from(texture, Color(1.04, 1.04, 1.04, 1.0)))
	add_theme_stylebox_override("pressed", _style_from(texture, Color(0.9, 0.9, 0.9, 1.0)))
	add_theme_stylebox_override("disabled", _style_from(texture, Color(0.55, 0.55, 0.55, 0.92)))


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
