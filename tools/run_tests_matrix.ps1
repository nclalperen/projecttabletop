param(
    [string]$GodotExe = "C:\Users\Alperen\Desktop\godot_notnet\Godot_v4.6-stable_win64.exe",
    [string]$ProjectPath = "."
)

$ErrorActionPreference = "Stop"

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
    $tempRel = "tests/_tmp_matrix_$id.gd"
    $tempAbs = Join-Path $RepoPath $tempRel
    $tempRes = "res://$tempRel"

    $runner = @"
extends SceneTree
func _init() -> void:
	var s = load("$TestPath")
	if s == null:
		print("ONE_RESULT|FAIL_LOAD|$TestPath")
		quit()
		return
	var i = s.new()
	var ok = i.run()
	if ok:
		print("ONE_RESULT|PASS|$TestPath")
	else:
		print("ONE_RESULT|FAIL|$TestPath")
	quit()
"@

    Set-Content -Path $tempAbs -Value $runner -Encoding ascii

    $outFile = Join-Path $RepoPath ("tests/_tmp_out_{0}.log" -f $id)
    $errFile = Join-Path $RepoPath ("tests/_tmp_err_{0}.log" -f $id)
    $args = @("--headless", "--path", $RepoPath, "-s", $tempRes)
    $proc = Start-Process -FilePath $ExePath -ArgumentList $args -Wait -NoNewWindow -PassThru -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    $rawText = ""
    if (Test-Path $outFile) { $rawText += (Get-Content -Path $outFile -Raw) }
    if (Test-Path $errFile) { $rawText += "`n" + (Get-Content -Path $errFile -Raw) }
    $matches = [regex]::Matches($rawText, 'ONE_RESULT\|([^|]+)\|([^\r\n]+)')

    # Best effort cleanup with small retry to avoid transient file locks.
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try {
            if (Test-Path $tempAbs) { Remove-Item -Path $tempAbs -Force }
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

    $last = $matches[$matches.Count - 1]
    $status = $last.Groups[1].Value
    $path = $last.Groups[2].Value
    return [PSCustomObject]@{
        Test = $path
        Status = $status
    }
}

$repo = (Resolve-Path $ProjectPath).Path
$runTests = Join-Path $repo "tests/run_tests.gd"

if (-not (Test-Path $GodotExe)) {
    Write-Error "Godot executable not found: $GodotExe"
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
    $results += Invoke-OneTest -TestPath $test -ExePath $GodotExe -RepoPath $repo
}

$failures = $results | Where-Object { $_.Status -ne "PASS" }

Write-Output "TEST_MATRIX_START"
foreach ($r in $results) {
    Write-Output ("{0}|{1}" -f $r.Status, $r.Test)
}
Write-Output "TEST_MATRIX_END"
Write-Output ("TOTAL|{0}" -f $results.Count)
Write-Output ("FAILED|{0}" -f $failures.Count)

if ($failures.Count -gt 0) {
    exit 1
}
exit 0
