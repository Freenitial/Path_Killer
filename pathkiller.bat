@echo off & chcp 65001 >nul & title Path Killer & setlocal enabledelayedexpansion & echo.




REM ================= DEFAULT CONFIGURATION ====================

set "folders="C:\first\path";"C:\second path""     :: List of paths formated like this
set "recursive=1"                                  :: Enable recursive search into subfolders
set "checkonly=0"                                  :: Not kill + show return code + pause
set "test=0"                                       :: Kill + show return code + pause
set "disablereturncodes=0"                         :: Activate if you want to return 0 everytime
set "silent=0"                                     :: Hide text output from taskkill commands
set "verysilent=0"                                 :: Hide everything
set "logs=1"                                       :: Enable writting logs
set "logfile=%temp%\pathkiller.log"                :: logs location

REM %temp% openas user/admin = %localappdata%\Temp :: %temp% opened as system account = C:\Windows\Temp



if "%verysilent%"=="0" echo  ====================   PATH KILLER   =====================
REM                         |                           ---                            |
REM                         |   Kill any process located into specified folder paths   |
REM                          ==========================================================




REM ======================= TUTORIAL ==========================

REM (optionnal) CALL WITH ARGS TO REPLACE CORRESPONDING DEFAULT CONFIG ABOVE (/folder can be used many times)
REM How to call with args : pathkiller.bat /folder "C:\first\path" /folder "C:\second path" /test 1
REM If you call this script without any arg : full default config above applied

REM Return codes 
::     0 = Some processes have been found and killed
::     1 = Not any process to kill was found
::     2 = %folders% value is null (check if your args are correctly given, otherwise if default is correctly set)
::     3 = No valid filter created (check if your args are correctly given)
::     4 = Failed to close those processes
::     5 = Unrecognized argument

REM *******  You can stop read from there.  *******




REM =============== OPTIONAL ARGUMENTS HANDLING ===============

:parse_args
if "%~1"=="" goto :after_args
if /i "%~1"=="/folder" (
    if defined folders (set "folders=%folders%;"%~2"") else (set "folders="%~2"")
    shift & shift & goto :parse_args
)
if /i "%~1"=="/recursive"           (set "recursive=%~2"          & shift & shift & goto :parse_args)
if /i "%~1"=="/checkonly"           (set "checkonly=%~2"          & shift & shift & goto :parse_args)
if /i "%~1"=="/test"                (set "test=%~2"               & shift & shift & goto :parse_args)
if /i "%~1"=="/disablereturncodes"  (set "disablereturncodes=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="/silent"              (set "silent=%~2"             & shift & shift & goto :parse_args)
if /i "%~1"=="/verysilent"          (set "verysilent=%~2"         & shift & shift & goto :parse_args)
if /i "%~1"=="/logs"                (set "logs=%~2"               & shift & shift & goto :parse_args)
REM We hit this point if an unrecognized argument is given
if "verysilent" neq "1" echo Unrecognized argument : %~1
echo Unrecognized argument : %~1 >> "%logfile%"
set "returncode=5" & goto :end
:after_args




REM ===================== EXECUTION =============================

set "doublecheckfile=%temp%\pathkiller_doublecheck.txt"

if "%logs%"=="1" ((
    echo -
    echo -
    echo -
    echo ================  [BEGIN] - %date% - %time:~0,8%  ===============
    echo -
    echo VARIABLES AT BEGIN :
    echo folders = %folders%
    echo recursive = %recursive% / checkonly = %checkonly% / test = %test% / disablereturncodes = %disablereturncodes% / silent = %silent% / verysilent = %verysilent% / logs = %logs%
    echo -
)) >> "%logfile%"
   
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

if "%silent%" neq "0" set "nulornot=1"
if "%verysilent%" neq "0" set "nulornot=1"
if defined nulornot (set "switch=>nul") else (set "switch=")

if "%verysilent%" neq "1" echo Looking for processes to kill...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "try{((Get-WmiObject Win32_Process | Where-Object { %filter% } | Select-Object -Property ProcessId, Name, ExecutablePath)[0])}catch{exit 1}" %switch% && set "checkok=1"

if defined checkok (set "returncode=0") else (set "returncode=1" & goto :end)

if "%checkonly%" neq "1" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try{((Get-WmiObject Win32_Process | Where-Object { %filter% } | ForEach-Object { echo $_.Name $_.ProcessId `n - | Add-Content -Path "%logfile%" -Encoding UTF8; taskkill /PID $_.ProcessId /F 2>&1 })[0])}catch{exit 1}" >nul || set "returncode=1"
    if "!returncode!" neq "1" timeout /t 3 >Nul
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "try{((Get-WmiObject Win32_Process | Where-Object { %filter% } | Select-Object -Property ProcessId, Name, ExecutablePath))}catch{exit 1}" > "%doublecheckfile%"
    for %%i in ("%doublecheckfile%") do if %%~zi NEQ 0 set "returncode=4"
)




REM ====================== ENDING ===============================

:end
if not defined returncode set "returncode=1"


if "%verysilent%"=="0" (
    if "%returncode%"=="0"                       echo Some processes have been killed.
    if "%returncode%"=="1"                       echo Not any matching process found.
    if "%returncode%"=="2"                       echo [Error] - Variable %%folders%% is null.
    if "%returncode%"=="3"                       echo [Error] - No valid folder filter created.
    if "%returncode%"=="4"                       echo [Error] - Failed to close those processes : & type "%doublecheckfile%"
    if "%returncode%"=="5"                       echo [Error] - Unrecognized argument
)

if "%logs%"=="1" ((
    echo VARIABLES AT END :
    echo folders = %folders%
    echo recursive = %recursive% / checkonly = %checkonly% / test = %test% / disablereturncodes = %disablereturncodes% / silent = %silent% / verysilent = %verysilent% / logs = %logs%
    echo -    
    echo filter = %filter%
    echo -
    echo FINAL RETURN CODE :
    if "%returncode%"=="0"                       echo %returncode% - Some processes have been killed.
    if "%returncode%"=="1"                       echo %returncode% - Not any matching process found.
    if "%returncode%"=="2"                       echo %returncode% - [Error] - Variable %%folders%% is null.
    if "%returncode%"=="3"                       echo %returncode% - [Error] - No valid folder filter created.
    if "%returncode%"=="4"                       echo %returncode% - [Error] - Failed to close those processes : & type "%doublecheckfile%"
    if "%returncode%"=="5"                       echo %returncode% - [Error] - Unrecognized argument
    echo -
)) >> "%logfile%"
del /f "%doublecheckfile%" >nul 2>&1

if "%checkonly%"=="1" if "%verysilent%" neq "1" echo Return Code = %returncode%
if "%test%"=="1"      if "%verysilent%" neq "1" echo Return Code = %returncode%
if "%verysilent%"=="0" echo  --------------------------  END  ------------------------- & echo.
echo --------------  [END] - %date% -%time:~0,8%  ------------- >> "%logfile%" & echo. >> "%logfile%"
if "%checkonly%"=="1" pause
if "%test%"=="1" pause
if "%disablereturncodes%"=="1" set "returncode=0"
exit /b %returncode%
