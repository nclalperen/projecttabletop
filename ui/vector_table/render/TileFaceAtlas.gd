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
	Color("#b71c1c"), # 0: Red (Rich Carmine)
	Color("#e65100"), # 1: Yellow/Orange (Deep Burnt Tangerine)
	Color("#111111"), # 2: Black (Obsidian Ink)
	Color("#0d47a1"), # 3: Blue (Royal Cobalt)
]

const FONT_ID: StringName = AssetIds.UI_FONT_BARLOW_CONDENSED_BOLD

static var _cached_texture: ImageTexture = null
static var _is_building: bool = false


static func get_texture() -> ImageTexture:
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
		if _cached_texture != null:
			_cached_texture.set_image(img)
		else:
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

			# 1. Solid warm ivory resin background
			var cell_rect := Rect2(cell_x, cell_y, CELL_WIDTH, CELL_HEIGHT)
			drawer.draw_rect(cell_rect, Color("#f5eee3"))
			# Subtle perimeter bevel shade
			drawer.draw_rect(cell_rect, Color(0.0, 0.0, 0.0, 0.06), false, 4.0)

			# 2. Bold engraved numeral
			var font_size: int = 158
			var ascent: float = font.get_ascent(font_size)
			var descent: float = font.get_descent(font_size)
			var baseline_y: float = center_y + (ascent - descent) * 0.5 - 6.0

			var text := str(number)
			# Deep engraved crease (top-left shadow)
			drawer.draw_string(font, Vector2(cell_x - 1.5, baseline_y - 1.5), text, HORIZONTAL_ALIGNMENT_CENTER, CELL_WIDTH, font_size, Color(0.0, 0.0, 0.0, 0.45))
			# Specular highlight rim below
			drawer.draw_string(font, Vector2(cell_x + 1.0, baseline_y + 1.5), text, HORIZONTAL_ALIGNMENT_CENTER, CELL_WIDTH, font_size, Color(1.0, 1.0, 1.0, 0.40))
			# Saturated 100% solid suit-colored numeral
			drawer.draw_string(font, Vector2(cell_x, baseline_y), text, HORIZONTAL_ALIGNMENT_CENTER, CELL_WIDTH, font_size, color)

			# 3. Pip at 70% height
			var pip_y: float = cell_y + 258.0
			drawer.draw_circle(Vector2(center_x, pip_y + 1.5), 22.0, Color(0.0, 0.0, 0.0, 0.30))
			drawer.draw_arc(Vector2(center_x, pip_y + 1.5), 21.0, 0.2, PI - 0.2, 24, Color(1.0, 1.0, 1.0, 0.40), 2.0, true)
			drawer.draw_circle(Vector2(center_x, pip_y), 21.0, color)
			drawer.draw_arc(Vector2(center_x, pip_y), 21.0, 0.0, TAU, 36, color.darkened(0.40), 2.0, true)

	# Fake Okey in column 13
	for row in range(4):
		var cell_x: float = 13.0 * float(CELL_WIDTH)
		var cell_y: float = float(row * CELL_HEIGHT)
		var center_x: float = cell_x + 128.0
		var star_center_y: float = cell_y + 155.0

		var cell_rect := Rect2(cell_x, cell_y, CELL_WIDTH, CELL_HEIGHT)
		drawer.draw_rect(cell_rect, Color("#f5eee3"))
		drawer.draw_rect(cell_rect, Color(0.0, 0.0, 0.0, 0.06), false, 4.0)

		var points := PackedVector2Array()
		var outer_r: float = 58.0
		var inner_r: float = 26.0
		for i in range(10):
			var angle := -PI * 0.5 + float(i) * PI / 5.0
			var r := outer_r if (i % 2 == 0) else inner_r
			points.append(Vector2(center_x + cos(angle) * r, star_center_y + sin(angle) * r))

		var gold := Color("#d4a017")
		var ruby := Color("#8b0000")
		var shadow_points := PackedVector2Array()
		for pt in points:
			shadow_points.append(pt + Vector2(0, 2.0))
		drawer.draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.35))
		drawer.draw_colored_polygon(points, gold)
		drawer.draw_polyline(points, ruby, 3.5, true)

		# Center ruby gem
		drawer.draw_circle(Vector2(center_x, star_center_y), 10.0, ruby)
		drawer.draw_circle(Vector2(center_x, star_center_y), 6.5, gold)

		# Pip below star
		var pip_y: float = cell_y + 280.0
		drawer.draw_circle(Vector2(center_x, pip_y + 1.5), 20.0, Color(0.0, 0.0, 0.0, 0.30))
		drawer.draw_circle(Vector2(center_x, pip_y), 20.0, gold)
		drawer.draw_arc(Vector2(center_x, pip_y), 20.0, 0.0, TAU, 36, ruby, 2.5, true)
