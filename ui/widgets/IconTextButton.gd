extends Button
class_name IconTextButton

const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")
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
	var min_button_size: Vector2 = MENU_STYLE.vector(&"icon_button_min")
	if custom_minimum_size.y < min_button_size.y:
		custom_minimum_size = Vector2(custom_minimum_size.x, min_button_size.y)
	if button_label == "":
		button_label = text
	text = button_label
	icon = icon_texture
	add_theme_constant_override("h_separation", int(round(MENU_STYLE.scalar(&"button_h_separation"))))
	add_theme_constant_override("outline_size", 1)
	add_theme_font_size_override("font_size", int(round(MENU_STYLE.scalar(&"button_font_size"))))
	add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.2))
	_apply_kenney_button_skin()


func _apply_kenney_button_skin() -> void:
	var texture_id: StringName = BUTTON_GOLD_ID
	var font_normal: Color = MENU_STYLE.color(&"button_primary_font")
	var font_hover: Color = MENU_STYLE.color(&"button_primary_hover_font")
	var normal_tint: Color = MENU_STYLE.color(&"button_primary_tint")
	var hover_tint: Color = MENU_STYLE.color(&"button_primary_hover_tint")
	var pressed_tint: Color = MENU_STYLE.color(&"button_primary_pressed_tint")
	var disabled_tint: Color = MENU_STYLE.color(&"button_disabled_tint")
	if style_variant == ButtonVariant.SECONDARY_BLUE:
		texture_id = BUTTON_BLUE_ID
		font_normal = MENU_STYLE.color(&"button_secondary_font")
		font_hover = MENU_STYLE.color(&"button_secondary_hover_font")
		normal_tint = MENU_STYLE.color(&"button_secondary_tint")
		hover_tint = MENU_STYLE.color(&"button_secondary_hover_tint")
		pressed_tint = MENU_STYLE.color(&"button_secondary_pressed_tint")
		disabled_tint = MENU_STYLE.color(&"button_disabled_tint")
	var texture: Texture2D = ASSET_REGISTRY.texture(texture_id)
	if texture != null:
		add_theme_stylebox_override("normal", _make_button_style(texture, normal_tint))
		add_theme_stylebox_override("hover", _make_button_style(texture, hover_tint))
		add_theme_stylebox_override("pressed", _make_button_style(texture, pressed_tint))
		add_theme_stylebox_override("disabled", _make_button_style(texture, disabled_tint))
	else:
		add_theme_stylebox_override("normal", _make_button_flat(normal_tint))
		add_theme_stylebox_override("hover", _make_button_flat(hover_tint))
		add_theme_stylebox_override("pressed", _make_button_flat(pressed_tint))
		add_theme_stylebox_override("disabled", _make_button_flat(disabled_tint))
	add_theme_color_override("font_color", font_normal)
	add_theme_color_override("font_hover_color", font_hover)
	add_theme_color_override("font_pressed_color", font_normal.darkened(0.08))
	add_theme_color_override("font_disabled_color", MENU_STYLE.color(&"button_disabled_font"))
	add_theme_color_override("icon_normal_color", MENU_STYLE.color(&"button_icon_normal"))
	add_theme_color_override("icon_hover_color", MENU_STYLE.color(&"button_icon_hover"))
	add_theme_color_override("icon_pressed_color", MENU_STYLE.color(&"button_icon_pressed"))
	add_theme_color_override("icon_disabled_color", Color(0.66, 0.61, 0.55, 0.8))


func _make_button_style(texture: Texture2D, tint: Color) -> StyleBoxTexture:
	var panel_margin: float = MENU_STYLE.scalar(&"panel_margin")
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	style.draw_center = true
	style.texture_margin_left = panel_margin + 2.0
	style.texture_margin_top = panel_margin + 2.0
	style.texture_margin_right = panel_margin + 2.0
	style.texture_margin_bottom = panel_margin + 2.0
	style.content_margin_left = panel_margin + 2.0
	style.content_margin_top = panel_margin - 2.0
	style.content_margin_right = panel_margin + 2.0
	style.content_margin_bottom = panel_margin - 2.0
	return style


func _make_button_flat(tint: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = tint.darkened(0.28)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	return style
