# Local theme scripts

Run these scripts from a PowerShell or CMD window outside Codex because the launcher closes existing Codex processes.

## Apply and restart

```powershell
.\scripts\restart-codex-theme.ps1
.\scripts\restart-codex-theme.ps1 -Theme light
```

The root `restart-codex-theme.cmd` wrapper is the simplest entry point and defaults to `dark`.

Use `-DryRun` to validate paths and settings without downloading CodeDrobe, closing Codex, creating the isolated profile, opening port 9335, or applying a theme.

## Restore

```powershell
.\scripts\restore-codex-theme.ps1
```

The restore script is intended to run while the themed Codex instance is still open. It also asks CodeDrobe to restore managed host appearance settings if the renderer is unavailable.

## Runtime data

- Isolated Codex profile: `%LOCALAPPDATA%\CodeDrobe\profiles\xjtu-codex-theme`
- npm cache: `%LOCALAPPDATA%\CodeDrobe\npm-cache`
- CDP: `127.0.0.1:9335`

No existing Codex browser data, cookies, or credentials are copied by these scripts.
