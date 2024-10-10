@echo off & chcp 65001 >nul & title PATHKILLER & setlocal enabledelayedexpansion

:: Author = Leo Gillet / Freenitial




REM    =====================   PATHKILLER   =====================
REM   |                           ---                            |
REM   |        Kill any processeS by path, title or name         |
REM    ==========================================================




REM   ================= DEFAULT CONFIGURATION ====================

REM How to pre-complete variable %folders%         :  set "folders="C:\first\path";"C:\second path""
REM How to pre-complete variable %titles%          :  set "titles="first title";"second title""
REM How to pre-complete variable %processes%       :  set "processes="first process.exe";"second process.exe""

set "folders="                                     :: Pseudo-list of paths to search processes running from
set "titles="                                      :: Pseudo-list of titles to search processes corresponding
set "processes="                                   :: Pseudo-list of processes name to search directly

set "logpath=%temp%\pathkiller\pathkiller.log"     :: Logfile location
set "logs=1"                                       :: Enable logs
set "recursive=1"                                  :: If folders specified, search into subfolders
set "retry=1"                                      :: Kill again if processes still runing -max 4 attemps, 1s loop-
set "ensure=0"                                     :: Force retry -8 attempts, 1s loop-
set "titleim="                                     :: If titles specified, filter by process name - eg : cmd.exe
set "titlepartial=1"                               :: Search partial title and case unsensitive - 0 mean exact title
set "checkonly=0"                                  :: Only search without killing
set "endpause=0"                                   :: Pause script at the end to let you read
set "disablereturncodes=0"                         :: Final return code '0' everytime
set "silent=0"                                     :: Hide output of tasklist commands in console
set "verysilent=0"                                 :: Hide everything in console
set "admin=1"                                      :: Ensure run as admin




REM   ======================= TUTORIAL ==========================

goto :skiptutorial

Opening this script without any arg : full default configuration above applied, you have to complete at least %folders%, %titles% or %processes

--------

OPTIONNAL : CALL WITH ARGS TO REPLACE CORRESPONDING DEFAULT CONFIG ABOVE (/folder, /title and /process can be used many times)
In this case make sure %CD% is already in pathkiller.bat directory to let cmd interpret arguments correctly
How to launch with args : pathkiller.bat /folder "C:\first\path" /folder "C:\second path" /endpause 1

How to nice launch with cmd /c :
cmd /c pathkiller.bat ^
       /folder "C:\Program Files\Mozilla" ^
       /folder "%programfiles%\Google\Chrome" ^
       /recursive 1 ^
       /process "notepad++.exe" ^
       /process "chrome.exe" ^
       /title "first title" ^
       /title "second title" ^
       /titleim "cmd.exe" ^
       /titlepartial 1 ^
       /retry 1 ^
       /checkonly 0 ^
       /endpause 0 ^
       /disablereturncodes 0 ^
       /silent 0
       /admin 1

--------

Return codes :
     0 = All processes have been found and killed
     1 = Not any process to kill was found
     2 = Variables %folders%, %titles% and %processes% are all empty
     3 = No valid filter created (related to %folders% - maybe check arguments synthax)
     4 = Failed to close some processes
     5 = Unrecognized argument

%temp% from user/admin     =  %localappdata%\Temp
%temp% from system account =  %windir%\Temp  OR  %windir%\System32\config\systemprofile\AppData\Local\Temp

:skiptutorial


REM   -----------------------------------------------------------
REM                 You can stop read from there.  
REM   -----------------------------------------------------------




REM   =============== OPTIONAL ARGUMENTS HANDLING ===============

