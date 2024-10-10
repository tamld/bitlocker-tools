@echo off
setlocal enabledelayedexpansion
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo  Run CMD as Administrator...
    goto goUAC
) else (
 goto goADMIN )

:: Go UAC to get Admin privileges
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

:: ===========================================
:: Define global variables
:: ===========================================
:: Base directory for BitLocker operations
set "bitlockerPATH=%temp%\Bitlocker"
:: Log file paths
set "logFilePath=%bitlockerPATH%\Logs"
set "logFile=%logFilePath%\bitlocker.log"
set "usbLogFile=%logFilePath%\bitlocker_usb.log"
:: Recovery key paths
set "recoveryKeyPath=%bitlockerPATH%\RecoveryKeys"
set "recoveryKeyInfoFile=%recoveryKeyPath%\drive-%targetDrive%-recoveryKeyInfo.txt"
:: Create the base directory if it doesn't exist
dir /b %bitlockerPATH% > nul 2>&1 || mkdir %bitlockerPATH% > nul 2>&1
dir /b %recoveryKeyPath% > nul 2>&1 || mkdir %recoveryKeyPath% > nul 2>&1
dir /b %logFilePath% > nul 2>&1 || mkdir %logFilePath% > nul 2>&1
:: Get the current timestamp using PowerShell
for /f %%i in ('powershell -command "Get-Date -Format \"ddMMyyyy-HHmmss\""') do set timestamp=%%i
:: Initialize variables for the target drive, encryption status, and percentage completed
set targetDrive=
set status=
set percent=
:: Enable ANSI escape codes for colored output
for /f "tokens=2 delims==" %%i in ('"prompt $E" ^& for %%i in (1) do rem') do set "ESC=%%i"
:: ::   Define color codes for colored output
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
:: ======================================================================================::
:: ===========================================
:: Main menu
:: ===========================================
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
:: echo ===========================================
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
if %errorlevel% == 5 call :checkTPMStatus && goto MainMenu
if %errorlevel% == 4 goto recoverySecurityOptions
if %errorlevel% == 3 goto lockUnlockBitLocker
if %errorlevel% == 2 goto configureBitLocker
if %errorlevel% == 1 goto manageBitLockerStatus

:: ===========================================
:: =         Manage BitLocker Status         =
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

if %errorlevel% ==  3 goto MainMenu
if %errorlevel% ==  2 goto showActivityLog
if %errorlevel% ==  1 goto checkBitLockerStatus

endlocal

:showBitLockerStatus
cls
echo ========================================
echo       Check BitLocker Status
echo ========================================
echo Checking BitLocker status on all drives...

manage-bde -status >> "%logFile%"
if %errorlevel% equ 0 (
    echo %COLOR_GREEN%Successfully checked BitLocker status on all drives.%COLOR_RESET%
    call :logMessage "Successfully checked BitLocker status on all drives."
) else (
    echo %COLOR_RED%Failed to check BitLocker status on all drives.%COLOR_RESET%
    call :logMessage "Failed to check BitLocker status on all drives."
)

:: Display the log file content
type "%logFile%"
PAUSE
goto manageBitLockerStatus

:showActivityLog
cls
echo off
echo ========================================
echo        BitLocker Activity Log
echo ========================================
:: Check if the event log file exists and display it, or show a message if it doesn't
(dir /b %logFile% > nul 2>&1 && type "%logFile%" || echo No BitLocker activity log found.)
pause
goto manageBitLockerStatus

:: ===========================================
::             Configure BitLocker           =
:: ===========================================
:configureBitLocker
cls
echo.
echo ===========================================
echo =           Configure BitLocker           =
echo ===========================================
echo =  1. Enable BitLocker                    =
echo =  2. Encrypt a partition / USB drive     =
echo =  3. Decrypt a partition / USB drive     =
echo =  4. Back to Main Menu                   =
echo ===========================================
choice /N /C 1234 /M "Your choice is: "

