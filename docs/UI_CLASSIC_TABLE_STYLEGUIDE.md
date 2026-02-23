# UI Classic-Table Style Guide

This document defines the menu/lobby/settings visual system for the classic-table direction.
Implementation source of truth is `res://ui/services/MenuStyleRegistry.gd`.

## Design Intent

- Warm, tactile board-game look.
- Strong hierarchy for action-first navigation.
- Calm motion with clear interaction feedback.

## Palette Tokens

Use `MenuStyleRegistry.color(id)` and these token IDs:

- `bg_pattern`: page background modulation.
- `backdrop_tint`: global screen darkening layer.
- `panel_shell`: panel interior tint.
- `panel_border`: panel frame tint.
- `title_text`: screen and card titles.
- `subtitle_text`: section headers and secondary labels.
- `body_text`: normal descriptive text.
- `muted_text`: low-emphasis metadata.
- `chip_text`: chip and compact label text.
- `chip_icon`: chip icon accent.
- `field_bg`, `field_border`, `field_border_focus`, `field_text`, `field_placeholder`.

## Typography Scale

- Title: 40-56.
- Section heading: 20-23.
- Body text: 16-18.
- Prompt badges: 16.
- Buttons: 22.

Prefer one size step at a time between neighboring text groups.

## Components

- Icon buttons:
  - Primary: warm gold action buttons.
  - Secondary: muted support buttons.
- Prompt badges:
  - Compact rounded chips with icon + short label.
- Lobby player chips:
  - Avatar, name, seat/state, host/ready badges.
- Emote buttons:
  - Small square icon actions (lobby only).

## Motion Rules

Use `MenuStyleRegistry.scalar(id)` for durations/scales:

- `motion_menu_in`, `motion_button_in`, `motion_stagger`, `motion_fade_out`.
- `press_scale`.

Constraints:

- Maximum transition duration: 250 ms.
- No continuous looped decorative animation in menus.
- Feedback should be single-fire per interaction.

## Do / Do Not

Do:

- Read colors/scales/vectors from `MenuStyleRegistry`.
- Keep button disabled reasons explicit via tooltip text.
- Keep status copy deterministic for each lobby state.

Do not:

- Hardcode repeated style values in menu scripts/widgets.
- Introduce new visual variants without a registry token.
- Add long-running motion effects to menu scenes.
