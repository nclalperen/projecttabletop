@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0godot.ps1" %*
exit /b %ERRORLEVEL%
