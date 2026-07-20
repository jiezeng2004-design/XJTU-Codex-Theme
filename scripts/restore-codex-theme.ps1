[CmdletBinding()]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "theme-safety.ps1")

$CorePackage = "@codedrobe/core@0.6.1"
$AppId = "codex"
$Port = 9335
$CodeDrobeRoot = Join-Path $env:LOCALAPPDATA "CodeDrobe"
$NpmCache = Join-Path $CodeDrobeRoot "npm-cache"
$BackupRoot = Join-Path $CodeDrobeRoot "backups\xjtu-codex-theme"
$LockPath = Join-Path $CodeDrobeRoot "xjtu-codex-theme.lock"
$ConfigPath = Join-Path $HOME ".codex\config.toml"

if (-not (Get-Command npx.cmd -ErrorAction SilentlyContinue)) {
    throw "npx.cmd was not found. Install Node.js/npm before running this restore script."
}

$codex = Resolve-XjtuCodexExecutable
$activeSnapshot = Test-Path -LiteralPath (Join-Path $BackupRoot "active.json") -PathType Leaf

Write-Host "XJTU CodeDrobe guarded restore" -ForegroundColor Green
Write-Host "  App:         $AppId"
Write-Host "  Codex:       $($codex.Version)"
Write-Host "  Config:      $ConfigPath"
Write-Host "  Backup root: $BackupRoot"
Write-Host "  CDP:         127.0.0.1:$Port"
Write-Host "  Core:        $CorePackage"
Write-Host "  Active copy: $activeSnapshot"

if ($DryRun) {
    Write-Host "Dry run passed. No renderer, config, process, or host settings were changed." -ForegroundColor Green
    exit 0
}
if (-not $activeSnapshot) {
    throw "No active pre-trial config snapshot exists. Nothing will be changed."
}

New-Item -ItemType Directory -Force -Path $NpmCache | Out-Null
$env:npm_config_cache = $NpmCache
$lock = Enter-XjtuThemeLock -Path $LockPath

try {
    $codeDrobeRestored = $true
    try {
        & npx.cmd --yes $CorePackage "restore" "--app" $AppId "--port" ([string]$Port)
        if ($LASTEXITCODE -ne 0) {
            $codeDrobeRestored = $false
        }
    } catch {
        $codeDrobeRestored = $false
    }

    if (-not $codeDrobeRestored) {
        Write-Warning "CodeDrobe renderer restore did not complete. The isolated process will be closed and the independent config snapshot will still be restored."
    }

    $restored = Restore-XjtuConfigSnapshot -BackupRoot $BackupRoot -ExpectedConfigPath $ConfigPath
    Write-Host "Config restore verified: $($restored.SHA256)" -ForegroundColor Green

    Stop-XjtuCodexProcesses -Executable $codex.Executable
    Start-XjtuNormalCodex -Executable $codex.Executable
    Write-Host "Normal Codex was started with the original profile and verified config." -ForegroundColor Green
} finally {
    if ($lock) {
        $lock.Dispose()
    }
}
