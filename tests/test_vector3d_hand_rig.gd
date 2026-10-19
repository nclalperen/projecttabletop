extends RefCounted
## Unit test for HandRig3D slot coordinates, symmetry, and nearest_slot projection.

const HandRig3D = preload("res://ui/vector_table/hand/HandRig3D.gd")

func run() -> bool:
	var root := (Engine.get_main_loop() as SceneTree).root
	var ok: bool = true

	var rig := HandRig3D.new()
	root.add_child(rig)

	# 1. Slot 0 and slot 14 are symmetric about x = 0
	var xf0 := rig.slot_local_transform(0)
	var xf14 := rig.slot_local_transform(14)
	if not is_equal_approx(xf0.origin.x, -xf14.origin.x):
		push_error("Slot 0 x (%.4f) and Slot 14 x (%.4f) not symmetric about 0" % [xf0.origin.x, xf14.origin.x])
		ok = false
	if absf(xf0.origin.x + xf14.origin.x) > 0.0001:
		push_error("Slot 0 and Slot 14 sum to non-zero: %.4f" % [xf0.origin.x + xf14.origin.x])
		ok = false

	# 2. Slot 15 is below slot 0
	var xf15 := rig.slot_local_transform(15)
	if xf15.origin.y >= xf0.origin.y:
		push_error("Slot 15 y (%.4f) not below slot 0 y (%.4f)" % [xf15.origin.y, xf0.origin.y])
		ok = false
	if not is_equal_approx(xf0.origin.x, xf15.origin.x):
		push_error("Slot 0 and Slot 15 do not align horizontally: %.4f vs %.4f" % [xf0.origin.x, xf15.origin.x])
		ok = false

	# 3. nearest_slot round-trips for all 30 slots
	for s in range(30):
		var global_xf := rig.slot_global_transform(s)
		var found_slot := rig.nearest_slot(global_xf.origin)
		if found_slot != s:
			push_error("nearest_slot failed to round-trip for slot %d (got %d)" % [s, found_slot])
			ok = false

		# Perturb slightly within pitch boundary (±0.015m) and verify it still lands on slot s
		var rig_basis: Basis = rig.global_transform.basis if rig.is_inside_tree() else rig.transform.basis
		var jittered_pos := global_xf.origin + rig_basis.x * 0.012
		var jitter_found := rig.nearest_slot(jittered_pos)
		if jitter_found != s:
			push_error("nearest_slot jitter failed for slot %d (got %d)" % [s, jitter_found])
			ok = false

	rig.queue_free()
	return ok
