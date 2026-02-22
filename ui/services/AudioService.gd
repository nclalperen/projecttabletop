extends Node
class_name AudioService

const EVENT_DRAW_FROM_DECK: StringName = &"draw_from_deck"
const EVENT_TAKE_DISCARD: StringName = &"take_discard"
const EVENT_RACK_MOVE: StringName = &"rack_move"
const EVENT_STAGE_MOVE: StringName = &"stage_move"
const EVENT_ADD_TO_MELD: StringName = &"add_to_meld"
const EVENT_DISCARD: StringName = &"discard"
const EVENT_INVALID_ACTION: StringName = &"invalid_action"
const EVENT_ROUND_END: StringName = &"round_end"
const EVENT_NEW_ROUND: StringName = &"new_round"

const PACK_PROCEDURAL: StringName = &"procedural"
const PACK_CC0: StringName = &"cc0"
const CC0_AUDIO_BASE_PATH: String = "res://assets/audio/cc0"

const SFX_POOL_SIZE: int = 8
const SAMPLE_RATE: int = 22050

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null
var _sfx_streams: Dictionary = {}
var _ambient_stream: AudioStream = null
var _sfx_db: float = -6.0
var _music_db: float = -22.0
var _next_sfx_index: int = 0
var _content_pack: StringName = PACK_PROCEDURAL

func _ready() -> void:
	_ensure_players()
	_build_streams()
	_apply_levels()
	_start_ambient_loop()


func play_sfx(event_id: StringName) -> void:
	var stream: AudioStream = _sfx_streams.get(event_id, null) as AudioStream
	if stream == null:
		stream = _sfx_streams.get(EVENT_INVALID_ACTION, null) as AudioStream
	if stream == null:
		return
	var player: AudioStreamPlayer = _next_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.play()


func set_bus_levels(sfx_db: float, music_db: float) -> void:
	_sfx_db = clampf(sfx_db, -60.0, 6.0)
	_music_db = clampf(music_db, -60.0, 6.0)
	_apply_levels()


func set_levels_linear(sfx_volume: float, music_volume: float) -> void:
	set_bus_levels(_linear_to_db_safe(sfx_volume), _linear_to_db_safe(music_volume))


func set_content_pack(pack_id: StringName) -> void:
	var chosen: StringName = pack_id if pack_id != StringName("") else PACK_PROCEDURAL
	if chosen != PACK_CC0 and chosen != PACK_PROCEDURAL:
		chosen = PACK_PROCEDURAL
	if _content_pack == chosen:
		return
	_content_pack = chosen
	_build_streams()
	_start_ambient_loop()


func _ensure_players() -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		add_child(_music_player)
	if _sfx_players.is_empty():
		for i in range(SFX_POOL_SIZE):
			var p := AudioStreamPlayer.new()
			p.name = "SfxPlayer%d" % i
			add_child(p)
			_sfx_players.append(p)


func _build_streams() -> void:
	_sfx_streams.clear()
	_sfx_streams[EVENT_DRAW_FROM_DECK] = _make_dual_tone_stream(512.0, 684.0, 0.078, 0.26)
	_sfx_streams[EVENT_TAKE_DISCARD] = _make_dual_tone_stream(470.0, 598.0, 0.095, 0.29)
	_sfx_streams[EVENT_RACK_MOVE] = _make_dual_tone_stream(336.0, 428.0, 0.060, 0.19)
	_sfx_streams[EVENT_STAGE_MOVE] = _make_dual_tone_stream(360.0, 522.0, 0.064, 0.21)
	_sfx_streams[EVENT_ADD_TO_MELD] = _make_dual_tone_stream(420.0, 640.0, 0.082, 0.24)
	_sfx_streams[EVENT_DISCARD] = _make_dual_tone_stream(272.0, 316.0, 0.076, 0.22)
	_sfx_streams[EVENT_INVALID_ACTION] = _make_dual_tone_stream(170.0, 140.0, 0.088, 0.18)
	_sfx_streams[EVENT_ROUND_END] = _make_dual_tone_stream(250.0, 182.0, 0.110, 0.50)
	_sfx_streams[EVENT_NEW_ROUND] = _make_dual_tone_stream(392.0, 588.0, 0.095, 0.40)
	_ambient_stream = _make_ambient_stream()

	if _content_pack == PACK_CC0:
		_try_apply_cc0_pack()


func _apply_levels() -> void:
	for p in _sfx_players:
		if p != null:
			p.volume_db = _sfx_db
	if _music_player != null:
		_music_player.volume_db = _music_db


