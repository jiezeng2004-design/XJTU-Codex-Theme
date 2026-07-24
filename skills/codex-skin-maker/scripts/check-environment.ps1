[CmdletBinding()]
param(
    [string]$RepositoryRoot
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

function Find-ThemeWorkspace {
    param([Parameter(Mandatory)][string[]]$Starts)

    foreach ($start in $Starts) {
        if ([string]::IsNullOrWhiteSpace($start)) { continue }
        $candidate = [System.IO.Path]::GetFullPath($start)
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

$result = [ordered]@{
    status = "blocked"
    windows = ($env:OS -eq "Windows_NT")
    architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    repositoryRoot = $null
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
if ($result.architecture -ne "X64") {
    $result.blockers += "x64 Windows is required; detected $($result.architecture)."
}

$starts = @()
if ($RepositoryRoot) { $starts += $RepositoryRoot }
$starts += (Get-Location).Path
$starts += $PSScriptRoot
$workspace = Find-ThemeWorkspace -Starts $starts

if ($workspace) {
    $result.repositoryRoot = (Resolve-Path -LiteralPath $workspace).Path
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

if ($workspace -and $result.windows) {
    $launcher = Join-Path $workspace "xjtu-theme.cmd"
    $doctorOutput = @(& cmd.exe /d /c "`"$launcher`" doctor" 2>&1 | ForEach-Object { $_.ToString() })
    $doctorExitCode = $LASTEXITCODE
    $result.doctor.ran = $true
    $result.doctor.exitCode = $doctorExitCode
    $result.doctor.summary = @($doctorOutput | Select-Object -Last 8)
    if ($doctorExitCode -ne 0) {
        $result.blockers += "Theme doctor did not pass."
    }
}

if ($result.blockers.Count -eq 0) {
    $result.status = "ready"
}

$result | ConvertTo-Json -Depth 6
if ($result.status -ne "ready") { exit 1 }
