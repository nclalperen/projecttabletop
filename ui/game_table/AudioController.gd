class_name AudioController
extends RefCounted

## Audio controller component for managing game table sound effects.
##
## Wraps audio service invocations and provides semantic helper methods
## for game actions, while respecting sound enabled settings and verifying
## service availability.

const SFX_DRAW_FROM_DECK: StringName = &"draw_from_deck"
const SFX_TAKE_DISCARD: StringName = &"take_discard"
const SFX_RACK_MOVE: StringName = &"rack_move"
const SFX_DRAFT_MOVE: StringName = &"stage_move"
const SFX_ADD_TO_MELD: StringName = &"add_to_meld"
const SFX_DISCARD: StringName = &"discard"
const SFX_INVALID_ACTION: StringName = &"invalid_action"
const SFX_ROUND_END: StringName = &"round_end"
const SFX_NEW_ROUND: StringName = &"new_round"

## Reference to the audio service node, or null for silent operation.
var audio_service: Node = null

## Whether sound playback is enabled.
var sound_enabled: bool = true


func _init(p_audio_service: Node = null, p_sound_enabled: bool = true) -> void:
	audio_service = p_audio_service
	sound_enabled = p_sound_enabled


## Plays a sound effect identified by [param sfx_id] if sound is enabled and service is available.
func play(sfx_id: StringName) -> void:
	if not sound_enabled:
		return
	if sfx_id.is_empty():
		return
	if audio_service != null and is_instance_valid(audio_service):
		if audio_service.has_method(&"play_sfx"):
			audio_service.play_sfx(sfx_id)


## Plays the draw-from-deck sound effect.
func play_draw() -> void:
	play(SFX_DRAW_FROM_DECK)


## Plays the take-discard-tile sound effect.
func play_take_discard() -> void:
	play(SFX_TAKE_DISCARD)


## Plays the rack tile movement sound effect.
func play_rack_move() -> void:
	play(SFX_RACK_MOVE)


## Plays the draft / stage area tile movement sound effect.
func play_draft_move() -> void:
	play(SFX_DRAFT_MOVE)


## Plays the add-tile-to-meld sound effect.
func play_add_to_meld() -> void:
	play(SFX_ADD_TO_MELD)


## Plays the discard tile sound effect.
func play_discard() -> void:
	play(SFX_DISCARD)


## Plays the invalid action sound effect.
func play_invalid() -> void:
	play(SFX_INVALID_ACTION)


## Plays the round end sound effect.
func play_round_end() -> void:
	play(SFX_ROUND_END)


## Plays the new round sound effect.
func play_new_round() -> void:
	play(SFX_NEW_ROUND)
