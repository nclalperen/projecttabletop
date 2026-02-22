class_name BoardRenderer
extends Node

const GEO = preload("res://ui/game_table/TableGeometry.gd")

var _table_area: Control = null
var _meld_island: Control = null
var _show_rails: bool = false
var _show_wall_ring: bool = false
var _slot_size: Vector2 = Vector2(52, 72)
var _felt_cloth_texture: Texture2D = null
var _ambient_time: float = 0.0

var _board_layer: Node2D = null
var _board_table_poly: Polygon2D = null
var _board_table_border: Line2D = null
var _board_table_spot_poly: Polygon2D = null
var _board_table_vignette_top: Polygon2D = null
var _board_table_vignette_bottom: Polygon2D = null
var _board_table_vignette_left: Polygon2D = null
var _board_table_vignette_right: Polygon2D = null
var _table_grain_lines: Array[Line2D] = []
var _board_shadow_poly: Polygon2D = null
var _board_outer_poly: Polygon2D = null
var _board_felt_poly: Polygon2D = null
var _board_felt_warm_poly: Polygon2D = null
var _board_felt_sheen_poly: Polygon2D = null
var _board_felt_depth_poly: Polygon2D = null
var _board_rim_glow: Line2D = null
var _board_felt_border: Line2D = null
var _board_inner_border: Line2D = null
var _wall_ring_layer: Control = null
var _wall_stack_nodes: Array[Panel] = []

func configure(table_area: Control) -> void:
	_table_area = table_area
	_meld_island = null
	if _table_area != null:
		_meld_island = _table_area.get_node_or_null("MeldsPanel/MeldIsland") as Control

func create_board_geometry(show_rails: bool, show_wall_ring: bool) -> void:
	_show_rails = show_rails
	_show_wall_ring = show_wall_ring
	if _table_area == null:
		return

	if _board_layer != null and is_instance_valid(_board_layer):
		if _board_layer.get_parent() == _table_area:
			_table_area.remove_child(_board_layer)
		_board_layer.queue_free()
	_board_layer = Node2D.new()
	_board_layer.name = "BoardGeometry"
	_board_layer.z_index = -1
	_table_area.add_child(_board_layer)
	_table_area.move_child(_board_layer, 0)

	_board_shadow_poly = Polygon2D.new()
	_board_shadow_poly.color = Color(0, 0, 0, 0.22)
	_board_layer.add_child(_board_shadow_poly)

	_board_table_poly = Polygon2D.new()
	_board_table_poly.color = Color(0.20, 0.12, 0.08, 0.32)
	_board_layer.add_child(_board_table_poly)

	_board_table_border = Line2D.new()
	_board_table_border.width = 1.2
	_board_table_border.default_color = Color(0.10, 0.06, 0.04, 0.24)
	_board_table_border.antialiased = true
	_board_layer.add_child(_board_table_border)

	_board_table_spot_poly = Polygon2D.new()
	_board_table_spot_poly.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_table_spot_poly)

	_board_table_vignette_top = Polygon2D.new()
	_board_table_vignette_top.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_table_vignette_top)

	_board_table_vignette_bottom = Polygon2D.new()
	_board_table_vignette_bottom.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_table_vignette_bottom)

	_board_table_vignette_left = Polygon2D.new()
	_board_table_vignette_left.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_table_vignette_left)

	_board_table_vignette_right = Polygon2D.new()
	_board_table_vignette_right.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_table_vignette_right)

	_table_grain_lines.clear()
	for i in range(GEO.TABLE_GRAIN_LINES):
		var grain := Line2D.new()
		grain.width = 1.0
		grain.antialiased = true
		grain.default_color = Color(0.07, 0.04, 0.02, 0.03 + float(i % 3) * 0.008)
		_board_layer.add_child(grain)
		_table_grain_lines.append(grain)

	_board_outer_poly = Polygon2D.new()
	_board_outer_poly.color = Color(0.33, 0.22, 0.13, 0.92)
	_board_layer.add_child(_board_outer_poly)

	_board_felt_poly = Polygon2D.new()
	_board_felt_poly.color = Color(0.07, 0.36, 0.24, 0.99)
	_board_layer.add_child(_board_felt_poly)

	_board_felt_warm_poly = Polygon2D.new()
	_board_felt_warm_poly.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_felt_warm_poly)

	_board_felt_sheen_poly = Polygon2D.new()
	_board_felt_sheen_poly.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_felt_sheen_poly)

	_board_felt_depth_poly = Polygon2D.new()
	_board_felt_depth_poly.color = Color(1, 1, 1, 1)
	_board_layer.add_child(_board_felt_depth_poly)

	_board_rim_glow = Line2D.new()
	_board_rim_glow.width = 3.0
	_board_rim_glow.default_color = Color(0.82, 0.93, 0.84, 0.14)
	_board_rim_glow.antialiased = true
	_board_layer.add_child(_board_rim_glow)

	_board_felt_border = Line2D.new()
	_board_felt_border.width = 1.8
	_board_felt_border.default_color = Color(0.72, 0.90, 0.76, 0.62)
	_board_felt_border.antialiased = true
	_board_layer.add_child(_board_felt_border)

	_board_inner_border = Line2D.new()
	_board_inner_border.width = 0.9
	_board_inner_border.default_color = Color(0.84, 0.95, 0.86, 0.16)
	_board_inner_border.antialiased = true
	_board_layer.add_child(_board_inner_border)

	if _felt_cloth_texture != null:
		apply_felt_texture(_felt_cloth_texture)

	if _show_wall_ring:
		_create_wall_ring()

