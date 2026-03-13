extends Node

const LOADER_V1: Script = preload("res://prototype/imported/brotato/save/ProgressDataLoaderV1.gd")
const LOADER_V2: Script = preload("res://prototype/imported/brotato/save/ProgressDataLoaderV2.gd")
const LOADER_V3: Script = preload("res://prototype/imported/brotato/save/ProgressDataLoaderV3.gd")

var version: int = 3
var save_dir: String = "user://"
var current_profile_id: int = 0
var data: Dictionary = {}
var run_state: Dictionary = {}
var load_status: String = "save_missing"


func _ready() -> void:
	load_game_file()


func load_game_file() -> void:
	var loader = _make_loader(version)
	loader.load_game_file()
	load_status = String(loader.load_status)
	data = loader.data.duplicate(true)
	if loader.has_variable("run_state"):
		run_state = loader.run_state.duplicate(true)


func save_game_file() -> int:
	var loader = _make_loader(version)
	loader.data = data.duplicate(true)
	if loader.has_variable("run_state"):
		loader.run_state = run_state.duplicate(true)
	var err: int = loader.save()
	load_status = String(loader.load_status)
	return err


func _make_loader(ver: int):
	var save_path: String = save_dir.path_join("save_v%d_%d.json" % [ver, current_profile_id])
	var run_path: String = save_dir.path_join("run_v%d_%d.json" % [ver, current_profile_id])
	if ver <= 1:
		return LOADER_V1.new(save_path)
	if ver == 2:
		return LOADER_V2.new(save_path, run_path)
	return LOADER_V3.new(save_path, run_path, current_profile_id, save_dir)

