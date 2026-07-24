# Codex compatibility

XJTU Codex Theme depends on Microsoft Store Codex Desktop's Electron process and renderer structure. A Codex update can therefore require a compatibility adjustment even when the theme files have not changed.

## Verified matrix

| XJTU Theme | Windows | Codex Desktop | Verification | Status |
| --- | --- | --- | --- | --- |
| v0.3.0-rc.2 | Windows 11 x64, build 26200.8875 | 26.721.3996.0 | Engine dark/light preview, manual click/input/scroll checks, verify, disable and invalid-manifest recovery; new-session Skill E2E pending | Maintainer verified on one machine on 2026-07-24 |
| v0.2.1 | Windows x64, build 26200 (25H2) | 26.715.7063.0 | Live dark preview, renderer health verification, disable/recovery, Node tests, PowerShell safety tests, offline DryRun | Verified by maintainer on 2026-07-21 |
| v0.2.1 | Other supported Windows 10/11 x64 builds | 26.715.7063.0 | Not yet independently tested | Needs tester |
| v0.2.1 | Windows 10/11 x64 | Newer than 26.715.7063.0 | Not yet verified | Report results after updating |

“Verified” applies only to the exact machine and scope stated in each row. It does not promise compatibility with every Windows 10/11 build or future Codex versions.

## After Codex updates

Run the read-only check before applying a theme:

```cmd
xjtu-theme.cmd doctor
```

Then use a one-time preview and verify the renderer:

```cmd
xjtu-theme.cmd preview dark
xjtu-theme.cmd verify
```

If verification fails, stop switching themes and run:

```cmd
xjtu-theme.cmd disable
```

Open a **Codex update compatibility report** with the XJTU Theme version, Codex package version, Windows version, reproduction commands, and a redacted error. Never attach tokens, cookies, account data, complete Codex logs, or unrelated private paths.

## CI boundary

Repository CI validates JSON, local resource paths, engine unit tests, PowerShell safety behavior, and offline DryRun on Windows with Node.js 22. CI does not install or launch Microsoft Store Codex Desktop, so a green workflow does not replace live compatibility testing.
