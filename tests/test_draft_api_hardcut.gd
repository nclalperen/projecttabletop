extends RefCounted

const GAME_TABLE_SCENE_PATH := "res://ui/GameTable.tscn"
const GAME_TABLE3D_SCRIPT_PATH := "res://ui/GameTable3D.gd"
const RACK_SLOT_MANAGER = preload("res://ui/game_table/RackSlotManager.gd")
const STAGE_MELD_LOGIC = preload("res://ui/game_table/StageMeldLogic.gd")

func run() -> bool:
	var ok: bool = true
	ok = _test_game_table_api_hardcut() and ok
	ok = _test_rack_slot_manager_api_hardcut() and ok
	ok = _test_stage_meld_logic_api_hardcut() and ok
	ok = _test_game_table3d_no_stage_fallback_tokens() and ok

	if ok:
		print("  PASS  test_draft_api_hardcut")
	else:
		print("  FAIL  test_draft_api_hardcut")
	return ok


func _test_game_table_api_hardcut() -> bool:
	var packed: PackedScene = load(GAME_TABLE_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Failed to load GameTable scene for hardcut test")
		return false
	var table: Node = packed.instantiate()
	if table == null:
		push_error("Failed to instantiate GameTable scene for hardcut test")
		return false

	var ok: bool = true
	var removed_methods: Array[String] = [
		"get_stage_slots",
		"overlay_submit_staged",
		"overlay_move_rack_to_stage",
		"overlay_move_stage_to_rack",
		"overlay_move_stage_slot",
		"_submit_staged_melds",
		"_all_staged_tile_ids",
		"_build_new_melds_from_stage_slots_opened",
		"_build_melds_from_stage_slots",
		"_has_staged_tiles",
		"_restore_staged_to_rack",
		"_clear_stage_slots",
		"_find_stage_drop_slot",
	]
	for method_name in removed_methods:
		if table.has_method(method_name):
			push_error("GameTable should not expose stage-era method: %s" % method_name)
			ok = false

	var required_methods: Array[String] = [
		"get_draft_slots",
		"overlay_move_rack_to_draft",
		"overlay_move_draft_to_rack",
		"overlay_move_draft_slot",
	]
	for method_name in required_methods:
		if not table.has_method(method_name):
			push_error("GameTable missing draft API method: %s" % method_name)
			ok = false

	var draft_slots_variant: Variant = table.call("get_draft_slots")
	if not (draft_slots_variant is Array):
		push_error("GameTable.get_draft_slots() should return Array")
		ok = false

	if table.get_parent() != null:
		table.get_parent().remove_child(table)
	table.free()
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


func _test_game_table3d_no_stage_fallback_tokens() -> bool:
	var f := FileAccess.open(GAME_TABLE3D_SCRIPT_PATH, FileAccess.READ)
	if f == null:
		push_error("Failed to open GameTable3D script for hardcut inspection")
		return false
	var text: String = f.get_as_text()
	f.close()

	var forbidden_tokens: Array[String] = [
		"get_stage_slots",
		"overlay_move_rack_to_stage",
		"overlay_move_stage_to_rack",
		"overlay_move_stage_slot",
		"\"stage_tile\"",
		"SFX_STAGE_MOVE",
	]
	for token in forbidden_tokens:
		if text.find(token) != -1:
			push_error("GameTable3D still contains stage fallback token: %s" % token)
			return false
	return true
