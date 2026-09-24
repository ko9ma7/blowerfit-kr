@echo off
setlocal EnableExtensions
cd /d "%~dp0"
if errorlevel 1 goto :fail

echo [INFO] Starting BlowerFit KR local preview at http://127.0.0.1:5173/
where node >nul 2>nul
if not errorlevel 1 (
  call npm run dev
  goto :eof
)

where py >nul 2>nul
if not errorlevel 1 (
  start "" "http://127.0.0.1:5173/"
  py -3 -m http.server 5173 --directory web --bind 127.0.0.1
  goto :eof
)

where python >nul 2>nul
if not errorlevel 1 (
  start "" "http://127.0.0.1:5173/"
  python -m http.server 5173 --directory web --bind 127.0.0.1
  goto :eof
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\preview-windows.ps1"
if errorlevel 1 goto :fail
goto :eof

:fail
echo [ERROR] Could not start the local preview server.
pause
exit /b 1
