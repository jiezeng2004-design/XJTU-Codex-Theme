# XJTU Codex Theme - Suspended

Status: suspended on 2026-07-19.

## Preserved deliverables

- `assets/backgrounds/xjtu-campus-light-v1-2560x1440.png`: approved light campus background.
- `assets/backgrounds/xjtu-campus-dark-v1-2560x1440.png`: matching dark campus background.
- `themes/xjtu-academic-light/`: CodeDrobe source for the light Codex theme.
- `themes/xjtu-academic-dark/`: CodeDrobe source for the dark Codex theme.
- `dist/xjtu-academic-light-0.1.0.codedrobe-theme`: packaged light theme.
- `dist/xjtu-academic-dark-0.1.0.codedrobe-theme`: packaged dark theme.

The source themes use package-optimized JPEG hero assets. The approved PNG originals remain in `assets/backgrounds/`.

## Verified state

- Both packages were created and inspected with `@codedrobe/core` 0.6.1.
- Both packages target the `codex` adapter, use schema version 1, and embed one named `hero` image.
- Package inspection reported only missing store catalog metadata. This does not affect local use.
- The current Microsoft Store Codex build is `26.715.4045.0`.

## Not completed

- No theme was applied to Codex.
- No live DOM snapshot, probe, renderer verification, or screenshot verification was completed.
- The Store edition accepted a restart but did not retain CodeDrobe's `--remote-debugging-port=9335` argument. The actual main `ChatGPT.exe` process had no remote-debugging flag and port 9335 was not listening.

## Resume boundary

Do not retry application or alter CodeDrobe/Core runtime files without explicit authorization. Resolving the Microsoft Store CDP limitation may require a separate Codex profile, which can require a new local user-data directory and sign-in.

## Tool state

CodeDrobe was run only through a workspace-local `npx` cache. No CodeDrobe global command, Codex Skill, or MCP server is installed or enabled. The cache is intentionally retained for reproducibility and can remain unused while this project is suspended.
