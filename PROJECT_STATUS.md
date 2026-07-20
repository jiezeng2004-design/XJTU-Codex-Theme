# XJTU Codex Theme - Trial Ready

Status: ready for scripted local trial on 2026-07-20.

## Preserved deliverables

- `assets/backgrounds/xjtu-campus-light-v1-2560x1440.png`: approved light campus background.
- `assets/backgrounds/xjtu-campus-dark-v1-2560x1440.png`: matching dark campus background.
- `themes/xjtu-academic-light/`: CodeDrobe source for the light Codex theme.
- `themes/xjtu-academic-dark/`: CodeDrobe source for the dark Codex theme.
- `dist/xjtu-academic-light-0.1.0.codedrobe-theme`: packaged light theme.
- `dist/xjtu-academic-dark-0.1.0.codedrobe-theme`: packaged dark theme.

The source themes use package-optimized JPEG hero assets. The approved PNG originals remain in `assets/backgrounds/`.

## One-command trial

Run the root launcher outside Codex:

```cmd
restart-codex-theme.cmd
```

It defaults to the dark theme. Use `restart-codex-theme.cmd light` for the light theme.

The launcher resolves the installed Microsoft Store Codex package, creates a stable isolated Chromium profile under `%LOCALAPPDATA%\CodeDrobe\profiles\xjtu-codex-theme`, restarts Codex on loopback port 9335, then runs CodeDrobe inspect, probe, apply, and verify. The isolated profile is required because the Store build ignored remote debugging when launched against its default Chromium profile.

The first run may download `@codedrobe/core@0.6.1` into `%LOCALAPPDATA%\CodeDrobe\npm-cache` and may require signing in to the isolated Codex profile. Existing Codex browser data is not copied.

## Restore

While the themed Codex instance is running, use:

```cmd
restore-codex-theme.cmd
```

CodeDrobe restores its managed Codex appearance settings even if the renderer connection is no longer available.

## Verified state

- Both packages were created and inspected with `@codedrobe/core` 0.6.1.
- Both packages target the `codex` adapter, use schema version 1, and embed one named `hero` image.
- PowerShell parsing plus dark, light, and restore `-DryRun` checks passed on 2026-07-20 without changing processes, profiles, ports, or theme state.
- Live application, renderer, and screenshot verification remain pending until the user runs the restart script.

## Tool boundary

CodeDrobe remains an on-demand `npx` dependency. No global CodeDrobe command, Codex Skill, or MCP server is installed or enabled. The launcher binds CDP to `127.0.0.1` only and does not patch WindowsApps or edit CodeDrobe runtime files.
