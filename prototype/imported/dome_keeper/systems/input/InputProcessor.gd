extends Node

class_name ImportedInputProcessor

var predecessor: ImportedInputProcessor = null
var successor: ImportedInputProcessor = null
var stop_with_predecessor: bool = true
var stop_successors: bool = true
var desintegrating: bool = false
var device_id: int = -1


func can_stop() -> bool:
	return true


func handle(_event: InputEvent) -> bool:
	return false


func handle_start() -> void:
	pass


func handle_stop() -> void:
	pass


func became_leaf() -> void:
	pass


func not_leaf() -> void:
	pass

