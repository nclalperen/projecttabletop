# Developer Notes

## Headless Tests
Run tests in headless mode:

```bash
godot --headless -s res://tests/run_tests.gd
```

Recommended project wrapper usage:

```powershell
.\tools\godot.cmd --headless --path . -s res://tests/run_tests.gd
```

### Mono Headless Crash (Windows)
If the mono build crashes on startup in headless mode, use the standard (non-mono) Godot
console executable to run GDScript tests, or run tests from the editor.

Examples:

```bash
Godot_v4.6-stable_win64_console.exe --headless -s res://tests/run_tests.gd
```

```bash
Godot_v4.6-stable_win64.exe -e
```

## Editor Test Runner
You can run tests from the editor with the dedicated scene:

- Open `res://tests/TestRunner.tscn`
- Press Play

## Canonical Rules
SeOkey11 gameplay rules are defined in:

- `docs/SEOKEY11_CANONICAL.md`

## Renderer Policy (Forward+ Migration)

Current rendering targets:

- Windows Desktop: `Forward+` on `D3D12`
- Android: `Forward+` on `Vulkan` (modern devices only)

Legacy / non-Vulkan Android support is intentionally out of scope for this phase.

See:

- `docs/RENDERING_SUPPORT_MATRIX.md`

## Android Forward+ Validation Gate

Before accepting Forward+ as stable for Android, run real-device validation on:

1. one modern Adreno Vulkan phone
2. one modern Mali Vulkan phone

Minimum run:

- 20 minutes interactive gameplay with heavy drag/drop + round transitions
- no crash/black-screen/shader lock
- average FPS target >= 50 with no sustained stutter

If the gate fails:

1. revert renderer mode in `project.godot` to previous baseline
2. keep Android Forward+ marked experimental until re-validation

## Runtime Telemetry (Debug Build)

In debug builds, 3D mode shows a small telemetry line at the bottom-left with:

- renderer method
- configured driver for current platform
- sampled FPS

This is for migration verification and is non-intrusive for release workflows.

## Visual Quality Profiles

UI-side visual settings are stored in `user://ui_settings.cfg` and consumed by:

- `res://ui/services/UISettings.gd`
- `res://ui/services/VisualQualityService.gd`

Profiles:

- `low`
- `medium`
- `high`
- `ultra`

Defaults:

- Windows: `high`
- Android (modern Vulkan): `medium`

Tunable keys:

- `graphics_profile`
- `aa_mode`
- `ssao_quality`
- `ssr_enabled`
- `resolution_scale`
- `postfx_strength`

## Visual Baselines

Use deterministic captures for regression checks:

- `docs/VISUAL_ACCEPTANCE_SNAPSHOTS.md`
- `docs/VISUAL_STYLE_GUIDE.md`

## Automatic Capture Workflow (Debug)

In `GameTable3D` debug builds:

- auto capture runs every 20 seconds by default,
- captures are timestamped PNGs,
- files are saved to:
  - preferred: `res://ai agent docs/screenshots/auto`
  - fallback: `user://captures/desktop` (or `user://captures/android/<device>` on Android)

One-command timed capture run (desktop):

- `.\tools\capture_gametable3d.cmd`
- custom duration example: `.\tools\capture_gametable3d.cmd -DurationSec 120`
- keep Godot open after timer: `.\tools\capture_gametable3d.cmd -KeepOpen`

Hotkeys:

- `F7`: toggle auto capture on/off
- `F8`: save one manual capture immediately

## Asset Compliance Gate

Runtime-used external assets must be registered in:

- `docs/ASSET_LICENSES.md`

The test `res://tests/test_asset_license_registry.gd` enforces:

- every runtime asset path has a row,
- row status is `approved`,
- license is CC0/Public Domain style,
- source URL and license URL are present.
