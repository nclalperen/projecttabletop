extends SceneTree

const SUITE_RUNNER = preload("res://tests/TestSuiteRunner.gd")

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--test="):
			path = argument.trim_prefix("--test=")
	if path.is_empty():
		push_error("Provide -- --test=res://tests/test_name.gd")
		quit(2)
		return
	var ok: bool = await SUITE_RUNNER.run_suite(path, self)
	quit(0 if ok else 1)
