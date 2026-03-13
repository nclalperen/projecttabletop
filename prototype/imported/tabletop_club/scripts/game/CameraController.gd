extends Node3D

const TOOL_CURSOR: int = 0
const TOOL_FLICK: int = 1
const TOOL_RULER: int = 2
const TOOL_HIDDEN_AREA: int = 3
const TOOL_PAINT: int = 4
const TOOL_ERASE: int = 5

signal adding_cards_to_hand(cards, id)
signal adding_pieces_to_container(container, pieces)
signal painting(pos1, pos2, color, size)
signal placing_hidden_area(point1, point2)
signal selecting_all_pieces()
signal setting_spawn_point(position)
signal spawning_piece_at(position)

@export var max_speed: float = 10.0
@export var zoom_sensitivity: float = 1.0
@export var hand_preview_enabled: bool = true

var _tool: int = TOOL_CURSOR
var _selected_pieces: Array = []
var _camera: Camera3D = null


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()


func apply_options(config: ConfigFile) -> void:
	if config == null:
		return
	max_speed = float(config.get_value("controls", "camera_movement_speed", 10.0))
	zoom_sensitivity = float(config.get_value("controls", "zoom_sensitivity", 1.0))
	hand_preview_enabled = bool(config.get_value("controls", "hand_preview_enabled", true))


func get_hover_position() -> Vector3:
	if _camera == null:
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return global_position
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = _camera.project_ray_origin(mouse_pos)
	var dir: Vector3 = _camera.project_ray_normal(mouse_pos)
	var to: Vector3 = from + dir * 1000.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.has("position"):
		return hit["position"]
	return to


func set_tool(new_tool: int) -> void:
	_tool = clampi(new_tool, TOOL_CURSOR, TOOL_ERASE)


func get_tool() -> int:
	return _tool


func append_selected_pieces(pieces: Array) -> void:
	for piece in pieces:
		if piece == null:
			continue
		if piece in _selected_pieces:
			continue
		_selected_pieces.append(piece)
		if piece.has_method("set_outline_color"):
			piece.call("set_outline_color", Color(0.36, 0.9, 1.0, 0.85))


func erase_selected_pieces(piece: Node) -> void:
	if piece in _selected_pieces:
		_selected_pieces.erase(piece)
		if piece.has_method("set_outline_color"):
			piece.call("set_outline_color", Color.TRANSPARENT)


func clear_selected_pieces() -> void:
	for piece in _selected_pieces:
		if piece != null and piece.has_method("set_outline_color"):
			piece.call("set_outline_color", Color.TRANSPARENT)
	_selected_pieces.clear()


func get_selected_pieces() -> Array:
	return _selected_pieces.duplicate()


func remove_piece_ref(ref: Node) -> void:
	erase_selected_pieces(ref)

