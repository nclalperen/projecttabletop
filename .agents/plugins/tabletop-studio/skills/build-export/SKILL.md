---
name: build-export
description: Run preflight environment checks and export Windows Desktop (trial / trial-offline) or Android APK (com.alperen.okey101) builds. Trigger via /build-export.
---

# Cross-Platform Build & Export Workflow (`/build-export`)

Use this skill to validate export environments and build Windows Desktop or Android (`com.alperen.okey101`) deliverables.

## 1. Pre-Export Fast Test Gate

Always run the fast headless suite before exporting:

```powershell
.\tools\godot.cmd --headless -s tests/run_tests_fast.gd
```

## 2. Windows Desktop Export

Export the Windows Desktop preset defined in `export_presets.cfg`:

```powershell
New-Item -ItemType Directory -Force -Path .\build\Windows | Out-Null
.\tools\godot.cmd --headless --export-release "Windows Desktop" .\build\Windows\Okey101.exe
```

Or for the offline trial preset (`trial-offline`):

```powershell
.\tools\godot.cmd --headless --export-release "Windows Desktop Offline" .\build\Windows\Okey101-Offline.exe
```

## 3. Android Debug APK Export (`com.alperen.okey101`)

### Step 3A: Verify Android Toolchain & Keystore
Run the Android environment preflight check (verifies JDK 17, Android SDK, `apksigner`, and Godot export templates):

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check_android_env.ps1
```

### Step 3B: Export Signed Debug APK
Run the Android debug export script:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\export_android_debug.ps1
```

Verify that `permissions/vibrate=true` remains enabled in `export_presets.cfg` so `TableAudioController.gd` tactile haptics function on Android devices.
