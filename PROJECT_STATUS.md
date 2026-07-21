# XJTU Codex Theme - Local Hot Engine Ready

Status: the local hot theme engine passed unit, syntax, and no-side-effect DryRun validation on Codex 26.715.7063.0 as of 2026-07-21. The first live Inspector injection remains pending explicit approval.

## Preserved deliverables

- `assets/backgrounds/xjtu-campus-light-v1-2560x1440.png`: approved light campus background.
- `assets/backgrounds/xjtu-campus-dark-v1-2560x1440.png`: matching dark campus background.
- `themes/xjtu-academic-light/`: CodeDrobe source for the light Codex theme.
- `themes/xjtu-academic-dark/`: CodeDrobe source for the dark Codex theme.
- `switch-codex-theme.cmd`: one-click safe toggle, with optional `dark` or `light` target.
- `xjtu-theme.cmd`: no-restart local hot-theme command wrapper.
- `engine/`: local Node implementation, including its dark/light manifests and tests.
- `dist/xjtu-academic-light-0.1.3.codedrobe-theme`: current packaged light theme.
- `dist/xjtu-academic-dark-0.1.3.codedrobe-theme`: current packaged dark theme.
- `dist/*-0.1.0.codedrobe-theme` through `dist/*-0.1.2.codedrobe-theme`: retained historical packages; do not use them for the current trial.

The source themes use package-optimized JPEG hero assets. The approved PNG originals remain in `assets/backgrounds/`.

## Local hot-theme engine

The default switch entry now uses the local hot engine. It applies or toggles the visual theme in the current Codex process without restarting Codex or modifying WindowsApps, `app.asar`, Codex configuration, browser profiles, cookies, or credentials.

```cmd
xjtu-theme.cmd doctor
xjtu-theme.cmd preview dark
xjtu-theme.cmd preview light
xjtu-theme.cmd switch
xjtu-theme.cmd disable
```

`preview` applies a theme once. `switch` toggles light and dark, or accepts an explicit target. `disable` removes the renderer injection from the running Codex process and clears the local hot-engine state. `enable dark` additionally creates the opt-in, limited-privilege `XJTU-Codex-Theme` logon task; it has not been enabled or created during development.

Each live apply briefly opens a loopback-only Node Inspector endpoint on port 9229, verifies its PID matches the selected Codex main process, injects the local renderer payload, then closes the endpoint. The engine refuses to operate when an old CodeDrobe transaction, host backup, or port 9335 is present. It also skips the incompatible `avatar-overlay` utility renderer.

The Store AppX discovery is performed by the PowerShell host wrapper. This avoids the restricted Node child-process context that previously produced a false "OpenAI.Codex was not found" result, without weakening Store-signature or executable-path validation.

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

The switch wrapper never overwrites an active snapshot. It restores and verifies the current trial first, then lets the normal guarded launcher create a new snapshot for the target theme. An unresolved CodeDrobe backup without an active XJTU snapshot stops the switch instead of guessing.

## Legacy CodeDrobe trial

The commands below are retained only for recovery and comparison with the previous CodeDrobe design. They restart Codex and use an isolated CodeDrobe profile. They are not used by `xjtu-theme.cmd`.

## One-command trial

Run outside Codex:

```cmd
restart-codex-theme.cmd
```

It defaults to the dark theme. Use `restart-codex-theme.cmd light` for the light theme.

To toggle the currently active XJTU theme in one operation, run:

```cmd
switch-codex-theme.cmd
```

The same wrapper accepts `dark` or `light` to select an explicit target. Switching restores the current trial before applying the target; Codex restarts as part of the guarded sequence.

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
- Version 0.1.3 follows a wallpaper-first enlarged reference: the hero layer is rendered at 116% height and positioned at 68% horizontally, the main surface uses only 6% dark / 8% light tint with no full-panel backdrop blur, and stronger opacity is restricted to the sidebar, cards, header, and composer.
- Both 0.1.3 packages were created and inspected with `@codedrobe/core` 0.6.1; neither package contains `rendererProfile`.
- Both packages target the `codex` adapter, use schema version 1, and embed one named `hero` image.
- PowerShell parsing, launcher-flow checks, toggle/dark/light target-resolution tests, restore DryRun, and a temporary-file backup/mutate/restore SHA-256 exercise passed on 2026-07-20.
- The one-click switch DryRun was exercised against a real active 0.1.3 light trial: both `toggle` and explicit `dark` resolved to `light -> dark`, explicit `light` exited unchanged, and the active pointer plus CodeDrobe backup retained identical SHA-256 hashes before and after testing.
- Live 0.1.3 apply and campus artwork rendering have been confirmed. The current visual direction is still being refined from user screenshots.
- A separate current-state baseline copy of `~/.codex/config.toml` was created under the private backup root and verified against SHA-256 `28FED8BDAE28692984D097A6E13590B5FDF3C5983ECD2372691FA284C6EEDECA`.
- Hot engine validation on 2026-07-21: all 7 Node tests passed, PowerShell parsed all scripts, the existing legacy safety tests passed, and `doctor`, `preview dark --dry-run`, `preview light --dry-run`, `switch toggle --dry-run`, `enable dark --dry-run`, and `disable --dry-run` all passed. The DryRun state comparison confirmed no local state file, scheduled task, Inspector port, or CodeDrobe port was created.
- `doctor` now identifies the installed Store Codex executable and PID through the PowerShell host wrapper. The active baseline remains clear: Inspector port 9229 closed, CodeDrobe port 9335 closed, no CodeDrobe backup/snapshot, no hot-engine state, and no `XJTU-Codex-Theme` scheduled task.

## Tool boundary

CodeDrobe remains an on-demand `npx` dependency. No global CodeDrobe command, Codex Skill, or MCP server is installed or enabled. The launcher binds CDP to `127.0.0.1` only and does not patch WindowsApps or edit CodeDrobe runtime files.
