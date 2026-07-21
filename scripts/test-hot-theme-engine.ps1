[CmdletBinding()]
param()

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
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $HostScript @arguments
    if ($LASTEXITCODE -ne 0) { throw "Hot theme command failed: $($arguments -join ' ')" }
}

$after = Get-LiveState
if (($before | ConvertTo-Json -Compress) -ne ($after | ConvertTo-Json -Compress)) {
    throw "Hot theme tests changed live state, a scheduled task, or a debug port."
}

Write-Host "PASS hot theme unit tests and DryRun preserved live state" -ForegroundColor Green
