$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot "godot.cmd") --path $RepoRoot --resolution 1920x1080 res://ui/vector_table/VectorGameTable3D.tscn -- --layout-studio
exit $LASTEXITCODE
