# RuleConfig Schema

This document defines all fields in `RuleConfig` and their canonical defaults for **SeOkey11**.

## Core Identity
- `preset_name` (String)
  Default: `"seokey11"`
  Description: Named preset for serialization and UI selection.

## Dealing / Opening
- `tiles_per_player` (int)
  Default: `21`
  Description: Tiles dealt to each player.

- `starter_tiles` (int)
  Default: `22`
  Description: Tiles dealt to the starting player.

- `open_min_points_initial` (int)
  Default: `101`
  Description: Minimum points needed to open by melds.

- `allow_open_by_five_pairs` (bool)
  Default: `true`
  Description: If `true`, opening by 5 pairs is allowed.

- `open_by_pairs_locks_to_pairs` (bool)
  Default: `true`
  Description: If `true`, opening by pairs locks the player into pairs-only meld creation (they may still add to existing melds on table).

## Discard Take
- `require_discard_take_to_be_used` (bool)
  Default: `true`
  Description: If `true`, a tile taken from discard must be used.

- `if_not_opened_discard_take_requires_open_and_includes_tile` (bool)
  Default: `true`
  Description: If `true`, taking from discard before opening forces an opening and the taken tile must be included in the opening melds that turn.

- `discard_take_must_be_used_always` (bool)
  Default: `true`
  Description: If `true`, a tile taken from discard must be used immediately even after opening.

## Indicator Behavior
- `indicator_fake_joker_behavior` (String)
  Default: `"redraw"`
  Allowed: `"redraw"`, `"risk_mode"`
  Description: Behavior if the indicator reveals a fake okey tile.

## Match / Timer
- `timer_seconds` (int)
  Default: `45`
  Range: `0..180`
  Description: Turn timer in seconds. `0` disables the timer.

- `match_end_mode` (String)
  Default: `"rounds"`
  Allowed: `"rounds"`, `"target_score"`
  Description: Determines match end condition.

- `match_end_value` (int)
  Default: `7`
  Description: Number of rounds or target score based on `match_end_mode`.

## JSON Roundtrip
`RuleConfig.gd` supports roundtrip via `to_dict()` and `from_dict()` using these fields.