func apply_felt_texture(texture: Texture2D) -> void:
	_felt_cloth_texture = texture
	if _board_felt_poly == null or _felt_cloth_texture == null:
		return
	_board_felt_poly.texture = _felt_cloth_texture
	_board_felt_poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_board_felt_poly.texture_scale = Vector2(2.0, 2.0)

func set_slot_size(slot_size: Vector2) -> void:
	_slot_size = slot_size

func set_wall_ring_state(visible: bool, ring_alpha: float) -> void:
	if _wall_ring_layer == null:
		return
	_wall_ring_layer.visible = visible and _show_wall_ring
	if not _wall_ring_layer.visible:
		return
	for stack_panel in _wall_stack_nodes:
		if stack_panel != null and is_instance_valid(stack_panel):
			stack_panel.modulate = Color(1, 1, 1, ring_alpha)

func layout_table_backdrop(table_w: float, table_h: float) -> void:
	if _board_table_poly == null or _board_table_border == null:
		return
	var inset: float = 0.5
	var tl: Vector2 = Vector2(inset, inset)
	var top_right: Vector2 = Vector2(table_w - inset, inset)
	var br: Vector2 = Vector2(table_w - inset, table_h - inset)
	var bl: Vector2 = Vector2(inset, table_h - inset)
	_board_table_poly.polygon = PackedVector2Array([tl, top_right, br, bl])
	_board_table_border.points = PackedVector2Array([tl, top_right, br, bl, tl])

	var fade_h: float = clamp(table_h * 0.09, 42.0, 92.0)
	var fade_w: float = clamp(table_w * 0.065, 56.0, 128.0)

	if _board_table_spot_poly != null:
		var spot_tl: Vector2 = Vector2(table_w * 0.24, table_h * 0.14)
		var spot_tr: Vector2 = Vector2(table_w * 0.74, table_h * 0.16)
		var spot_br: Vector2 = Vector2(table_w * 0.88, table_h * 0.84)
		var spot_bl: Vector2 = Vector2(table_w * 0.12, table_h * 0.86)
		_board_table_spot_poly.polygon = PackedVector2Array([spot_tl, spot_tr, spot_br, spot_bl])
		_board_table_spot_poly.vertex_colors = PackedColorArray([
			Color(0.84, 0.60, 0.34, 0.10),
			Color(0.80, 0.56, 0.31, 0.09),
			Color(0.28, 0.20, 0.14, 0.01),
			Color(0.30, 0.22, 0.16, 0.02),
		])

	if _board_table_vignette_top != null:
		var inner_top_l: Vector2 = Vector2(inset, inset + fade_h)
		var inner_top_r: Vector2 = Vector2(table_w - inset, inset + fade_h)
		_board_table_vignette_top.polygon = PackedVector2Array([tl, top_right, inner_top_r, inner_top_l])
		_board_table_vignette_top.vertex_colors = PackedColorArray([
			Color(0.02, 0.01, 0.01, 0.19),
			Color(0.02, 0.01, 0.01, 0.17),
			Color(0.02, 0.01, 0.01, 0.00),
			Color(0.02, 0.01, 0.01, 0.00),
		])

	if _board_table_vignette_bottom != null:
		var inner_bot_l: Vector2 = Vector2(inset, table_h - inset - fade_h)
		var inner_bot_r: Vector2 = Vector2(table_w - inset, table_h - inset - fade_h)
		_board_table_vignette_bottom.polygon = PackedVector2Array([inner_bot_l, inner_bot_r, br, bl])
		_board_table_vignette_bottom.vertex_colors = PackedColorArray([
			Color(0.02, 0.01, 0.01, 0.00),
			Color(0.02, 0.01, 0.01, 0.00),
			Color(0.02, 0.01, 0.01, 0.18),
			Color(0.02, 0.01, 0.01, 0.20),
		])

	if _board_table_vignette_left != null:
		var inner_left_t: Vector2 = Vector2(inset + fade_w, inset)
		var inner_left_b: Vector2 = Vector2(inset + fade_w, table_h - inset)
		_board_table_vignette_left.polygon = PackedVector2Array([tl, inner_left_t, inner_left_b, bl])
		_board_table_vignette_left.vertex_colors = PackedColorArray([
			Color(0.02, 0.01, 0.01, 0.16),
			Color(0.02, 0.01, 0.01, 0.00),
			Color(0.02, 0.01, 0.01, 0.00),
			Color(0.02, 0.01, 0.01, 0.17),
		])

	if _board_table_vignette_right != null:
		var inner_right_t: Vector2 = Vector2(table_w - inset - fade_w, inset)
		var inner_right_b: Vector2 = Vector2(table_w - inset - fade_w, table_h - inset)
		_board_table_vignette_right.polygon = PackedVector2Array([inner_right_t, top_right, br, inner_right_b])
		_board_table_vignette_right.vertex_colors = PackedColorArray([
			Color(0.02, 0.01, 0.01, 0.00),
			Color(0.02, 0.01, 0.01, 0.16),
			Color(0.02, 0.01, 0.01, 0.18),
			Color(0.02, 0.01, 0.01, 0.00),
		])

	if not _table_grain_lines.is_empty():
		var usable_top: float = inset + 6.0
		var usable_bottom: float = table_h - inset - 6.0
		for i in range(_table_grain_lines.size()):
			var g: Line2D = _table_grain_lines[i]
			if g == null:
				continue
			var t: float = float(i + 1) / float(_table_grain_lines.size() + 1)
			var y: float = lerpf(usable_top, usable_bottom, t) + sin(float(i) * 1.93) * 1.4
			var x_l: float = inset + 8.0 + sin(float(i) * 1.21) * 2.8
			var x_r: float = table_w - inset - 8.0 + cos(float(i) * 1.67) * 2.4
			g.points = PackedVector2Array([Vector2(x_l, y), Vector2(x_r, y + sin(float(i) * 0.73) * 1.1)])

