---
name: party-menu-hud
description: Build or restyle the Tabletop Party main menu (ui/MainMenu.tscn) as a chunky, bouncy, glass-panel HUD overlay over a live 3D table - profile pill, party tray, game mode cards, glowing PLAY NOW CTA, secondary pills, hover tilt/press juice. Trigger via /party-menu-hud or when editing MainMenu layout, MenuStyleRegistry tokens, or menu button feel.
---

# Party Main Menu HUD Overlay (`/party-menu-hud`)

Use this skill to implement the "Tabletop Party / 101 Okey" main menu as a transparent 16:9 HUD that sits on top of the live 3D table (see `/menu-3d-backdrop` for the scene behind it).

## Files You Will Touch

| File | Role |
| --- | --- |
| `ui/MainMenu.tscn` / `ui/MainMenu.gd` | Root `Control`, layout, button wiring, `_apply_responsive_layout()` |
| `ui/services/MenuStyleRegistry.gd` | Single source of colors / scalars / vectors (`_COLORS`, `_SCALARS`, `_VECTORS`) |
| `ui/widgets/IconTextButton.tscn` | Reusable icon + label button (`style_variant`, `icon_texture`, `button_label`) |
| `ui/services/MenuAudioService.gd` | `bind_button()`, `play_hover()`, `play_confirm()` SFX |
| `ui/services/PlayerProfile.gd` | Nickname / avatar data for the profile pill |
| `gd/config/TabletopGameCatalog.gd` | Game ids, names, `min_players`/`max_players` for mode cards |
| `ui/themes/MainMenuTheme.tres` | Theme defaults (fonts, base styleboxes) |
| `tests/test_ui_menu_scene_contract.gd` | Node-path contract the scene must satisfy |

## Hard Rules

1. **Asset guard**: never write `"res://assets/..."` or `"res://Kenney_c0/..."` literals. Resolve textures/fonts/audio via `AssetRegistry.gd` + `AssetIds.gd` (add new ids there first). The PostToolUse hook `check_asset_literals_hook.ps1` will flag violations.
2. **Style tokens only**: every new color, radius, border width, tilt angle, or tween duration goes into `MenuStyleRegistry` and is read with `_style_color()`, `_style_scalar()`, `_style_vector()`. No inline `Color(...)` in `MainMenu.gd`.
3. **Scene contract**: keep `StartButton`, `SettingsButton`, `QuitButton`, and `SettingsSummary` reachable at the paths listed in `tests/test_ui_menu_scene_contract.gd`. If the layout restructure moves them, update the contract test in the same change and run `/okey-test`.
4. **Pass-through input**: every full-rect layout container (`LayoutSplit`, spacers, the open viewport area) must use `mouse_filter = MOUSE_FILTER_IGNORE` so clicks in empty space reach the 3D scene. Only interactive widgets use `STOP`.
5. **Turkish glyphs**: labels like "MASAYA OTUR", "Karakter Stüdyosu", "Satranç" need `ş ç ü ğ ı İ`. Verify glyph coverage of `UI_FONT_KENNEY_FUTURE`; fall back to `UI_FONT_BARLOW_CONDENSED_BOLD` (or a `FontVariation` with fallbacks) for any string with Turkish characters.

## Palette Tokens (add to `_COLORS`)

| Token | Purpose | Suggested value |
| --- | --- | --- |
| `party_amber` | Primary CTA fill, leader crown | `Color(1.0, 0.62, 0.12)` |
| `party_teal` | Selected card ring, online accents | `Color(0.0, 0.82, 0.78)` |
| `party_lime` | Online dot, positive badges | `Color(0.62, 0.92, 0.2)` |
| `party_cream` | Text on glass, borders | `Color(1.0, 0.96, 0.86)` |
| `party_glass` | Panel fill (translucent) | `Color(0.08, 0.1, 0.14, 0.45)` |
| `party_ink` | Text on amber / bevel shadow | `Color(0.12, 0.08, 0.04)` |

Keep to these 5-6 colors; do not reintroduce the old brown `panel_shell` look on new widgets.

## Layout Blueprint (16:9 reference 1920x1080)

```
MainMenu (Control, full rect, mouse IGNORE)
├─ TopBar (HBoxContainer, top-wide, margin 24)
│  ├─ ProfilePill      avatar TextureRect (circle mask) + nickname + crown "Party Leader" badge + status dot
│  ├─ Spacer (expand, IGNORE)
│  └─ PartyTray        InviteButton(+) · MicToggle · SettingsButton(gear) · QuitButton
├─ ActionZone (VBoxContainer, left, width <= 40% of viewport)
│  ├─ GameLogo         "TABLETOP PARTY" + "101 OKEY" (stacked, slight -2deg rotation)
│  ├─ ModeCards        HBox/HFlow of GameModeCard x4 (okey101, backgammon, poker, chess)
│  ├─ StartButton      giant amber CTA "MASAYA OTUR / PLAY NOW"
│  └─ SecondaryRow     "Karakter Stüdyosu" pill · "Masa Ayarları" pill
└─ OpenViewport (Control, expand, IGNORE)  <- >= 60% width, nothing drawn here
```

