@echo off
setlocal

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0package-addon.ps1"
set "EXITCODE=%ERRORLEVEL%"

endlocal & exit /b %EXITCODE%
