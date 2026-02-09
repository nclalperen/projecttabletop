# Project workflow (tmux supervisor/worker)

This repo is developed with:
- Supervisor: Claude Code CLI (tmux pane 1)
- Worker: Codex CLI (tmux pane 2)

Rules:
- Implementation work is delegated to Codex.
- Supervisor reviews diffs + test/export output.
- Prefer running Godot via repo wrappers:
  - Standard: ./tools/godot ...
  - .NET/C#:  ./tools/godot dotnet ...
  - Windows PowerShell/CMD: .\tools\godot.cmd ...
  - Export helper: ./tools/export_windows.sh

When coordinating between panes:
- Use /tmux-cli skill (send -> wait_idle -> capture).
- Do NOT use raw tmux send-keys directly.

Definition of Done for tasks:
- Changes compile/run.
- Export succeeds (Windows Desktop preset) OR relevant Godot CLI command succeeds.
- No uncommitted junk files; only intended changes.