func layout_board_geometry(top_left: Vector2, top_right: Vector2, bottom_right: Vector2, bottom_left: Vector2) -> void:
	if _board_layer == null or _board_outer_poly == null or _board_felt_poly == null:
		return
	var top_expand: float = 13.0
	var side_expand_far: float = 22.0
	var side_expand_near: float = 28.0
	var bottom_expand: float = 18.0

	var outer_tl: Vector2 = Vector2(top_left.x - side_expand_far, top_left.y - top_expand)
	var outer_tr: Vector2 = Vector2(top_right.x + side_expand_far, top_right.y - top_expand)
	var outer_br: Vector2 = Vector2(bottom_right.x + side_expand_near, bottom_right.y + bottom_expand)
	var outer_bl: Vector2 = Vector2(bottom_left.x - side_expand_near, bottom_left.y + bottom_expand)

	if _board_shadow_poly != null:
		var shadow_off := Vector2(22.0, 20.0)
		var sh_tl: Vector2 = outer_tl + shadow_off + Vector2(0, -2.0)
		var sh_tr: Vector2 = outer_tr + shadow_off + Vector2(4.0, 0.0)
		var sh_br: Vector2 = outer_br + shadow_off + Vector2(10.0, 6.0)
		var sh_bl: Vector2 = outer_bl + shadow_off + Vector2(-6.0, 5.0)
		_board_shadow_poly.polygon = PackedVector2Array([sh_tl, sh_tr, sh_br, sh_bl])

	_board_outer_poly.polygon = PackedVector2Array([outer_tl, outer_tr, outer_br, outer_bl])
	_board_felt_poly.polygon = PackedVector2Array([top_left, top_right, bottom_right, bottom_left])

	if _board_felt_warm_poly != null:
		var warm_tl: Vector2 = top_left + Vector2(12.0, 10.0)
		var warm_tr: Vector2 = top_right + Vector2(-12.0, 10.0)
		var warm_br: Vector2 = bottom_right + Vector2(-14.0, -16.0)
		var warm_bl: Vector2 = bottom_left + Vector2(14.0, -16.0)
		_board_felt_warm_poly.polygon = PackedVector2Array([warm_tl, warm_tr, warm_br, warm_bl])
		_board_felt_warm_poly.vertex_colors = PackedColorArray([
			Color(0.78, 0.68, 0.44, 0.06),
			Color(0.76, 0.66, 0.42, 0.06),
			Color(0.18, 0.22, 0.14, 0.02),
			Color(0.18, 0.22, 0.14, 0.02),
		])

	if _board_felt_sheen_poly != null:
		var sheen_tl: Vector2 = top_left + Vector2(12.0, 10.0)
		var sheen_tr: Vector2 = top_right + Vector2(-12.0, 10.0)
		var sheen_br: Vector2 = bottom_right + Vector2(-16.0, -20.0)
		var sheen_bl: Vector2 = bottom_left + Vector2(16.0, -20.0)
		_board_felt_sheen_poly.polygon = PackedVector2Array([sheen_tl, sheen_tr, sheen_br, sheen_bl])
		_board_felt_sheen_poly.vertex_colors = PackedColorArray([
			Color(0.78, 0.90, 0.74, 0.10),
			Color(0.74, 0.88, 0.72, 0.10),
			Color(0.24, 0.38, 0.28, 0.03),
			Color(0.23, 0.36, 0.27, 0.03),
		])

	if _board_felt_depth_poly != null:
		var depth_tl: Vector2 = top_left + Vector2(8.0, 10.0)
		var depth_tr: Vector2 = top_right + Vector2(-8.0, 10.0)
		var depth_br: Vector2 = bottom_right + Vector2(-10.0, -10.0)
		var depth_bl: Vector2 = bottom_left + Vector2(10.0, -10.0)
		_board_felt_depth_poly.polygon = PackedVector2Array([depth_tl, depth_tr, depth_br, depth_bl])
		_board_felt_depth_poly.vertex_colors = PackedColorArray([
			Color(0.03, 0.12, 0.08, 0.00),
			Color(0.03, 0.12, 0.08, 0.00),
			Color(0.01, 0.05, 0.03, 0.17),
			Color(0.01, 0.05, 0.03, 0.17),
		])

	if _board_rim_glow != null:
		_board_rim_glow.points = PackedVector2Array([top_left, top_right, bottom_right, bottom_left, top_left])
	if _board_felt_border != null:
		_board_felt_border.points = PackedVector2Array([top_left, top_right, bottom_right, bottom_left, top_left])
	if _board_inner_border != null:
		var inner_tl: Vector2 = top_left + Vector2(16.0, 12.0)
		var inner_tr: Vector2 = top_right + Vector2(-16.0, 12.0)
		var inner_br: Vector2 = bottom_right + Vector2(-18.0, -13.0)
		var inner_bl: Vector2 = bottom_left + Vector2(18.0, -13.0)
		_board_inner_border.points = PackedVector2Array([inner_tl, inner_tr, inner_br, inner_bl, inner_tl])

