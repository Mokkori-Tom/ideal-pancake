:: start.bat
@echo off
setlocal
set "APPDATA=%~dp0\config"
start "" alacritty.exe --config-file "%~dp0\alacritty.toml"