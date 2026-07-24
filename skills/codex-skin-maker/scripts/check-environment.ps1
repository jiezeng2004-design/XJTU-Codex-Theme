[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [switch]$AllowDevelopmentWorkspace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TrustedRepository = "https://github.com/jiezeng2004-design/XJTU-Codex-Theme.git"
$TrustedTag = "v0.3.0-rc.1"
$TrustedRevision = "87a90403453bc2a469423b005cc8d9c761aba307"

function Test-ThemeWorkspace {
    param([Parameter(Mandatory)][string]$Path)

    return (
        (Test-Path -LiteralPath (Join-Path $Path "engine") -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Path "template\unbranded") -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $Path "xjtu-theme.cmd") -PathType Leaf)
    )
}

function Find-ThemeWorkspace {
    param([Parameter(Mandatory)][string[]]$Starts)

    foreach ($start in $Starts) {
        if ([string]::IsNullOrWhiteSpace($start)) { continue }
        try {
            $candidate = [System.IO.Path]::GetFullPath($start)
        } catch {
            continue
        }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $candidate = Split-Path -Parent $candidate
        }

        while ($candidate) {
            if (Test-ThemeWorkspace -Path $candidate) {
                return $candidate
            }
            $parent = Split-Path -Parent $candidate
            if (-not $parent -or $parent -eq $candidate) { break }
            $candidate = $parent
        }
    }

    return $null
}

function ConvertTo-SafeDisplayPath {
    param([Parameter(Mandatory)][string]$Path)

    return "<workspace>\$(Split-Path -Leaf $Path)"
}

function ConvertTo-RedactedDoctorLine {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Line)

    $redacted = $Line -replace '(?i)[a-z]:\\[^\s,;\]\}\)"'']+', '<path>'
    return $redacted -replace '(?i)\\\\[^\s,;\]\}\)"'']+', '<path>'
}

function Test-TrustedWorkspace {
    param([Parameter(Mandatory)][string]$Path)

    $receiptPath = Join-Path $Path ".codex-skin-maker-source.json"
    if (Test-Path -LiteralPath $receiptPath -PathType Leaf) {
        try {
            $receipt = Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
            return (
                [string]::Equals(([string]$receipt.repository).Trim().TrimEnd("/"), $TrustedRepository.TrimEnd("/"), [System.StringComparison]::OrdinalIgnoreCase) -and
                [string]::Equals(([string]$receipt.tag).Trim(), $TrustedTag, [System.StringComparison]::OrdinalIgnoreCase) -and
                [string]::Equals(([string]$receipt.revision).Trim(), $TrustedRevision, [System.StringComparison]::OrdinalIgnoreCase) -and
                @("git", "https-archive") -contains [string]$receipt.source
            )
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
    $isOfficial = [string]::Equals(([string]$remote).Trim().TrimEnd("/"), $TrustedRepository.TrimEnd("/"), [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $isOfficial) { return $false }
    if ($AllowDevelopmentWorkspace) { return $true }
    return [string]::Equals(([string]$revision).Trim(), $TrustedRevision, [System.StringComparison]::OrdinalIgnoreCase)
}

$result = [ordered]@{
    status = "blocked"
    windows = ($env:OS -eq "Windows_NT")
    windowsVersion = [Environment]::OSVersion.Version.ToString()
    windowsSupported = $false
    architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    repositoryRoot = $null
    workspaceTrusted = $false
    node = [ordered]@{
        found = $false
        version = $null
        supported = $false
    }
    git = [ordered]@{
        found = $false
        version = $null
    }
    doctor = [ordered]@{
        ran = $false
        exitCode = $null
        summary = @()
    }
    blockers = @()
}

if (-not $result.windows) {
    $result.blockers += "Windows 10/11 x64 is required."
}
if ($result.windows -and [Environment]::OSVersion.Version.Major -lt 10) {
    $result.blockers += "Windows 10/11 is required."
} else {
    $result.windowsSupported = $result.windows
}
if ($result.architecture -ne "X64") {
    $result.blockers += "x64 Windows is required; detected $($result.architecture)."
}

$starts = @()
if ($RepositoryRoot) { $starts += $RepositoryRoot }
$starts += (Get-Location).Path
$starts += $PSScriptRoot
$workspace = Find-ThemeWorkspace -Starts $starts

if ($workspace) {
    $result.repositoryRoot = ConvertTo-SafeDisplayPath -Path (Resolve-Path -LiteralPath $workspace).Path
    $result.workspaceTrusted = Test-TrustedWorkspace -Path $workspace
    if (-not $result.workspaceTrusted) {
        $result.blockers += "Theme workspace source could not be verified."
    }
} else {
    $result.blockers += "XJTU Codex Theme workspace was not found."
}

$node = Get-Command node.exe -ErrorAction SilentlyContinue
if ($node) {
    $nodeText = (& $node.Source --version 2>$null | Select-Object -First 1)
    $result.node.found = $true
    $result.node.version = $nodeText
    try {
        $parsed = [version]($nodeText.Trim().TrimStart("v"))
        $result.node.supported = ($parsed -ge [version]"22.0.0")
    } catch {
        $result.node.supported = $false
    }
} else {
    $result.blockers += "Node.js was not found."
}

if ($result.node.found -and -not $result.node.supported) {
    $result.blockers += "Node.js 22 or newer is required; detected $($result.node.version)."
}

$git = Get-Command git.exe -ErrorAction SilentlyContinue
if ($git) {
    $result.git.found = $true
    $result.git.version = (& $git.Source --version 2>$null | Select-Object -First 1)
}

if ($workspace -and $result.workspaceTrusted -and $result.windows) {
    $launcher = Join-Path $workspace "xjtu-theme.cmd"
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $doctorOutput = @(& cmd.exe /d /c "`"$launcher`" doctor" 2>&1 | ForEach-Object { $_.ToString() })
        $doctorExitCode = $LASTEXITCODE
    } catch {
        $doctorOutput = @($_.Exception.Message)
        $doctorExitCode = 1
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $result.doctor.ran = $true
    $result.doctor.exitCode = $doctorExitCode
    $result.doctor.summary = @($doctorOutput | Select-Object -Last 8 | ForEach-Object { ConvertTo-RedactedDoctorLine -Line $_ })
    if ($doctorExitCode -ne 0) {
        $result.blockers += "Theme doctor did not pass."
    }
}

if ($result.blockers.Count -eq 0) {
    $result.status = "ready"
}

$result | ConvertTo-Json -Depth 6
if ($result.status -ne "ready") { exit 1 }
