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
$fallback = if ($mode -eq "dotnet") {
    "C:\Users\Alperen\Desktop\godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64.exe"
} else {
    "C:\Users\Alperen\Desktop\godot_notnet\Godot_v4.6-stable_win64.exe"
}

$exePath = [Environment]::GetEnvironmentVariable($envVar, "Process")
if ([string]::IsNullOrWhiteSpace($exePath)) {
    $exePath = [Environment]::GetEnvironmentVariable($envVar, "User")
}
if ([string]::IsNullOrWhiteSpace($exePath)) {
    $exePath = Read-ExeFromPathsFile $keyName
}
if ([string]::IsNullOrWhiteSpace($exePath)) {
    $exePath = $fallback
}
$exePath = Convert-MsysPathToWindows $exePath

if (!(Test-Path $exePath)) {
    Write-Error "Godot executable not found for mode '$mode': $exePath"
}

& $exePath @CliArgs
exit $LASTEXITCODE
