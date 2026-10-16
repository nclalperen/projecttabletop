---
name: okey-test
description: Run Godot 4.7.1 headless test suites (fast suite, single test script, or full test matrix including scene smoke and EOS lanes). Trigger via /okey-test or when verifying GDScript changes.
---

# Okey 101 & Tabletop Hub Test Runner (`/okey-test`)

Use this skill whenever you modify GDScript (`.gd`) or scene (`.tscn`) files in the repository and need to verify correctness, scene contracts, and asset literal guards.

## 1. Fast Headless Test Suite (Default — ~6s)

Runs all 25+ core, UI, 3D subsystem, and guard test suites without slow scene-smoke or live EOS network dependencies:

```powershell
.\tools\godot.cmd --headless -s tests/run_tests_fast.gd
```

## 2. Targeted Single Test Suite

When iterating on a specific subsystem, run a single test file via `tests/run_single_test.gd`:

```powershell
.\tools\godot.cmd --headless -s tests/run_single_test.gd -- --test=res://tests/test_phase5_polish_subsystems.gd
```

Common UI/3D test suites:
- `res://tests/test_okey_play_hud_declarative.gd` — Phase 1 declarative HUD & reactive session snapshots
- `res://tests/test_tile_drag_and_input_subsystems.gd` — Phase 2 3D raycast input, drag spring visualizer & rack reflow
- `res://tests/test_meld_and_discard_subsystems.gd` — Phase 3 3D meld extension sockets, discard stacks & camera rig
- `res://tests/test_common_tabletop_components.gd` — Phase 4 shared `TableEnvironment3D` & `PlayerSeatBadge`
- `res://tests/test_phase5_polish_subsystems.gd` — Phase 5/6 world-projected meld pills, focus navigator, 3D audio, round summary modal & 3D focus reticle
- `res://tests/test_no_direct_asset_literals.gd` — Enforces zero direct `"res://assets/"` or `"res://Kenney_c0/"` literals
- `res://tests/test_ui_scene_contract.gd` — Enforces required node structure across core scenes

## 3. Full Test Matrix (Pre-Release Verification)

Runs the complete matrix including scene smoke tests and optional EOS runtime lanes:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_tests_matrix.ps1 -IncludeSceneSmoke
```

## Troubleshooting Common Failures

- **`Direct asset literal forbidden`**: Never hardcode `"res://assets/..."` or `"res://Kenney_c0/..."` in `ui/`, `core/`, `net/`, or `bots/`. Always resolve assets via `AssetRegistry.gd` and `AssetIds.gd`.
- **GDScript Lambda Capture**: Primitive variables (`bool`, `int`, `StringName`) captured inside GDScript 4 lambdas are captured by value. Use a `Dictionary` (e.g., `var state := {"fired": false}`) when mutating state inside signal callbacks in tests.
