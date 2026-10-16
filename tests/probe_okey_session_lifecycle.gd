extends SceneTree
## Standalone: --headless --path . --script tests/probe_okey_session_lifecycle.gd
## Exercise both detachment and deletion while a bot worker is thinking.
class SlowBot extends RefCounted:
	func choose_action(_state, _seat):
		OS.delay_msec(100)
		return null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for delete_session in [false, true]:
		var session = load("res://ui/game_table/OkeySession.gd").new()
		session.bots_enabled = false
		root.add_child(session)
		_think(session)
		var worker: Thread = session._active_bot_thread
		if worker == null:
			push_error("Lifecycle probe failed to start the bot worker")
			quit(1)
			return
		if delete_session:
			session.queue_free()
		else:
			root.remove_child(session)
		await process_frame
		await process_frame
		if worker.is_started():
			push_error("Session exit did not join the active bot thread")
			quit(1)
			return
		if not delete_session:
			session.free()
		await process_frame
	print("SESSION BOT EXIT: PASS (detach and queue_free)")
	quit()

func _think(session) -> void:
	await session._compute_bot_action_async(SlowBot.new(), session.get_controller().state, 1)
