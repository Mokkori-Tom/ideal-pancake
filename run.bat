@echo off
cd /d %~dp0

REM dkronが既に実行中か確認
tasklist /FI "IMAGENAME eq dkron.exe" | find /I "dkron.exe" >nul

REM プロセスが見つからなければ新たに起動する
if errorlevel 1 (
    echo Starting Dkron...
    start bash_auto.exe dkron agent --server --bootstrap-expect=1
) else (
    echo Dkron is already running.
)