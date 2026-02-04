# Turkish Rummy 101 - Technical API Specification

## Action System

All game state changes occur through the Action system: `validate_action()` → `apply_action()`.

---

## Action Types & Payloads

### 1. DRAW_FROM_DECK
```gdscript
{
    "type": Action.Type.DRAW_FROM_DECK,
    "player_id": int,
    "payload": {}  # Empty - deck draw is deterministic
}
```

**Validation:**
- Is player's turn
- Player has not drawn this turn
- Deck is not empty
- Player hand has exactly 13 tiles (14 after draw)

**Effect:**
- Remove top tile from deck
- Add to player's hand
- Set `has_drawn_this_turn = true`

---

### 2. DRAW_FROM_DISCARD
```gdscript
{
    "type": Action.Type.DRAW_FROM_DISCARD,
    "player_id": int,
    "payload": {}  # Top of discard pile is implicit
}
```

**Validation:**
- Is player's turn
- Player has not drawn this turn
- Discard pile is not empty
- Not the tile player discarded last turn (prevent immediate take-back)
- (First round only) All players must draw from discard on first turn

**Effect:**
- Remove top tile from discard pile
- Add to player's hand
- Set `has_drawn_this_turn = true`
- Set `drew_from_discard = true` (for discard validation)

---

### 3. DISCARD
```gdscript
{
    "type": Action.Type.DISCARD,
    "player_id": int,
    "payload": {
        "tile_id": String  # Unique ID of tile to discard
    }
}
```

**Validation:**
- Is player's turn
- Player has drawn this turn
- Tile exists in player's hand
- If drew from discard this turn, cannot discard the same tile

**Effect:**
- Remove tile from player's hand
- Add tile to top of discard pile
- End turn (next player becomes current)
- Reset `has_drawn_this_turn = false`

---

### 4. OPEN_HAND
```gdscript
{
    "type": Action.Type.OPEN_HAND,
    "player_id": int,
    "payload": {
        "melds": Array[
            {
                "type": String,  # "set" or "run"
                "tiles": Array[String]  # Tile IDs
            }
        ]
    }
}
```

**Validation:**
- Is player's turn
- Player has drawn this turn
- Player has not opened yet
- All melds are valid (sets or runs)
- Total meld points ≥ 51 (or configured threshold)
- All tiles exist in player's hand

**Effect:**
- Mark player as `has_opened = true`
- Move specified tiles from hand to `melds` array
- Do NOT end turn (player still needs to discard)

---

### 5. ADD_TO_MELD
```gdscript
{
    "type": Action.Type.ADD_TO_MELD,
    "player_id": int,
    "payload": {
        "meld_owner": int,  # Player who owns the meld
        "meld_index": int,  # Which meld to add to
        "tiles": Array[String]  # Tile IDs to add
    }
}
```

**Validation:**
- Is player's turn
- Player has drawn this turn
- Player has opened
- Target meld exists
- Adding tiles maintains meld validity
- All tiles exist in player's hand

**Effect:**
- Move tiles from hand to specified meld
- Do NOT end turn

---

### 6. REARRANGE_MELD
```gdscript
{
    "type": Action.Type.REARRANGE_MELD,
    "player_id": int,
    "payload": {
        "new_configuration": Array[
            {
                "type": String,
                "tiles": Array[String]
            }
        ]
    }
}
```

**Validation:**
- Player has opened
- All new melds are valid
- Uses exact same tiles as before (no adding/removing)

**Effect:**
- Replace player's melds with new configuration

---

### 7. FINISH
```gdscript
{
    "type": Action.Type.FINISH,
    "player_id": int,
    "payload": {
        "final_melds": Array[  # Complete hand layout
            {
                "type": String,
                "tiles": Array[String]
            }
        ]
    }
}
```

**Validation:**
- Is player's turn
- Player has drawn this turn
- All 14 tiles form valid melds
- OR exactly 7 pairs (special win)

**Effect:**
- Mark player as winner
- End round
- Calculate scores
- Move to next round or end match

---

### 8. TIMEOUT
```gdscript
{
    "type": Action.Type.TIMEOUT,
    "player_id": int,
    "payload": {}
}
```

**Validation:**
- Turn timer expired
- Is player's turn

**Effect:**
- Auto-draw from deck (if not drawn)
- Auto-discard rightmost tile
- Increment timeout counter
- If timeout_count ≥ 3 (online only): forfeit round

---

## Validation Result

```gdscript
class ValidationResult:
    var valid: bool
    var reason: String  # Empty if valid, error message if invalid
    var error_code: String  # Machine-readable code
```

