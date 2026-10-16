$ErrorActionPreference = "SilentlyContinue"
$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
    $targetFile = $payload.tool_input.TargetFile
    if ([string]::IsNullOrWhiteSpace($targetFile)) {
        exit 0
    }
    if (-not ($targetFile.EndsWith(".gd")) -or -not (Test-Path -LiteralPath $targetFile)) {
        exit 0
    }
    $normalized = $targetFile.Replace("\", "/").ToLowerInvariant()
    $isGuardedDir = ($normalized -match "/(ui|core|net|bots)/")
    if (-not $isGuardedDir) {
        exit 0
    }

    $content = Get-Content -LiteralPath $targetFile -Raw
    if ($content -match '"res://assets/' -or $content -match '"res://Kenney_c0/') {
        $warning = @{
            hookSpecificOutput = @{
                hookEventName = "PostToolUse"
                additionalContext = "WARNING: Direct asset path literal ('res://assets/' or 'res://Kenney_c0/') detected in $targetFile. tests/test_no_direct_asset_literals.gd forbids direct asset literals in ui/, core/, net/, and bots/. Resolve assets via AssetRegistry.gd and AssetIds.gd instead."
            }
        } | ConvertTo-Json -Compress
        Write-Output $warning
    }
} catch {
    # Never block tool execution on hook parse errors
}
exit 0
