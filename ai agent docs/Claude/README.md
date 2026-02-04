# Turkish Rummy 101 (Okey) - Development Plan

## Quick Start for Codex Integration

This package contains everything needed to build a complete Turkish Rummy 101 game using OpenAI Codex in VS Code.

### Package Contents

1. **turkish_rummy_project_plan.xlsx** - Master task tracker with:
   - Task Master List (45 tasks with dependencies)
   - Gantt Chart View
   - Phase Summary
   - Codex Prompt Templates
   - Daily Progress Tracker

2. **ARCHITECTURE.md** - Complete technical architecture
   - System design
   - Directory structure
   - Data structures
   - Bot AI design
   - Network protocol

3. **RULES.md** - Complete game rules specification
   - Turkish Rummy 101 rules
   - Win conditions
   - Scoring system
   - House rules options

4. **API.md** - Technical API documentation
   - Action system
   - Network protocol
   - EOS integration
   - State management

5. **gantt_chart.png** - Visual project timeline

### How to Use This with Codex

#### Step 1: Set Up Project
```bash
# Create project directory
mkdir turkish_rummy_101
cd turkish_rummy_101

# Initialize Godot 4.x project
# Open Godot → New Project → Select folder
```

#### Step 2: Task-by-Task Development

Open `turkish_rummy_project_plan.xlsx` → "Task Master List" sheet

For each task (in order):

1. **Read the task details:**
   - Task ID, Name, Dependencies
   - Check if dependencies are complete

2. **Go to "Codex Prompts" sheet:**
   - Find corresponding task ID
   - Copy the prompt template

3. **Customize prompt for Codex:**
   - Add specific requirements from ARCHITECTURE.md
   - Reference API.md for data structures
   - Include RULES.md sections if needed

4. **Feed to Codex in VS Code:**
   ```
   Example for Task 1.2:
   
   "Create a RuleConfig class in GDScript following the specification 
   in API.md. This should be a resource that can be serialized to JSON.
   
   Requirements:
   - Follow schema in API.md section 'RuleConfig Schema'
   - Include validation methods
   - Support hash calculation for online sync
   - Include 'classic_tr_101' preset
   
   File: scripts/core/rule_config.gd"
   ```

5. **Update tracker:**
   - Mark status as "In Progress" → "Completed"
   - Update Completion % to 100%
   - Add any notes or issues

#### Step 3: Track Progress

Use "Daily Progress" sheet to log:
- Date
- Tasks completed
- Tasks in progress
- Any blockers
- Notes

### Task Order (Critical Path)

**Week 1-2: Foundation**
- Tasks 1.1 → 1.4 (must complete in order)
- Set up project structure
- Create core state system

**Week 3-4: Game Logic**
- Tasks 2.1 → 2.6
- Build game mechanics
- Implement validation

**Week 5-6: Bot AI & UI**
- Tasks 3.1 → 3.5 (bots)
- Tasks 4.1 → 4.5 (UI foundation)
- Tasks 5.1 → 5.6 (interactions)

**Week 7-8: Multiplayer**
- Tasks 6.1 → 6.4 (offline mode)
- Tasks 7.1 → 7.6 (online EOS)

**Week 9: Polish**
- Tasks 8.1 → 8.5
- Tasks 9.1 → 9.4

### Codex Best Practices

1. **One task at a time** - Don't skip ahead
2. **Test after each task** - Run in Godot to verify
3. **Follow architecture** - Reference ARCHITECTURE.md for patterns
4. **Modular code** - Keep functions small and testable
5. **Use type hints** - GDScript 2.0 static typing
6. **Comment complex logic** - Especially meld validation, bot AI

### Key Files to Reference

- **During Phase 1-2:** API.md (data structures)
- **During Phase 3:** RULES.md + API.md (bot logic)
- **During Phase 4-5:** ARCHITECTURE.md (UI patterns)
- **During Phase 7:** API.md (network protocol), EOS docs

### Testing Checklist

After each phase, verify:

