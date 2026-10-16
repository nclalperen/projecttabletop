# Okey 101 — 3D Vector Table Reference Architecture

This document records the locked architectural decisions, coordinate systems, and target scene tree for the 3D Vector Tabletop Engine on branch `feature/vector-tabletop`.

---

## 1. Locked Design Decisions

### D1 — The Hand Rig is Attached to the Camera
The local player's rack is **a child of `Camera3D`**, not a table object. It always faces the camera, is always large and readable, and is still lit by the scene light and part of the same 3D world, so drags onto the table work with normal raycasts.

### D2 — Tile Faces Come from One Generated Texture Atlas
At startup, `TileFaceAtlas.gd` builds **one** `ImageTexture` atlas by rendering face cells through a `SubViewport`, using a bundled bold font. Each tile then has one face quad with UV offset into the atlas. This means crisp, engraved-looking faces, the same on every platform, and no `Label3D` runtime overhead.

### D3 — One Persistent Tile Node per Tile ID
A `TileRegistry` maps `unique_id → VectorTile3D` for the whole round. Session updates **only change target transforms**; tiles are created when they first appear and freed only when the round resets. This allows springs and Bézier arcs to play continuously.

### D4 — The Session is the Single Source of Truth
The visuals never reorder the hand themselves. A drop calls `OkeySession.request_move_tile(...)` (or `overlay_move_slot`). The resulting `rack_and_draft_changed` signal drives the new targets.

### D5 — World Coordinates (Metres; Felt Top is `y = 0.075`; Local Player Sits at `+z`)
Build the table with `OkeyTableArt.build_table(world, 0.075)`. The felt interior is x ∈ [−0.579, 0.579], z ∈ [−0.469, 0.469].

| Element | Position | Rotation (deg) | Notes |
|---|---|---|---|
| Stock (deck) | (−0.035, 0.075, −0.03) | (0, 8, 0) | Flat face-down stack; small per-tile jitter of ±1.5 mm and ±2° |
| Indicator | (0.035, 0.075, −0.03) | (0, −6, 0) | Flat, face up |
| North rack (seat 2) | (0, 0.075, −0.41) | (0, 180, 0) | Opponent rack, face-down tiles, scale 0.85 |
| East rack (seat 1) | (0.51, 0.075, 0) | (0, −90, 0) | Same as North |
| West rack (seat 3) | (−0.51, 0.075, 0) | (0, 90, 0) | Same as North |
| Discard: local (out) | (0.33, 0.075, 0.27) | (0, −12, 0) | Each player discards to their right |
| Discard: East | (0.33, 0.075, −0.27) | (0, 12, 0) | |
| Discard: North | (−0.33, 0.075, −0.27) | (0, −12, 0) | |
| Discard: West (local takes from here) | (−0.33, 0.075, 0.27) | (0, 12, 0) | Southwest, left of local player |
| Meld zone | x ∈ [−0.44, 0.44], z ∈ [−0.30, 0.20], minus a 0.16 × 0.12 box around the stock | — | Flat tiles on felt |

### D6 — Camera
- `Camera3D.fov = 40.0`. Position `(0.0, 0.66, 0.70)`. Look at `(0.0, 0.0, -0.06)`.
- **No camera tweens during normal play.** Inspection mode (top-down) is opt-in only through the HUD "View" button.

### D7 — Hand Rig Geometry (in Camera-Local Space)
- Rig origin: `Vector3(0.0, -0.215, -0.56)`. Rotation: `Vector3(-8.0, 0.0, 0.0)` relative to the camera.
- Rack body: procedural mesh `HandRackMesh.gd`. Length 0.80, depth 0.07, two shelves.
- Tile pitch 0.050. Row 0 at local y = +0.040, row 1 at y = −0.030. Tiles stand upright, tilted back 6°.
- 15 tiles per row, 30 slots total. **The slot index maps 1:1 to `OkeySession.get_rack_slots()` index** (0–14 = row 0, 15–29 = row 1). Empty slots render nothing, but keep their position.

