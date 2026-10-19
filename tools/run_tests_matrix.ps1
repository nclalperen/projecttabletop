param(
    [string]$GodotExe = ".\tools\godot.cmd",
    [string]$ProjectPath = ".",
    [switch]$IncludeSceneSmoke,
    [bool]$IncludeRuntimeLane = $true
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

function Get-TestScripts {
    param([string]$RunTestsPath)
    $lines = Get-Content -Path $RunTestsPath
    $tests = @()
    foreach ($line in $lines) {
        if ($line -match '"(res://tests/[^"]+\.gd)"') {
            $tests += $matches[1]
        }
    }
    return $tests
}

function Invoke-OneTest {
    param(
        [string]$TestPath,
        [string]$ExePath,
        [string]$RepoPath
    )

    $id = [guid]::NewGuid().ToString("N")
    $outFile = Join-Path ([System.IO.Path]::GetTempPath()) ("okey_matrix_out_{0}.log" -f $id)
    $errFile = Join-Path ([System.IO.Path]::GetTempPath()) ("okey_matrix_err_{0}.log" -f $id)
    $engineArgs = @("--headless", "--path", $RepoPath, "-s", "res://tests/run_single_test.gd", "--", "--test=$TestPath")
    $quotedArgs = $engineArgs | ForEach-Object { '"' + $_ + '"' }
    $proc = Start-Process -FilePath $ExePath -ArgumentList $quotedArgs -Wait -WindowStyle Hidden -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $rawText = ""
    if (Test-Path $outFile) { $rawText += (Get-Content -Path $outFile -Raw) }
    if (Test-Path $errFile) { $rawText += "`n" + (Get-Content -Path $errFile -Raw) }
    $matches = [regex]::Matches($rawText, 'ONE_RESULT\|([^|]+)\|([^\r\n]+)')

    # Best effort cleanup with small retry to avoid transient file locks.
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            if (Test-Path $outFile) { Remove-Item -Path $outFile -Force }
            if (Test-Path $errFile) { Remove-Item -Path $errFile -Force }
            break
        } catch {
            Start-Sleep -Milliseconds 120
        }
    }

    if ($matches.Count -eq 0) {
        return [PSCustomObject]@{
            Test = $TestPath
            Status = "FAIL_NO_OUTPUT"
        }
    }

    if ($proc.ExitCode -ne 0 -or $matches.Count -ne 1 -or $rawText -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
        Write-Host $rawText
        return [PSCustomObject]@{ Test = $TestPath; Status = "FAIL" }
    }
    $last = $matches[$matches.Count - 1]
    $status = $last.Groups[1].Value
    $path = $last.Groups[2].Value
    return [PSCustomObject]@{
        Test = $path
        Status = $status
    }
}

function Invoke-Probe {
    param(
        [string]$ProbePath,
        [string]$ExePath,
        [string]$RepoPath
    )

    $id = [guid]::NewGuid().ToString("N")
    $outFile = Join-Path ([System.IO.Path]::GetTempPath()) ("okey_smoke_out_$id.log")
    $errFile = Join-Path ([System.IO.Path]::GetTempPath()) ("okey_smoke_err_$id.log")
    $engineArgs = @("--headless", "--path", $RepoPath, "--scene", $ProbePath, "--quit-after", "120")
    $quotedArgs = $engineArgs | ForEach-Object { '"' + $_ + '"' }
    try {
        $proc = Start-Process -FilePath $ExePath -ArgumentList $quotedArgs -Wait -WindowStyle Hidden -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        $rawText = [System.IO.File]::ReadAllText($outFile) + "`n" + [System.IO.File]::ReadAllText($errFile)
        $status = "FAIL"
        if ($proc.ExitCode -eq 0 -and $rawText -notmatch '(?m)^(SCRIPT ERROR:|ERROR:)') {
            $status = "PASS"
        } else {
            Write-Host $rawText
        }
        return [PSCustomObject]@{ Test = $ProbePath; Status = $status }
    } finally {
        foreach ($logPath in @($outFile, $errFile)) {
            if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
        }
    }
}

