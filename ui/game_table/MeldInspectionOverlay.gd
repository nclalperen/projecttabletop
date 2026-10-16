class_name MeldInspectionOverlay
extends Control

@export var camera: Camera3D

var _meld_anchors: Dictionary = {} # meld_id -> { "world_pos": Vector3, "summary_text": String, "is_valid_target": bool }
var _pill_nodes: Dictionary = {} # meld_id -> PanelContainer

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func sync_meld_groups(meld_groups: Array, valid_target_ids: Array = []) -> void:
	_meld_anchors.clear()
	for i in range(meld_groups.size()):
		var group = meld_groups[i]
		if group == null:
			continue
		var meld_id: int = i
		var world_pos: Vector3 = Vector3.ZERO
		var summary_text: String = ""

		if group is Dictionary:
			meld_id = int(group.get("meld_id", i))
			world_pos = group.get("center_world_pos", Vector3.ZERO) as Vector3
			summary_text = str(group.get("summary_text", ""))
		elif group is Object:
			if "center_world_pos" in group:
				world_pos = group.center_world_pos
			var kind_str: String = "Run"
			if "kind" in group:
				kind_str = ["Run", "Set", "Pairs"][mini(int(group.kind), 2)]
			var count: int = group.tiles_data.size() if "tiles_data" in group else (group.tiles.size() if "tiles" in group else 0)
			summary_text = "%s (%d)" % [kind_str, count]

		_meld_anchors[meld_id] = {
			"world_pos": world_pos + Vector3(0.0, 0.020, 0.0),
			"summary_text": summary_text,
			"is_valid_target": valid_target_ids.has(meld_id)
		}
	_rebuild_pills()

func _rebuild_pills() -> void:
	for child in get_children():
		child.queue_free()
	_pill_nodes.clear()

	for meld_id in _meld_anchors.keys():
		var data: Dictionary = _meld_anchors[meld_id]
		var pill := PanelContainer.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.theme_type_variation = (
			&"DraftPillReady" if data["is_valid_target"] else &"HUDGlassPanel"
		)
		var lbl := Label.new()
		lbl.text = data["summary_text"]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
		pill.add_child(lbl)
		add_child(pill)
		_pill_nodes[meld_id] = pill

func _process(_delta: float) -> void:
	if camera == null or not is_instance_valid(camera) or not camera.is_inside_tree() or not visible:
		return
	for meld_id in _meld_anchors.keys():
		var pill: PanelContainer = _pill_nodes.get(meld_id)
		if pill == null:
			continue
		var world_pos: Vector3 = _meld_anchors[meld_id]["world_pos"]
		if camera.is_position_behind(world_pos):
			pill.visible = false
			continue
		pill.visible = true
		var screen_pos: Vector2 = camera.unproject_position(world_pos)
		pill.position = screen_pos - (pill.size * 0.5)

func get_pill_count() -> int:
	return _pill_nodes.size()

func get_meld_anchor(meld_id: int) -> Dictionary:
	return _meld_anchors.get(meld_id, {})
