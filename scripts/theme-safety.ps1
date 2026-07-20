function Write-XjtuJsonAtomic {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $temporary = "$Path.$PID.tmp"
    $InputObject | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $temporary -Encoding UTF8
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Resolve-XjtuCodexExecutable {
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

function Enter-XjtuThemeLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    try {
        return [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::OpenOrCreate,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
    } catch {
        throw "Another XJTU theme launch or restore operation is already running."
    }
}

function New-XjtuConfigSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,

        [Parameter(Mandatory = $true)]
        [string]$BackupRoot,

        [Parameter(Mandatory = $true)]
        [string]$Theme,

        [Parameter(Mandatory = $true)]
        [string]$CodexVersion
    )

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        throw "Codex config was not found: $ConfigPath"
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
    $snapshotDirectory = Join-Path $BackupRoot $timestamp
    New-Item -ItemType Directory -Path $snapshotDirectory | Out-Null
    $backupPath = Join-Path $snapshotDirectory "config.toml"
    Copy-Item -LiteralPath $ConfigPath -Destination $backupPath

    $sourceHash = (Get-FileHash -LiteralPath $ConfigPath -Algorithm SHA256).Hash
    $backupHash = (Get-FileHash -LiteralPath $backupPath -Algorithm SHA256).Hash
    if ($sourceHash -ne $backupHash) {
        throw "Config snapshot hash verification failed."
    }

    $manifestPath = Join-Path $snapshotDirectory "manifest.json"
    $manifest = [ordered]@{
        schemaVersion = 1
        createdAt = (Get-Date).ToString("o")
        theme = $Theme
        codexVersion = $CodexVersion
        configPath = $ConfigPath
        backupPath = $backupPath
        sha256 = $backupHash
    }
    Write-XjtuJsonAtomic -InputObject $manifest -Path $manifestPath
    Write-XjtuJsonAtomic -InputObject ([ordered]@{ manifestPath = $manifestPath }) -Path (Join-Path $BackupRoot "active.json")

    return [pscustomobject]@{
        ManifestPath = $manifestPath
        BackupPath = $backupPath
        SHA256 = $backupHash
        Theme = $Theme
    }
}

function Get-XjtuActiveSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot
    )

    $activePath = Join-Path $BackupRoot "active.json"
    if (-not (Test-Path -LiteralPath $activePath -PathType Leaf)) {
        throw "No active XJTU Codex config snapshot was found at $activePath"
    }

    $pointer = Get-Content -Raw -Encoding UTF8 -LiteralPath $activePath | ConvertFrom-Json
    if (-not $pointer.manifestPath -or -not (Test-Path -LiteralPath $pointer.manifestPath -PathType Leaf)) {
        throw "The active snapshot pointer is invalid."
    }

    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $pointer.manifestPath | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or -not $manifest.backupPath -or -not $manifest.sha256) {
        throw "The active snapshot manifest is invalid."
    }
    $theme = [string]$manifest.theme
    if ($theme -notin @("dark", "light")) {
        throw "The active snapshot has an invalid theme value."
    }

    return [pscustomobject]@{
        ActivePath = $activePath
        ManifestPath = [string]$pointer.manifestPath
        ConfigPath = [string]$manifest.configPath
        BackupPath = [string]$manifest.backupPath
        SHA256 = [string]$manifest.sha256
        Theme = $theme
    }
}

function Resolve-XjtuSwitchTarget {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("toggle", "dark", "light")]
        [string]$RequestedTheme,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$CurrentTheme
    )

    if ($RequestedTheme -ne "toggle") {
        return $RequestedTheme
    }
    if (-not $CurrentTheme) {
        return "dark"
    }
    if ($CurrentTheme -eq "dark") {
        return "light"
    }
    if ($CurrentTheme -eq "light") {
        return "dark"
    }
    throw "Cannot toggle an unknown current theme: $CurrentTheme"
}

function Restore-XjtuConfigSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupRoot,

        [string]$ExpectedConfigPath
    )

    $snapshot = Get-XjtuActiveSnapshot -BackupRoot $BackupRoot
    if ($ExpectedConfigPath -and $snapshot.ConfigPath -ne $ExpectedConfigPath) {
        throw "Snapshot config path does not match the expected Codex config path."
    }
    if (-not (Test-Path -LiteralPath $snapshot.BackupPath -PathType Leaf)) {
        throw "Snapshot config file is missing: $($snapshot.BackupPath)"
    }

    $backupHash = (Get-FileHash -LiteralPath $snapshot.BackupPath -Algorithm SHA256).Hash
    if ($backupHash -ne $snapshot.SHA256) {
        throw "Snapshot config hash no longer matches its manifest."
    }

    $snapshotDirectory = Split-Path -Parent $snapshot.BackupPath
    if (Test-Path -LiteralPath $snapshot.ConfigPath -PathType Leaf) {
        $emergencyPath = Join-Path $snapshotDirectory ("config.before-restore-{0}.toml" -f (Get-Date -Format "yyyyMMdd-HHmmss-fff"))
        Copy-Item -LiteralPath $snapshot.ConfigPath -Destination $emergencyPath
    }

    Copy-Item -LiteralPath $snapshot.BackupPath -Destination $snapshot.ConfigPath -Force
    $restoredHash = (Get-FileHash -LiteralPath $snapshot.ConfigPath -Algorithm SHA256).Hash
    if ($restoredHash -ne $snapshot.SHA256) {
        throw "Restored Codex config hash does not match the snapshot."
    }

    Remove-Item -LiteralPath $snapshot.ActivePath -Force
    return [pscustomobject]@{
        ConfigPath = $snapshot.ConfigPath
        BackupPath = $snapshot.BackupPath
        SHA256 = $restoredHash
    }
}

function Stop-XjtuCodexProcesses {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable
    )

    $processes = Get-Process -Name "ChatGPT" -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -eq $Executable }
    foreach ($process in $processes) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    if ($processes) {
        Start-Sleep -Milliseconds 800
    }
}

function Start-XjtuNormalCodex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable
    )

    Start-Process -FilePath $Executable | Out-Null
}
