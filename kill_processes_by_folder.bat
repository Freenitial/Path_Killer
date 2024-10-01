@echo off & setlocal



REM ======================= TUTORIAL ==========================

REM (optionnal) CALL WITH 1-3 ARGS TO REPLACE CORRESPONDING DEFAULT CONFIG
REM How to call with 3 args : kill_processes_by_folder.bat /folder "C:\Program Files" /recursive 1 /testing 0
REM If you call with 0 args : full default config below applied



REM ================= DEFAULT CONFIGURATION ====================

set "folder=C:\Program Files"          :: Predefined folder path
set "recursive=1"                      :: Enable recursion into subfolders
set "testing=0"                        :: Only display, not kill



REM =============== OPTIONNAL ARGUMENTS HANDLING ===============

:parse_args
if "%~1"=="" goto :after_args
if /i "%~1"=="/folder"    (set "folder=%~2"    & shift & shift & goto :parse_args)
if /i "%~1"=="/recursive" (set "recursive=%~2" & shift & shift & goto :parse_args)
if /i "%~1"=="/testing"   (set "testing=%~2"   & shift & shift & goto :parse_args)
goto :parse_args
:after_args



REM ===================== EXECUTION =============================

if not exist "%folder%" (
    echo Folder not found : "%folder%"
    timeout /t 2 >nul
    exit /b 0
)

if "%recursive%"=="1" (
    set "filter={$_.ExecutablePath -like '%folder%\*'}"
) else (
    set "filter={$_.ExecutablePath -like '%folder%\*' -and (Split-Path $_.ExecutablePath -Parent) -eq '%folder%'}"
)

REM (Compatibility) Using "WMI" below instead of "Get-Process" to keep all user processes visible by system account / sccm

if "%testing%"=="1" (
    echo Testing mode is enabled. No action will be performed.
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Get-WmiObject Win32_Process | Where-Object %filter% | Select-Object -Property ProcessId, Name, ExecutablePath"
    pause
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Get-WmiObject Win32_Process | Where-Object %filter% | ForEach-Object { taskkill /PID $_.ProcessId /F }"
)

exit /b 0
