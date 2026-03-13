extends Node

const INPUT_PROCESSOR_SCRIPT: Script = preload("res://prototype/imported/dome_keeper/systems/input/InputProcessor.gd")

var processors_to_add: Array = []
var processors_to_remove: Array = []
var processors_changing: bool = false
var game_not_in_focus: bool = false

var _root_processor


func _ready() -> void:
	_root_processor = INPUT_PROCESSOR_SCRIPT.new()
	_root_processor.name = "RootProcessor"
	add_child(_root_processor)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _on_joy_connection_changed(_device_id: int, _connected: bool) -> void:
	pass


func add_processor(processor) -> void:
	if processor == null:
		return
	processors_to_add.append(processor)
	processors_changing = true


func remove_processor(processor) -> void:
	if processor == null:
		return
	processors_to_remove.append(processor)
	processors_changing = true


func clear_processors() -> void:
	var current = get_last_child()
	while current != null and current != _root_processor:
		processors_to_remove.append(current)
		current = current.predecessor
	processors_changing = true


func _process(_delta: float) -> void:
	processors_changing = false
	_apply_removals()
	_apply_additions()


func _unhandled_input(event: InputEvent) -> void:
	if processors_changing or game_not_in_focus:
		return
	var current = get_last_child()
	var handled: bool = false
	while current != null and not handled:
		if current.device_id == -1 or current.device_id == _device_from_event(event):
			handled = bool(current.handle(event))
		if not handled:
			current = current.predecessor


func get_last_child(device_id: int = -1):
	var current = _root_processor
	var last = current
	while current != null and current.successor != null:
		current = current.successor
		if (device_id == -1 or current.device_id == -1 or current.device_id == device_id) and not bool(current.desintegrating):
			last = current
	return last


func _apply_removals() -> void:
	for processor in processors_to_remove.duplicate():
		if processor == null:
			processors_to_remove.erase(processor)
			continue
		if not bool(processor.can_stop()):
			continue
		var pred = processor.predecessor
		var succ = processor.successor
		if pred != null:
			pred.successor = succ
		if succ != null:
			succ.predecessor = pred
		processor.handle_stop()
		if processor.get_parent() != null:
			processor.get_parent().remove_child(processor)
		processor.queue_free()
		processors_to_remove.erase(processor)


func _apply_additions() -> void:
	for processor in processors_to_add:
		var last = get_last_child()
		if processor.get_parent() != null:
			processor.get_parent().remove_child(processor)
		add_child(processor)
		processor.predecessor = last
		last.successor = processor
		processor.handle_start()
		processor.became_leaf()
	processors_to_add.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		game_not_in_focus = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		game_not_in_focus = false


func _device_from_event(event: InputEvent) -> int:
	return event.device

