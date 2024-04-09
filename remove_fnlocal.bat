@echo off

rem Check if the script is running as administrator
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo This script requires administrator privileges.
    echo Please run it as an administrator.
    pause
    exit /b 1
)

echo Proceeding with the removal of FNLocalCloud agent.

rem Kill the FNLocal.exe process if it's running
tasklist | findstr /i "FNLocal.exe" > nul
if %errorlevel% == 0 (
    taskkill /f /im FNLocal.exe
    echo FNLocal.exe process has been terminated.
)

rem Check if the scheduled task exists, then remove it
schtasks /query /tn "FNLocal" > nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "FNLocal" /f
    echo Scheduled task "FNLocal" removed.
) else (
    echo Scheduled task "FNLocal" not found.
)

rem Check if FNLocal.exe exists and delete it
if exist "C:\Program Files (x86)\FNLocal\FNLocal.exe" (
    del "C:\Program Files (x86)\FNLocal\FNLocal.exe" 2>nul
    echo FNLocal.exe file deleted.
) else (
    echo FNLocal.exe file not found.
)

rem Delete the setup_fnlocal.bat file
if exist "%USERPROFILE%\Downloads\setup_fnlocal.bat" (
    del "%USERPROFILE%\Downloads\setup_fnlocal.bat"
    echo setup_fnlocal.bat file deleted.
) else (
    echo setup_fnlocal.bat file not found.
)

rem Delete the remove_fnlocal.bat file
if exist "%USERPROFILE%\Downloads\remove_fnlocal.bat" (
    del "%USERPROFILE%\Downloads\remove_fnlocal.bat"
    echo remove_fnlocal.bat file deleted.
)

echo FNLocalCloud agent has been removed successfully.
