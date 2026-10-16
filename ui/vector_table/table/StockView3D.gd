class_name StockView3D
extends Node3D
## Procedural 3D Stock Pile for VectorGameTable3D.
## Renders a tactile physical stack of ivory tiles matching remaining deck count,
## with subtle natural jitter, face-down top tile, and collision picking for draws.

signal stock_clicked

const TABLE_ART = preload("res://ui/game_table/OkeyTableArt.gd")
const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

const TILE_W: float = 0.045
const TILE_H: float = 0.065
const TILE_D: float = 0.009 # 9mm thickness

var remaining_count: int = 106
var _stack_container: Node3D = null
var _pick_area: Area3D = null
var _tile_layers: Array[Node3D] = []


func _ready() -> void:
	if _stack_container == null:
		setup(remaining_count)


func setup(count: int = 106) -> void:
	position = TUNING.STOCK_POS_3D
	rotation_degrees = TUNING.STOCK_ROT_DEG

	for child in get_children():
		child.queue_free()
	_tile_layers.clear()

	_stack_container = Node3D.new()
	_stack_container.name = "StackLayers"
	add_child(_stack_container)

	_pick_area = Area3D.new()
	_pick_area.name = "StockPickArea"
	_pick_area.collision_layer = 2
	_pick_area.collision_mask = 0
	_pick_area.set_meta("action", "draw_stock")

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(TILE_W + 0.01, 0.08, TILE_H + 0.01)
	col.shape = box
	col.position = Vector3(0.0, 0.04, 0.0)
	_pick_area.add_child(col)
	add_child(_pick_area)

	update_count(count)


func update_count(count: int) -> void:
	remaining_count = maxi(0, count)
	if remaining_count == 0:
		visible = false
		return
	visible = true

	# Layer count from 1 to 7 based on remaining count
	var target_layers: int = clampi(int(ceil(float(remaining_count) / 15.0)), 1, 7)
	if _tile_layers.size() == target_layers:
		return

	for layer in _tile_layers:
		if layer != null and is_instance_valid(layer):
			layer.queue_free()
	_tile_layers.clear()

	# Deterministic pseudo-jitter per layer
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in range(target_layers):
		var tile := TABLE_ART.build_tile(false, false) # flat, face-down
		tile.name = "DeckLayer_%d" % i

		var jx: float = rng.randf_range(-0.0006, 0.0006)
		var jz: float = rng.randf_range(-0.0006, 0.0006)
		var j_rot: float = rng.randf_range(-1.2, 1.2)
		var y_pos: float = (float(i) + 0.5) * TILE_D

		tile.position = Vector3(jx, y_pos, jz)
		tile.rotation_degrees = Vector3(90.0, j_rot, 0.0)
		_stack_container.add_child(tile)
		_tile_layers.append(tile)


func get_draw_transform() -> Transform3D:
	var top_y: float = float(maxi(1, _tile_layers.size())) * TILE_D
	var local_top := Vector3(0.0, top_y, 0.0)
	var xf := global_transform if is_inside_tree() else transform
	return Transform3D(Basis.from_euler(Vector3(deg_to_rad(90.0), deg_to_rad(TUNING.STOCK_ROT_DEG.y), 0.0)), xf.origin + xf.basis * local_top)
