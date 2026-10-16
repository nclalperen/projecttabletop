## Fluid Continuous Vector Rack for Okey 101.
## Completely replaces rigid 3D slot grids with continuous mathematical spring layouts,
## dynamic push-aside physics, and meld cluster spacing.
class_name FluidRack2D
extends Control

signal tile_reordered(from_slot: int, to_slot: int)
signal tile_action_requested(tile: VectorTile2D, action: StringName)

const SPRING = preload("res://ui/vector_table/math/SpringSolver2D.gd")
const VectorTile2D = preload("res://ui/vector_table/render/VectorTile2D.gd")

const RACK_WIDTH: float = 1060.0
const RACK_HEIGHT: float = 210.0
const ROW_COUNT: int = 2
const MAX_SLOTS_PER_ROW: int = 15

# Visual palette for sculpted walnut rack
const COLOR_WALNUT_SHELL: Color = Color(0.24, 0.13, 0.08, 0.96)
const COLOR_WALNUT_BED: Color = Color(0.12, 0.07, 0.04, 0.98)
const COLOR_WALNUT_EDGE: Color = Color(0.38, 0.22, 0.14, 1.0)
const COLOR_GOLD_TRIM: Color = Color(0.78, 0.62, 0.32, 0.85)

# Row vertical offsets within rack
const ROW_Y: Array[float] = [28.0, 114.0]
const TILE_PITCH: float = 62.0 # 56px tile + 6px gap

# Rack storage: array of tile instances per row
var _row_tiles: Array[Array] = [[], []] # Array of VectorTile2D
var _active_drag_tile: VectorTile2D = null
var _hovered_row: int = -1
var _insertion_index: int = -1


func _init() -> void:
	custom_minimum_size = Vector2(RACK_WIDTH, RACK_HEIGHT)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	queue_redraw()


## Clear all tiles from the rack
func clear_rack() -> void:
	for row in _row_tiles:
		for tile in row:
			if is_instance_valid(tile):
				tile.queue_free()
		row.clear()
	_active_drag_tile = null


## Populate rack with an array of tile dictionaries or instances
func set_tiles(tiles_data: Array) -> void:
	clear_rack()
	var row_idx := 0
	for data in tiles_data:
		var tile := VectorTile2D.new()
		tile.setup_tile(
			data.get("unique_id", -1),
			data.get("number", 1),
			data.get("color", 0),
			data.get("kind", 0) != 0,
			true
		)
		_connect_tile_signals(tile)
		add_child(tile)

		if _row_tiles[row_idx].size() >= MAX_SLOTS_PER_ROW:
			row_idx = mini(row_idx + 1, ROW_COUNT - 1)
		_row_tiles[row_idx].append(tile)

	layout_tiles(true)


func _connect_tile_signals(tile: VectorTile2D) -> void:
	tile.tile_drag_started.connect(_on_tile_drag_started)
	tile.tile_drag_ended.connect(_on_tile_drag_ended)
	tile.tile_double_clicked.connect(func(t): tile_action_requested.emit(t, &"discard"))


## Mathematically compute target positions for all tiles across both rows.
func layout_tiles(snap_immediate: bool = false, held_tile: VectorTile2D = null, pointer_pos: Vector2 = Vector2.ZERO) -> void:
	for row_idx in range(ROW_COUNT):
		var row: Array = _row_tiles[row_idx]
		var count: int = row.size()
		if count == 0:
			continue

		var total_width: float = (count * TILE_PITCH) - (TILE_PITCH - VectorTile2D.DEFAULT_WIDTH)
		var start_x: float = (RACK_WIDTH - total_width) * 0.5
		var row_y: float = ROW_Y[row_idx]

		for i in range(count):
			var tile: VectorTile2D = row[i]
			if tile == held_tile:
				continue # Held tile is controlled by mouse pointer

			var base_x: float = start_x + (i * TILE_PITCH)
			var target_pos := Vector2(base_x, row_y)

			# If a tile is being dragged in this row, apply Gaussian push-aside force
			if held_tile != null and _hovered_row == row_idx:
				var push: float = SPRING.gaussian_push(base_x + 28.0, pointer_pos.x, 38.0, 48.0)
				target_pos.x += push

			tile.set_target_position(target_pos, snap_immediate)


func _process(_delta: float) -> void:
	if _active_drag_tile != null:
		var local_mouse := get_local_mouse_position()
		_update_drag_hover(local_mouse)
		layout_tiles(false, _active_drag_tile, local_mouse)


func _update_drag_hover(mouse_pos: Vector2) -> void:
	# Detect row proximity
	var d0: float = absf(mouse_pos.y - (ROW_Y[0] + 40.0))
	var d1: float = absf(mouse_pos.y - (ROW_Y[1] + 40.0))
	_hovered_row = 0 if d0 < d1 else 1

	# Find insertion index in the hovered row
	var row: Array = _row_tiles[_hovered_row]
	_insertion_index = row.size()
	for i in range(row.size()):
		var tile: VectorTile2D = row[i]
		if tile != _active_drag_tile and mouse_pos.x < (tile.position.x + (VectorTile2D.DEFAULT_WIDTH * 0.5)):
			_insertion_index = i
			break


func _on_tile_drag_started(tile: VectorTile2D) -> void:
	_active_drag_tile = tile
	# Elevate tile above other children in drawing order
	move_child(tile, get_child_count() - 1)


func _on_tile_drag_ended(tile: VectorTile2D) -> void:
	if _active_drag_tile == tile:
		_commit_tile_drop(tile)
		_active_drag_tile = null
		_hovered_row = -1
		_insertion_index = -1
		layout_tiles(false)


func _commit_tile_drop(tile: VectorTile2D) -> void:
	# Remove tile from its previous row
	for row in _row_tiles:
		row.erase(tile)

	# Insert into hovered row at insertion index
	var target_row: int = clampi(_hovered_row, 0, ROW_COUNT - 1)
	var row: Array = _row_tiles[target_row]
	var idx: int = clampi(_insertion_index, 0, row.size())
	row.insert(idx, tile)


## Draw procedural sculpted walnut rack with carved tile beds and gold trim
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# 1. Main Walnut Frame
	draw_rect(rect, COLOR_WALNUT_SHELL, true)

	# 2. Carved Grooves / Tile Beds for Row 0 and Row 1
	for row_y in ROW_Y:
		var bed_rect := Rect2(Vector2(14.0, row_y - 4.0), Vector2(size.x - 28.0, VectorTile2D.DEFAULT_HEIGHT + 8.0))
		draw_rect(bed_rect, COLOR_WALNUT_BED, true)
		# Subtle depth bevel
		draw_rect(bed_rect, COLOR_WALNUT_EDGE, false, 1.5)

	# 3. Gold Trim Inlay & Maker Badge
	draw_line(Vector2(14.0, size.y - 6.0), Vector2(size.x - 14.0, size.y - 6.0), COLOR_GOLD_TRIM, 2.0)
	var badge_rect := Rect2(Vector2((size.x - 80.0) * 0.5, size.y - 12.0), Vector2(80.0, 5.0))
	draw_rect(badge_rect, COLOR_GOLD_TRIM, true)
