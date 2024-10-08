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

if %errorlevel% == 6 goto end
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
set %BITLOCKER_DIR%=%temp%\Bitlocker
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
::manage-bde -on %drive%: > nul
manage-bde -on %drive%: -EncryptionMethod XtsAes128 -RecoveryPassword -Protectors > %outputFile%
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
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format 'ddMMyy_HHmmss'"') do set timestamp=%%i
set outputFile=%temp%\Bitlocker\Bitlocker_Decrypt_%timestamp%.txt
:: List available partitions
echo %COLOR_YELLOW%Listing available drive partitions...%COLOR_RESET%
for /f "skip=1 tokens=2,3 delims=," %%A in ('wmic logicaldisk get deviceid^, description /format:csv') do (
    if "%%A"=="Local Fixed Disk" (
        set "drives=!drives! %%B"
    )
)
cls
echo %COLOR_GREEN%List partitions available for decryption: %drives%%COLOR_RESET%
echo.
if "%drives%"=="" (
    echo %COLOR_RED%No available drives found.%COLOR_RESET%
    ping -n 4 localhost > nul
    goto configureBitLocker
)

:selectDriveToDecrypt
echo %COLOR_YELLOW%Please select a drive to decrypt from the list above (e.g., C):%COLOR_RESET%
set /p "drive=Enter the drive letter: "

:: Check if the drive letter is valid
if not exist %drive%:\ (
    echo %COLOR_RED%Invalid drive selected. Please enter a valid drive letter from the list.%COLOR_RESET%
    ping -n 4 localhost > nul
    goto selectDriveToEncrypt
)

echo %COLOR_YELLOW%Checking if the partition %drive% is encrypted...%COLOR_RESET%
manage-bde -status %drive%: | findstr /i "Conversion Status" | findstr /i "Fully Encrypted" > nul
if !errorlevel! equ 0 (
    echo %COLOR_YELLOW%Decrypting drive %drive%...%COLOR_RESET%
    manage-bde -off %drive%: > nul
    if !errorlevel! equ 0 (
        cls
        echo %COLOR_GREEN%Drive %drive% has been decrypted successfully.%COLOR_RESET%
    ) else (
        echo %COLOR_RED%Failed to decrypt drive. Please run decryft the partition manually later.%drive%.%COLOR_RESET%
    )
    PAUSE
    endlocal
    goto configureBitLocker
) else (
    echo %COLOR_RED%The partition %drive% is not encrypted.%COLOR_RESET%
    endlocal
    pause
    goto configureBitLocker
)

:encryptUSBDrive

:: Get timestamp using PowerShell
for /f %%i in ('powershell -command "Get-Date -Format \"ddMMyyyy-HHmmss\""') do set timestamp=%%i

:: Define a unique log file for USB encryption
set usbLogFile=%BITLOCKER_DIR%\bitlocker_usb_%timestamp%.log

:: Create directories if they do not exist
if not exist %BITLOCKER_DIR% (
    mkdir %BITLOCKER_DIR%
)
if not exist %BITLOCKER_DIR% (
    mkdir %BITLOCKER_DIR%
)

:setlectUSBDrive
cls
:: List USB drives
echo %COLOR_YELLOW%Listing available USB drives...%COLOR_RESET%
wmic logicaldisk where "drivetype=2" get deviceid, volumename, description

:: Prompt user to select a USB drive
echo %COLOR_YELLOW%Select the USB drive to encrypt:%COLOR_RESET%
set /p targetDrive=Enter the drive letter (e.g., E:): 

:: Validate the selected drive
if not exist %targetDrive%\ (
    echo %COLOR_RED%Invalid drive selected. Please choose a correct DeviceID from the list above.%COLOR_RESET%
    ping -n 3 localhost > nul
    goto setlectUSBDrive
)

:: Check if BitLocker is already enabled on the drive
manage-bde -status %targetDrive% | find "Conversion Status" | find "Fully Encrypted"
if %errorlevel% equ 0 (
    echo %COLOR_RED%BitLocker is already enabled on this drive.%COLOR_RESET%
    ping -n 3 localhost > nul
    goto configureBitLocker
)

:: Enable BitLocker with AES-256 encryption and a recovery password, only encrypt used space
echo %COLOR_GREEN%Enabling BitLocker on %targetDrive% with AES-256 encryption (used space only)...%COLOR_RESET%
manage-bde -on %targetDrive% -RecoveryPassword -RecoveryKey %BITLOCKER_DIR% -EncryptionMethod AES256 -used >> %usbLogFile% 2>&1

:: Check if the BitLocker enable command was successful
if %errorlevel% neq 0 (
    echo %COLOR_RED%Failed to enable BitLocker on %targetDrive%.%COLOR_RESET%
    type %usbLogFile%
    pause
    goto configureBitLocker
)

:: Get and display the protectors
echo %COLOR_GREEN%Getting the protectors for %targetDrive%...%COLOR_RESET%
manage-bde -protectors -get %targetDrive% >> %usbLogFile% 2>&1

:: Check if the get protectors command was successful
if %errorlevel% neq 0 (
    echo %COLOR_RED%Failed to get protectors for %targetDrive%.%COLOR_RESET%
    type %usbLogFile%
    pause
    goto configureBitLocker
)

:: Check the encryption status
call :checkEncryptionStatus %targetDrive%

:: Display the log file content
type %usbLogFile%
pause
goto configureBitLocker

:checkEncryptionStatus
set targetDrive=%1
:checkStatusLoop
:: Get the encryption status
for /f "tokens=3" %%a in ('manage-bde -status %targetDrive% ^| find "Conversion Status"') do set status=%%a
for /f "tokens=3" %%a in ('manage-bde -status %targetDrive% ^| find "Percentage Encrypted"') do set percent=%%a

