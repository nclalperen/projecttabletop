extends Node
class_name MenuAudioService

const ASSET_REGISTRY: Script = preload("res://gd/assets/AssetRegistry.gd")
const ASSET_IDS: Script = preload("res://gd/assets/AssetIds.gd")
const STREAM_HOVER_A_ID: StringName = ASSET_IDS.UI_AUDIO_ROLLOVER_3
const STREAM_HOVER_B_ID: StringName = ASSET_IDS.UI_AUDIO_ROLLOVER_5
const STREAM_CLICK_ID: StringName = ASSET_IDS.UI_AUDIO_CLICK_3
const STREAM_CONFIRM_ID: StringName = ASSET_IDS.UI_AUDIO_CLICK_4
const STREAM_TOGGLE_ID: StringName = ASSET_IDS.UI_AUDIO_SWITCH_12
const STREAM_OPEN_ID: StringName = ASSET_IDS.UI_AUDIO_OPEN_002
const STREAM_CLOSE_ID: StringName = ASSET_IDS.UI_AUDIO_CLOSE_002
const STREAM_BACK_ID: StringName = ASSET_IDS.UI_AUDIO_BACK_002
const STREAM_ERROR_ID: StringName = ASSET_IDS.UI_AUDIO_ERROR_004

const PLAYER_POOL_SIZE: int = 4

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _streams: Dictionary = {}
var _hover_flip: bool = false

func _ready() -> void:
	_ensure_player_pool()
	_load_streams()


func play_hover() -> void:
	_hover_flip = not _hover_flip
	_play_stream("hover_b" if _hover_flip else "hover_a")


func play_click() -> void:
	_play_stream("click")


func play_confirm() -> void:
	_play_stream("confirm")
	_play_stream("open")


func play_back() -> void:
	_play_stream("back")
	_play_stream("close")


func play_error() -> void:
	_play_stream("error")


func play_toggle() -> void:
	_play_stream("toggle")


func bind_button(button: BaseButton, enable_toggle: bool = false) -> void:
	if button == null:
		return
	if not button.mouse_entered.is_connected(_on_button_hover):
		button.mouse_entered.connect(_on_button_hover)
	button.pressed.connect(_on_button_click.bind(enable_toggle), CONNECT_REFERENCE_COUNTED)


func _on_button_hover() -> void:
	play_hover()


func _on_button_click(enable_toggle: bool) -> void:
	if enable_toggle:
		play_toggle()
	else:
		play_click()


func _ensure_player_pool() -> void:
	if not _players.is_empty():
		return
	for i in range(PLAYER_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "MenuSfxPlayer%d" % i
		player.volume_db = -8.0
		add_child(player)
		_players.append(player)


func _load_streams() -> void:
	_streams.clear()
	_streams["hover_a"] = _stream(STREAM_HOVER_A_ID)
	_streams["hover_b"] = _stream(STREAM_HOVER_B_ID)
	_streams["click"] = _stream(STREAM_CLICK_ID)
	_streams["confirm"] = _stream(STREAM_CONFIRM_ID)
	_streams["open"] = _stream(STREAM_OPEN_ID)
	_streams["close"] = _stream(STREAM_CLOSE_ID)
	_streams["back"] = _stream(STREAM_BACK_ID)
	_streams["error"] = _stream(STREAM_ERROR_ID)
	_streams["toggle"] = _stream(STREAM_TOGGLE_ID)


func _stream(id: StringName) -> AudioStream:
	return ASSET_REGISTRY.audio(id)


func _play_stream(key: String) -> void:
	var stream: AudioStream = _streams.get(key, null) as AudioStream
	if stream == null:
		return
	var player: AudioStreamPlayer = _next_available_player()
	if player == null:
		return
	player.stream = stream
	player.play()


func _next_available_player() -> AudioStreamPlayer:
	if _players.is_empty():
		return null
	for i in range(_players.size()):
		var idx: int = (_next_player + i) % _players.size()
		var candidate: AudioStreamPlayer = _players[idx]
		if candidate != null and not candidate.playing:
			_next_player = (idx + 1) % _players.size()
			return candidate
	var fallback: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return fallback
