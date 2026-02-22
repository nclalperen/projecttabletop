# Okey 101 (Yüzbir) — Ruleset Specification (TR-101 Classic)

> **Scope:** This document specifies a **digital-implementation-ready** ruleset for the Turkish tile game **Okey 101**
> (“Yüzbir”) with **scoring, penalties, and round-end logic** suitable for a rules/round engine.
>
> **Note on “official” rules:** In real life there are **regional / platform variations**. This spec chooses one coherent,
> widely used baseline (“TR-101 Classic”) and exposes common variations as **RuleConfig toggles**.

---

## 1) Terminology

- **Tile**: A physical/virtual piece with a **color** and **rank** (1–13). Each tile exists in **two copies**.
- **Colors** (common): Red, Blue, Yellow, Black.
- **False Jokers (Sahte Okey)**: Two special star tiles. They are **not independent wildcards**; they represent the current
  **Joker tile** for this deal (see below).
- **Indicator (Gösterge)**: One tile revealed face-up at the start of the deal.
- **Joker tile (Okey)**: Determined by the indicator: **same color, rank + 1** (13 wraps to 1).
- **Meld / Per**: A valid group of tiles placed on the table.
- **Opening / “Açmak”**: The first time a player places melds on the table in a deal (must meet an opening condition).
- **Doubles opening / “Çift açmak”**: Opening by placing **pairs** instead of sets/runs (configurable; see §5).
- **Finish / “Bitmek”**: Ending the deal by discarding your last remaining tile (you must have exactly 1 tile left to discard).

---

## 2) Components & Tile Set

### 2.1 Tile set (106 tiles)
- 4 colors × ranks 1–13 × **2 copies** = 104 tiles
- + 2 **False Jokers** (Sahte Okey) = 106 total

### 2.2 Tile identity model (implementation)
Each physical tile must have a **unique id** (because duplicates exist).
Recommended fields:
- `color` ∈ {R,B,Y,K} (or enum)
- `rank` ∈ 1..13 (or `null` for false jokers)
- `copy_index` ∈ {0,1} for normal tiles
- `kind` ∈ {NORMAL, FALSE_JOKER}

---

## 3) Setup (Dealing)

### 3.1 Seating & direction
- 4 players. Play proceeds **counter-clockwise** (anti-clockwise).
- Seats are typically N/E/S/W, but implementation should use indices 0..3.

### 3.2 Shuffle & indicator
1. Shuffle all 106 tiles.
2. Deal tiles (see §3.3).
3. Reveal the **indicator** tile from the remaining face-down tiles.
4. Determine **joker tile**:
   - `joker_rank = indicator.rank + 1` (wrap 13→1), `joker_color = indicator.color`
   - Both copies of that tile are **real jokers** (wild).
5. False jokers represent the **joker tile** (see §4.3).

> **Implementation hint:** Treat “joker-ness” as *derived from indicator*, not a permanent tile property.

### 3.3 Dealing (hand sizes)
TR-101 Classic uses **21/22 tiles**:
- Deal **21** tiles to each player.
- The player **to the dealer’s right** receives **one extra** tile (so **22**) and **starts**.

The starting player begins the deal by **discarding one tile without drawing** (because they already have 22).

### 3.4 Stock (draw pile) and discard
- Remaining face-down tiles form the **stock**.
- Discards form a **face-up discard pile**; only the **top** tile is available to take.

---

## 4) Meld Types & Joker Semantics

### 4.1 Valid meld: Set (Group)
- **3 or 4** tiles
- Same rank
- All colors **distinct** (no duplicate colors)

Example: 5R, 5B, 5Y ✓  
Invalid: 5R, 5R, 5B ✗

### 4.2 Valid meld: Run (Sequence)
- **3+** tiles
- Same color
- Consecutive ranks
- **No wrap** from 13→1

Example: 10B, 11B, 12B, 13B ✓  
Invalid: 12R, 13R, 1R ✗

### 4.3 Real Joker (Okey)
A **real joker tile** (the tile(s) equal to indicator+1) may substitute for any missing tile in a meld.

### 4.4 False Joker (Sahte Okey)
A false joker is treated as **the joker tile itself** (i.e., “a copy of the real joker” for this deal).
- In meld validation, it behaves like a real joker **because the joker tile is wild**.
- In UI, it should still be visually identifiable as a false joker tile.

### 4.5 Scoring value of jokers (important)
For **penalty scoring**, any **unplayed joker** (real or false) remaining in a player’s hand is worth **101 points each**
(regardless of which rank it substituted earlier).

---

## 5) Opening Rules (Açma)

A player is considered “opened” after they successfully place opening melds on the table.

### 5.1 Opening by points (standard)
To open by points:
- In a **single turn**, the player places one or more valid sets/runs whose **total value ≥ 101**.

**Meld value:**
- For a set/run of normal tiles, add the ranks of the tiles.
- For jokers used inside melds, count the **represented tile’s rank** for the purpose of meeting 101.

> Many players use the “middle-tile trick” for runs, but the engine should compute exact totals.

### 5.2 Opening by doubles (pairs) — optional but common
To open by doubles:
- Place **at least 5 pairs (doubles)**.
- A pair is **two identical tiles** (same color + same rank; i.e., the two copies).

After a doubles opening:
- The player must continue the deal using **pairs as their primary melding method** (see RuleConfig toggle).
- They **may still add tiles to other players’ melds** after they have opened.

### 5.3 “All players open with doubles” cancellation (optional)
If **all 4 players** open with doubles during the same deal:
- The deal is **cancelled and replayed**
- No one scores points for that deal.

