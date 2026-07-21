# XJTU Hot Theme Engine

This local Windows-only engine applies the XJTU Codex theme to an already-running Microsoft Store Codex process without restarting it.

## Commands

```cmd
xjtu-theme.cmd doctor
xjtu-theme.cmd preview dark
xjtu-theme.cmd preview light
xjtu-theme.cmd switch
xjtu-theme.cmd enable dark
xjtu-theme.cmd disable
```

- `preview`: apply once to the current Codex process.
- `switch`: toggle dark/light in the current process. An explicit target is accepted.
- `enable`: apply now and install the limited-privilege `XJTU-Codex-Theme` logon task for future Codex processes.
- `disable` / `restore`: remove the task, restore the current renderer, and clear engine state.
- `doctor` / `status`: read-only environment and state report.
- `--dry-run`: validate and describe an operation without opening the inspector or changing state.

The engine refuses to apply while the legacy CodeDrobe snapshot, host backup, or port 9335 is active.

## Safety boundary

The engine does not edit WindowsApps, `app.asar`, Codex configuration, browser profiles, cookies, or credentials. A real apply briefly opens the Codex main-process Node inspector on `127.0.0.1:9229`, verifies the attached PID, injects a fixed local renderer payload, and closes the inspector. It refuses to use a pre-existing inspector endpoint.

Persistent mode creates a user-level scheduled task named `XJTU-Codex-Theme` with limited privileges. The task runs the local `agent.mjs`, polls for a new Codex PID, and performs one pulse per new process. `disable` removes the task.

Windows inspector attachment remains an experimental integration with the current Store Codex build. Use `preview` and `disable` successfully before enabling persistence.
