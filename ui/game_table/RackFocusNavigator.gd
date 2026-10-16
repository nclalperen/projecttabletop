class_name RackFocusNavigator
extends Node

signal focus_slot_changed(zone: StringName, slot_index: int)
signal virtual_tile_picked(zone: StringName, slot_index: int)
signal virtual_tile_dropped(target_zone: StringName, target_slot: int)
signal quick_sort_triggered(mode: StringName)
signal inspection_camera_toggled

const RACK_COLS := 15
const RACK_ROWS := 2
const DRAFT_COLS := 15

@export var enabled: bool = true

var active_zone: StringName = &"RACK" # &"RACK", &"DRAFT", &"TABLE_MELDS", &"DECK_DISCARD"
var active_slot: int = 0
var held_tile_origin_zone: StringName = &"NONE"
var held_tile_origin_slot: int = -1

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	if event.is_action_pressed(&"ui_left"):
		_step_horizontal(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right"):
		_step_horizontal(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up"):
		_step_vertical(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down"):
		_step_vertical(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept"):
		_handle_accept()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and held_tile_origin_slot != -1:
		held_tile_origin_zone = &"NONE"
		held_tile_origin_slot = -1
		focus_slot_changed.emit(active_zone, active_slot)
		get_viewport().set_input_as_handled()

func _step_horizontal(delta_col: int) -> void:
	if active_zone == &"RACK":
		var row: int = active_slot / RACK_COLS
		var col: int = posmod((active_slot % RACK_COLS) + delta_col, RACK_COLS)
		active_slot = row * RACK_COLS + col
	elif active_zone == &"DRAFT":
		active_slot = posmod(active_slot + delta_col, DRAFT_COLS)
	elif active_zone == &"TABLE_MELDS":
		active_slot = maxi(0, active_slot + delta_col)
	focus_slot_changed.emit(active_zone, active_slot)

func _step_vertical(delta_row: int) -> void:
	if active_zone == &"RACK":
		var row: int = active_slot / RACK_COLS
		var col: int = active_slot % RACK_COLS
		if row == 1 and delta_row < 0:
			active_slot = col # Move from bottom rack row to top rack row
		elif row == 0 and delta_row > 0:
			active_slot = RACK_COLS + col # Move from top rack row to bottom rack row
		elif row == 0 and delta_row < 0:
			active_zone = &"DRAFT"
			active_slot = clampi(col, 0, DRAFT_COLS - 1)
	elif active_zone == &"DRAFT":
		if delta_row > 0:
			active_zone = &"RACK"
			active_slot = clampi(active_slot, 0, RACK_COLS - 1)
		elif delta_row < 0:
			active_zone = &"TABLE_MELDS"
			active_slot = 0
	elif active_zone == &"TABLE_MELDS" and delta_row > 0:
		active_zone = &"DRAFT"
		active_slot = 0
	focus_slot_changed.emit(active_zone, active_slot)

func _handle_accept() -> void:
	if held_tile_origin_slot == -1:
		held_tile_origin_zone = active_zone
		held_tile_origin_slot = active_slot
		virtual_tile_picked.emit(active_zone, active_slot)
	else:
		virtual_tile_dropped.emit(active_zone, active_slot)
		held_tile_origin_zone = &"NONE"
		held_tile_origin_slot = -1

func set_focus(zone: StringName, slot_idx: int) -> void:
	active_zone = zone
	active_slot = slot_idx
	focus_slot_changed.emit(active_zone, active_slot)

func is_holding_tile() -> bool:
	return held_tile_origin_slot != -1
