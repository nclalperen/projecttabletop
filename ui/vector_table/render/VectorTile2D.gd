## Procedural Vector Tile for Okey 101 & Tabletop Hub.
## Rendered entirely in vector 2D with dynamic drop shadows, spring kinematics, and velocity tilt.
class_name VectorTile2D
extends Control

signal tile_clicked(tile: VectorTile2D)
signal tile_double_clicked(tile: VectorTile2D)
signal tile_drag_started(tile: VectorTile2D)
signal tile_drag_ended(tile: VectorTile2D)

const SPRING = preload("res://ui/vector_table/math/SpringSolver2D.gd")

# Tile dimensions
const DEFAULT_WIDTH: float = 56.0
const DEFAULT_HEIGHT: float = 80.0
const CORNER_RADIUS: float = 7.0

# Visual palette
const COLOR_IVORY_BASE: Color = Color(0.955, 0.925, 0.855, 1.0)
const COLOR_IVORY_FACE: Color = Color(0.985, 0.965, 0.915, 1.0)
const COLOR_IVORY_EDGE: Color = Color(0.78, 0.72, 0.62, 0.90)
const COLOR_SHADOW: Color = Color(0.04, 0.05, 0.06, 0.45)
const COLOR_GOLD_GLOW: Color = Color(0.92, 0.75, 0.20, 0.85)
const COLOR_EMERALD_MELD: Color = Color(0.18, 0.78, 0.45, 0.90)

# Suit colors
const SUIT_COLORS: Array[Color] = [
	Color(0.85, 0.16, 0.12, 1.0), # 0: Red
	Color(0.88, 0.58, 0.06, 1.0), # 1: Yellow/Orange
	Color(0.14, 0.14, 0.16, 1.0), # 2: Black
	Color(0.08, 0.44, 0.84, 1.0), # 3: Blue
]

# Tile Data
var unique_id: int = -1
var number: int = 1
var color_index: int = 0
var is_fake_okey: bool = false
var is_face_up: bool = true
var is_valid_meld: bool = false
var is_selected: bool = false
var is_hovered: bool = false

# Kinematics & Springs
var target_pos: Vector2 = Vector2.ZERO
var spring_pos: Vector2 = Vector2.ZERO
var spring_vel: Vector2 = Vector2.ZERO

var target_elevation: float = 0.0 # 0.0 = resting, 1.0 = lifted/dragged
var spring_elevation: float = 0.0
var spring_elevation_vel: float = 0.0

var base_rotation_rad: float = 0.0
var spring_rot: float = 0.0
var spring_rot_vel: float = 0.0

# Drag interaction
var is_dragging: bool = false
var drag_pointer_offset: Vector2 = Vector2.ZERO
var _last_click_time_msec: int = 0
var _press_pos: Vector2 = Vector2.ZERO
var _is_pressed: bool = false


func _init() -> void:
	custom_minimum_size = Vector2(DEFAULT_WIDTH, DEFAULT_HEIGHT)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_PASS


func _ready() -> void:
	spring_pos = position
	target_pos = position


func setup_tile(uid: int, num: int, col_idx: int, fake_okey: bool = false, face_up: bool = true) -> void:
	unique_id = uid
	number = num
	color_index = posmod(col_idx, SUIT_COLORS.size())
	is_fake_okey = fake_okey
	is_face_up = face_up
	queue_redraw()


func set_target_position(pos: Vector2, snap_immediate: bool = false) -> void:
	target_pos = pos
	if snap_immediate:
		spring_pos = pos
		spring_vel = Vector2.ZERO
		position = pos


func set_elevation(elev: float) -> void:
	target_elevation = clampf(elev, 0.0, 1.0)


func _process(delta: float) -> void:
	if is_dragging:
		return

	var needs_redraw := false

	# 1. Step position spring
	if not spring_pos.is_equal_approx(target_pos) or spring_vel.length_squared() > 0.01:
		var pos_res := SPRING.step_vector2(spring_pos, spring_vel, target_pos, delta, 26.0, 0.74)
		spring_pos = pos_res["position"]
		spring_vel = pos_res["velocity"]
		position = spring_pos
		needs_redraw = true

	# 2. Step elevation spring (lift / drop)
	if not is_equal_approx(spring_elevation, target_elevation) or absf(spring_elevation_vel) > 0.001:
		var elev_res := SPRING.step_float(spring_elevation, spring_elevation_vel, target_elevation, delta, 28.0, 0.72)
		spring_elevation = elev_res["value"]
		spring_elevation_vel = elev_res["velocity"]
		# Dynamic scale based on elevation (lifts towards camera)
		var s := 1.0 + (0.07 * spring_elevation)
		scale = Vector2(s, s)
		needs_redraw = true

	# 3. Dynamic velocity tilt
	var dynamic_tilt := SPRING.calculate_tilt(spring_vel.x, 0.00032, 0.22)
	var target_rot := base_rotation_rad + dynamic_tilt
	if not is_equal_approx(spring_rot, target_rot) or absf(spring_rot_vel) > 0.001:
		var rot_res := SPRING.step_float(spring_rot, spring_rot_vel, target_rot, delta, 22.0, 0.70)
		spring_rot = rot_res["value"]
		spring_rot_vel = rot_res["velocity"]
		rotation = spring_rot
		needs_redraw = true

	if needs_redraw:
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# 1. Dynamic Vector Drop Shadow (expands and shifts with pseudo-Z elevation)
	_draw_dynamic_shadow(rect)

	if not is_face_up:
		_draw_tile_back(rect)
		return

	# 2. Outer Bevel & Ivory Base
	_draw_tile_body(rect)

	# 3. Valid Meld Aura Glow
	if is_valid_meld:
		_draw_meld_indicator(rect)

	# 4. Face Value (Number & Suit Pip)
	_draw_face_content(rect)

	# 5. Selection / Hover Highlight
	if is_selected or is_hovered:
		var highlight_col := COLOR_GOLD_GLOW if is_selected else Color(1.0, 1.0, 1.0, 0.35)
		draw_rect(rect, highlight_col, false, 2.0)


