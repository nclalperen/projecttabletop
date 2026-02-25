extends RefCounted
class_name BotBase


static func create(difficulty: String, bot_seed: int = 0):
	match difficulty.to_lower():
		"easy":
			var script: Script = load("res://core/bots/BotEasy.gd")
			return script.new(bot_seed)
		"hard":
			var script: Script = load("res://core/bots/BotHard.gd")
			return script.new(bot_seed)
		_:
			var script: Script = load("res://core/bots/BotHeuristic.gd")
			return script.new()


func choose_action(_state, _player_index: int):
	return null

