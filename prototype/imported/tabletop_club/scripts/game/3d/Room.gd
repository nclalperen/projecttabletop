extends Node3D

signal setting_spawn_point(position)
signal spawning_piece_at(position)
signal spawning_piece_in_container(container_name)
signal table_flipped()
signal table_unflipped()
signal undo_stack_empty()
signal undo_stack_pushed()

const UNDO_STACK_SIZE_LIMIT: int = 20
const UNDO_STATE_EVENT_TIMEOUTS_MS: Dictionary = {
	"add_piece": 10000,
	"add_piece_to_container": 10000,
	"add_piece_to_stack": 8000,
	"add_stack": 8000,
	"remove_pieces": 5000,
}

var _pieces: Node3D
var _hidden_areas: Node3D
var _hands: Node3D
var _undo_stack: Array = []
var _last_undo_call_ms: Dictionary = {}


func _ready() -> void:
	_pieces = _ensure_child("Pieces")
	_hidden_areas = _ensure_child("HiddenAreas")
	_hands = _ensure_child("Hands")


func add_hand(player: int, transform3d: Transform3D) -> Node3D:
	var hand_script: Script = load("res://prototype/imported/tabletop_club/scripts/game/3d/Hand.gd")
	var hand: Node3D = hand_script.new()
	hand.name = str(player)
	hand.global_transform = transform3d
	_hands.add_child(hand)
	return hand


func add_piece(name: String, transform3d: Transform3D, entry_path: String = "") -> Node3D:
	_push_undo_state("add_piece")
	var factory_script: Script = load("res://prototype/imported/tabletop_club/scripts/PieceFactory.gd")
	var piece_script: Script = load("res://prototype/imported/tabletop_club/scripts/game/pieces/Piece.gd")
	if factory_script == null or piece_script == null:
		push_warning("Imported tabletop scripts unavailable for add_piece.")
		return null
	var piece: Node3D = piece_script.new()
	piece.name = name
	piece.global_transform = transform3d
	piece.set("piece_entry", {"entry_path": entry_path, "name": name, "scene_path": entry_path})
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.04, 0.01, 0.06)
	col.shape = box
	piece.add_child(col)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	piece.add_child(mesh)
	_pieces.add_child(piece)
	return piece


func add_piece_to_container(container_name: String, piece_name: String) -> void:
	var container := _pieces.get_node_or_null(container_name)
	var piece := _pieces.get_node_or_null(piece_name)
	if container == null or piece == null:
		return
	if not container.has_method("add_piece"):
		return
	_push_undo_state("add_piece_to_container")
	_pieces.remove_child(piece)
	container.call("add_piece", piece)


func add_piece_to_stack(piece_name: String, stack_name: String, piece_transform: Transform3D, stack_transform: Transform3D, on: int = 0, flip: int = 0) -> void:
	var piece := _pieces.get_node_or_null(piece_name)
	var stack := _pieces.get_node_or_null(stack_name)
	if piece == null or stack == null:
		return
	if not stack.has_method("add_piece"):
		return
	_push_undo_state("add_piece_to_stack")
	piece.global_transform = piece_transform
	stack.global_transform = stack_transform
	var entry: Dictionary = piece.get("piece_entry") if piece.has_method("get") else {}
	_pieces.remove_child(piece)
	stack.call("add_piece", entry, piece_transform, on, flip)
	piece.queue_free()


func add_stack(name: String, piece1_name: String, piece2_name: String, piece1_transform: Transform3D, piece2_transform: Transform3D) -> Node3D:
	_push_undo_state("add_stack")
	var stack_script: Script = load("res://prototype/imported/tabletop_club/scripts/game/pieces/Stack.gd")
	var stack: Node3D = stack_script.new()
	stack.name = name
	stack.global_transform = piece2_transform
	_pieces.add_child(stack)
	add_piece_to_stack(piece1_name, name, piece1_transform, piece2_transform)
	add_piece_to_stack(piece2_name, name, piece2_transform, piece2_transform)
	return stack


func add_hidden_area(point1: Vector3, point2: Vector3, owner_player_id: int) -> Node3D:
	var hidden_script: Script = load("res://prototype/imported/tabletop_club/scripts/game/3d/HiddenArea.gd")
	var hidden_area: Area3D = hidden_script.new()
	hidden_area.name = "HiddenArea_%d" % _hidden_areas.get_child_count()
	hidden_area.global_position = (point1 + point2) * 0.5
	hidden_area.set("player_id", owner_player_id)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var size: Vector3 = Vector3(absf(point1.x - point2.x), 0.08, absf(point1.z - point2.z))
	box.size = size.max(Vector3(0.1, 0.08, 0.1))
	shape.shape = box
	hidden_area.add_child(shape)
	_hidden_areas.add_child(hidden_area)
	return hidden_area


func remove_pieces(piece_names: Array) -> void:
	_push_undo_state("remove_pieces")
	for n in piece_names:
		var piece := _pieces.get_node_or_null(String(n))
		if piece != null:
			piece.queue_free()


func _ensure_child(name_text: String) -> Node3D:
	var existing := get_node_or_null(name_text)
	if existing is Node3D:
		return existing as Node3D
	var created := Node3D.new()
	created.name = name_text
	add_child(created)
	return created


func _push_undo_state(func_name: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var timeout: int = int(UNDO_STATE_EVENT_TIMEOUTS_MS.get(func_name, 0))
	var last_ms: int = int(_last_undo_call_ms.get(func_name, -1000000))
	if timeout > 0 and now_ms - last_ms < timeout:
		return
	_last_undo_call_ms[func_name] = now_ms
	_undo_stack.push_back({"event": func_name, "ts_ms": now_ms})
	while _undo_stack.size() > UNDO_STACK_SIZE_LIMIT:
		_undo_stack.pop_front()
	if _undo_stack.is_empty():
		emit_signal("undo_stack_empty")
	else:
		emit_signal("undo_stack_pushed")
