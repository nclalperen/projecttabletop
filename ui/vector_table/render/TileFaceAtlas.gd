## Generates and caches the 14x4 tile face texture atlas for Okey 101.
## Built once at startup via SubViewport rendering, sampling Barlow Condensed Bold font.
## Column 0..12: Numbers 1..13 across 4 suit rows (Red, Yellow, Black, Blue).
## Column 13: Fake Okey (Gold Star).
class_name TileFaceAtlas
extends RefCounted

const ATLAS_WIDTH: int = 3584
const ATLAS_HEIGHT: int = 1472
const CELL_WIDTH: int = 256
const CELL_HEIGHT: int = 368
const COLS: int = 14
const ROWS: int = 4

const SUIT_COLORS: Array[Color] = [
	Color("#c8231b"), # 0: Red
	Color("#e09a12"), # 1: Yellow
	Color("#1d1d22"), # 2: Black
	Color("#1563c9"), # 3: Blue
]

const FONT_ID: StringName = AssetIds.UI_FONT_BARLOW_CONDENSED_BOLD

static var _cached_texture: Texture2D = null
static var _is_building: bool = false


static func get_texture() -> Texture2D:
	if _cached_texture != null:
		return _cached_texture
	# Fallback before atlas generation or in headless
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 0.0))
	_cached_texture = ImageTexture.create_from_image(img)
	return _cached_texture


static func uv_rect(number: int, color_idx: int, fake_okey: bool = false) -> Rect2:
	var col: int = 13 if fake_okey else clampi(number - 1, 0, 12)
	var row: int = 0 if fake_okey else clampi(color_idx, 0, 3)
	var u_step: float = 1.0 / float(COLS)
	var v_step: float = 1.0 / float(ROWS)
	return Rect2(float(col) * u_step, float(row) * v_step, u_step, v_step)


static func ensure_atlas(tree: SceneTree) -> void:
	if _cached_texture != null and _cached_texture.get_width() > 1:
		return
	if tree == null:
		return

	if DisplayServer.get_name() == "headless":
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_cached_texture = ImageTexture.create_from_image(img)
		return

	if _is_building:
		return
	_is_building = true

	var font: Font = AssetRegistry.font(FONT_ID)
	if font == null:
		# Fallback to system bold font if registry font failed
		var sys_font := SystemFont.new()
		sys_font.font_names = PackedStringArray(["Arial", "Helvetica", "Sans-Serif"])
		sys_font.font_weight = 700
		font = sys_font

	var viewport := SubViewport.new()
	viewport.name = "TileFaceAtlasViewport"
	viewport.size = Vector2i(ATLAS_WIDTH, ATLAS_HEIGHT)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)

	var drawer := Control.new()
	drawer.size = Vector2(ATLAS_WIDTH, ATLAS_HEIGHT)
	viewport.add_child(drawer)

	drawer.draw.connect(func():
		_draw_atlas(drawer, font)
	)

	# Allow 2 frames for rendering
	for _i in range(2):
		await tree.process_frame

	await RenderingServer.frame_post_draw

	var img: Image = viewport.get_texture().get_image()
	if img != null and not img.is_empty():
		_cached_texture = ImageTexture.create_from_image(img)

	viewport.queue_free()
	_is_building = false


static func _draw_atlas(drawer: Control, font: Font) -> void:
	for row in range(4):
		var color: Color = SUIT_COLORS[row]
		for col in range(13):
			var number: int = col + 1
			var cell_x: float = float(col * CELL_WIDTH)
			var cell_y: float = float(row * CELL_HEIGHT)
			var center_x: float = cell_x + 128.0
			var center_y: float = cell_y + 130.0 # 35% height

			var font_size: int = 150
			var ascent: float = font.get_ascent(font_size)
			var descent: float = font.get_descent(font_size)
			var baseline_y: float = center_y + (ascent - descent) * 0.5 - 6.0

			var text := str(number)
			# 2px engraved highlight below
			drawer.draw_string(font, Vector2(cell_x, baseline_y + 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, CELL_WIDTH, font_size, Color(1, 1, 1, 0.45))
			# Main suit-colored number
			drawer.draw_string(font, Vector2(cell_x, baseline_y), text, HORIZONTAL_ALIGNMENT_CENTER, CELL_WIDTH, font_size, color)

			# Pip at 70% height (368 * 0.70 = 258)
			var pip_y: float = cell_y + 258.0
			# Engraved highlight
			drawer.draw_arc(Vector2(center_x, pip_y + 1.5), 20.0, 0.2, PI - 0.2, 24, Color(1, 1, 1, 0.35), 2.0, true)
			# Filled circular pip (radius 20)
			drawer.draw_circle(Vector2(center_x, pip_y), 20.0, color)
			# 1px darker ring
			drawer.draw_arc(Vector2(center_x, pip_y), 20.5, 0.0, TAU, 36, color.darkened(0.35), 1.5, true)

	# Fake Okey in column 13
	for row in range(4):
		var cell_x: float = 13.0 * float(CELL_WIDTH)
		var cell_y: float = float(row * CELL_HEIGHT)
		var center_x: float = cell_x + 128.0
		var star_center_y: float = cell_y + 155.0

		var points := PackedVector2Array()
		var outer_r: float = 58.0
		var inner_r: float = 26.0
		for i in range(10):
			var angle := -PI * 0.5 + float(i) * PI / 5.0
			var r := outer_r if (i % 2 == 0) else inner_r
			points.append(Vector2(center_x + cos(angle) * r, star_center_y + sin(angle) * r))

		var gold := Color("#d99b26")
		# Engraved highlight
		var highlight_points := PackedVector2Array()
		for pt in points:
			highlight_points.append(pt + Vector2(0, 2))
		drawer.draw_colored_polygon(highlight_points, Color(1, 1, 1, 0.45))
		# Main 5-point star
		drawer.draw_colored_polygon(points, gold)
		drawer.draw_polyline(points, gold.darkened(0.4), 2.5, true)

		# Pip below star
		var pip_y: float = cell_y + 280.0
		drawer.draw_circle(Vector2(center_x, pip_y), 18.0, gold)
		drawer.draw_arc(Vector2(center_x, pip_y), 18.5, 0.0, TAU, 36, gold.darkened(0.4), 1.5, true)
