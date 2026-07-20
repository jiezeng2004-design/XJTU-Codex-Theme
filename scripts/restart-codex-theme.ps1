[CmdletBinding()]
param(
    [ValidateSet("dark", "light")]
    [string]$Theme = "dark",

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CorePackage = "@codedrobe/core@0.6.1"
$AppId = "codex"
$Port = 9335
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ThemePackage = Join-Path $ProjectRoot "dist\xjtu-academic-$Theme-0.1.0.codedrobe-theme"
$CodeDrobeRoot = Join-Path $env:LOCALAPPDATA "CodeDrobe"
$ProfilePath = Join-Path $CodeDrobeRoot "profiles\xjtu-codex-theme"
$NpmCache = Join-Path $CodeDrobeRoot "npm-cache"

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

function Resolve-CodexExecutable {
    $package = Get-AppxPackage -Name "OpenAI.Codex" -ErrorAction Stop |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $package) {
        throw "Microsoft Store Codex package OpenAI.Codex was not found."
    }

    [xml]$manifest = Get-AppxPackageManifest -Package $package
    $application = @($manifest.Package.Applications.Application) |
        Where-Object { $_.Id -eq "App" } |
        Select-Object -First 1

    if (-not $application -or -not $application.Executable) {
        throw "Codex AppX executable was not declared in the package manifest."
    }

    $relativeExecutable = ([string]$application.Executable) -replace "/", "\"
    $executable = Join-Path $package.InstallLocation $relativeExecutable
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "Codex executable was not found at $executable"
    }

    return [pscustomobject]@{
        Version = [string]$package.Version
        Executable = $executable
    }
}

if (-not (Get-Command npx.cmd -ErrorAction SilentlyContinue)) {
    throw "npx.cmd was not found. Install Node.js/npm before running this launcher."
}

if (-not (Test-Path -LiteralPath $ThemePackage -PathType Leaf)) {
    throw "Theme package was not found: $ThemePackage"
}

$codex = Resolve-CodexExecutable

Write-Host "XJTU Codex Theme launcher" -ForegroundColor Green
Write-Host "  Theme:       $Theme"
Write-Host "  Package:     $ThemePackage"
Write-Host "  Codex:       $($codex.Version)"
Write-Host "  Executable:  $($codex.Executable)"
Write-Host "  CDP:         127.0.0.1:$Port"
Write-Host "  Profile:     $ProfilePath"
Write-Host "  Core:        $CorePackage"

if ($DryRun) {
    Write-Host "Dry run passed. No process, profile, port, or theme state was changed." -ForegroundColor Green
    exit 0
}

New-Item -ItemType Directory -Force -Path $NpmCache, $ProfilePath | Out-Null
$env:npm_config_cache = $NpmCache

Write-Warning "All running Codex windows will be closed. The isolated profile may require sign-in on first use."

Invoke-CodeDrobe -Arguments @("theme", "inspect", $ThemePackage)
Invoke-CodeDrobe -Arguments @(
    "launch",
    "--app", $AppId,
    "--app-path", $codex.Executable,
    "--port", [string]$Port,
    "--profile", $ProfilePath,
    "--restart-existing"
)
Invoke-CodeDrobe -Arguments @(
    "probe",
    "--app", $AppId,
    "--port", [string]$Port,
    "--theme", $ThemePackage,
    "--timeout-ms", "10000"
)
Invoke-CodeDrobe -Arguments @(
    "apply",
    "--app", $AppId,
    "--port", [string]$Port,
    "--theme", $ThemePackage,
    "--no-launch"
)
Invoke-CodeDrobe -Arguments @(
    "verify",
    "--app", $AppId,
    "--port", [string]$Port,
    "--theme", $ThemePackage
)

Write-Host "Theme '$Theme' is applied and verified for the current Codex renderer." -ForegroundColor Green
Write-Host "Restore with: $ProjectRoot\restore-codex-theme.cmd"
