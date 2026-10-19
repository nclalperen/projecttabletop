param(
    [ValidateRange(0, 120)][int]$DurationSec = 1,
    [ValidateSet("opening", "midgame", "crowded", "after_discard", "dragging", "results")]
    [string]$Fixture = "opening",
    [string]$Resolution = "1920x1080",
    [string]$CaptureProjectRelPath = "dev/qa",
    [string]$GodotExe = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$launcher = if ([string]::IsNullOrWhiteSpace($GodotExe)) { Join-Path $PSScriptRoot "godot.cmd" } else { $GodotExe }
$captureDir = if ([System.IO.Path]::IsPathRooted($CaptureProjectRelPath)) { $CaptureProjectRelPath } else { Join-Path $projectRoot $CaptureProjectRelPath }

$expectedCapture = Join-Path $captureDir "$Fixture-$Resolution.png"
$previousWrite = if (Test-Path -LiteralPath $expectedCapture) { (Get-Item -LiteralPath $expectedCapture).LastWriteTimeUtc } else { $null }
# Vector captures use the existing deterministic fixture harness.
& $launcher --path $projectRoot -s res://tests/qa_vector3d.gd -- "--qa-dir=$captureDir" "--qa-fixture=$Fixture" "--qa-size=$Resolution" "--qa-delay=$DurationSec"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not (Test-Path -LiteralPath $expectedCapture)) { throw "Vector capture did not produce $expectedCapture" }
$capture = Get-Item -LiteralPath $expectedCapture
if ($capture.Length -eq 0 -or ($null -ne $previousWrite -and $capture.LastWriteTimeUtc -le $previousWrite)) {
    throw "Vector capture did not update $expectedCapture"
}
$capture | Select-Object FullName, LastWriteTime
exit 0
