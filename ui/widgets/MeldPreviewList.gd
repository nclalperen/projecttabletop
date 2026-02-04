extends ItemList
class_name MeldPreviewList

signal reorder_requested(from_index: int, to_index: int)
signal remove_requested(index: int)

func _get_drag_data(at_position: Vector2):
	var idx := get_item_at_position(at_position, true)
	if idx == -1:
		return null
	var preview := Label.new()
	preview.text = get_item_text(idx)
	set_drag_preview(preview)
	return {"from": idx}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("from")

func _drop_data(at_position: Vector2, data) -> void:
	var from_idx := int(data["from"])
	var to_idx := get_item_at_position(at_position, true)
	if to_idx == -1:
		to_idx = item_count - 1
	if from_idx == to_idx:
		return
	emit_signal("reorder_requested", from_idx, to_idx)

func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var idx := get_item_at_position(event.position, true)
		if idx != -1:
			emit_signal("remove_requested", idx)
