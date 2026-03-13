extends "res://prototype/imported/tabletop_club/scripts/game/pieces/Piece.gd"

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	super._ready()
	_rng.randomize()


func get_face_value() -> String:
	var face_values: Dictionary = piece_entry.get("face_values", {})
	if face_values.is_empty():
		return str(_estimate_face_from_rotation())
	var max_dot: float = -INF
	var closest_value: String = "1"
	for value in face_values.keys():
		var normals = face_values[value]
		if typeof(normals) != TYPE_ARRAY:
			continue
		for normal_val in normals:
			if normal_val is Vector3:
				var world_normal: Vector3 = global_transform.basis * (normal_val as Vector3)
				var dotv: float = world_normal.dot(Vector3.UP)
				if dotv > max_dot:
					max_dot = dotv
					closest_value = String(value)
	return closest_value


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_being_shaked():
		var euler := Vector3(
			_rng.randf_range(-PI, PI),
			_rng.randf_range(-PI, PI),
			_rng.randf_range(-PI, PI)
		)
		set_hover_rotation(Quaternion.from_euler(euler))


func _estimate_face_from_rotation() -> int:
	var up_dot_x: float = absf(global_transform.basis.x.dot(Vector3.UP))
	var up_dot_y: float = absf(global_transform.basis.y.dot(Vector3.UP))
	var up_dot_z: float = absf(global_transform.basis.z.dot(Vector3.UP))
	if up_dot_y >= up_dot_x and up_dot_y >= up_dot_z:
		return 1
	if up_dot_x >= up_dot_y and up_dot_x >= up_dot_z:
		return 3
	return 5
