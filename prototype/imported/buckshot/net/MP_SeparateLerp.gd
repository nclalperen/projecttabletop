extends Node

@export var obj: Node3D

var _duration: float = 0.3
var _curve_value_y: float = -2.0
var _elapsed: float = 0.0
var _from_pos: Vector3 = Vector3.ZERO
var _to_pos: Vector3 = Vector3.ZERO
var _from_rot: Vector3 = Vector3.ZERO
var _to_rot: Vector3 = Vector3.ZERO
var _moving: bool = false


func start_lerp(from_pos: Vector3, to_pos: Vector3, from_rot: Vector3, to_rot: Vector3, curve_value_y: float = -2.0, duration_override: float = 0.3) -> void:
	_duration = maxf(0.001, duration_override)
	_curve_value_y = curve_value_y
	_elapsed = 0.0
	_from_pos = from_pos
	_to_pos = to_pos
	_from_rot = from_rot
	_to_rot = to_rot
	_moving = true


func stop_lerp() -> void:
	_moving = false


func snap_to_next_position() -> void:
	_moving = false
	if obj == null:
		return
	obj.position = _to_pos
	obj.rotation_degrees = _to_rot


func _process(delta: float) -> void:
	if not _moving:
		return
	_elapsed += delta
	var c: float = clampf(_elapsed / _duration, 0.0, 1.0)
	var cx: float = ease(c, -2.0)
	var cy: float = ease(c, _curve_value_y)
	if obj != null:
		obj.position = Vector3(
			lerpf(_from_pos.x, _to_pos.x, cx),
			lerpf(_from_pos.y, _to_pos.y, cy),
			lerpf(_from_pos.z, _to_pos.z, cx)
		)
		obj.rotation_degrees = _from_rot.lerp(_to_rot, cx)
	if c >= 1.0:
		snap_to_next_position()

