# Unbranded Codex theme template

This directory is a neutral starting point for a custom no-restart Codex theme. It does not contain a distributable wallpaper.

## Required input

Place one or two images in `assets/`:

- `hero-dark.jpg`
- `hero-light.jpg`

If only one image is available, use the same image for both filenames and tune the two JSON files independently.

Recommended image properties:

- 2560×1440 or another 16:9 resolution
- JPEG, PNG, or WebP
- visual focus on the right side
- low-detail area on the left for navigation and text
- no watermarks, credentials, private information, or unlicensed artwork

## Template manifests

- `dark.json`: neutral dark configuration
- `light.json`: neutral light configuration

After editing, copy these two manifests to `engine/themes/dark.json` and `engine/themes/light.json`. Keep the image paths valid relative to those destination files. The supplied paths already point back to this template directory.

Run the validator before any live preview:

```powershell
node .\skills\codex-theme-author\scripts\validate-theme-pack.mjs .
node --test --test-isolation=none .\engine\tests\engine.test.mjs
.\xjtu-theme.cmd preview dark --dry-run
```

Only run a real `preview` after reviewing the generated manifests and confirming that `disable` is available.
