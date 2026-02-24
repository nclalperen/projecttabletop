# EOS Runtime Setup (Policy-Driven, Account Portal First)

This project uses a centralized backend policy with three modes:

- `mock_allowed`: editor/dev default, deterministic local workflow.
- `runtime_preferred`: exported debug/internal QA default, attempt EOS runtime and fallback to mock if unavailable.
- `runtime_required`: release/public gate, runtime must initialize (no silent mock fallback).

Policy override env var:

```powershell
$env:PROJECT101_EOS_BACKEND_POLICY="runtime_preferred"  # or mock_allowed / runtime_required
```

Legacy compatibility override still works:

```powershell
$env:PROJECT101_EOS_RUNTIME="1"  # implies runtime_preferred
```

## 1) Prerequisites
- Windows desktop for current runtime lane automation.
- `addons/epic-online-services-godot` present and plugin enabled in `project.godot`.
- Not headless for runtime login/lobby tests.
- EOS credentials configured for your deployment.

## 2) Required Environment Variables
Set before launching runtime lane commands:

```powershell
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
$env:PROJECT101_BUILD_FAMILY="dev"
```

Runtime lane currently uses internal DevAuth helper credentials for automation:

```powershell
$env:EOS_DEV_AUTH_HOST="localhost:4545"
$env:EOS_DEV_AUTH_CREDENTIAL_HOST="dev_host"
$env:EOS_DEV_AUTH_CREDENTIAL_CLIENT="dev_client"
```

Runtime lane preflight is strict:

- If required env vars are missing, `tools/run_eos_runtime_lane.ps1` prints `EOS_RUNTIME_LANE: BLOCKED_ENV_MISSING` and exits with code `2`.
- This is a deliberate non-green status (not a pass, not a false fallback).

## 3) Authentication Modes
- App UI path defaults to **Account Portal** (`OnlineLobby` login button).
- DevAuth remains available as internal helper for runtime automation and integration debugging.

## 4) Test Lanes
### Core deterministic lane (headless)

```powershell
./tools/godot.cmd --headless --path . --quit
./tools/godot.cmd --headless --path . -s res://tests/run_tests.gd
```

### Runtime EOS lane (non-headless)

```powershell
./tools/run_eos_runtime_lane.ps1
```

Expected lane outcomes:

- `EOS_RUNTIME_LANE: PASS` (exit `0`)
- `EOS_RUNTIME_LANE: FAIL` (non-zero fail code)
- `EOS_RUNTIME_LANE: BLOCKED_ENV_MISSING` (exit `2`)

Runner script: `res://tests/run_tests_runtime_eos.gd`

What it validates:
- runtime init on host/client services,
- login,
- lobby create/join,
- ready convergence,
- match-start attr publish (`phase = MATCH_STARTING`).

## 5) Windows <-> Android Crossplay Checklist (Manual)
1. Export/install Android debug build with same `build_family` and protocol version as Windows build.
2. On both devices, login to EOS (Account Portal path preferred).
3. Host on Windows creates lobby.
4. Android client discovers/joins lobby.
5. Verify both clients show each other in roster with expected platform markers.
6. Ready all players and start match.
7. Confirm initial snapshot arrives and table opens on both devices.

## 6) Release Gate (Deferred No-Mock Cutover)
Before public release, set production lane to `runtime_required` and verify:
- no silent fallback to mock in runtime app paths,
- startup fails clearly if EOS runtime is unavailable,
- runtime lane is green on supported platforms.
