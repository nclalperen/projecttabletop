class_name TableAudioController
extends Node

const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")

@export var sfx_tile_pickup: AudioStream
@export var sfx_tile_snap_rack: AudioStream
@export var sfx_tile_discard_clack: AudioStream
@export var sfx_meld_commit_chime: AudioStream
@export var sfx_invalid_buzz: AudioStream
@export var enable_mobile_haptics: bool = true
@export var sound_enabled: bool = true

var _player_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_load_default_streams()
	_init_pool()

func _load_default_streams() -> void:
	if sfx_tile_pickup == null and ASSET_REGISTRY != null and ASSET_IDS != null:
		sfx_tile_pickup = ASSET_REGISTRY.audio(ASSET_IDS.GAMEPLAY_AUDIO_RACK_MOVE)
	if sfx_tile_snap_rack == null and ASSET_REGISTRY != null and ASSET_IDS != null:
		sfx_tile_snap_rack = ASSET_REGISTRY.audio(ASSET_IDS.GAMEPLAY_AUDIO_STAGE_MOVE)
	if sfx_tile_discard_clack == null and ASSET_REGISTRY != null and ASSET_IDS != null:
		sfx_tile_discard_clack = ASSET_REGISTRY.audio(ASSET_IDS.GAMEPLAY_AUDIO_DISCARD)
	if sfx_meld_commit_chime == null and ASSET_REGISTRY != null and ASSET_IDS != null:
		sfx_meld_commit_chime = ASSET_REGISTRY.audio(ASSET_IDS.GAMEPLAY_AUDIO_ADD_TO_MELD)
	if sfx_invalid_buzz == null and ASSET_REGISTRY != null and ASSET_IDS != null:
		sfx_invalid_buzz = ASSET_REGISTRY.audio(ASSET_IDS.GAMEPLAY_AUDIO_INVALID_ACTION)

func _init_pool() -> void:
	if not _player_pool.is_empty():
		return
	var bus_name: StringName = &"Master"
	if AudioServer.get_bus_index(&"SFX") != -1:
		bus_name = &"SFX"
	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.name = "AudioPlayer%d" % i
		p.bus = bus_name
		add_child(p)
		_player_pool.append(p)

func on_tile_picked() -> void:
	_play_stream(sfx_tile_pickup, -4.0, true)
	_trigger_haptic(8)

func on_tile_hovered_slot_changed() -> void:
	_trigger_haptic(4)

func on_tile_snapped_to_rack() -> void:
	_play_stream(sfx_tile_snap_rack, -2.0, true)
	_trigger_haptic(12)

func on_tile_discarded() -> void:
	_play_stream(sfx_tile_discard_clack, 0.0, true)
	_trigger_haptic(20)

func on_melds_committed() -> void:
	_play_stream(sfx_meld_commit_chime, 0.0, false)
	_trigger_haptic(35)

func on_invalid_action() -> void:
	_play_stream(sfx_invalid_buzz, -1.0, false)
	_trigger_haptic(45)

func _play_stream(stream: AudioStream, volume_db: float, randomize_pitch: bool = true) -> void:
	if not sound_enabled or stream == null or not is_inside_tree():
		return
	_init_pool()
	var pitch: float = randf_range(0.96, 1.04) if randomize_pitch else 1.0
	for p in _player_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	if not _player_pool.is_empty():
		var p0 = _player_pool[0]
		p0.stream = stream
		p0.volume_db = volume_db
		p0.pitch_scale = pitch
		p0.play()

func _trigger_haptic(duration_ms: int) -> void:
	if enable_mobile_haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)

func get_pool_size() -> int:
	return _player_pool.size()
