# Turkish Rummy 101 (Okey) - Architecture Document

## Project Overview
**Platform:** Godot 4.x  
**Target:** PC (Windows/Linux) + Android  
**Timeline:** 8-9 weeks  
**Network:** Epic Online Services (EOS) P2P + Local offline

---

## Core Architecture Principles

### 1. Pure State Management
- **Single Source of Truth**: `GameState` object contains all game data
- **Immutable Actions**: All changes go through `validate_action()` → `apply_action()`
- **No Scene Logic**: Game scenes only render state, never modify it

### 2. Host-Authoritative Multiplayer
- **Offline**: Local game controller acts as host
- **Online**: Lobby creator is authoritative host
- **Validation**: Host validates all actions before applying
- **Sync**: Clients send intents, receive state updates

---

## Directory Structure

```
turkish_rummy_101/
├── project.godot
├── assets/
│   ├── tiles/           # Tile sprites (PNG)
│   ├── ui/              # UI elements
│   ├── sounds/          # SFX and music
│   └── fonts/           # Fonts
├── scenes/
│   ├── main_menu.tscn
│   ├── game_table.tscn
│   ├── lobby.tscn
│   └── settings.tscn
├── scripts/
│   ├── core/
│   │   ├── game_state.gd       # Main state container
│   │   ├── rule_config.gd      # Rule configuration
│   │   ├── actions.gd          # Action definitions
│   │   └── validator.gd        # Action validation
│   ├── game_logic/
│   │   ├── tile.gd
│   │   ├── hand.gd
│   │   ├── meld.gd
│   │   ├── scoring.gd
│   │   └── turn_manager.gd
│   ├── bots/
│   │   ├── bot_base.gd
│   │   ├── bot_easy.gd
│   │   ├── bot_medium.gd
│   │   ├── bot_hard.gd
│   │   └── personality.gd
│   ├── network/
│   │   ├── eos_manager.gd      # EOS integration
│   │   ├── lobby_manager.gd
│   │   ├── host_controller.gd
│   │   └── client_controller.gd
│   ├── ui/
│   │   ├── table_view.gd
│   │   ├── hand_display.gd
│   │   ├── meld_display.gd
│   │   └── animation_controller.gd
│   └── controllers/
│       ├── game_controller.gd  # Offline controller
│       └── input_handler.gd
├── data/
│   └── rules/
│       ├── classic_tr_101.json
│       └── preset_configs.json
└── docs/
    ├── ARCHITECTURE.md (this file)
    ├── RULES.md
    └── API.md
```

---

## Core Data Structures

### GameState
```gdscript
class_name GameState

var rule_config: RuleConfig
var players: Array[PlayerState]  # 4 players
var deck: Array[Tile]
var discard_pile: Array[Tile]
var current_player_index: int
var round_number: int
var match_score: Array[int]  # Per player
var phase: String  # "dealing", "playing", "finished"
var turn_start_time: float
var move_history: Array[MoveRecord]
```

### RuleConfig
```gdscript
class_name RuleConfig

# Preset
var preset_id: String  # "classic_tr_101"

# Opening rules
var opening_points_threshold: int = 51
var allow_double_open: bool = false

# Dealing rules
var tiles_per_player: int = 14
var initial_discard_rule: String = "must_pick_from_pile"

# Scoring
var base_win_score: int = 2
var double_score_multiplier: int = 2
var joker_penalty: int = -1

# Timer
var turn_time_seconds: int = 45  # 0 = off

# Match format
var match_type: String = "rounds"  # "rounds" or "score"
var target_value: int = 7  # 7 rounds or 100 points
```

### Action
```gdscript
class_name Action

enum Type {
    DRAW_FROM_DECK,
    DRAW_FROM_DISCARD,
    DISCARD,
    OPEN_HAND,
    ADD_TO_MELD,
    REARRANGE_MELD,
    FINISH,
    TIMEOUT
}

var type: Type
var player_id: int
var payload: Dictionary  # Type-specific data
```

