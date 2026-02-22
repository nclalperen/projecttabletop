extends RefCounted

const REGISTRY_PATH: String = "res://docs/ASSET_LICENSES.md"
const RUNTIME_ASSET_PATHS: PackedStringArray = [
	"res://uassets/gameplay/3d/textures/cloth-texture.png",
	"res://uassets/gameplay/3d/models/rack.glb",
	"res://uassets/gameplay/3d/models/tiles_library.glb",
]


func run() -> bool:
	var rows_by_path: Dictionary = _parse_registry()
	if rows_by_path.is_empty():
		push_error("Asset registry parse failed or no rows found: %s" % REGISTRY_PATH)
		return false
	for asset_path in RUNTIME_ASSET_PATHS:
		if not rows_by_path.has(asset_path):
			push_error("Runtime asset missing from registry: %s" % asset_path)
			return false
		var row: Dictionary = rows_by_path[asset_path] as Dictionary
		var status: String = str(row.get("status", "")).to_lower()
		if status != "approved":
			push_error("Runtime asset is not approved in registry: %s (status=%s)" % [asset_path, status])
			return false
		var license_text: String = str(row.get("license", ""))
		if license_text.findn("cc0") == -1 and license_text.findn("public domain") == -1:
			push_error("Runtime asset license must be CC0/Public Domain: %s (license=%s)" % [asset_path, license_text])
			return false
		var source_url: String = str(row.get("source_url", "")).strip_edges()
		var license_url: String = str(row.get("license_url", "")).strip_edges()
		if source_url == "" or source_url == "-":
			push_error("Runtime asset source URL missing: %s" % asset_path)
			return false
		if license_url == "" or license_url == "-":
			push_error("Runtime asset license URL missing: %s" % asset_path)
			return false
	return true


func _parse_registry() -> Dictionary:
	var out: Dictionary = {}
	var f := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if f == null:
		push_error("Unable to open asset registry: %s" % REGISTRY_PATH)
		return out
	var text: String = f.get_as_text()
	f.close()
	var lines: PackedStringArray = text.split("\n")
	for raw_line in lines:
		var line: String = raw_line.strip_edges()
		if not line.begins_with("|"):
			continue
		if line.find("---") != -1:
			continue
		var cells: Array[String] = _split_markdown_row(line)
		if cells.size() < 9:
			continue
		if str(cells[0]).to_lower() == "source url":
			continue
		var imported_path: String = _strip_ticks(cells[3])
		if imported_path == "":
			continue
		out[imported_path] = {
			"source_url": cells[0],
			"license_url": cells[1],
			"asset_name": cells[2],
			"imported_path": imported_path,
			"license": cells[4],
			"hash_version": cells[5],
			"reviewer": cells[6],
			"date_added": cells[7],
			"status": cells[8],
		}
	return out


func _split_markdown_row(line: String) -> Array[String]:
	var parts_raw: PackedStringArray = line.split("|", false)
	var out: Array[String] = []
	for p in parts_raw:
		out.append(str(p).strip_edges())
	return out


func _strip_ticks(v: String) -> String:
	var s: String = v.strip_edges()
	if s.begins_with("`") and s.ends_with("`") and s.length() >= 2:
		return s.substr(1, s.length() - 2)
	return s
