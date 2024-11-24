@echo off
for /f "delims=" %%i in ('%cd%\PortableGit\bin\bash.exe -c "cygpath -w $HOME"') do (
    set "HOME_PATH=%%i"
)
echo %HOME_PATH%
pause
