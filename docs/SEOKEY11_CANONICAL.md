# SeOkey 11 / Okey 101 — Canonical Rules (Dossier-Driven)

This document is derived from the **“New SeOkey 11 projectexplandior”** dossier and the clarifications that followed it. It is the single source of truth for the rules engine.

## 1) Lobby / Session (Pre-Game)

- **Host is always Player 1**.
- Players can join via **invite + join code**.
- Every player (including host) has a **Ready** status.
- Any change to lobby settings (mode, rules, etc.) **resets Ready for everyone** (including host).
- Rack colors:
  - Each player chooses a rack color as their identity.
  - **No two players may choose the same color.**

## 2) Seating & Turn Direction

- Seating and turn order are **counter-clockwise (CCW)**.
- Internal indexing convention:
  - Player 1 = index `0`, Player 2 = index `1`, Player 3 = index `2`, Player 4 = index `3`.
  - “Next player” in CCW order is `(+1) mod 4`.

## 3) Dealer Selection

- At the start of a match (first round), all players roll dice; the **highest roll becomes dealer**.
- If there is a tie for highest, the tied players **re-roll** until a single dealer is determined.
- For subsequent rounds, the dealer rotates **counter-clockwise** (dealer becomes `(dealer + 1) mod 4`).

## 4) Tiles, Indicator, Okey, Fake Okey

- The set contains **106 tiles**:
  - Numbers `1..13` in 4 colors, **two copies each** (104 tiles).
  - **2 fake okey** tiles (special marker tiles).
- **Indicator tile** is selected during setup and stays visible throughout the round.
- **Okey tile value**:
  - Same color as the indicator.
  - Number is `indicator + 1`, with wrap: `13 -> 1`.
- **Real okey tiles** (the two tiles matching the okey value) are **wild** and can substitute any needed tile in melds.
- **Fake okey** tiles are **not free wilds**:
  - Each fake okey represents the **exact okey tile value** for that round (same color+number).

## 5) Setup: 15-Stack Dealing Method

### 5.1 Build Stacks

- Shuffle all 106 tiles face-down.
- Build **15 stacks** of **7 tiles** each (105 tiles total).
- **1 leftover tile** remains (the 106th tile).

### 5.2 Select Indicator

- Dealer selects an **indicator** by dice (UX).
- Implementation detail:
  - Pick `(indicator_stack_index, indicator_tile_index)`.
  - `indicator_stack_index` selects which of the 15 stacks.
  - `indicator_tile_index` selects which tile within that stack.
- Remove the indicator tile from its stack and place it **beside the draw deck**, visible throughout the round.

### 5.3 Create the 8-Tile Starter Stack

- Let `starter_stack_index = indicator_stack_index + 1` (wrapping after 15 back to 1).
- Place the **leftover tile** on top of `starter_stack_index`, making it an **8-tile stack**.

### 5.4 Deal Stacks to Players

- The **starting player** is the player to the dealer’s right (CCW): `starter_player = (dealer + 1) mod 4`.
- Starting from `starter_stack_index`, distribute **12 consecutive stacks** (wrapping) in CCW player order:
  - Stack `starter_stack_index` goes to `starter_player`.
  - Next stack goes to the next player CCW, etc.
  - Each player receives **3 stacks** total.
- Resulting hand sizes:
  - Starting player receives one 8-tile stack + two 7-tile stacks → **22 tiles**.
  - Other players receive three 7-tile stacks → **21 tiles**.

### 5.5 Build the Draw Deck

- The **3 remaining stacks** become the draw deck source.
- Combine them into a single draw deck so that **higher stack number is drawn first**.
- The indicator stack itself is combined (minus the removed indicator tile).

## 6) Round Start: Starter Discard

- The starting player begins the round by **discarding one tile**.
- The starting player does **not draw** on this first action.

## 7) Turn Loop (Normal Turns)

Each turn (after the starter discard) proceeds CCW and consists of:

1. **Draw**:
   - Draw from the draw deck, **OR**
   - Take the last discard from the previous player (the player on your left).
2. **Play / Meld**:
   - Lay down new melds if allowed (see opening rules), and/or
   - Add tiles to existing melds on the table if allowed.
3. **Discard**:
   - Discard exactly one tile to end your turn.

## 8) Taking From Discard (Strict Rule)

- You may take the last discarded tile **only if you will use it immediately in a meld**.
- If you have **not opened yet**:
  - You may take the discard **only if you can open this turn and include that tile** in your opening.
- Otherwise, you must draw from the draw deck.

## 9) Meld Types

### 9.1 Runs

- Same color.
- Consecutive numbers.
- Minimum length **3**; no maximum length.
- **No wrap**: runs do not continue after 13 (e.g., `12-13-1` is invalid).

### 9.2 Sets

- Same number.
- Size is **3 or 4**.
- **All colors must be distinct** (no duplicate color within the set).

### 9.3 Pairs (Opening Path)

- A **pair** is two identical tiles (same color + number).
- Opening by pairs requires **at least 5 pairs** laid down in one opening.
- If you open by pairs, you are **locked to pairs mode**:
  - You cannot create additional melds later (no new runs/sets/pairs).
  - After you have opened, you **may add single tiles** to other players’ opened melds.

## 10) Opening Rules

You cannot add to table melds until you have opened. You may open by:

1. **Meld points opening**:
   - In a single turn, the total value of newly played runs/sets must be **>= 101**.
   - Opening value is the **sum of represented tile numbers** in the groups.
   - Wild real okey tiles count as the **substituted number** they represent.
2. **Pairs opening**:
   - In a single turn, lay down **>= 5 pairs**.

## 11) Adding to Melds (Layoffs)

- After you have opened, you may add tiles to **any** melds on the table (yours or others’).

## 12) Finishing the Round

- To finish, a player must play out their remaining tiles and **discard the last tile** (finish-by-discard).

## 13) Scoring (Simplified Dossier Mode)

- Winner: **0**
- Player who **never opened** during the round: **202**
- Player who **opened**:
  - Score is the sum of remaining tiles in hand.
  - Real okey (wild) left in hand after opening: **101** per tile.
  - Fake okey: counts as its **represented value** (okey number).
  - If the player opened by pairs, their score is **doubled**.

## Appendix A — Worked Example (From Dossier)

Example: dealer is Player 1, dealer selects indicator at **stack 6**, **tile 5**.

- The leftover tile is added to **stack 7**, making it an 8-tile starter stack.
- Player 2 (dealer’s right) receives stacks **7, 11, 15** → 22 tiles.
- Player 3 receives stacks **8, 12, 1** → 21 tiles.
- Player 4 receives stacks **9, 13, 2** → 21 tiles.
- Player 1 receives stacks **10, 14, 3** → 21 tiles.
- Remaining stacks **4, 5, 6** form the draw deck (indicator tile removed; the rest of stack 6 is included).