func layout_wall_ring() -> void:
	if _wall_ring_layer == null:
		return
	if not _show_wall_ring:
		_wall_ring_layer.visible = false
		return
	if _meld_island == null or not is_instance_valid(_meld_island):
		_wall_ring_layer.visible = false
		return
	var island_w: float = max(220.0, _meld_island.size.x)
	var island_h: float = max(180.0, _meld_island.size.y)
	var outer_w: float = clamp(island_w * 0.44, 300.0, 560.0)
	var outer_h: float = clamp(island_h * 0.48, 200.0, 340.0)
	var cx: float = island_w * 0.47
	var cy: float = island_h * 0.40
	var left: float = cx - outer_w * 0.5
	var top: float = cy - outer_h * 0.5
	var stack_w: float = clamp(_slot_size.x * 0.22, 9.0, 15.0)
	var stack_h: float = clamp(_slot_size.y * 0.36, 16.0, 26.0)

	var top_n: int = 11
	var right_n: int = 14
	var bottom_n: int = 16
	var left_n: int = 12
	var far_inset: float = clamp(outer_w * 0.12, 22.0, 44.0)
	var side_inset: float = clamp(outer_w * 0.05, 8.0, 20.0)
	var idx: int = 0
	for i in range(top_n):
		var t: float = 0.0 if top_n <= 1 else float(i) / float(top_n - 1)
		var x: float = left + far_inset + t * (outer_w - far_inset * 2.0 - stack_w)
		_set_rect_pixels(_wall_stack_nodes[idx], x, top, stack_w, stack_h)
		idx += 1
	for i in range(right_n):
		var t: float = 0.0 if right_n <= 1 else float(i) / float(right_n - 1)
		var y: float = top + t * (outer_h - stack_w)
		var x: float = left + outer_w - stack_h - lerpf(0.0, side_inset, t)
		_set_rect_pixels(_wall_stack_nodes[idx], x, y, stack_h, stack_w)
		idx += 1
	for i in range(bottom_n):
		var t: float = 0.0 if bottom_n <= 1 else float(i) / float(bottom_n - 1)
		var x: float = left + (1.0 - t) * (outer_w - stack_w)
		_set_rect_pixels(_wall_stack_nodes[idx], x, top + outer_h - stack_h, stack_w, stack_h)
		idx += 1
	for i in range(left_n):
		var t: float = 0.0 if left_n <= 1 else float(i) / float(left_n - 1)
		var y: float = top + (1.0 - t) * (outer_h - stack_w)
		var x: float = left + lerpf(0.0, side_inset, t)
		_set_rect_pixels(_wall_stack_nodes[idx], x, y, stack_h, stack_w)
		idx += 1

