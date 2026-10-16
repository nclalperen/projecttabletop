param(
    [string]$ProjectRoot = 'C:\Users\ncl_a\.codex\worktrees\4e6a\projecttabletop',
    [string]$ExpectedHeadPrefix = '3c788b3a',
    [ValidateSet('all', 'games', 'assets', 'tavla')][string]$Only = 'all'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "Project checkout not found: $ProjectRoot"
}
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$runner = Join-Path $root 'tools\local_ai.ps1'
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) { throw "Local AI runner not found: $runner" }
$gitTop = (& git -C $root rev-parse --show-toplevel | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Not a Git checkout' }
if ([System.IO.Path]::GetFullPath($gitTop).TrimEnd([char[]]@('\', '/')) -ne [System.IO.Path]::GetFullPath($root).TrimEnd([char[]]@('\', '/'))) {
    throw 'Given ProjectRoot is not its own worktree root'
}
$head = (& git -C $root rev-parse HEAD | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $head -notlike "$ExpectedHeadPrefix*") { throw "Unexpected Git HEAD: $head" }
$branch = (& git -C $root branch --show-current | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne '') { throw "Expected detached local AI checkout; branch = $branch" }

$tasks = @(
    @{ id='games'; file='01_game_routes.md'; log='01-game-routes.log' },
    @{ id='assets'; file='02_asset_inventory.md'; log='02-asset-inventory.log' },
    @{ id='tavla'; file='03_tavla_slice.md'; log='03-tavla-slice.log' }
)
$selected = @($tasks | Where-Object { $Only -eq 'all' -or $_.id -eq $Only })
foreach ($t in $selected) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $t.file) -PathType Leaf)) {
        throw "Task prompt missing: $($t.file)"
    }
}

$logDir = Join-Path $root '.local-ai\manual-phase1-scoped'
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$before = @(& git -C $root status --porcelain=v1 --untracked-files=no)
if ($LASTEXITCODE -ne 0) { throw 'Cannot record tracked Git status' }
$results = @()
Write-Host "Local AI checkout verified: $root" -ForegroundColor Cyan
Write-Host "HEAD: $head (detached)" -ForegroundColor Cyan
Write-Host "Tasks: $Only. No doctor/index rerun; read-only analysis only." -ForegroundColor Cyan

Push-Location -LiteralPath $root
try {
    foreach ($t in $selected) {
        $prompt = Get-Content -LiteralPath (Join-Path $PSScriptRoot $t.file) -Raw -Encoding UTF8
        $log = Join-Path $logDir $t.log
        Write-Host "`n=== $($t.id) ===" -ForegroundColor Yellow
        $global:LASTEXITCODE = 0
        & $runner analyze --role analysis --task $prompt 2>&1 | Tee-Object -FilePath $log
        $rc = $LASTEXITCODE
        if ($null -eq $rc) { $rc = 1 }
        $results += [pscustomobject]@{ task=$t.id; exit_code=$rc; log=$log }
        if ($rc -ne 0) {
            Write-Warning "Task $($t.id) failed (exit $rc). Continuing with the remaining independent tasks."
        }
    }
} finally {
    $after = @(& git -C $root status --porcelain=v1 --untracked-files=no)
    if (($before -join "`n") -ne ($after -join "`n")) {
        Write-Warning 'Tracked Git status has changed. Inspect before accepting patches.'
    }
    Pop-Location
}

$results | Format-Table -AutoSize
$results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $logDir 'task-summary.json') -Encoding UTF8
Write-Host "`nLogs: $logDir"
if (@($results | Where-Object { $_.exit_code -ne 0 }).Count -gt 0) { exit 1 }
Write-Host 'All selected scoped analysis tasks completed.' -ForegroundColor Green
