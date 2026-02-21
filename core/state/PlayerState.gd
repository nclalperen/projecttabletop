extends RefCounted
class_name PlayerState

var hand: Array = []
var has_opened: bool = false
var opened_by_pairs: bool = false
var opened_mode: String = "" # "melds" | "pairs"
var score_total: int = 0
var score_round: int = 0
var deal_penalty_points: int = 0
var last_round_breakdown: Dictionary = {}

