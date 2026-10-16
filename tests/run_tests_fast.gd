extends SceneTree

const FULL_RUNNER_SCRIPT: Script = preload("res://tests/run_tests.gd")
const EXCLUDE_MARKERS: Array = [
	"test_bot_long_round_stability.gd",
	"soak_",
]

func _init() -> void:
	var test_scripts: Array = _load_full_test_list()
	var ok: bool = true
	for path in test_scripts:
		if _should_skip(path):
			continue
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script == null:
			push_error("Failed to load test: %s" % path)
			ok = false
			continue
		var test = script.new()
		if not test.run():
			ok = false
		test = null
		script = null
		LocalGameController.free_test_tracked_instances()
		HostMatchController.free_test_tracked_instances()
		ClientMatchController.free_test_tracked_instances()
		P2PTransportEOS.free_test_tracked_instances()
		OnlineServiceEOS.free_test_tracked_instances()
		LobbyServiceEOS.free_test_tracked_instances()

	if ok:
		print("All tests passed (fast)")
	else:
		print("Tests failed (fast)")
	call_deferred("_complete", ok)

func _complete(ok: bool) -> void:
	await process_frame
	await process_frame
	quit(0 if ok else 1)

func _load_full_test_list() -> Array:
	if FULL_RUNNER_SCRIPT == null:
		return []
	var constants: Dictionary = FULL_RUNNER_SCRIPT.get_script_constant_map()
	return (constants.get("TEST_SCRIPTS", []) as Array).duplicate(true)

func _should_skip(path: String) -> bool:
	for marker in EXCLUDE_MARKERS:
		if String(path).findn(String(marker)) >= 0:
			return true
	return false
