# XJTU Codex Theme - Safety Trial Ready

Status: ready for a guarded local retry on Codex 26.715.7063.0 as of 2026-07-20.

## Preserved deliverables

- `assets/backgrounds/xjtu-campus-light-v1-2560x1440.png`: approved light campus background.
- `assets/backgrounds/xjtu-campus-dark-v1-2560x1440.png`: matching dark campus background.
- `themes/xjtu-academic-light/`: CodeDrobe source for the light Codex theme.
- `themes/xjtu-academic-dark/`: CodeDrobe source for the dark Codex theme.
- `dist/xjtu-academic-light-0.1.2.codedrobe-theme`: current packaged light theme.
- `dist/xjtu-academic-dark-0.1.2.codedrobe-theme`: current packaged dark theme.
- `dist/*-0.1.0.codedrobe-theme` and `dist/*-0.1.1.codedrobe-theme`: retained legacy packages; do not use them for the current trial.

The source themes use package-optimized JPEG hero assets. The approved PNG originals remain in `assets/backgrounds/`.

## Safety model

The trial uses an isolated Chromium profile under `%LOCALAPPDATA%\CodeDrobe\profiles\xjtu-codex-theme`. The existing `%APPDATA%\Codex` browser profile is not copied, edited, or used by the themed instance.

Before any process is closed, the launcher:

1. resolves and validates the Store Codex executable and selected theme package;
2. refuses to continue when CodeDrobe has an unresolved transactional backup;
3. creates a private snapshot of `~/.codex/config.toml` under `%LOCALAPPDATA%\CodeDrobe\backups\xjtu-codex-theme`;
4. verifies the snapshot with SHA-256 and records an active restore pointer;
5. acquires an exclusive lock so launch and restore cannot run concurrently.

CodeDrobe also creates its own transactional backup. After inspect, one guarded `apply --restart-existing` operation performs launch, DOM preflight, compatible-target injection, and built-in verification. If inspect or apply fails, the launcher attempts CodeDrobe restore, restores the independently verified config snapshot, closes the isolated instance, and starts normal Codex without a custom profile.

This protects the files and settings touched by the workflow. It cannot guarantee recovery from operating-system failure, disk loss, or unrelated application corruption.

## One-command trial

Run outside Codex:

```cmd
restart-codex-theme.cmd
```

It defaults to the dark theme. Use `restart-codex-theme.cmd light` for the light theme.

The first run may download `@codedrobe/core@0.6.1` into `%LOCALAPPDATA%\CodeDrobe\npm-cache`. The isolated profile may require sign-in; existing cookies and login data are never copied.

## Restore

Run:

```cmd
restore-codex-theme.cmd
```

The restore script uses CodeDrobe when available, then independently restores the SHA-256-verified config snapshot, closes the isolated instance, and starts normal Codex. Snapshot files are retained for audit; only the active pointer is cleared after successful restoration.

## Verified state

- A guarded live trial of version 0.1.0 reached launch and probe, then failed at apply because the optional `codex-theme-v1` renderer profile required noninteractive chrome that Codex 26.715.7063.0 did not provide. Automatic CodeDrobe restore and the independent SHA-256 config restore both completed successfully.
- Version 0.1.1 removes that optional renderer profile. The XJTU background and glass styling remain implemented by the themes' own CSS and named `hero` image.
- A version 0.1.1 visual trial confirmed that the artwork loaded, but the 46–48% main content tint plus 18px backdrop blur obscured the right-side campus focal point. Version 0.1.2 reduces the main tint to 20% dark / 22% light and the main backdrop blur to 6px while retaining stronger local surfaces for text and controls.
- A subsequent 0.1.2 trial exposed two Codex renderer targets: the compatible main window and an `avatar-overlay` utility window without `main.main-surface`. CodeDrobe's standalone `probe` rejects the whole session when any target is incompatible, while `apply` is explicitly designed to skip incompatible secondary windows and verify each compatible target. The launcher now uses that single guarded apply flow instead of redundant standalone probe/verify commands.
- Both 0.1.2 packages were created and inspected with `@codedrobe/core` 0.6.1; neither package contains `rendererProfile`.
- Both packages target the `codex` adapter, use schema version 1, and embed one named `hero` image.
- PowerShell parsing, dark/light/restore DryRun, and a temporary-file backup/mutate/restore SHA-256 exercise passed on 2026-07-20 without touching the real Codex config.
- After verification there was no active XJTU snapshot, no unresolved CodeDrobe transactional backup, and no listener on port 9335.
- A separate current-state baseline copy of `~/.codex/config.toml` was created under the private backup root and verified against SHA-256 `28FED8BDAE28692984D097A6E13590B5FDF3C5983ECD2372691FA284C6EEDECA`.
- Live apply and visual verification of version 0.1.2 remain pending until the user runs the restart script.

## Tool boundary

CodeDrobe remains an on-demand `npx` dependency. No global CodeDrobe command, Codex Skill, or MCP server is installed or enabled. The launcher binds CDP to `127.0.0.1` only and does not patch WindowsApps or edit CodeDrobe runtime files.
