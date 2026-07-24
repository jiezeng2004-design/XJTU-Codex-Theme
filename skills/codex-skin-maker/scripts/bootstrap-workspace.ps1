[CmdletBinding()]
param(
    [string]$Destination = (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Codex-Skin-Maker"),
    [string]$Repository = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme.git",
    [switch]$Update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TrustedRepository = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme.git"
$TrustedTag = "v0.2.1"
$TrustedRevision = "18404b64791bf7e640e91597df17c1fe287399ac"

function Test-ThemeWorkspace {
    param([Parameter(Mandatory)][string]$Path)

    return (
        (Test-Path -LiteralPath (Join-Path $Path "engine") -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Path "template\unbranded") -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Path "xjtu-theme.cmd") -PathType Leaf)
    )
}

function Write-Result {
    param(
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Method
    )

    [ordered]@{
        status = $Status
        path = "<workspace>\$(Split-Path -Leaf (Resolve-Path -LiteralPath $Path).Path)"
        method = $Method
        next = "Run skills/codex-skin-maker/scripts/check-environment.ps1 -RepositoryRoot <path>"
    } | ConvertTo-Json -Depth 3
}

function Assert-TrustedRepository {
    param([Parameter(Mandatory)][string]$Value)

    $normalized = $Value.Trim().TrimEnd("/")
    $expected = $TrustedRepository.TrimEnd("/")
    if (-not [string]::Equals($normalized, $expected, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Only the official XJTU Codex Theme repository is supported by this bootstrap script."
    }
}

function Assert-PinnedRevision {
    param([Parameter(Mandatory)][string]$Path)

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $git) {
        throw "Git is required to verify the downloaded revision."
    }

    $actual = (& $git.Source -C $Path rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or -not [string]::Equals($actual, $TrustedRevision, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Downloaded source did not match the trusted revision."
    }
}

function Test-TrustedWorkspace {
    param([Parameter(Mandatory)][string]$Path)

    $receiptPath = Join-Path $Path ".codex-skin-maker-source.json"
    if (Test-Path -LiteralPath $receiptPath -PathType Leaf) {
        try {
            $receipt = Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
            return ([string]::Equals([string]$receipt.revision, $TrustedRevision, [System.StringComparison]::OrdinalIgnoreCase))
        } catch {
            return $false
        }
    }

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $git -or -not (Test-Path -LiteralPath (Join-Path $Path ".git"))) { return $false }
    $remoteOutput = @(& $git.Source -C $Path remote get-url origin 2>$null)
    $remoteExitCode = $LASTEXITCODE
    $revisionOutput = @(& $git.Source -C $Path rev-parse HEAD 2>$null)
    $revisionExitCode = $LASTEXITCODE
    if ($remoteExitCode -ne 0 -or $revisionExitCode -ne 0) { return $false }
    $remote = $remoteOutput | Select-Object -First 1
    $revision = $revisionOutput | Select-Object -First 1
    return (
        [string]::Equals(([string]$remote).Trim().TrimEnd("/"), $TrustedRepository.TrimEnd("/"), [System.StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals(([string]$revision).Trim(), $TrustedRevision, [System.StringComparison]::OrdinalIgnoreCase)
    )
}

function Write-SourceReceipt {
    param([Parameter(Mandatory)][string]$Path)

    [ordered]@{
        repository = $TrustedRepository
        tag = $TrustedTag
        revision = $TrustedRevision
        source = "https-archive"
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Path ".codex-skin-maker-source.json") -Encoding UTF8
}

if ($env:OS -ne "Windows_NT") {
    throw "Codex Skin Maker currently supports Windows only."
}

$Destination = [Environment]::ExpandEnvironmentVariables($Destination)
$Destination = [System.IO.Path]::GetFullPath($Destination)
Assert-TrustedRepository -Value $Repository

if (Test-Path -LiteralPath $Destination) {
    if (-not (Test-ThemeWorkspace -Path $Destination)) {
        $items = @(Get-ChildItem -LiteralPath $Destination -Force -ErrorAction SilentlyContinue)
        if ($items.Count -gt 0) {
            throw "Destination exists and is not a valid theme workspace. Choose a new empty directory."
        }
    } else {
        if (-not (Test-TrustedWorkspace -Path $Destination)) {
            throw "Destination looks like a theme workspace, but its source could not be verified. Choose a new directory."
        }
        if ($Update) {
            throw "Workspace updates are disabled by this bootstrap script. Choose a new directory to obtain a newer verified release."
        }

        Write-Result -Status "ready" -Path $Destination -Method "existing"
        exit 0
    }
}

$parent = Split-Path -Parent $Destination
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

$gitCommand = Get-Command git.exe -ErrorAction SilentlyContinue
if ($gitCommand) {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & $gitCommand.Source clone --depth 1 --branch $TrustedTag -- $TrustedRepository $Destination 2>&1 | Out-Null
        $gitExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($gitExitCode -ne 0) {
        throw "git clone failed with exit code $gitExitCode"
    }

    Assert-PinnedRevision -Path $Destination

    if (-not (Test-ThemeWorkspace -Path $Destination)) {
        throw "Downloaded repository does not contain the expected theme workspace structure."
    }

    Write-Result -Status "created" -Path $Destination -Method "git"
    exit 0
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("CodexSkinMaker-{0}" -f [Guid]::NewGuid().ToString("N"))
$archive = Join-Path $tempRoot "source.zip"
$extract = Join-Path $tempRoot "extract"
$archiveUrl = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme/archive/$TrustedRevision.zip"

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archive -UseBasicParsing
    Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force

    $extractEntries = @(Get-ChildItem -LiteralPath $extract -Force)
    if ($extractEntries.Count -ne 1 -or -not $extractEntries[0].PSIsContainer) {
        throw "Downloaded archive has an unexpected top-level layout."
    }
    $expandedRoot = $extractEntries[0]
    $reparsePoints = @(Get-ChildItem -LiteralPath $expandedRoot.FullName -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
    if ($reparsePoints.Count -gt 0 -or -not (Test-ThemeWorkspace -Path $expandedRoot.FullName)) {
        throw "Downloaded archive does not contain the expected theme workspace structure."
    }

    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }
    if (@(Get-ChildItem -LiteralPath $Destination -Force).Count -ne 0) {
        throw "Destination is no longer empty. Choose a new directory."
    }
    Get-ChildItem -LiteralPath $expandedRoot.FullName -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
    }
    if (-not (Test-ThemeWorkspace -Path $Destination)) {
        throw "Downloaded archive does not contain the expected theme workspace structure."
    }
    Write-SourceReceipt -Path $Destination
    Write-Result -Status "created" -Path $Destination -Method "https-archive-pinned"
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
