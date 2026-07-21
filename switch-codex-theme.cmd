@echo off
setlocal
set "THEME=%~1"
if "%THEME%"=="" set "THEME=toggle"

call "%~dp0xjtu-theme.cmd" switch "%THEME%"
exit /b %ERRORLEVEL%