if %errorlevel% == 4 goto MainMenu
if %errorlevel% == 3 call :decryptDrive
if %errorlevel% == 2 call :encryptDrive
if %errorlevel% == 1 call :enableBitLocker
goto configureBitLocker

:: Functions to enable BitLocker
:enableBitLocker
cls
echo off
echo ========================================
echo        Enable BitLocker
echo ========================================
setlocal enabledelayedexpansion
call :checkSupportedWindowsEdition
call :checkTPMStatus
if not "%TPM_STATUS%"=="TRUE" (
    call :enableBitlockerWithoutTPM
)
PAUSE
endlocal
goto configureBitLocker

:encryptDrive
cls
echo off
echo ========================================
echo        Encrypt Drive
echo ========================================
setlocal enabledelayedexpansion
call :checkBitlockerStatus
IF "%BITLOCKER_STATUS%"=="FALSE" (
    echo %COLOR_RED%Bitlocker cannot run on this system.%COLOR_RESET%
    ping -n 3 localhost > nul
    goto configureBitLocker
) else  (
    echo %COLOR_GREEN%Bitlocker can run on this system.%COLOR_RESET%
    call :listPartitions
    call :promptDriveSelection
    REM call :checkEncryptionStatus %targetDrive%
    REM if "%status%"=="Fully Decrypted" (
        REM echo %COLOR_YELLOW%Drive %targetDrive%: is ready to be encrypted.%COLOR_RESET%
        REM ping -n 3 localhost > nul
        REM exit /b 0) else if "%status%"=="Fully Encrypted" ( 
        REM echo %COLOR_YELLOW%Drive %targetDrive%: is already encrypted.%COLOR_RESET%
        REM echo %COLOR_YELLOW%Please decrypt the drive before encrypting again or select another drive.%COLOR_RESET%
        REM echo %COLOR_YELLOW%You can also get the decryption key by using the function create recovery key.%COLOR_RESET%
        REM ping -n 3 localhost > nul
        REM goto configureBitLocker
    REM )
    call :performEncryptBitlocker
)
endlocal
goto configureBitLocker

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

if %errorlevel% ==  4 goto MainMenu
if %errorlevel% ==  3 call :unlockBitLockerVolumeUSB
if %errorlevel% ==  2 call :unlockBitLockerVolumeRecoveryKey
if %errorlevel% ==  1 call :lockBitLockerVolume

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

if %errorlevel% ==  3 goto MainMenu
if %errorlevel% == 2 call :exportRecoveryKey
if %errorlevel% == 1 call :recoverWithRecoveryKey

::goto recoverySecurityOptions

:recoverWithRecoveryKey
cls
echo Recover with Recovery Key not implemented yet.
pause
goto recoverySecurityOptions

:exportRecoveryKey
cls
echo Exporting Recovery Key to "%bitlockerPATH%\RecoveryKey.txt"...
:: Here we would run the command to export the recovery key
echo (Command to export key not yet implemented)
pause
goto recoverySecurityOptions

:: ===========================================
:: Function: Show TPM Status
:: ===========================================
:showTPMStatus
cls
echo ========================================
echo        Show TPM Status
echo ========================================
setlocal
set "logFile=%bitlockerPATH%\tpm_status.log"

:: Clear the log file if it exists
if exist "%logFile%" del "%logFile%"

:: Check TPM status and write to the log file
wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get /value > "%logFile%" 2>&1

:: Display the log file
type "%logFile%"
endlocal
pause
goto MainMenu

:: ======================================================================================::
:: Reuseable functions
:: ======================================================================================::
:: ===========================================
:: Function: List Partitions
:: ===========================================
:listPartitions
:: List all partitions "Local Fixed Disk" and "Removable Disk" on the computer
echo %COLOR_GREEN%Listing available partitions...%COLOR_RESET%
wmic logicaldisk where "drivetype=2 or drivetype=3" get deviceid, volumename, description
goto :EOF

