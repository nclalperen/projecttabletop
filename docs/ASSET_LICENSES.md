# Asset Licenses (Art/Audio: CC0 or Public Domain)

This registry is the source of truth for shipping asset license compliance.

## Policy

- Art/audio assets: `CC0` or `Public Domain` only.
- Code/tooling may use permissive OSS (`MIT` / `Apache-2.0` / `BSD`) with separate documentation.
- Any runtime-used external asset missing from this registry is a release blocker.

## Status Values

- `approved`: cleared for shipping.
- `blocked`: not cleared, cannot ship.
- `replaced`: no longer runtime-used.

## Registry Schema

| Source URL | License URL | Asset Name | Imported File Path | License | Hash/Version | Reviewer | Date Added | Status |
|---|---|---|---|---|---|---|---|---|
| local://alperen/blender | local://alperen/license/cc0-dedication | Rack model | `res://uassets/gameplay/3d/models/rack.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | approved |
| local://alperen/blender | local://alperen/license/cc0-dedication | Tile model | `res://uassets/archive/models/tile.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| local://alperen/blender | local://alperen/license/cc0-dedication | Tile library | `res://uassets/gameplay/3d/models/tiles_library.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | approved |
| local://alperen/blender | local://alperen/license/cc0-dedication | Red tileset | `res://uassets/archive/models/tilesetred.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| local://alperen/blender | local://alperen/license/cc0-dedication | Blue tileset | `res://uassets/archive/models/tilesetblue.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| local://alperen/blender | local://alperen/license/cc0-dedication | Yellow tileset | `res://uassets/archive/models/tilesetyellow.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| local://alperen/blender | local://alperen/license/cc0-dedication | Green tileset | `res://uassets/archive/models/tilesetgreen.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| local://alperen/blender | local://alperen/license/cc0-dedication | Fake okey tileset | `res://uassets/archive/models/tilesetfakeokey.glb` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| local://alperen/blender | local://alperen/license/cc0-dedication | Rack base color texture | `res://uassets/archive/textures/rack-basecolor.png` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| local://alperen/blender | local://alperen/license/cc0-dedication | Cloth texture | `res://uassets/gameplay/3d/textures/cloth-texture.png` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | approved |
| local://alperen/blender | local://alperen/license/cc0-dedication | Tile face texture | `res://uassets/archive/textures/tile-texture.png` | CC0 (user-authored) | v1-local | Alperen | 2026-02-13 | replaced |
| https://polyhaven.com/a/studio_small_01 | https://polyhaven.com/license | Studio HDRI 01 | `res://uassets/gameplay/3d/hdri/studio_small_01_4k.hdr` | CC0 | 4k | Codex | 2026-02-13 | approved |
| https://polyhaven.com/a/studio_small_03 | https://polyhaven.com/license | Studio HDRI 03 | `res://uassets/gameplay/3d/hdri/studio_small_03_4k.hdr` | CC0 | 4k | Codex | 2026-02-13 | approved |
| https://ambientcg.com/a/Fabric083 | https://docs.ambientcg.com/license/ | Fabric083 (felt set) | `res://uassets/gameplay/3d/textures/felt/fabric083_2k_jpg/*` | CC0 | 2K-JPG | Codex | 2026-02-13 | approved |
| https://polyhaven.com/a/wood_table_worn | https://polyhaven.com/license | Wood Table Worn (set) | `res://uassets/gameplay/3d/textures/wood/wood_table_worn_2k_jpg/*` | CC0 | 2K-JPG | Codex | 2026-02-13 | approved |
| https://polyhaven.com/a/wood_table_001 | https://polyhaven.com/license | Wood Table 001 (set) | `res://uassets/gameplay/3d/textures/wood/wood_table_001_2k_jpg/*` | CC0 | 2K-JPG | Codex | 2026-02-13 | approved |
| https://kenney.nl/assets/impact-sounds | https://kenney.nl/support | Kenney Impact Sounds (selected) | `res://uassets/gameplay/audio/discard.ogg`, `res://uassets/gameplay/audio/take_discard.ogg` | CC0/Public Domain | 1.0 | Codex | 2026-02-13 | approved |
| https://kenney.nl/assets/interface-sounds | https://kenney.nl/support | Kenney Interface Sounds (selected) | `res://uassets/gameplay/audio/draw_from_deck.ogg`, `res://uassets/gameplay/audio/rack_move.ogg`, `res://uassets/gameplay/audio/stage_move.ogg`, `res://uassets/gameplay/audio/add_to_meld.ogg`, `res://uassets/gameplay/audio/invalid_action.ogg`, `res://uassets/gameplay/audio/round_end.ogg`, `res://uassets/gameplay/audio/new_round.ogg` | CC0/Public Domain | 1.0 | Codex | 2026-02-13 | approved |
| https://freesound.org/s/712772/ | https://freesound.org/help/faq/#licenses | Evening Chores ambience | `res://uassets/gameplay/audio/ambient_table.wav` | CC0 | 712772 | Codex | 2026-02-13 | approved |

## Approved External CC0 Sources

- Poly Haven: https://polyhaven.com/license
- ambientCG: https://docs.ambientcg.com/license/
- Kenney: https://kenney.nl/support
- Kenney Audio Catalog: https://kenney.nl/assets/category:Audio
- Freesound (CC0 items only): https://freesound.org/help/faq/#licenses

## Notes

- `ui/services/AudioService.gd` supports both procedural fallback and optional CC0 sample pack loading from `res://uassets/gameplay/audio`.

