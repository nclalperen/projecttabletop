extends RefCounted
## Unit test for OpponentRack3D, StockView3D, and DiscardPiles3D subsystems.

const OpponentRack3D = preload("res://ui/vector_table/opponents/OpponentRack3D.gd")
const StockView3D = preload("res://ui/vector_table/table/StockView3D.gd")
const DiscardPiles3D = preload("res://ui/vector_table/table/DiscardPiles3D.gd")
const TileRegistry3D = preload("res://ui/vector_table/TileRegistry3D.gd")

func run() -> bool:
	var root := (Engine.get_main_loop() as SceneTree).root
	var ok: bool = true

	# 1. OpponentRack3D tests
	for seat in [1, 2, 3]:
		var opp := OpponentRack3D.new()
		root.add_child(opp)
		opp.setup(seat, "Bot_%d" % seat)

		if opp.seat_index != seat:
			push_error("OpponentRack seat mismatch: expected %d got %d" % [seat, opp.seat_index])
			ok = false

		if opp.tile_count != 21:
			push_error("OpponentRack initial count expected 21 got %d" % opp.tile_count)
			ok = false

		# Check launch transform is valid
		var launch_xf: Transform3D = opp.get_launch_transform()
		if not launch_xf.origin.is_finite():
			push_error("OpponentRack launch transform not finite")
			ok = false

		# Test tile count changes
		opp.set_tile_count(12)
		if opp.tile_count != 12:
			push_error("OpponentRack count expected 12 got %d" % opp.tile_count)
			ok = false

		opp.set_tile_count(0)
		if opp.tile_count != 0:
			push_error("OpponentRack count expected 0 got %d" % opp.tile_count)
			ok = false

		opp.queue_free()

	# 2. StockView3D tests
	var stock := StockView3D.new()
	root.add_child(stock)
	stock.setup(106)

	if stock.remaining_count != 106:
		push_error("StockView remaining_count expected 106 got %d" % stock.remaining_count)
		ok = false

	var draw_xf: Transform3D = stock.get_draw_transform()
	if not draw_xf.origin.is_finite():
		push_error("StockView draw transform not finite")
		ok = false

	stock.update_count(45)
	if stock.remaining_count != 45:
		push_error("StockView remaining_count expected 45 got %d" % stock.remaining_count)
		ok = false

	stock.update_count(0)
	if stock.visible:
		push_error("StockView expected invisible at count 0")
		ok = false

	stock.queue_free()

	# 3. DiscardPiles3D tests
	var registry := TileRegistry3D.new()
	root.add_child(registry)

	var discards := DiscardPiles3D.new()
	root.add_child(discards)
	discards.setup(registry)

	for seat in range(4):
		var target_xf: Transform3D = discards.get_pile_target_transform(seat, 0)
		if not target_xf.origin.is_finite():
			push_error("Discard target transform not finite for seat %d" % seat)
			ok = false

	# Test mock stack sync
	var mock_tile := Tile.new(0, 10, Tile.Kind.NORMAL, 777123)
	var mock_stacks: Array = [[mock_tile], [], [], []]
	discards.sync_stacks(mock_stacks, null, {})

	if not registry.has_node_for(777123):
		push_error("Registry expected node for synced discard tile 777123")
		ok = false

	if registry.zone_of(777123) != &"discard_0":
		push_error("Expected zone discard_0, got %s" % registry.zone_of(777123))
		ok = false

	discards.queue_free()
	registry.queue_free()

	return ok
