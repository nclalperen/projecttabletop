param(
    [string]$ProjectPath = ".",
    [string]$LogDir = "exports/runtime",
    [string]$RunnerScript = "res://tests/run_tests_runtime_eos.gd"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $ProjectPath).Path
$godotCmd = Join-Path $repoRoot "tools\godot.cmd"
if (-not (Test-Path $godotCmd)) {
    throw "Godot wrapper not found: $godotCmd"
}

$resolvedLogDir = $LogDir
if (-not [System.IO.Path]::IsPathRooted($resolvedLogDir)) {
    $resolvedLogDir = Join-Path $repoRoot $resolvedLogDir
}
New-Item -ItemType Directory -Force -Path $resolvedLogDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $resolvedLogDir ("eos_runtime_lane_{0}.log" -f $timestamp)

Write-Output "==> Running EOS runtime lane"
Write-Output "Runner: $RunnerScript"
Write-Output "Log: $logPath"

$process = Start-Process -FilePath $godotCmd -ArgumentList @("--path", $repoRoot, "-s", $RunnerScript) -NoNewWindow -PassThru -RedirectStandardOutput $logPath -RedirectStandardError $logPath
$process.WaitForExit()

Get-Content -Path $logPath

if ($process.ExitCode -ne 0) {
    Write-Output "EOS_RUNTIME_LANE: FAIL"
    exit $process.ExitCode
}

Write-Output "EOS_RUNTIME_LANE: PASS"
exit 0
