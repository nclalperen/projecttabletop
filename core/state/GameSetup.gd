extends RefCounted
class_name GameSetup

func new_round(rule_config: RuleConfig, rng_seed: int, player_count: int = 4) -> GameState:
	var rng = RandomNumberGenerator.new()
	rng.seed = rng_seed

	var builder = DeckBuilder.new()
	var deck = builder.build_standard_set(rng)

	var indicator = _draw_indicator(deck, rule_config)
	var okey_ctx = OkeyContext.new(indicator)

	var state = GameState.new()
	state.rule_config = rule_config
	state.okey_context = okey_ctx
	state.deck = deck
	state.discard_pile = []
	state.table_melds = []
	state.players = _create_players(player_count)

	_deal_tiles(state, rule_config.tiles_per_player)

	state.current_player_index = rng.randi_range(0, player_count - 1)
	var starter = state.players[state.current_player_index]
	starter.hand.append(_draw_from_deck(state))

	state.phase = GameState.Phase.STARTER_DISCARD
	return state

func _create_players(player_count: int) -> Array:
	var players: Array = []
	for i in range(player_count):
		players.append(PlayerState.new())
	return players

func _deal_tiles(state: GameState, tiles_per_player: int) -> void:
	for i in range(tiles_per_player):
		for player in state.players:
			player.hand.append(_draw_from_deck(state))

func _draw_from_deck(state: GameState) -> Tile:
	return state.deck.pop_back()

func _draw_indicator(deck: Array, rule_config: RuleConfig) -> Tile:
	var indicator = deck.pop_back()
	if indicator.kind == Tile.Kind.FAKE_OKEY and rule_config.indicator_fake_joker_behavior == "redraw":
		# Place fake okey at bottom and draw again until we get a normal tile.
		deck.insert(0, indicator)
		indicator = deck.pop_back()
		while indicator.kind == Tile.Kind.FAKE_OKEY:
			deck.insert(0, indicator)
			indicator = deck.pop_back()
	return indicator
