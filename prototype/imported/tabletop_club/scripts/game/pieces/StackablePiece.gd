extends "res://prototype/imported/tabletop_club/scripts/game/pieces/Piece.gd"

signal stack_requested(piece1, piece2)

const DISTANCE_THRESHOLD: float = 0.12
const DOT_STACK_THRESHOLD: float = 0.9

@export var stack_ignore_y_rotation: bool = false


func matches(body: Node) -> bool:
	if body == null:
		return false
	if not body.has_method("get"):
		return false
	var other_entry = body.get("piece_entry")
	if typeof(other_entry) != TYPE_DICTIONARY:
		return false
	var other_dict: Dictionary = other_entry
	var this_scene: String = String(piece_entry.get("scene_path", ""))
	var other_scene: String = String(other_dict.get("scene_path", ""))
	if this_scene != "" and this_scene == other_scene:
		return true
	return String(piece_entry.get("name", name)) == String(other_dict.get("name", body.name))


func can_stack_with(body: Node3D) -> bool:
	if body == null:
		return false
	var me: Transform3D = global_transform
	var you: Transform3D = body.global_transform
	var me_xz: Vector3 = me.origin
	var you_xz: Vector3 = you.origin
	me_xz.y = 0.0
	you_xz.y = 0.0
	if me_xz.distance_to(you_xz) > DISTANCE_THRESHOLD:
		return false
	if absf(me.basis.y.dot(you.basis.y)) <= DOT_STACK_THRESHOLD:
		return false
	if stack_ignore_y_rotation:
		return true
	return absf(me.basis.z.dot(you.basis.z)) > DOT_STACK_THRESHOLD


func try_request_stack_with(body: Node3D) -> bool:
	if body == null:
		return false
	if is_hovering():
		return false
	if body.has_method("is_hovering") and body.call("is_hovering"):
		return false
	if not matches(body):
		return false
	if not can_stack_with(body):
		return false
	emit_signal("stack_requested", self, body)
	return true

