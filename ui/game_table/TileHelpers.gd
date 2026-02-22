## Static utility functions for tile display and game state queries.
class_name TileHelpers
extends RefCounted

static func instruction_for_state(state, is_my_turn_val: bool) -> String:
	if state == null:
		return "Starting round..."
	if state.phase == GameState.Phase.ROUND_END:
		return "Round ended"
	if not is_my_turn_val:
		return "Waiting for bots..."
	match state.phase:
		GameState.Phase.STARTER_DISCARD:
			return "Starter: drag one tile to your corner discard slot"
		GameState.Phase.TURN_DRAW:
			return "Tap deck to draw, or previous player's corner discard if you can use it"
		GameState.Phase.TURN_PLAY:
			return "Drag tiles onto the felt to build melds. Drag to your discard corner to end turn."
		GameState.Phase.TURN_DISCARD:
			return "Drag one tile to your corner discard slot"
		_:
			return "Play"

static func phase_name(phase: int) -> String:
	match phase:
		GameState.Phase.SETUP: return "Setup"
		GameState.Phase.STARTER_DISCARD: return "Start"
		GameState.Phase.TURN_DRAW: return "Draw"
		GameState.Phase.TURN_PLAY: return "Play"
		GameState.Phase.TURN_DISCARD: return "Discard"
		GameState.Phase.ROUND_END: return "End"
		_: return "-"

static func tile_label(tile) -> String:
	if tile == null:
		return "-"
	if int(tile.kind) != int(Tile.Kind.NORMAL):
		return "F-%d" % int(tile.number)
	return "%s-%d" % [color_letter(int(tile.color)), int(tile.number)]

static func tile_color(tile) -> Color:
	if tile == null:
		return Color(0.95, 0.95, 0.95)
	match int(tile.color):
		Tile.TileColor.RED: return Color(0.85, 0.12, 0.1)
		Tile.TileColor.BLUE: return Color(0.1, 0.4, 0.75)
		Tile.TileColor.BLACK: return Color(0.12, 0.12, 0.15)
		Tile.TileColor.YELLOW: return Color(0.45, 0.29, 0.03)
		_: return Color(0.95, 0.95, 0.95)

static func color_letter(color_value: int) -> String:
	match color_value:
		Tile.TileColor.RED: return "R"
		Tile.TileColor.BLUE: return "B"
		Tile.TileColor.BLACK: return "K"
		Tile.TileColor.YELLOW: return "Y"
		_: return "?"

static func pair_key_for_tile(tile, okey_context) -> String:
	if okey_context != null and int(tile.kind) == int(Tile.Kind.FAKE_OKEY):
		return "%d-%d" % [int(okey_context.okey_color), int(okey_context.okey_number)]
	return "%d-%d" % [int(tile.color), int(tile.number)]

static func is_primary_tap(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		return st.pressed
	return false

static func is_my_turn(state) -> bool:
	return state != null and int(state.current_player_index) == 0

static func is_tile_in_hand(hand: Array, tile_id: int) -> bool:
	for tile in hand:
		if int(tile.unique_id) == tile_id:
			return true
	return false

static func prev_player(state, player_index: int) -> int:
	if state == null:
		return 0
	var count: int = state.players.size()
	if count <= 0:
		return 0
	return (player_index - 1 + count) % count