func _start_ambient_loop() -> void:
	if _music_player == null or _ambient_stream == null:
		return
	_music_player.stream = _ambient_stream
	if not _music_player.playing:
		_music_player.play()


func _next_sfx_player() -> AudioStreamPlayer:
	if _sfx_players.is_empty():
		return null
	for i in range(_sfx_players.size()):
		var idx: int = (_next_sfx_index + i) % _sfx_players.size()
		var p: AudioStreamPlayer = _sfx_players[idx]
		if p != null and not p.playing:
			_next_sfx_index = (idx + 1) % _sfx_players.size()
			return p
	var fallback: AudioStreamPlayer = _sfx_players[_next_sfx_index]
	_next_sfx_index = (_next_sfx_index + 1) % _sfx_players.size()
	return fallback


func _make_dual_tone_stream(freq_a: float, freq_b: float, amplitude: float, duration: float) -> AudioStreamWAV:
	var total_samples: int = max(1, int(round(duration * float(SAMPLE_RATE))))
	var data := PackedByteArray()
	data.resize(total_samples * 2)
	var attack: float = min(0.018, duration * 0.22)
	var release: float = min(0.080, duration * 0.28)
	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var env: float = 1.0
		if attack > 0.0 and t < attack:
			env = t / attack
		elif release > 0.0 and t > duration - release:
			env = maxf(0.0, (duration - t) / release)
		var wave_a: float = sin(TAU * freq_a * t)
		var wave_b: float = sin(TAU * freq_b * t + 0.42)
		var wave: float = (wave_a * 0.62 + wave_b * 0.38) * env
		var sample_v: int = int(round(clampf(wave * amplitude, -1.0, 1.0) * 32767.0))
		var packed: int = sample_v & 0xFFFF
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	return _build_wav_stream(data, false)


func _make_ambient_stream() -> AudioStreamWAV:
	var duration: float = 2.80
	var total_samples: int = max(1, int(round(duration * float(SAMPLE_RATE))))
	var data := PackedByteArray()
	data.resize(total_samples * 2)
	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var slow_lfo: float = 0.70 + 0.30 * sin(TAU * 0.12 * t)
		var hum_a: float = sin(TAU * 73.0 * t)
		var hum_b: float = sin(TAU * 109.0 * t + 1.20)
		var hum_c: float = sin(TAU * 146.0 * t + 0.40)
		var mix: float = (hum_a * 0.55 + hum_b * 0.30 + hum_c * 0.15) * slow_lfo
		var sample_v: int = int(round(clampf(mix * 0.045, -1.0, 1.0) * 32767.0))
		var packed: int = sample_v & 0xFFFF
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	var stream: AudioStreamWAV = _build_wav_stream(data, true)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


func _build_wav_stream(data: PackedByteArray, looped: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED
	return stream


func _linear_to_db_safe(level: float) -> float:
	var clamped: float = clampf(level, 0.0, 1.0)
	if clamped <= 0.001:
		return -60.0
	return linear_to_db(clamped)


func _try_apply_cc0_pack() -> void:
	var event_to_base: Dictionary = {
		EVENT_DRAW_FROM_DECK: "draw_from_deck",
		EVENT_TAKE_DISCARD: "take_discard",
		EVENT_RACK_MOVE: "rack_move",
		EVENT_STAGE_MOVE: "stage_move",
		EVENT_ADD_TO_MELD: "add_to_meld",
		EVENT_DISCARD: "discard",
		EVENT_INVALID_ACTION: "invalid_action",
		EVENT_ROUND_END: "round_end",
		EVENT_NEW_ROUND: "new_round",
	}
	for event_id in event_to_base.keys():
		var base: String = str(event_to_base[event_id])
		var stream: AudioStream = _load_stream_from_cc0_pack(base)
		if stream != null:
			_sfx_streams[event_id] = stream

	var ambient_stream: AudioStream = _load_stream_from_cc0_pack("ambient_table")
	if ambient_stream != null:
		_ambient_stream = ambient_stream


func _load_stream_from_cc0_pack(base_name: String) -> AudioStream:
	var candidates: PackedStringArray = [
		"%s/%s.ogg" % [CC0_AUDIO_BASE_PATH, base_name],
		"%s/%s.wav" % [CC0_AUDIO_BASE_PATH, base_name],
	]
	for p in candidates:
		if FileAccess.file_exists(p):
			var stream: AudioStream = load(p) as AudioStream
			if stream != null:
				return stream
	return null
