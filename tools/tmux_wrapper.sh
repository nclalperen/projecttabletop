#!/usr/bin/env bash
# Wrapper to ensure tmux is in PATH for tmux-cli commands
export PATH="/c/msys64/usr/bin:$PATH"
exec "$@"