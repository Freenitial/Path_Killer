@echo off
setlocal

REM ================== DEFAULT CONFIGURATION ==================
set "folder=C:\Program Files\Altair" :: The default folder path
set "recursive=1"                    :: Enable recursion into subfolders by default
set "testing=0"                      :: Only display, not kill by default
REM =============================================================

REM ============= OPTIONNAL ARGS, ERASE DEFAULT =================
:parse_args
if "%~1"=="" goto :after_args
if /i "%~1"=="/folder" (
    set "folder=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="/recursive" (
    set "recursive=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="/testing" (
    set "testing=%~2"
    shift
    shift
    goto :parse_args
)
goto :parse_args

:after_args
REM =============================================================

if not exist "%folder%" (
    echo The folder "%folder%" does not exist.
    pause
    exit /b 1
)

if "%recursive%"=="1" (
    set "filter={$_.Path -like '%folder%\*'}"
) else (
    set "filter={$_.Path -like '%folder%\*' -and (Split-Path $_.Path -Parent) -eq '%folder%'}"
)

if "%testing%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process | Where-Object %filter% | Select-Object Id, Path"
    echo.
    echo Testing mode is enabled. No action has been performed.
    pause
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process | Where-Object %filter% | ForEach-Object { taskkill /PID $_.Id /F }"
    if "%recursive%"=="1" (
        echo All processes related to the folder "%folder%" and its subfolders have been terminated.
    ) else (
        echo All processes related to the folder "%folder%" only have been terminated.
    )
)

endlocal