**Common Error Codes:**
- `NOT_YOUR_TURN`
- `MUST_DRAW_FIRST`
- `INVALID_MELD`
- `INSUFFICIENT_POINTS`
- `TILE_NOT_IN_HAND`
- `DECK_EMPTY`
- `ALREADY_OPENED`
- `MUST_DISCARD_DIFFERENT_TILE`

---

## Network Protocol (EOS)

### Message Types

#### 1. Client → Host: Action Request
```gdscript
{
    "msg_type": "action",
    "player_id": int,
    "action": Action,
    "sequence": int  # Client's message counter
}
```

#### 2. Host → All: State Update
```gdscript
{
    "msg_type": "state_update",
    "move_number": int,
    "delta": {
        "current_player": int,
        "last_action": Action,
        "affected_hands": {
            "player_id": Array[Tile]  # Only if hand changed
        },
        "discard_top": Tile,  # If changed
        "deck_size": int,
        "melds": {
            "player_id": Array[Meld]  # If changed
        },
        "phase": String,  # If changed
        "scores": Array[int]  # If round ended
    }
}
```

#### 3. Host → All: Full Snapshot (resync)
```gdscript
{
    "msg_type": "snapshot",
    "state": GameState,  # Complete state
    "move_number": int
}
```

#### 4. Client → Host: Reconnect Request
```gdscript
{
    "msg_type": "reconnect",
    "player_id": int,
    "last_known_move": int
}
```

#### 5. Host → Client: Reconnect Response
```gdscript
{
    "msg_type": "reconnect_response",
    "accepted": bool,
    "snapshot": GameState,
    "move_log": Array[MoveRecord],  # What bot did while away
    "can_reclaim_next_turn": bool
}
```

#### 6. Host → All: Player Disconnected
```gdscript
{
    "msg_type": "player_disconnected",
    "player_id": int,
    "bot_takeover": bool
}
```

#### 7. Host → All: Player Reconnected
```gdscript
{
    "msg_type": "player_reconnected",
    "player_id": int,
    "reclaimed_control": bool
}
```

---

## RuleConfig Schema (JSON)

### Classic TR 101 Preset
```json
{
  "preset_id": "classic_tr_101",
  "version": "1.0",
  
  "opening": {
    "points_threshold": 51,
    "allow_double_open": false,
    "double_threshold": 101
  },
  
  "dealing": {
    "tiles_per_player": 14,
    "first_round_draw_rule": "must_pick_discard"
  },
  
  "scoring": {
    "win_points": 2,
    "second_place_points": 1,
    "last_place_points": -1,
    "double_win_multiplier": 2,
    "joker_penalty": -1,
    "apply_joker_penalty": true
  },
  
  "timer": {
    "enabled": true,
    "turn_seconds": 45,
    "warning_seconds": 10,
    "timeout_limit": 3
  },
  
  "match": {
    "format": "rounds",
    "target_value": 7
  },
  
  "misc": {
    "allow_meld_rearrange": true,
    "seven_pairs_enabled": true,
    "dead_hand_rule": "fewest_tiles_wins"
  }
}
```

### Hash Calculation
```gdscript
func calculate_rule_hash(config: RuleConfig) -> String:
    var json_string = JSON.stringify(config.to_dict(), "\t")
    return json_string.sha256_text()
```

Used to ensure all clients are playing with identical rules.

---

## Game State Snapshot Format

```gdscript
{
    "version": "1.0",
    "rule_config_hash": String,
    "move_number": int,
    "round_number": int,
    "phase": String,  # "dealing", "playing", "round_end"
    
    "players": [
        {
            "id": int,
            "name": String,
            "is_bot": bool,
            "bot_config": {
                "difficulty": String,
                "personality": String
            },
            "hand": Array[Tile],  # Hidden for other players online
            "melds": Array[Meld],
            "has_opened": bool,
            "is_connected": bool,
            "round_score": int,
            "match_score": int,
            "timeout_count": int
        }
    ],
    
    "deck_size": int,  # Don't send tiles, just count
    "discard_pile": Array[Tile],  # Visible to all
    "indicator_tile": Tile,
    "okey_value": int,  # Calculated joker
    
    "current_player": int,
    "turn_start_time": float,
    "has_drawn_this_turn": bool,
    
    "match_scores": Array[int]
}
```

---

## Tile Data Structure

```gdscript
class Tile:
    var id: String  # Unique: "R5-1" (Red 5, copy 1)
    var number: int  # 1-13
    var color: String  # "red", "blue", "yellow", "black"
    var is_joker: bool  # True for star jokers
    var is_okey: bool  # Calculated based on indicator
    
    func to_dict() -> Dictionary:
        return {
            "id": id,
            "number": number,
            "color": color,
            "is_joker": is_joker
        }
```

