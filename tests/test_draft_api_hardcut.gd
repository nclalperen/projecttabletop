extends RefCounted

const RACK_SLOT_MANAGER = preload("res://ui/game_table/RackSlotManager.gd")
const STAGE_MELD_LOGIC = preload("res://ui/game_table/StageMeldLogic.gd")

func run() -> bool:
	var ok: bool = true
	ok = _test_rack_slot_manager_api_hardcut() and ok
	ok = _test_stage_meld_logic_api_hardcut() and ok

	if ok:
		print("  PASS  test_draft_api_hardcut")
	else:
		print("  FAIL  test_draft_api_hardcut")
	return ok


func _test_rack_slot_manager_api_hardcut() -> bool:
	var slots = RACK_SLOT_MANAGER.new()
	var ok: bool = true

	var removed_methods: Array[String] = [
		"init_stage_slots",
		"has_staged_tiles",
		"all_staged_tile_ids",
		"clear_stage_slots",
		"restore_staged_to_rack",
		"nearest_empty_stage_slot",
		"move_rack_to_stage",
		"move_stage_to_rack",
		"move_stage_slot",
	]
	for method_name in removed_methods:
		if slots.has_method(method_name):
			push_error("RackSlotManager should not expose stage-era method: %s" % method_name)
			ok = false

	for p in slots.get_property_list():
		if String(p.get("name", "")) == "stage_slots":
			push_error("RackSlotManager should not expose stage_slots property alias")
			ok = false
			break

	var required_methods: Array[String] = [
		"init_draft_slots",
		"has_draft_tiles",
		"all_draft_tile_ids",
		"clear_draft_slots",
		"restore_draft_to_rack",
		"nearest_empty_draft_slot",
		"move_rack_to_draft",
		"move_draft_to_rack",
		"move_draft_slot",
	]
	for method_name in required_methods:
		if not slots.has_method(method_name):
			push_error("RackSlotManager missing draft API method: %s" % method_name)
			ok = false

	return ok


func _test_stage_meld_logic_api_hardcut() -> bool:
	var logic = STAGE_MELD_LOGIC.new()
	var ok: bool = true

	var removed_methods: Array[String] = [
		"submit_staged_melds",
		"build_new_melds_from_stage_slots_opened",
		"build_melds_from_stage_slots",
	]
	for method_name in removed_methods:
		if logic.has_method(method_name):
			push_error("StageMeldLogic should not expose stage-era wrapper: %s" % method_name)
			ok = false

	var required_methods: Array[String] = [
		"submit_draft_melds",
		"build_new_melds_from_draft_slots_opened",
		"build_melds_from_draft_slots",
	]
	for method_name in required_methods:
		if not logic.has_method(method_name):
			push_error("StageMeldLogic missing draft API method: %s" % method_name)
			ok = false

	return ok
