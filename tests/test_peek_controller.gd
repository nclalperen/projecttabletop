extends RefCounted

const RuleConfig = preload("res://core/rules/RuleConfig.gd")
const LocalGameController = preload("res://core/controller/LocalGameController.gd")

func run() -> bool:
	return _test_peek_discard_controller()

func _test_peek_discard_controller() -> bool:
	var controller = LocalGameController.new()
	var cfg = RuleConfig.new()
	controller.start_new_round(cfg, 9999, 4)

	# Starter discard to move to TURN_DRAW for next player.
	var starter = controller.state.current_player_index
	var tile = controller.state.players[starter].hand[0]
	var res = controller.starter_discard(starter, tile.unique_id)
	if not res.ok:
		push_error("Starter discard failed")
		return false

	var player = controller.state.current_player_index
	var peek = controller.peek_discard(player)
	if not peek.ok:
		push_error("Peek discard failed")
		return false
	return true
