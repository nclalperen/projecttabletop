#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Change preset name if yours differs
PRESET="Windows Desktop"
OUT="build/game.exe"

mkdir -p build

# Use dotnet build if this project uses C# (common case if you installed Godot.NET)
./tools/godot dotnet --headless --path . --export-release "$PRESET" "$OUT"
echo "Exported -> $OUT"