:parse_args
if "%~1"=="" goto :after_args
if /i "%~1"=="/folder" (
    set "arg2=%~2"
    if defined resetedfolders (set "folders=!folders!;"!arg2!"") else (set "folders="!arg2!"")
    set "resetedfolders=1"
    shift & shift
    goto :parse_args
)
if /i "%~1"=="/title" (
    set "arg2=%~2"
    if defined resetedtitles (set "titles=!titles!;"!arg2!"") else (set "titles="!arg2!"")
    set "resetedtitles=1"
    shift & shift & goto :parse_args
)
if /i "%~1"=="/process" (
    set "arg2=%~2"
    if defined resetedprocesses (set "processes=!processes!;"!arg2!"") else (set "processes="!arg2!"")
    set "resetedprocesses=1"
    shift & shift & goto :parse_args
)
if /i "%~1"=="/admin"               (set "admin=%~2"              & shift & shift & goto :parse_args)
if /i "%~1"=="/recursive"           (set "recursive=%~2"          & shift & shift & goto :parse_args)
if /i "%~1"=="/checkonly"           (set "checkonly=%~2"          & shift & shift & goto :parse_args)
if /i "%~1"=="/endpause"            (set "endpause=%~2"           & shift & shift & goto :parse_args)
if /i "%~1"=="/disablereturncodes"  (set "disablereturncodes=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="/silent"              (set "silent=%~2"             & shift & shift & goto :parse_args)
if /i "%~1"=="/verysilent"          (set "verysilent=%~2"         & shift & shift & goto :parse_args)
if /i "%~1"=="/logs"                (set "logs=%~2"               & shift & shift & goto :parse_args)
if /i "%~1"=="/logpath"             (set "logpath=%~2"            & shift & shift & goto :parse_args)
if /i "%~1"=="/retry"               (set "retry=%~2"              & shift & shift & goto :parse_args)
if /i "%~1"=="/ensure"              (set "ensure=%~2"             & shift & shift & goto :parse_args)
if /i "%~1"=="/titleim"             (set "titleim=%~2"            & shift & shift & goto :parse_args)
if /i "%~1"=="/titlepartial"        (set "titlepartial=%~2"       & shift & shift & goto :parse_args)
REM We hit this point if an argument is not recognized
set "returncode=6"
:after_args
if "%verysilent%"=="1" set "silent=1"
if "%ensure%"=="1" set "retry=1"




REM   ===================== EXECUTION =============================

if "%verysilent%" neq "1" (echo. & echo. & echo  ==================   PATHKILLER START   ================== & echo.)

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
    )
    rmdir "!testDir!" >nul 2>&1
)

if not exist "%temp%\pathkiller" mkdir "%temp%\pathkiller"
set "results=%temp%\pathkiller\last_results.txt"
del /f "%results%" >nul 2>&1

if "%logs%"=="1" if not defined alreadyheader ((
    echo _________________________________________________________________________________________________
    echo.
    echo ===============================  [BEGIN] - %date% - %time:~0,8%  ===============================
    echo _________________________________________________________________________________________________
)) >> "%logpath%"

if "%returncode%"=="6" (
    set "errorarg=%~1"
    goto :end
)

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
    echo logpath = %logpath%
    echo folders = %folders%
    echo processes = %processes%
    echo titles = %titles%
    echo titleim = %titleim%
    echo [titlepartial=%titlepartial%] [recursive=%recursive%] [retry=%retry%] [checkonly=%checkonly%] [endpause=%endpause%] [disablereturncodes=%disablereturncodes%] [silent=%silent%] [verysilent=%verysilent%]
    echo -
)) >> "%logpath%"

if not defined folders if not defined titles if not defined processes (set "returncode=3" & goto :end)

REM =========================================================================================================================================================
REM =========================================================================================================================================================
REM =========================================================================================================================================================

if "%admin%"=="1" (net session >nul 2>&1 && goto :skipadmin || set "returncode=8") else goto :skipadmin
set "args=%*"
for %%a in (%*) do (
    set "arg=%%a" & if not defined firstarg (set "psArgs='!arg!'" & set "firstArg=0") else (set "psArgs=!psArgs!, '!arg!'")
)
net session >nul 2>&1 || (
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -window minimized -command ""
    powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath '%~f0' -ArgumentList @(!psArgs!) -Verb RunAs -Wait" >nul || (set "returncode=8" & goto :end)
    echo ICI RECUPERER et SET LE RETURN CODE DE POWERSHELL puis exit /b %returncode%
)
:skipadmin

REM =========================================================================================================================================================
REM =========================================================================================================================================================
REM =========================================================================================================================================================


REM   ====================== SEARCH by PATHS ===============================

if not defined folders goto :skipfolders
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
if not defined filter (set "returncode=4" & goto :end)
if "%verysilent%" neq "1" echo Searching processes by path...
if "%logs%"=="1" echo Searching processes by path...   >> "%logpath%"
call :searchfolders
:skipfolders




REM   ====================== SEARCH by TITLES ===============================

if not defined titles goto :skiptitles
if "%verysilent%" neq "1" echo Searching processes by title...
if "%logs%"=="1" echo Searching processes by title...   >> "%logpath%"
if defined titleim set "titleim=/fi "imagename eq %titleim%""
call :searchtitles
:skiptitles




REM   ==================== SEARCH by PROCESSES ==========================

