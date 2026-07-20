[CmdletBinding()]
param(
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CorePackage = "@codedrobe/core@0.6.1"
$AppId = "codex"
$Port = 9335
$CodeDrobeRoot = Join-Path $env:LOCALAPPDATA "CodeDrobe"
$NpmCache = Join-Path $CodeDrobeRoot "npm-cache"

if (-not (Get-Command npx.cmd -ErrorAction SilentlyContinue)) {
    throw "npx.cmd was not found. Install Node.js/npm before running this restore script."
}

Write-Host "CodeDrobe restore" -ForegroundColor Green
Write-Host "  App:  $AppId"
Write-Host "  CDP:  127.0.0.1:$Port"
Write-Host "  Core: $CorePackage"

if ($DryRun) {
    Write-Host "Dry run passed. No renderer or host settings were changed." -ForegroundColor Green
    exit 0
}

New-Item -ItemType Directory -Force -Path $NpmCache | Out-Null
$env:npm_config_cache = $NpmCache

& npx.cmd --yes $CorePackage "restore" "--app" $AppId "--port" ([string]$Port)
if ($LASTEXITCODE -ne 0) {
    throw "CodeDrobe restore exited with code $LASTEXITCODE."
}

Write-Host "CodeDrobe theme state and managed Codex appearance settings were restored." -ForegroundColor Green
