---
name: menu-3d-backdrop
description: Render a live photorealistic 3D tabletop scene (table, player's Wii-style character, floating emote bubbles) behind the transparent main menu HUD, keeping the center-right 60% of the screen unobstructed. Trigger via /menu-3d-backdrop or when adding a 3D background, menu camera, idle character, or world-anchored emote bubbles to MainMenu.
---

# Live 3D Table Behind the Main Menu (`/menu-3d-backdrop`)

Pair this with `/party-menu-hud`. The HUD is a `Control` overlay; this skill owns the 3D world drawn underneath it.

## Reuse, Don't Rebuild

- Table: instance the existing shell from `ui/common_tabletop/TableEnvironment3D.gd` (felt, wood rim, lighting, `SeatAnchor_<id>` markers) configured with `TableConfig`/`SeatConfig`, or the approved Vector Okey table under `ui/vector_table/`. Do **not** fork or alter the approved Okey table layout.
- Assets: resolve every mesh/texture/audio via `AssetRegistry.gd` + `AssetIds.gd` (no `res://assets/...` literals).
- Quality: read `VisualQualityService` to pick shadows, MSAA, SSAO, glow, and whether the backdrop renders at full or reduced resolution.

## Scene Structure

Preferred: a dedicated `ui/menu_backdrop/MenuBackdrop3D.tscn` placed **below** the HUD.

```
MainMenuRoot (Control, full rect)
├─ BackdropViewportContainer (SubViewportContainer, full rect, stretch = true, mouse IGNORE)
│  └─ SubViewport (own_world_3d = true, transparent_bg = false)
│     └─ MenuBackdrop3D (Node3D)
│        ├─ WorldEnvironment   (tonemap ACES/AgX, glow on, soft fog)
│        ├─ DirectionalLight3D (warm key) + OmniLight3D (teal rim)
│        ├─ TableEnvironment3D
│        ├─ PlayerCharacter    (idle animation, standing at a SeatAnchor)
│        ├─ EmoteAnchor        (Marker3D above the character's head)
│        └─ MenuCamera3D       (slow orbit / breathing dolly)
└─ MainMenu (HUD, see /party-menu-hud)
```

- Remove or hide the old 2D `Background` TextureRect and `BackdropTint` when the 3D backdrop is active; keep a 2D fallback path for low-quality / headless test runs.
- Frame the camera so the table and character sit in the **center-right**: offset the look-at target to the right, or set `Camera3D.h_offset` (~0.3-0.6) so the composition clears the left action zone. Validate at 16:9 and at 1600x720.
- Use `SubViewport.scaling_3d_scale` (0.67-1.0) or `size_2d_override` to reduce cost on mobile/web.

## Character

- If no character model exists yet, start with a CC0 stylized low-poly humanoid (glTF/GLB) registered in `AssetIds.gd`, plus an `AnimationPlayer`/`AnimationTree` with `idle`, `wave`, and `cheer` clips.
- Customization ("Karakter Stüdyosu") should drive the character through data in `ui/services/PlayerProfile.gd` (colors, accessory ids) so the same character renders in the menu, lobby, and at the table.
- Trigger `wave` when the CTA is hovered and `cheer` on PLAY NOW press via signals from the HUD - the HUD must not reach into 3D nodes directly.

## Floating Emote Bubbles (world-anchored 2D)

Keep bubbles as HUD `Control`s (crisp text, theme-consistent) positioned from the 3D anchor every frame:

```gdscript
func _process(_delta: float) -> void:
	var cam := _backdrop_camera
	var world_pos := _emote_anchor.global_position
	if cam == null or cam.is_position_behind(world_pos):
		_emote_bubble.visible = false
		return
	var screen_pos := cam.unproject_position(world_pos)
	# SubViewport -> HUD space when the viewport is scaled.
	screen_pos *= _viewport_container.size / Vector2(_sub_viewport.size)
	_emote_bubble.visible = true
	_emote_bubble.position = screen_pos - Vector2(_emote_bubble.size.x * 0.5, _emote_bubble.size.y)
```

- Reuse `ui/widgets/LobbyEmoteButton.gd` icons/style for the bubble content; pop in with a `TRANS_BACK` scale tween and a gentle bob (sine on `position.y`).
- Bubbles must use `mouse_filter = MOUSE_FILTER_IGNORE`.

## Performance & Lifecycle

- Free or pause the backdrop (`process_mode = PROCESS_MODE_DISABLED`, `SubViewport.render_target_update_mode = UPDATE_DISABLED`) when transitioning to `OnlineLobby` or a game table via `_replace_self_in_shell()` to avoid two 3D worlds rendering.
- Headless test runs (`/okey-test`) have no renderer: guard camera/viewport logic with `DisplayServer.get_name() != "headless"` so scene instantiation tests still pass.

## Verify

1. `/okey-test` - menu scene contract and asset guards pass with the backdrop attached.
2. Run `./tools/godot --path . res://ui/MainMenu.tscn` and check: table + character visible in center-right, emote bubble tracks the head during camera motion, clicks on empty space are not swallowed by the HUD.
3. Check frame time on the lowest `VisualQualityService` tier and in the web export (`/web-preview`).
