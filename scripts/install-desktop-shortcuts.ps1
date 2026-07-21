[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Remove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Launcher = Join-Path $ProjectRoot "xjtu-theme.cmd"
$Desktop = [Environment]::GetFolderPath("Desktop")

if (-not (Test-Path -LiteralPath $Launcher -PathType Leaf)) {
    throw "Hot theme launcher was not found: $Launcher"
}

$shortcuts = @(
    [pscustomobject]@{ Name = "XJTU Codex - Switch"; Arguments = "switch"; Description = "Toggle the XJTU theme without restarting Codex" },
    [pscustomobject]@{ Name = "XJTU Codex - Dark"; Arguments = "preview dark"; Description = "Apply the XJTU dark theme without restarting Codex" },
    [pscustomobject]@{ Name = "XJTU Codex - Light"; Arguments = "preview light"; Description = "Apply the XJTU light theme without restarting Codex" },
    [pscustomobject]@{ Name = "XJTU Codex - Disable"; Arguments = "disable"; Description = "Remove the XJTU theme from the running Codex process" }
)

$shell = New-Object -ComObject WScript.Shell
foreach ($definition in $shortcuts) {
    $shortcutPath = Join-Path $Desktop "$($definition.Name).lnk"
    if ($Remove) {
        if (Test-Path -LiteralPath $shortcutPath -PathType Leaf -and $PSCmdlet.ShouldProcess($shortcutPath, "Remove XJTU Codex shortcut")) {
            Remove-Item -LiteralPath $shortcutPath -Force
            Write-Host "Removed: $shortcutPath" -ForegroundColor Yellow
        }
        continue
    }

    if ($PSCmdlet.ShouldProcess($shortcutPath, "Create or update XJTU Codex shortcut")) {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $env:ComSpec
        $shortcut.Arguments = '/d /c ""{0}" {1}"' -f $Launcher, $definition.Arguments
        $shortcut.WorkingDirectory = $ProjectRoot
        $shortcut.Description = $definition.Description
        $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,167"
        $shortcut.Save()
        Write-Host "Installed: $shortcutPath" -ForegroundColor Green
    }
}
