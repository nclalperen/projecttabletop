extends RefCounted
## A suite is a passive RefCounted with run() -> bool (optionally async).
## Only the executable runners may start work or quit the engine.

class ErrorCounter extends Logger:
	var errors := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != Logger.ERROR_TYPE_WARNING:
			errors += 1

static func run_suite(path: String, tree: SceneTree) -> bool:
	print("RUN ", path.get_file())
	var error_counter := ErrorCounter.new()
	OS.add_logger(error_counter)
	var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if script == null or not script.can_instantiate() or script.get_instance_base_type() != "RefCounted":
		push_error("Invalid passive test suite: %s" % path)
		OS.remove_logger(error_counter)
		print("ONE_RESULT|FAIL|%s" % path)
		return false
	var initial_children := tree.root.get_children()
	var test = script.new()
	var result: Variant = null
	if test != null and test.has_method("run"):
		result = await test.run()
	var ok: bool = result is bool and result == true
	if not ok:
		push_error("Test failed or did not return true: %s" % path)
	test = null
	script = null
	LocalGameController.free_test_tracked_instances()
	HostMatchController.free_test_tracked_instances()
	ClientMatchController.free_test_tracked_instances()
	P2PTransportEOS.free_test_tracked_instances()
	OnlineServiceEOS.free_test_tracked_instances()
	LobbyServiceEOS.free_test_tracked_instances()
	# Remove test-mounted scene nodes, including those queued for deletion.
	for child in tree.root.get_children():
		if not initial_children.has(child):
			child.free()
	await tree.process_frame
	await tree.process_frame
	ok = ok and error_counter.errors == 0
	OS.remove_logger(error_counter)
	print("ONE_RESULT|%s|%s" % ["PASS" if ok else "FAIL", path])
	return ok
