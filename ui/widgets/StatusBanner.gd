extends PanelContainer
class_name StatusBanner

@onready var _label: Label = $Label

func set_text(text: String) -> void:
	_label.text = text
	modulate = Color(1, 1, 1, 1)

# Deprecated compatibility shim; retained for external/dynamic callers.
func set_warning(text: String) -> void:
	_label.text = text
	modulate = Color(1.0, 0.9, 0.82)

# Deprecated compatibility shim; retained for external/dynamic callers.
func clear_warning() -> void:
	modulate = Color(1, 1, 1)

