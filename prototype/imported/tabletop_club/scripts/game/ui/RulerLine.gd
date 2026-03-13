extends Control

var is_metric: bool = true
var point1: Vector3 = Vector3.ZERO
var point2: Vector3 = Vector3.ZERO
var unit_scale: float = 1.0

var _label_visible: bool = true


func set_label_visible(is_visible: bool) -> void:
	_label_visible = is_visible
	queue_redraw()


func is_label_visible() -> bool:
	return _label_visible


func update_ruler(camera: Camera3D) -> void:
	if camera == null:
		return
	var p1: Vector2 = camera.unproject_position(point1)
	var p2: Vector2 = camera.unproject_position(point2)
	var dist_world_cm: float = point1.distance_to(point2) * unit_scale
	var text: String = ""
	if is_metric:
		text = "%.1f cm | %.2f m" % [dist_world_cm, dist_world_cm / 100.0]
	else:
		var inches: float = dist_world_cm * 0.3937008
		text = "%.1f in | %.2f ft" % [inches, inches / 12.0]
	tooltip_text = text
	position = p1
	size = Vector2(maxf(4.0, p1.distance_to(p2)), 4.0)
	rotation = (p2 - p1).angle()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.95, 0.82, 0.2, 0.95))
	if _label_visible:
		draw_string(ThemeDB.fallback_font, Vector2(6, -2), tooltip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.9))
