extends RefCounted

const CATALOG = preload("res://gd/config/TabletopGameCatalog.gd")


func run() -> bool:
	if CATALOG.default_game_id() != CATALOG.GAME_OKEY_101 or CATALOG.primary_game_ids()[0] != CATALOG.GAME_OKEY_101:
		push_error("Okey must be the default visible table")
		return false
	for game_id in [CATALOG.GAME_POKER, CATALOG.GAME_BLACKJACK, CATALOG.GAME_BACKGAMMON, CATALOG.GAME_CHESS]:
		if not CATALOG.all_game_ids().has(game_id):
			push_error("Tabletop menu lost game: %s" % game_id)
			return false
	var correct_routes := true
	for prototype_enabled in [true, false]:
		correct_routes = correct_routes and CATALOG._resolve_launch_scene_path(CATALOG.GAME_OKEY_101, "3d", prototype_enabled) == "res://ui/vector_table/VectorGameTable3D.tscn"
		correct_routes = correct_routes and CATALOG._resolve_launch_scene_path(CATALOG.GAME_OKEY_101, "vector3d", prototype_enabled) == "res://ui/vector_table/VectorGameTable3D.tscn"
		correct_routes = correct_routes and CATALOG._resolve_launch_scene_path(CATALOG.GAME_OKEY_101, "2d", prototype_enabled) == "res://ui/vector_table/VectorGameTable3D.tscn"
	correct_routes = correct_routes and CATALOG._resolve_launch_scene_path(CATALOG.GAME_CHESS, "3d", true) == "res://ui/ImportedTable3D.tscn"
	correct_routes = correct_routes and CATALOG._resolve_launch_scene_path(CATALOG.GAME_CHESS, "3d", false) == "res://ui/PlaceholderTable.tscn"
	if not correct_routes:
		push_error("Okey and prototype launch routes must remain independent")
		return false
	return true
