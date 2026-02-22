extends RefCounted

const CODEC: Script = preload("res://core/network/StateCodec.gd")
const ADAPTER: Script = preload("res://core/network/SeatViewAdapter.gd")

func run() -> bool:
	return _test_redacted_projection_roundtrip()

func _test_redacted_projection_roundtrip() -> bool:
	var setup := GameSetup.new()
	var state: GameState = setup.new_round(RuleConfig.new(), 8801, 4)
	state.table_melds = [
		Meld.new(Meld.Kind.RUN, [101, 102, 103], [
			Tile.new(Tile.TileColor.RED, 4, Tile.Kind.NORMAL, 101),
			Tile.new(Tile.TileColor.RED, 5, Tile.Kind.NORMAL, 102),
			Tile.new(Tile.TileColor.RED, 6, Tile.Kind.NORMAL, 103),
		], 3)
	]
	var local_abs_seat: int = 2
	var payload: Dictionary = CODEC.encode_for_client(state, local_abs_seat)
	var decoded: GameState = CODEC.decode_client_snapshot(payload)
	if decoded.players.size() != 4:
		push_error("Decoded player count mismatch")
		return false
	var expected_local_hand: int = state.players[2].hand.size()
	if decoded.players[0].hand.size() != expected_local_hand:
		push_error("Local hand not projected correctly")
		return false
	if decoded.players[1].hand.size() != state.players[3].hand.size():
		push_error("Opponent hand count mismatch")
		return false
	if decoded.players[1].hand.size() > 0 and int(decoded.players[1].hand[0].unique_id) == int(state.players[3].hand[0].unique_id):
		push_error("Opponent hand should be redacted placeholder tiles")
		return false
	if decoded.deck.size() != state.deck.size():
		push_error("Deck size mismatch after redacted decode")
		return false
	if decoded.current_player_index != ADAPTER.to_local(state.current_player_index, local_abs_seat, 4):
		push_error("Current player index projection mismatch")
		return false
	if decoded.table_melds.is_empty() or int(decoded.table_melds[0].owner_index) != ADAPTER.to_local(3, local_abs_seat, 4):
		push_error("Meld owner projection mismatch")
		return false
	return true
