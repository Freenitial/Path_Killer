@echo off & chcp 65001 >nul & title Path Killer & setlocal enabledelayedexpansion & echo.




REM    ====================   PATH KILLER   =====================
REM   |                           ---                            |
REM   |   Kill any process located into specified folder paths   |
REM    ==========================================================




REM   ================= DEFAULT CONFIGURATION ====================

set "folders="C:\first\path";"C:\second path""     :: Pseudo-list of paths preformated -to modify if you dont use /folder arg-
set "logpath=%temp%\pathkiller.log"                :: Logs location
set "logs=1"                                       :: Write logs
set "recursive=1"                                  :: Search into subfolders
set "retry=1"                                      :: Kill again if processes still runing (max 3 attemps, 2s loop)
set "checkonly=0"                                  :: Only search processes without killing
set "endpause=0"                                   :: Pause at the end
set "disablereturncodes=0"                         :: Final return '0' everytime
set "silent=0"                                     :: Hide text output from taskkill commands
set "verysilent=0"                                 :: Hide everything




REM   ======================= TUTORIAL ==========================

REM (optionnal) CALL WITH ARGS TO REPLACE CORRESPONDING DEFAULT CONFIG ABOVE (/folder can be used many times)
REM How to call with args : pathkiller.bat /folder "C:\first\path" /folder "C:\second path" /endpause 1
REM If you call this script without any arg : full default config above applied

REM Return codes 
::     0 = All processes have been found and killed
::     1 = Not any process to kill was found
::     2 = %folders% value is null (check if your args are correctly given, otherwise if default is correctly set)
::     3 = No valid filter created (check if your args are correctly given)
::     4 = Failed to close some processes
::     5 = Unrecognized argument

REM  %temp% from user/admin = %localappdata%\Temp  ::  %temp% from system account = %windir%\Temp




REM   -----------------------------------------------------------
REM                 You can stop read from there.  
REM   -----------------------------------------------------------




REM   =============== OPTIONAL ARGUMENTS HANDLING ===============

