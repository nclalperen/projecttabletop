extends RefCounted
class_name AssetCatalog

const IDS: Script = preload("res://gd/assets/AssetIds.gd")

# Canonical runtime catalog: all runtime lookups resolve through uassets.
static var _id_to_path: Dictionary = {
	# UI fonts
	IDS.UI_FONT_KENNEY_FUTURE: "res://uassets/ui/fonts/Kenney Future.ttf",
	IDS.UI_FONT_KENNEY_FUTURE_NARROW: "res://uassets/ui/fonts/Kenney Future Narrow.ttf",

	# UI shells and buttons
	IDS.UI_PANEL_BORDER_GREY_DETAIL: "res://uassets/ui/panels/panel_border_grey_detail.png",
	IDS.UI_PANEL_GREY_DARK: "res://uassets/ui/panels/panel_grey_dark.png",
	IDS.UI_PANEL_PATTERN_DIAGONAL_TRANSPARENT_SMALL: "res://uassets/ui/panels/pattern_diagonal_transparent_small.png",
	IDS.UI_BUTTON_RECT_GOLD: "res://uassets/ui/buttons/button_rectangle_depth_gradient_gold.png",
	IDS.UI_BUTTON_RECT_BLUE: "res://uassets/ui/buttons/button_rectangle_depth_gradient_blue.png",

	# UI board icons
	IDS.UI_ICON_CARD_ADD: "res://uassets/ui/icons/board/card_add.png",
	IDS.UI_ICON_PAWNS: "res://uassets/ui/icons/board/pawns.png",
	IDS.UI_ICON_LOCK_CLOSED: "res://uassets/ui/icons/board/lock_closed.png",
	IDS.UI_ICON_LOCK_OPEN: "res://uassets/ui/icons/board/lock_open.png",
	IDS.UI_ICON_TIMER_100: "res://uassets/ui/icons/board/timer_100.png",
	IDS.UI_ICON_CARDS_STACK: "res://uassets/ui/icons/board/cards_stack.png",
	IDS.UI_ICON_HOURGLASS: "res://uassets/ui/icons/board/hourglass.png",
	IDS.UI_ICON_CROWN_A: "res://uassets/ui/icons/board/crown_a.png",

	# UI support and emote icons
	IDS.UI_ICON_GEAR: "res://uassets/ui/icons/support/gear.png",
	IDS.UI_ICON_CHECKMARK: "res://uassets/ui/icons/support/checkmark.png",
	IDS.UI_ICON_CROSS: "res://uassets/ui/icons/support/cross.png",
	IDS.UI_ICON_RETURN: "res://uassets/ui/icons/support/return.png",
	IDS.UI_ICON_QUESTION: "res://uassets/ui/icons/emotes/question.png",
	IDS.UI_ICON_WARNING: "res://uassets/ui/icons/emotes/warning.png",
	IDS.UI_ICON_STAR: "res://uassets/ui/icons/emotes/star.png",
	IDS.UI_ICON_TROPHY: "res://uassets/ui/icons/emotes/trophy.png",

	# UI prompt icons
	IDS.UI_PROMPT_ESC: "res://uassets/ui/icons/prompts/tile_0017.png",
	IDS.UI_PROMPT_ENTER: "res://uassets/ui/icons/prompts/tile_0133.png",
	IDS.UI_PROMPT_SPACE: "res://uassets/ui/icons/prompts/tile_0135.png",
	IDS.UI_PROMPT_MOUSE_LEFT: "res://uassets/ui/icons/prompts/mouseLeft.png",
	IDS.UI_PROMPT_MOUSE_RIGHT: "res://uassets/ui/icons/prompts/mouseRight.png",

	# UI avatars
	IDS.UI_AVATAR_FACE_1: "res://uassets/ui/avatars/face1.png",
	IDS.UI_AVATAR_FACE_2: "res://uassets/ui/avatars/face2.png",
	IDS.UI_AVATAR_FACE_3: "res://uassets/ui/avatars/face3.png",
	IDS.UI_AVATAR_FACE_4: "res://uassets/ui/avatars/face4.png",

	# UI audio
	IDS.UI_AUDIO_ROLLOVER_3: "res://uassets/audio/ui/rollover3.ogg",
	IDS.UI_AUDIO_ROLLOVER_5: "res://uassets/audio/ui/rollover5.ogg",
	IDS.UI_AUDIO_CLICK_3: "res://uassets/audio/ui/click3.ogg",
	IDS.UI_AUDIO_CLICK_4: "res://uassets/audio/ui/click4.ogg",
	IDS.UI_AUDIO_SWITCH_12: "res://uassets/audio/ui/switch12.ogg",
	IDS.UI_AUDIO_OPEN_002: "res://uassets/audio/interface/open_002.ogg",
	IDS.UI_AUDIO_CLOSE_002: "res://uassets/audio/interface/close_002.ogg",
	IDS.UI_AUDIO_BACK_002: "res://uassets/audio/interface/back_002.ogg",
	IDS.UI_AUDIO_ERROR_004: "res://uassets/audio/interface/error_004.ogg",

	# Gameplay 3D textures
	IDS.GAMEPLAY_TEXTURE_CLOTH: "res://uassets/gameplay/3d/textures/cloth-texture.png",
	IDS.GAMEPLAY_TEXTURE_RACK_BASECOLOR: "res://uassets/gameplay/3d/textures/wood/wood_table_001_2k_jpg/diffuse.jpg",
	IDS.GAMEPLAY_TEXTURE_TILE_FACE: "res://uassets/gameplay/3d/textures/cloth-texture.png",
	IDS.GAMEPLAY_HDRI_STUDIO_SMALL_01: "res://uassets/gameplay/3d/hdri/studio_small_01_4k.hdr",
	IDS.GAMEPLAY_HDRI_STUDIO_SMALL_03: "res://uassets/gameplay/3d/hdri/studio_small_03_4k.hdr",
	IDS.GAMEPLAY_TEXTURE_FELT_COLOR: "res://uassets/gameplay/3d/textures/felt/fabric083_2k_jpg/color.jpg",
	IDS.GAMEPLAY_TEXTURE_FELT_ROUGHNESS: "res://uassets/gameplay/3d/textures/felt/fabric083_2k_jpg/roughness.jpg",
	IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_DIFFUSE: "res://uassets/gameplay/3d/textures/wood/wood_table_worn_2k_jpg/diffuse.jpg",
	IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_NORMAL: "res://uassets/gameplay/3d/textures/wood/wood_table_worn_2k_jpg/normal_gl.jpg",
	IDS.GAMEPLAY_TEXTURE_TABLE_WOOD_ROUGHNESS: "res://uassets/gameplay/3d/textures/wood/wood_table_worn_2k_jpg/roughness.jpg",
	IDS.GAMEPLAY_TEXTURE_RACK_WOOD_DIFFUSE: "res://uassets/gameplay/3d/textures/wood/wood_table_001_2k_jpg/diffuse.jpg",
	IDS.GAMEPLAY_TEXTURE_RACK_WOOD_NORMAL: "res://uassets/gameplay/3d/textures/wood/wood_table_001_2k_jpg/normal_gl.jpg",
	IDS.GAMEPLAY_TEXTURE_RACK_WOOD_ROUGHNESS: "res://uassets/gameplay/3d/textures/wood/wood_table_001_2k_jpg/roughness.jpg",

	# Gameplay 3D models
	IDS.GAMEPLAY_MODEL_RACK: "res://uassets/gameplay/3d/models/rack.glb",
	IDS.GAMEPLAY_MODEL_TILE: "res://uassets/gameplay/3d/models/tiles_library.glb",
	IDS.GAMEPLAY_MODEL_TILES_LIBRARY: "res://uassets/gameplay/3d/models/tiles_library.glb",
	IDS.GAMEPLAY_MODEL_TILESET_RED: "res://uassets/gameplay/3d/models/tiles_library.glb",
	IDS.GAMEPLAY_MODEL_TILESET_BLUE: "res://uassets/gameplay/3d/models/tiles_library.glb",
	IDS.GAMEPLAY_MODEL_TILESET_YELLOW: "res://uassets/gameplay/3d/models/tiles_library.glb",
	IDS.GAMEPLAY_MODEL_TILESET_GREEN: "res://uassets/gameplay/3d/models/tiles_library.glb",
	IDS.GAMEPLAY_MODEL_TILESET_FAKE_OKEY: "res://uassets/gameplay/3d/models/tiles_library.glb",

	# Gameplay audio
	IDS.GAMEPLAY_AUDIO_DRAW_FROM_DECK: "res://uassets/gameplay/audio/draw_from_deck.ogg",
	IDS.GAMEPLAY_AUDIO_TAKE_DISCARD: "res://uassets/gameplay/audio/take_discard.ogg",
	IDS.GAMEPLAY_AUDIO_RACK_MOVE: "res://uassets/gameplay/audio/rack_move.ogg",
	IDS.GAMEPLAY_AUDIO_STAGE_MOVE: "res://uassets/gameplay/audio/stage_move.ogg",
	IDS.GAMEPLAY_AUDIO_ADD_TO_MELD: "res://uassets/gameplay/audio/add_to_meld.ogg",
	IDS.GAMEPLAY_AUDIO_DISCARD: "res://uassets/gameplay/audio/discard.ogg",
	IDS.GAMEPLAY_AUDIO_INVALID_ACTION: "res://uassets/gameplay/audio/invalid_action.ogg",
	IDS.GAMEPLAY_AUDIO_ROUND_END: "res://uassets/gameplay/audio/round_end.ogg",
	IDS.GAMEPLAY_AUDIO_NEW_ROUND: "res://uassets/gameplay/audio/new_round.ogg",
	IDS.GAMEPLAY_AUDIO_AMBIENT_TABLE: "res://uassets/gameplay/audio/ambient_table.wav",
}


static func path_for(id: StringName) -> String:
	var p = _id_to_path.get(id, "")
	return str(p)


static func has_id(id: StringName) -> bool:
	return _id_to_path.has(id)


static func all_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key in _id_to_path.keys():
		out.append(StringName(key))
	return out


static func all_entries() -> Dictionary:
	return _id_to_path.duplicate()
