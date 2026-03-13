extends Node

signal finished(order, piece)

var _order_list: Array = []
var _order_list_mutex: Mutex = Mutex.new()
var _next_order_id: int = 0
var _last_accepted_order: int = -1

var _finished_list: Array = []
var _finished_list_mutex: Mutex = Mutex.new()

var _build_thread: Thread = Thread.new()
var _stop_flag: bool = false
var _stop_flag_mutex: Mutex = Mutex.new()


func request(piece_entry: Dictionary) -> int:
	var order_id: int = _next_order_id
	_next_order_id += 1
	_order_list_mutex.lock()
	_order_list.append({"order": order_id, "piece_entry": piece_entry.duplicate(true)})
	_order_list_mutex.unlock()
	if not _build_thread.is_started():
		_build_thread.start(Callable(self, "_build"))
	return order_id


func accept(order: int) -> void:
	_last_accepted_order = order


func cancel(order: int) -> void:
	_order_list_mutex.lock()
	for i in range(_order_list.size() - 1, -1, -1):
		if int(_order_list[i].get("order", -1)) == order:
			_order_list.remove_at(i)
	_order_list_mutex.unlock()


func _process(_delta: float) -> void:
	_finished_list_mutex.lock()
	while not _finished_list.is_empty():
		var item: Dictionary = _finished_list.pop_front()
		var order: int = int(item.get("order", -1))
		var piece: Node3D = item.get("piece", null)
		emit_signal("finished", order, piece)
		if order != _last_accepted_order and piece != null and is_instance_valid(piece):
			piece.queue_free()
	_finished_list_mutex.unlock()


func _exit_tree() -> void:
	_stop_flag_mutex.lock()
	_stop_flag = true
	_stop_flag_mutex.unlock()
	if _build_thread.is_started():
		_build_thread.wait_to_finish()


func _build() -> void:
	while true:
		_stop_flag_mutex.lock()
		var stop_now: bool = _stop_flag
		_stop_flag_mutex.unlock()
		if stop_now:
			return
		var order_item: Dictionary = {}
		_order_list_mutex.lock()
		if not _order_list.is_empty():
			order_item = _order_list.pop_front()
		_order_list_mutex.unlock()
		if order_item.is_empty():
			OS.delay_msec(10)
			continue
		var piece: RigidBody3D = _build_simple_piece(order_item.get("piece_entry", {}))
		_finished_list_mutex.lock()
		_finished_list.append({"order": int(order_item.get("order", -1)), "piece": piece})
		_finished_list_mutex.unlock()


func _build_simple_piece(entry: Dictionary) -> RigidBody3D:
	var piece_script: Script = preload("res://prototype/imported/tabletop_club/scripts/game/pieces/Piece.gd")
	var piece: RigidBody3D = piece_script.new()
	piece.name = String(entry.get("name", "ImportedPiece"))
	piece.set("piece_entry", entry.duplicate(true))
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var scale_vec: Vector3 = Vector3(0.04, 0.01, 0.06)
	if entry.has("scale") and entry["scale"] is Vector3:
		scale_vec = entry["scale"]
	shape.size = scale_vec
	collision.shape = shape
	piece.add_child(collision)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = scale_vec
	mesh.mesh = box
	piece.add_child(mesh)
	return piece
