# XJTU Academic CodeDrobe themes

This directory contains two independent Codex theme sources:

- `xjtu-academic-light`: warm ivory daylight artwork with light glass surfaces.
- `xjtu-academic-dark`: indigo blue-hour artwork with dark glass surfaces.

Both themes target the CodeDrobe `codex` app adapter and embed a high-quality, package-optimized JPEG copy of the approved PNG background as the named `hero` image. The source PNG files remain untouched in the project background library.

## Build

```powershell
npx.cmd --yes @codedrobe/core@0.6.1 theme pack .\xjtu-academic-light\theme.json --output ..\dist\xjtu-academic-light-0.1.0.codedrobe-theme
npx.cmd --yes @codedrobe/core@0.6.1 theme pack .\xjtu-academic-dark\theme.json --output ..\dist\xjtu-academic-dark-0.1.0.codedrobe-theme
```

## Trial

Use the root `restart-codex-theme.cmd` launcher. It defaults to the dark theme and accepts `light` as its only alternate argument. The launcher uses an isolated Chromium profile and performs inspect, launch, probe, apply, and verify in order.

Live selectors still require final validation on the current Microsoft Store Codex renderer. Do not claim visual compatibility until the scripted verify step passes and the user inspects both home and conversation contexts.
