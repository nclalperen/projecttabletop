class_name DeckAndDiscards3D
extends Node3D

signal draw_requested
signal take_discard_requested(seat_index: int)
signal discard_dropped(tile_id: int)

const TILE_W: float = 0.038
const TILE_H: float = 0.052
const TILE_D: float = 0.010
const DECK_TILE_SCALE: float = 0.95
const INDICATOR_TILE_SCALE: float = 0.95
const DISCARD_DROP_RADIUS_PX: float = 60.0
const DRAW_CLICK_RADIUS_PX: float = 50.0

var _deck_container: Node3D = null
var _indicator_node: Node3D = null
var _discard_containers: Array[Node3D] = []

var _last_deck_hash: int = -1
var _last_discard_hashes: Array[int] = [-1, -1, -1, -1]

func _ready() -> void:
	_setup_containers()

func _setup_containers() -> void:
	if _deck_container == null:
		_deck_container = Node3D.new()
		_deck_container.name = "DeckPile"
		add_child(_deck_container)

	while _discard_containers.size() < 4:
		var pi: int = _discard_containers.size()
		var pile := Node3D.new()
		pile.name = "DiscardPile%d" % pi
		add_child(pile)
		_discard_containers.append(pile)

func configure_layout(table_half_felt: float = 0.38) -> void:
	_setup_containers()
	var discard_offsets: Array[Vector2] = [
		Vector2(table_half_felt * 0.44, table_half_felt * 0.42),   # Local (Seat 0, right side)
		Vector2(table_half_felt * 0.42, -table_half_felt * 0.44),  # Right opponent (Seat 1)
		Vector2(-table_half_felt * 0.44, -table_half_felt * 0.42), # Top opponent (Seat 2)
		Vector2(-table_half_felt * 0.42, table_half_felt * 0.44)   # Left opponent (Seat 3)
	]

	for i in range(mini(4, _discard_containers.size())):
		var off: Vector2 = discard_offsets[i]
		_discard_containers[i].position = Vector3(off.x, 0.002, off.y)

	if _deck_container != null:
		_deck_container.position = Vector3(0.0, 0.002, 0.0)

func evaluate_discard_drop(screen_pos: Vector2, camera: Camera3D) -> bool:
	if camera == null or not is_instance_valid(camera):
		return false
	if _discard_containers.is_empty() or _discard_containers[0] == null:
		return false
	var pile_world: Vector3 = _discard_containers[0].global_position if _discard_containers[0].is_inside_tree() else _discard_containers[0].position
	if camera.is_position_behind(pile_world):
		return false
	var pile_screen: Vector2 = camera.unproject_position(pile_world)
	return pile_screen.distance_to(screen_pos) <= DISCARD_DROP_RADIUS_PX

func evaluate_draw_click(screen_pos: Vector2, camera: Camera3D) -> bool:
	if camera == null or not is_instance_valid(camera):
		return false
	if _deck_container == null:
		return false
	var deck_world: Vector3 = _deck_container.global_position if _deck_container.is_inside_tree() else _deck_container.position
	if camera.is_position_behind(deck_world):
		return false
	var deck_screen: Vector2 = camera.unproject_position(deck_world)
	return deck_screen.distance_to(screen_pos) <= DRAW_CLICK_RADIUS_PX

func get_local_discard_world_pos() -> Vector3:
	if _discard_containers.is_empty() or _discard_containers[0] == null:
		return Vector3.ZERO
	return _discard_containers[0].global_position if _discard_containers[0].is_inside_tree() else _discard_containers[0].position
