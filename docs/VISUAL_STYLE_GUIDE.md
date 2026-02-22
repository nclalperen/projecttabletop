# Visual Style Guide (Premium Tabletop Realism)

## Goal

Move from functional visuals to a warm, production-grade tabletop look while preserving gameplay readability.

## Core Direction

- Mood: warm, tactile, cafe-table atmosphere.
- Priority: local player rack readability first, ambience second.
- Contrast policy: tile glyphs must remain legible at default gameplay camera (`competitive` preset).

## Color Targets

- Felt base: deep green-teal, low specular.
- Wood base: warm brown with varnish response (subtle highlights, not mirror-like).
- Tile body: warm off-white.
- Tile glyphs:
  - Red: deep saturated red.
  - Blue: medium-dark royal blue.
  - Black: near-black neutral.
  - Yellow: dark amber/brown (must be high-contrast on tile face).

## Lighting Intent

- Key light: warm directional, primary scene shape.
- Rim light: cool directional, edge definition for racks/tiles.
- Fill light: neutral/warm omni, low intensity.
- Opponent racks: de-emphasized with lower contrast and rougher response.

## PostFX Rules

- Allowed: mild SSAO/SSIL, restrained glow, optional SSR.
- Disabled by default: DOF blur in gameplay.
- Tone mapping: ACES.
- Rule: effects must never reduce tile readability or drag feedback clarity.

## Camera Rules

- Default preset: `competitive`.
- Framing target: active gameplay area should occupy ~75% of viewport height.
- Local rack must stay fully readable on 16:9 and ~16:10.
- `cinematic` preset is for capture/replay only.

## Interaction Visibility Rules

- Meld guide:
  - Idle: subtle.
  - During drag: stronger but not dominant.
- Invalid drop feedback: clear and brief.
- Snap feedback: visible but not noisy.

## Do / Don’t

- Do:
  - Keep local player visuals as focal anchor.
  - Preserve clear silhouettes for face-up vs face-down tiles.
  - Use quality profiles to prevent GPU cost creep.
- Don’t:
  - Overuse bloom, DOF, or high-gloss materials.
  - Let opponent racks or guides steal visual focus from active hand.
  - Sacrifice readable glyph contrast for color richness.
