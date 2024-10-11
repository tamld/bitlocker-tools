call :checkEncryptionStatus e
PAUSE

:checkEncryptionStatus
:: Get the Conversion Status (retrieve everything after "Conversion")
for /f "tokens=3* delims=: " %%a in ('manage-bde -status %targetDrive%: ^| find "Conversion Status"') do set conversion_status=%%a %%b

:: Get the Percentage Encrypted (retrieve the percentage)
for /f "tokens=3 delims=: " %%f in ('manage-bde -status %targetDrive%: ^| find "Percentage Encrypted"') do set percent=%%f

:: Get the Protection Status (retrieve everything after "Protection Status")
for /f "tokens=3* delims=: " %%p in ('manage-bde -status %targetDrive%: ^| find "Protection Status"') do set protection_status=%%p %%q

:: Determine the conversion status
if "%conversion_status%"=="Encryption in Progress" (set conversion_status=encrypting)
if "%conversion_status%"=="Decryption in Progress" (set conversion_status=decrypting)
if "%conversion_status%"=="Fully Encrypted" (set conversion_status=encrypted)
if "%conversion_status%"=="Fully Decrypted" (set conversion_status=decrypted)
if not defined conversion_status (set conversion_status=unknown)

:: Determine the protection status
rem if "%protection_status%"=="Protection Off" (set protection_status=off)
rem if "%protection_status%"=="Protection On" (set protection_status=on)
rem if not defined protection_status (set protection_status=unknown)
cls
echo conversion status: %conversion_status%
echo protection status: %protection_status%
echo percent: %percent%
goto :EOF