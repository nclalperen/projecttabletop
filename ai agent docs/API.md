# Okey 101 — Technical API Specification (Action System)

All state changes occur through:
`validate_action(action, state) -> ValidationResult`
then
`apply_action(action, state) -> void`

This spec is written for a host-authoritative multiplayer model.

---

## 1) Action envelope

```json
{
  "type": "ACTION_NAME",
  "player_id": 0,
  "payload": { }
}
```

---

## 2) Turn-phase model (recommended)

State fields:
- `state.turn_phase ∈ {DRAW, PLAY, DISCARD}`
- `player.has_drawn_this_turn: bool`
- `player.must_use_discard_tile: TileId?`

---

## 3) Action Types

### 3.1 DRAW_FROM_STOCK
Draw the top tile from stock.

Payload: `{}`

Validation:
- `state.current_player == player_id`
- `state.turn_phase == DRAW`
- (Not starter’s first turn) OR starter already discarded once
- `state.stock not empty`
- player hand size is expected (typically 21; starter may be 22 only at deal start)

Effect:
- pop stock top → add to player hand
- `player.has_drawn_this_turn = true`
- `state.turn_phase = PLAY`

---

### 3.2 TAKE_DISCARD
Take the top tile from discard pile (strict rule: must use immediately).

Payload: `{}`

Validation:
- `state.current_player == player_id`
- `state.turn_phase == DRAW`
- `discard_pile not empty`

Effect:
- pop discard top → add to player hand
- `player.has_drawn_this_turn = true`
- `player.must_use_discard_tile = taken_tile_id`
- `state.turn_phase = PLAY`

---

### 3.3 PLACE_TILES (general “play melds” action)
Places tiles from hand onto the table, either by creating melds or extending existing melds.

Payload:
```json
{
  "placements": [
    {
      "op": "CREATE_MELD",
      "meld_type": "SET|RUN",
      "tiles": ["tile_id_1", "tile_id_2", "..."]
    },
    {
      "op": "ADD_TO_MELD",
      "meld_ref": {"owner": 1, "index": 0},
      "tiles": ["tile_id_x", "..."],
      "position": "AUTO|START|END"
    }
  ],
  "declare_open": false,
  "open_mode": "SETS_RUNS|DOUBLES"
}
```

Validation (core):
- `state.current_player == player_id`
- `state.turn_phase == PLAY`
- all referenced tiles exist in player hand
- resulting table melds are all valid
- if `declare_open`:
  - player has not opened yet
  - if `open_mode == SETS_RUNS`: placed sets/runs total ≥ 101 points
  - if `open_mode == DOUBLES`: placed pairs count ≥ configured minimum
- if `player.must_use_discard_tile != null`:
  - that tile must appear in the placed tiles and end up on the table after placements

Effect:
- move tiles from hand to table meld structures
- if opening succeeded, mark `player.has_opened = true`, set `open_mode`
- leaving the table in its new state

Notes:
- UI can allow drag/drop freely; only the submitted action must validate.

---

### 3.4 REARRANGE_TABLE (optional, if you want explicit rearrange)
Instead of complex incremental actions, you can allow a “submit final table state” action.

Payload:
```json
{
  "table_melds": [
    {"type":"RUN","tiles":["..."]},
    {"type":"SET","tiles":["..."]}
  ]
}
```

Validation:
- only allowed if player has opened
- all melds valid
- multiset of tiles on table unchanged (no tile duplication/loss)

Effect:
- replace table melds with the submitted canonical representation

---

### 3.5 DISCARD
Discard a tile to end the turn (and possibly finish the deal).

Payload:
```json
{ "tile_id": "..." }
```

Validation:
- `state.current_player == player_id`
- `state.turn_phase == DISCARD` OR `state.turn_phase == PLAY` with implicit end
- player has drawn this turn (except starter’s first turn)
- tile exists in player hand
- if `player.must_use_discard_tile != null`: invalid (player hasn’t used taken discard)
- finishing rule: if player wants to finish, they must have exactly 1 tile left **before** discard

Effect:
- remove tile from hand → push onto discard pile
- apply any immediate penalties (e.g., discarding joker, discarding playable tile) if enabled and not a finishing discard
- if player hand becomes 0: trigger DEAL_END
- else: advance `current_player` and reset turn flags, `turn_phase = DRAW`

---

### 3.6 DECLARE_FINISH (optional convenience)
Some implementations combine finish with discard. If you want explicitness:

Payload:
```json
{
  "discard_tile_id": "...",
  "finish": true
}
```

This can simplify end-of-deal scoring triggers.

---

## 4) Deal End & Scoring

When a deal ends:
- Winner is the player who discarded their last tile
- Derive finish flags:
  - `winner_opened_with_doubles`
  - `winner_finishing_discard_is_joker`
  - `winner_finished_in_one_turn_before_anyone_opened`
- Compute per-player deal scores using RULES.md scoring algorithm
- Add accumulated +101 penalties

---

## 5) Determinism requirements

- Stock order is deterministic from RNG seed
- Indicator selection is deterministic from the shuffled stock
- Server/host is the authority on:
  - meld validation with jokers
  - “discarded playable tile” detection (işlek check)
  - penalty application
  - scoring

Clients may predict but must accept host corrections.
