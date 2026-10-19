extends SceneTree

const FULL_RUNNER_SCRIPT: Script = preload("res://tests/run_tests.gd")
const SUITE_RUNNER = preload("res://tests/TestSuiteRunner.gd")
const EXCLUDE_MARKERS: Array = ["test_bot_long_round_stability.gd", "soak_"]

func _init() -> void:
	call_deferred("_run_all_tests")

func _run_all_tests() -> void:
	var constants: Dictionary = FULL_RUNNER_SCRIPT.get_script_constant_map()
	var paths: Array = constants.get("TEST_SCRIPTS", [])
	var selected: Array = paths.filter(func(path): return not _should_skip(path))
	var ok := not selected.is_empty()
	var completed := 0
	for path in selected:
		if not await SUITE_RUNNER.run_suite(path, self):
			ok = false
		completed += 1
	print("TEST_SUMMARY|%d|%d" % [completed, selected.size()])
	print("All tests passed (fast)" if ok else "Tests failed (fast)")
	quit(0 if ok else 1)

func _should_skip(path: String) -> bool:
	for marker in EXCLUDE_MARKERS:
		if path.contains(marker):
			return true
	return false
