@echo off
setlocal

set "DevFolder=%~dp0..\Conceal"
set "GameFolder=C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\Conceal"

if not exist "%DevFolder%" (
    powershell -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Dev folder not found: %DevFolder%', 'Sync Addon Error', 'OK', 'Error')"
    exit /b 1
)

robocopy "%DevFolder%" "%GameFolder%" /MIR

if %ERRORLEVEL% GEQ 8 (
    powershell -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Robocopy failed with exit code %ERRORLEVEL%', 'Sync Addon Error', 'OK', 'Error')"
    exit /b %ERRORLEVEL%
)

endlocal
