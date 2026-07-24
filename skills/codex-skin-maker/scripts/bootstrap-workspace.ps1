[CmdletBinding()]
param(
    [string]$Destination = (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Codex-Skin-Maker"),
    [string]$Repository = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme.git",
    [switch]$Update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
        path = (Resolve-Path -LiteralPath $Path).Path
        method = $Method
        next = "Run skills/codex-skin-maker/scripts/check-environment.ps1 -RepositoryRoot <path>"
    } | ConvertTo-Json -Depth 3
}

if ($env:OS -ne "Windows_NT") {
    throw "Codex Skin Maker currently supports Windows only."
}

$Destination = [Environment]::ExpandEnvironmentVariables($Destination)
$Destination = [System.IO.Path]::GetFullPath($Destination)

if (Test-Path -LiteralPath $Destination) {
    if (-not (Test-ThemeWorkspace -Path $Destination)) {
        $items = @(Get-ChildItem -LiteralPath $Destination -Force -ErrorAction SilentlyContinue)
        if ($items.Count -gt 0) {
            throw "Destination exists and is not a valid theme workspace: $Destination"
        }
        Remove-Item -LiteralPath $Destination -Force
    } else {
        if ($Update) {
            $git = Get-Command git.exe -ErrorAction SilentlyContinue
            if (-not $git) {
                throw "Git is required to update an existing workspace."
            }

            & $git.Source -C $Destination pull --ff-only
            if ($LASTEXITCODE -ne 0) {
                throw "git pull --ff-only failed with exit code $LASTEXITCODE"
            }
            Write-Result -Status "updated" -Path $Destination -Method "git"
            exit 0
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
    & $gitCommand.Source clone --depth 1 --branch main -- $Repository $Destination
    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed with exit code $LASTEXITCODE"
    }

    if (-not (Test-ThemeWorkspace -Path $Destination)) {
        throw "Downloaded repository does not contain the expected theme workspace structure."
    }

    Write-Result -Status "created" -Path $Destination -Method "git"
    exit 0
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("CodexSkinMaker-{0}" -f [Guid]::NewGuid().ToString("N"))
$archive = Join-Path $tempRoot "source.zip"
$extract = Join-Path $tempRoot "extract"
$archiveUrl = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme/archive/refs/heads/main.zip"

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archive -UseBasicParsing
    Expand-Archive -LiteralPath $archive -DestinationPath $extract -Force

    $expandedRoot = Get-ChildItem -LiteralPath $extract -Directory | Select-Object -First 1
    if (-not $expandedRoot -or -not (Test-ThemeWorkspace -Path $expandedRoot.FullName)) {
        throw "Downloaded archive does not contain the expected theme workspace structure."
    }

    Move-Item -LiteralPath $expandedRoot.FullName -Destination $Destination
    Write-Result -Status "created" -Path $Destination -Method "https-archive"
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
