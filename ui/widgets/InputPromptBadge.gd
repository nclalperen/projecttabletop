extends PanelContainer
class_name InputPromptBadge

@onready var _icon_rect: TextureRect = $Margin/HBox/Icon
@onready var _label: Label = $Margin/HBox/Text

@export var prompt_icon: Texture2D = null:
	set(value):
		prompt_icon = value
		if _icon_rect != null:
			_icon_rect.texture = value
			_icon_rect.visible = value != null

@export var prompt_text: String = "":
	set(value):
		prompt_text = value
		if _label != null:
			_label.text = value

func _ready() -> void:
	if _icon_rect != null:
		_icon_rect.texture = prompt_icon
		_icon_rect.visible = prompt_icon != null
		_icon_rect.modulate = Color(0.95, 0.86, 0.67, 1.0)
	if _label != null:
		_label.text = prompt_text
		_label.add_theme_color_override("font_color", Color(0.93, 0.88, 0.76, 0.97))
		_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
		_label.add_theme_constant_override("shadow_offset_x", 1)
		_label.add_theme_constant_override("shadow_offset_y", 1)
		_label.add_theme_font_size_override("font_size", 16)


func configure(icon_texture: Texture2D, value: String) -> void:
	prompt_icon = icon_texture
	prompt_text = value
	if _icon_rect != null:
		_icon_rect.texture = prompt_icon
		_icon_rect.visible = prompt_icon != null
		_icon_rect.modulate = Color(0.95, 0.86, 0.67, 1.0)
	if _label != null:
		_label.text = prompt_text
