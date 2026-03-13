extends Node3D

const CARD_HEIGHT_DIFF: float = 0.005

@export var hand_width: float = 0.45

var _srv_cards: Array = []
var _owner_color: Color = Color(0.24, 0.62, 0.96, 0.65)
var _owner_name: String = "Player"


func owner_id() -> int:
	return int(name) if String(name).is_valid_int() else 0


func set_owner_display_data(player_name: String, color: Color) -> void:
	_owner_name = player_name
	_owner_color = color


func update_owner_display() -> void:
	# Preserved API contract from source import; visual owner display is driven by scene UI.
	pass


func srv_add_card(card: Node3D) -> bool:
	if card == null:
		return false
	if card in _srv_cards:
		return true
	if card.has_method("start_hovering"):
		card.call("start_hovering", owner_id(), global_position, Vector3.ZERO)
	_srv_cards.append(card)
	_srv_set_card_positions()
	return true


func srv_clear_cards(_play_sound: bool = true) -> void:
	for card in _srv_cards.duplicate():
		srv_remove_card(card, false)


func srv_remove_card(card: Node3D, _play_sound: bool = true) -> void:
	_srv_cards.erase(card)
	_srv_set_card_positions()
	if card != null and card.has_method("rpc_set_collisions_on"):
		card.call("rpc_set_collisions_on", true)


func _srv_set_card_positions() -> void:
	if _srv_cards.is_empty():
		return
	var total_w: float = 0.0
	var widths: Array[float] = []
	for card in _srv_cards:
		var w: float = 0.04
		if card != null and card.has_method("get_size"):
			var s: Vector3 = card.call("get_size")
			w = maxf(0.01, s.x)
		total_w += w
		widths.append(w)
	var spacing: float = 0.0
	if _srv_cards.size() > 1:
		spacing = minf((hand_width - total_w) / float(_srv_cards.size() - 1), 0.0)
	var x: float = -hand_width * 0.5 + widths[0] * 0.5
	for i in _srv_cards.size():
		var card = _srv_cards[i]
		if card == null:
			continue
		var offset := transform.basis.x * x
		if total_w > hand_width:
			offset += transform.basis.y * (CARD_HEIGHT_DIFF * float(i))
		var target: Vector3 = global_position + offset
		if card.has_method("set_hover_position"):
			card.call("set_hover_position", target)
		if card.has_method("set_hover_rotation"):
			card.call("set_hover_rotation", global_transform.basis.get_rotation_quaternion())
		x += widths[i] + spacing