- Use anchors/containers, not absolute positions, so `_apply_responsive_layout()` can switch between desktop (1920x1080) and mobile landscape (1600x720): shrink cards to 2x2 grid and drop subtitle text under ~1280 px width.
- Map catalog ids: Okey 101 = `GAME_OKEY_101`, Tavla = `GAME_BACKGAMMON`, Poker = `GAME_POKER`, Satranç = `GAME_CHESS`. Player-count badge text comes from catalog `min_players`-`max_players`, never hardcoded.

## Chunky Glass Panels

Build with `StyleBoxFlat` in code (or `MainMenuTheme.tres`):

```gdscript
func _party_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = _style_color(&"party_glass")
	sb.border_color = _style_color(&"party_cream")
	sb.set_border_width_all(int(_style_scalar(&"party_border_width")))   # 4-6 px
	sb.set_corner_radius_all(int(_style_scalar(&"party_corner_radius")))  # 20-28 px
	sb.shadow_color = Color(_style_color(&"party_ink"), 0.45)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2(0, 6)   # hard drop = fake 3D bevel
	sb.anti_aliasing = true
	return sb
```

For true background blur put a `ColorRect` (or `Panel` with `material`) behind the panel content using a canvas_item shader that samples `hint_screen_texture, filter_linear_mipmap` with `textureLod(..., lod)` (lod ~2.5-4). Store the shader at `ui/shaders/glass_blur.gdshader`. Blur is a GPU cost; gate it behind `VisualQualityService` and fall back to plain translucent fill on low quality / web / mobile.

## Juice: Hover Tilt, Pop, and Bouncy Press

Containers reset position/size but keep `rotation` and `scale`, so animate those. Always keep `pivot_offset` centered:

```gdscript
func _bind_party_juice(control: Control) -> void:
	control.resized.connect(func(): control.pivot_offset = control.size * 0.5)
	control.pivot_offset = control.size * 0.5
	control.mouse_entered.connect(_on_party_hover.bind(control, true))
	control.mouse_exited.connect(_on_party_hover.bind(control, false))
	control.focus_entered.connect(_on_party_hover.bind(control, true))   # gamepad parity
	control.focus_exited.connect(_on_party_hover.bind(control, false))
	if control is BaseButton:
		(control as BaseButton).button_down.connect(_on_party_press.bind(control))
		(control as BaseButton).button_up.connect(_on_party_hover.bind(control, true))

func _on_party_hover(control: Control, hovered: bool) -> void:
	var tilt := deg_to_rad(_style_scalar(&"party_hover_tilt_deg")) * (1.0 if control.get_index() % 2 == 0 else -1.0)
	var tw := control.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_parallel()
	tw.tween_property(control, "scale", Vector2.ONE * (1.06 if hovered else 1.0), 0.16)
	tw.tween_property(control, "rotation", tilt if hovered else 0.0, 0.16)

func _on_party_press(control: Control) -> void:
	var tw := control.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(control, "scale", Vector2(1.08, 0.9), 0.06)
	tw.tween_property(control, "scale", Vector2.ONE, 0.28)
```

- Tilt range is **-1deg to 1deg** (`party_hover_tilt_deg = 1.0`); mode cards may also lift (`scale` 1.08) and brighten their teal ring when hovered/selected.
- CTA glow: pulse `self_modulate` or a child glow `Panel` alpha with a looping tween (`set_loops()`); kill/recreate tweens instead of stacking them (keep a reference per control).
- Respect a reduced-motion setting from `UISettings` if present: skip tilt/elastic and use plain fades.
- Wire every new button through `MenuAudioService.bind_button()`; CTA uses `play_confirm()`.
- Every interactive widget must be focusable (`focus_mode = FOCUS_ALL`) with explicit `focus_neighbor_*` so keyboard/controller navigation flows TopBar -> ModeCards -> CTA -> SecondaryRow. Show the controller glyph via `ui/widgets/InputPromptBadge.tscn` on the CTA.

## Verify

1. `/okey-test` (fast suite) - scene contract + asset guards must pass.
2. Launch the menu: `./tools/godot --path . res://ui/MainMenu.tscn` (Windows: `.\tools\godot.cmd`).
3. Visual check at 1920x1080 and 1600x720 (and the web build via `/web-preview` if blur is enabled): center-right 60% stays clear, no clipped Turkish glyphs, hover tilt stays within +/-1deg, focus ring visible on every button.
