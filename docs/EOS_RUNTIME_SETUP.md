# EOS Runtime Setup (Windows Dev-Auth)

This project keeps EOS runtime **opt-in** and mock-safe by default.

## 1) Prerequisites
- Windows desktop.
- `addons/epic-online-services-godot` present and plugin enabled in `project.godot`.
- EOS Developer Authentication Tool running (default endpoint: `localhost:4545`).
- Not headless for runtime smoke/login.

## 2) Required Environment Variables
Set these in your shell before launching Godot:

```powershell
$env:PROJECT101_EOS_RUNTIME="1"
$env:EOS_PRODUCT_NAME="project101"
$env:EOS_PRODUCT_VERSION="0.1.0"
$env:EOS_PRODUCT_ID="<product-id>"
$env:EOS_SANDBOX_ID="<sandbox-id>"
$env:EOS_DEPLOYMENT_ID="<deployment-id>"
$env:EOS_CLIENT_ID="<client-id>"
$env:EOS_CLIENT_SECRET="<client-secret>"
```

Optional:

```powershell
$env:EOS_ENCRYPTION_KEY="<64-hex-chars>"
$env:EOS_DEV_AUTH_HOST="localhost:4545"
$env:EOS_DEV_AUTH_CREDENTIAL="dev_player"
```

## 3) Runtime Behavior
- If runtime init/login fails, services downgrade to `mock` backend and stay usable.
- Offline flow remains unchanged.
- Runtime path is guarded off in headless mode.

## 4) Known Limitation
- On this machine, EOS extension teardown can occasionally crash on shutdown.
- This is treated as an external baseline; test gates remain mock/headless-safe.

## 5) Verification Commands
Fast gate:

```powershell
./tools/godot.cmd --headless --path . --quit
./tools/godot.cmd --headless --path . -s res://tests/run_tests_fast.gd
./tools/godot.cmd --headless --path . -s res://tests/_tmp_probe_round_click.gd
./tools/godot.cmd --headless --path . -s res://tests/probe_gametable3d_interaction_matrix.gd
```

Long/full gate:

```powershell
./tools/godot.cmd --headless --path . -s res://tests/run_tests.gd
```

Manual runtime smoke (non-headless, EOS env configured):

```powershell
./tools/godot.cmd --path . -s res://tests/eos_runtime_smoke.gd
```
