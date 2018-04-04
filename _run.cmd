@title run AutoUpload
@setlocal

set AUTOIT=C:\Start\AutoIt

set EXE=AutoIt3_x64.exe
if %PROCESSOR_ARCHITECTURE% == x86 (
    if not defined PROCESSOR_ARCHITEW6432 set EXE=AutoIt3.exe
)

cd /D "%~dp0\src"
cls
@echo AutoUpload is starting, see icon in the system tray
"%AUTOIT%\%EXE%" AutoUpload.au3
