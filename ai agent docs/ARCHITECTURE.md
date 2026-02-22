# Okey 101 (Yüzbir) — Architecture Document (Godot 4.x)

This architecture is optimized for a deterministic, host-authoritative rules engine that supports:
- Okey 101 dealing (21/22 tiles), opening (≥101 or doubles), strict discard pickup, and penalty scoring
- Offline + online (P2P host authoritative)
- Bots that operate only on public state + their hand

---

## 1) Core Principles (unchanged)

### Pure state management
- Single source of truth: `GameState`
- All mutations via `validate_action(action, state)` → `apply_action(action, state)`
- Scenes render state; they do not mutate game rules

### Host authoritative multiplayer
- Host validates all actions
- Clients send intents; host returns authoritative updates
- Deterministic RNG: seed stored in `GameState` for replay/debug

---

## 2) Directory Structure (same idea)

```
okey_101/
├── assets/
├── scenes/
├── scripts/
│   ├── core/        # state, actions, validator, rule_config
│   ├── game_logic/  # tiles, melds, scoring, turn_manager
│   ├── bots/
│   ├── network/
│   ├── ui/
│   └── controllers/
├── data/
│   └── rules/       # JSON presets
└── docs/
    ├── ARCHITECTURE.md
    ├── RULES.md
    └── API.md
```

---

## 3) Data Model

### 3.1 Tile
Key requirement: duplicates exist, so every tile has a unique id.

Suggested `Tile` fields:
- `id: String` (stable unique)
- `kind: int` (NORMAL / FALSE_JOKER)
- `color: int` (enum; null for false joker)
- `rank: int` (1..13; null for false joker)

Derived:
- `is_real_joker(tile, indicator)` if tile.color == indicator.color and tile.rank == indicator.rank+1 (wrap)
- `is_effective_joker(tile, indicator)` if real joker OR false joker (because false joker represents the real joker)

### 3.2 Meld
Store melds as explicit tiles with order:
- `type: SET | RUN`
- `tiles: Array[TileId]`
- `owner_id: int` (optional: for UI grouping; not required for rules)
- `locked: bool` (optional, for UI / tutorial; rules engine can ignore)

Validation uses `indicator` to treat jokers as wild.

### 3.3 PlayerState
- `hand: Array[TileId]`
- `has_opened: bool`
- `open_mode: NONE | SETS_RUNS | DOUBLES`
- `opened_value: int` (opening points total if using points)
- `doubles_pairs_count: int` (if opened by doubles)
- `deal_penalties: int` (accumulated +101 penalties this deal)
- `turn_flags`:
  - `has_drawn_this_turn: bool`
  - `must_use_discard_tile: TileId?` (set when taking from discard)

### 3.4 GameState
- `rule_config: RuleConfig`
- `players: Array[PlayerState]` (size 4)
- `stock: Array[TileId]`
- `discard_pile: Array[TileId]` (top at end)
- `indicator: TileId`
- `dealer_index: int`
- `current_player_index: int`
- `phase: DEALING | PLAYING | SCORING`
- `turn_phase: DRAW | PLAY | DISCARD` (explicit)
- `deal_number: int`
- `match_score: Array[int]` (cumulative)
- `history: Array[MoveRecord]` (optional)

---

## 4) RuleConfig (updated for Okey 101)

Example fields:

```json
{
  "preset_id": "tr_101_classic",
  "players": 4,

  "direction": "CCW",

  "hand_size": 21,
  "starter_extra_tile": 1,              // starter begins with 22
  "starter_is_right_of_dealer": true,

  "opening_points_threshold": 101,
  "allow_doubles_open": true,
  "doubles_pairs_to_open": 5,
  "doubles_open_locks_to_pairs_only": true,

  "discard_pickup_must_use_immediately": true,

  "penalty_value": 101,
  "penalty_unopened": 202,
  "joker_hand_value": 101,

  "penalties": {
    "discarding_joker": true,
    "discarding_playable_tile": true,
    "failed_open_attempt": true,
    "illegal_takeback": true
  },

  "cancel_deal_if_all_open_doubles": true,

  "end_on_stock_empty": "SCORE_NO_WINNER"   // SCORE_NO_WINNER | REDEAL | PLATFORM_DEFAULT
}
```

---

## 5) Turn Manager (101-specific)

### 5.1 First turn special-case
- Starter begins with 22 tiles and **does not draw**.
- They may play (open/add/rearrange) and must discard 1.

### 5.2 Discard-pickup constraint
If a player takes the top discard:
- set `must_use_discard_tile = taken_tile_id`
- any “place tiles” action must ensure the taken tile ends up on the table
- at end of turn, validator must assert `must_use_discard_tile == null`

---

## 6) Scoring module (pure function)

`score_deal(state, winner_id, finish_flags) -> DealResult`

Inputs:
- each player’s remaining hand
- each player’s open_mode
- finish flags: `elden`, `winner_opened_doubles`, `winner_finished_with_joker`
- penalties accumulated (+101 events)

Outputs:
- per-player deal delta score (signed)
- per-player penalty breakdown (optional UI)
- reason codes (for replay/debug)

---

## 7) Networking

- Sync only validated actions + deterministic seed
- Host sends authoritative state hash after each action
- Clients can predict locally but must reconcile

---

## 8) Testing strategy (high value for rules engine)

1) Unit-test meld validation (sets/runs) with jokers
2) Unit-test opening checks (≥101 and doubles)
3) Unit-test discard pickup constraint
4) Golden scoring tests:
   - normal finish
   - finish with joker
   - winner opened doubles
   - doubles + joker
   - elden finish
   - elden + joker
   - unopened player penalties
   - extra +101 penalties (joker discard, işlek discard)
