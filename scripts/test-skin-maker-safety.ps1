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
$trustedRepository = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme.git"
$trustedTag = "v0.3.0-rc.3"
$trustedRevision = "c36ed3c0b3f0476f91c8e494eec5a1965c294f79"
$legacyRevision = "18404b64791bf7e640e91597df17c1fe287399ac"

function New-MarkerWorkspace {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Revision,
        [Parameter(Mandatory)][string]$Tag
    )

    New-Item -ItemType Directory -Path (Join-Path $Path "engine") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Path "template\unbranded") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $Path "xjtu-theme.cmd") -Value "@echo off" -Encoding ASCII
    [ordered]@{
        repository = $trustedRepository
        tag = $Tag
        revision = $Revision
        source = "https-archive"
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Path ".codex-skin-maker-source.json") -Encoding UTF8
}

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

    $trustedWorkspace = Join-Path $tempRoot "trusted-workspace"
    New-MarkerWorkspace -Path $trustedWorkspace -Revision $trustedRevision -Tag $trustedTag
    Set-Content -LiteralPath (Join-Path $trustedWorkspace "user-change.txt") -Value "keep-local-change" -Encoding ASCII
    $trustedHashBefore = (Get-FileHash -LiteralPath (Join-Path $trustedWorkspace "user-change.txt") -Algorithm SHA256).Hash
    $trustedOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript -Destination $trustedWorkspace)
    $trustedExit = $LASTEXITCODE
    Assert-True ($trustedExit -eq 0) "The current pinned workspace must be reused."
    Assert-True ((($trustedOutput -join "`n") | ConvertFrom-Json).method -eq "existing") "Reused workspace must report the existing method."
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $trustedWorkspace "user-change.txt") -Algorithm SHA256).Hash -eq $trustedHashBefore) "Bootstrap modified a local change in the trusted workspace."

    $environmentOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $environmentScript -RepositoryRoot $trustedWorkspace 2>$null)
    $environmentExit = $LASTEXITCODE
    $trustedEnvironment = ($environmentOutput -join "`n") | ConvertFrom-Json
    Assert-True ($trustedEnvironment.workspaceTrusted) "Environment check must trust the exact official release receipt."
    Assert-True ($trustedEnvironment.doctor.ran) "Environment check must run doctor after receipt validation."

    $legacyWorkspace = Join-Path $tempRoot "legacy-workspace"
    New-MarkerWorkspace -Path $legacyWorkspace -Revision $legacyRevision -Tag "v0.2.1"
    Set-Content -LiteralPath (Join-Path $legacyWorkspace "keep-legacy.txt") -Value "preserve-old-workspace" -Encoding ASCII
    $legacyHashBefore = (Get-FileHash -LiteralPath (Join-Path $legacyWorkspace "keep-legacy.txt") -Algorithm SHA256).Hash
    try {
        $ErrorActionPreference = "Continue"
        $legacyOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript -Destination $legacyWorkspace 2>&1)
        $legacyExit = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $legacyMessage = $legacyOutput -join "`n"
    Assert-True ($legacyExit -ne 0) "The legacy v0.2.1 workspace must not be reused as current."
    Assert-True ($legacyMessage -match "older v0\.2\.1 workspace") "Legacy rejection must identify the old workspace version."
    Assert-True ($legacyMessage -match "new empty directory") "Legacy rejection must provide upgrade guidance."
    Assert-True ($legacyMessage -match "not be overwritten or deleted") "Legacy rejection must state the preservation guarantee."
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $legacyWorkspace "keep-legacy.txt") -Algorithm SHA256).Hash -eq $legacyHashBefore) "Bootstrap modified the legacy workspace."
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "PASS Codex Skin Maker safety gates" -ForegroundColor Green
exit 0
