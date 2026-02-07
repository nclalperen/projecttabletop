# Tmux Setup for Supervisor/Worker Workflow

## Current Status

✅ **Tmux Session Active**: `project101`
- **Pane 0**: Claude Code CLI (Supervisor) - PID 692
- **Pane 1**: Codex CLI (Worker) - PID 709

## Known Issues & Solutions

### 1. tmux-cli PATH Issue

**Problem**: The `tmux-cli` tool cannot find tmux because it's located at `/c/msys64/usr/bin/tmux` which isn't in the default PATH when Python subprocess calls are made.

**Workaround**: Use direct tmux commands with PATH exported:

```bash
export PATH="/c/msys64/usr/bin:$PATH"
tmux send-keys -t project101:0.1 'your command here' C-m
tmux capture-pane -t project101:0.1 -p
```

### 2. Communicating with Codex

**Current Method**: Direct tmux commands work for sending text to the Codex pane.

```bash
# Send a task to Codex (pane 1)
export PATH="/c/msys64/usr/bin:$PATH"
tmux send-keys -t project101:0.1 'Task description for Codex' C-m

# Wait for Codex to process (adjust sleep time as needed)
sleep 5

# Capture Codex output
tmux capture-pane -t project101:0.1 -p -S -50
```

### 3. Pane Targeting

- Current session: `project101`
- Window: `0` (named "dev")
- Panes: `0` (Claude/supervisor), `1` (Codex/worker)

**Target format**: `project101:0.1` (session:window.pane)

## Helper Scripts

### tools/tmux_wrapper.sh
Wrapper script that ensures tmux is in PATH:

```bash
#!/usr/bin/env bash
export PATH="/c/msys64/usr/bin:$PATH"
exec "$@"
```

## Recommended Workflow

1. **Supervisor (Claude)** receives task from user
2. **Supervisor** delegates implementation to worker using:
   ```bash
   export PATH="/c/msys64/usr/bin:$PATH"
   tmux send-keys -t project101:0.1 "Implement feature X" C-m
   ```
3. **Worker (Codex)** implements the task
4. **Supervisor** monitors output:
   ```bash
   tmux capture-pane -t project101:0.1 -p
   ```
5. **Supervisor** reviews changes, runs tests, verifies export

## Definition of Done

Per CLAUDE.md:
- Changes compile/run
- Export succeeds (Windows Desktop preset) OR relevant Godot CLI command succeeds
- No uncommitted junk files; only intended changes

## Future Improvements Needed

- [ ] Fix tmux PATH issue for tmux-cli (possibly add tmux to system PATH or create tmux symlink)
- [ ] Test automated wait_idle functionality
- [ ] Create helper functions for common supervisor/worker patterns