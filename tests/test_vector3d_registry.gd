extends RefCounted
## Unit test for TileRegistry3D node persistence and zone transitions.

const TileRegistry3D = preload("res://ui/vector_table/TileRegistry3D.gd")
const VectorTile3D = preload("res://ui/vector_table/render/VectorTile3D.gd")

func run() -> bool:
	var root := (Engine.get_main_loop() as SceneTree).root
	var ok: bool = true

	var reg := TileRegistry3D.new()
	root.add_child(reg)

	# 1. Ensure tile creates a persistent node
	var tile1 := reg.ensure(9001, 10, 0, false, true, true)
	if tile1 == null or tile1.unique_id != 9001:
		push_error("TileRegistry3D.ensure failed to create tile 9001")
		ok = false

	reg.set_zone(9001, &"hand")
	if reg.zone_of(9001) != &"hand":
		push_error("Zone mismatch for tile 9001")
		ok = false

	# 2. Call ensure again for same ID: must return identical instance
	var tile1_again := reg.ensure(9001, 10, 0, false, true, true)
	if tile1 != tile1_again:
		push_error("TileRegistry3D.ensure returned different instance for same unique_id")
		ok = false

	if reg.count() != 1:
		push_error("Tile count mismatch (expected 1, got %d)" % reg.count())
		ok = false

	# 3. Simulate zone transition: tile moves from hand to discard_0
	var prev_zone: StringName = reg.zone_of(9001)
	var new_zone: StringName = &"discard_0"
	var zone_changed: bool = (prev_zone != new_zone)
	if not zone_changed:
		push_error("Zone change detection failed")
		ok = false
	reg.set_zone(9001, new_zone)
	if reg.zone_of(9001) != &"discard_0":
		push_error("Zone update failed")
		ok = false

	# Verify instance is STILL the same
	var tile1_after := reg.get_node_for(9001)
	if tile1_after != tile1:
		push_error("Tile node instance changed after zone transition")
		ok = false

	# 4. release_all() frees all nodes and resets count to 0
	reg.release_all()
	if reg.count() != 0:
		push_error("TileRegistry3D.release_all failed to clear dictionary")
		ok = false
	if reg.has_node_for(9001):
		push_error("TileRegistry3D still has node for 9001 after release_all")
		ok = false

	reg.queue_free()
	return ok
