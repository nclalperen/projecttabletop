# Okey 101 (Yüzbir) — Development Pack (Godot 4.x)

This package documents a complete, implementation-ready ruleset and architecture for building a **digital Okey 101**
(Turkish “Yüzbir”) game in Godot 4.x.

> If you previously used a 14-tile Okey/“51” style rules doc, **delete it** — Okey 101 differs in
> **dealing (21/22 tiles), opening threshold (101), doubles mode, and penalty scoring**.

---

## What’s Included

- **RULES.md** — authoritative TR-101 Classic ruleset:
  - dealing (21/22), indicator/joker/false joker
  - opening by **≥101 points** or **5 doubles**
  - strict discard pickup (“take discard → must use immediately”)
  - full scoring table (+101 penalties, multipliers, elden/okey finish)
- **API.md** — action spec for a host-authoritative rules engine
- **ARCHITECTURE.md** — Godot project structure + state model + validation patterns
- **Excel plans** — task tracking / Gantt (optional project-management layer)

---

## Recommended Development Order

1) Implement the **core rules engine** (state + validator + apply)
2) Add a minimal offline UI that can:
   - draw / take discard
   - open
   - add tiles
   - discard
   - end deal + score
3) Add bots
4) Add online sync

---

## High-Risk Areas (test first)

- Joker semantics (real vs false joker)
- Opening validation (≥101 points, and doubles opening)
- Discard pickup constraint (“must use immediately”)
- Scoring multipliers:
  - winner finished with joker
  - winner opened doubles
  - elden finish
- +101 penalties:
  - discarding joker (non-finishing)
  - discarding playable tile (“işlek”)
  - failed open attempt
  - illegal take-backs

---

## Terminology
- **Real Joker (Okey)**: indicator+1 tile (both copies), wild
- **False Joker (Sahte Okey)**: star tile; represents the real joker tile for this deal
- **Low score wins**: negative for winner, positive penalty for others

---

## Next Step
Open **RULES.md** and implement the engine so that every rule is enforceable via `validate_action`.
