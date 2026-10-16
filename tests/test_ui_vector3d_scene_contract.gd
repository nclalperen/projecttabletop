extends RefCounted
## Verifies scene contract, required node hierarchy, camera parameters, and
## environment settings for VectorGameTable3D.tscn.

const SCENE_PATH := "res://ui/vector_table/VectorGameTable3D.tscn"


func run() -> bool:
	var scene: PackedScene = load(SCENE_PATH)
	if scene == null:
		push_error("Failed to load %s" % SCENE_PATH)
		return false

	var root = scene.instantiate()
	if root == null:
		push_error("Failed to instantiate %s" % SCENE_PATH)
		return false

	var required_nodes: PackedStringArray = [
		"WorldEnvironment",
		"KeyLight",
		"FillLight",
		"Camera3D",
		"Camera3D/HandRig3D",
		"Table",
		"Tiles",
		"Animator",
		"StockPile",
		"DiscardPiles",
		"MeldLayout",
		"VectorInput",
		"PlayHUD",
		"AudioController",
		"VignetteLayer",
	]

	for node_path in required_nodes:
		if root.get_node_or_null(node_path) == null:
			push_error("VectorGameTable3D missing required node: %s" % node_path)
			root.free()
			return false

	# Verify camera FOV locked at 40 degrees
	var camera: Camera3D = root.get_node_or_null("Camera3D") as Camera3D
	if camera == null or not is_equal_approx(camera.fov, 40.0):
		push_error("VectorGameTable3D Camera3D fov must be 40.0 degrees")
		root.free()
		return false

	# Verify WorldEnvironment settings
	var world_env: WorldEnvironment = root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env == null or world_env.environment == null:
		push_error("VectorGameTable3D missing valid WorldEnvironment or Environment resource")
		root.free()
		return false

	var env: Environment = world_env.environment
	if env.tonemap_mode != Environment.TONE_MAPPER_AGX:
		push_error("VectorGameTable3D must use AgX tonemapper")
		root.free()
		return false

	if env.background_mode != Environment.BG_COLOR:
		push_error("VectorGameTable3D environment background_mode must be BG_COLOR")
		root.free()
		return false

	# Verify AudioController is TableAudioController instance
	var audio = root.get_node_or_null("AudioController")
	if audio == null or not (audio is TableAudioController):
		push_error("VectorGameTable3D AudioController must be TableAudioController")
		root.free()
		return false

	root.free()
	print("  PASS  test_ui_vector3d_scene_contract")
	return true
