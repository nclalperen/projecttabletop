# Release Asset Replacement Checklist

This checklist tracks third-party/prototype assets that must be replaced with first-party release assets before ship.

## Goal

Replace temporary UI/audio assets and remove missing-import errors so release builds only ship project-owned content.

## Current Missing Assets (from latest headless boot)

These are currently referenced but missing/import-broken:

- `res://uassets/ui/buttons/button_rectangle_depth_gradient_gold.png`
- `res://uassets/ui/buttons/button_rectangle_depth_gradient_blue.png`
- `res://uassets/ui/panels/pattern_diagonal_transparent_small.png`
- `res://uassets/ui/panels/panel_grey_dark.png`
- `res://uassets/ui/panels/panel_border_grey_detail.png`
- `res://uassets/ui/icons/board/pawns.png`
- `res://uassets/ui/icons/board/lock_open.png`
- `res://uassets/ui/icons/board/card_add.png`
- `res://uassets/ui/icons/support/gear.png`
- `res://uassets/ui/icons/support/cross.png`
- `res://uassets/audio/ui/rollover3.ogg`
- `res://uassets/audio/ui/rollover5.ogg`
- `res://uassets/audio/ui/click3.ogg`
- `res://uassets/audio/ui/click4.ogg`
- `res://uassets/audio/ui/switch12.ogg`
- `res://uassets/audio/interface/open_002.ogg`
- `res://uassets/audio/interface/close_002.ogg`
- `res://uassets/audio/interface/back_002.ogg`
- `res://uassets/audio/interface/error_004.ogg`

## Replacement Plan

1. Add owned replacement files at the same `res://uassets/...` paths (fastest, no code changes).
2. Open project in Godot once to reimport assets and regenerate `.godot/imported/*`.
3. If you want different paths, update the IDs/lookup layer instead of scene-by-scene edits:
   - `res://gd/assets/AssetIds.gd`
   - `res://gd/assets/AssetRegistry.gd`
4. Keep audio format consistent (`.ogg`) for current loaders.
5. Keep button/panel/icon dimensions consistent to avoid UI regressions.

## Release Gate (must pass)

Run:

```powershell
tools/godot.cmd --headless --path . --quit
```

Pass criteria:

- No `Failed loading resource` errors for `res://uassets/...`
- No missing `.godot/imported/*.ctex` or `*.oggvorbisstr` for release assets

## Optional Cleanup (after replacement)

- Remove any prototype/borrowed media still checked in under temporary folders.
- Re-run a content/license audit on `res://prototype/imported/**` and `res://uassets/**`.
