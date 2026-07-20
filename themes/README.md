# XJTU Academic CodeDrobe themes

This directory contains two independent Codex theme sources:

- `xjtu-academic-light`: warm ivory daylight artwork with light glass surfaces.
- `xjtu-academic-dark`: indigo blue-hour artwork with dark glass surfaces.

Both themes target the CodeDrobe `codex` app adapter and embed a high-quality, package-optimized JPEG copy of the approved PNG background as the named `hero` image. The source PNG files remain untouched in the project background library.

Version 0.1.1 removed the optional `codex-theme-v1` renderer profile because its noninteractive-chrome verification is incompatible with Codex 26.715.7063.0. Version 0.1.2 reduced the original heavy glass treatment. Version 0.1.3 adopts a wallpaper-first layout: the campus art is enlarged to 116%, shifted toward the content area, and kept sharp beneath a 6–8% main tint with no full-panel backdrop blur. Stronger local surfaces remain around controls and text. Retained earlier packages are historical artifacts and should not be used for the current trial.

## Build

```powershell
npx.cmd --yes @codedrobe/core@0.6.1 theme pack .\xjtu-academic-light\theme.json --output ..\dist\xjtu-academic-light-0.1.3.codedrobe-theme
npx.cmd --yes @codedrobe/core@0.6.1 theme pack .\xjtu-academic-dark\theme.json --output ..\dist\xjtu-academic-dark-0.1.3.codedrobe-theme
```

## Guarded trial

Use the root `restart-codex-theme.cmd` launcher. It defaults to the dark theme and accepts `light` as its only alternate argument. The launcher uses an isolated Chromium profile, creates and verifies an independent Codex config snapshot, then performs inspect followed by one guarded CodeDrobe apply. Apply launches Codex, preflights all renderer targets, skips incompatible utility windows such as `avatar-overlay`, and verifies every compatible target after injection. Any failure triggers best-effort CodeDrobe restore plus independent config restoration and normal Codex relaunch.

Live selectors still require final validation on the current Microsoft Store Codex renderer. Do not claim visual compatibility until the guarded apply's built-in verification passes and the user inspects both home and conversation contexts.