:parse_args
if "%~1"=="" goto :after_args
if /i "%~1"=="/folder" (
    if defined resetedfolders (set "folders=%folders%;"%~2"") else (set "folders="%~2"")
    set "resetedfolders=1"
    shift & shift & goto :parse_args
)
if /i "%~1"=="/recursive"           (set "recursive=%~2"          & shift & shift & goto :parse_args)
if /i "%~1"=="/checkonly"           (set "checkonly=%~2"          & shift & shift & goto :parse_args)
if /i "%~1"=="/endpause"            (set "endpause=%~2"           & shift & shift & goto :parse_args)
if /i "%~1"=="/disablereturncodes"  (set "disablereturncodes=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="/silent"              (set "silent=%~2"             & shift & shift & goto :parse_args)
if /i "%~1"=="/verysilent"          (set "verysilent=%~2"         & shift & shift & goto :parse_args)
if /i "%~1"=="/logs"                (set "logs=%~2"               & shift & shift & goto :parse_args)
if /i "%~1"=="/logpath"             (set "logpath=%~2"            & shift & shift & goto :parse_args)
if /i "%~1"=="/retry"               (set "retry=%~2"              & shift & shift & goto :parse_args)
REM We hit this point if an unrecognized argument is given
if "%verysilent%" neq "1" echo Unrecognized argument : %~1
set "returncode=5"
:after_args
if "%verysilent%"=="1" set "silent=1"




REM   ===================== EXECUTION =============================

if not defined logpath set "logpathwasnull=1"
if "%logs%"=="1" (
    if not defined logpathwasnull (
        for %%I in ("%logpath%") do set "folderPath=%%~dpI"
        set "testDir=!folderPath!!RANDOM!_testdir"
        mkdir "!testDir!" >nul 2>&1
    )
    if not exist !testDir! (
        set "logpath=%temp%\pathkiller.log"
        if "%verysilent%" neq "1" (
            echo [WARNING] - Overriding %%logpath%% value by %%temp%%\pathkiller.log, 
            if not defined logpathwasnull (
                echo             because cannot write into specified log path :
                echo             "%logpath%"
            ) else (
                echo             because current value seems to be empty or wrong: "%logpath%"
            )
            echo.
        )
        echo _________________________________________________________________________________________________ >> "!logpath!" 
        echo. >> "!logpath!" 
        echo ===============================  [BEGIN] - %date% - %time:~0,8%  =============================== >> "!logpath!" 
        echo _________________________________________________________________________________________________ >> "!logpath!" 
        set "alreadyheader=1"
        echo [WARNING] - Overriding %%logpath%% by %%temp%%\pathkiller.log, >> "!logpath!" 
        if not defined logpathwasnull (
            echo             because cannot write into specified log path :  >> "!logpath!"
            echo             "!logpath!" >> "!logpath!"
        ) else (
            echo             because value of %%logpath%% seems to be empty or wrong : "%logpath%"  >> "!logpath!"
        )
        if "%returncode%"=="5" (echo Unrecognized argument : %~1 >> "!logpath!" & goto :end)
    )
    rmdir "!testDir!" >nul 2>&1
)

if "%verysilent%"=="0" (echo  ====================   PATH KILLER   ===================== & echo.)
set "doublecheckfile=%temp%\pathkiller_doublecheck.txt"
del /f "%doublecheckfile%" >nul 2>&1

if "%logs%"=="1" if not defined alreadyheader ((
    echo _________________________________________________________________________________________________
    echo.
    echo ===============================  [BEGIN] - %date% - %time:~0,8%  ===============================
    echo _________________________________________________________________________________________________
)) >> "%logpath%"
if "%logs%"=="1" ((
    echo -
    echo UserName                =  %UserName%
    echo UserProfile             =  %UserProfile%
    echo Temp                    =  %Temp%
    echo Current Directory - CD  =  %CD%
    echo ComputerName            =  %ComputerName%
    echo UserDomain              =  %UserDomain%
    echo -
    echo VARIABLES AT BEGIN :
    echo folders = %folders%
    echo logpath = %logpath%
    echo [recursive = %recursive%] [retry = %retry%] [checkonly = %checkonly%] [endpause = %endpause%] [disablereturncodes = %disablereturncodes%] [silent = %silent%] [verysilent = %verysilent%]
    echo -
)) >> "%logpath%"
   
if not defined folders (set "returncode=2" & goto :end)

set "filter="
for %%F in (%folders%) do (
    set "tempFolder=%%F" & set "tempFolder=!tempFolder:~1,-1!"
    if "%recursive%"=="1" (
        set "filter=!filter!$_.ExecutablePath -like '!tempFolder!\*' -or "
    ) else (
        set "filter=!filter!($_.ExecutablePath -like '!tempFolder!\*' -and (Split-Path $_.ExecutablePath -Parent) -eq '!tempFolder!') -or "
    )
)
REM Remove the trailing " -or " from the filter string
set "filter=%filter:~0,-4%"
if not defined filter (set "returncode=3" & goto :end)

if "%verysilent%" neq "1" echo Searching processes...
if "%logs%"=="1" echo Searching processes...   >> "%logpath%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-WmiObject Win32_Process | Where-Object { %filter% } | Select-Object -Property ProcessId, Name, ExecutablePath" > "%doublecheckfile%"
for %%i in ("%doublecheckfile%") do if %%~zi NEQ 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "(Get-Content '%doublecheckfile%' | Select-Object -SkipLast 1) | Set-Content '%doublecheckfile%'"
    set "returncode=0"
    if "%silent%" neq "1" type "%doublecheckfile%"
    if "%logs%"=="1" type "%doublecheckfile%" >> "%logpath%"
) else (
    set "returncode=1" & goto :end
)

if "%checkonly%"=="1" goto :end

