---
name: codex-theme-author
description: Author or revise advanced Codex Desktop theme manifests, template structure, renderer layout fields, and engine integration in the XJTU Codex Theme repository. Use for explicit manifest/schema work, reusable theme-source maintenance, or low-level preview and rollback engineering; prefer codex-skin-maker for ordinary one- or two-image skin requests.
---

# Codex Theme Author

Create a custom theme from user-owned images while preserving the repository's tested injection and recovery engine.

## Workflow

1. Locate the repository root containing `engine/`, `template/unbranded/`, and `xjtu-theme.cmd`.
2. Read `references/theme-schema.md` before editing theme manifests.
3. Inspect Git status and preserve all existing user changes.
4. Treat source images as read-only. Create new derived assets; do not overwrite the originals.
5. Start from `template/unbranded/dark.json` and `light.json`.
6. Create unique, lowercase theme IDs and new asset directories under `themes/`.
7. Set readable colors and conservative scrims. Keep `conversationWallpaper` false unless the user explicitly requests wallpaper in long conversations.
8. Update `engine/themes/dark.json` and `light.json` to point to the new project-contained assets.
9. Run the bundled validator:

```powershell
node .\skills\codex-theme-author\scripts\validate-theme-pack.mjs .
```

10. Run existing engine tests and `preview --dry-run`. Do not claim success for checks that were not run.
11. Show the user the changed files and validation results. Do not perform a real preview until the user explicitly approves live injection.
12. After approval, run one `preview`, then `verify`. If apply or verification fails, run `disable` immediately and report the exact error.

## Image handling

- Prefer 2560×1440 or another 16:9 image.
- Prefer a right-side focal point and a quiet left region.
- Accept JPEG, PNG, or WebP.
- If the user provides one image, reuse it safely for both modes or make local non-destructive derivatives.
- Do not call paid image APIs or upload images unless the user explicitly requests and authorizes it.
- Reject images containing secrets, private data, watermarks, or assets the user cannot legally use.

## Safety boundary

- Never edit `WindowsApps`, `app.asar`, Codex browser profiles, cookies, credentials, or global Codex configuration.
- Never restart Codex for the hot-theme workflow.
- Never create persistence or a scheduled task unless the user explicitly requests it.
- Keep `disable` available before every live preview.
- Refuse live injection when the engine reports an unknown Codex process, a CodeDrobe conflict, or an occupied Inspector that cannot be verified as the same Codex PID.

## Resources

- Read `references/theme-schema.md` for manifest fields, path rules, and tuning ranges.
- Run `scripts/validate-theme-pack.mjs` after every manifest or image change.
