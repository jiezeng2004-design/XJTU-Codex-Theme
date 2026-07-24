[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) { throw $Message }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentScript = Join-Path $projectRoot "skills\codex-skin-maker\scripts\check-environment.ps1"
$bootstrapScript = Join-Path $projectRoot "skills\codex-skin-maker\scripts\bootstrap-workspace.ps1"
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("CodexSkinMakerSafety-{0}" -f [Guid]::NewGuid().ToString("N"))

try {
    $fakeWorkspace = Join-Path $tempRoot "fake-workspace"
    New-Item -ItemType Directory -Path (Join-Path $fakeWorkspace "engine") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $fakeWorkspace "template\unbranded") -Force | Out-Null
    @'
@echo off
echo {"unexpected":"doctor-executed"}
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $fakeWorkspace "xjtu-theme.cmd") -Encoding ASCII

    $environmentOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $environmentScript -RepositoryRoot $fakeWorkspace 2>$null)
    $environmentExit = $LASTEXITCODE
    $environment = ($environmentOutput -join "`n") | ConvertFrom-Json
    Assert-True ($environmentExit -ne 0) "Untrusted workspaces must return a non-zero exit code."
    Assert-True (-not $environment.workspaceTrusted) "Marker-only workspace was incorrectly trusted."
    Assert-True (-not $environment.doctor.ran) "Untrusted workspace doctor must not run."

    $nonEmpty = Join-Path $tempRoot "non-empty"
    New-Item -ItemType Directory -Path $nonEmpty -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $nonEmpty "keep.txt") -Value "preserve-me" -Encoding ASCII
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "SilentlyContinue"
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript -Destination $nonEmpty *> $null
        $bootstrapExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    Assert-True ($bootstrapExit -ne 0) "Non-empty unknown destinations must be rejected."
    Assert-True ((Get-Content -LiteralPath (Join-Path $nonEmpty "keep.txt") -Raw).Trim() -eq "preserve-me") "Bootstrap modified the existing file."
    Assert-True (@(Get-ChildItem -LiteralPath $nonEmpty -Force).Count -eq 1) "Bootstrap added files to a rejected destination."

    $customDestination = Join-Path $tempRoot "custom-source"
    try {
        $ErrorActionPreference = "SilentlyContinue"
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript -Destination $customDestination -Repository "https://example.invalid/theme.git" *> $null
        $customSourceExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    Assert-True ($customSourceExit -ne 0) "Custom remote sources must be rejected."
    Assert-True (-not (Test-Path -LiteralPath $customDestination)) "Rejected custom source created a destination."
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS Codex Skin Maker safety gates" -ForegroundColor Green
