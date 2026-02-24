param(
    [string]$EditorSettingsPath = ""
)

$ErrorActionPreference = "Stop"

function Get-DefaultEditorSettingsPath {
    $candidates = @(
        (Join-Path $env:APPDATA "Godot\editor_settings-4.6.tres"),
        (Join-Path $env:APPDATA "Godot\editor_settings-4.5.tres"),
        (Join-Path $env:APPDATA "Godot\editor_settings-4.tres"),
        (Join-Path $env:APPDATA "Godot\editor_settings.tres")
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }
    return ""
}

function Get-TresStringValue {
    param(
        [string]$Text,
        [string]$Key
    )

    $escaped = [Regex]::Escape($Key)
    $pattern = '(?m)^' + $escaped + '\s*=\s*"([^"]*)"'
    $match = [Regex]::Match($Text, $pattern)
    if (-not $match.Success) {
        return ""
    }
    $value = $match.Groups[1].Value
    return $value -replace '\\\\', '\\'
}

function Add-Issue {
    param(
        [ref]$Issues,
        [string]$Message
    )
    $Issues.Value += $Message
}

if ([string]::IsNullOrWhiteSpace($EditorSettingsPath)) {
    $EditorSettingsPath = Get-DefaultEditorSettingsPath
}

$issues = @()
if ([string]::IsNullOrWhiteSpace($EditorSettingsPath)) {
    Add-Issue ([ref]$issues) "Could not locate Godot editor settings file under %APPDATA%\\Godot."
} elseif (-not (Test-Path $EditorSettingsPath)) {
    Add-Issue ([ref]$issues) "Editor settings file does not exist: $EditorSettingsPath"
}

$settingsText = ""
if ($issues.Count -eq 0) {
    $settingsText = Get-Content -Path $EditorSettingsPath -Raw
}

$javaSdkPath = ""
$androidSdkPath = ""
if ($settingsText -ne "") {
    $javaSdkPath = Get-TresStringValue -Text $settingsText -Key "export/android/java_sdk_path"
    $androidSdkPath = Get-TresStringValue -Text $settingsText -Key "export/android/android_sdk_path"
}

if ([string]::IsNullOrWhiteSpace($javaSdkPath)) {
    Add-Issue ([ref]$issues) "Missing export/android/java_sdk_path in editor settings."
} elseif (-not (Test-Path $javaSdkPath)) {
    Add-Issue ([ref]$issues) "Java SDK path does not exist: $javaSdkPath"
} else {
    $javaExe = Join-Path $javaSdkPath "bin\java.exe"
    $javacExe = Join-Path $javaSdkPath "bin\javac.exe"
    if (-not (Test-Path $javaExe)) {
        Add-Issue ([ref]$issues) "Java SDK missing java.exe: $javaExe"
    }
    if (-not (Test-Path $javacExe)) {
        Add-Issue ([ref]$issues) "Java SDK missing javac.exe: $javacExe"
    }
}

if ([string]::IsNullOrWhiteSpace($androidSdkPath)) {
    Add-Issue ([ref]$issues) "Missing export/android/android_sdk_path in editor settings."
} elseif (-not (Test-Path $androidSdkPath)) {
    Add-Issue ([ref]$issues) "Android SDK path does not exist: $androidSdkPath"
} else {
    $platformTools = Join-Path $androidSdkPath "platform-tools"
    $adbExe = Join-Path $platformTools "adb.exe"
    if (-not (Test-Path $platformTools)) {
        Add-Issue ([ref]$issues) "Android SDK missing platform-tools directory: $platformTools"
    } elseif (-not (Test-Path $adbExe)) {
        Add-Issue ([ref]$issues) "Android SDK missing adb executable: $adbExe"
    }

    $buildToolsRoot = Join-Path $androidSdkPath "build-tools"
    if (-not (Test-Path $buildToolsRoot)) {
        Add-Issue ([ref]$issues) "Android SDK missing build-tools directory: $buildToolsRoot"
    } else {
        $buildToolDirs = Get-ChildItem -Path $buildToolsRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($buildToolDirs.Count -eq 0) {
            Add-Issue ([ref]$issues) "Android SDK build-tools has no installed versions: $buildToolsRoot"
        } else {
            $apksignerFound = $false
            foreach ($dir in $buildToolDirs) {
                $candidateBat = Join-Path $dir.FullName "apksigner.bat"
                $candidateExe = Join-Path $dir.FullName "apksigner.exe"
                if ((Test-Path $candidateBat) -or (Test-Path $candidateExe)) {
                    $apksignerFound = $true
                    break
                }
            }
            if (-not $apksignerFound) {
                Add-Issue ([ref]$issues) "Android SDK build-tools missing apksigner(.bat/.exe) in installed versions under: $buildToolsRoot"
            }
        }
    }
}

if ($issues.Count -gt 0) {
    Write-Output "ANDROID_ENV_CHECK: FAIL"
    Write-Output "EditorSettings: $EditorSettingsPath"
    foreach ($issue in $issues) {
        Write-Output " - $issue"
    }
    exit 1
}

Write-Output "ANDROID_ENV_CHECK: PASS"
Write-Output "EditorSettings: $EditorSettingsPath"
Write-Output "Java SDK: $javaSdkPath"
Write-Output "Android SDK: $androidSdkPath"
exit 0
