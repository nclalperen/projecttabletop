# TR-101 Canonical Profile (Implementation Contract)

This document is the implementation lock for the current rules-engine pass.

## Source Priority

When documents disagree, use this priority order:

1. `ai agent docs/Turkish Okey 101 Scoring, Penalties, and Edge-Case Ruleset for a Rules Engine.md`
2. `ai agent docs/RULES.md`
3. `ai agent docs/API.md`
4. `ai agent docs/ARCHITECTURE.md`

Notes:
- `ai agent docs/okey101_docs_v2/*` is considered non-authoritative mirror content if recreated.
- This profile resolves all ambiguities needed for deterministic implementation.

## Locked Defaults

- Ruleset: `tr_101_classic`
- Turn model: strict `TURN_DRAW -> TURN_PLAY -> TURN_DISCARD`
- `DISCARD` action validity: only in `TURN_DISCARD`
- Opening: `>=101` points or `>=5` doubles (pairs)
- Strict discard-take use: enabled
- Joker reclaim: enabled only after player has opened
- Stock-empty default: `score_no_winner`
- `pairs+okey` unopened default penalty: `404` (profile override to `808` supported)

## Scoring Contract

- Winner credits:
  - normal: `-101`
  - okey finish: `-202`
  - pairs finish: `-202`
  - pairs + okey: `-404`
  - elden: `-202`
  - elden + okey: `-404`
- Unopened baseline: `202`
- Joker hand value: `101`
- Opened-by-pairs loser multiplier: `x2` on hand value before finish multiplier
- Non-finishing discard penalties (+101 blocks) are accumulated per player in-round and applied at round scoring.

## Compatibility Policy

- Legacy action helpers remain available.
- New canonical API envelope is supported via controller translation.
- Legacy config aliases are accepted in `RuleConfig.from_dict`.