### 5.4 Invalid opening attempt penalty (common)
If a player attempts to open but fails validation (insufficient points / invalid melds):
- The placed tiles return to their hand
- Player receives **+101 penalty points** for that deal.

---

## 6) Turn Structure

### 6.1 First turn (starting player)
Starting player has 22 tiles and performs:
1) **Optional play** (open / add / rearrange)  
2) **Discard exactly 1 tile**  
Turn ends.

### 6.2 Normal turn (all other turns)
1) **Draw**
   - Either draw top tile from **stock**
   - Or take the **top discard** (see §6.3)
2) **Play (optional)**
   - If not opened: may attempt to open (points or doubles).
   - If opened: may add tiles to any melds, and may rearrange melds (see §7).
3) **Discard exactly 1 tile** to end the turn.

### 6.3 Taking from discard (strict rule)
If you take the top tile from the discard pile, you **must use it immediately** in the same turn:
- If you have not opened yet, the taken tile must be included in your **opening** meld(s).
- If you have opened, it must be included in a **meld placed/extended** on the table that remains after your play.

You may not take a discard and “just keep it”.

---

## 7) Table Manipulation Rules (Rearranging)

After a player has opened, they may:
- Add tiles to existing melds (theirs or others)
- Split/recombine melds **only if** all melds on the table remain valid after the operation

**Constraint:** Players may not temporarily create invalid melds as an intermediate state at end-of-turn.
(Implementation can allow interactive drag/drop as long as the final submitted move validates.)

---

## 8) Finishing the Deal (Bitme)

### 8.1 Finish condition
A player finishes the deal when:
- After their play, they have **exactly 1 tile** in hand, and
- They **discard** that final tile (finishing discard).

If a player places all tiles on the table leaving **0 tiles** before discarding, the deal **does not end**;
they must still have a tile to discard to finish.

### 8.2 Finish types (for scoring)
Track these boolean flags for the deal winner:
- `winner_opened_with_doubles`
- `winner_finishing_discard_is_joker` (real or false joker)
- `winner_finished_in_one_turn_before_anyone_opened` (“elden bitme”)

---

## 9) Scoring (Points + Penalties)

Okey 101 is a **low-score-wins** game:
- The winner gets a **negative** score (reward).
- Others get **penalty points**.

### 9.1 Hand value for penalty scoring
For a player at the end of the deal:
- Ordinary tiles: value = rank (1..13)
- Any unplayed joker (real or false): value = **101**

HandValue = sum(values of tiles remaining in hand)

### 9.2 Base scoring table (TR-101 Classic)

#### A) Special case: “Elden bitme”
If the winner puts down all tiles and finishes **in one turn before anyone else opened**:

- If winner’s finishing discard is **not** a joker:
  - Winner: **-202**
  - Each other player: **+404**
- If winner’s finishing discard **is** a joker:
  - Winner: **-404**
  - Each other player: **+808**

#### B) Normal case (not elden bitme)
Compute `winner_score` and each loser score as follows.

**Winner score**
- Start with -101
- If winner opened with doubles: ×2  → -202
- If winner finished by discarding a joker: ×2  → -202 or -404

So winner is one of: **-101, -202, -404**

**Loser base penalties**
- If a loser never opened:  
  - +202 if winner score is -101  
  - +404 if winner score is -202 or -404
- If a loser opened with sets/runs:  
  - Loser = HandValue × (|winner_score| / 101)
- If a loser opened with doubles:  
  - Loser = HandValue × (2 × |winner_score| / 101)

(So multipliers are 1/2/4 for sets/runs openers, and 2/4/8 for doubles openers, matching common play.)

### 9.3 Additional +101 penalties (added on top)
Add **+101** penalty points to a player’s deal total for each of these events:

1) **Discarding a joker** (non-finishing discard)
2) **Discarding a tile that could be legally added to any meld currently on the table** (“işlek taş atma”),
   even if the player has not opened yet
   - **Exception:** No penalty if it was the **finishing discard**
3) **Failed opening attempt** (see §5.4)
4) **Illegal take-backs during table manipulation**:
   - Taking back multiple placed tiles (beyond “undo last tile”) after committing them to table state

> These penalties are common in online rulesets; keep them configurable because some tables ignore them.

### 9.4 Match winner
After the agreed number of deals (or reaching a target), sum all deal scores.
The **lowest total** wins the match.

---

## 10) Common Rule Variations (make these config flags)

- **Katlamalı 101**: Each new opener must open with at least (previous_open_value + 1).
- **Doubles opening enabled/disabled**; required pair count (default 5).
- **Discard pickup strictness**: “must use immediately” vs “may keep but can’t discard same turn”.
- **Penalty rules enabled/disabled** (joker discard, işlek discard, failed open, take-back).
- **End when stock empties**:
  - Option A: treat as “no winner”, everyone scores HandValue (and unopened=202), no negatives
  - Option B: cancel deal and redeal
  - Option C: platform-specific (expose as config)

---

## 11) Engine-Level Invariants (recommended)

- Hand sizes:
  - Start of deal: [22 for starter, 21 others]
  - After normal draw: hand temporarily increases by 1, then must discard back to expected size.
- Turn phases are explicit:
  - `TURN_DRAW` (skipped for starter’s first turn)
  - `TURN_PLAY`
  - `TURN_DISCARD`
- A player who has not opened may not add to existing melds unless a variant allows it.
- Any action that changes table melds must validate **final** table state as all-valid.

---

## 12) References (for baseline rules)
This TR-101 Classic baseline is aligned with common online descriptions of Okey 101 scoring, doubling cases, and +101 penalties
(e.g., Pagat, and several Turkish online rule summaries).
