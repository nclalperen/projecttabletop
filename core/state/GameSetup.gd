extends RefCounted
class_name GameSetup

const STACK_COUNT := 15
const STACK_SIZE := 7

# SeOkey11 round setup using the 15-stack dealing method from the dossier.
#
# dealer_index:
# - If >= 0, use as dealer for this round.
# - If < 0, dealer is selected by RNG-simulated dice with tie rethrows.
func new_round(rule_config: RuleConfig, rng_seed: int, player_count: int = 4, dealer_index: int = -1) -> GameState:
	# SeOkey11 is defined for 4 players (single-player is still 4 with bots).
	if player_count != 4:
		player_count = 4

	var rng = RandomNumberGenerator.new()
	rng.seed = rng_seed

	var builder = DeckBuilder.new()
	var tiles: Array = builder.build_standard_set(rng)
	if tiles.size() != 106:
		push_error("Expected 106 tiles, got %s" % tiles.size())

	# Build 15 stacks of 7 tiles + 1 leftover tile.
	var leftover_tile: Tile = tiles.pop_back()
	var stacks: Array = _build_stacks(tiles)

	# Pick and remove indicator.
	var indicator_info: Dictionary = _pick_indicator_from_stacks(stacks, rng, rule_config)
	var indicator_tile: Tile = indicator_info.tile
	var indicator_stack_index: int = int(indicator_info.stack_index) # 1..15
	var indicator_tile_index: int = int(indicator_info.tile_index)   # 1..7, counted from top

	var okey_ctx = OkeyContext.new(indicator_tile)

	# The stack immediately after the indicator becomes the 8-tile starter stack.
	var starter_stack_index: int = _wrap_stack_index(indicator_stack_index + 1)
	stacks[starter_stack_index - 1].append(leftover_tile)

	var dealer: int = dealer_index
	if dealer < 0:
		dealer = _pick_dealer_by_dice(rng, player_count)
	var starter_player: int = (dealer + 1) % player_count

	var state = GameState.new()
	state.rule_config = rule_config
	state.okey_context = okey_ctx
	state.dealer_index = dealer
	state.indicator_stack_index = indicator_stack_index
	state.indicator_tile_index = indicator_tile_index
	state.players = _create_players(player_count)
	state.discard_pile = []
	state.player_discard_stacks = []
	for _i in range(player_count):
		state.player_discard_stacks.append([])
	state.table_melds = []
	state.turn_required_use_tile_id = -1

	var dealt_stack_indices: Array = _deal_stacks_to_players(state.players, stacks, starter_stack_index, starter_player, player_count)
	state.draw_stack_indices = _compute_draw_stack_indices(dealt_stack_indices)
	state.deck = _build_draw_deck_from_stacks(stacks, state.draw_stack_indices)

	state.current_player_index = starter_player
	state.phase = GameState.Phase.STARTER_DISCARD
	return state

func _create_players(player_count: int) -> Array:
	var players: Array = []
	for i in range(player_count):
		players.append(PlayerState.new())
	return players

func _build_stacks(tiles: Array) -> Array:
	var stacks: Array = []
	var index := 0
	for s in range(STACK_COUNT):
		var stack: Array = []
		for t in range(STACK_SIZE):
			stack.append(tiles[index])
			index += 1
		stacks.append(stack)
	return stacks

func _wrap_stack_index(stack_index: int) -> int:
	var idx = stack_index
	while idx > STACK_COUNT:
		idx -= STACK_COUNT
	while idx < 1:
		idx += STACK_COUNT
	return idx

func _pick_indicator_from_stacks(stacks: Array, rng: RandomNumberGenerator, rule_config: RuleConfig) -> Dictionary:
	var attempts := 0
	while true:
		attempts += 1
		if attempts > 500:
			push_error("Failed to pick a non-fake indicator after many attempts")
			break

		var stack_index: int = rng.randi_range(1, STACK_COUNT)
		var stack: Array = stacks[stack_index - 1]

		# tile_index is counted from the TOP of the stack (1..7).
		var tile_index: int = rng.randi_range(1, STACK_SIZE)
		var array_index: int = stack.size() - tile_index
		var tile: Tile = stack[array_index]

		if tile.kind == Tile.Kind.FAKE_OKEY and rule_config != null and rule_config.indicator_fake_joker_behavior == "redraw":
			continue

		stack.remove_at(array_index)
		return {
			"stack_index": stack_index,
			"tile_index": tile_index,
			"tile": tile,
		}

	# Fallback (should not happen): pop from first stack.
	var fallback_stack: Array = stacks[0]
	var fallback_tile: Tile = fallback_stack.pop_back()
	return {"stack_index": 1, "tile_index": 1, "tile": fallback_tile}

func _pick_dealer_by_dice(rng: RandomNumberGenerator, player_count: int) -> int:
	var tied: Array = []
	for i in range(player_count):
		tied.append(i)

	while tied.size() > 1:
		var best = -1
		var best_players: Array = []
		for p in tied:
			var roll = rng.randi_range(1, 6)
			if roll > best:
				best = roll
				best_players = [p]
			elif roll == best:
				best_players.append(p)
		tied = best_players

	return int(tied[0])

func _deal_stacks_to_players(players: Array, stacks: Array, start_stack_index: int, start_player_index: int, player_count: int) -> Array:
	var dealt: Array = []
	var total_stacks_to_deal := player_count * 3 # 12 in 4-player SeOkey11
	for offset in range(total_stacks_to_deal):
		var stack_index: int = _wrap_stack_index(start_stack_index + offset)
		var player_index: int = (start_player_index + offset) % player_count
		dealt.append(stack_index)

		var stack: Array = stacks[stack_index - 1]
		players[player_index].hand.append_array(stack)
		stacks[stack_index - 1] = [] # consumed

	return dealt

func _compute_draw_stack_indices(dealt_stack_indices: Array) -> Array:
	var dealt_set := {}
	for s in dealt_stack_indices:
		dealt_set[int(s)] = true

	var draw: Array = []
	for i in range(1, STACK_COUNT + 1):
		if not dealt_set.has(i):
			draw.append(i)
	return draw

func _build_draw_deck_from_stacks(stacks: Array, draw_stack_indices: Array) -> Array:
	var deck: Array = []

	# We want the *highest* stack number to be drawn first.
	# Since we draw by pop_back(), we append stacks in ascending order so the highest
	# stack ends up at the end of the deck array (the "top").
	var indices: Array = draw_stack_indices.duplicate()
	indices.sort()
	for stack_index in indices:
		deck.append_array(stacks[int(stack_index) - 1])

	return deck
