extends RefCounted
class_name GameState

enum Phase { SETUP, STARTER_DISCARD, TURN_DRAW, TURN_PLAY, TURN_DISCARD, ROUND_END }

var players: Array = []
var deck: Array = []
var discard_pile: Array = []
var table_melds: Array = []
var current_player_index: int = 0
var phase: int = Phase.SETUP
var turn_required_use_tile_id: int = -1
var okey_context: OkeyContext
var rule_config: RuleConfig
var last_finish_all_in_one_turn: bool = false
var round_cancelled: bool = false
