# Theme manifest reference

The hot engine reads these active manifests:

- `engine/themes/dark.json`
- `engine/themes/light.json`

Use `template/unbranded/` as the neutral source. Store final images anywhere inside the repository and keep manifest image paths relative to the active manifest file.

## Required top-level fields

- `schemaVersion`: integer `1`.
- `id`: lowercase letters, digits, and hyphens; maximum 64 characters.
- `name`: non-empty display name.
- `variant`: `dark` or `light`, matching the active filename.
- `image`: relative path to a project-contained JPEG, PNG, or WebP image.
- `colors`: exact color fields listed below.
- `layout`: exact layout fields listed below.

Do not add unknown fields; the engine rejects them.

## Colors

Required keys:

- `background`: base application background.
- `panel`: local surface and composer background.
- `accent`: links, focus, and selected controls.
- `text`: primary foreground.
- `muted`: secondary foreground.
- `line`: borders and separators.

Use six-digit hex colors or safe `rgb()` / `rgba()` values. Ensure primary text remains readable over `panel` and `background`.

## Layout

- `positionX`: horizontal wallpaper focal point; usually `64%`–`76%` for right-weighted art.
- `zoom`: wallpaper height; usually `105%`–`118%`.
- `bodyScrimStart` / `bodyScrimEnd`: global image tint.
- `mainScrimStart` / `mainScrimEnd`: main-surface transparent layer.
- `sidebarScrimStart` / `sidebarScrimEnd`: sidebar readability layer.
- `conversationWallpaper`: boolean; default `false`.

All layout values except `conversationWallpaper` are percentages accepted by the engine. Keep values at or below `120%`.

## Safe validation sequence

```powershell
node .\skills\codex-theme-author\scripts\validate-theme-pack.mjs .
node --test --test-isolation=none .\engine\tests\engine.test.mjs
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-hot-theme-engine.ps1
```

Run a real `preview` only after explicit user approval. Follow it with `verify`; use `disable` immediately on failure.
