@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0capture_gametable3d.ps1" %*
exit /b %ERRORLEVEL%

