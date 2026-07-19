# XJTU Academic CodeDrobe themes

This directory contains two independent Codex theme sources:

- `xjtu-academic-light`: warm ivory daylight artwork with light glass surfaces.
- `xjtu-academic-dark`: indigo blue-hour artwork with dark glass surfaces.

Both themes target the CodeDrobe `codex` app adapter and embed a high-quality, package-optimized JPEG copy of the approved PNG background as the named `hero` image. The source PNG files remain untouched in the project background library.

## Build

```powershell
$env:npm_config_cache='D:\ai_agent\codex_program\.codex-tmp\codedrobe-npm-cache'
npx.cmd --yes @codedrobe/core@latest theme pack .\xjtu-academic-light\theme.json --output ..\dist\xjtu-academic-light-0.1.0.codedrobe-theme
npx.cmd --yes @codedrobe/core@latest theme pack .\xjtu-academic-dark\theme.json --output ..\dist\xjtu-academic-dark-0.1.0.codedrobe-theme
```

The packages can be inspected offline. Live `probe`, `apply`, and `verify` require Codex to expose a loopback CDP port and must not restart an existing Codex process without explicit authorization.
