extends Node
class_name MenuAudioService

const STREAM_HOVER_A := "res://Kenney_c0/kenney_ui-audio/Audio/rollover3.ogg"
const STREAM_HOVER_B := "res://Kenney_c0/kenney_ui-audio/Audio/rollover5.ogg"
const STREAM_CLICK := "res://Kenney_c0/kenney_ui-audio/Audio/click3.ogg"
const STREAM_CONFIRM := "res://Kenney_c0/kenney_ui-audio/Audio/click4.ogg"
const STREAM_TOGGLE := "res://Kenney_c0/kenney_ui-audio/Audio/switch12.ogg"
const STREAM_OPEN := "res://Kenney_c0/kenney_interface-sounds/Audio/open_002.ogg"
const STREAM_CLOSE := "res://Kenney_c0/kenney_interface-sounds/Audio/close_002.ogg"
const STREAM_BACK := "res://Kenney_c0/kenney_interface-sounds/Audio/back_002.ogg"
const STREAM_ERROR := "res://Kenney_c0/kenney_interface-sounds/Audio/error_004.ogg"

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
	_streams["hover_a"] = _safe_load(STREAM_HOVER_A)
	_streams["hover_b"] = _safe_load(STREAM_HOVER_B)
	_streams["click"] = _safe_load(STREAM_CLICK)
	_streams["confirm"] = _safe_load(STREAM_CONFIRM)
	_streams["open"] = _safe_load(STREAM_OPEN)
	_streams["close"] = _safe_load(STREAM_CLOSE)
	_streams["back"] = _safe_load(STREAM_BACK)
	_streams["error"] = _safe_load(STREAM_ERROR)
	_streams["toggle"] = _safe_load(STREAM_TOGGLE)


func _safe_load(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	var lowered: String = path.to_lower()
	if lowered.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_file(path)
	if lowered.ends_with(".wav"):
		return AudioStreamWAV.load_from_file(path)
	return load(path) as AudioStream


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
