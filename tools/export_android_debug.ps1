param(
    [string]$ProjectPath = ".",
    [string]$PresetName = "Android",
    [string]$OutputApk = "exports/android/project101-debug.apk"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $ProjectPath).Path
$godotCmd = Join-Path $repoRoot "tools\godot.cmd"
$envCheckScript = Join-Path $repoRoot "tools\check_android_env.ps1"

if (-not (Test-Path $godotCmd)) {
    throw "Godot wrapper not found: $godotCmd"
}
if (-not (Test-Path $envCheckScript)) {
    throw "Android env check script not found: $envCheckScript"
}

$outputPath = $OutputApk
if (-not [System.IO.Path]::IsPathRooted($outputPath)) {
    $outputPath = Join-Path $repoRoot $outputPath
}
$outputDir = Split-Path -Path $outputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

Write-Output "==> Android env check"
& powershell -NoProfile -ExecutionPolicy Bypass -File $envCheckScript
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "==> Parse check"
& $godotCmd --headless --path $repoRoot --quit
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "==> Full test suite"
& $godotCmd --headless --path $repoRoot -s res://tests/run_tests.gd
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "==> Export debug APK"
& $godotCmd --headless --path $repoRoot --export-debug $PresetName $outputPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Output "ANDROID_EXPORT_DEBUG: PASS"
Write-Output "APK: $outputPath"
exit 0
