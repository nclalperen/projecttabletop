extends RefCounted
class_name GameState

enum Phase { SETUP, STARTER_DISCARD, TURN_DRAW, TURN_PLAY, TURN_DISCARD, ROUND_END }

var players: Array = []
var deck: Array = []
var discard_pile: Array = []
# Per-player discard history for UI and deterministic replay/debug.
var player_discard_stacks: Array = []
var table_melds: Array = []

# SeOkey11 round metadata (useful for UX/debug and deterministic replays).
var dealer_index: int = -1
var indicator_stack_index: int = -1 # 1..15
var indicator_tile_index: int = -1  # 1..7 (index within stack, counted from top)
var draw_stack_indices: Array = []  # Array[int] (size 3 in 4p)

var current_player_index: int = 0
var phase: int = Phase.SETUP
var turn_required_use_tile_id: int = -1
var okey_context: OkeyContext
var rule_config: RuleConfig
var last_finish_all_in_one_turn: bool = false
