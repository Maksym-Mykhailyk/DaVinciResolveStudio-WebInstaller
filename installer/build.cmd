@echo off
setlocal
set "NSIS=%ProgramFiles(x86)%\NSIS"
if not exist "%NSIS%\makensis.exe" set "NSIS=%ProgramFiles%\NSIS"
"%NSIS%\makensis.exe" "%~dp0ResolveWebInstaller.nsi" %*