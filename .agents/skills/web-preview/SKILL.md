---
name: web-preview
description: Export Godot 4.6/4.7 HTML5/WebAssembly build, run the local COOP/COEP HTTP preview server (tools/serve_web.py), and test via browser automation. Trigger via /web-preview.
---

# Web Preview & Browser Testing Workflow (`/web-preview`)

Use this skill to build, locally serve, and verify the Web/HTML5 export of Okey 101 and the Tabletop Hub.

## 1. Export Web Build (Headless)

Ensure Godot 4.6/4.7 Web export templates are available:

```powershell
New-Item -ItemType Directory -Force -Path .\build\web | Out-Null
.\tools\godot.cmd --headless --export-debug "Web" .\build\web\index.html
```

## 2. Launch Local COOP/COEP Preview Server

Browsers block WebAssembly and `.pck` assets when loaded from `file://` and require Cross-Origin Isolation headers:

```powershell
python .\tools\serve_web.py --port 8080 --directory build/web
```

The server binds to `http://127.0.0.1:8080/` and provides:
- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`
- `Cache-Control: no-store, no-cache, must-revalidate`
- Strict MIME types (`application/wasm` for `.wasm`, `application/octet-stream` for `.pck`)

## 3. Verify via Browser Subagent

Use the `browser` subagent to open `http://127.0.0.1:8080/` and inspect:
1. **Console errors**: Verify zero WebGL shader compilation or WebAudio initialization failures.
2. **Telemetry**: Check `window.__tabletopDebug` exposed by `WebDebugBridge.gd`.
3. **Multi-client**: Open multiple browser tabs to simulate 2-4 seated players.
