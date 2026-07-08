# Project Tabletop

**Okey 101 — the Turkish tile game — built in Godot 4.6 with a deterministic rules core, tiered bot AI, and Epic Online Services multiplayer.**

Project Tabletop implements the full Okey 101 ruleset (106 tiles, indicator/okey
wilds, fake okeys, 101-point opening, meld extension) on top of a
framework-agnostic game core, with local play against bots, online play over
EOS lobbies and P2P, and both 2D and 3D table views.

## Features

**Rules engine**
- Canonical Okey 101 rules, documented in
  [`docs/RULES_CANONICAL.md`](docs/RULES_CANONICAL.md) and kept as the single
  source of truth for the implementation
- Deterministic **action → validator → reducer** pipeline: every move is an
  immutable action that is validated against the current `GameState` and
  applied by a pure reducer — seeded RNG makes rounds fully reproducible
- Configurable rule variants via `RuleConfig`
  ([`docs/RULECONFIG.md`](docs/RULECONFIG.md))
- Meld validation, discard rules, and scoring as isolated, testable modules

**Bot AI**
- Four difficulty tiers behind a common interface: `BotRandom`, `BotEasy`,
  `BotHeuristic`, and `BotHard`

**Multiplayer**
- Epic Online Services integration: lobby service, P2P transport, and
  host/client match controllers speaking a shared protocol
- `StateCodec` + `SeatViewAdapter` serialize per-seat views of the game state,
  so clients only ever see the information their seat is entitled to
- Local and networked play share the same core through the
  `MatchControllerPort` interface

**Presentation & platforms**
- 2D and 3D game tables (Godot scenes with drag/drop tile interaction)
- Desktop and Android export pipeline, with an environment/readiness gate for
  Android builds
- CC0/public-domain-only art and audio, enforced by a license registry
  ([`docs/ASSET_LICENSES.md`](docs/ASSET_LICENSES.md)) that tests check at
  build time

## Getting started

1. Install [Godot 4.6](https://godotengine.org/) (standard build).
2. Open the project (`project.godot`) in the editor and run — the main scene
   is `ui/MainMenu.tscn`.
3. For online play, EOS credentials are required; see
   [`docs/EOS_RUNTIME_SETUP.md`](docs/EOS_RUNTIME_SETUP.md). Local play against
   bots works without any setup.

## Testing

The project ships 75+ headless test scripts covering action validation, meld
logic, scoring, bot behavior, state serialization, and asset-license
compliance, plus soak tests and drag/drop interaction probes:

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

The strict gate (`tools/run_tests_matrix.ps1`) runs the full matrix including
the EOS runtime lane, and deliberately fails as `BLOCKED_ENV_MISSING` rather
than reporting a false green when required environment is absent.

## Project layout

```
core/        framework-agnostic game logic
  actions/     Action, Validator, Reducer
  model/       Tile, Meld, DeckBuilder, OkeyContext
  rules/       MeldValidator, DiscardRules, Scoring, RuleConfig
  state/       GameState, PlayerState, GameSetup
  bots/        BotRandom / BotEasy / BotHeuristic / BotHard
  controller/  MatchControllerPort + LocalGameController
  network/     StateCodec, SeatViewAdapter
net/         EOS services: lobby, P2P transport, host/client controllers
ui/          menus, 2D/3D game tables, round-end screens
tests/       headless test runner, unit tests, soak tests, probes
docs/        canonical rules, rule config, EOS setup, asset licenses
addons/      epic-online-services-godot
```

## Documentation

- [`docs/RULES_CANONICAL.md`](docs/RULES_CANONICAL.md) — the Okey 101 rules as implemented
- [`docs/RULECONFIG.md`](docs/RULECONFIG.md) — rule variant configuration
- [`docs/EOS_RUNTIME_SETUP.md`](docs/EOS_RUNTIME_SETUP.md) — multiplayer credential setup
- [`docs/README_DEV.md`](docs/README_DEV.md) — developer workflow, test gates, Android builds
