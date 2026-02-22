# Quick Start — Okey 101 (Godot 4.x)

## 1) Read this first
- **RULES.md** is the authoritative ruleset.
- **API.md** defines the action/validation surface.
- **ARCHITECTURE.md** shows how to organize the engine and keep it deterministic.

## 2) Minimal playable milestone (offline)
Aim for this smallest loop:

1. Deal (21/22), choose indicator, compute joker
2. Starter discards (no draw)
3. Each turn:
   - draw from stock OR take discard
   - optionally open / place tiles / add tiles
   - discard
4. Finish by discarding last tile
5. Score deal with penalties
6. Repeat

## 3) Engine checklist (must-haves)
- Tile identity supports duplicates + false jokers
- Joker status derived from indicator every deal
- Strict discard pickup:
  - if taken, must be used in table melds that remain
- Opening:
  - points ≥ 101 OR 5 doubles (configurable)
- Scoring:
  - -101 / -202 / -404 winner cases
  - multipliers for losers (1/2/4 and 2/4/8)
  - unopened = 202 or 404 depending on winner case
  - elden = (winner -202 or -404; others 404 or 808)
- +101 penalties (configurable)

## 4) Suggested first unit tests
- Meld validation:
  - set with duplicate colors invalid
  - run with 13→1 invalid
  - jokers fill gaps correctly
- Opening:
  - exactly 101 passes, 100 fails
  - doubles count = 5 passes, 4 fails
- Discard pickup:
  - take discard and not use it must fail discard/end turn
- Scoring golden tests:
  - normal win
  - win with joker discard
  - win opened doubles
  - doubles + joker
  - elden
  - elden + joker
  - unopened scoring

## 5) Optional: configurable variants
If you want “Katlamalı 101” or different penalty behaviors, add RuleConfig flags rather than branching logic in UI.
