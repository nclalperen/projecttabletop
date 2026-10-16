## Manages cubic Bezier flight arcs and transitions between table zones for VectorTile3D.
## Controls 3D apex heights, cubic ease-out, rotation slerping, and hand-off back to spring physics.
class_name TileAnimator3D
extends Node

signal flight_completed(tile: VectorTile3D, kind: StringName)

const TUNING = preload("res://ui/vector_table/VectorTuning3D.gd")

class Flight:
	var tile: VectorTile3D
	var from_xform: Transform3D
	var to_xform: Transform3D
	var kind: StringName
	var duration: float
	var apex_y: float
	var delay: float
	var elapsed: float = 0.0

var _active_flights: Array[Flight] = []


func fly(tile: VectorTile3D, from_xform: Transform3D, to_xform: Transform3D, kind: StringName = &"generic", duration: float = 0.36, apex_y: float = 0.08, delay_sec: float = 0.0) -> void:
	if tile == null or not is_instance_valid(tile):
		return

	# Remove any existing flight for this tile
	cancel_flight_for(tile)

	tile.is_flying = true
	# Snap to starting transform immediately
	tile.position = from_xform.origin
	tile.rotation_degrees = from_xform.basis.get_euler() * (180.0 / PI)

	var f := Flight.new()
	f.tile = tile
	f.from_xform = from_xform
	f.to_xform = to_xform
	f.kind = kind
	f.duration = maxf(0.05, duration)
	f.apex_y = apex_y
	f.delay = delay_sec
	f.elapsed = 0.0
	_active_flights.append(f)


func fly_draw(tile: VectorTile3D, from_xform: Transform3D, to_xform: Transform3D) -> void:
	fly(tile, from_xform, to_xform, &"draw", TUNING.FLIGHT_DRAW_DURATION_SEC, TUNING.FLIGHT_DRAW_APEX_Y)


func fly_discard(tile: VectorTile3D, from_xform: Transform3D, to_xform: Transform3D) -> void:
	fly(tile, from_xform, to_xform, &"discard", TUNING.FLIGHT_DISCARD_DURATION_SEC, TUNING.FLIGHT_DISCARD_APEX_Y)


func fly_opponent_discard(tile: VectorTile3D, from_xform: Transform3D, to_xform: Transform3D) -> void:
	fly(tile, from_xform, to_xform, &"opponent_discard", TUNING.FLIGHT_OPPONENT_DISCARD_DURATION_SEC, TUNING.FLIGHT_DISCARD_APEX_Y)


func fly_meld(tile: VectorTile3D, from_xform: Transform3D, to_xform: Transform3D, delay_sec: float = 0.0) -> void:
	fly(tile, from_xform, to_xform, &"meld", TUNING.FLIGHT_MELD_DURATION_SEC, 0.06, delay_sec)


func cancel_flight_for(tile: VectorTile3D) -> void:
	for i in range(_active_flights.size() - 1, -1, -1):
		if _active_flights[i].tile == tile:
			_active_flights.remove_at(i)
			break


func is_tile_flying(tile: VectorTile3D) -> bool:
	for f in _active_flights:
		if f.tile == tile:
			return true
	return false


func active_flight_count() -> int:
	return _active_flights.size()


func _process(delta: float) -> void:
	if _active_flights.is_empty():
		return

	for i in range(_active_flights.size() - 1, -1, -1):
		var f := _active_flights[i]
		if f.tile == null or not is_instance_valid(f.tile):
			_active_flights.remove_at(i)
			continue

		if f.delay > 0.0:
			f.delay -= delta
			continue

		f.elapsed += delta
		var t: float = clampf(f.elapsed / f.duration, 0.0, 1.0)

		# Smoothstep ease-in-out: zero jerk at liftoff, gentle cushioning on landing
		var progress: float = t * t * (3.0 - 2.0 * t)

		# Lerp position along trajectory with arc peak at exact spatial midpoint
		var pos: Vector3 = f.from_xform.origin.lerp(f.to_xform.origin, progress)
		var arc_h: float = sin(progress * PI) * f.apex_y
		pos.y += arc_h

		# Slerp orientation (orthonormalize to handle scaled parent nodes)
		var from_b: Basis = f.from_xform.basis.orthonormalized()
		var to_b: Basis = f.to_xform.basis.orthonormalized()
		var basis: Basis = from_b.slerp(to_b, progress)

		f.tile.position = pos
		f.tile.rotation_degrees = basis.get_euler() * (180.0 / PI)

		if t >= 1.0:
			f.tile.is_flying = false
			f.tile.set_target_position_3d(f.to_xform.origin, true)
			f.tile.set_target_rotation_3d(f.to_xform.basis.get_euler() * (180.0 / PI), true)
			var completed_tile := f.tile
			var completed_kind := f.kind
			_active_flights.remove_at(i)
			flight_completed.emit(completed_tile, completed_kind)
