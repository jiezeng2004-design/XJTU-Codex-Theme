# Local theme scripts

## Hot switch without restart

The root `xjtu-theme.cmd` wrapper is now the default path for the local hot-theme engine. It operates on the Codex process already running and does not restart it.

```cmd
xjtu-theme.cmd doctor
xjtu-theme.cmd preview dark
xjtu-theme.cmd preview light
xjtu-theme.cmd switch
xjtu-theme.cmd switch dark
xjtu-theme.cmd disable
```

`preview` applies once; `switch` toggles light/dark; `disable` restores the live renderer to its unthemed appearance and clears hot-engine state. Append `--dry-run` to `preview`, `switch`, `enable`, or `disable` to validate without opening the Inspector or changing live state.

The first real `preview` or `switch` is a deliberate live operation: it opens the current Codex main process' loopback-only Inspector briefly, validates the PID, injects a local payload, then closes the Inspector. Use `doctor` first. Do not run a hot command while a legacy CodeDrobe trial or port 9335 is active; the engine refuses this automatically.

`enable dark` is optional persistence. It applies the theme now and creates the limited-privilege `XJTU-Codex-Theme` logon task. `disable` removes that task too. Persistent mode has not been enabled during development.

## Legacy CodeDrobe scripts

The remaining scripts are preserved for the older isolated-profile recovery workflow. They close and restart Codex, so run them from PowerShell or CMD outside Codex.

## One-click switch

Double-click the root `switch-codex-theme.cmd` wrapper to call the no-restart hot engine. It switches `light -> dark` or `dark -> light`; when no hot theme is active, it applies `dark`.

An explicit target is also supported:

```powershell
.\switch-codex-theme.cmd dark
.\switch-codex-theme.cmd light
.\xjtu-theme.cmd switch dark
.\xjtu-theme.cmd switch light
```

The former `scripts\switch-codex-theme.ps1` remains available only for the legacy guarded CodeDrobe workflow. It restores the old isolated-profile trial before applying a new package and restarts Codex.

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
