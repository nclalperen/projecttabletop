extends RefCounted
class_name ImportedCompat


static func connect_if_possible(signal_source: Object, signal_name: StringName, callable_target: Callable) -> bool:
	if signal_source == null:
		return false
	if not signal_source.has_signal(signal_name):
		return false
	if signal_source.is_connected(signal_name, callable_target):
		return true
	return signal_source.connect(signal_name, callable_target) == OK


static func disconnect_if_connected(signal_source: Object, signal_name: StringName, callable_target: Callable) -> bool:
	if signal_source == null:
		return false
	if not signal_source.has_signal(signal_name):
		return false
	if not signal_source.is_connected(signal_name, callable_target):
		return true
	return signal_source.disconnect(signal_name, callable_target) == OK


static func ensure_dir(path: String) -> int:
	if path.strip_edges() == "":
		return ERR_INVALID_PARAMETER
	return DirAccess.make_dir_recursive_absolute(path)


static func read_text(path: String, default_text: String = "") -> String:
	if not FileAccess.file_exists(path):
		return default_text
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return default_text
	return f.get_as_text()


static func write_text(path: String, text: String) -> int:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_OPEN
	f.store_string(text)
	return OK


static func has_singleton(name: String) -> bool:
	return Engine.has_singleton(name)


static func call_rpc(node: Node, method_name: StringName, args: Array = []) -> void:
	if node == null:
		return
	if node.has_method(method_name):
		node.callv(method_name, args)


static func call_rpc_id(node: Node, _peer_id: int, method_name: StringName, args: Array = []) -> void:
	# Wrapper kept for compatibility with imported modules that previously used rpc_id.
	call_rpc(node, method_name, args)


static func is_node_valid(node: Node) -> bool:
	return node != null and is_instance_valid(node)