function Invoke-RuntimeLane {
    param(
        [string]$RepoPath
    )

    $missing = Get-MissingRuntimeEnv
    if ($missing.Count -gt 0) {
        return [PSCustomObject]@{
            Test = "tools/run_eos_runtime_lane.ps1"
            Status = "BLOCKED_ENV_MISSING"
            ExitCode = 2
            Note = ("missing_env={0}" -f ($missing -join ","))
        }
    }

    $runnerPath = Join-Path $RepoPath "tools\run_eos_runtime_lane.ps1"
    if (-not (Test-Path $runnerPath)) {
        return [PSCustomObject]@{
            Test = "tools/run_eos_runtime_lane.ps1"
            Status = "FAIL"
            ExitCode = 1
            Note = "runner_missing"
        }
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $runnerPath -ProjectPath $RepoPath | Out-Host
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        return [PSCustomObject]@{
            Test = "tools/run_eos_runtime_lane.ps1"
            Status = "PASS"
            ExitCode = 0
            Note = ""
        }
    }
    if ($exitCode -eq 2) {
        return [PSCustomObject]@{
            Test = "tools/run_eos_runtime_lane.ps1"
            Status = "BLOCKED_ENV_MISSING"
            ExitCode = 2
            Note = "blocked_by_runtime_lane"
        }
    }
    return [PSCustomObject]@{
        Test = "tools/run_eos_runtime_lane.ps1"
        Status = "FAIL"
        ExitCode = $exitCode
        Note = ("runtime_exit={0}" -f $exitCode)
    }
}

$repo = (Resolve-Path $ProjectPath).Path
$runTests = Join-Path $repo "tests/run_tests.gd"
$resolvedGodotExe = $GodotExe
if (-not [System.IO.Path]::IsPathRooted($resolvedGodotExe)) {
    $resolvedGodotExe = Join-Path $repo $resolvedGodotExe
}

if (-not (Test-Path $resolvedGodotExe)) {
    Write-Error "Godot executable not found: $resolvedGodotExe"
}
if (-not (Test-Path $runTests)) {
    Write-Error "run_tests.gd not found: $runTests"
}

$tests = Get-TestScripts -RunTestsPath $runTests
if ($tests.Count -eq 0) {
    Write-Error "No tests discovered in tests/run_tests.gd"
}

$results = @()
foreach ($test in $tests) {
    $results += Invoke-OneTest -TestPath $test -ExePath $resolvedGodotExe -RepoPath $repo
}

if ($IncludeSceneSmoke) {
    $probeScripts = @(
        "res://ui/vector_table/VectorGameTable3D.tscn"
    )
    foreach ($probe in $probeScripts) {
        $results += Invoke-Probe -ProbePath $probe -ExePath $resolvedGodotExe -RepoPath $repo
    }
}

$runtimeResult = $null
if ($IncludeRuntimeLane) {
    $runtimeResult = Invoke-RuntimeLane -RepoPath $repo
    $results += $runtimeResult
}

$failures = $results | Where-Object { $_.Status -eq "FAIL" -or $_.Status -eq "FAIL_LOAD" -or $_.Status -eq "FAIL_NO_OUTPUT" }
$blocked = $results | Where-Object { $_.Status -eq "BLOCKED_ENV_MISSING" }

Write-Output "TEST_MATRIX_START"
foreach ($r in $results) {
    if ($r.PSObject.Properties.Name -contains "Note" -and -not [string]::IsNullOrWhiteSpace([string]$r.Note)) {
        Write-Output ("{0}|{1}|{2}" -f $r.Status, $r.Test, $r.Note)
    } else {
        Write-Output ("{0}|{1}" -f $r.Status, $r.Test)
    }
}
Write-Output "TEST_MATRIX_END"
Write-Output ("TOTAL|{0}" -f $results.Count)
Write-Output ("FAILED|{0}" -f $failures.Count)
Write-Output ("BLOCKED|{0}" -f $blocked.Count)

if ($failures.Count -gt 0) {
    exit 1
}
if ($blocked.Count -gt 0) {
    exit 2
}
exit 0