:: ===========================================
:: Function: Prompt Drive Selection
:: ===========================================
:promptDriveSelection
:: Prompt user to select a drive
echo %COLOR_YELLOW%Select the drive to process:%COLOR_RESET%
set /p targetDrive=Enter the drive letter (e.g., letter C or D): 
if not exist %targetDrive%:\ (
    echo %COLOR_RED%Invalid drive inputed. Please try again. %COLOR_RESET%
    ping -n 2 localhost > nul
    goto promptDriveSelection
)
goto :EOF

:: ===========================================
:: Function: Log Message
:: ===========================================
:logMessage
:: %1 is the message to log
for /f %%i in ('powershell -command "Get-Date -Format \"ddMMyyyy-HHmmss\""') do set timestamp=%%i
echo %~1-%timestamp% >> %logFile%
goto :EOF

:: ===========================================
:: Function: Enable BitLocker
:: ===========================================
:performEncryptBitlocker
setlocal enabledelayedexpansion
cls
for /f %%i in ('powershell -command "Get-Date -Format \"ddMMyyyy-HHmmss\""') do set timestamp=%%i
:: Base directory for BitLocker operations
set "bitlockerPATH=%temp%\Bitlocker"
:: Log file paths
set "logFilePath=%bitlockerPATH%\Logs"
set "logFile=%logFilePath%\bitlocker.log"
:: Recovery key paths
set "recoveryKeyPath=%bitlockerPATH%\RecoveryKeys"
set "recoveryKeyInfoFile=%recoveryKeyPath%\drive-%targetDrive%-recoveryKeyInfo.txt"

:: Prompt user to select encryption method
echo %COLOR_YELLOW%Select the encryption method for %targetDrive%:%COLOR_RESET%
echo 1. %COLOR_PURPLE%XtsAes128%COLOR_RESET% (Recommended for faster encryption - USB Drives)
echo 2. %COLOR_BLUE%XtsAes256%COLOR_RESET% (Recommended for better protection - Internal Drives)
choice /c 12 /m "Enter the encryption method (1 or 2):"

