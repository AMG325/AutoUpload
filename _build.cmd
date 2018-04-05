rem !!! Antivirus can break compilation with "Error: Unable to add resources"

@title build AutoUpload exe
@setlocal EnableDelayedExpansion

set AUTOIT=C:\Start\AutoIt

set COMPILER=Aut2Exe\Aut2exe_x64.exe
if %PROCESSOR_ARCHITECTURE% == x86 (
    if not defined PROCESSOR_ARCHITEW6432 set COMPILER=Aut2Exe\Aut2exe.exe
)

set NAME=AutoUpload

set BUILD=%~dp0build

if not exist "%BUILD%\" mkdir "%BUILD%"
if "!ErrorLevel!" NEQ "0" (
    cls
    echo Error while creating build folder
    goto Exit
)

cd /D "%BUILD%"
if exist %NAME%.exe     del /Q %NAME%.exe
if exist %NAME%-x64.exe del /Q %NAME%-x64.exe

cd /D "%~dp0\src"
"%AUTOIT%\%COMPILER%" /in %NAME%.au3 /out "%BUILD%\%NAME%.exe"     /icon Lightning.ico /x86
"%AUTOIT%\%COMPILER%" /in %NAME%.au3 /out "%BUILD%\%NAME%-x64.exe" /icon Lightning.ico /x64

copy config.ini "%BUILD%"

:Exit
@pause
