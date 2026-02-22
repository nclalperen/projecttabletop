extends SceneTree

const DEFAULT_ROUNDS: int = 120
const DEFAULT_MAX_ACTIONS_PER_ROUND: int = 3200


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var rounds: int = _parse_round_count(args)
	var max_actions: int = _parse_max_actions(args)
	var summary: Dictionary = _run_soak(rounds, max_actions)
	var completed: int = int(summary.get("completed_rounds", 0))
	var bot_open_rounds: int = int(summary.get("bot_open_rounds", 0))
	var rejection_counts: Dictionary = summary.get("rejection_counts", {}) as Dictionary
	var completion_rate: float = float(completed) / maxf(1.0, float(rounds))
	var open_freq: float = float(bot_open_rounds) / maxf(1.0, float(rounds))

	print("SOAK_ROUNDS:", rounds)
	print("MAX_ACTIONS_PER_ROUND:", max_actions)
	print("ROUND_COMPLETED:", completed)
	print("ROUND_COMPLETION_RATE:", "%.3f" % completion_rate)
	print("BOT_OPEN_ROUNDS:", bot_open_rounds)
	print("BOT_OPEN_FREQUENCY:", "%.3f" % open_freq)
	print("REJECTION_COUNTS_BEGIN")
	var keys: Array = rejection_counts.keys()
	keys.sort()
	for k in keys:
		print("REJECT[%s]=%d" % [str(k), int(rejection_counts[k])])
	print("REJECTION_COUNTS_END")
	_write_report(rounds, max_actions, completed, completion_rate, bot_open_rounds, open_freq, rejection_counts)

	quit(0 if completed == rounds else 1)


func _parse_round_count(args: PackedStringArray) -> int:
	var env_rounds: String = OS.get_environment("SOAK_ROUNDS")
	if env_rounds != "":
		var env_parsed: int = int(env_rounds)
		if env_parsed > 0:
			return env_parsed
	for arg in args:
		if arg.begins_with("--rounds="):
			var value_text: String = arg.trim_prefix("--rounds=")
			var parsed: int = int(value_text)
			if parsed > 0:
				return parsed
	return DEFAULT_ROUNDS


func _parse_max_actions(args: PackedStringArray) -> int:
	var env_max_actions: String = OS.get_environment("SOAK_MAX_ACTIONS")
	if env_max_actions != "":
		var env_parsed: int = int(env_max_actions)
		if env_parsed > 0:
			return env_parsed
	for arg in args:
		if arg.begins_with("--max-actions="):
			var value_text: String = arg.trim_prefix("--max-actions=")
			var parsed: int = int(value_text)
			if parsed > 0:
				return parsed
	return DEFAULT_MAX_ACTIONS_PER_ROUND


func _run_soak(rounds: int, max_actions_per_round: int) -> Dictionary:
	var cfg := RuleConfig.new()
	var completed_rounds: int = 0
	var bot_open_rounds: int = 0
	var rejection_counts: Dictionary = {}

	for round_i in range(rounds):
		var controller := LocalGameController.new()
		controller.start_new_round(cfg, 990000 + round_i, 4)
		var heuristic := BotHeuristic.new()
		var random_bot := BotRandom.new(1990000 + round_i)
		var actions: int = 0
		var rejection_streak: int = 0
		var saw_bot_open: bool = false

		while controller.state != null and int(controller.state.phase) != int(GameState.Phase.ROUND_END) and actions < max_actions_per_round:
			actions += 1
			for bi in range(1, 4):
				if bool(controller.state.players[bi].has_opened):
					saw_bot_open = true
			var pi: int = int(controller.state.current_player_index)
			var action = heuristic.choose_action(controller.state, pi)
			if action == null:
				action = random_bot.choose_action(controller.state, pi)
			if action == null:
				_add_rejection(rejection_counts, "null_action")
				rejection_streak += 1
				if rejection_streak >= 18:
					break
				continue
			var res: Dictionary = controller.apply_action_if_valid(pi, action)
			if bool(res.get("ok", false)):
				rejection_streak = 0
				continue

			_add_rejection(rejection_counts, str(res.get("code", "unknown")))
			rejection_streak += 1
			var fallback = random_bot.choose_action(controller.state, pi)
			if fallback != null:
				var fallback_res: Dictionary = controller.apply_action_if_valid(pi, fallback)
				if bool(fallback_res.get("ok", false)):
					rejection_streak = 0
					continue
				_add_rejection(rejection_counts, str(fallback_res.get("code", "unknown")))
				rejection_streak += 1
			if rejection_streak >= 18:
				break

		if controller.state != null and int(controller.state.phase) == int(GameState.Phase.ROUND_END):
			completed_rounds += 1
			if saw_bot_open:
				bot_open_rounds += 1
		else:
			_add_rejection(rejection_counts, "round_stall")

	return {
		"completed_rounds": completed_rounds,
		"bot_open_rounds": bot_open_rounds,
		"rejection_counts": rejection_counts,
	}


func _add_rejection(rejection_counts: Dictionary, key: String) -> void:
	rejection_counts[key] = int(rejection_counts.get(key, 0)) + 1


func _write_report(rounds: int, max_actions: int, completed: int, completion_rate: float, bot_open_rounds: int, open_freq: float, rejection_counts: Dictionary) -> void:
	var lines: Array[String] = []
	lines.append("SOAK_ROUNDS=%d" % rounds)
	lines.append("MAX_ACTIONS_PER_ROUND=%d" % max_actions)
	lines.append("ROUND_COMPLETED=%d" % completed)
	lines.append("ROUND_COMPLETION_RATE=%.3f" % completion_rate)
	lines.append("BOT_OPEN_ROUNDS=%d" % bot_open_rounds)
	lines.append("BOT_OPEN_FREQUENCY=%.3f" % open_freq)
	var keys: Array = rejection_counts.keys()
	keys.sort()
	for k in keys:
		lines.append("REJECT_%s=%d" % [str(k), int(rejection_counts[k])])
	var output_paths: Array[String] = ["user://soak_report_latest.txt"]
	for out_path in output_paths:
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		if f == null:
			continue
		for line in lines:
			f.store_line(line)
		f.flush()
