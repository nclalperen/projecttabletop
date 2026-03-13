extends Node3D

const FLAGS_PATH: String = "/root/ImportedFeatureFlags"
const BRIDGE_PATH: String = "/root/ImportedRuntimeBridge"

const ROOM_SCRIPT: Script = preload("res://prototype/imported/tabletop_club/scripts/game/3d/Room.gd")
const CAMERA_CONTROLLER_SCRIPT: Script = preload("res://prototype/imported/tabletop_club/scripts/game/CameraController.gd")
const CHAT_SCRIPT: Script = preload("res://prototype/imported/tabletop_club/scripts/game/ui/ChatBox.gd")
const RULER_SCRIPT: Script = preload("res://prototype/imported/tabletop_club/scripts/game/ui/RulerLine.gd")
const SEPARATE_LERP_SCRIPT: Script = preload("res://prototype/imported/buckshot/net/MP_SeparateLerp.gd")

var _game_id: StringName = &""
var _lobby_model: Dictionary = {}
var _local_puid: String = ""
var _seat_by_puid: Dictionary = {}
var _match_id: String = ""
var _match_seed: int = -1

var _room: Node3D = null
var _camera_controller: Node3D = null
var _chat_box: Control = null
var _ruler: Control = null
var _status_label: Label = null
var _remote_piece_lerps: Dictionary = {}


func configure_table(game_id: StringName, lobby_model: Dictionary, local_puid: String, seat_by_puid: Dictionary, match_id: String, match_seed: int) -> void:
	_game_id = game_id
	_lobby_model = lobby_model.duplicate(true)
	_local_puid = local_puid
	_seat_by_puid = seat_by_puid.duplicate(true)
	_match_id = match_id
	_match_seed = match_seed
	_refresh_status()


func _ready() -> void:
	_build_world()
	_build_imported_runtime()
	_build_ui()
	_spawn_demo_content()
	_refresh_status()


func _build_world() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 1.6, 2.5)
	camera.look_at(Vector3(0.0, 0.1, 0.0), Vector3.UP)
	add_child(camera)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, 35, 0)
	add_child(sun)
	var table := MeshInstance3D.new()
	table.name = "Table"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 0.1, 1.6)
	table.mesh = mesh
	table.position = Vector3(0, -0.05, 0)
	add_child(table)
	var collider := StaticBody3D.new()
	collider.name = "TableCollider"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 0.1, 1.6)
	col.shape = shape
	collider.add_child(col)
	collider.position = table.position
	add_child(collider)


func _build_imported_runtime() -> void:
	var bridge: Node = get_node_or_null(BRIDGE_PATH)
	if bridge != null and bridge.has_method("is_module_available"):
		if not bool(bridge.call("is_module_available", StringName("tabletop_club"))):
			return
	_room = ROOM_SCRIPT.new()
	_room.name = "ImportedRoom"
	add_child(_room)

	_camera_controller = CAMERA_CONTROLLER_SCRIPT.new()
	_camera_controller.name = "ImportedCameraController"
	add_child(_camera_controller)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	var root := VBoxContainer.new()
	root.anchors_preset = Control.PRESET_TOP_LEFT
	root.offset_left = 16
	root.offset_top = 16
	root.custom_minimum_size = Vector2(860, 240)
	layer.add_child(root)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)

	_chat_box = CHAT_SCRIPT.new()
	_chat_box.name = "ImportedChatBox"
	root.add_child(_chat_box)
	if _chat_box.has_signal("message_submitted"):
		_chat_box.connect("message_submitted", Callable(self, "_on_chat_submitted"))

	_ruler = RULER_SCRIPT.new()
	_ruler.name = "ImportedRuler"
	_ruler.position = Vector2(16, 210)
	_ruler.size = Vector2(220, 4)
	root.add_child(_ruler)

	var back_btn := Button.new()
	back_btn.text = "Back To Main"
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://ui/Main.tscn")
	)
	root.add_child(back_btn)


func _spawn_demo_content() -> void:
	if _room == null:
		return
	var add_piece_callable: Callable = Callable(_room, "add_piece")
	if not add_piece_callable.is_valid():
		return
	var tf1 := Transform3D(Basis.IDENTITY, Vector3(-0.2, 0.12, 0.0))
	var tf2 := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.12, 0.05))
	var tf3 := Transform3D(Basis.IDENTITY, Vector3(0.2, 0.12, -0.02))
	_room.call("add_piece", "PrototypeCardA", tf1, "res://prototype/imported/tabletop_club/pieces/card")
	_room.call("add_piece", "PrototypeCardB", tf2, "res://prototype/imported/tabletop_club/pieces/card")
	_room.call("add_piece", "PrototypeDice", tf3, "res://prototype/imported/tabletop_club/pieces/dice")
	_room.call("add_hidden_area", Vector3(-0.5, 0.01, -0.4), Vector3(-0.1, 0.01, -0.1), 1)


func _refresh_status() -> void:
	if _status_label == null:
		return
	var flags_node: Node = get_node_or_null(FLAGS_PATH)
	var bridge_node: Node = get_node_or_null(BRIDGE_PATH)
	var prototype_enabled: bool = true
	if flags_node != null and flags_node.has_method("is_prototype_table_enabled"):
		prototype_enabled = bool(flags_node.call("is_prototype_table_enabled"))
	var module_status: String = "unknown"
	if bridge_node != null and bridge_node.has_method("availability_reason"):
		module_status = String(bridge_node.call("availability_reason", StringName("tabletop_club")))
	_status_label.text = "Imported Prototype Table | Game: %s | Match: %s | Seed: %s | Local: %s | prototype_flag=%s | tabletop=%s" % [
		String(_game_id),
		_match_id if _match_id != "" else "pending",
		"random" if _match_seed < 0 else str(_match_seed),
		_local_puid if _local_puid != "" else "n/a",
		str(prototype_enabled),
		module_status,
	]


func _on_chat_submitted(message: String) -> void:
	if _chat_box != null and _chat_box.has_method("add_raw_message"):
		_chat_box.call("add_raw_message", "[you] %s" % message, false)


func apply_remote_piece_transform(piece_name: String, target_transform: Transform3D, duration_sec: float = 0.18) -> void:
	var piece: Node3D = _find_imported_piece(piece_name)
	if piece == null:
		return
	var to_pos: Vector3 = target_transform.origin
	if piece.get_parent() is Node3D:
		to_pos = (piece.get_parent() as Node3D).to_local(target_transform.origin)
	var to_rot: Vector3 = target_transform.basis.get_euler() * (180.0 / PI)
	var lerp_node: Node = _remote_piece_lerps.get(piece_name, null)
	if lerp_node == null or not is_instance_valid(lerp_node):
		lerp_node = SEPARATE_LERP_SCRIPT.new()
		lerp_node.name = "ImportedSeparateLerp"
		lerp_node.set("obj", piece)
		piece.add_child(lerp_node)
		_remote_piece_lerps[piece_name] = lerp_node
	lerp_node.call(
		"start_lerp",
		piece.position,
		to_pos,
		piece.rotation_degrees,
		to_rot,
		-2.0,
		duration_sec
	)


func _find_imported_piece(piece_name: String) -> Node3D:
	if _room == null:
		return null
	var pieces_root: Node = _room.get_node_or_null("Pieces")
	if pieces_root == null:
		return null
	var piece_node: Node = pieces_root.get_node_or_null(piece_name)
	if piece_node is Node3D:
		return piece_node as Node3D
	return null
