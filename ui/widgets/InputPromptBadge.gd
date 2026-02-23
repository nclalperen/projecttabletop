extends PanelContainer
class_name InputPromptBadge

const MENU_STYLE: Script = preload("res://ui/services/MenuStyleRegistry.gd")

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
		_icon_rect.modulate = MENU_STYLE.color(&"prompt_icon")
	if _label != null:
		_label.text = prompt_text
		_label.add_theme_color_override("font_color", MENU_STYLE.color(&"prompt_text"))
		_label.add_theme_color_override("font_shadow_color", MENU_STYLE.color(&"prompt_shadow"))
		var shadow_offset: int = int(round(MENU_STYLE.scalar(&"prompt_shadow_offset")))
		_label.add_theme_constant_override("shadow_offset_x", shadow_offset)
		_label.add_theme_constant_override("shadow_offset_y", shadow_offset)
		_label.add_theme_font_size_override("font_size", int(round(MENU_STYLE.scalar(&"prompt_font_size"))))


func configure(icon_texture: Texture2D, value: String) -> void:
	prompt_icon = icon_texture
	prompt_text = value
	if _icon_rect != null:
		_icon_rect.texture = prompt_icon
		_icon_rect.visible = prompt_icon != null
		_icon_rect.modulate = MENU_STYLE.color(&"prompt_icon")
	if _label != null:
		_label.text = prompt_text
