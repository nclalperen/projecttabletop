param(
    [string]$ProjectPath = ".",
    [string]$LogDir = "exports/runtime",
    [string]$RunnerScript = "res://tests/run_tests_runtime_eos.gd"
)

$ErrorActionPreference = "Stop"

function Get-MissingRuntimeEnv {
    $required = @(
        "EOS_PRODUCT_NAME",
        "EOS_PRODUCT_VERSION",
        "EOS_PRODUCT_ID",
        "EOS_SANDBOX_ID",
        "EOS_DEPLOYMENT_ID",
        "EOS_CLIENT_ID",
        "EOS_CLIENT_SECRET",
        "EOS_DEV_AUTH_HOST"
    )
    $missing = @()
    foreach ($key in $required) {
        $value = [Environment]::GetEnvironmentVariable($key)
        if ([string]::IsNullOrWhiteSpace($value)) {
            $missing += $key
        }
    }
    return $missing
}

$repoRoot = (Resolve-Path $ProjectPath).Path
$godotCmd = Join-Path $repoRoot "tools\godot.cmd"
if (-not (Test-Path $godotCmd)) {
    throw "Godot wrapper not found: $godotCmd"
}

$missingEnv = Get-MissingRuntimeEnv
if ($missingEnv.Count -gt 0) {
    Write-Output "EOS_RUNTIME_LANE: BLOCKED_ENV_MISSING"
    Write-Output ("MISSING_ENV_KEYS: {0}" -f ($missingEnv -join ", "))
    exit 2
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