set /a "attempt=1"
if "%verysilent%" neq "1" echo Killing processes...
if "%logs%"=="1" (echo - >> "%logpath%" & echo Killing processes... >> "%logpath%")
:kill
if "%attempt%" NEQ "1" if "%silent%" NEQ "1" echo attempt = "%attempt%"
if "%logs%"=="1" echo Attempt = "%attempt%"  >> "%logpath%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-WmiObject Win32_Process | Where-Object { %filter% } | ForEach-Object { taskkill /PID $_.ProcessId /F 2>&1 }" >nul
timeout /t 2 >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try{((Get-WmiObject Win32_Process | Where-Object { %filter% } | Select-Object -Property ProcessId, Name, ExecutablePath))}catch{exit 1}" > "%doublecheckfile%"
for %%i in ("%doublecheckfile%") do if %%~zi NEQ 0 (set "returncode=4") else (set "returncode=0")
if "!returncode!"=="4" if "%retry%"=="1" if "%attempt%" NEQ "3" (
    set /a attempt+=1
    goto :kill
)
for %%i in ("%doublecheckfile%") do if %%~zi NEQ 0 if "!returncode!"=="4" powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "(Get-Content '%doublecheckfile%' | Select-Object -SkipLast 1) | Set-Content '%doublecheckfile%'"
if "%logs%"=="1" echo - >> "%logpath%"




REM   ====================== ENDING ===============================

:end
if not defined returncode set "returncode=1"

if "%verysilent%" neq "1" (
    echo.
    if "%returncode%"=="0" if "%checkonly%"=="0" echo  RESULT Code %returncode% : All processes have been killed.
    if "%returncode%"=="0" if "%checkonly%"=="1" echo  RESULT Code %returncode% : Matching processes found.
    if "%returncode%"=="1"                       echo  RESULT Code %returncode% : Not any matching process found.
    if "%returncode%"=="2"                       echo  RESULT Code %returncode% : [Error] - Variable %%folders%% is null.
    if "%returncode%"=="3"                       echo  RESULT Code %returncode% : [Error] - No valid folder filter created.
    if "%returncode%"=="4" if "%silent%"=="0"    echo  RESULT Code %returncode% : [Error] - Failed to close those processes : & type "%doublecheckfile%"
    if "%returncode%"=="4" if "%silent%"=="1"    echo  RESULT Code %returncode% : [Error] - Failed to close some processes.
    if "%returncode%"=="5"                       echo  RESULT Code %returncode% : [Error] - Unrecognized argument
    if "%disablereturncodes%"=="1"               echo 'disablereturncodes' is enabled so this script will return 0 anyway
    echo.
)

if "%logs%"=="1" ((
    echo VARIABLES AT END :
    echo folders = %folders%
    echo logpath = %logpath%
    echo [recursive = %recursive%] [retry = %retry%] [checkonly = %checkonly%] [endpause = %endpause%] [disablereturncodes = %disablereturncodes%] [silent = %silent%] [verysilent = %verysilent%]
    echo filter = %filter%
    echo -
    echo FINAL RETURN CODE :
    if "%returncode%"=="0" if "%checkonly%"=="0" echo %returncode% - All processes have been killed.
    if "%returncode%"=="0" if "%checkonly%"=="1" echo %returncode% - Matching processes found.
    if "%returncode%"=="1"                       echo %returncode% - Not any matching process found.
    if "%returncode%"=="2"                       echo %returncode% - [Error] - Variable %%folders%% is null.
    if "%returncode%"=="3"                       echo %returncode% - [Error] - No valid folder filter created.
    if "%returncode%"=="4"                       echo %returncode% - [Error] - Failed to close those processes : & type "%doublecheckfile%"
    if "%returncode%"=="5"                       echo %returncode% - [Error] - Unrecognized argument
    if "%disablereturncodes%"=="1"               echo 'disablereturncodes' is enabled so this script will return 0 anyway
    echo -
)) >> "%logpath%"
del /f "%doublecheckfile%" >nul 2>&1

if "%verysilent%" neq "1" (echo  --------------------------  END  ------------------------- & echo.)
echo -------------------------  [END] ------------------------- >> "%logpath%" & echo - >> "%logpath%" & echo - >> "%logpath%" & echo - >> "%logpath%" & echo - >> "%logpath%"

if "%endpause%"=="1" pause
if "%disablereturncodes%"=="1" set "returncode=0"
exit /b %returncode%
