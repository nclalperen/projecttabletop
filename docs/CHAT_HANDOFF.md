# Chat Handoff - SeOkey 11 Project Snapshot

Last updated: 2026-02-09
Branch: master
Base commit seen: 90f0108

## 1) What was completed

### Rules and engine alignment (core)
- Canonical dossier-based rules are documented in `docs/SEOKEY11_CANONICAL.md`.
- Rule config schema is documented in `docs/RULECONFIG.md`.
- Core gameplay files were heavily updated for SeOkey 11 flow:
  - `core/state/GameSetup.gd`
  - `core/state/GameState.gd`
  - `core/actions/Validator.gd`
  - `core/actions/Reducer.gd`
  - `core/rules/MeldValidator.gd`
  - `core/rules/Scoring.gd`
  - `core/controller/LocalGameController.gd`
  - `core/bots/BotHeuristic.gd`
  - `core/bots/BotRandom.gd`

### Tests
- Test runner includes broad coverage for setup, discard-take, scoring, bots, UI contract, and turn progression.
- Current headless run exits OK:
  - `./tools/godot.cmd --headless --path . -s res://tests/run_tests.gd`
- Current parse smoke exits OK:
  - `./tools/godot.cmd --headless --path . --quit`

### Tooling
- Godot launcher wrappers exist:
  - `tools/godot.cmd`
  - `tools/godot.ps1`

## 2) UI state now (important)

Main files:
- `ui/GameTable.tscn`
- `ui/GameTable.gd`
- `ui/widgets/OkeyTile.gd`

There are backup artifacts from earlier iterations:
- `ui/GameTable.gd.bak_geometry_working`
- `ui/GameTable.tscn.bak_geometry_working`
- `ui/backup/` (if present)

Current UI is functional at baseline drag/drop level, but still not at the intended final visual target.

### Current `GameTable` architecture highlights
- Perspective constants are active:
  - `PERSPECTIVE_FAR_WIDTH_RATIO = 0.76`
  - `PERSPECTIVE_NEAR_WIDTH_RATIO = 0.95`
  - `PERSPECTIVE_TOP_Y_RATIO = 0.11`
  - `PERSPECTIVE_BOTTOM_Y_RATIO = 0.90`
- Table backdrop/polygon shaping exists.
- Corner discard slots exist and are interactive.
- Rack uses fixed slot rows (no auto-sort expected by user).
- Staging pipeline still exists in code (stage rows + stage slot logic), even after attempts to move toward direct-to-felt interaction.

## 3) Known unresolved issues from recent session

1. Visual target mismatch:
- Current board still does not match the requested "35-degree seated POV" aesthetic.
- Proportions and composition are still perceived as off.

2. Interaction model still mixed:
- User requested "no staging panels / direct to table feel" at points.
- Code still contains staging-first logic in several paths (`_stage_slots`, `_build_melds_from_stage_slots`, etc.).

3. Layout drift during iterations:
- Multiple geometry passes happened quickly; some runs appeared to regress.
- There is risk of reintroducing overlap / off-anchor behavior if edits continue without a strict geometry lock.

4. Gameplay/UI coupling risk:
- `GameTable.gd` currently contains both geometry and many gameplay interaction branches.
- This increases chance of regressions when changing presentation.

## 4) Modified/untracked files at snapshot

Modified:
- `CLAUDE.md`
- `core/actions/Reducer.gd`
- `core/actions/Validator.gd`
- `core/bots/BotHeuristic.gd`
- `core/bots/BotRandom.gd`
- `core/controller/LocalGameController.gd`
- `core/model/Meld.gd`
- `core/state/GameSetup.gd`
- `core/state/GameState.gd`
- `docs/README_DEV.md`
- `tests/run_tests.gd`
- `tests/test_deck_exhausted.gd`
- `ui/GameTable.gd`
- `ui/GameTable.tscn`
- `ui/widgets/OkeyTile.gd`

Untracked:
- `tests/test_bot_finish_and_random_draw.gd`
- `tests/test_bot_finish_and_random_draw.gd.uid`
- `tests/test_discard_stacks_state.gd`
- `tests/test_discard_stacks_state.gd.uid`
- `tests/test_fake_okey_pairs.gd`
- `tests/test_fake_okey_pairs.gd.uid`
- `tests/test_open_add_discard_flow.gd`
- `tests/test_open_add_discard_flow.gd.uid`
- `tests/test_reducer_clone_melds.gd`
- `tests/test_reducer_clone_melds.gd.uid`
- `tests/test_turn_progression_invariants.gd`
- `tests/test_turn_progression_invariants.gd.uid`
- `tools/godot.cmd`
- `tools/godot.ps1`
- `ui/GameTable.gd.bak_geometry_working`
- `ui/GameTable.tscn.bak_geometry_working`
- `ui/backup/` (if any files inside)

## 5) Recommended restart strategy for next chat

Use this exact order to avoid further UI loops:

1. Lock gameplay behavior first (no UI changes)
- Freeze and verify:
  - turn progression,
  - discard-take constraints,
  - opening thresholds,
  - scoring.
- Keep tests green before any geometry changes.

2. Lock a geometry contract before coding
- Define fixed screen-space anchors for:
  - table trapezoid,
  - rack,
  - corner discard slots,
  - center draw/indicator,
  - player nameplates.
- Do not change gameplay code in this step.

3. Remove mixed interaction paths
- Choose one interaction model and delete dead branches.
- If staging is removed, remove all stage-slot paths fully (not partially).
- If staging remains, make it explicit and minimal.

4. Reintroduce meld rendering in owner zones only
- Separate per-player opened meld rows from neutral felt center.
- Keep all placement rules deterministic and grid-snapped.

5. Then do visual polish
- Texture, shadows, fake depth, rack material, tile style.

## 6) Commands for the next chat

- Parse check:
  - `./tools/godot.cmd --headless --path . --quit`
- Full tests:
  - `./tools/godot.cmd --headless --path . -s res://tests/run_tests.gd`
- Search UI hotspots:
  - `rg -n "stage|meld|discard|PERSPECTIVE|_layout_table" ui/GameTable.gd`

## 7) Explicit context to carry into new chat

- Project intent is SeOkey 11 rules first, then visual quality.
- The canonical source for rules is `docs/SEOKEY11_CANONICAL.md`.
- Current blocker is not parser errors; it is UX/geometry correctness and interaction clarity.
- Preserve the currently working baseline before any major UI refactor (use the `.bak` files or branch).