### D8 — Animation Constants (`ui/vector_table/VectorTuning3D.gd`)
| Motion | Model | Value |
|---|---|---|
| Rack reflow | Spring | ω = 26, ζ = 0.78 |
| Hover lift | Spring on local +y | 0.012 m, ω = 30, ζ = 0.70 |
| Drag follow | Spring toward pointer target | ω = 38, ζ = 0.85 |
| Drag tilt | `calculate_tilt_3d` | sensitivity 6, max 14° |
| Push-aside | Gaussian | amplitude 0.022 m, σ = 0.040 m |
| Draw (stock → rack) | Cubic Bezier | 0.42 s, apex +0.12 m, ease-out cubic, then settle by spring |
| Discard (rack → pile) | Cubic Bezier | 0.36 s, apex +0.08 m, lands with ±6° random yaw |
| Opponent discard | Cubic Bezier | 0.40 s |
| Meld open | Staggered Bezier | 0.05 s per tile, 0.32 s each |
| Invalid drop | Spring back + shake | 3 cycles, 4 mm |

---

## 2. Target Scene Tree

```
VectorGameTable3D (Node3D)                     VectorGameTable3D.gd — coordinator only
├── WorldEnvironment                           P1
├── KeyLight (DirectionalLight3D)              P1
├── FillLight (OmniLight3D)                    P1
├── Table (from OkeyTableArt.build_table)      P1
├── Camera3D                                   P1
│   └── HandRig (Node3D)                       P2  HandRig3D.gd
│       └── HandRackMesh                       P2
├── StockAndIndicator (Node3D)                 P4  StockView3D.gd
├── OpponentRacks (Node3D)                     P4  OpponentRack3D.gd ×3
├── DiscardPiles (Node3D)                      P4  DiscardPiles3D.gd
├── TableMelds (Node3D)                        P6  MeldLayout3D.gd
├── Tiles (Node3D)                             P3  TileRegistry3D.gd: every VectorTile3D lives here
├── InputController (Node)                     P5  VectorInput3D.gd
├── Animator (Node)                            P3  TileAnimator3D.gd
├── OkeySession (Node)                         existing
└── HUD (OkeyPlayHUD.tscn instance)            P7  reuse; do not hand-build buttons
```

All tiles live under `Tiles` **in world space**. When a tile belongs to the hand, its world target is computed every frame from `HandRig.global_transform * slot_local_transform`. Tiles are not re-parented between zones.

---

## 3. Phase P8: Audio Integration, Routing, and Merge Gate

### Audio Integration (`TableAudioController.gd`)
- `VectorGameTable3D` owns a dedicated `TableAudioController` instance (`"AudioController"`).
- Sound effects are triggered declaratively on physics and animation signals:
  - **Tile Landings (`flight_completed`)**: Pitch randomized ±8% on flight completion for `&"discard"`, `&"opponent_discard"`, `&"draw"`, and `&"meld"`.
  - **Input Events (`VectorInput3D`)**: `tile_picked` clack on initial drag pickup, `tile_moved` snap on slot reordering.
  - **HUD Operations (`OkeyPlayHUD`)**: `on_melds_committed` chime on valid meld opening, `on_invalid_action` buzz on rejected open, and tactile snap on `sort_runs`, `sort_pairs`, `undo`, and `return_draft`.

### Unified Presentation Routing
- Added `"vector3d"` as a first-class presentation mode across:
  - `ui/services/UISettings.gd`: `sanitize_presentation_mode` accepts `"vector3d"`.
  - `gd/config/TabletopGameCatalog.gd`: `_resolve_launch_scene_path` routes Okey 101 to `VectorGameTable3D.tscn`.
  - `ui/MainMenu.gd`: Seamless launch of `VectorGameTable3D.tscn` when `presentation_mode == "vector3d"`.
  - `ui/OnlineLobby.gd`: Multiplayer host/client and local offline matches route to `VectorGameTable3D.tscn` with `inject_controller` support.

### Verification Matrix
- **Fast Test Suite**: 38/38 tests passing (`.\tools\godot.cmd --headless -s tests/run_tests_fast.gd`).
- **Scene Contract Guard**: `tests/test_ui_vector3d_scene_contract.gd` verifies 15 required nodes, AgX tonemapping, 40° FOV, and dark `#0d0b0a` room.
- **Asset Literal Guard**: Fully compliant with `tests/test_no_direct_asset_literals.gd` via `AssetRegistry` and `AssetIds`.
- **Render Performance**: Sustained 165 FPS at 1080p and 720p forward+ renderer.

