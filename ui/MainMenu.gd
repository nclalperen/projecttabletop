extends Control

const LocalGameController := preload("res://core/controller/LocalGameController.gd")

@onready var _banner: Node = $StatusBanner
var _controller: LocalGameController

func _ready() -> void:
	_controller = LocalGameController.new()
	_controller.state_changed.connect(_on_state_changed)
	_controller.round_cancelled.connect(_on_round_cancelled)
	_controller.action_rejected.connect(_on_action_rejected)

	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Status: Ready")

func _on_state_changed(_state) -> void:
	if _banner != null and _banner.has_method("set_text"):
		_banner.call("set_text", "Status: State updated")

	# Demo: show penalty warning for the first tile in hand during discard phase.
	if _controller.state != null and _controller.state.phase == _controller.state.Phase.TURN_DISCARD:
		var player := _controller.state.current_player_index
		if _controller.state.players[player].hand.size() > 0:
			var tile = _controller.state.players[player].hand[0]
			var info := _controller.get_discard_penalty_info(player, tile.unique_id)
			if info.discard_joker or info.extendable:
				if _banner != null and _banner.has_method("set_warning"):
					_banner.call("set_warning", "Penalty risk on discard (joker/extendable)")

func _on_round_cancelled() -> void:
	if _banner != null and _banner.has_method("set_warning"):
		_banner.call("set_warning", "Round cancelled (all pairs)")

func _on_action_rejected(reason: String) -> void:
	if _banner != null and _banner.has_method("set_warning"):
		_banner.call("set_warning", "Action rejected: %s" % reason)