:: Set encryption method based on user choice
if %errorlevel% equ 1 (
    set encryptionMethod=xts_aes128
    echo %COLOR_GREEN%You selected XtsAes128 for faster encryption.%COLOR_RESET%
) else if %errorlevel% equ 2 (
    set encryptionMethod=xts_aes256
    echo %COLOR_GREEN%You selected XtsAes256 for better protection.%COLOR_RESET%
) else (
    echo %COLOR_RED%Invalid selection. Defaulting to XtsAes128.%COLOR_RESET%
    set encryptionMethod=xts_aes128
)
:: Enable BitLocker on the target drive
echo %COLOR_YELLOW%Enabling BitLocker on %targetDrive%: with %encryptionMethod% encryption...%COLOR_RESET%
echo command using: manage-bde -on %targetDrive%: -EncryptionMethod %encryptionMethod% -RecoveryPassword -used
manage-bde -on %targetDrive%: -EncryptionMethod %encryptionMethod% -RecoveryPassword -used >> %recoveryKeyInfoFile%
if %errorlevel% neq 0 (
    echo %COLOR_RED%Failed to enable BitLocker on %targetDrive%: .%COLOR_RESET%
    call :logMessage "Failed to enable BitLocker on %targetDrive%:."
    type %logFile%
    pause
    goto configureBitLocker
) 
rem call :checkEncryptionStatus %targetDrive%
rem if "%status%"=="Encryption in Progress" (
rem     echo %COLOR_YELLOW%Encryption is in progress on %targetDrive%: at: %percent%:...%COLOR_RESET%
rem     timeout /t 5 > nul
rem     call :checkEncryptionStatus %targetDrive%)
rem if "%status%"=="Fully Encrypted" (echo %COLOR_GREEN%Successfully enabled BitLocker on %targetDrive%: with %encryptionMethod% encryption.%COLOR_RESET%)
rem if %status%=="unknown"  (
rem     echo %COLOR_RED%Failed to enable BitLocker on %targetDrive%.%COLOR_RESET%
rem     echo %COLOR_RED%Script will exit.%COLOR_RESET%
rem     exit /b 1
rem )
:: Add RecoveryKey protector to the drive
echo %COLOR_YELLOW%Adding RecoveryKey protector to drive %targetDrive%: ...%COLOR_RESET%
echo ================================================================= >> %recoveryKeyInfoFile%
echo Recovery key for drive %targetDrive% created at: %timestamp% >> %recoveryKeyInfoFile%
echo ================================================================= >> %recoveryKeyInfoFile%
echo command using: manage-bde -protectors -add %targetDrive%: -RecoveryKey "%recoveryKeyPath%" >> %recoveryKeyInfoFile%
manage-bde -protectors -add %targetDrive%: -RecoveryKey "%recoveryKeyPath%" >> %recoveryKeyInfoFile%
if %errorlevel% neq 0 (
    echo %COLOR_RED%Failed to add RecoveryKey protector to drive %targetDrive%.%COLOR_RESET%
    call :logMessage "Failed to add RecoveryKey protector to drive %targetDrive%"
    type %logFile%
    pause
    goto configureBitLocker
)
echo %COLOR_GREEN%Successfully added RecoveryKey protector to drive %targetDrive%.%COLOR_RESET%
ping -n 3 localhost > nul
:: Unhide the recovery key file
attrib -s -h "%recoveryKeyPath%\*.*" > nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_RED%Failed to hide the recovery key file.%COLOR_RESET%
    call :logMessage "Failed to hide the recovery key file."
    type %logFile%
    pause
    goto configureBitLocker
)
echo %COLOR_GREEN%Successfully un-hidden the recovery key file.%COLOR_RESET%
ping -n 3 localhost > nul
:: Display recovery key information
::echo ================================================================= >> "%recoveryKeyInfoFile%"
::echo Recovery key info for drive %targetDrive% created at: %timestamp% >> "%recoveryKeyInfoFile%"
::echo ================================================================= >> "%recoveryKeyInfoFile%"
::manage-bde -protectors -get %targetDrive%: >> "%recoveryKeyInfoFile%"
cls
type "%recoveryKeyInfoFile%"
echo %COLOR_GREEN%Recovery key file for %targetDrive%: created at: %recoveryKeyInfoFile%%COLOR_RESET%
echo %COLOR_BRIGHTYELLOW%Please backup the recovery key file and the info file carefully. If you lose the recovery key, you will not be able to recover your data.%COLOR_RESET%
echo %COLOR_GREEN%Successfully enabled BitLocker on %targetDrive%: with %encryptionMethod% encryption.%COLOR_RESET%
call :logMessage "Successfully enabled BitLocker on %targetDrive%: with %encryptionMethod% encryption at"
PAUSE
endlocal
goto :EOF

:: ===========================================
:: Function: Check TPM Status
:: ===========================================

goto EOF

:: ===========================================
:: Function: Check TPM Status
:: ===========================================

:checkTPMStatus
:: Check TPM status and store in a variable
FOR /F "tokens=2 delims==" %%A IN ('wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get IsEnabled_InitialValue /value') DO SET IsEnabled_InitialValue=%%A

:: Set TPM status based on IsEnabled_InitialValue
IF /I "%IsEnabled_InitialValue%"=="TRUE" (
    SET TPM_STATUS=TRUE
    ECHO %COLOR_GREEN%TPM is enabled and ready for BitLocker.%COLOR_RESET%
) ELSE (
    SET TPM_STATUS=FALSE
    ECHO %COLOR_RED%TPM is not available.%COLOR_RESET%
)
EXIT /B 0

:: ===========================================
:: Function: Check Bitlocker Status
:: ===========================================

