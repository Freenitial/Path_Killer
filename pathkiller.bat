@echo off & chcp 65001 >nul & setlocal



::------------------------------------------------------------::
::    Kill any process located into specified folder paths    ::
::------------------------------------------------------------::



REM ======================= TUTORIAL ==========================

REM (optionnal) CALL WITH ARGS TO REPLACE CORRESPONDING DEFAULT CONFIG (/folder can be used many times)
REM How to call with args : pathkiller.bat /folder "C:\first\path" /folder "C:\second path" /testing 1
REM If you call without any arg : full default config below applied



REM ================= DEFAULT CONFIGURATION ====================

set "folders="C:\first\path";"C:\second path""     :: List of paths formated like this
set "recursive=1"                                  :: Enable recursion into subfolders
set "testing=0"                                    :: Only display, not kill



REM =============== OPTIONAL ARGUMENTS HANDLING ===============

:parse_args
if "%~1"=="" goto :after_args
if /i "%~1"=="/folder" (
    if defined folders (set "folders=%folders%;"%~2"") else (set "folders="%~2"")
    shift & shift & goto :parse_args
)
if /i "%~1"=="/recursive" (set "recursive=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="/testing"   (set "testing=%~2"   & shift & shift & goto :parse_args)
goto :parse_args
:after_args



REM ===================== EXECUTION =============================

if not defined folders (
    echo No folders provided.
    timeout /t 2 >nul
    exit /b 0
)

REM Create the PowerShell filter logic dynamically based on the folder list
setlocal enabledelayedexpansion
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

if not defined filter (
    echo No valid folder filter created.
    timeout /t 2 >nul
    exit /b 0
)

REM (Compatibility) Using "WMI" below instead of "Get-Process" to keep all user processes visible by system account / SCCM
if "%testing%"=="1" (
    echo Testing mode is enabled. No action will be performed.
    echo %%filter%% = %filter%
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Get-WmiObject Win32_Process | Where-Object { %filter% } | Select-Object -Property ProcessId, Name, ExecutablePath"
    pause
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Get-WmiObject Win32_Process | Where-Object { %filter% } | ForEach-Object { taskkill /PID $_.ProcessId /F }"
)

endlocal & exit /b 0
