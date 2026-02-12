extends Control
class_name OkeyTile

signal clicked(tile_control: OkeyTile)
signal drag_started(tile_control: OkeyTile)
signal drag_ended(tile_control: OkeyTile, global_pos: Vector2)
signal double_clicked(tile_control: OkeyTile)

@onready var _shadow: Panel = $Shadow
@onready var _body: Panel = $TileBody
@onready var _color_strip: Panel = $TileBody/ColorStrip
@onready var _bottom_edge: Panel = $TileBody/BottomEdge
@onready var _number: Label = $TileBody/Number
@onready var _highlight: Panel = $Highlight

var tile_data = null  # The actual tile object from game state
var tile_index: int = -1
var is_selected: bool = false
var is_dragging: bool = false
var is_hovered: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var _press_pos: Vector2 = Vector2.ZERO
var _mouse_down: bool = false
var _touch_down: bool = false
var _origin_global: Vector2 = Vector2.ZERO
var _drag_pointer_pos: Vector2 = Vector2.ZERO
var _zoom_factor: float = 1.0

const DRAG_THRESHOLD := 10.0
const BASE_TILE_SIZE := Vector2(44, 62)

# Style caches
var _body_style: StyleBoxFlat
var _shadow_style: StyleBoxFlat
var _highlight_style: StyleBoxFlat
var _strip_style: StyleBoxFlat
var _edge_style: StyleBoxFlat

const TILE_COLORS = {
	0: Color(0.85, 0.12, 0.1),    # Red
	1: Color(0.1, 0.4, 0.75),     # Blue
	2: Color(0.12, 0.12, 0.15),   # Black
	3: Color(0.8, 0.6, 0.05),     # Yellow/Orange
}

func _ready() -> void:
	_setup_styles()
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# Update visuals if setup was called before _ready
	if tile_data != null:
		_update_visuals()
	_apply_zoom_font()
	_apply_selected_visuals()

func setup(tile, index: int) -> void:
	tile_data = tile
	tile_index = index
	custom_minimum_size = BASE_TILE_SIZE
	# Only update visuals if node is ready (has entered tree)
	if is_node_ready():
		_update_visuals()

func _setup_styles() -> void:
	# Shadow style
	_shadow_style = StyleBoxFlat.new()
	_shadow_style.bg_color = Color(0, 0, 0, 0.34)
	_shadow_style.corner_radius_top_left = 5
	_shadow_style.corner_radius_top_right = 5
	_shadow_style.corner_radius_bottom_right = 7
	_shadow_style.corner_radius_bottom_left = 7
	_shadow.add_theme_stylebox_override("panel", _shadow_style)

	# Body style (cream tile)
	_body_style = StyleBoxFlat.new()
	_body_style.bg_color = Color(0.985, 0.965, 0.90)
	_body_style.corner_radius_top_left = 4
	_body_style.corner_radius_top_right = 4
	_body_style.corner_radius_bottom_right = 4
	_body_style.corner_radius_bottom_left = 4
	_body_style.border_width_left = 1
	_body_style.border_width_top = 1
	_body_style.border_width_right = 1
	_body_style.border_width_bottom = 1
	_body_style.border_color = Color(0.78, 0.66, 0.48)
	_body.add_theme_stylebox_override("panel", _body_style)

	_edge_style = StyleBoxFlat.new()
	_edge_style.bg_color = Color(0.88, 0.81, 0.66, 0.96)
	_edge_style.corner_radius_top_left = 0
	_edge_style.corner_radius_top_right = 0
	_edge_style.corner_radius_bottom_right = 3
	_edge_style.corner_radius_bottom_left = 3
	_edge_style.border_width_top = 1
	_edge_style.border_color = Color(0.69, 0.58, 0.42, 0.72)
	_bottom_edge.add_theme_stylebox_override("panel", _edge_style)

	_strip_style = StyleBoxFlat.new()
	_strip_style.bg_color = Color(0.4, 0.4, 0.4, 0.94)
	_strip_style.corner_radius_top_left = 1
	_strip_style.corner_radius_top_right = 1
	_strip_style.corner_radius_bottom_right = 1
	_strip_style.corner_radius_bottom_left = 1
	_color_strip.add_theme_stylebox_override("panel", _strip_style)

	# Highlight style (selection glow)
	_highlight_style = StyleBoxFlat.new()
	_highlight_style.bg_color = Color(0.96, 0.78, 0.24, 0.14)
	_highlight_style.corner_radius_top_left = 5
	_highlight_style.corner_radius_top_right = 5
	_highlight_style.corner_radius_bottom_right = 5
	_highlight_style.corner_radius_bottom_left = 5
	_highlight_style.border_width_left = 2
	_highlight_style.border_width_top = 2
	_highlight_style.border_width_right = 2
	_highlight_style.border_width_bottom = 2
	_highlight_style.border_color = Color(0.98, 0.82, 0.29, 0.86)
	_highlight.add_theme_stylebox_override("panel", _highlight_style)