:checkBitlockerStatus
call :checkTPMStatus
:: Check Bitlocker status based on TPM status and registry values
IF "%TPM_STATUS%"=="TRUE" (
    ECHO %COLOR_GREEN%Bitlocker can run with TPM.%COLOR_RESET%
    SET BITLOCKER_STATUS=TRUE
) ELSE (
    :: Check registry values for Bitlocker without TPM
    REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v UseAdvancedStartup >nul 2>&1
    SET UseAdvancedStartup=%ERRORLEVEL%
    REG QUERY "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v EnableBDEWithNoTPM >nul 2>&1
    SET EnableBDEWithNoTPM=%ERRORLEVEL%

    IF "%UseAdvancedStartup%"=="0" IF "%EnableBDEWithNoTPM%"=="0" (
        ECHO %COLOR_YELLOW%Bitlocker can run without TPM.%COLOR_RESET%
        SET BITLOCKER_STATUS=TRUE
		ping -n 3 localhost > nul
    ) ELSE (
        SET TPM_STATUS=FALSE
        SET BITLOCKER_STATUS=FALSE
        ECHO %COLOR_RED%Bitlocker cannot run.%COLOR_RESET%
		ping -n 3 localhost > nul
    )
)
EXIT /B 0

:: ===========================================
:: Function: Check Supported Windows Edition
:: ===========================================
:checkSupportedWindowsEdition
for /f "tokens=2 delims==" %%A in ('wmic os get Caption /value ^| findstr /i "Caption"') do set WIN_EDITION=%%A
echo %COLOR_YELLOW%Checking if Windows edition is supported...%COLOR_RESET%
set SUPPORTED_EDITIONS="Microsoft Windows 10 Pro" "Microsoft Windows 10 Enterprise" "Microsoft Windows 10 Education" "Microsoft Windows 11 Pro" "Microsoft Windows 11 Enterprise" "Microsoft Windows 11 Education"
echo %SUPPORTED_EDITIONS% | findstr /i /c:"%WIN_EDITION%" > nul
if %errorlevel% neq 0 (
    echo %COLOR_YELLOW%Unsupported Windows edition: %WIN_EDITION%%COLOR_RESET%
    echo %COLOR_YELLOW%This script only supports Windows editions that include BitLocker.%COLOR_RESET%
    pause
    goto manageBitLockerStatus
)
echo %COLOR_GREEN%%WIN_EDITION% edition is supported.%COLOR_RESET%
goto :EOF

:enableBitlockerWithoutTPM
echo %COLOR_YELLOW%TPM is not enabled.%COLOR_RESET%
echo %COLOR_YELLOW%Attempting to enable BitLocker without TPM...%COLOR_RESET%
ping -n 2 localhost > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v UseAdvancedStartup /t REG_DWORD /d 1 /f > nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\FVE" /v EnableBDEWithNoTPM /t REG_DWORD /d 1 /f > nul 2>&1
echo %COLOR_GREEN%BitLocker configured to work without TPM.%COLOR_RESET%
goto :EOF

:checkEncryptionStatus
:: Get the encryption status
set targetDrive=%1

:: Get the Conversion Status (retrieve everything after "Conversion")
for /f "tokens=3* delims=: " %a in ('manage-bde -status %targetDrive%: ^| find "Conversion Status"') do set status=%a %b

:: Get the Percentage Encrypted (retrieve the percentage)
for /f "tokens=3 delims=: " %f in ('manage-bde -status %targetDrive%: ^| find "Percentage Encrypted"') do set percent=%f

:: Determine the status
rem if "%status%"=="Encryption in Progress" (set status=encrypting)
rem if "%status%"=="Fully Encrypted" (set status=encrypted)
rem if "%status%"=="Fully Decrypted" (set status=decrypted)

:: If status is not determined, report an error
if not defined status (set status=unknown)
goto :EOF


:EOF

:end
cls
echo Exiting BitLocker Management...
exit /b

