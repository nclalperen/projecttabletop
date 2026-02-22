param(
    [int]$DurationSec = 70,
    [string]$ScenePath = "res://ui/GameTable3D.tscn",
    [string]$CaptureProjectRelPath = "ai agent docs/screenshots/auto",
    [string]$GodotExe = "",
    [int]$TargetFps = 120,
    [switch]$KeepOpen,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraGodotArgs
)

$ErrorActionPreference = "Stop"

if ($DurationSec -lt 5) {
    throw "DurationSec must be at least 5 seconds."
}
if ($TargetFps -lt 1) {
    throw "TargetFps must be >= 1."
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotCmd = Join-Path $PSScriptRoot "godot.cmd"

function Resolve-GodotLauncher([string]$WrapperPath, [string]$PreferredExe) {
    if (![string]::IsNullOrWhiteSpace($PreferredExe)) {
        $candidate = $PreferredExe.Trim('"')
        if (Test-Path $candidate) {
            return $candidate
        }
        throw "Provided GodotExe does not exist: $candidate"
    }

    if (Test-Path $WrapperPath) {
        $wrapperOk = $false
        try {
            & $WrapperPath --version *> $null
            $wrapperOk = ($LASTEXITCODE -eq 0)
        } catch {
            $wrapperOk = $false
        }
        if ($wrapperOk) {
            return $WrapperPath
        }
        Write-Host "[capture] Wrapper failed health check, falling back to direct exe search."
    }

    $candidates = @()
    foreach ($scope in @("Process", "User", "Machine")) {
        $envPath = [Environment]::GetEnvironmentVariable("GODOT_EXE", $scope)
        if (![string]::IsNullOrWhiteSpace($envPath)) {
            $candidates += $envPath.Trim('"')
        }
    }

    $commonDirs = @(
        (Join-Path $env:USERPROFILE "OneDrive\Desktop\Godot"),
        (Join-Path $env:USERPROFILE "Desktop\Godot"),
        (Join-Path $env:USERPROFILE "Desktop")
    )
    foreach ($dir in $commonDirs) {
        if (!(Test-Path $dir)) {
            continue
        }
        $found = Get-ChildItem -Path $dir -Filter "Godot*.exe" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        foreach ($f in $found) {
            $candidates += $f.FullName
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }
    throw "Could not resolve a working Godot executable. Set -GodotExe or GODOT_EXE."
}
$godotLauncher = Resolve-GodotLauncher $godotCmd $GodotExe
$launcherName = [System.IO.Path]::GetFileName($godotLauncher)
$usingWrapper = $launcherName.ToLowerInvariant().EndsWith(".cmd")
$captureDir = Join-Path $projectRoot $CaptureProjectRelPath
$beforeLatestUtc = $null
if (Test-Path $captureDir) {
    $beforeLatest = Get-ChildItem -Path $captureDir -Filter "*.png" -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($beforeLatest -ne $null) {
        $beforeLatestUtc = $beforeLatest.LastWriteTimeUtc
    }
}

$argList = @("--path", $projectRoot)
if (![string]::IsNullOrWhiteSpace($ScenePath)) {
    $argList += @("--scene", $ScenePath)
}
if ($ExtraGodotArgs -and $ExtraGodotArgs.Count -gt 0) {
    $argList += $ExtraGodotArgs
}

Write-Host "[capture] Launching GameTable3D..."
Write-Host ("[capture] Launcher={0}" -f $godotLauncher)
if ($usingWrapper) {
    Write-Host "[capture] Using tools/godot.cmd wrapper."
} else {
    Write-Host "[capture] Using direct Godot executable fallback."
}
if ($KeepOpen) {
    Write-Host "[capture] KeepOpen enabled: run until you close the Godot window."
} else {
    Write-Host ("[capture] Target capture window: {0}s" -f $DurationSec)
    $quitAfterFrames = [Math]::Max(1, [int]($DurationSec * $TargetFps))
    $argList += @("--quit-after", $quitAfterFrames)
    Write-Host ("[capture] Using --quit-after {0} frames (~{1}s at {2} FPS)." -f $quitAfterFrames, $DurationSec, $TargetFps)
}
& $godotLauncher @argList
$godotExitCode = $LASTEXITCODE
Write-Host ("[capture] Godot exited with code {0}." -f $godotExitCode)

if (!(Test-Path $captureDir)) {
    Write-Host "[capture] Capture directory not found:"
    Write-Host ("          {0}" -f $captureDir)
    exit 0
}

if ($beforeLatestUtc -ne $null) {
    $newCaptures = Get-ChildItem -Path $captureDir -Filter "*.png" -File |
        Where-Object { $_.LastWriteTimeUtc -gt $beforeLatestUtc } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 8 Name, LastWriteTime
    if (@($newCaptures).Count -gt 0) {
        Write-Host "[capture] New captures from this run:"
        $newCaptures | Format-Table -AutoSize
        exit 0
    }
}

Write-Host "[capture] No new captures detected in this run."
$latest = Get-ChildItem -Path $captureDir -Filter "*.png" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 8 Name, LastWriteTime
if (@($latest).Count -eq 0) {
    Write-Host "[capture] No PNG captures found in:"
    Write-Host ("          {0}" -f $captureDir)
    Write-Host "[capture] Note: auto-capture is available in debug builds and defaults to every 20s."
    exit 0
}

Write-Host "[capture] Latest captures:"
$latest | Format-Table -AutoSize
