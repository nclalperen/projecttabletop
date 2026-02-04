# Developer Notes

## Headless Tests
Run tests in headless mode:

```bash
godot --headless -s res://tests/run_tests.gd
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