- [ ] Phase 1: Can create GameState, validate actions
- [ ] Phase 2: Full offline game works with dummy bots
- [ ] Phase 3: Bots can play complete game
- [ ] Phase 4-5: UI displays game state correctly
- [ ] Phase 6: Offline mode playable end-to-end
- [ ] Phase 7: 4 players can connect and play online
- [ ] Phase 8: Polished, no crashes, smooth animations
- [ ] Phase 9: Builds run on PC and Android

### EOS Setup (Phase 7)

When reaching Task 7.1:

1. Create Epic Games account (developer.epicgames.com)
2. Create organization + product
3. Get Product ID, Sandbox ID, Deployment ID
4. Download EOS Godot plugin (EOSG)
5. Configure in Godot project settings

See API.md "EOS Integration Points" for code examples.

### Troubleshooting

**Codex gives incomplete code?**
- Be more specific in prompt
- Reference exact section in docs
- Break task into smaller sub-tasks

**Dependencies not clear?**
- Check "Dependencies" column in Excel
- Ensure all prior tasks marked "Completed"

**Stuck on a task?**
- Mark as "Blocked" in tracker
- Document issue in "Issues" column
- Skip to independent task if possible

### Success Metrics

By end of each phase:

- **Phase 1:** All unit tests pass
- **Phase 2:** Can simulate full game in console
- **Phase 3:** Hard bot beats you sometimes
- **Phase 4:** Game looks playable
- **Phase 5:** Smooth 60 FPS with animations
- **Phase 6:** Friend can play vs bots
- **Phase 7:** 4-player online game works
- **Phase 8:** Production-ready quality
- **Phase 9:** APK installs and runs

### Timeline

- **Start:** February 9, 2026
- **Phase 1 Done:** ~Feb 16
- **Phase 2-3 Done:** ~Mar 2
- **Phase 4-6 Done:** ~Mar 23
- **Phase 7 Done:** ~Apr 2
- **Final:** April 17, 2026

**Total:** 67 days / 9.6 weeks

### Support Resources

- Godot Docs: docs.godotengine.org
- EOS Plugin: github.com/3ddelano/epic-online-services-godot
- GDScript Reference: docs.godotengine.org/en/stable/tutorials/scripting/gdscript

---

## Development Flow Example

### Example: Task 2.3 (Meld Validation)

1. **Read requirement:**
   - Task: "Meld Validation (sets, runs)"
   - Duration: 3 days
   - Dependencies: 2.1, 2.2 ✓

2. **Reference docs:**
   - RULES.md: "Valid Melds" section
   - API.md: `Meld` class structure

3. **Codex prompt:**
   ```
   Create meld validation system for Turkish Rummy 101.
   
   File: scripts/game_logic/meld.gd
   
   Requirements from RULES.md:
   - Set: 3-4 tiles, same number, different colors
   - Run: 3+ consecutive tiles, same color
   - Jokers can substitute any tile
   - No wraparound (13→1)
   
   Implement:
   - is_valid_meld(tiles: Array[Tile]) -> bool
   - is_valid_set(tiles: Array[Tile]) -> bool
   - is_valid_run(tiles: Array[Tile]) -> bool
   - calculate_points(meld: Meld) -> int
   
   Include unit tests for edge cases.
   ```

4. **Codex generates code**

5. **Test in Godot:**
   ```gdscript
   # Test script
   var test_set = [Tile.new(5, "red"), Tile.new(5, "blue"), Tile.new(5, "yellow")]
   assert(is_valid_set(test_set))
   
   var test_run = [Tile.new(7, "red"), Tile.new(8, "red"), Tile.new(9, "red")]
   assert(is_valid_run(test_run))
   ```

6. **Update tracker:**
   - Status: Completed ✓
   - Completion: 100%
   - Notes: "All edge cases tested"

7. **Move to next task:** 2.4

---

## Final Notes

- **Stay organized:** Update Excel after every task
- **Commit often:** Git commit after each completed task
- **Test frequently:** Don't wait until the end
- **Ask questions:** Document unclear requirements in tracker

Good luck! 🎮
