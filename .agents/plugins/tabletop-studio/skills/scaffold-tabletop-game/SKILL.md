---
name: scaffold-tabletop-game
description: Scaffold or upgrade a multi-game Tabletop Hub game (Backgammon/Tavla, Blackjack, Texas Hold'em, Chess, or a new catalog entry) using TableEnvironment3D, TableConfig, SeatConfig, and PlayerSeatBadge. Trigger via /scaffold-tabletop-game.
---

# Scaffold or Upgrade a Tabletop Hub Game (`/scaffold-tabletop-game`)

Use this skill when adding a new game to `core/platform/TabletopGameCatalog.gd` or upgrading an existing game in `ui/PlaceholderTable.gd` into a full interactive 3D tabletop experience.

## Architectural Blueprint

Every game in the Tabletop Hub shares the common 3D shell in `ui/common_tabletop/`:
1. **Catalog Entry (`core/platform/TabletopGameCatalog.gd`)**:
   - Defines `id`, `title`, `subtitle`, `min_players`, `max_players`, `status`, and `scene_path`.
2. **Table & Seat Configuration (`ui/common_tabletop/TableConfig.gd` & `SeatConfig.gd`)**:
   - Configures felt color, rim tint, table dimensions (`Vector2`), and radial `SeatConfig` anchors (`position_3d`, `rotation_degrees_y`, `hud_anchor_preset`).
3. **3D Table Environment (`ui/common_tabletop/TableEnvironment3D.gd`)**:
   - Instantiates the procedural 3D table felt, wood rim, lighting, and `SeatAnchor_<id>` `Marker3D` nodes.
4. **HUD Seat Badges (`ui/common_tabletop/PlayerSeatBadge.tscn`)**:
   - Displays each seated player's name, score/chips, active turn border, and status tag.
5. **Audio & Haptics (`ui/game_table/TableAudioController.gd`)**:
   - Provides tactile SFX and mobile vibration via `AssetRegistry.gd` and `AssetIds.gd`.

## Checklist When Adding or Upgrading a Game

1. **Core Rules (`core/<game_id>/`)**:
   - Keep game rules deterministic and decoupled from `Node3D` / `Control` presentation classes.
   - Use seeded `RandomNumberGenerator` for dice rolls, card shuffles, or deal order.
2. **Asset Guard Compliance**:
   - Never use direct `"res://assets/..."` or `"res://Kenney_c0/..."` string literals. Always query `AssetRegistry.gd` with constants from `AssetIds.gd`.
3. **Automated Test Suite (`tests/test_<game_id>.gd`)**:
   - Register the new headless test script in `tests/run_tests.gd` so `/okey-test` verifies both rules and 3D/HUD instantiation.
