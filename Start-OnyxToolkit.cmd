@echo off
setlocal
fltmc.exe >nul 2>&1
if errorlevel 1 (
    echo Administrator rights are required. Requesting elevation...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-OnyxToolkit.ps1"
if errorlevel 1 (
    echo.
    echo The toolkit stopped with an error. See the logs directory.
    pause
)
endlocal
