extends "res://prototype/imported/tabletop_club/scripts/game/pieces/Piece.gd"

signal absorbing_hovered(container, player_id)
signal releasing_random_piece(container)

@onready var _pieces: Node3D = _ensure_piece_root()

var _srv_is_locked: bool = false


func _ensure_piece_root() -> Node3D:
	var existing := get_node_or_null("Pieces")
	if existing is Node3D:
		return existing as Node3D
	var root := Node3D.new()
	root.name = "Pieces"
	add_child(root)
	return root


func add_piece(piece: Node3D) -> void:
	if piece == null:
		return
	if piece.get_parent() != null:
		piece.get_parent().remove_child(piece)
	piece.position = Vector3(9999, 9999, 9999)
	if piece is RigidBody3D:
		(piece as RigidBody3D).freeze = true
	_pieces.add_child(piece)
	if piece is RigidBody3D:
		mass += maxf(0.0, (piece as RigidBody3D).mass)


func duplicate_piece(piece_name: String) -> Node3D:
	if not _pieces.has_node(piece_name):
		return null
	var original := _pieces.get_node(piece_name)
	return original.duplicate(Node.DUPLICATE_SCRIPTS)


func get_piece_count() -> int:
	return _pieces.get_child_count()


func get_piece_names() -> Array:
	var out: Array = []
	for p in _pieces.get_children():
		out.append(p.name)
	return out


func has_piece(piece_name: String) -> bool:
	return _pieces.has_node(piece_name)


func remove_piece(piece_name: String) -> Node3D:
	if not has_piece(piece_name):
		return null
	var piece := _pieces.get_node(piece_name)
	_pieces.remove_child(piece)
	if piece is RigidBody3D:
		(piece as RigidBody3D).freeze = false
		mass = maxf(0.0, mass - (piece as RigidBody3D).mass)
	return piece


func recalculate_mass() -> void:
	var next_mass: float = 0.0
	for p in _pieces.get_children():
		if p is RigidBody3D:
			next_mass += (p as RigidBody3D).mass
	mass = maxf(0.01, next_mass)


func set_locked_container(is_locked: bool) -> void:
	_srv_is_locked = is_locked
	freeze = is_locked


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _srv_is_locked:
		return
	if is_being_shaked() and get_piece_count() > 0:
		emit_signal("releasing_random_piece", self)