if not defined processes goto :skipprocesses
if "%verysilent%" neq "1" echo Searching processes directly...
if "%logs%"=="1" echo Searching processes directly...   >> "%logpath%"
call :searchprocesses
:skipprocesses




REM   ========================== VERIFY ===============================

REM Clear last_results.txt from lines that are not a result 
if exist "%results%" (powershell -NoProfile -ExecutionPolicy Bypass -Command "$tempFile = [System.IO.Path]::GetTempFileName(); Get-Content '%results%' -Encoding UTF8 | Where-Object { ($_ -split ',').Count -gt 8 } | Set-Content $tempFile -Encoding UTF8; Move-Item $tempFile '%results%' -Force")
for %%i in ("%results%") do if %%~zi NEQ 0 (
    set "returncode=0"
) else (
    set "returncode=2"
)
if "%returncode%"=="2" goto :end
if "%silent%" neq "1" call :writeresultsconsole
echo this line prevent previous line not working >nul
if "%logs%"=="1" call :writeresultslogs
echo this line prevent previous line not working >nul
echo this line prevent previous line not working >nul
if "%checkonly%"=="1" goto :end




REM   ========================= KILLING ===============================

set /a "attempt=1"
if "%verysilent%" neq "1" echo Killing processes...
if "%logs%"=="1" (echo - >> "%logpath%" & echo Killing processes... >> "%logpath%")
:kill
if "%attempt%" NEQ "1" if "%silent%" NEQ "1" echo attempt = "%attempt%"
if "%logs%"=="1" echo Attempt = "%attempt%"  >> "%logpath%"
REM That next line kill all results by pid
for /f "tokens=2 delims=," %%a in (%results%) do taskkill /f /pid %%a >nul 2>&1
:recheck
del /f "%results%"
if exist "%results%" (set "returncode=7" & goto :end)
timeout /t 1 >nul
if defined folders call :searchfolders
echo this line prevent previous line not working >nul
if defined titles call :searchtitles
echo this line prevent previous line not working >nul
if defined processes call :searchprocesses
echo this line prevent previous line not working >nul
REM Clear last_results.txt from lines that are not a result 
if exist "%results%" (powershell -NoProfile -ExecutionPolicy Bypass -Command "$tempFile = [System.IO.Path]::GetTempFileName(); Get-Content '%results%' -Encoding UTF8 | Where-Object { ($_ -split ',').Count -gt 8 } | Set-Content $tempFile -Encoding UTF8; Move-Item $tempFile '%results%' -Force")
echo this line prevent previous line not working >nul
for %%i in ("%results%") do if %%~zi NEQ 0 (set "returncode=5") else (set "returncode=0")
if "%retry%"=="1" (
    set /a attempt+=1
    if "%ensure%"=="1" if not defined stop (
        if %attempt% lss 8 (goto :kill) else (timeout /t 4 >nul & set "stop=1" & goto :recheck)
    ) else (
        if %attempt% lss 5 goto :kill
    )
)





REM   ====================== ENDING ===============================

:end
if not defined returncode set "returncode=1"
if "%logs%"=="1" echo - >> "%logpath%"

if "%verysilent%" neq "1" (
    echo.
    if "%returncode%"=="0" if "%checkonly%"=="0" echo  RESULT Code %returncode% : All processes have been killed.
    if "%returncode%"=="0" if "%checkonly%"=="1" echo  RESULT Code %returncode% : Matching processes found.
    if "%returncode%"=="1"                       echo  RESULT Code %returncode% : Unhandled error.
    if "%returncode%"=="2"                       echo  RESULT Code %returncode% : Not any matching process found.
    if "%returncode%"=="3"                       echo  RESULT Code %returncode% : [Error] - Variables %%folders%%, %%titles%% and %%processes%% are all empty.
    if "%returncode%"=="4"                       echo  RESULT Code %returncode% : [Error] - No valid filter created related to %%folders%% - maybe check arguments synthax.
    if "%returncode%"=="5" if "%silent%"=="0"    echo  RESULT Code %returncode% : [Error] - Failed to close those processes : & call :writeresultsconsole
    if "%returncode%"=="5" if "%silent%"=="1"    echo  RESULT Code %returncode% : [Error] - Failed to close some processes.
    if "%returncode%"=="6"                       echo  RESULT Code %returncode% : [Error] - Argument not recognized : %errorarg%
    if "%returncode%"=="7"                       echo  RESULT Code %returncode% : [Error] - Results file is locked in %%Temp%%\pathkiller\last_results.txt
)

