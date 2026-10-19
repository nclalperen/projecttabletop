extends RefCounted
## Verifies the mathematical seat-to-discard mapping according to Okey 101 rules:
## Player 0 (South) takes discard from Player 3 (West, sitting on local player's left),
## and discards to their right towards Player 1 (East).

const VectorTuning3D = preload("res://ui/vector_table/VectorTuning3D.gd")

func run() -> bool:
	var ok: bool = true

	# 1. Turn order rules: seat 0 previous player is seat 3
	var prev_seat: int = (0 - 1 + 4) % 4
	if prev_seat != 3:
		push_error("Expected seat 0 previous seat to be 3, got %d" % prev_seat)
		ok = false

	# 2. Local take position is on the West / left side (X < 0)
	var take_pos: Vector3 = VectorTuning3D.DISCARD_POS_3D[3]
	if take_pos.x >= 0.0 or take_pos.z <= 0.0:
		push_error("Seat 3 (take pile) must be in South-West (+Z, -X), got %s" % take_pos)
		ok = false

	# 3. Local discard position is on the East / right side (X > 0)
	var discard_out_pos: Vector3 = VectorTuning3D.DISCARD_POS_3D[0]
	if discard_out_pos.x <= 0.0 or discard_out_pos.z <= 0.0:
		push_error("Seat 0 (outgoing discard) must be in South-East (+Z, +X), got %s" % discard_out_pos)
		ok = false

	# 4. North and East discard positions
	var east_pos: Vector3 = VectorTuning3D.DISCARD_POS_3D[1]
	if east_pos.x <= 0.0 or east_pos.z >= 0.0:
		push_error("Seat 1 (East discard) must be in North-East (-Z, +X), got %s" % east_pos)
		ok = false

	var north_pos: Vector3 = VectorTuning3D.DISCARD_POS_3D[2]
	if north_pos.x >= 0.0 or north_pos.z >= 0.0:
		push_error("Seat 2 (North discard) must be in North-West (-Z, -X), got %s" % north_pos)
		ok = false

	return ok
