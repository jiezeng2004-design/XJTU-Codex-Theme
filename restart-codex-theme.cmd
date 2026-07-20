@echo off
setlocal
set "THEME=%~1"
if "%THEME%"=="" set "THEME=dark"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\restart-codex-theme.ps1" -Theme "%THEME%"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo XJTU Codex theme startup failed with exit code %EXIT_CODE%.
  pause
)

exit /b %EXIT_CODE%
