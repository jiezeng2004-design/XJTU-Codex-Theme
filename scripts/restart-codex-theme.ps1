[CmdletBinding()]
param(
    [ValidateSet("dark", "light")]
    [string]$Theme = "dark",

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "theme-safety.ps1")

$CorePackage = "@codedrobe/core@0.6.1"
$AppId = "codex"
$Port = 9335
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ThemePackage = Join-Path $ProjectRoot "dist\xjtu-academic-$Theme-0.1.2.codedrobe-theme"
$CodeDrobeRoot = Join-Path $env:LOCALAPPDATA "CodeDrobe"
$ProfilePath = Join-Path $CodeDrobeRoot "profiles\xjtu-codex-theme"
$NpmCache = Join-Path $CodeDrobeRoot "npm-cache"
$BackupRoot = Join-Path $CodeDrobeRoot "backups\xjtu-codex-theme"
$CodeDrobeBackupPath = Join-Path $CodeDrobeRoot "config.before-codedrobe.toml"
$LockPath = Join-Path $CodeDrobeRoot "xjtu-codex-theme.lock"
$ConfigPath = Join-Path $HOME ".codex\config.toml"

function Invoke-CodeDrobe {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Write-Host "[CodeDrobe] $($Arguments -join ' ')" -ForegroundColor Cyan
    & npx.cmd --yes $CorePackage @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "CodeDrobe exited with code $LASTEXITCODE."
    }
}

if (-not (Get-Command npx.cmd -ErrorAction SilentlyContinue)) {
    throw "npx.cmd was not found. Install Node.js/npm before running this launcher."
}
if (-not (Test-Path -LiteralPath $ThemePackage -PathType Leaf)) {
    throw "Theme package was not found: $ThemePackage"
}
if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Codex config was not found: $ConfigPath"
}

$codex = Resolve-XjtuCodexExecutable
$staleCodeDrobeBackup = Test-Path -LiteralPath $CodeDrobeBackupPath -PathType Leaf

Write-Host "XJTU Codex Theme guarded launcher" -ForegroundColor Green
Write-Host "  Theme:       $Theme"
Write-Host "  Package:     $ThemePackage"
Write-Host "  Codex:       $($codex.Version)"
Write-Host "  Executable:  $($codex.Executable)"
Write-Host "  Config:      $ConfigPath"
Write-Host "  Backup root: $BackupRoot"
Write-Host "  CDP:         127.0.0.1:$Port"
Write-Host "  Profile:     $ProfilePath"
Write-Host "  Core:        $CorePackage"

if ($staleCodeDrobeBackup) {
    throw "CodeDrobe already has an unresolved backup at $CodeDrobeBackupPath. Run restore-codex-theme.cmd before another trial."
}

if ($DryRun) {
    Write-Host "Dry run passed. No process, snapshot, profile, port, or theme state was changed." -ForegroundColor Green
    exit 0
}

New-Item -ItemType Directory -Force -Path $NpmCache, $ProfilePath, $BackupRoot | Out-Null
$env:npm_config_cache = $NpmCache
$lock = Enter-XjtuThemeLock -Path $LockPath
$snapshot = $null
$codexRestarted = $false

try {
    $snapshot = New-XjtuConfigSnapshot -ConfigPath $ConfigPath -BackupRoot $BackupRoot -Theme $Theme -CodexVersion $codex.Version
    Write-Host "Config snapshot verified: $($snapshot.BackupPath)" -ForegroundColor Green
    Write-Host "Snapshot SHA-256: $($snapshot.SHA256)"
    Write-Warning "All running Codex windows will be closed. The isolated profile may require sign-in on first use."

    Invoke-CodeDrobe -Arguments @("theme", "inspect", $ThemePackage)
    # CodeDrobe apply performs its own DOM preflight, skips incompatible
    # secondary renderer targets, and verifies every compatible target after
    # injection. A separate probe/verify is stricter and incorrectly rejects
    # Codex utility windows such as app://-/index.html?initialRoute=/avatar-overlay.
    $codexRestarted = $true
    Invoke-CodeDrobe -Arguments @(
        "apply",
        "--app", $AppId,
        "--theme", $ThemePackage,
        "--app-path", $codex.Executable,
        "--port", [string]$Port,
        "--profile", $ProfilePath,
        "--restart-existing"
    )

    Write-Host "Theme '$Theme' is applied and internally verified for compatible Codex renderer targets." -ForegroundColor Green
    Write-Host "Restore with: $ProjectRoot\restore-codex-theme.cmd"
} catch {
    $failure = $_
    Write-Warning "Theme trial failed. Starting automatic rollback."

    try {
        & npx.cmd --yes $CorePackage "restore" "--app" $AppId "--port" ([string]$Port)
    } catch {
        Write-Warning "CodeDrobe restore was unavailable; independent config restoration will continue."
    }

    if ($snapshot) {
        $restored = Restore-XjtuConfigSnapshot -BackupRoot $BackupRoot -ExpectedConfigPath $ConfigPath
        Write-Host "Independent config restore verified: $($restored.SHA256)" -ForegroundColor Green
    }

    if ($codexRestarted) {
        Stop-XjtuCodexProcesses -Executable $codex.Executable
        Start-XjtuNormalCodex -Executable $codex.Executable
    }

    throw $failure
} finally {
    if ($lock) {
        $lock.Dispose()
    }
}
