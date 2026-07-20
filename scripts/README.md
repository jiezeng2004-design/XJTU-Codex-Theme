# Local theme scripts

Run these scripts from a PowerShell or CMD window outside Codex because the launcher closes existing Codex processes.

## One-click switch

Double-click the root `switch-codex-theme.cmd` wrapper to toggle the active XJTU theme. It switches `light -> dark` or `dark -> light`; when no XJTU theme is active, it applies `dark`.

An explicit target is also supported:

```powershell
.\switch-codex-theme.cmd dark
.\switch-codex-theme.cmd light
.\scripts\switch-codex-theme.ps1 -Theme toggle -DryRun
```

When a theme is active, switching first runs the guarded restore to recover the original config, checks that both restore pointers are cleared, and only then starts a fresh guarded apply for the target. Codex restarts during this operation. If the target is already active, the switch exits without changing anything.

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