### PlayerState
```gdscript
class_name PlayerState

var id: int
var name: String
var is_bot: bool
var bot_difficulty: String  # "easy", "medium", "hard"
var bot_personality: String  # "aggressive", "conservative", "chaotic"
var hand: Array[Tile]
var melds: Array[Meld]  # Opened melds
var has_opened: bool
var is_connected: bool  # For online
var total_score: int
```

---

## Action Flow

### Offline Mode
```
User Input → InputHandler → validate_action() → apply_action() → GameState
                                    ↓                    ↓
                                 UI Feedback      Update Views
```

### Online Mode (Host)
```
Client Intent → Network → Host validate_action() → apply_action() → GameState
                                                          ↓
                                            Broadcast state delta to all clients
```

### Online Mode (Client)
```
User Input → Send to Host → Wait for state update → Render new state
```

---

## Key Systems

### 1. Validation System (`validator.gd`)
```gdscript
static func validate_action(state: GameState, action: Action) -> ValidationResult:
    match action.type:
        Action.Type.DRAW_FROM_DECK:
            return validate_draw_from_deck(state, action)
        Action.Type.OPEN_HAND:
            return validate_opening(state, action)
        # ... etc
    
    return ValidationResult.new(false, "Unknown action")

class ValidationResult:
    var valid: bool
    var reason: String  # If invalid
```

### 2. Meld Validation
```gdscript
# A valid meld is either:
# 1. SET: 3+ tiles same number, different colors
# 2. RUN: 3+ consecutive tiles, same color

static func is_valid_meld(tiles: Array[Tile]) -> bool:
    if tiles.size() < 3:
        return false
    
    # Check if it's a valid set
    if is_valid_set(tiles):
        return true
    
    # Check if it's a valid run
    if is_valid_run(tiles):
        return true
    
    return false
```

### 3. Bot Decision System
```gdscript
class BotBase:
    var difficulty: String
    var personality: String
    
    func choose_action(state: GameState, player_id: int) -> Action:
        # 1. Get all valid actions
        var valid_actions = get_valid_actions(state, player_id)
        
        # 2. Evaluate each action (difficulty-dependent)
        var scored_actions = evaluate_actions(valid_actions, state)
        
        # 3. Apply personality weighting
        scored_actions = apply_personality(scored_actions)
        
        # 4. Add randomness (difficulty-dependent)
        return select_with_randomness(scored_actions)
```

**Difficulty Levels:**
- **Easy**: Random valid moves, 80% randomness
- **Medium**: Heuristic evaluation, 40% randomness, lookahead=1
- **Hard**: Advanced heuristics, 15% randomness, lookahead=2

**Personalities:**
- **Aggressive**: +weight to opening early, risky discards
- **Conservative**: +weight to flexibility, safe discards
- **Chaotic**: Extra randomness, unexpected plays

### 4. Network Protocol (EOS)

**Lobby Flow:**
```
1. Host: Create lobby via EOS (room code generated)
2. Clients: Join via room code
3. Host: Lock lobby when 4 players
4. Host: Send initial state snapshot + RuleConfig hash
5. Game starts
```

**During Game:**
```
Client → Host:  { "action": Action, "player_id": int }
Host → All:     { "state_delta": {...}, "move_number": int }
```

**State Delta Structure:**
```gdscript
{
    "move_number": 42,
    "current_player": 2,
    "last_action": { ... },
    "affected_hands": {
        "2": [Tile, Tile, ...],  # Only changed hands
    },
    "discard_pile_top": Tile,
    "deck_size": 67
}
```

**Reconnect Flow:**
```
1. Client disconnects → Host marks player as disconnected
2. Bot takes over immediately
3. Client reconnects → sends reconnect request
4. Host sends full state snapshot
5. On client's next turn: client can reclaim seat
6. Show move log of bot's actions while away
```

---

## UI Architecture

### Scene Hierarchy
```
GameTable
├── TableBackground
├── PlayerPositions (4)
│   ├── PlayerHand
│   ├── PlayerMelds
│   └── PlayerNameplate
├── CenterArea
│   ├── DeckPile
│   ├── DiscardPile
│   └── Indicator (joker tile)
├── ActionPanel
│   ├── DrawButton
│   ├── DiscardButton
│   ├── OpenButton
│   └── FinishButton
└── UIOverlay
    ├── TurnTimer
    ├── ScoreDisplay
    └── MenuButton
```

