---
name: eos-smoke
description: Verify Epic Online Services (EOS) GDExtension loading, P2P transport, and lobby lifecycle smoke tests. Trigger via /eos-smoke.
---

# EOS Runtime & P2P Smoke Verification (`/eos-smoke`)

Use this skill when modifying `net/EOSManager.gd`, `net/P2PTransportEOS.gd`, `net/LobbyServiceEOS.gd`, or `ui/OnlineLobby.gd`.

## 1. Check IEOS GDExtension Availability

Verify whether the native EOS GDExtension binary loads cleanly in the current environment:

```powershell
.\tools\godot.cmd --headless -s tools/check_eos_gdextension.gd
```

## 2. Run Mock & Contract Network Tests

Verify offline/mock P2P transport, host migration, resync, and lobby state machine contracts:

```powershell
.\tools\godot.cmd --headless -s tests/run_single_test.gd -- --test=res://tests/test_eos_contract.gd
.\tools\godot.cmd --headless -s tests/run_single_test.gd -- --test=res://tests/test_network_lifecycle.gd
.\tools\godot.cmd --headless -s tests/run_single_test.gd -- --test=res://tests/test_p2p_eos_mock.gd
```

## 3. Run Full EOS Runtime Lane

Execute the dedicated EOS runtime lane script:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\run_eos_runtime_lane.ps1
```
