[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$EngineArguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "theme-safety.ps1")

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Cli = Join-Path $ProjectRoot "engine\bin\xjtu-theme.mjs"

if (-not (Get-Command node.exe -ErrorAction SilentlyContinue)) {
    throw "node.exe was not found. Install Node.js 22 or newer before using the hot theme engine."
}
if (-not (Test-Path -LiteralPath $Cli -PathType Leaf)) {
    throw "Hot theme CLI was not found: $Cli"
}

$codex = Resolve-XjtuCodexExecutable
$process = Get-Process -Name "ChatGPT" -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $codex.Executable } |
    Select-Object -First 1

$hostInfo = [ordered]@{
    executable = $codex.Executable
    location = Split-Path -Parent (Split-Path -Parent $codex.Executable)
    signatureKind = "Store"
    version = $codex.Version
    pid = if ($process) { $process.Id } else { $null }
}
$env:XJTU_THEME_HOST_INFO = $hostInfo | ConvertTo-Json -Compress

& node.exe $Cli @EngineArguments
exit $LASTEXITCODE
