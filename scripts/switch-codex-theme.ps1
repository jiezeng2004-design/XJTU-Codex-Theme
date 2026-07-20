[CmdletBinding()]
param(
    [ValidateSet("toggle", "dark", "light")]
    [string]$Theme = "toggle",

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "theme-safety.ps1")

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$CodeDrobeRoot = Join-Path $env:LOCALAPPDATA "CodeDrobe"
$BackupRoot = Join-Path $CodeDrobeRoot "backups\xjtu-codex-theme"
$ActivePath = Join-Path $BackupRoot "active.json"
$CodeDrobeBackupPath = Join-Path $CodeDrobeRoot "config.before-codedrobe.toml"
$RestoreScript = Join-Path $PSScriptRoot "restore-codex-theme.ps1"
$RestartScript = Join-Path $PSScriptRoot "restart-codex-theme.ps1"

foreach ($scriptPath in @($RestoreScript, $RestartScript)) {
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Required theme script was not found: $scriptPath"
    }
}

$activeSnapshot = $null
if (Test-Path -LiteralPath $ActivePath -PathType Leaf) {
    $activeSnapshot = Get-XjtuActiveSnapshot -BackupRoot $BackupRoot
}
$currentTheme = if ($activeSnapshot) { $activeSnapshot.Theme } else { $null }
$targetTheme = Resolve-XjtuSwitchTarget -RequestedTheme $Theme -CurrentTheme $currentTheme
$hasCodeDrobeBackup = Test-Path -LiteralPath $CodeDrobeBackupPath -PathType Leaf

Write-Host "XJTU Codex Theme safe switch" -ForegroundColor Green
Write-Host "  Requested:   $Theme"
Write-Host "  Current:     $(if ($currentTheme) { $currentTheme } else { 'none' })"
Write-Host "  Target:      $targetTheme"
Write-Host "  Snapshot:    $([bool]$activeSnapshot)"
Write-Host "  CD backup:   $hasCodeDrobeBackup"

if ($currentTheme -eq $targetTheme) {
    Write-Host "Theme '$targetTheme' is already active. No process or file was changed." -ForegroundColor Green
    exit 0
}

if ($hasCodeDrobeBackup -and -not $activeSnapshot) {
    throw "CodeDrobe has an unresolved host backup without an active XJTU snapshot. Refusing to switch automatically."
}

if ($DryRun) {
    if ($activeSnapshot) {
        Write-Host "Dry run plan: restore '$currentTheme', verify rollback, then apply '$targetTheme'."
    } else {
        Write-Host "Dry run plan: apply '$targetTheme' from the normal Codex state."
    }
    Write-Host "Dry run passed. No config, process, profile, port, backup, or theme state was changed." -ForegroundColor Green
    exit 0
}

if ($activeSnapshot) {
    Write-Host "Restoring active theme '$currentTheme' before switching..." -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $RestoreScript
    if ($LASTEXITCODE -ne 0) {
        throw "Theme restore failed with exit code $LASTEXITCODE. The target theme was not started."
    }
    if (Test-Path -LiteralPath $ActivePath -PathType Leaf) {
        throw "The active snapshot pointer remains after restore. The target theme was not started."
    }
    if (Test-Path -LiteralPath $CodeDrobeBackupPath -PathType Leaf) {
        throw "The CodeDrobe host backup remains after restore. The target theme was not started."
    }
}

Write-Host "Applying target theme '$targetTheme'..." -ForegroundColor Cyan
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $RestartScript -Theme $targetTheme
if ($LASTEXITCODE -ne 0) {
    throw "Target theme '$targetTheme' failed with exit code $LASTEXITCODE. Its guarded launcher attempted automatic rollback."
}

Write-Host "Theme switch completed: $(if ($currentTheme) { $currentTheme } else { 'none' }) -> $targetTheme" -ForegroundColor Green
Write-Host "Restore with: $ProjectRoot\restore-codex-theme.cmd"
