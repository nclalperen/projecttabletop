# Okey 101 desktop table

## Architecture

`ui/GameTable3D.tscn` renders the desktop 3D table. `ui/GameTable3D.gd` owns camera fitting, world geometry, tile picking, drag previews, animation, and audio. `ui/game_table/OkeyPlayHUD.gd` owns the screen controls, help, table-meld browser, and results panels. The 3D table does not instantiate a hidden 2D scene.

Both `ui/GameTable.gd` and the 3D table use `ui/game_table/OkeySession.gd`. This presenter owns local rack/draft arrangements, selection, undo, rule previews, controller binding, request sequencing, and local bot scheduling. Cached action and draft previews are invalidated by state or presentation changes; per-frame HUD updates must not invoke expensive validators directly.

The controller remains the authority for rules and scoring. Public `configure_game(...)`, `inject_controller(...)`, controller action envelopes, and `MatchControllerPort` signals are preserved. Injected online controllers supply seat-relative, visibility-filtered snapshots; the presenter never reads hidden opponent hands or stock values. Four seats are used because the existing 101 setup always deals four players.

Arrangement undo is local and clears after authoritative changes. Online requests remain pending until both an accepted result and a state snapshot arrive, in either order. Rejection unlocks controls and displays the reason. Explicit discard during play queues END_PLAY, then submits the exact selected tile after the authoritative discard phase; it never submits draft melds or chooses a replacement tile.

## Controls

- Click a tile to select it. Click a draft slot or committed meld to place the selected tile, or drag it onto the highlighted target.
- Use **Draw tile** or **Take discard** at the start of a turn. **Discard selected** or a deliberate drop in the discard zone ends the turn.
- Build separated, contiguous groups in the workspace and press **Open melds** or **Play melds**. The HUD shows opening points, pairs, and validation feedback.
- Use **Return draft**, **Undo**, and color/number sorting to organize tiles. Rack organization remains available during opponents' turns.
- Escape cancels a drag or selection. Focus loss and opening a dialog cancel dragging.
- **Overhead** enters inspection; **Return to play** restores manipulation. **Table melds** opens the enlarged, scrollable meld browser.
- **How to play** reopens the first-play guide. Sound and reduced-motion toggles are in the HUD. Results use explicit next-round/menu controls; the host controls online round advancement.

## Validation on Windows

Run from the repository root in PowerShell. Use the repository wrapper with an explicit argument array so flags such as `--verbose` are not interpreted as PowerShell parameters:

```powershell
$env:GODOT_EXE = 'D:\Tools\Godot\Godot_v4.7.1-stable_win64_console.exe'
& .\tools\godot.ps1 -CliArgs @('--headless', '--path', '.', '--editor', '--quit')
& .\tools\godot.ps1 -CliArgs @('--headless', '--path', '.', '--script', 'tests/run_tests_fast.gd')
& .\tools\godot.ps1 -CliArgs @('--headless', '--path', '.', '--script', 'tests/probe_gametable3d_interaction_matrix.gd')
```

`tests/test_okey_session.gd` covers arrangements, preview immutability, signal ordering, duplicate requests, rejection recovery, explicit discards, and next-round requests. It is included in the normal test runner. The interaction probe covers actual 3D interaction paths.

Capture rendered fixtures outside the repository, repeating at 1280×720, 1920×1080, 2560×1440, and ultrawide resolutions. The QA script supports `open`, `crowded`, `results`, and `match` fixtures:

```powershell
& .\tools\godot.ps1 -CliArgs @('--path', '.', '--script', 'tests/qa_okey3d.gd', '--', '--okey-skip-guide', '--qa-fixture=crowded', '--qa-size=1920x1080', '--qa-dir=C:/Temp/okey-qa')
& .\tools\godot.ps1 -CliArgs @('--headless', '--path', '.', '--script', 'tests/qa_okey3d.gd', '--', '--okey-skip-guide', '--qa-fixture=match')
```

The match fixture plays two complete rounds with the real presenter/controller and bots. It has a bounded timeout and progress logging. `--qa-size` renders into a dedicated viewport with exact pixel dimensions, avoiding operating-system window-size clamps. Captures warm up for 120 frames, then measure another 120 frames. Headless checks do not verify graphics, audio, frame rate, or live EOS connectivity. Live EOS validation requires configured credentials and a host/client session.

## Windows export

Use **trial-offline** for a playable local Windows preview with Godot 4.7.1. The bundled native EOS bridge crashes before startup in the standard **trial** build; the separate offline preset selects a safe no-op bridge and supports local bot matches. It does not provide live Epic services. The standard preset retains native EOS for compatibility testing. See [EOS runtime setup](EOS_RUNTIME_SETUP.md#7-godot-47-windows-offline-preview) for the diagnosis and release gate. `tools/export_windows.sh` still names `Windows Desktop` and should not be used unchanged for these preset names.

```powershell
New-Item -ItemType Directory -Force C:/Temp/okey-export | Out-Null
& .\tools\godot.ps1 -CliArgs @('--headless', '--path', '.', '--export-release', 'trial-offline', 'C:/Temp/okey-export/okey-offline.exe')
Start-Process -FilePath C:/Temp/okey-export/okey-offline.exe -WindowStyle Hidden
```

Keep captures, logs, and export artifacts out of tracked source. Record the tested hardware, renderer, resolution, and measured frame rate when reporting graphical acceptance.