var _body_style: StyleBoxFlat
var _inner_style: StyleBoxFlat
var _shadow_style: StyleBoxFlat
var _back_style: StyleBoxFlat


func _init_styles() -> void:
	if _body_style != null:
		return
	_body_style = StyleBoxFlat.new()
	_body_style.bg_color = COLOR_IVORY_BASE
	_body_style.set_corner_radius_all(6)
	_body_style.border_width_bottom = 2
	_body_style.border_width_right = 1
	_body_style.border_color = COLOR_IVORY_EDGE

	_inner_style = StyleBoxFlat.new()
	_inner_style.bg_color = COLOR_IVORY_FACE
	_inner_style.set_corner_radius_all(4)

	_shadow_style = StyleBoxFlat.new()
	_shadow_style.bg_color = COLOR_SHADOW
	_shadow_style.set_corner_radius_all(8)

	_back_style = StyleBoxFlat.new()
	_back_style.bg_color = Color(0.88, 0.82, 0.71, 0.95)
	_back_style.set_corner_radius_all(4)


func _draw_dynamic_shadow(rect: Rect2) -> void:
	_init_styles()
	var elev: float = clampf(spring_elevation, 0.0, 1.0)
	var shadow_offset := Vector2(2.5, 4.0) + Vector2(4.0, 9.0) * elev
	var shadow_scale := 1.0 + (0.12 * elev)
	var shadow_alpha := 0.38 * (1.0 - (0.28 * elev))

	var s_rect := Rect2(
		rect.position + shadow_offset - (rect.size * (shadow_scale - 1.0) * 0.5),
		rect.size * shadow_scale
	)
	_shadow_style.bg_color = Color(COLOR_SHADOW.r, COLOR_SHADOW.g, COLOR_SHADOW.b, shadow_alpha)
	draw_style_box(_shadow_style, s_rect)


func _draw_tile_body(rect: Rect2) -> void:
	_init_styles()
	# Base ivory rounded body
	draw_style_box(_body_style, rect)

	# Inner face well
	var inner_rect := rect.grow(-2.5)
	draw_style_box(_inner_style, inner_rect)


func _draw_tile_back(rect: Rect2) -> void:
	_init_styles()
	draw_style_box(_body_style, rect)
	var inner_rect := rect.grow(-3.5)
	draw_style_box(_back_style, inner_rect)


func _draw_meld_indicator(rect: Rect2) -> void:
	# Subtle bottom emerald highlight bar indicating valid meld membership
	var bar_rect := Rect2(Vector2(6.0, rect.size.y - 5.0), Vector2(rect.size.x - 12.0, 3.0))
	draw_rect(bar_rect, COLOR_EMERALD_MELD, true)


func _draw_face_content(rect: Rect2) -> void:
	var suit_color: Color = SUIT_COLORS[color_index]
	var text: String = "★" if is_fake_okey else str(number)
	if is_fake_okey:
		suit_color = Color(0.88, 0.62, 0.12)

	# 1. Tile Number (Carved into upper center)
	var font := ThemeDB.fallback_font
	var font_size: int = 24 if is_fake_okey else 28
	var text_pos := Vector2(rect.size.x * 0.5, rect.size.y * 0.44)

	# Carved depth: slight 1px bottom specular highlight
	draw_string(font, text_pos + Vector2(0.0, 1.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1.0, 1.0, 1.0, 0.55))
	# Main number text
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, suit_color)

	# 2. Suit Pip Well & Circular Pip (Lower center)
	var pip_center := Vector2(rect.size.x * 0.5, rect.size.y * 0.74)
	# Recessed well
	draw_circle(pip_center + Vector2(0.0, 0.5), 5.5, Color(0.86, 0.80, 0.68, 0.60))
	# Crisp colored pip
	draw_circle(pip_center, 4.2, suit_color)


# ─── Input & Drag Handling ───

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_pressed = true
				_press_pos = mb.position
				var now := Time.get_ticks_msec()
				if (now - _last_click_time_msec) < 320:
					tile_double_clicked.emit(self)
					_last_click_time_msec = 0
				else:
					_last_click_time_msec = now
					tile_clicked.emit(self)
			else:
				if is_dragging:
					is_dragging = false
					set_elevation(0.0)
					tile_drag_ended.emit(self)
				_is_pressed = false

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_pressed and not is_dragging:
			if _press_pos.distance_to(mm.position) > 6.0:
				is_dragging = true
				set_elevation(1.0)
				drag_pointer_offset = mm.position - (size * 0.5)
				tile_drag_started.emit(self)

		if is_dragging:
			# Direct follow during drag with instant responsiveness
			position += mm.relative
			spring_pos = position
			# Velocity from mouse motion for instant tilt
			spring_vel = mm.velocity
			queue_redraw()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			is_hovered = true
			if not is_dragging:
				set_elevation(0.35)
			queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			is_hovered = false
			if not is_dragging:
				set_elevation(0.0)
			queue_redraw()