func tick_ambient(delta: float) -> void:
	_ambient_time += delta
	var pulse_fast: float = 0.5 + 0.5 * sin(_ambient_time * GEO.AMBIENT_PULSE_SPEED)
	var pulse_slow: float = 0.5 + 0.5 * sin(_ambient_time * GEO.AMBIENT_DRIFT_SPEED + 0.9)
	var pulse_micro: float = 0.5 + 0.5 * sin(_ambient_time * 2.35 + 0.4)

	if _board_table_spot_poly != null:
		_board_table_spot_poly.self_modulate = Color(1, 1, 1, 0.84 + pulse_slow * 0.14)
	if _board_table_vignette_top != null:
		_board_table_vignette_top.self_modulate = Color(1, 1, 1, 0.90 + (1.0 - pulse_slow) * 0.10)
	if _board_table_vignette_bottom != null:
		_board_table_vignette_bottom.self_modulate = Color(1, 1, 1, 0.88 + pulse_micro * 0.12)
	if _board_table_vignette_left != null:
		_board_table_vignette_left.self_modulate = Color(1, 1, 1, 0.88 + pulse_fast * 0.12)
	if _board_table_vignette_right != null:
		_board_table_vignette_right.self_modulate = Color(1, 1, 1, 0.88 + (1.0 - pulse_fast) * 0.12)
	if not _table_grain_lines.is_empty():
		for i in range(_table_grain_lines.size()):
			var g: Line2D = _table_grain_lines[i]
			if g == null:
				continue
			var g_wave: float = 0.5 + 0.5 * sin(_ambient_time * (0.34 + float(i) * 0.025) + float(i) * 0.91)
			var c: Color = g.default_color
			c.a = 0.016 + g_wave * 0.040
			g.default_color = c
	if _board_felt_warm_poly != null:
		_board_felt_warm_poly.self_modulate = Color(1, 1, 1, 0.88 + pulse_slow * 0.10)
	if _board_felt_sheen_poly != null:
		_board_felt_sheen_poly.self_modulate = Color(1, 1, 1, 0.86 + pulse_fast * 0.12)
	if _board_felt_depth_poly != null:
		_board_felt_depth_poly.self_modulate = Color(1, 1, 1, 0.92 + (1.0 - pulse_slow) * 0.08)
	if _board_rim_glow != null:
		_board_rim_glow.default_color = Color(0.82, 0.93, 0.84, 0.10 + pulse_fast * 0.06)

