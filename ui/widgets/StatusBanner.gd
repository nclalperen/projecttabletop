extends PanelContainer
class_name StatusBanner

@onready var _label: Label = $Label

func set_text(text: String) -> void:
	_label.text = text

func set_warning(text: String) -> void:
	_label.text = text
	modulate = Color(1.0, 0.8, 0.6)

func clear_warning() -> void:
	modulate = Color(1, 1, 1)