func _update_visuals() -> void:
	if tile_data == null:
		return

	# Set number text
	var num_text = str(tile_data.number)
	if tile_data.kind != 0:  # False okey
		num_text = "★" + num_text
	_number.text = num_text

	# Set number color based on tile color
	var text_color = TILE_COLORS.get(tile_data.color, Color.WHITE)
	_number.add_theme_color_override("font_color", text_color)
	_number.add_theme_font_size_override("font_size", 21)
	_number.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1, 0.12))
	_number.add_theme_constant_override("outline_size", 1)

	# Update body style for false okey
	if tile_data.kind != 0:
		_body_style.border_color = Color(0.93, 0.55, 0.24)
		_body_style.border_width_left = 2
		_body_style.border_width_top = 2
		_body_style.border_width_right = 2
		_body_style.border_width_bottom = 2
		_strip_style.bg_color = Color(0.92, 0.55, 0.2, 0.95)
		_edge_style.bg_color = Color(0.88, 0.74, 0.58, 0.96)
	else:
		_body_style.border_color = Color(0.78, 0.66, 0.48)
		_body_style.border_width_left = 1
		_body_style.border_width_top = 1
		_body_style.border_width_right = 1
		_body_style.border_width_bottom = 1
		_strip_style.bg_color = text_color.darkened(0.08)
		_edge_style.bg_color = Color(0.88, 0.81, 0.66, 0.96)

func set_zoom(zoom: float) -> void:
	_zoom_factor = clamp(zoom, 0.82, 1.24)
	custom_minimum_size = BASE_TILE_SIZE * _zoom_factor
	_apply_zoom_font()

func _apply_zoom_font() -> void:
	if not is_node_ready():
		return
	if _number == null:
		return
	_number.add_theme_font_size_override("font_size", int(round(21.0 * _zoom_factor)))

func set_selected(selected: bool) -> void:
	is_selected = selected
	_apply_selected_visuals()

func _apply_selected_visuals() -> void:
	if not is_node_ready():
		return
	if _highlight == null:
		return
	_highlight.visible = is_selected
	if _body_style == null:
		return
	if is_selected:
		_body_style.bg_color = Color(0.995, 0.98, 0.93)
		z_index = 1
	else:
		_body_style.bg_color = Color(0.985, 0.965, 0.90)
		z_index = 0

func _on_mouse_entered() -> void:
	is_hovered = true
	if not is_dragging:
		_animate_hover(true)

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_dragging:
		_animate_hover(false)

func _animate_hover(hovering: bool) -> void:
	var tween = create_tween()
	if hovering:
		tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.08)
	else:
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click:
				double_clicked.emit(self)
				_mouse_down = false
				return
			_mouse_down = true
			_press_pos = get_global_mouse_position()
			_drag_pointer_pos = _press_pos
			set_process(true)
		else:
			if is_dragging:
				_end_drag(get_global_mouse_position())
			elif _mouse_down:
				clicked.emit(self)
			_mouse_down = false
			if not is_dragging:
				set_process(false)

	elif event is InputEventMouseMotion:
		_drag_pointer_pos = get_global_mouse_position()
		if _mouse_down:
			if not is_dragging and _drag_pointer_pos.distance_to(_press_pos) > DRAG_THRESHOLD:
				_start_drag(_drag_pointer_pos)

	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_down = true
			_press_pos = event.position
			_drag_pointer_pos = event.position
			set_process(true)
		else:
			if is_dragging:
				_end_drag(event.position)
			elif _touch_down:
				clicked.emit(self)
			_touch_down = false
			if not is_dragging:
				set_process(false)

	elif event is InputEventScreenDrag:
		if _touch_down:
			_drag_pointer_pos = event.position
			if not is_dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
				_start_drag(event.position)

func _process(_delta: float) -> void:
	if not is_dragging and not _mouse_down and not _touch_down:
		set_process(false)
		return
	if _mouse_down and not is_dragging:
		var pos = get_global_mouse_position()
		if pos.distance_to(_press_pos) > DRAG_THRESHOLD:
			_start_drag(pos)

	if is_dragging:
		var pos = _drag_pointer_pos if _touch_down else get_global_mouse_position()
		global_position = pos - drag_offset

func _start_drag(global_pos: Vector2) -> void:
	is_dragging = true
	var start_global: Vector2 = global_position
	set_as_top_level(true)
	global_position = start_global
	drag_offset = global_pos - start_global
	_origin_global = start_global
	z_index = 100
	scale = Vector2(1.10, 1.10)
	modulate.a = 0.94
	drag_started.emit(self)

func _end_drag(global_pos: Vector2) -> void:
	if not is_dragging:
		clicked.emit(self)
		return

	is_dragging = false
	set_as_top_level(false)
	z_index = 1 if is_selected else 0
	scale = Vector2(1.0, 1.0)
	modulate.a = 1.0
	drag_ended.emit(self, global_pos)

func animate_deal(delay: float) -> void:
	modulate.a = 0
	position.y += 50
	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(self, "position:y", position.y - 50, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func animate_select() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 8, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y, 0.1).set_ease(Tween.EASE_IN)
