# Tabletop Studio Plugin Rules (Okey 101 & Tabletop Hub)

1. **Asset Registry Guard (`tests/test_no_direct_asset_literals.gd`)**:
   - Never hardcode `"res://assets/..."` or `"res://Kenney_c0/..."` string literals inside `ui/`, `core/`, `net/`, or `bots/`. Always resolve assets via `AssetRegistry.gd` and `AssetIds.gd`.
2. **Scene Contract Preservation (`tests/test_ui_scene_contract.gd`)**:
   - Preserve required top-level nodes in core scenes (`GameTable3D.tscn`, `GameTable.tscn`, `StarterMenu.tscn`, `OnlineLobby.tscn`).
3. **Declarative UI & Shared 3D Shell**:
   - Use `ui/themes/okey_theme.tres` type variations and `PlayerSeatBadge.tscn` for HUD elements.
   - Use `TableEnvironment3D.gd` driven by `TableConfig` and `SeatConfig` for multi-game 3D tables.
4. **Headless Verification**:
   - Run `.\tools\godot.cmd --headless -s tests/run_tests_fast.gd` (`/okey-test`) after modifying GDScript or scenes.