func _create_wall_ring() -> void:
	if _meld_island == null or not is_instance_valid(_meld_island):
		return
	if _wall_ring_layer != null and is_instance_valid(_wall_ring_layer):
		if _wall_ring_layer.get_parent() == _meld_island:
			_meld_island.remove_child(_wall_ring_layer)
		_wall_ring_layer.queue_free()
	_wall_ring_layer = Control.new()
	_wall_ring_layer.name = "WallRing"
	_wall_ring_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wall_ring_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wall_ring_layer.z_index = 3
	_meld_island.add_child(_wall_ring_layer)
	_wall_stack_nodes.clear()
	for _i in range(53):
		var stack_panel := Panel.new()
		stack_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack_panel.z_index = 3
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.94, 0.91, 0.84, 0.36)
		s.border_width_left = 1
		s.border_width_top = 1
		s.border_width_right = 1
		s.border_width_bottom = 2
		s.border_color = Color(0.77, 0.70, 0.58, 0.52)
		s.corner_radius_top_left = 3
		s.corner_radius_top_right = 3
		s.corner_radius_bottom_left = 3
		s.corner_radius_bottom_right = 3
		stack_panel.add_theme_stylebox_override("panel", s)
		_wall_ring_layer.add_child(stack_panel)
		_wall_stack_nodes.append(stack_panel)

func _set_rect_pixels(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.anchor_left = 0.0
	node.anchor_top = 0.0
	node.anchor_right = 0.0
	node.anchor_bottom = 0.0
	node.offset_left = x
	node.offset_top = y
	node.offset_right = x + max(1.0, w)
	node.offset_bottom = y + max(1.0, h)
