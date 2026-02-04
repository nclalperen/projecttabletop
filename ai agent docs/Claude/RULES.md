# Turkish Rummy 101 (Okey) - Rules Specification

## Game Overview
Turkish Rummy 101 (Okey) is a 4-player tile-based rummy game popular in Turkey. Players aim to form valid melds (sets and runs) from tiles drawn from a shared pool.

---

## Setup

### Components
- **106 tiles total:**
  - 2 sets of tiles numbered 1-13 in 4 colors (Red, Blue, Yellow, Black)
  - 2 Joker tiles (wild cards marked with star)
- **4 players** (seated North, East, South, West)

### Initial Deal
1. Shuffle all 106 tiles
2. Deal **14 tiles** to each player (random order)
3. Reveal one tile from remaining deck → This determines the **Okey (joker)**
   - Okey = (revealed tile number + 1) of same color
   - If revealed is 13, Okey = 1 of that color
   - Both copies of the Okey are wild cards
4. Place revealed tile face-up (indicator)
5. Remaining tiles form the **draw pile**
6. First discard: Player who received the 15th tile in dealing discards first

---

## Turn Structure

### Player Turn (45 seconds default)
1. **Draw Phase:**
   - EITHER draw top tile from deck
   - OR take top tile from discard pile
   
2. **Action Phase (optional):**
   - Open hand (if not yet opened)
   - Add tiles to existing melds
   - Rearrange melds
   
3. **Discard Phase:**
   - Must discard exactly 1 tile to discard pile
   - Cannot discard the tile just drawn from discard pile (same turn)

### Turn ends → Next player clockwise

---

## Valid Melds

### Set (Group)
- **3 or 4 tiles** of the **same number**, **different colors**
- Examples:
  - 5-Red, 5-Blue, 5-Yellow ✓
  - 9-Red, 9-Black, 9-Yellow, 9-Blue ✓
  - 3-Red, 3-Red, 3-Blue ✗ (duplicate color)

### Run (Sequence)
- **3+ consecutive tiles** of the **same color**
- Examples:
  - 4-Red, 5-Red, 6-Red ✓
  - 10-Blue, 11-Blue, 12-Blue, 13-Blue ✓
  - 1-Yellow, 2-Yellow, 3-Yellow ✓
  - 12-Red, 13-Red, 1-Red ✗ (no wraparound)

### Joker Rules
- **Okey tiles** can substitute for any tile
- **Star jokers** can substitute for any tile
- A meld can contain multiple jokers
- Examples:
  - 5-Red, Okey, 7-Red (run with joker as 6-Red) ✓
  - 8-Red, 8-Blue, Joker (set with joker as 8-Yellow/Black) ✓

---

## Opening Your Hand

### Opening Requirement
- Must have **minimum 51 points** worth of valid melds
- Points calculated from tile numbers:
  - Number tiles = face value (1=1pt, 7=7pt, 13=13pt)
  - Okey/Joker = value of tile they represent

### Opening Action
1. Declare "Opening"
2. Lay down valid melds totaling ≥51 points
3. Can keep remaining tiles in hand (don't need to meld everything)
4. Once opened, can add to your melds or others' melds in future turns

### Cannot Open If:
- Total meld points < 51
- Any meld is invalid
- Haven't drawn a tile this turn yet

---

## Winning the Round

### Win Condition
Player completes a valid hand where **all 14 tiles** form valid melds.

### Two Ways to Win:

#### 1. Standard Win
- All tiles in valid sets/runs
- Example: 
  - Set: 5-R, 5-B, 5-Y
  - Run: 8-R, 9-R, 10-R, 11-R
  - Run: 2-B, 3-B, 4-B
  - Set: 12-R, 12-B, 12-Y, 12-Bl

#### 2. Special Win (7 Pairs)
- Hand contains exactly **7 pairs** (2 identical tiles each)
- Pairs must be exact matches (same number AND color)
- Example: 3-R/3-R, 7-B/7-B, 1-Y/1-Y, 9-Bl/9-Bl, 5-R/5-R, 11-B/11-B, 13-Y/13-Y
- Scores **double points**

### Declaring Win
1. On your turn, after drawing
2. Reveal all melds
3. If valid → round ends, calculate scores
4. If invalid → penalty (lose round automatically)

---

## Scoring

### Basic Scoring (per round)
- **Winner:** +2 points
- **2nd place:** +1 point (most complete hand)
- **3rd place:** 0 points
- **Last place:** -1 point

### Multipliers
- **Double Win (7 pairs):** Winner gets +4 points
- **Joker Penalty:** -1 point if holding Okey/Joker at round end (not winner)

### Match End
- **Play to N rounds:** First to complete 7 rounds (default)
- **Play to target score:** First to reach 15 points (configurable)

---

## Special Rules

### First Round Exception
- All players must **pick from discard pile** for their first draw (not deck)
- After first draw, normal rules apply

### Timeout
- If turn timer expires (45s default):
  - Auto-draw from deck
  - Auto-discard rightmost tile
  - No penalty if offline/practice mode
  - Online: 3 timeouts = forfeit round

### Discard Pile Rules
- Can only take top tile
- Cannot take if it was your discard last turn
- Taking from discard → must use in a meld immediately OR next turn

### Dead Hand
- If deck runs out before anyone wins:
  - Round ends
  - Score based on hand completion (fewest unmelded tiles wins)

---

## House Rules (Configurable)

### Opening Threshold
- Classic: 51 points
- Variants: 40, 60, or "double" (101)

### Double Opening
- Enabled: Can open with 101+ points for double round score
- Disabled: Standard opening only

### Initial Draw Rule
- Classic: Must pick from discard pile first turn
- Variant: Can pick from deck

### Timer Options
- Off (unlimited)
- 30s / 45s / 60s / 90s

### Match Format
- Rounds: 5 / 7 / 10
- Score target: 10 / 15 / 20 / 50

---

## Strategy Notes (for Bot AI)

### Good Discards
- High numbers if not in runs (reduce points if caught)
- Tiles far from your melds
- Duplicates of tiles already discarded

### Bad Discards
- Jokers/Okeys (unless winning)
- Tiles that complete common runs (6, 7, 8)
- Tiles next player likely needs (watch their picks)

### When to Open
- Have 51+ points AND hand is flexible (multiple ways to complete)
- Late in round (fewer tiles in deck)
- Other players opening (don't fall behind)

### When to Hold
- Hand close to winning without opening
- Early round with strong hand
- Can reach 7 pairs (double score)

---

## Edge Cases

### What if two players finish simultaneously?
- Cannot happen (turn-based)

### Can I rearrange opponent's melds?
- No, only your own opened melds

### Can I take back a discard?
- No, discards are final

### What if I draw the indicator tile?
- It acts as Okey (wild card) like the other two

### Minimum deck size to continue?
- Game continues until deck empty or someone wins
