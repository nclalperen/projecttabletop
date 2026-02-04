# Canonical Okey 101 Rules

This document defines the canonical rules for Okey 101 used by this project. These rules are aligned with the RuleConfig defaults in `RuleConfig.gd`.

## Components
- 106 tiles total
- Two copies of each tile numbered 1-13 in four colors
- 2 fake okey tiles (jokers that represent the okey tile)

## Dealing
- Each player receives `21` tiles.
- The starting player receives `22` tiles.
- The starting player **discards first without drawing**.

## Turn Loop
1. Draw **one** tile from the deck **or** take the last discard.
2. Play melds if allowed (opening or extending melds).
3. Discard **one** tile to end the turn.

## Indicator and Okey
- One tile is revealed as the **indicator**.
- The **okey** is the indicator tile number + 1 with wrap (13 -> 1), same color.
- There are two copies of the okey tile; both are wild, but only as the okey tile.

## Fake Okey Tiles
- Fake okey tiles **represent the okey tile**.
- They are not free wilds unrelated to the okey.

## Opening
- To open, a player must lay down melds totaling **at least 101 points**.
- Optional rule: **opening by 5 pairs** is allowed if enabled.

## Taking From Discard
- If a player takes the last discard, they **must use it**.
- If the player has **not opened**, taking from discard **requires opening** and the taken tile **must be included** in the opening melds that turn.

## Finish
- A player finishes the hand by playing all tiles and discarding the last tile.
