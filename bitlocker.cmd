@echo off
setlocal enabledelayedexpansion
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo  Run CMD as Administrator...
    goto goUAC
) else (
 goto goADMIN )

REM Go UAC to get Admin privileges
:goUAC
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:goADMIN
    pushd "%CD%"
    CD /D "%~dp0"
:: Define variables
set "BITLOCKER_DIR=%temp%\Bitlocker"
set "LOGFILE=%BITLOCKER_DIR%\bitlocker.log"

:: Create directory if it doesn't exist
dir /b %BITLOCKER_DIR% > nul 2>&1 || mkdir %BITLOCKER_DIR%

:: Enable ANSI escape codes
for /f "tokens=2 delims==" %%i in ('"prompt $E" ^& for %%i in (1) do rem') do set "ESC=%%i"

:: Define color codes
set COLOR_BLACK=[30m>nul
set COLOR_BLUE=[34m>nul
set COLOR_CYAN=[36m>nul
set COLOR_GREEN=[32m>nul
set COLOR_PURPLE=[35m>nul
set COLOR_RED=[31m>nul
set COLOR_WHITE=[37m>nul
set COLOR_YELLOW=[33m>nul
set COLOR_BRIGHTBLACK=[1;30m>nul
set COLOR_BRIGHTBLUE=[1;34m>nul
set COLOR_BRIGHTCYAN=[1;36m>nul
set COLOR_BRIGHTGREEN=[1;32m>nul
set COLOR_BRIGHTPURPLE=[1;35m>nul
set COLOR_BRIGHTRED=[1;31m>nul
set COLOR_BRIGHTWHITE=[1;37m>nul
set COLOR_BRIGHTYELLOW=[1;33m>nul
set COLOR_BG_BLACK=[40m>nul
set COLOR_BG_BLUE=[44m>nul
set COLOR_BG_CYAN=[46m>nul
set COLOR_BG_GREEN=[42m>nul
set COLOR_BG_PURPLE=[45m>nul
set COLOR_BG_RED=[41m>nul
set COLOR_BG_WHITE=[47m>nul
set COLOR_BG_YELLOW=[43m>nul
set COLOR_RESET=[0m>nul

:: Main menu
:MainMenu
cls
echo ".--------------------------------------------------------------."
echo "| ____  _ _   _            _                                   |"
echo "|| __ )(_) |_| | ___   ___| | _____ _ __                       |"
echo "||  _ \| | __| |/ _ \ / __| |/ / _ \ '__|                      |"
echo "|| |_) | | |_| | (_) | (__|   <  __/ |                         |"
echo "||____/|_|\__|_|\___/ \___|_|\_\___|_|                     _   |"
echo "||  \/  | __ _ _ __   __ _  __ _  ___ _ __ ___   ___ _ __ | |_ |"
echo "|| |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '_ ` _ \ / _ \ '_ \| __||"
echo "|| |  | | (_| | | | | (_| | (_| |  __/ | | | | |  __/ | | | |_ |"
echo "||_|__|_|\__,_|_| |_|\__,_|\__, |\___|_| |_| |_|\___|_| |_|\__||"
echo "||_   _|__   ___ | |___    |___/                               |"
echo "|  | |/ _ \ / _ \| / __|                                       |"
echo "|  | | (_) | (_) | \__ \                                       |"
echo "|  |_|\___/ \___/|_|___/                                       |"
echo "'--------------------------------------------------------------'"
echo.
:: echo ===========================================
:: echo =          BitLocker Management           =
echo ===========================================
echo =  1. Manage BitLocker Status             =
echo =  2. Configure BitLocker                 =
echo =  3. Lock/Unlock BitLocker Volumes       =
echo =  4. Recovery and Security Options       =
echo =  5. Check TPM Status                    =
echo =  6. Exit                                =
echo ===========================================
choice /N /C 123456 /M "Your choice is: "

if %errorlevel% == 6 goto Exit
if %errorlevel% == 5 goto checkTPMStatus
if %errorlevel% == 4 goto recoverySecurityOptions
if %errorlevel% == 3 goto lockUnlockBitLocker
if %errorlevel% == 2 goto configureBitLocker
if %errorlevel% == 1 goto manageBitLockerStatus

:: ===========================================
:: Function: Manage BitLocker Status
:: ===========================================
:manageBitLockerStatus
cls
echo.
echo ===========================================
echo =         Manage BitLocker Status         =
echo ===========================================
echo =  1. Check BitLocker status              =
echo =  2. Show BitLocker activity log         =
echo =  3. Back to Main Menu                   =
echo ===========================================
choice /N /C 123 /M "Your choice is: "

if %errorlevel% ==  == 3 goto MainMenu
if %errorlevel% ==  == 2 goto showActivityLog
if %errorlevel% ==  == 1 goto checkBitLockerStatus

endlocal

:checkBitLockerStatus
cls
echo ========================================
echo        Check BitLocker Status
echo ========================================
echo Checking BitLocker status on all drives...
set "LOGFILE=%BITLOCKER_DIR%\bitlocker_status.log"
if exist "%LOGFILE%" del "%LOGFILE%"
manage-bde -status > "%LOGFILE%"
type "%LOGFILE%"
PAUSE
goto manageBitLockerStatus

:showActivityLog
cls
echo off
echo ========================================
echo        BitLocker Activity Log
echo ========================================
:: Check if the event log file exists and display it, or show a message if it doesn't
(dir /b %LOGFILE% > nul 2>&1 && type "%LOGFILE%" || echo No BitLocker activity log found.)
pause
goto manageBitLockerStatus

:: ===========================================
:: Function: Configure BitLocker
:: ===========================================
:configureBitLocker
cls
echo.
echo ===========================================
echo =           Configure BitLocker           =
echo ===========================================
echo =  1. Enable BitLocker on a partition     =
echo =  2. Disable BitLocker on a partition    =
echo =  3. Encrypt a USB drive                 =
echo =  4. Back to Main Menu                   =
echo ===========================================
choice /N /C 1234 /M "Your choice is: "

if %errorlevel% ==  == 4 goto MainMenu
if %errorlevel% ==  == 3 call :encryptUSBDrive
if %errorlevel% ==  == 2 call :disableBitLocker
if %errorlevel% ==  == 1 call :enableBitLocker

goto configureBitLocker

:: Functions to enable BitLocker
:enableBitLocker
cls
echo off
echo ========================================
echo        Enable BitLocker
echo ========================================
setlocal enabledelayedexpansion
set LOGFILE=%BITLOCKER_DIR%\bitlocker_enable.log

:: Clear the log file if it exists
if exist "%LOGFILE%" del "%LOGFILE%"

:: Check Windows edition and write to the log file
echo Checking Windows edition... >> "%LOGFILE%"
wmic os get Caption, Version, OSArchitecture /format:list >> "%LOGFILE%"

:: Check TPM status and write to the log file
echo Checking TPM status... >> "%LOGFILE%"
wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get /value >> "%LOGFILE%"

:: Read Windows edition directly using wmic
for /f "tokens=2 delims==" %%A in ('wmic os get Caption /value ^| findstr /i "Caption"') do set WIN_EDITION=%%A

:: Read TPM status from the log file
for /f "tokens=2 delims==" %%A in ('findstr /i "IsEnabled_InitialValue=" "%LOGFILE%"') do set TPM_STATUS=%%A

:: Display the log file
type "%LOGFILE%"

:: Check if Windows edition is supported
echo Checking if Windows edition is supported...
set SUPPORTED_EDITIONS="Microsoft Windows 10 Pro" "Microsoft Windows 10 Enterprise" "Microsoft Windows 10 Education" "Microsoft Windows 11 Pro" "Microsoft Windows 11 Enterprise" "Microsoft Windows 11 Education"
echo %SUPPORTED_EDITIONS% | findstr /i /c:"%WIN_EDITION%" > nul
if %errorlevel% neq 0 (
    echo %COLOR_BLUE%Unsupported Windows edition: %WIN_EDITION%%COLOR_RESET%
    echo %COLOR_BLUE%This script only supports Windows editions that include BitLocker.%COLOR_RESET%
    endlocal
    pause
    goto manageBitLockerStatus
)
echo %COLOR_GREEN%%WIN_EDITION% edition is supported.%COLOR_RESET%

:: Check if TPM is enabled
echo Checking if TPM is enabled...
if not "%TPM_STATUS%"=="TRUE" (
    echo %COLOR_YELLOW%TPM is not enabled.%COLOR_RESET%
    echo %COLOR_YELLOW%Attempting to enable BitLocker without TPM...%COLOR_RESET%
    reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v UseAdvancedStartup /t REG_DWORD /d 1 /f > nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v EnableBDEWithNoTPM /t REG_DWORD /d 1 /f > nul 2>&1
    echo %COLOR_GREEN%BitLocker configured to work without TPM.%COLOR_RESET%
)
PAUSE
:: List available partitions
cls
echo %COLOR_YELLOW%Listing available drive partitions...%COLOR_RESET%
set "drives="

for /f "skip=1 tokens=2,3 delims=," %%A in ('wmic logicaldisk get deviceid^, description /format:csv') do (
    if "%%A"=="Local Fixed Disk" (
        set "drives=!drives! %%B"
    )
)
cls
echo %COLOR_GREEN%Partition Ready for encryption: %drives%%COLOR_RESET%

if "!drives!"=="" (
    echo No available drives found.
    ping -n 4 localhost > nul
    goto manageBitLockerStatus
)

:selectDriveToEncrypt
setlocal enabledelayedexpansion
:: Get the current timestamp using PowerShell
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format 'ddMMyy_HHmmss'"') do set timestamp=%%i
set outputFile=%temp%\Bitlocker\Bitlocker_Encrypt_%timestamp%.txt

echo %COLOR_YELLOW%Please select a drive to process...%COLOR_RESET%
set /p "drive=Enter the drive letter (e.g., C): "

:: Check if the drive letter is valid
if not exist %drive%:\ (
    echo %COLOR_RED%Invalid drive selected. Please enter a valid drive letter from the list.%COLOR_RESET%
    ping -n 4 localhost > nul
    goto selectDriveToEncrypt
)

echo %COLOR_YELLOW%Encrypting drive %drive%...%COLOR_RESET%
manage-bde -on %drive%: > nul
if !errorlevel! equ 0 (
    echo %COLOR_GREEN%Drive %drive% encrypted successfully.%COLOR_RESET%
    echo %COLOR_YELLOW%Adding RecoveryPassword to drive %drive%...%COLOR_RESET%
    manage-bde -protectors -add %drive%: -RecoveryPassword > nul
    if !errorlevel! equ 0 (
        echo %COLOR_GREEN%RecoveryPassword added to drive %drive% successfully.%COLOR_RESET%
        echo %COLOR_YELLOW%Exporting BitLocker protector information to %outputFile%...%COLOR_RESET%
        manage-bde -protectors -get %drive%: >> "%outputFile%"
        if !errorlevel! equ 0 (
            cls
            type "%outputFile%"
            echo %COLOR_GREEN%BitLocker protector information has been exported to %outputFile%.%COLOR_RESET%
            echo %COLOR_BG_YELLOW%Please backup the file %outputFile% carefully. If you lose the recovery key, you will not be able to recover your data.%COLOR_RESET%
        ) else (
            echo %COLOR_RED%Failed to export BitLocker protector information.%COLOR_RESET%
        )
    ) else (
        echo %COLOR_RED%Failed to add RecoveryPassword to drive %drive%.%COLOR_RESET%
    )
) else (
    echo %COLOR_RED%Failed to encrypt drive %drive%.%COLOR_RESET%
)
PAUSE
endlocal
goto configureBitLocker

:disableBitLocker
cls
echo off
echo ========================================
echo        Disable BitLocker
echo ========================================
setlocal enabledelayedexpansion

:: List available partitions
echo Listing available drive partitions...
set "drives="

for /f "skip=1 tokens=2,3 delims=," %%A in ('wmic logicaldisk get deviceid^, description /format:csv') do (
    if "%%A"=="Local Fixed Disk" (
        set "drives=!drives! %%B"
    )
)
cls
echo Partitions available for decryption: %drives%

if "!drives!"=="" (
    echo No available drives found.
    ping -n 4 localhost > nul
    goto configureBitLocker
)

:selectDriveToDecrypt
set /p "selectedDrive=Choose a drive to decrypt (e.g., C:): "
if defined selectedDrive (
    setlocal enabledelayedexpansion
    set "selectedDrive=!selectedDrive: =!"
    echo %COLOR_YELLOW%Selected drive after processing: !selectedDrive!%COLOR_RESET%
    for %%D in (!drives!) do (
        if /i "!selectedDrive!"=="%%D" (
            echo %COLOR_YELLOW%Checking if the partition %%D is encrypted...%COLOR_RESET%
            manage-bde -status %%D | findstr /i "Conversion Status" | findstr /i "Fully Encrypted" > nul
            if !errorlevel! equ 0 (
                echo %COLOR_YELLOW%Decrypting drive %%D...%COLOR_RESET%
                manage-bde -off %%D
                if !errorlevel! equ 0 (
                    echo %COLOR_GREEN%Drive %%D has been decrypted successfully.%COLOR_RESET%
                ) else (
                    echo %COLOR_RED%Failed to decrypt drive %%D.%COLOR_RESET%
                )
                PAUSE
                endlocal
                goto configureBitLocker
            ) else (
                echo %COLOR_RED%The partition %%D is not encrypted.%COLOR_RESET%
                endlocal
                pause
                goto configureBitLocker
            )
        )
    )
    endlocal
)
echo %COLOR_RED%Invalid drive selected. Please enter a valid drive letter from the list.%COLOR_RESET%
ping -n 4 localhost > nul
goto selectDriveToDecrypt

:encryptUSBDrive
cls
echo Encrypt USB drive not implemented yet.
pause
goto configureBitLocker

:disableBitLocker
cls
echo Disable BitLocker not implemented yet.
pause
goto configureBitLocker

:encryptUSBDrive
cls
echo Encrypt USB drive not implemented yet.
pause
goto configureBitLocker

:: ===========================================
:: Function: Lock/Unlock BitLocker Volumes
:: ===========================================
:lockUnlockBitLocker
cls
echo.
echo =============================================
echo =       Lock/Unlock BitLocker Volumes       =
echo =============================================
echo =  1. Lock a BitLocker volume               =
echo =  2. Unlock a BitLocker volume (Password)  =
echo =  3. Unlock a BitLocker volume (USB)       =
echo =  4. Back to Main Menu                     =
echo =============================================
choice /N /C 1234 /M "Your choice is: "

if %errorlevel% ==  == 4 goto MainMenu
if %errorlevel% ==  == 3 call :unlockBitLockerVolumeUSB
if %errorlevel% ==  == 2 call :unlockBitLockerVolumePassword
if %errorlevel% ==  == 1 call :lockBitLockerVolume

::goto lockUnlockBitLocker

:lockBitLockerVolume
cls
echo Lock BitLocker volume not implemented yet.
pause
goto lockUnlockBitLocker

:unlockBitLockerVolumePassword
cls
echo Unlock BitLocker volume with password not implemented yet.
pause
goto lockUnlockBitLocker

:unlockBitLockerVolumeUSB
cls
echo Unlock BitLocker volume with USB not implemented yet.
pause
goto lockUnlockBitLocker

:: ===========================================
:: Function: Recovery and Security Options
:: ===========================================
:recoverySecurityOptions
cls
echo.
echo ===========================================
echo =       Recovery and Security Options     =
echo ===========================================
echo =  1. Recover data with Recovery Key      =
echo =  2. Export Recovery Key                 =
echo =  3. Back to Main Menu                   =
echo ===========================================
choice /N /C 123 /M "Your choice is: "

if %errorlevel% ==  == 3 goto MainMenu
if %errorlevel% ==  == 2 call :exportRecoveryKey
if %errorlevel% ==  == 1 call :recoverWithRecoveryKey

::goto recoverySecurityOptions

:recoverWithRecoveryKey
cls
echo Recover with Recovery Key not implemented yet.
pause
goto recoverySecurityOptions

:exportRecoveryKey
cls
echo Exporting Recovery Key to "%BITLOCKER_DIR%\RecoveryKey.txt"...
:: Here we would run the command to export the recovery key
echo (Command to export key not yet implemented)
pause
goto recoverySecurityOptions

:: ===========================================
:: Function: Check TPM Status
:: ===========================================
:checkTPMStatus
cls
echo ========================================
echo        Check TPM Status
echo ========================================
setlocal
set "LOGFILE=%BITLOCKER_DIR%\tpm_status.log"

:: Clear the log file if it exists
if exist "%LOGFILE%" del "%LOGFILE%"

:: Check TPM status and write to the log file
wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get /value > "%LOGFILE%" 2>&1

:: Display the log file
type "%LOGFILE%"
endlocal
pause
goto MainMenu

:: Exit function
:Exit
cls
echo Exiting BitLocker Management...
exit /b

