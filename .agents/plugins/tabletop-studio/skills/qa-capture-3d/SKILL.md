---
name: qa-capture-3d
description: Capture automated screenshots of GameTable3D across desktop or mobile resolutions and perform visual QA inspection of 3D tiles, rack slots, felt lighting, and HUD layout. Trigger via /qa-capture-3d.
---

# 3D Table Screenshot Capture & Visual QA (`/qa-capture-3d`)

Use this skill to capture a rendered frame of `ui/GameTable3D.tscn` and inspect the visual presentation of the 3D table, rack tiles, meld zones, and `OkeyPlayHUD`.

## Step 1: Capture Screenshot via `capture_gametable3d.ps1`

Run the capture helper from the repository root (`d:\Projects\projecttabletop`):

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\capture_gametable3d.ps1 -Width 1920 -Height 1080 -WaitFrames 60
```

For compact mobile landscape aspect ratio verification (`com.alperen.okey101`):

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\capture_gametable3d.ps1 -Width 1600 -Height 720 -WaitFrames 60
```

## Step 2: Locate and View Captured Image

1. The script outputs the exact saved path under `%APPDATA%\Godot\app_userdata\Okey 101\captures\` (or `user://captures/gametable3d_*.png`).
2. Call `view_file` on the output `.png` path to visually inspect the rendered frame.

## Step 3: Visual QA Checklist

Verify each of the following in the captured frame:
- **HUD Layout**: Top bar, opponent `PlayerSeatBadge` widgets, and bottom action dock (`OkeyPlayHUD`) do not overlap the 30-slot 3D rack or draft workspace.
- **Tile Readability**: Tile numbers, suit colors, and indicator tile on `DeckAndDiscards3D` are sharp and legible.
- **Lighting & Shadows**: Table felt shader, wood rim material, and tile contact shadows render cleanly without clipping or Z-fighting.
- **World Callouts**: `MeldInspectionOverlay` pills (when melds are on the felt) align cleanly above their 3D meld groups.
