## Persistent 3D Tile Registry for Okey 101.
## Maintains exactly one VectorTile3D node per unique_id across the entire round.
## Tracks zone ownership (&"hand", &"stock", &"indicator", &"discard_<seat>", &"meld_<i>", &"opponent_<seat>").
class_name TileRegistry3D
extends Node3D

# unique_id -> VectorTile3D
var _tiles: Dictionary = {}

# unique_id -> StringName (zone)
var _zones: Dictionary = {}


func ensure(id: int, number: int, color_idx: int, fake_okey: bool = false, standing: bool = true, face_up: bool = true) -> VectorTile3D:
	if _tiles.has(id):
		var existing: VectorTile3D = _tiles[id] as VectorTile3D
		if existing != null and is_instance_valid(existing):
			return existing

	var tile := VectorTile3D.new()
	tile.name = "Tile_%d" % id
	tile.setup_tile(id, number, color_idx, fake_okey, standing, face_up)
	_tiles[id] = tile
	_zones[id] = &"none"
	add_child(tile)
	return tile


func get_node_for(id: int) -> VectorTile3D:
	if _tiles.has(id):
		var t = _tiles[id]
		if is_instance_valid(t):
			return t as VectorTile3D
	return null


func has_node_for(id: int) -> bool:
	return _tiles.has(id) and is_instance_valid(_tiles[id])


func set_zone(id: int, zone: StringName) -> void:
	_zones[id] = zone


func zone_of(id: int) -> StringName:
	return _zones.get(id, &"none")


func all_tile_ids() -> Array:
	return _tiles.keys()


func count() -> int:
	return _tiles.size()


func release_all() -> void:
	for id in _tiles.keys():
		var t = _tiles[id]
		if t != null and is_instance_valid(t):
			t.queue_free()
	_tiles.clear()
	_zones.clear()


func refresh_all_face_textures() -> void:
	for tile in _tiles.values():
		if tile != null and is_instance_valid(tile):
			tile.refresh_face_texture()
