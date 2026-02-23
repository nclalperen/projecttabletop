extends RefCounted
class_name MenuStyleRegistry

const _COLORS := {
	&"bg_pattern": Color(0.18, 0.16, 0.11, 0.9),
	&"backdrop_tint": Color(0.07, 0.06, 0.04, 0.68),
	&"panel_shell": Color(0.34, 0.29, 0.22, 0.97),
	&"panel_border": Color(0.92, 0.8, 0.59, 0.92),
	&"title_text": Color(0.96, 0.9, 0.78, 1.0),
	&"subtitle_text": Color(0.9, 0.85, 0.75, 0.97),
	&"body_text": Color(0.92, 0.87, 0.78, 0.95),
	&"muted_text": Color(0.82, 0.77, 0.67, 0.88),
	&"chip_text": Color(0.95, 0.89, 0.77, 0.98),
	&"chip_icon": Color(0.98, 0.86, 0.58, 1.0),
	&"button_primary_font": Color(0.14, 0.11, 0.08, 1.0),
	&"button_primary_hover_font": Color(0.12, 0.09, 0.07, 1.0),
	&"button_secondary_font": Color(0.94, 0.9, 0.83, 1.0),
	&"button_secondary_hover_font": Color(0.98, 0.95, 0.87, 1.0),
	&"button_disabled_font": Color(0.77, 0.72, 0.65, 0.75),
	&"button_primary_tint": Color(1.0, 0.94, 0.79, 1.0),
	&"button_primary_hover_tint": Color(1.0, 0.96, 0.84, 1.0),
	&"button_primary_pressed_tint": Color(0.89, 0.82, 0.68, 1.0),
	&"button_secondary_tint": Color(0.46, 0.35, 0.24, 1.0),
	&"button_secondary_hover_tint": Color(0.52, 0.39, 0.27, 1.0),
	&"button_secondary_pressed_tint": Color(0.4, 0.3, 0.21, 1.0),
	&"button_disabled_tint": Color(0.37, 0.31, 0.28, 0.9),
	&"button_icon_normal": Color(0.96, 0.92, 0.84, 1.0),
	&"button_icon_hover": Color(1.0, 0.96, 0.88, 1.0),
	&"button_icon_pressed": Color(0.9, 0.84, 0.74, 1.0),
	&"prompt_text": Color(0.93, 0.88, 0.76, 0.97),
	&"prompt_icon": Color(0.95, 0.86, 0.67, 1.0),
	&"prompt_shadow": Color(0, 0, 0, 0.35),
	&"lobby_player_local": Color(0.99, 0.91, 0.74, 1.0),
	&"lobby_player_remote": Color(0.94, 0.88, 0.78, 1.0),
	&"lobby_ready_on": Color(0.78, 0.87, 0.69, 1.0),
	&"lobby_ready_off": Color(0.95, 0.82, 0.56, 1.0),
	&"lobby_emote_icon": Color(0.24, 0.17, 0.1, 1.0),
	&"lobby_emote_icon_hover": Color(0.2, 0.14, 0.08, 1.0),
	&"lobby_emote_icon_pressed": Color(0.17, 0.12, 0.07, 1.0),
	&"lobby_emote_tint": Color(0.96, 0.88, 0.7, 1.0),
	&"lobby_emote_tint_hover": Color(1.0, 0.94, 0.76, 1.0),
	&"lobby_emote_tint_pressed": Color(0.88, 0.79, 0.63, 1.0),
	&"lobby_emote_tint_disabled": Color(0.56, 0.5, 0.43, 0.92),
	&"field_bg": Color(0.27, 0.22, 0.16, 0.96),
	&"field_border": Color(0.9, 0.78, 0.55, 0.95),
	&"field_border_focus": Color(0.98, 0.9, 0.66, 1.0),
	&"field_text": Color(0.95, 0.9, 0.82, 1.0),
	&"field_placeholder": Color(0.76, 0.69, 0.57, 0.76),
	&"field_shadow": Color(0, 0, 0, 0.25),
}

const _SCALARS := {
	&"motion_menu_in": 0.22,
	&"motion_button_in": 0.18,
	&"motion_stagger": 0.035,
	&"motion_fade_out": 0.2,
	&"press_scale": 1.02,
	&"panel_margin": 12.0,
	&"panel_content_x": 14.0,
	&"panel_content_y": 12.0,
	&"panel_border_margin": 12.0,
	&"button_h_separation": 12.0,
	&"button_font_size": 22.0,
	&"prompt_font_size": 16.0,
	&"prompt_shadow_offset": 1.0,
}

const _VECTORS := {
	&"icon_button_min": Vector2(0.0, 60.0),
	&"emote_button_min": Vector2(54.0, 54.0),
	&"main_menu_min": Vector2(420.0, 540.0),
	&"main_menu_max": Vector2(820.0, 820.0),
	&"online_card_min": Vector2(520.0, 500.0),
	&"online_card_max": Vector2(1480.0, 900.0),
	&"settings_panel_min": Vector2(460.0, 500.0),
	&"settings_panel_max": Vector2(980.0, 760.0),
}


static func color(id: StringName) -> Color:
	return _COLORS.get(id, Color(1, 0, 1, 1))


static func scalar(id: StringName) -> float:
	return float(_SCALARS.get(id, 0.0))


static func vector(id: StringName) -> Vector2:
	return _VECTORS.get(id, Vector2.ZERO)
