extends RefCounted
## Unit test for TileFaceAtlas UV coordinates and texture generation.

const TileFaceAtlas = preload("res://ui/vector_table/render/TileFaceAtlas.gd")

func run() -> bool:
	var ok: bool = true

	# 1. Fallback / headless texture check
	var tex := TileFaceAtlas.get_texture()
	if tex == null:
		push_error("TileFaceAtlas.get_texture() returned null")
		return false

	# 2. Test UV rects for all 52 standard tiles (13 numbers x 4 colors) + fake okey
	var seen_rects: Dictionary = {}
	for color in range(4):
		for num in range(1, 14):
			var rect: Rect2 = TileFaceAtlas.uv_rect(num, color, false)
			# Must lie in [0, 1]
			if rect.position.x < 0.0 or rect.position.y < 0.0 or rect.end.x > 1.0001 or rect.end.y > 1.0001:
				push_error("Tile UV rect out of [0, 1] range: %s for %d color %d" % [rect, num, color])
				ok = false
			if rect.size.x <= 0.0 or rect.size.y <= 0.0:
				push_error("Tile UV rect has non-positive size: %s" % [rect])
				ok = false
			var key := "%s_%s_%s_%s" % [snappedf(rect.position.x, 0.001), snappedf(rect.position.y, 0.001), snappedf(rect.size.x, 0.001), snappedf(rect.size.y, 0.001)]
			if seen_rects.has(key):
				push_error("Duplicate UV rect detected for num %d color %d: %s" % [num, color, rect])
				ok = false
			seen_rects[key] = true

	# 3. Test Fake Okey UV rect (must be column 13)
	var fake_rect: Rect2 = TileFaceAtlas.uv_rect(0, 0, true)
	if fake_rect.position.x < 0.0 or fake_rect.end.x > 1.0001:
		push_error("Fake okey UV rect out of bounds: %s" % [fake_rect])
		ok = false
	var col13_u: float = 13.0 / 14.0
	if absf(fake_rect.position.x - col13_u) > 0.001:
		push_error("Fake okey expected at col 13 (u=%.4f), got u=%.4f" % [col13_u, fake_rect.position.x])
		ok = false

	# Total 52 normal + 1 fake okey = 53 distinct cells
	var fake_key := "%s_%s_%s_%s" % [snappedf(fake_rect.position.x, 0.001), snappedf(fake_rect.position.y, 0.001), snappedf(fake_rect.size.x, 0.001), snappedf(fake_rect.size.y, 0.001)]
	if seen_rects.has(fake_key):
		push_error("Fake okey overlaps with standard tile rect: %s" % fake_rect)
		ok = false

	return ok
