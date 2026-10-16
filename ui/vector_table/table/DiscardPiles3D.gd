class_name DiscardPiles3D
extends Node3D
## Procedural 3D Discard Piles for VectorGameTable3D.
## Manages the 4 discard piles around the table (Seats 0..3) with fanned multi-tile history,
## accurate table coordinates, and collision picking for taking discards.

signal take_discard_requested(seat: int)

const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")
const TileRegistry3D = preload("res://ui/vector_table/TileRegistry3D.gd")
const TileAnimator3D = preload("res://ui/vector_table/TileAnimator3D.gd")
const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")

const FAN_OFFSET_X: float = 0.006
const FAN_OFFSET_Z: float = 0.004
const FAN_ROT_DEG: float = 4.0
const LAYER_Y_STEP: float = 0.0012

var _anchors: Dictionary = {} # seat -> Node3D
var _pick_areas: Dictionary = {} # seat -> Area3D
var _registry: TileRegistry3D = null


func setup(registry: TileRegistry3D) -> void:
	_registry = registry
	for child in get_children():
		child.queue_free()
	_anchors.clear()
	_pick_areas.clear()

	for seat in range(4):
		var anchor := Node3D.new()
		anchor.name = "DiscardAnchor_%d" % seat
		anchor.position = TUNING.DISCARD_POS_3D.get(seat, Vector3.ZERO)
		var base_rot: Vector3 = TUNING.DISCARD_ROT_DEG.get(seat, Vector3.ZERO)
		anchor.rotation_degrees = base_rot
		add_child(anchor)
		_anchors[seat] = anchor

		# Add pick area for Seat 3 (West pile, which player 0 can draw from)
		if seat == 3:
			var pick := Area3D.new()
			pick.name = "TakeDiscardPickArea"
			pick.collision_layer = 2
			pick.collision_mask = 0
			pick.set_meta("action", "take_discard")
			pick.set_meta("seat", seat)

			var col := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(0.065, 0.03, 0.08)
			col.shape = box
			col.position = Vector3(0.0, 0.015, 0.0)
			pick.add_child(col)
			anchor.add_child(pick)
			_pick_areas[seat] = pick


func get_pile_target_transform(seat: int, layer_from_top: int = 0) -> Transform3D:
	var base_pos: Vector3 = TUNING.DISCARD_POS_3D.get(seat, Vector3.ZERO)
	var base_rot: Vector3 = TUNING.DISCARD_ROT_DEG.get(seat, Vector3.ZERO)

	var off_x: float = float(layer_from_top) * FAN_OFFSET_X
	var off_z: float = float(layer_from_top) * FAN_OFFSET_Z
	var rot_yaw: float = base_rot.y + float(layer_from_top) * FAN_ROT_DEG
	var y_pos: float = TUNING.TABLE_SURFACE_Y + float(-layer_from_top) * LAYER_Y_STEP

	var target_pos := base_pos + Vector3(off_x, y_pos, off_z)
	var target_rot := Vector3(-90.0, rot_yaw, 0.0)
	return Transform3D(Basis.from_euler(Vector3(deg_to_rad(-90.0), deg_to_rad(rot_yaw), 0.0)), target_pos)


func sync_stacks(stacks: Array, animator: TileAnimator3D = null, opponent_racks: Dictionary = {}) -> void:
	if _registry == null or stacks.is_empty():
		return

	for seat in range(mini(stacks.size(), 4)):
		var pile: Array = stacks[seat]
		if pile.is_empty():
			continue

		# Display top up to 3 tiles
		var start_idx: int = maxi(0, pile.size() - 3)
		for idx in range(start_idx, pile.size()):
			var tile_data = pile[idx]
			var top_id: int = int(tile_data.unique_id)
			var layer_from_top: int = idx - (pile.size() - 1) # 0 for top, -1, -2
			var target_xf: Transform3D = get_pile_target_transform(seat, layer_from_top)

			var prev_zone := _registry.zone_of(top_id)
			var dest_zone := StringName("discard_%d" % seat)

			var node: VectorTile3D = _registry.ensure(top_id, tile_data.number, tile_data.color, tile_data.kind != 0, false, true)

			if prev_zone != dest_zone:
				if animator != null:
					if prev_zone == &"hand":
						animator.fly_discard(node, node.global_transform, target_xf)
					elif prev_zone == &"none":
						var opp_xf := Transform3D.IDENTITY
						if opponent_racks.has(seat) and opponent_racks[seat] != null:
							opp_xf = opponent_racks[seat].get_launch_transform()
						else:
							var opp_pos: Vector3 = TUNING.OPPONENT_RACK_POS_3D.get(seat, TUNING.STOCK_POS_3D)
							opp_xf = Transform3D(Basis.IDENTITY, opp_pos)
						animator.fly_opponent_discard(node, opp_xf, target_xf)
					else:
						node.set_target_position_3d(target_xf.origin, true)
						node.set_target_rotation_3d(target_xf.basis.get_euler() * (180.0 / PI), true)
				else:
					node.set_target_position_3d(target_xf.origin, true)
					node.set_target_rotation_3d(target_xf.basis.get_euler() * (180.0 / PI), true)

				_registry.set_zone(top_id, dest_zone)
			else:
				if not node.is_flying and not node.is_dragging:
					node.set_target_position_3d(target_xf.origin, false)
					node.set_target_rotation_3d(target_xf.basis.get_euler() * (180.0 / PI), false)
