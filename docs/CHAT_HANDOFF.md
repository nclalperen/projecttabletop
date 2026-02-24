# Chat Handoff - SeOkey 11 Project Snapshot

Last updated: 2026-02-24
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
- Draft Grid is canonical for temporary felt placement; stage-named interaction APIs were removed from runtime classes.
- 2D and 3D drop intent resolution is unified through `InteractionResolver`.

## 3) Known unresolved issues from recent session

1. Visual target mismatch:
- Current board still does not match the requested "35-degree seated POV" aesthetic.
- Proportions and composition are still perceived as off.

2. Interaction model migration:
- Draft-only naming is active in interaction APIs (`get_draft_slots`, `overlay_move_*_draft`).
- Stage-named runtime wrappers were hard-cut.

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

3. Keep a single interaction contract
- Preserve resolver precedence and draft-lane targeting rules.
- Avoid reintroducing implicit fallback placement paths.
- Keep runtime interaction surface draft-only; do not reintroduce stage aliases.

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
- Interaction probes:
  - `./tools/godot.cmd --headless --path . -s res://tests/probe_gametable3d_interaction_matrix.gd`
  - `./tools/godot.cmd --headless --path . -s res://tests/probe_gametable2d_interaction_matrix.gd`
- Strict matrix gate:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File ./tools/run_tests_matrix.ps1`
  - Runtime lane status can be `PASS`, `FAIL`, or `BLOCKED_ENV_MISSING` (exit `2`).
- Probe note:
  - 3D probe may print renderer RID/resource warnings on shutdown in headless Forward+ mode; rely on scenario summary and process exit code.
- Search UI hotspots:
  - `rg -n "draft|stage|meld|discard|PERSPECTIVE|_layout_table" ui/GameTable.gd`

## 7) Explicit context to carry into new chat

- Project intent is SeOkey 11 rules first, then visual quality.
- The canonical source for rules is `docs/SEOKEY11_CANONICAL.md`.
- Current blocker is not parser errors; it is UX/geometry correctness and interaction clarity.
- Preserve the currently working baseline before any major UI refactor (use the `.bak` files or branch).