### Input System
```
Touch/Click → InputHandler.handle_input()
    ↓
Determine intent:
    - Tile selected?
    - Action button pressed?
    - Drag detected?
    ↓
Emit signal → GameController
    ↓
Create Action → Validate → Execute
```

### Animation System
```gdscript
class AnimationController:
    func animate_draw(tile: Tile, target_hand: Node):
        # Tween from deck to hand (0.3s)
    
    func animate_discard(tile: Tile, from: Node):
        # Tween to discard pile (0.3s)
    
    func animate_meld_open(meld: Meld, player: int):
        # Fan out meld tiles (0.5s)
    
    # All animations can be skipped with tap/setting
```

---

## Testing Strategy

### Unit Tests
```
tests/
├── test_tile.gd
├── test_meld_validation.gd
├── test_scoring.gd
├── test_validator.gd
└── test_bots.gd
```

### Integration Tests
```
tests/integration/
├── test_full_game.gd
├── test_network_sync.gd
└── test_reconnect.gd
```

### Manual Test Scenarios
1. Complete offline game vs 3 hard bots
2. 4-player online game with 1 disconnect/reconnect
3. All rule variations
4. Android portrait/landscape handling
5. Timer expiry handling

---

## Build Configuration

### Godot Export Presets

**PC (Windows/Linux)**
```
- Architecture: x86_64
- Embed PCK: true
- Include: All scenes, scripts, assets
```

**Android**
```
- Min SDK: 21 (Android 5.0)
- Target SDK: 33
- Permissions: INTERNET, ACCESS_NETWORK_STATE
- Orientation: Landscape (sensor landscape)
- Screen: Keep screen on during game
```

---

## Performance Targets

- **Load time**: < 3 seconds
- **Frame rate**: 60 FPS (Android: 30 FPS acceptable)
- **Memory**: < 200MB on Android
- **Network latency tolerance**: < 500ms (show lag indicator if higher)

---

## Accessibility Features

1. **Colorblind Mode**: Alternative tile designs with symbols
2. **Large Text Option**: 150% font scaling
3. **Sound Toggle**: Separate music/SFX controls
4. **Animation Speed**: Fast/Normal/Slow options

---

## Asset Requirements

### Tiles
- 104 unique tiles (2 sets of 1-13 in 4 colors + 2 jokers)
- Size: 128x180px per tile
- Format: PNG with alpha
- Style: Flat, high-contrast, clean numbers

### UI
- Buttons: 5 states (normal, hover, pressed, disabled, selected)
- Background: Table texture (seamless)
- Icons: Settings, sound, help, etc.

### Audio
- SFX: draw, discard, open, win, timer warning (< 100KB each)
- Music: Ambient loop (< 1MB, optional)

---

## Risk Mitigation

### Technical Risks
1. **EOS Integration Complexity**
   - Mitigation: Start early (Phase 7), have LAN fallback
   
2. **Android Performance**
   - Mitigation: Profile early, optimize texture atlas
   
3. **Network Desync**
   - Mitigation: Host-authoritative + periodic full state sync

### Scope Risks
1. **Bot AI Too Complex**
   - Mitigation: Ship Easy/Medium first, Hard as update
   
2. **UI Polish Time Sink**
   - Mitigation: Functional UI first, polish in Phase 8

---

## Versioning Strategy

### v1.0 (MVP)
- Offline vs bots
- Online P2P (EOS)
- Classic TR 101 rules only
- Basic UI

### v1.1 (Post-launch)
- Additional rule presets
- Improved bot AI
- UI themes
- Statistics tracking

### v1.2 (Future)
- Ranked matchmaking
- Leaderboards
- Daily challenges

---

## Next Steps for Codex

1. **Set up project structure** (Task 1.1)
2. **Create `RuleConfig` class** (Task 1.2)
3. **Implement `GameState`** (Task 1.3)
4. **Build `Action` system** (Task 1.4)

Each task has detailed prompts in the Excel tracker.
