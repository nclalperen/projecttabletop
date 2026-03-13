extends "res://prototype/imported/tabletop_club/scripts/game/pieces/StackablePiece.gd"

signal card_exiting_tree(card)

var over_hands: Array = []


func is_collisions_on() -> bool:
	return collision_layer != 0


func set_collisions_on(on: bool) -> void:
	collision_layer = 1 if on else 0
	collision_mask = 1 if on else 0


@rpc("any_peer", "call_local")
func rpc_set_collisions_on(on: bool) -> void:
	set_collisions_on(on)


func _exit_tree() -> void:
	emit_signal("card_exiting_tree", self)