---

## Meld Data Structure

```gdscript
class Meld:
    var type: String  # "set" or "run"
    var tiles: Array[Tile]
    var points: int  # Calculated
    
    func calculate_points() -> int:
        var total = 0
        for tile in tiles:
            if tile.is_joker or tile.is_okey:
                # Joker value depends on context
                total += infer_joker_value(tile)
            else:
                total += tile.number
        return total
```

---

## Move Record (for replay/history)

```gdscript
class MoveRecord:
    var move_number: int
    var player_id: int
    var action: Action
    var timestamp: float
    var result: String  # "success" or error
```

---

## Bot Action Selection API

```gdscript
# BotBase.choose_action()
func choose_action(state: GameState, player_id: int) -> Action:
    # 1. Get valid actions
    var actions = get_all_valid_actions(state, player_id)
    
    # 2. Score each action
    var scored = []
    for action in actions:
        var score = evaluate_action(action, state)
        scored.append({"action": action, "score": score})
    
    # 3. Apply personality
    scored = apply_personality_weights(scored)
    
    # 4. Select based on difficulty
    return select_action(scored)
```

**Evaluation Factors:**
- Hand completion progress (how close to winning)
- Flexibility (number of ways to meld remaining tiles)
- Risk (high tiles in hand = higher risk)
- Opponent tracking (what they might need)

---

## EOS Integration Points

### Initialization
```gdscript
# In eos_manager.gd
func initialize() -> bool:
    var init_result = EOS.Platform.PlatformInterface.initialize(platform_options)
    if init_result != EOS.Result.Success:
        return false
    
    # Create platform
    platform_handle = EOS.Platform.PlatformInterface.create(create_options)
    return platform_handle != null
```

### Create Lobby
```gdscript
func create_lobby(max_players: int, rule_config: RuleConfig) -> Dictionary:
    var create_options = {
        "max_players": max_players,
        "permission_level": EOS.Lobby.LobbyPermissionLevel.Publicadvertised,
        "local_user_id": account_id
    }
    
    # Add rule hash as lobby attribute
    var lobby_id = await EOS.Lobby.create_lobby(create_options)
    
    await EOS.Lobby.update_lobby_attribute(lobby_id, "rule_hash", rule_config_hash)
    
    return {"lobby_id": lobby_id, "join_code": generate_join_code()}
```

### Join Lobby
```gdscript
func join_lobby(join_code: String) -> bool:
    var lobby_id = resolve_join_code(join_code)
    var join_result = await EOS.Lobby.join_lobby(lobby_id, local_user_id)
    
    # Verify rule hash matches
    var attributes = await EOS.Lobby.get_lobby_attributes(lobby_id)
    if attributes["rule_hash"] != expected_hash:
        return false  # Mismatched rules
    
    return join_result.success
```

### Send Action (P2P)
```gdscript
func send_action_to_host(action: Action):
    var message = {
        "msg_type": "action",
        "player_id": local_player_id,
        "action": action.to_dict(),
        "sequence": sequence_number
    }
    
    EOS.P2P.send_packet(host_user_id, JSON.stringify(message).to_utf8_buffer())
    sequence_number += 1
```

### Broadcast State (Host)
```gdscript
func broadcast_state_update(delta: Dictionary):
    var message = {
        "msg_type": "state_update",
        "move_number": current_move_number,
        "delta": delta
    }
    
    var data = JSON.stringify(message).to_utf8_buffer()
    
    for peer_id in connected_peers:
        EOS.P2P.send_packet(peer_id, data)
```

---

## Testing Utilities

### Simulate Full Game
```gdscript
func simulate_game(rule_config: RuleConfig) -> GameResult:
    var state = GameState.new(rule_config)
    var bots = [BotEasy.new(), BotMedium.new(), BotHard.new(), BotMedium.new()]
    
    while state.phase != "match_end":
        var current_bot = bots[state.current_player]
        var action = current_bot.choose_action(state, state.current_player)
        
        var validation = validate_action(state, action)
        assert(validation.valid, "Bot produced invalid action")
        
        state = apply_action(state, action)
    
    return state.get_result()
```

---

## Performance Considerations

### State Update Frequency
- **Send delta updates** every action (< 1KB each)
- **Full snapshot** every 20 moves or on request (< 10KB)
- **Resync** if client detects desync (sequence mismatch)

### Latency Handling
- Show "waiting for host" if response > 500ms
- Local prediction for own actions (optimistic UI)
- Rollback if host rejects action

### Memory
- Keep only last 100 moves in history
- Compress historical snapshots
- Clear completed rounds after match end
