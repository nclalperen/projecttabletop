extends RefCounted
## Verifies audio controller integration and signal dispatch in VectorGameTable3D.

const VectorGameTable3D = preload("res://ui/vector_table/VectorGameTable3D.gd")
const TableAudioController = preload("res://ui/game_table/TableAudioController.gd")


func run() -> bool:
	var table := VectorGameTable3D.new()
	if table == null:
		push_error("Failed to instantiate VectorGameTable3D")
		return false

	var audio: TableAudioController = table.get_audio_controller()
	if audio == null:
		push_error("VectorGameTable3D missing TableAudioController")
		table.free()
		return false

	if audio.name != "AudioController":
		push_error("AudioController has unexpected name: %s" % audio.name)
		table.free()
		return false

	# Verify flight completed audio handler
	table._on_flight_completed(null, &"discard")
	table._on_flight_completed(null, &"opponent_discard")
	table._on_flight_completed(null, &"draw")
	table._on_flight_completed(null, &"meld")

	# Verify input audio handlers
	table._on_input_tile_picked(null)
	table._on_input_tile_moved(0, 5)

	# Verify HUD audio triggers
	table._on_hud_sort(&"runs")
	table._on_hud_sort(&"pairs")
	table._on_hud_undo()
	table._on_hud_return_draft()

	table.free()
	print("  PASS  test_vector3d_audio")
	return true
