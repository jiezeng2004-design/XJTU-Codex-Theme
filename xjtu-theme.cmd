@echo off
setlocal

if "%~1"=="" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\xjtu-hot-theme.ps1" status
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\xjtu-hot-theme.ps1" %*
)
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo XJTU hot theme command failed with exit code %EXIT_CODE%.
  pause
)

exit /b %EXIT_CODE%
