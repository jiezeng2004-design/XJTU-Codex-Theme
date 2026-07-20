[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "theme-safety.ps1")

$launcherPath = Join-Path $PSScriptRoot "restart-codex-theme.ps1"
$launcherTokens = $null
$launcherErrors = $null
$launcherAst = [System.Management.Automation.Language.Parser]::ParseFile(
    $launcherPath,
    [ref]$launcherTokens,
    [ref]$launcherErrors
)
if ($launcherErrors.Count) {
    throw "Launcher parse failed: $($launcherErrors[0].Message)"
}

$launcherStrings = @(
    $launcherAst.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.StringConstantExpressionAst]
    }, $true) | ForEach-Object { $_.Value }
)
if (@($launcherStrings | Where-Object { $_ -eq "apply" }).Count -ne 1) {
    throw "Launcher must contain exactly one CodeDrobe apply command."
}
foreach ($disallowedCommand in @("launch", "probe", "verify")) {
    if ($launcherStrings -contains $disallowedCommand) {
        throw "Launcher must not use standalone CodeDrobe '$disallowedCommand'; apply owns launch, target filtering, and verification."
    }
}
foreach ($requiredOption in @("--app", "--theme", "--app-path", "--port", "--profile", "--restart-existing")) {
    if ($launcherStrings -notcontains $requiredOption) {
        throw "Launcher apply command is missing required option: $requiredOption"
    }
}
Write-Host "PASS single guarded apply owns launch, compatible-target filtering, and verification" -ForegroundColor Green

$switchCases = @(
    @{ Requested = "toggle"; Current = $null; Expected = "dark" },
    @{ Requested = "toggle"; Current = "dark"; Expected = "light" },
    @{ Requested = "toggle"; Current = "light"; Expected = "dark" },
    @{ Requested = "dark"; Current = "light"; Expected = "dark" },
    @{ Requested = "light"; Current = "dark"; Expected = "light" }
)
foreach ($case in $switchCases) {
    $actual = Resolve-XjtuSwitchTarget -RequestedTheme $case.Requested -CurrentTheme $case.Current
    if ($actual -ne $case.Expected) {
        throw "Switch target mismatch: requested=$($case.Requested), current=$($case.Current), expected=$($case.Expected), actual=$actual"
    }
}
Write-Host "PASS toggle/dark/light target resolution" -ForegroundColor Green

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
    if ($snapshot.Theme -ne "dark") {
        throw "Snapshot did not retain the selected theme."
    }
    $activeSnapshot = Get-XjtuActiveSnapshot -BackupRoot $backupRoot
    if ($activeSnapshot.Theme -ne "dark") {
        throw "Active snapshot did not expose the selected theme."
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
