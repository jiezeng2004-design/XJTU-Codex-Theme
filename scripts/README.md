# Local theme scripts

Run these scripts from a PowerShell or CMD window outside Codex because the launcher closes existing Codex processes.

## Apply and restart

```powershell
.\scripts\restart-codex-theme.ps1
.\scripts\restart-codex-theme.ps1 -Theme light
```

The root `restart-codex-theme.cmd` wrapper is the simplest entry point and defaults to `dark`.

Use `-DryRun` to validate paths and safety state without downloading CodeDrobe, closing Codex, creating the isolated profile, opening port 9335, writing a snapshot, or applying a theme.

## Restore

```powershell
.\scripts\restore-codex-theme.ps1
```

Restore is layered: CodeDrobe removes renderer state and restores its managed host backup when possible; the script then restores the independent SHA-256-verified config snapshot, closes the isolated Codex instance, and launches normal Codex.

## Preserved state

- Existing Codex browser profile: `%APPDATA%\Codex` (never copied or modified)
- Isolated trial profile: `%LOCALAPPDATA%\CodeDrobe\profiles\xjtu-codex-theme`
- Independent snapshots: `%LOCALAPPDATA%\CodeDrobe\backups\xjtu-codex-theme`
- CodeDrobe transactional backup: `%LOCALAPPDATA%\CodeDrobe\config.before-codedrobe.toml`
- npm cache: `%LOCALAPPDATA%\CodeDrobe\npm-cache`
- CDP: `127.0.0.1:9335`

No existing Codex browser data, cookies, or credentials are copied by these scripts.
