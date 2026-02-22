extends Button
class_name IconTextButton

const KENNEY_ASSET_LOADER: Script = preload("res://ui/services/KenneyAssetLoader.gd")
const BUTTON_GOLD_PATH := "res://Kenney_c0/kenney_ui-pack/PNG/Yellow/Default/button_rectangle_depth_gradient.png"
const BUTTON_BLUE_PATH := "res://Kenney_c0/kenney_ui-pack/PNG/Blue/Default/button_rectangle_depth_gradient.png"

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
	add_theme_font_size_override("font_size", 23)
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.18))
	_apply_kenney_button_skin()


func _apply_kenney_button_skin() -> void:
	var texture_path: String = BUTTON_GOLD_PATH
	var font_normal := Color(0.08, 0.18, 0.22, 1.0)
	var font_hover := Color(0.08, 0.18, 0.22, 1.0)
	if style_variant == ButtonVariant.SECONDARY_BLUE:
		texture_path = BUTTON_BLUE_PATH
		font_normal = Color(0.95, 0.98, 1.0, 1.0)
		font_hover = Color(1.0, 0.99, 0.88, 1.0)
	var texture: Texture2D = KENNEY_ASSET_LOADER.texture(texture_path)
	if texture == null:
		return

	add_theme_stylebox_override("normal", _make_button_style(texture, Color(1.0, 1.0, 1.0, 1.0)))
	add_theme_stylebox_override("hover", _make_button_style(texture, Color(1.05, 1.05, 1.05, 1.0)))
	add_theme_stylebox_override("pressed", _make_button_style(texture, Color(0.9, 0.9, 0.9, 1.0)))
	add_theme_stylebox_override("disabled", _make_button_style(texture, Color(0.52, 0.52, 0.52, 0.92)))
	add_theme_color_override("font_color", font_normal)
	add_theme_color_override("font_hover_color", font_hover)
	add_theme_color_override("font_pressed_color", font_normal.darkened(0.1))
	add_theme_color_override("font_disabled_color", Color(0.75, 0.78, 0.82, 0.75))


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
