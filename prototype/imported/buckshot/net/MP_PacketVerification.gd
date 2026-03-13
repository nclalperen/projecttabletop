extends RefCounted

# Imported/adapted from Buckshot Roulette multiplayer packet verification.
# This variant is host-authoritative and designed for EOS-backed room state.

func verify_packet(packet_data: Dictionary, player_state: Dictionary, match_state: Dictionary) -> Dictionary:
	if not packet_data.has("packet_id"):
		return {}
	var packet_id: int = int(packet_data.get("packet_id", -1))
	var turn_owner: String = String(match_state.get("turn_owner_puid", ""))
	var sender: String = String(packet_data.get("sender_puid", ""))
	if sender == "":
		return {}
	var verified: bool = false
	match packet_id:
		10:
			verified = _can_pickup_main_item(player_state, sender, turn_owner)
		12:
			verified = _can_fire(player_state, sender, turn_owner)
		17:
			verified = _can_grab_item(player_state, sender, turn_owner)
		19:
			verified = _can_place_item(player_state, sender, turn_owner)
		22:
			verified = _can_use_item(player_state, packet_data, sender, turn_owner)
		_:
			verified = true
	return packet_data.duplicate(true) if verified else {}


func _can_pickup_main_item(player_state: Dictionary, sender: String, turn_owner: String) -> bool:
	var p: Dictionary = player_state.get(sender, {})
	return bool(p.get("has_turn", false)) and sender == turn_owner and not bool(p.get("is_holding_main_item", false))


func _can_fire(player_state: Dictionary, sender: String, turn_owner: String) -> bool:
	var p: Dictionary = player_state.get(sender, {})
	return bool(p.get("has_turn", false)) and sender == turn_owner and bool(p.get("is_holding_main_item", false))


func _can_grab_item(player_state: Dictionary, sender: String, turn_owner: String) -> bool:
	var p: Dictionary = player_state.get(sender, {})
	return bool(p.get("has_turn", false)) and sender == turn_owner and bool(p.get("is_grabbing_items", false))


func _can_place_item(player_state: Dictionary, sender: String, turn_owner: String) -> bool:
	var p: Dictionary = player_state.get(sender, {})
	return bool(p.get("has_turn", false)) and sender == turn_owner and bool(p.get("is_holding_item_to_place", false))


func _can_use_item(player_state: Dictionary, packet_data: Dictionary, sender: String, turn_owner: String) -> bool:
	var p: Dictionary = player_state.get(sender, {})
	if not bool(p.get("has_turn", false)) or sender != turn_owner:
		return false
	return packet_data.has("item_id")

