@echo off
del PingWatchDog.exe
del PingWatchDog.ini

for /f %%i in ('cd') do set CDRESULT=%%i
echo The directory is %CDRESULT%

IF NOT EXIST "%ProgramFiles(x86)%\Autoit3\aut2exe\aut2exe.exe" GOTO NOTON64
"%ProgramFiles(x86)%\Autoit3\aut2exe\aut2exe.exe" /in PingWatchDog.au3 /out PingWatchDog.exe /icon %CDRESULT%\App-world-clock.ico 

:NOTON64
IF NOT EXIST "%ProgramFiles%\Autoit3\aut2exe\aut2exe.exe" GOTO EGGSIT
"%ProgramFiles(x86)%\Autoit3\aut2exe\aut2exe.exe" /in PingWatchDog.au3 /out PingWatchDog.exe /icon %CDRESULT%\App-world-clock.ico 

:EGGSIT
pause