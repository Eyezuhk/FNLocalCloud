@echo off

rem Check if the script is running as administrator

net session >nul 2>&1

if %errorlevel% NEQ 0 (
    echo This script requires administrator privileges.
    echo Please run it as an administrator.
    pause
    exit /b 1
)

setlocal

rem Define the installation directory
set "installdir=C:\Program Files (x86)\FNLocal"

rem Check if the installation directory exists, if not, create it
if not exist "%installdir%" (
    mkdir "%installdir%"
)

rem Download the FNLocal.exe file directly into the correct program folder
echo Downloading FNLocal.exe...
curl -o "%installdir%\FNLocal.exe" -LJO https://github.com/Eyezuhk/FNLocalCloud/releases/download/v1.0.1/FNLocal.exe

rem Check if the download was successful
if exist "%installdir%\FNLocal.exe" (
    echo FNLocal.exe downloaded successfully.
) else (
    echo Failed to download FNLocal.exe. Please check your internet connection and try again.
    exit /b 1
)

rem Prompt the user for the required parameters
set /p server_address="Enter the server address: "
set /p server_port="Enter the server port [default: 80]: "
set /p local_port="Enter the local port: "
set /p buffer_size="Enter the buffer size in KB: "
set /p protocol="Enter the protocol [HTTP, RDP, TCP]: "

rem Create a scheduled task to start the program at system startup
echo Creating a scheduled task to start the program at system startup...
schtasks /create /tn "FNLocal" /tr "\"%installdir%\FNLocal.exe\" -sa %server_address% -sp %server_port% -lp %local_port% -bs %buffer_size% -p %protocol%" /sc ONSTART /ru S4U /f

if %errorlevel% equ 0 (
    echo Scheduled task created successfully.
) else (
    echo Failed to create scheduled task. Error code: %errorlevel%
    exit /b 1
)

endlocal

pause