if "%status%"=="Encryption" (
    echo %COLOR_YELLOW%Encryption in Progress: %percent% completed.%COLOR_RESET%
    timeout /t 10 > nul
    goto checkStatusLoop
) else if "%status%"=="Encrypted" (
    echo %COLOR_GREEN%BitLocker encryption completed successfully.%COLOR_RESET%
    exit /b 0
) else (
    echo %COLOR_RED%BitLocker encryption failed.%COLOR_RESET%
    exit /b 1
)

:: ===========================================
:: Function: Lock/Unlock BitLocker Volumes
:: ===========================================
:lockUnlockBitLocker
cls
echo.
echo ===============================================
echo =       Lock/Unlock BitLocker Volumes         =
echo ===============================================
echo =  1. Lock a BitLocker volume                 =
echo =  2. Unlock a BitLocker volume (RecoveryKey) =
echo =  3. Unlock a BitLocker volume (USB)         =
echo =  4. Back to Main Menu                       =
echo ===============================================
choice /N /C 1234 /M "Your choice is: "

if %errorlevel% ==  == 4 goto MainMenu
if %errorlevel% ==  == 3 call :unlockBitLockerVolumeUSB
if %errorlevel% ==  == 2 call :unlockBitLockerVolumeRecoveryKey
if %errorlevel% ==  == 1 call :lockBitLockerVolume

::goto lockUnlockBitLocker

:lockBitLockerVolume
cls
echo off
echo ========================================
echo        Lock BitLocker Volume
echo ========================================
setlocal enabledelayedexpansion

:: List available partitions
echo %COLOR_YELLOW%Listing available drive partitions...%COLOR_RESET%
set "drives="

:: Use WMIC to get the list of local fixed disks
for /f "skip=1 tokens=2,3 delims=," %%A in ('wmic logicaldisk get deviceid^, description /format:csv') do (
    if "%%A"=="Local Fixed Disk" (
        set "drives=!drives! %%B"
    )
)
cls
echo %COLOR_GREEN%List partitions available for locking: %drives%%COLOR_RESET%
echo.
if "%drives%"=="" (
    echo %COLOR_RED%No available drives found.%COLOR_RESET%
    ping -n 4 localhost > nul
    goto lockUnlockBitLocker
)

:selectDriveToLock
echo %COLOR_YELLOW%Please select a drive to lock from the list above (e.g., C):%COLOR_RESET%
set /p "drive=Enter the drive letter: "

:: Check if the drive letter is valid and in the list of available drives
set "validDrive=false"
for %%D in (%drives%) do (
    if /I "%%D"=="%drive%" (
        set "validDrive=true"
    )
)

if "%validDrive%"=="false" (
    echo %COLOR_RED%Invalid drive selected. Please enter a valid drive letter from the list.%COLOR_RESET%
    ping -n 4 localhost > nul
    goto selectDriveToLock
)

echo %COLOR_YELLOW%Locking drive %drive%...%COLOR_RESET%
manage-bde -lock %drive%: > nul
if !errorlevel! equ 0 (
    echo %COLOR_GREEN%Drive %drive% has been locked successfully.%COLOR_RESET%
) else (
    echo %COLOR_RED%Failed to lock drive %drive%. Please try again.%COLOR_RESET%
)

PAUSE
endlocal
goto lockUnlockBitLocker

:unlockBitLockerVolumeRecoveryKey
cls
echo off
echo ========================================
echo        Unlock BitLocker Volume
echo ========================================
setlocal enabledelayedexpansion

:: List available partitions
echo %COLOR_YELLOW%Listing available drive partitions...%COLOR_RESET%
set "drives="

:: Use WMIC to get the list of local fixed disks
for /f "skip=1 tokens=2,3 delims=," %%A in ('wmic logicaldisk get deviceid^, description /format:csv') do (
    if "%%B"=="Local Fixed Disk" (
        set "drives=!drives! %%A"
    )
)
cls
echo %COLOR_GREEN%List partitions available for unlocking: %drives%%COLOR_RESET%
echo.
if "%drives%"=="" (
    echo %COLOR_RED%No available drives found.%COLOR_RESET%
    ping -n 4 localhost > nul
    goto lockUnlockBitLocker
)

:selectDriveToUnlock
echo %COLOR_YELLOW%Please select a drive to unlock from the list above (e.g., C):%COLOR_RESET%
set /p "drive=Enter the drive letter: "

:: Check if the drive letter is valid and in the list of available drives
set "validDrive=false"
for %%D in (%drives%) do (
    if /I "%%D"=="%drive%" (
        set "validDrive=true"
    )
)

if "%validDrive%"=="false" (
    echo %COLOR_RED%Invalid drive selected. Please enter a valid drive letter from the list.%COLOR_RESET%
    ping -n 4 localhost > nul
    goto selectDriveToUnlock
)

echo %COLOR_YELLOW%Enter the recovery key for the drive %drive%:%COLOR_RESET%
set /p "recoveryKey=Enter the recovery key: "

echo %COLOR_YELLOW%Unlocking drive %drive%...%COLOR_RESET%
manage-bde -unlock %drive%: -RecoveryPassword %recoveryKey% > nul
if !errorlevel! equ 0 (
    echo %COLOR_GREEN%Drive %drive% has been unlocked successfully.%COLOR_RESET%
) else (
    echo %COLOR_RED%Failed to unlock drive %drive%. Please check the recovery key and try again.%COLOR_RESET%
)

PAUSE
endlocal
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
:end
cls
echo Exiting BitLocker Management...
exit /b

