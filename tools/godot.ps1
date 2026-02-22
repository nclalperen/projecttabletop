param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = "Stop"

function Convert-MsysPathToWindows([string]$PathValue) {
    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $PathValue
    }
    $trimmed = $PathValue.Trim()
    if ($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) {
        $trimmed = $trimmed.Substring(1, $trimmed.Length - 2)
    }
    if ($trimmed -match '^/([A-Za-z])/(.*)$') {
        $drive = $matches[1].ToUpper()
        $tail = $matches[2] -replace '/', '\'
        return "$drive`:\$tail"
    }
    return $trimmed
}

function Read-ExeFromPathsFile([string]$KeyName) {
    $pathsFile = Join-Path $PSScriptRoot "godot_paths.sh"
    if (!(Test-Path $pathsFile)) {
        return ""
    }
    foreach ($line in (Get-Content -Path $pathsFile)) {
        if ($line -match "^\s*$KeyName\s*=\s*(.+)\s*$") {
            return Convert-MsysPathToWindows $matches[1]
        }
    }
    return ""
}

function Add-Candidate([System.Collections.Generic.List[string]]$ListRef, [string]$PathValue) {
    $candidate = Convert-MsysPathToWindows $PathValue
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        return
    }
    $trimmed = $candidate.Trim('"')
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        return
    }
    if (-not $ListRef.Contains($trimmed)) {
        $null = $ListRef.Add($trimmed)
    }
}

function Search-GodotInDir([string]$DirPath, [string[]]$Patterns) {
    $results = @()
    if ([string]::IsNullOrWhiteSpace($DirPath) -or !(Test-Path $DirPath)) {
        return $results
    }
    foreach ($pattern in $Patterns) {
        try {
            $found = Get-ChildItem -Path $DirPath -Filter $pattern -File -Recurse -Depth 3 -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending
            foreach ($f in $found) {
                $results += $f.FullName
            }
        } catch {
            # Best-effort discovery only.
        }
    }
    return $results
}

function Resolve-GodotExe([string]$Mode, [string]$EnvVar, [string]$KeyName, [string[]]$HardFallbacks) {
    $candidates = New-Object 'System.Collections.Generic.List[string]'

    foreach ($scope in @("Process", "User", "Machine")) {
        Add-Candidate $candidates ([Environment]::GetEnvironmentVariable($EnvVar, $scope))
    }
    Add-Candidate $candidates (Read-ExeFromPathsFile $KeyName)

    $commonDirs = @(
        (Join-Path $env:USERPROFILE "OneDrive\Desktop\Godot"),
        (Join-Path $env:USERPROFILE "Desktop\Godot"),
        (Join-Path $env:USERPROFILE "Desktop"),
        "C:\Godot"
    )
    $patterns = if ($Mode -eq "dotnet") {
        @("*mono*console*.exe", "*mono*.exe", "Godot*.exe")
    } else {
        @("Godot*console*.exe", "Godot*win64*.exe", "Godot*.exe")
    }
    foreach ($dir in $commonDirs) {
        $found = Search-GodotInDir $dir $patterns
        foreach ($path in $found) {
            Add-Candidate $candidates $path
        }
    }

    foreach ($fallback in $HardFallbacks) {
        Add-Candidate $candidates $fallback
    }

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }

    $attempted = ($candidates | Select-Object -First 10) -join "; "
    if ([string]::IsNullOrWhiteSpace($attempted)) {
        $attempted = "<none>"
    }
    throw "Godot executable not found for mode '$Mode'. Tried: $attempted"
}

$mode = "standard"
if ($CliArgs.Count -gt 0 -and $CliArgs[0].ToLowerInvariant() -eq "dotnet") {
    $mode = "dotnet"
    if ($CliArgs.Count -gt 1) {
        $CliArgs = $CliArgs[1..($CliArgs.Count - 1)]
    } else {
        $CliArgs = @()
    }
}

$envVar = if ($mode -eq "dotnet") { "GODOT_DOTNET_EXE" } else { "GODOT_EXE" }
$keyName = if ($mode -eq "dotnet") { "GODOT_DOTNET_EXE" } else { "GODOT_EXE" }
$hardFallbacks = if ($mode -eq "dotnet") {
    @(
        "C:\Users\Alperen\Desktop\godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe",
        "C:\Godot\Godot_v4.5.1-stable_mono_win64_console.exe",
        "C:\Godot\Godot_v4.5.1-stable_mono_win64.exe"
    )
} else {
    @(
        "C:\Users\Alperen\Desktop\godot_notnet\Godot_v4.6-stable_win64.exe",
        "C:\Users\blade16\OneDrive\Desktop\Godot\Godot_v4.6.1-stable_win64_console.exe",
        "C:\Users\blade16\OneDrive\Desktop\Godot\Godot_v4.6.1-stable_win64.exe"
    )
}

$exePath = Resolve-GodotExe $mode $envVar $keyName $hardFallbacks

& $exePath @CliArgs
exit $LASTEXITCODE
