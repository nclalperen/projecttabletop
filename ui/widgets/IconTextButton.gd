extends Button
class_name IconTextButton

const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const BUTTON_GOLD_ID: StringName = ASSET_IDS.UI_BUTTON_RECT_GOLD
const BUTTON_BLUE_ID: StringName = ASSET_IDS.UI_BUTTON_RECT_BLUE

enum ButtonVariant {
	PRIMARY_GOLD = 0,
	SECONDARY_BLUE = 1,
}

@export var icon_texture: Texture2D = null:
	set(value):
		icon_texture = value
		icon = value

@export var button_label: String = "":
	set(value):
		button_label = value
		text = value

@export var style_variant: ButtonVariant = ButtonVariant.PRIMARY_GOLD:
	set(value):
		style_variant = value
		_apply_kenney_button_skin()

func _ready() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = false
	clip_text = true
	if custom_minimum_size.y < 58.0:
		custom_minimum_size = Vector2(custom_minimum_size.x, 58.0)
	if button_label == "":
		button_label = text
	text = button_label
	icon = icon_texture
	add_theme_constant_override("h_separation", 10)
	add_theme_constant_override("outline_size", 1)
	add_theme_font_size_override("font_size", 21)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	_apply_kenney_button_skin()


func _apply_kenney_button_skin() -> void:
	var texture_id: StringName = BUTTON_GOLD_ID
	var font_normal := Color(0.16, 0.12, 0.08, 1.0)
	var font_hover := Color(0.16, 0.12, 0.08, 1.0)
	var normal_tint := Color(1.0, 0.96, 0.86, 1.0)
	var hover_tint := Color(1.04, 1.0, 0.9, 1.0)
	var pressed_tint := Color(0.9, 0.86, 0.78, 1.0)
	var disabled_tint := Color(0.48, 0.45, 0.41, 0.92)
	if style_variant == ButtonVariant.SECONDARY_BLUE:
		texture_id = BUTTON_BLUE_ID
		font_normal = Color(0.96, 0.91, 0.82, 1.0)
		font_hover = Color(1.0, 0.95, 0.84, 1.0)
		normal_tint = Color(0.63, 0.48, 0.33, 1.0)
		hover_tint = Color(0.69, 0.52, 0.36, 1.0)
		pressed_tint = Color(0.56, 0.42, 0.3, 1.0)
		disabled_tint = Color(0.42, 0.35, 0.31, 0.92)
	var texture: Texture2D = ASSET_REGISTRY.texture(texture_id)
	if texture == null:
		return

	add_theme_stylebox_override("normal", _make_button_style(texture, normal_tint))
	add_theme_stylebox_override("hover", _make_button_style(texture, hover_tint))
	add_theme_stylebox_override("pressed", _make_button_style(texture, pressed_tint))
	add_theme_stylebox_override("disabled", _make_button_style(texture, disabled_tint))
	add_theme_color_override("font_color", font_normal)
	add_theme_color_override("font_hover_color", font_hover)
	add_theme_color_override("font_pressed_color", font_normal.darkened(0.1))
	add_theme_color_override("font_disabled_color", Color(0.77, 0.72, 0.65, 0.75))
	add_theme_color_override("icon_normal_color", Color(0.96, 0.93, 0.84, 1.0))
	add_theme_color_override("icon_hover_color", Color(1.0, 0.97, 0.89, 1.0))
	add_theme_color_override("icon_pressed_color", Color(0.9, 0.87, 0.78, 1.0))
	add_theme_color_override("icon_disabled_color", Color(0.66, 0.61, 0.55, 0.8))


func _make_button_style(texture: Texture2D, tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.draw_center = true
	style.texture_margin_left = 14.0
	style.texture_margin_top = 14.0
	style.texture_margin_right = 14.0
	style.texture_margin_bottom = 14.0
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	return style
