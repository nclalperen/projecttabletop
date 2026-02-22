# Visual Acceptance Snapshots

Use deterministic captures to compare visual regressions across polish iterations.

## Required Baseline Captures

1. `table_idle`
2. `dragging_tile`
3. `melded_groups`
4. `round_end`

## Capture Settings (Fixed)

- Scene: `res://ui/GameTable3D.tscn`
- Camera preset: `qa_reference` (toggle via `F6` in debug)
- Resolution: `1920x1080`
- Renderer: Forward+ (`D3D12` on Windows, `Vulkan` on Android)
- Seed: fixed project test seed (`101101`) for deterministic state comparisons
- Profile: `High` on desktop, `Medium` on Android

## Naming Convention

- Desktop: `captures/desktop/<case>_<yyyymmdd-hhmm>.png`
- Android: `captures/android/<device>/<case>_<yyyymmdd-hhmm>.png`

Examples:

- `captures/desktop/table_idle_20260213-1900.png`
- `captures/android/s25/dragging_tile_20260213-1912.png`

## Review Checklist Per Capture

- Local rack text readability (all colors, especially yellow).
- Opponent racks visible but de-emphasized.
- Felt/wood material balance (no plastic/glossy overkill).
- Meld guide does not dominate scene.
- No UI/HUD clipping or overlap.
- No unexpected gamma/contrast shifts.
