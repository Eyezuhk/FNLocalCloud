@echo off

rem Check if the script is running as administrator
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo This script requires administrator privileges.
    echo Please run it as an administrator.
    pause
    exit /b 1
)

rem Download the remove_fnlocal.bat script
echo Downloading remove_fnlocal.bat...
curl -o "%USERPROFILE%\Downloads\remove_fnlocal.bat" -LJO https://raw.githubusercontent.com/Eyezuhk/FNLocalCloud/main/remove_fnlocal.bat

rem Check if the download was successful
if exist "%USERPROFILE%\Downloads\remove_fnlocal.bat" (
    echo remove_fnlocal.bat downloaded successfully.
    "%USERPROFILE%\Downloads\remove_fnlocal.bat"
) else (
    echo Failed to download remove_fnlocal.bat. Proceeding with manual removal.
    
    rem Get the FNLocal.exe location from the scheduled task
    for /f "tokens=3 delims=\" %%a in ('schtasks /query /tn "FNLocalStartup" ^| findstr /i "Program"') do set fnlocal_path=%%a

    rem Kill the FNLocal.exe process if it's running
    tasklist | findstr /i "FNLocal.exe" > nul
    if %errorlevel% == 0 (
        taskkill /f /im FNLocal.exe
        echo FNLocal.exe process has been terminated.
    )

    rem Remove the scheduled task
    schtasks /delete /tn "FNLocalStartup" /f

    rem Delete the FNLocal.exe file
    if exist "%fnlocal_path%" (
        del "%fnlocal_path%" 2>nul
        echo FNLocal.exe file deleted.
    ) else (
        echo FNLocal.exe file not found.
    )

    rem Delete the setup_fnlocal.bat file
    if exist "%USERPROFILE%\Downloads\setup_fnlocal.bat" (
        del "%USERPROFILE%\Downloads\setup_fnlocal.bat"
        echo setup_fnlocal.bat file deleted.
    )

    echo FNLocalCloud setup has been removed successfully.
)

pause
