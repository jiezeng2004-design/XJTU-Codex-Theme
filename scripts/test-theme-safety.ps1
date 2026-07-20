[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "theme-safety.ps1")

$testRoot = Join-Path $env:TEMP ("XjtuThemeSafety-{0}" -f $PID)
$configPath = Join-Path $testRoot "home\.codex\config.toml"
$backupRoot = Join-Path $testRoot "backups"

try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $configPath) | Out-Null
    @"
model = "test"

[desktop]
appearanceTheme = "system"
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8

    $originalHash = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash
    $snapshot = New-XjtuConfigSnapshot -ConfigPath $configPath -BackupRoot $backupRoot -Theme "dark" -CodexVersion "test"
    if ($snapshot.SHA256 -ne $originalHash) {
        throw "Snapshot hash did not match the original test config."
    }

    Add-Content -LiteralPath $configPath -Value "changed = true" -Encoding UTF8
    if ((Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash -eq $originalHash) {
        throw "Test config mutation did not change the hash."
    }

    $restored = Restore-XjtuConfigSnapshot -BackupRoot $backupRoot -ExpectedConfigPath $configPath
    if ($restored.SHA256 -ne $originalHash) {
        throw "Restored hash did not match the original test config."
    }
    if (Test-Path -LiteralPath (Join-Path $backupRoot "active.json")) {
        throw "Active snapshot pointer was not cleared after restore."
    }
    if (-not (Get-ChildItem -LiteralPath (Split-Path -Parent $snapshot.BackupPath) -Filter "config.before-restore-*.toml" -File)) {
        throw "Emergency pre-restore copy was not created."
    }

    Write-Host "PASS backup -> mutate -> restore -> SHA-256 verification" -ForegroundColor Green
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
