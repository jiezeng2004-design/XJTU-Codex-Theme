[CmdletBinding()]
param(
    [switch]$Offline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$EngineRoot = Join-Path $ProjectRoot "engine"
$Cli = Join-Path $EngineRoot "bin\xjtu-theme.mjs"
$HostScript = Join-Path $PSScriptRoot "xjtu-hot-theme.ps1"
$StateRoot = Join-Path $env:LOCALAPPDATA "XJTU-Codex-Theme"
$StatePath = Join-Path $StateRoot "state.json"
$TaskName = "XJTU-Codex-Theme"

if (-not (Get-Command node.exe -ErrorAction SilentlyContinue)) {
    throw "node.exe was not found."
}
if (-not (Test-Path -LiteralPath $Cli -PathType Leaf)) {
    throw "Hot theme CLI was not found: $Cli"
}
if (-not (Test-Path -LiteralPath $HostScript -PathType Leaf)) {
    throw "Hot theme host wrapper was not found: $HostScript"
}

function Get-LiveState {
    $stateHash = if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
        (Get-FileHash -LiteralPath $StatePath -Algorithm SHA256).Hash
    } else { $null }
    return [pscustomobject]@{
        StateExists = Test-Path -LiteralPath $StatePath -PathType Leaf
        StateHash = $stateHash
        TaskExists = [bool](Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)
        Port9229 = [bool](Get-NetTCPConnection -LocalPort 9229 -State Listen -ErrorAction SilentlyContinue)
        Port9335 = [bool](Get-NetTCPConnection -LocalPort 9335 -State Listen -ErrorAction SilentlyContinue)
    }
}

$before = Get-LiveState

Push-Location $EngineRoot
try {
    & node.exe --test --test-isolation=none .\tests\engine.test.mjs
    if ($LASTEXITCODE -ne 0) { throw "Node unit tests failed: $LASTEXITCODE" }
} finally {
    Pop-Location
}

$originalHostInfo = $env:XJTU_THEME_HOST_INFO
$originalStateDir = $env:XJTU_THEME_STATE_DIR
$offlineStateDir = Join-Path $env:TEMP ("XjtuThemeOffline-{0}" -f $PID)
try {
    if ($Offline) {
        $testExecutable = (Get-Command powershell.exe -ErrorAction Stop).Source
        $env:XJTU_THEME_HOST_INFO = [ordered]@{
            executable = $testExecutable
            location = Split-Path -Parent $testExecutable
            signatureKind = "Store"
            version = "ci-offline"
            pid = $PID
        } | ConvertTo-Json -Compress
        $env:XJTU_THEME_STATE_DIR = $offlineStateDir
    }

    foreach ($arguments in @(
        @("doctor"),
        @("status"),
        @("preview", "dark", "--dry-run"),
        @("preview", "light", "--dry-run"),
        @("switch", "toggle", "--dry-run"),
        @("enable", "dark", "--dry-run"),
        @("disable", "--dry-run")
    )) {
        Write-Host "[DryRun] $($arguments -join ' ')" -ForegroundColor Cyan
        if ($Offline) {
            & node.exe $Cli @arguments
        } else {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $HostScript @arguments
        }
        if ($LASTEXITCODE -ne 0) { throw "Hot theme command failed: $($arguments -join ' ')" }
    }
} finally {
    $env:XJTU_THEME_HOST_INFO = $originalHostInfo
    $env:XJTU_THEME_STATE_DIR = $originalStateDir
    if (Test-Path -LiteralPath $offlineStateDir) {
        Remove-Item -LiteralPath $offlineStateDir -Recurse -Force
    }
}

$after = Get-LiveState
if (($before | ConvertTo-Json -Compress) -ne ($after | ConvertTo-Json -Compress)) {
    throw "Hot theme tests changed live state, a scheduled task, or a debug port."
}

Write-Host "PASS hot theme unit tests and DryRun preserved live state" -ForegroundColor Green