if "%logs%"=="1" if "%returncode%"=="6" (echo. >> "%logpath%" & echo FINAL RETURN CODE : %returncode% - [Error] - Argument not recognized : %errorarg% >> "%logpath%" & echo. >> "%logpath%")
if "%logs%"=="1" if "%returncode%" neq "6" ((
    echo VARIABLES AT END :
    echo logpath = %logpath%
    echo folders = %folders%
    echo processes = %processes%
    echo titles = %titles%
    echo titleim = %titleim%
    echo [titlepartial=%titlepartial%] [recursive=%recursive%] [retry=%retry%] [checkonly=%checkonly%] [endpause=%endpause%] [disablereturncodes=%disablereturncodes%] [silent=%silent%] [verysilent=%verysilent%]
    echo filter = !filter!
    echo -
    echo FINAL RETURN CODE :
    if "%returncode%"=="0" if "%checkonly%"=="0" echo %returncode% - All processes have been killed.
    if "%returncode%"=="0" if "%checkonly%"=="1" echo %returncode% - Matching processes found.
    if "%returncode%"=="1"                       echo %returncode% - Unhandled error.
    if "%returncode%"=="2"                       echo %returncode% - Not any matching process found.
    if "%returncode%"=="3"                       echo %returncode% - [Error] - Variables %%folders%%, %%titles%% and %%processes%% are all empty.
    if "%returncode%"=="4"                       echo %returncode% - [Error] - No valid filter created related to %%folders%% - maybe check arguments synthax.
    if "%returncode%"=="5"                       echo %returncode% - [Error] - Failed to close those processes :
    if "%returncode%"=="7"                       echo %returncode% - [Error] - last_results.txt file is locked in %%Temp%%\pathkiller
    if "%returncode%" neq "5" echo -
)) >> "%logpath%"

if "%logs%"=="1" if "%returncode%"=="5" (call :writeresultslogs & echo -  >> "%logpath%")
if "%disablereturncodes%"=="1" (
    if "%silent%" neq "1" (echo  BUT 'disablereturncodes' is enabled so this script will return 0 anyway.)
    if "%logs%"=="1" (echo  BUT 'disablereturncodes' is enabled so this script will return 0 anyway. >> "%logpath%" & echo. >> "%logpath%")
    set "returncode=0"
)

:: if defined results del /f "%results%" >nul 2>&1
if "%verysilent%" neq "1" (
    echo. & echo  --------------------  PATHKILLER END  ------------------- & echo.
)
if "%logs%"=="1" (
    echo -------------------------  [END] ------------------------- >> "%logpath%"
    echo - >> "%logpath%" & echo - >> "%logpath%" & echo - >> "%logpath%" & echo - >> "%logpath%"
)

if "%endpause%"=="1" pause
exit /b %returncode%





REM   ====================== FUNCTIONS ===============================



:searchfolders
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$processes = Get-WmiObject Win32_Process | Where-Object { %filter% }; if ($processes) { $results = foreach ($process in $processes) { $title = (Get-Process -Id $process.ProcessId).MainWindowTitle; [string]::Format('\"{0}\",\"{1}\",\"\",\"\",\"\",\"\",\"\",\"\",\"{2}\"', $process.Name, $process.ProcessId, $title) }; $results | Out-File -FilePath '%results%' -Encoding UTF8 -Append }"
goto :eof



:searchtitles
for %%t in (%titles%) do (
    if "%titlepartial%"=="1" (
        tasklist %titleim% /v /fo:csv /nh | findstr /i /r /c:".*%%~t[^,]*$" >> "%results%" 
    ) else (
        tasklist %titleim% /fi "windowtitle eq %%~t" /v /fo:csv /nh >> "%results%"
    )
)
goto :eof



:searchprocesses
for %%p in (%processes%) do (
    tasklist /fi "imagename eq %%~p" /v /fo:csv /nh >> "%results%"
)
goto :eof



:writeresultsconsole
if exist "%results%" (
    if "%silent%" neq "1" (
        echo.
        echo   PID       Process name                    Window Title
        echo   -----------------------------------------------------------------------
        for /f "tokens=1-9 delims=," %%a in (%results%) do (
            echo   %%~b     %%~a                %%~i
        )
        echo.
    )
)
goto :eof



:writeresultslogs
if exist "%results%" (
    if "%logs%"=="1" ((
        echo.
        echo   PID       Process name                    Window Title
        echo   -----------------------------------------------------------------------
        for /f "tokens=1-9 delims=," %%a in (%results%) do (
            echo   %%~b     %%~a                %%~i
        )
        echo.
    )) >> "%logpath%"
)
goto :eof
